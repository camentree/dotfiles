{
  description = "Camen's machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    parallax.url = "path:/Users/camen/Projects/parallax";
    parallax.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, parallax, ... }:
    let
      homeManagerModule = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "pre-nix-backup";
        home-manager.users.camen = import ./user.nix;
      };
      darwinModules = home-manager.darwinModules.home-manager;
    in {
      darwinConfigurations = {

        # Intel MacBook Pro — home server
        "mac-intel-server" = nix-darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          modules = [ ./os/macos.nix ./machines/mac-intel-server.nix parallax.darwinModules.default darwinModules homeManagerModule ];
        };

        # Apple Silicon — personal laptop
        "mac-arm-personal" = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [ ./os/macos.nix ./machines/mac-arm-personal.nix darwinModules homeManagerModule ];
        };

        # Apple Silicon — work laptop
        "mac-arm-work" = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [ ./os/macos.nix ./machines/mac-arm-work.nix darwinModules homeManagerModule ];
        };

      };
    };
}
