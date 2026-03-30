# ============================================================
# Intel MacBook Pro — home server
# ============================================================
{ pkgs, ... }:

{
  nixpkgs.hostPlatform = "x86_64-darwin";

  # Server packages
  environment.systemPackages = with pkgs; [
    nginx
    postgresql
    sqlite
    yarn
  ];

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
}
