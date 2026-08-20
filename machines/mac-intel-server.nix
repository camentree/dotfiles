# ============================================================
# Intel MacBook Pro — home server
# ============================================================
{ pkgs, lib, ... }:

let
  postgres = pkgs.postgresql.withPackages (p: [ p.pgvector ]);

  postgresLauncher = pkgs.writeShellScript "postgres-launch" ''
    PGDATA=/Users/camen/.postgres
    [ -f "$PGDATA/PG_VERSION" ] || ${postgres}/bin/initdb -D "$PGDATA"
    if [ -f "$PGDATA/postmaster.pid" ] && \
       ! ps -p "$(head -1 "$PGDATA/postmaster.pid")" -o comm= | grep -q postgres; then
      rm -f "$PGDATA/postmaster.pid"
    fi
    exec ${postgres}/bin/postgres -D "$PGDATA"
  '';

  # nixpkgs marks rsnapshot linux-only, but it's a pure-Perl rsync wrapper
  # that runs fine on darwin; widen meta.platforms instead of allowing
  # unsupported systems globally.
  rsnapshot = pkgs.rsnapshot.overrideAttrs (old: {
    meta = old.meta // { platforms = old.meta.platforms ++ lib.platforms.darwin; };
  });

  rsnapshotBackupRoot = "/Users/camen/Backups/rsnapshot";

  # rsnapshot's config format is tab-delimited; the \t escapes render real tabs.
  rsnapshotConf = pkgs.writeText "rsnapshot.conf" (
    "config_version\t1.2\n" +
    "snapshot_root\t${rsnapshotBackupRoot}/\n" +
    "cmd_rsync\t${pkgs.rsync}/bin/rsync\n" +
    "rsync_long_args\t--delete --numeric-ids --relative --delete-excluded --info=progress2,name0 --stats\n" +
    "link_dest\t1\n" +
    "retain\tdaily\t7\n" +
    "retain\tweekly\t4\n" +
    "retain\tmonthly\t6\n" +
    "verbose\t2\n" +
    "loglevel\t3\n" +
    "logfile\t${rsnapshotBackupRoot}/rsnapshot.log\n" +
    "lockfile\t${rsnapshotBackupRoot}/rsnapshot.pid\n" +
    "exclude\t.DS_Store\n" +
    "exclude\t*.icloud\n" +
    "backup\t/Users/camen/Documents/\tdocuments/\n"
  );

  rsnapshotRun = pkgs.writeShellScript "rsnapshot-run" ''
    set -euo pipefail
    mkdir -p ${rsnapshotBackupRoot}
    exec ${rsnapshot}/bin/rsnapshot -c ${rsnapshotConf} "$@"
  '';

  lifeBackup = pkgs.writeShellScript "life-backup" ''
    set -euo pipefail

    cd "$HOME/Documents/Life"

    git add -A
    if ! git diff --cached --quiet; then
        git commit -q -m "auto $(date -u +%FT%TZ)"
    fi
    git push -q origin main
  '';

  projectsRoot = "/Users/camen/Projects";

  appRepositories = [ "one-offs" "parallax" "parallax-frontend" ];

  appDeploy = pkgs.writeShellScript "app-deploy" ''
    for repository in ${lib.concatStringsSep " " appRepositories}; do
      ( cd ${projectsRoot}/$repository && scripts/deploy ) || echo "$repository deploy failed"
    done
  '';

  oneOffsRoot = "${projectsRoot}/one-offs";

  parallaxRoot = "${projectsRoot}/parallax";

  todoRoot = "${projectsRoot}/parallax-frontend";

  todoEnvironment = {
    PATH = "${pkgs.nodejs_24}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
    HOME = "/Users/camen";
    NODE_ENV = "production";
    DATABASE_URL = "postgres://localhost/parallax";
    PORT = "8790";
  };

  parallaxEnvironment = {
    PATH = "/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
    HOME = "/Users/camen";
  };

  uv = "/run/current-system/sw/bin/uv";

  parallaxService = name: {
    command = "${uv} run parallax serve ${name}";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      WorkingDirectory = parallaxRoot;
      StandardOutPath = "/tmp/parallax-${name}.stdout.log";
      StandardErrorPath = "/tmp/parallax-${name}.stderr.log";
      EnvironmentVariables = parallaxEnvironment;
    };
  };

  parallaxNginxConf = pkgs.writeText "parallax.nginx.conf" ''
    daemon off;
    worker_processes 1;
    pid /tmp/parallax-nginx.pid;
    error_log /tmp/parallax-nginx.error.log warn;
    events { worker_connections 64; }
    http {
      include ${pkgs.nginx}/conf/mime.types;
      default_type application/octet-stream;
      access_log off;
      client_body_temp_path /tmp/parallax-nginx-client;
      proxy_temp_path /tmp/parallax-nginx-proxy;
      fastcgi_temp_path /tmp/parallax-nginx-fastcgi;
      uwsgi_temp_path /tmp/parallax-nginx-uwsgi;
      scgi_temp_path /tmp/parallax-nginx-scgi;
      server {
        listen 127.0.0.1:8788;
        location /api/ { proxy_pass http://127.0.0.1:8787; }
        location /webhook/ { proxy_pass http://127.0.0.1:8787; }
        location /mcp {
          proxy_pass http://127.0.0.1:8000;
          proxy_http_version 1.1;
          proxy_set_header Host $host;
          proxy_set_header Connection "";
          proxy_buffering off;
          proxy_cache off;
          proxy_read_timeout 3600s;
          proxy_send_timeout 3600s;
        }
      }
    }
  '';

  oneOffsNginxConf = pkgs.writeText "one-offs.nginx.conf" ''
    daemon off;
    worker_processes 1;
    pid /tmp/one-offs-nginx.pid;
    error_log /tmp/one-offs-nginx.error.log warn;
    events { worker_connections 64; }
    http {
      include ${pkgs.nginx}/conf/mime.types;
      types { application/manifest+json webmanifest; }
      default_type application/octet-stream;
      access_log off;
      client_body_temp_path /tmp/one-offs-nginx-client;
      proxy_temp_path /tmp/one-offs-nginx-proxy;
      fastcgi_temp_path /tmp/one-offs-nginx-fastcgi;
      uwsgi_temp_path /tmp/one-offs-nginx-uwsgi;
      scgi_temp_path /tmp/one-offs-nginx-scgi;
      server {
        listen 127.0.0.1:8789;
        # cloudflared speaks plain http to us, so an absolute redirect would
        # send the browser from https back to http.
        absolute_redirect off;
        root ${oneOffsRoot};

        location ~ /\. { return 404; }
        location ~ \.md$ { return 404; }

        location = / { try_files /index.html =404; }

        # ^~ stops the project regex below from matching "api" as a project.
        location ^~ /api/ {
          proxy_pass http://127.0.0.1:8787;
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto https;
        }

        location ~ ^/(?<project>[^/.]+)$ { return 301 /$project/; }

        # index.html candidates come first: a bare directory candidate would
        # make try_files internally redirect to the same URI and loop.
        location ~ ^/(?<project>[^/.]+)(?<rest>/.*)$ {
          try_files /$project/dist''${rest}index.html /$project''${rest}index.html
                    /$project/dist$rest /$project$rest
                    /$project/dist/index.html /$project/index.html =404;
        }

        location / { try_files $uri =404; }
      }
    }
  '';
in
{
  nixpkgs.hostPlatform = "x86_64-darwin";

  networking.hostName = "mac-intel-server";
  networking.computerName = "mac-intel-server";

  environment.variables.NIX_MACHINE = "mac-intel-server";

  # DHCP hands out only the router as a resolver, so any hiccup there fails
  # every lookup outright -- Home Assistant integrations then time out and mark
  # their entities unavailable, which Apple Home shows as "No Response". The
  # router stays first so local hostnames still resolve.
  networking.knownNetworkServices = [ "Wi-Fi" "USB 10/100/1000 LAN" ];
  networking.dns = [ "192.168.0.1" "1.1.1.1" "8.8.8.8" ];

  system.defaults.screensaver.askForPassword = lib.mkForce false;

  # Disable iCloud "Optimize Mac Storage" so Documents/Desktop files stay fully
  # downloaded locally — otherwise macOS may evict them to .icloud placeholder
  # stubs, which rsnapshot would back up instead of the real content.
  system.defaults.CustomUserPreferences = {
    "com.apple.bird" = {
      optimize-storage = false;
    };
  };

  # XProtect definitions and Rapid Security Responses install without rebooting,
  # so they're safe to automate; full OS updates stay manual so the server never
  # restarts itself unattended.
  system.defaults.CustomSystemPreferences = {
    "/Library/Preferences/com.apple.SoftwareUpdate" = {
      ConfigDataInstall = true;
      CriticalUpdateInstall = true;
    };
  };
  system.defaults.SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;

  # Server packages
  environment.systemPackages = with pkgs; [
    cloudflared
    google-cloud-sdk
    nginx
    ntfy-sh
    postgres
    rsnapshot
    sqlite
    yarn
  ];

  # Reads tunnel config from ~/.cloudflared/config.yml (kept outside the repo).
  launchd.user.agents.cloudflared = {
    command = "${pkgs.cloudflared}/bin/cloudflared tunnel --config /Users/camen/.cloudflared/config.yml run";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/cloudflared.stdout.log";
      StandardErrorPath = "/tmp/cloudflared.stderr.log";
    };
  };

  launchd.user.agents.one-offs = {
    command = "${pkgs.nginx}/bin/nginx -c ${oneOffsNginxConf} -e /tmp/one-offs-nginx.error.log";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/one-offs-nginx.stdout.log";
      StandardErrorPath = "/tmp/one-offs-nginx.stderr.log";
    };
  };

  launchd.user.agents.app-deploy = {
    command = "${appDeploy}";
    serviceConfig = {
      RunAtLoad = true;
      StartInterval = 120;
      StandardOutPath = "/tmp/app-deploy.stdout.log";
      StandardErrorPath = "/tmp/app-deploy.stderr.log";
      EnvironmentVariables = todoEnvironment;
    };
  };

  # Hourly commit + push of ~/Documents/Life to the private github mirror.
  # The script is a no-op when nothing has changed.
  launchd.user.agents.life-backup = {
    command = "${lifeBackup}";
    serviceConfig = {
      RunAtLoad = true;
      StartInterval = 3600;
      StandardOutPath = "/tmp/life-backup.stdout.log";
      StandardErrorPath = "/tmp/life-backup.stderr.log";
      EnvironmentVariables = {
        PATH = "/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        HOME = "/Users/camen";
      };
    };
  };

  # Data dir lives at ~/.postgres; bootstrap runs initdb on first launch.
  # Launcher clears a stale postmaster.pid (e.g. after an unclean shutdown)
  # only when no live postgres owns it — guards against the PID-reuse case.
  launchd.user.agents.postgresql = {
    command = "${postgresLauncher}";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/postgresql.stdout.log";
      StandardErrorPath = "/tmp/postgresql.stderr.log";
    };
  };

  launchd.user.agents.todo = {
    command = "npm start";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      WorkingDirectory = todoRoot;
      StandardOutPath = "/tmp/todo.stdout.log";
      StandardErrorPath = "/tmp/todo.stderr.log";
      EnvironmentVariables = todoEnvironment;
    };
  };

  launchd.user.agents.parallax-mcp = parallaxService "mcp";
  launchd.user.agents.parallax-http = parallaxService "http";
  launchd.user.agents.parallax-ntfy = parallaxService "ntfy";

  launchd.user.agents.parallax-nginx = {
    command = "${pkgs.nginx}/bin/nginx -c ${parallaxNginxConf} -e /tmp/parallax-nginx.error.log";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/parallax-nginx.stdout.log";
      StandardErrorPath = "/tmp/parallax-nginx.stderr.log";
    };
  };

  launchd.user.agents.parallax-status = {
    command = "${uv} run --env-file .env -- parallax status";
    serviceConfig = {
      RunAtLoad = true;
      StartInterval = 1800;
      WorkingDirectory = parallaxRoot;
      EnvironmentVariables = parallaxEnvironment;
    };
  };

  launchd.user.agents.parallax-sync-oura = {
    command = "${uv} run --env-file .env -- parallax sync oura";
    serviceConfig = {
      RunAtLoad = true;
      StartInterval = 3600;
      WorkingDirectory = parallaxRoot;
      StandardOutPath = "/tmp/parallax-sync-oura.stdout.log";
      StandardErrorPath = "/tmp/parallax-sync-oura.stderr.log";
      EnvironmentVariables = parallaxEnvironment;
    };
  };

  launchd.user.agents.parallax-sync-health = {
    command = "${uv} run --env-file .env -- parallax sync health";
    serviceConfig = {
      RunAtLoad = true;
      StartInterval = 3600;
      WorkingDirectory = parallaxRoot;
      StandardOutPath = "/tmp/parallax-sync-health.stdout.log";
      StandardErrorPath = "/tmp/parallax-sync-health.stderr.log";
      EnvironmentVariables = parallaxEnvironment;
    };
  };

  launchd.user.agents.parallax-prompt-state = {
    command = "${uv} run --env-file .env -- parallax prompt state";
    serviceConfig = {
      RunAtLoad = false;
      StartCalendarInterval = lib.concatMap
        (hour: [ { Hour = hour; Minute = 0; } { Hour = hour; Minute = 30; } ])
        (lib.range 7 22);
      WorkingDirectory = parallaxRoot;
      StandardOutPath = "/tmp/parallax-prompt-state.stdout.log";
      StandardErrorPath = "/tmp/parallax-prompt-state.stderr.log";
      EnvironmentVariables = parallaxEnvironment;
    };
  };

  # ============================================================
  # rsnapshot — local versioned backup of ~/Documents (iCloud)
  # ============================================================
  # Hardlink-deduplicated snapshots under ~/Backups/rsnapshot. The lowest
  # interval (daily) does the actual rsync; weekly/monthly only rotate, so
  # they must fire *before* daily on overlapping days for correct rotation.
  launchd.user.agents.rsnapshot-daily = {
    command = "${rsnapshotRun} daily";
    serviceConfig = {
      StartCalendarInterval = [ { Hour = 3; Minute = 30; } ];
      StandardOutPath = "/tmp/rsnapshot.daily.stdout.log";
      StandardErrorPath = "/tmp/rsnapshot.daily.stderr.log";
      EnvironmentVariables = {
        PATH = "/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        HOME = "/Users/camen";
      };
    };
  };

  launchd.user.agents.rsnapshot-weekly = {
    command = "${rsnapshotRun} weekly";
    serviceConfig = {
      StartCalendarInterval = [ { Weekday = 0; Hour = 3; Minute = 10; } ];
      StandardOutPath = "/tmp/rsnapshot.weekly.stdout.log";
      StandardErrorPath = "/tmp/rsnapshot.weekly.stderr.log";
      EnvironmentVariables = {
        PATH = "/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        HOME = "/Users/camen";
      };
    };
  };

  launchd.user.agents.rsnapshot-monthly = {
    command = "${rsnapshotRun} monthly";
    serviceConfig = {
      StartCalendarInterval = [ { Day = 1; Hour = 3; Minute = 0; } ];
      StandardOutPath = "/tmp/rsnapshot.monthly.stdout.log";
      StandardErrorPath = "/tmp/rsnapshot.monthly.stderr.log";
      EnvironmentVariables = {
        PATH = "/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        HOME = "/Users/camen";
      };
    };
  };

  # ============================================================
  # SSH — key-only authentication
  # ============================================================
  environment.etc."ssh/sshd_config.d/200-no-password.conf".text = ''
    PasswordAuthentication no
    KbdInteractiveAuthentication no
  '';

  home-manager.users.camen = { config, ... }: {
    home.file.".terminfo" = {
      source = "${pkgs.ghostty-bin.terminfo}/share/terminfo";
      recursive = true;
    };

    home.file.".zshrc.local" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/home/locals/zshrc-local-server";
      force = true;
    };
  };

  # ============================================================
  # Keep the Mac awake (server mode)
  # ============================================================
  power = {
    sleep.display = "never";         # avoid WindowServer state transitions
    sleep.computer = "never";        # never sleep the computer
    sleep.harddisk = "never";        # never spin down disks
    restartAfterFreeze = true;       # auto-reboot on kernel panic
    # restartAfterPowerFailure: not supported on laptop hardware (battery)
  };

  # mkAfter so the screensaver override lands after os/macos.nix sets it to 300,
  # and so `asPrimaryUser` from that block is already defined.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    # GPU switching is managed manually via the switch-gpu-off / switch-gpu-on
    # shell aliases below — not set here because the dGPU causes GPU restart
    # storms when headless, but is needed for external displays.
    # Allow lid-closed operation without an external display attached.
    # Without this, closing the lid sleeps regardless of `sleep = never`.
    sudo pmset -a disablesleep 1
    # Wake on lid open / AC plug-in (no-ops with disablesleep but harmless)
    sudo pmset -a lidwake 1
    sudo pmset -a acwake 1
    # Wake on network packet (in case sleep ever happens)
    sudo pmset -a womp 1
    # Disable Power Nap (background work during sleep — irrelevant for a server)
    sudo pmset -a powernap 0
    # Sleep is disabled outright, so the RAM-sized hibernate image at
    # /var/vm/sleepimage is 32 GB that can never be written to.
    sudo pmset -a hibernatemode 0
    # The aerial screensaver decodes 4K video nonstop and pulls the dGPU up once
    # a minute; that storm wedged the machine on 2026-07-31 and 2026-08-06.
    $asPrimaryUser defaults -currentHost write com.apple.screensaver idleTime -int 0
  '';

  # ============================================================
  # Home Assistant
  # ============================================================
  # Runs as a LaunchDaemon (root) to bypass macOS Local Network Privacy,
  # which silently blocks mDNS multicast for LaunchAgent processes.
  # scripts/serve drops to user camen via sudo before launching hass.
  launchd.daemons.home-assistant = {
    command = "/bin/bash -c 'test -x /Users/camen/Projects/home-assistant/scripts/serve && exec /Users/camen/Projects/home-assistant/scripts/serve'";
    serviceConfig = {
      # RunAtLoad fires ~9s after boot, before Wi-Fi finishes associating, and
      # zeroconf binds its multicast sockets once — a bind that loses that race
      # stays broken for the life of the process. NetworkState holds the job
      # until an interface has an address, which covers most of that gap.
      KeepAlive = {
        PathState = {
          "/Users/camen/Projects/home-assistant/scripts/serve" = true;
        };
        NetworkState = true;
      };
      RunAtLoad = true;
      StandardOutPath = "/tmp/home-assistant.stdout.log";
      StandardErrorPath = "/tmp/home-assistant.stderr.log";
      WorkingDirectory = "/Users/camen/Projects/home-assistant";
      EnvironmentVariables = {
        PATH = "/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        HOME = "/Users/camen";
      };
    };
  };

  # Convenience aliases for managing Home Assistant
  environment.shellAliases = {
    ha-stop = "sudo launchctl bootout system/org.nixos.home-assistant";
    ha-start = "sudo launchctl bootstrap system /Library/LaunchDaemons/org.nixos.home-assistant.plist";
    ha-restart = "sudo launchctl bootout system/org.nixos.home-assistant && sudo launchctl bootstrap system /Library/LaunchDaemons/org.nixos.home-assistant.plist";
    ha-log = "tail -f /tmp/home-assistant.stderr.log";

    deploy-log = "tail -f /tmp/app-deploy.stdout.log /tmp/app-deploy.stderr.log";
    deploy-now = "launchctl kickstart -k gui/$UID/org.nixos.app-deploy";

    backup-now = "${rsnapshotRun} -V daily";
    backup-test = "${rsnapshot}/bin/rsnapshot -c ${rsnapshotConf} configtest";
    backup-ls = "ls -lah ${rsnapshotBackupRoot}";

    switch-gpu-off = "sudo pmset -a gpuswitch 0";
    switch-gpu-on = "sudo pmset -a gpuswitch 2";
  };
}
