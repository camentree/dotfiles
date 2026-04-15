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
    sleep.display = 15;              # display sleeps after 15 min
    sleep.computer = "never";        # never sleep the computer
    sleep.harddisk = "never";        # never spin down disks
  };

  system.activationScripts.postActivation.text = ''
    # Prevent sleep when lid is closed (clamshell mode)
    sudo pmset -a lidwake 1
    sudo pmset -a acwake 1
    # Wake on network access (for remote SSH)
    sudo pmset -a womp 1
    # Restart after power failure
    sudo pmset -a autorestart 1

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
