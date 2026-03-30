{
  description = "Camen's machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }:
    let
      homeManagerModule = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "pre-nix-backup";
        home-manager.users.camen = import ./shell.nix;
      };
    in {
      # Intel MacBook Pro — home server
      darwinConfigurations."server" = nix-darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        modules = [
          ./macos.nix
          ./hosts/server.nix
          home-manager.darwinModules.home-manager
          homeManagerModule
        ];
      };

      # Apple Silicon MacBook — work machine (uncomment when ready)
      # darwinConfigurations."work" = nix-darwin.lib.darwinSystem {
      #   system = "aarch64-darwin";
      #   modules = [
      #     ./macos.nix
      #     ./hosts/work.nix
      #     home-manager.darwinModules.home-manager
      #     homeManagerModule
      #   ];
      # };
    };
}
