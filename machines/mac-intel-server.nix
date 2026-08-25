{ pkgs, lib, ... }:

let
  # paths
  homeDirectory = "/Users/camen";
  documentsDirectory = "${homeDirectory}/Documents";
  projectsDirectory = "${homeDirectory}/Projects";

  oneOffsRoot = "${projectsDirectory}/one-offs";
  parallaxRoot = "${projectsDirectory}/parallax";
  todoRoot = "${projectsDirectory}/todo";
  homeAssistantRoot = "${projectsDirectory}/home-assistant";

  # environments
  systemPath = "/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";

  baseEnvironment = {
    PATH = systemPath;
    HOME = homeDirectory;
    USER = "camen";
  };

  parallaxEnvironment = baseEnvironment // {
    PATH = "${homeDirectory}/.npm-global/bin:${systemPath}";
  };

  todoEnvironment = baseEnvironment // {
    PATH = "${pkgs.nodejs_24}/bin:${systemPath}";
    NODE_ENV = "production";
    DATABASE_URL = "postgres://localhost/parallax";
    PORT = "8790";
  };

  uv = "/run/current-system/sw/bin/uv";

  # failure alerts
  ntfyTokenPath = "${homeDirectory}/.ntfy/token";
  ntfyUrl = "http://127.0.0.1:2586";
  ntfyHealthTopic = "server-health";

  ntfyAlert = pkgs.writeShellScript "ntfy-alert" ''
    title="$1"
    message="$2"
    [ -r ${ntfyTokenPath} ] || exit 0
    ${pkgs.curl}/bin/curl -fsS -m 10 --retry 3 -o /dev/null \
      -H "Authorization: Bearer $(< ${ntfyTokenPath})" \
      -H "Title: $title" \
      --data-raw "$message" \
      "${ntfyUrl}/${ntfyHealthTopic}" || true
  '';

  monitoredCommand = name: alertAfterFailures: command:
    "${pkgs.writeShellScript "${name}-monitored" ''
      output=$(mktemp)
      trap 'rm -f "$output"' EXIT
      failureCountFile=/tmp/${name}.failures
      ${command} > "$output" 2>&1
      status=$?
      cat "$output"
      if [ "$status" -eq 0 ]; then
        rm -f "$failureCountFile"
      else
        failureCount=$(( $(cat "$failureCountFile" 2>/dev/null || echo 0) + 1 ))
        echo "$failureCount" > "$failureCountFile"
        if [ "$failureCount" -eq ${toString alertAfterFailures} ]; then
          ${ntfyAlert} "${name} failed" "exit $status after $failureCount attempts
