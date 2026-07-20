# Flake Structure & Dependencies

## 1\. Flake Inputs

The `flake.nix` must define the following inputs:

-   `nixpkgs`: standard `nixpkgs-unstable`.
-   `darwin`: `nix-darwin` matching the `nixpkgs` branch.
-   `home-manager`: matching the `nixpkgs` branch.
-   `sops-nix`: For declarative secret decryption.

## 2\. Target Repository Structure

OpenCode should generate the code following this modular structure:

.  
├── flake.nix                   
├── flake.lock  
├── .sops.yaml                  
├── scripts/  
│   ├── setup.sh              # Bootstraps the Mac, imports age keys, builds flake  
│   └── teardown.sh           # Safely halts the VM and cleans up state  
├── secrets/  
│   └── secrets.yaml          # Encrypted SOPS file  
├── hosts/  
│   └── m1-server/  
│       ├── configuration.nix # The nix-darwin system module (includes host Tailscale)  
│       └── battery-daemon.nix# Battery hysteresis logic  
└── users/  
    └── primaryuser/  
        ├── home.nix          # Home Manager user module  
        └── vms/  
            └── test-vm.nix   # The specific VM definition and LaunchAgent
