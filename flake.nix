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
    LazyVim = {
      url = "github:matadaniel/LazyVim-module";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = inputs@{ self, darwin, nixpkgs, home-manager, sops-nix, LazyVim }: {
    darwinConfigurations."m1-server" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./hosts/m1-server/configuration.nix
        sops-nix.darwinModules.sops
        home-manager.darwinModules.home-manager
        LazyVim.homeManagerModules.default
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.dprado = import ./users/dprado/home.nix;
        }
      ];
    };
  };
}
