{ pkgs, ... }: {
  home.stateVersion = "24.05";
  home.username = "dprado";
  home.homeDirectory = "/Users/dprado";

  home.packages = with pkgs; [
    # Virtualization
    lima

    # Languages
    rustc
    cargo
    go
    golangci-lint
    perl
    lua
    luajit
    nodejs
    yarn
    pnpm

    # Python ML stack
    python3
    python3Packages.pip
    uv
    ruff
    pyright
    python3Packages.jupyter
    python3Packages.notebook
    python3Packages.ipython

    # Dev tools
    neovim
    ripgrep
    fd
    jq
    yq
    tree
    htop
    btop
    git
    gh
    lazygit
    direnv

    # Kubernetes
    kubectl
    kubectx
    kubens
    stern
    helm

    # Containers (Podman only, no Docker)
    podman
    podman-compose
    buildah
    skopeo

    # Database tools
    postgresql
    sqlite
    redis
  ];

  # Tmux with Dracula theme
  programs.tmux = {
    enable = true;
    clock24 = true;
    mouse = true;
    terminal = "tmux-256color";
    keyMode = "vi";
    historyLimit = 50000;
    baseIndex = 1;

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      {
        plugin = dracula;
        extraConfig = ''
          set -g @dracula-plugins "ram-usage git kubernetes-context time"
          set -g @dracula-ram-usage-label "󰍛 "
          set -g @dracula-show-powerline true
          set -g @dracula-military-time true
          set -g @dracula-show-left-icon session
          set -g @dracula-border-contrast true
        '';
      }
    ];

    extraConfig = ''
      # Split panes using | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # Switch panes using Alt-arrow without prefix
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # Enable true color
      set -ga terminal-overrides ",*256col*:Tc"

      # Status bar styling
      set -g status-position bottom
      set -g status-justify left
      set -g status-style "bg=#1e1e2e"
    '';
  };

  # Zsh with Oh-My-Zsh
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    oh-my-zsh = {
      enable = true;
      theme = "agnoster";
      plugins = [
        "git"
        "kubectl"
        "kubectx"
        "kubens"
        "podman"
        "python"
        "rust"
        "golang"
        "node"
        "tmux"
        "history"
        "sudo"
        "direnv"
      ];
    };

    shellAliases = {
      ll = "ls -la";
      la = "ls -A";
      l = "ls -CF";
      ns = "darwin-rebuild switch --flake ~/projects/macos-headless";
      k = "kubectl";
      kgp = "kubectl get pods";
      kgs = "kubectl get services";
      kgn = "kubectl get nodes";
      kns = "kubectl get namespaces";
      pod = "podman";
      dc = "podman-compose";
    };

    initExtra = ''
      # Krew path
      export PATH="''${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
    '';
  };

  # Neovim with LazyVim
  programs.lazyvim = {
    enable = true;

    extras = {
      coding = {
        yanky.enable = true;
      };

      editor = {
        neo-tree.enable = true;
        telescope.enable = true;
        which-key.enable = true;
      };

      lang = {
        nix.enable = true;
        python.enable = true;
        go.enable = true;
        rust.enable = true;
        typescript.enable = true;
        lua.enable = true;
        yaml.enable = true;
        json.enable = true;
        markdown.enable = true;
      };

      ui = {
        alpha.enable = true;
      };

      util = {
        dot.enable = true;
      };
    };
  };

  # Podman (Docker-compatible, daemonless)
  programs.podman = {
    enable = true;
  };

  # Krew path
  home.sessionVariables = {
    KREW_ROOT = "\${HOME}/.krew";
  };

  imports = [
    ./vms/linux-dev-machine.nix
  ];
}
