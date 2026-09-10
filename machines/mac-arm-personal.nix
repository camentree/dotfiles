# ============================================================
# Apple Silicon Mac — personal laptop
# ============================================================
{ pkgs, ... }:

{
  imports = [ ../os/postgres.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  environment.variables.NIX_MACHINE = "mac-arm-personal";

  # Personal packages
  environment.systemPackages = with pkgs; [
    cloudflared
  ];
}
