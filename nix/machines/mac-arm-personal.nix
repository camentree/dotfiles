# ============================================================
# Apple Silicon Mac — personal laptop
# ============================================================
{ pkgs, ... }:

{
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Personal packages
  environment.systemPackages = with pkgs; [
    postgresql
  ];
}
