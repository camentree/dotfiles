# ============================================================
# Intel MacBook Pro — home server (services live in os/server.nix)
# ============================================================
{ lib, ... }:

{
  imports = [ ../os/server.nix ];

  nixpkgs.hostPlatform = "x86_64-darwin";
  networking.hostName = "mac-intel-server";
  networking.computerName = "mac-intel-server";
  environment.variables.NIX_MACHINE = "mac-intel-server";

  # Fix for home-assistant
  networking.knownNetworkServices = [ "Wi-Fi" "USB 10/100/1000 LAN" ];
  networking.dns = [ "192.168.0.1" "1.1.1.1" "8.8.8.8" ];

  # mkAfter so the screensaver override lands after os/macos.nix sets it to 300,
  # and so `asPrimaryUser` from that block is already defined.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    # GPU switching is managed manually via the switch-gpu-off / switch-gpu-on
    # shell aliases in home/locals/zshrc-local-mac-intel-server — not set here
    # because the dGPU causes GPU restart storms when headless, but is needed
    # for external displays.
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
}
