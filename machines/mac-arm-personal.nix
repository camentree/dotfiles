# ============================================================
# Apple Silicon Mac — personal laptop
# ============================================================
{ pkgs, ... }:

{
  nixpkgs.hostPlatform = "aarch64-darwin";

  environment.variables.NIX_MACHINE = "mac-arm-personal";

  # Personal packages
  environment.systemPackages = with pkgs; [
    cloudflared
  ];

  home-manager.users.camen = { config, ... }: {
    home.file.".zshrc.local" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/home/locals/zshrc-local-personal";
      force = true;
    };
  };
}
