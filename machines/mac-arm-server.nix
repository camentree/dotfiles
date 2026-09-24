# ============================================================
# Apple Silicon Mac mini — home server (services live in os/server.nix)
# ============================================================
{ lib, ... }:

{
  imports = [ ../os/server.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  networking.hostName = "mac-arm-server";
  networking.computerName = "mac-arm-server";
  environment.variables.NIX_MACHINE = "mac-arm-server";

  # Fix for home-assistant
  networking.knownNetworkServices = [ "Ethernet" "USB 10/100/1000 LAN" "Wi-Fi" ];
  networking.dns = [ "192.168.0.1" "1.1.1.1" "8.8.8.8" ];

  # A desktop has no battery, so a power cut is a hard stop; come back up on
  # our own when power returns.
  power.restartAfterPowerFailure = true;

  # mkAfter so the screensaver override lands after os/macos.nix sets it to 300,
  # and so `asPrimaryUser` from that block is already defined.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    # Wake on network packet (in case sleep ever happens)
    sudo pmset -a womp 1
    # Disable Power Nap (background work during sleep — irrelevant for a server)
    sudo pmset -a powernap 0
    # Sleep is disabled outright, so the RAM-sized hibernate image at
    # /var/vm/sleepimage can never be written to.
    sudo pmset -a hibernatemode 0
    # No screensaver on a headless box; the aerial one decodes 4K video nonstop.
    $asPrimaryUser defaults -currentHost write com.apple.screensaver idleTime -int 0
  '';
}
