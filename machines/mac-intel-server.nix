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
in
{
  nixpkgs.hostPlatform = "x86_64-darwin";

  networking.hostName = "mac-intel-server";
  networking.computerName = "mac-intel-server";

  system.defaults.screensaver.askForPassword = lib.mkForce false;

  # Disable iCloud "Optimize Mac Storage" so Documents/Desktop files stay fully
  # downloaded locally — otherwise macOS may evict them to .icloud placeholder
  # stubs, which rsnapshot would back up instead of the real content.
  system.defaults.CustomUserPreferences = {
    "com.apple.bird" = {
      optimize-storage = false;
    };
  };

  # Server packages
  environment.systemPackages = with pkgs; [
    cloudflared
    nginx
    rsnapshot
    sqlite
    yarn
  ];

  # Reads tunnel config from ~/.cloudflared/config.yml (kept outside the repo).
  launchd.user.agents.cloudflared = {
    command = "${pkgs.cloudflared}/bin/cloudflared tunnel --config /Users/camen/.cloudflared/config.yml run parallax";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/cloudflared.stdout.log";
      StandardErrorPath = "/tmp/cloudflared.stderr.log";
    };
  };

  # Hourly commit + push of ~/Documents/Life to the private github mirror.
  # The script is a no-op when nothing has changed.
  launchd.user.agents.life-backup = {
    command = "/bin/bash /Users/camen/life-backup.sh";
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

  system.activationScripts.postActivation.text = ''
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
  '';

  # ============================================================
  # Home Assistant
  # ============================================================
  # Runs as a LaunchDaemon (root) to bypass macOS Local Network Privacy,
  # which silently blocks mDNS multicast for LaunchAgent processes.
  # bin/start drops to user camen via sudo before launching hass.
  launchd.daemons.home-assistant = {
    command = "/bin/bash -c 'test -x /Users/camen/Projects/home-assistant/bin/start && exec /Users/camen/Projects/home-assistant/bin/start'";
    serviceConfig = {
      KeepAlive.PathState = {
        "/Users/camen/Projects/home-assistant/bin/start" = true;
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

    backup-now = "${rsnapshotRun} -V daily";
    backup-test = "${rsnapshot}/bin/rsnapshot -c ${rsnapshotConf} configtest";
    backup-ls = "ls -lah ${rsnapshotBackupRoot}";

    switch-gpu-off = "sudo pmset -a gpuswitch 0";
    switch-gpu-on = "sudo pmset -a gpuswitch 2";
  };
}
