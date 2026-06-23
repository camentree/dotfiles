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
    krunkit
    postgresql
    yarn
  ];

  # mise — version manager for node / java / sbt. Work machine only.
  # Writes ~/.config/mise/config.toml; shell activation lives in home/zshenv
  # (zsh here is a hand-managed dotfile, not home-manager's programs.zsh).
  home-manager.users.camen.programs.mise = {
    enable = true;
    enableZshIntegration = false;
    globalConfig = {
      tools = {
        java = "temurin-17.0.16+8";
        node = "lts";
        sbt = "1.12.5";
      };
      settings = {
        # Honor .nvmrc / .node-version (e.g. august-frontend pins Node there, not .tool-versions)
        idiomatic_version_file_enable_tools = [ "node" ];
      };
    };
  };
}
