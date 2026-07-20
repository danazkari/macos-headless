{
  description = "Headless macOS Virtualization Node";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, darwin, nixpkgs, home-manager, sops-nix, ... }: {
    darwinConfigurations."m1-server" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./hosts/m1-server/configuration.nix
        sops-nix.darwinModules.sops
        home-manager.darwinModules.home-manager
        ({
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "before-nix-darwin";
          home-manager.users.dprado = import ./users/default/home.nix;
        })
      ];
    };
  };
}
