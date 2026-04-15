# ============================================================
# Apple Silicon Mac — work laptop
# ============================================================
{ pkgs, ... }:

{
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Work packages
  environment.systemPackages = with pkgs; [
    buf
    docker
    docker-compose
    imagemagick
    podman
    postgresql
    yarn
  ];
}
