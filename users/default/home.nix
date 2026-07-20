{ config, pkgs, username ? "yourname", homeDir ? "/Users/yourname", lazyvim, ... }:

{
  home.username = username;
  home.homeDirectory = homeDir;
  home.stateVersion = "24.11";

  imports = [
    lazyvim.homeManagerModules.default
    ./vms/linux-dev-machine.nix
  ];

  # Core development tools
  home.packages = with pkgs; [
    # Rust
    cargo
    rustc
    rustfmt
    clippy

    # Go
    go
    gopls

    # Perl
    perl

    # Lua
    luajit
    lua5_4
    stylua

    # Node.js
    nodejs
    nodePackages.npm
    yarn
    pnpm

    # Python (ML stack)
    python3
    python3Packages.pip
    python3Packages.virtualenv
    python3Packages.numpy
    python3Packages.pandas
    python3Packages.scikit-learn
    python3Packages.matplotlib

    # Cloud & Kubernetes
    kubectl
    helm
    kubernetes-helm

    # Container tools (Podman, not Docker)
    podman
    podman-compose
    buildah
    skopeo

    # Database clients
    postgresql
    sqlite
    redis

    # Modern CLI tools
    ripgrep
    fd
    bat
    eza
    fzf
    jq
    yq
    tree
    htop
    tmux
    curl
    wget
    git

    # Nix tools
    nixpkgs-fmt
    nil
  ];

  # Tmux with Dracula theme
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    historyLimit = 100000;
    keyMode = "vi";
    extraConfig = ''
      # Dracula theme
      set -g @dracula-show-battery false
      set -g @dracula-show-ram-usage true
      set -g @dracula-refresh-rate 5
      set -g @dracula-show-powerline true
      
      # Status bar
      set -g status-position bottom
      set -g status-justify left
      set -g status-style 'bg=colour235'
      set -g status-left '#[fg=green,bold]#S '
      set -g status-right '#[fg=yellow]RAM: #{ram_percentage} #[fg=cyan]│ %H:%M '
    '';
  };

  # Zsh with Oh-My-Zsh
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    oh-my-zsh = {
      enable = true;
      theme = "agnoster";
      plugins = [ "git" "docker" "kubectl" "rust" "node" "python" ];
    };
    shellAliases = {
      ll = "ls -la";
      ".." = "cd ..";
      "..." = "cd ../..";
      vim = "nvim";
      vi = "nvim";
      cat = "bat";
      ls = "eza --icons";
      grep = "rg";
      find = "fd";
    };
  };

  # LazyVim (Neovim distribution)
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.lazyvim = {
    enable = true;
    extras = [
      "lazyvim.plugins.extras.lang.rust"
      "lazyvim.plugins.extras.lang.go"
      "lazyvim.plugins.extras.lang.lua"
      "lazyvim.plugins.extras.lang.nodejs"
      "lazyvim.plugins.extras.lang.python"
      "lazyvim.plugins.extras.lang.perl"
      "lazyvim.plugins.extras.lang.kubernetes"
    ];
  };

  # Git
  programs.git = {
    enable = true;
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
    };
  };

  # direnv for automatic nix-shell
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
