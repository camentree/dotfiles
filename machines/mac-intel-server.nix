# ============================================================
# Intel MacBook Pro — home server
# ============================================================
{ pkgs, ... }:

{
  nixpkgs.hostPlatform = "x86_64-darwin";

  networking.hostName = "mac-intel-server";
  networking.computerName = "mac-intel-server";

  # Server packages
  environment.systemPackages = with pkgs; [
    nginx
    postgresql
    sqlite
    yarn
  ];

  # Data dir lives at ~/.postgres; bootstrap runs initdb on first launch.
  launchd.user.agents.postgresql = {
    command = "/bin/bash -c 'PGDATA=/Users/camen/.postgres; [ -f \"$PGDATA/PG_VERSION\" ] || ${pkgs.postgresql}/bin/initdb -D \"$PGDATA\"; exec ${pkgs.postgresql}/bin/postgres -D \"$PGDATA\"'";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/postgresql.stdout.log";
      StandardErrorPath = "/tmp/postgresql.stderr.log";
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
    # Force integrated GPU only.
    # The AMD Radeon Pro dGPU on the 16,1 is the most common cause of
    # WindowServer hangs (which trigger watchdog kernel panics) and runs
    # hot/power-hungry. Headless server has no use for it.
    sudo pmset -a gpuswitch 0
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
  };
}