$(tail -c 500 "$output")"
        fi
      fi
      exit "$status"
    ''}";

  # postgres
  postgres = pkgs.postgresql.withPackages (p: [ p.pgvector ]);
  postgresLauncher = pkgs.writeShellScript "postgres-launch" ''
    PGDATA=${homeDirectory}/.postgres
    [ -f "$PGDATA/PG_VERSION" ] || ${postgres}/bin/initdb -D "$PGDATA"
    if [ -f "$PGDATA/postmaster.pid" ] && \
       ! ps -p "$(head -1 "$PGDATA/postmaster.pid")" -o comm= | grep -q postgres; then
      rm -f "$PGDATA/postmaster.pid"
    fi
    exec ${postgres}/bin/postgres -D "$PGDATA"
  '';

  # local backups
  # nixpkgs marks rsnapshot linux-only erroneously
  rsnapshot = pkgs.rsnapshot.overrideAttrs (old: {
    meta = old.meta // { platforms = old.meta.platforms ++ lib.platforms.darwin; };
  });
  rsnapshotBackupRoot = "${homeDirectory}/Backups/rsnapshot";
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
    "backup\t${documentsDirectory}/\tdocuments/\n"
  );
  rsnapshotRun = pkgs.writeShellScript "rsnapshot-run" ''
    set -euo pipefail
    mkdir -p ${rsnapshotBackupRoot}
    exec ${rsnapshot}/bin/rsnapshot -c ${rsnapshotConf} "$@"
  '';

  backupNow = pkgs.writeShellScriptBin "backup-now" ''
    exec ${rsnapshotRun} -V daily
  '';
  backupTest = pkgs.writeShellScriptBin "backup-test" ''
    exec ${rsnapshot}/bin/rsnapshot -c ${rsnapshotConf} configtest
  '';

  # The lowest interval (daily) does the actual rsync; weekly/monthly only
  # rotate, so they must fire *before* daily on overlapping days for correct
  # rotation.
  rsnapshotAgent = interval: schedule: {
    command = monitoredCommand "rsnapshot-${interval}" 1 "${rsnapshotRun} ${interval}";
    serviceConfig = {
      StartCalendarInterval = [ schedule ];
      StandardOutPath = "/tmp/rsnapshot.${interval}.stdout.log";
      StandardErrorPath = "/tmp/rsnapshot.${interval}.stderr.log";
      EnvironmentVariables = baseEnvironment;
    };
  };

  # applications
  appDeploy = repository: pkgs.writeShellScript "deploy-${repository}" ''
    script=${projectsDirectory}/${repository}/scripts/deploy
    if [ ! -x "$script" ]; then
      echo "${repository}: $script is missing or not executable"
      exit 1
    fi
    exec "$script"
  '';
  deployAgent = repository: environment: {
    command = monitoredCommand "deploy-${repository}" 3 "${appDeploy repository}";
    serviceConfig = {
      RunAtLoad = true;
      StartInterval = 120;
      WorkingDirectory = "${projectsDirectory}/${repository}";
      StandardOutPath = "/tmp/deploy-${repository}.stdout.log";
      StandardErrorPath = "/tmp/deploy-${repository}.stderr.log";
      EnvironmentVariables = environment;
    };
  };

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

  # One nginx for both sites; cloudflared routes each hostname to its port.
  nginxConf = pkgs.writeText "nginx.conf" ''
    daemon off;
    worker_processes 1;
    pid /tmp/nginx.pid;
    error_log /tmp/nginx.error.log warn;
    events { worker_connections 64; }
    http {
      include ${pkgs.nginx}/conf/mime.types;
      types { application/manifest+json webmanifest; }
      default_type application/octet-stream;
      access_log off;
      client_body_temp_path /tmp/nginx-client;
      proxy_temp_path /tmp/nginx-proxy;
      fastcgi_temp_path /tmp/nginx-fastcgi;
      uwsgi_temp_path /tmp/nginx-uwsgi;
      scgi_temp_path /tmp/nginx-scgi;

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
  # ===== machine =====

  nixpkgs.hostPlatform = "x86_64-darwin";
  networking.hostName = "mac-intel-server";
  networking.computerName = "mac-intel-server";
  environment.variables.NIX_MACHINE = "mac-intel-server";
  environment.variables.PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
  environment.variables.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";

  # Fix for home-assistant
  networking.knownNetworkServices = [ "Wi-Fi" "USB 10/100/1000 LAN" ];
  networking.dns = [ "192.168.0.1" "1.1.1.1" "8.8.8.8" ];

  environment.systemPackages = with pkgs; [
    backupNow
    backupTest
    cloudflared
    google-cloud-sdk
    nginx
    ntfy-sh
    playwright-driver.browsers
    postgres
    rsnapshot
    sqlite
    yarn
  ];

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
      source = config.lib.file.mkOutOfStoreSymlink "${projectsDirectory}/dotfiles/home/locals/zshrc-local-server";
      force = true;
    };
  };

  # ===== macos defaults =====

  system.defaults.screensaver.askForPassword = lib.mkForce false;
  system.defaults.CustomUserPreferences = {
    "com.apple.bird" = {
      optimize-storage = false;
    };
  };
  system.defaults.CustomSystemPreferences = {
    "/Library/Preferences/com.apple.SoftwareUpdate" = {
      ConfigDataInstall = true;
      CriticalUpdateInstall = true;
    };
  };
  system.defaults.SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;

  power = {
    sleep.display = "never";
    sleep.computer = "never";
    sleep.harddisk = "never";
    restartAfterFreeze = true;
  };

  # mkAfter so the screensaver override lands after os/macos.nix sets it to 300,
  # and so `asPrimaryUser` from that block is already defined.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    # GPU switching is managed manually via the switch-gpu-off / switch-gpu-on
    # shell aliases in home/locals/zshrc-local-server — not set here because the
    # dGPU causes GPU restart storms when headless, but is needed for external
    # displays.
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

  # ===== shared services =====

  # Reads tunnel config from ~/.cloudflared/config.yml (kept outside the repo).
  launchd.user.agents.cloudflared = {
    command = "${pkgs.cloudflared}/bin/cloudflared tunnel --config ${homeDirectory}/.cloudflared/config.yml run";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/cloudflared.stdout.log";
      StandardErrorPath = "/tmp/cloudflared.stderr.log";
    };
  };

  launchd.user.agents.nginx = {
    command = "${pkgs.nginx}/bin/nginx -c ${nginxConf} -e /tmp/nginx.error.log";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/nginx.stdout.log";
      StandardErrorPath = "/tmp/nginx.stderr.log";
    };
  };

  launchd.user.agents.postgresql = {
    command = "${postgresLauncher}";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/postgresql.stdout.log";
      StandardErrorPath = "/tmp/postgresql.stderr.log";
    };
  };

  launchd.daemons.home-assistant = {
    command = "/bin/bash -c 'test -x ${homeAssistantRoot}/scripts/serve && exec ${homeAssistantRoot}/scripts/serve'";
    serviceConfig = {
      KeepAlive = {
        PathState = {
          "${homeAssistantRoot}/scripts/serve" = true;
        };
        NetworkState = true;
      };
      RunAtLoad = true;
      StandardOutPath = "/tmp/home-assistant.stdout.log";
      StandardErrorPath = "/tmp/home-assistant.stderr.log";
      WorkingDirectory = homeAssistantRoot;
      EnvironmentVariables = baseEnvironment;
    };
  };

  # ===== applications =====

  launchd.user.agents.parallax-mcp = parallaxService "mcp";
  launchd.user.agents.parallax-http = parallaxService "http";
  launchd.user.agents.parallax-ntfy = parallaxService "ntfy";

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

  # ===== deploys =====

  launchd.user.agents.deploy-one-offs = deployAgent "one-offs" baseEnvironment;
  launchd.user.agents.deploy-parallax = deployAgent "parallax" parallaxEnvironment;
  launchd.user.agents.deploy-todo = deployAgent "todo" todoEnvironment;

  # ===== scheduled jobs =====

  # Which parallax jobs exist and when each is due lives in the parallax repo;
  # this agent only asks once a minute what is due now.
  launchd.user.agents.parallax-jobs = {
    command = "${uv} run --env-file .env -- parallax jobs --due";
    serviceConfig = {
      RunAtLoad = true;
      StartInterval = 60;
      WorkingDirectory = parallaxRoot;
      StandardOutPath = "/tmp/parallax-jobs.stdout.log";
      StandardErrorPath = "/tmp/parallax-jobs.stderr.log";
      EnvironmentVariables = parallaxEnvironment;
    };
  };

  launchd.user.agents.rsnapshot-daily =
    rsnapshotAgent "daily" { Hour = 3; Minute = 30; };
  launchd.user.agents.rsnapshot-weekly =
    rsnapshotAgent "weekly" { Weekday = 0; Hour = 3; Minute = 10; };
  launchd.user.agents.rsnapshot-monthly =
    rsnapshotAgent "monthly" { Day = 1; Hour = 3; Minute = 0; };
}
