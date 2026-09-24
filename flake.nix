{
  description = "machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }:
    let
      homeManagerModule = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "pre-nix-backup";
        home-manager.users.camen = import ./user.nix;
      };
    in {
      darwinConfigurations = {

        "mac-intel-server" = nix-darwin.lib.darwinSystem {
          modules = [ ./os/macos.nix ./machines/mac-intel-server.nix home-manager.darwinModules.home-manager homeManagerModule ];
        };

        "mac-arm-server" = nix-darwin.lib.darwinSystem {
          modules = [ ./os/macos.nix ./machines/mac-arm-server.nix home-manager.darwinModules.home-manager homeManagerModule ];
        };

        "mac-arm-personal" = nix-darwin.lib.darwinSystem {
          modules = [ ./os/macos.nix ./machines/mac-arm-personal.nix home-manager.darwinModules.home-manager homeManagerModule ];
        };

        "mac-arm-work" = nix-darwin.lib.darwinSystem {
          modules = [ ./os/macos.nix ./machines/mac-arm-work.nix home-manager.darwinModules.home-manager homeManagerModule ];
        };

      };
    };
}
