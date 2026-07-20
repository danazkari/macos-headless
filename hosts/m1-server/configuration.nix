{ pkgs, config, ... }: {
  system.stateVersion = 4;
  system.primaryUser = "dprado";
  nix.settings.experimental-features = "nix-command flakes";
  ids.gids.nixbld = 350;

  # User account
  users.users.dprado = {
    home = "/Users/dprado";
    shell = pkgs.zsh;
  };

  # Hardware / Power Config
  # TODO: Configure power settings once nix-darwin power module is stable
  # See: https://github.com/nix-darwin/nix-darwin/pull/1767

  # Host Tailscale
  services.tailscale.enable = true;

  # SOPS secrets for host
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.secrets.tailscale_oauth_client_id = {
    sopsFile = ../../secrets/secrets.yaml;
    owner = "root";
    group = "wheel";
    mode = "0400";
  };

  sops.secrets.tailscale_oauth_client_secret = {
    sopsFile = ../../secrets/secrets.yaml;
    owner = "root";
    group = "wheel";
    mode = "0400";
  };

  # Tailscale activation on boot (using pre-auth key)
  system.activationScripts.tailscale-auth = ''
    # Wait for tailscaled to be ready
    for i in $(seq 1 10); do
      if /run/current-system/sw/bin/tailscale status &>/dev/null; then
        break
      fi
      sleep 1
    done
    TAILSCALE_AUTH_KEY=$(cat /run/secrets/tailscale_oauth_client_secret)
    /run/current-system/sw/bin/tailscale up --authkey="$TAILSCALE_AUTH_KEY" --ssh --hostname=m1-host
  '';

  # Copy SOPS secrets to a real directory for VM mounting (Nix store symlinks can't be mounted by VZ)
  system.activationScripts.sops-mountable = ''
    mkdir -p /var/lib/sops-nix/mountable
    cp /run/secrets/* /var/lib/sops-nix/mountable/ 2>/dev/null || true
    chmod 755 /var/lib/sops-nix/mountable
    chmod 444 /var/lib/sops-nix/mountable/*
  '';

  # Homebrew
  homebrew = {
    enable = true;
    onActivation.autoUpdate = false;
    onActivation.upgrade = false;
    onActivation.cleanup = "zap";

    casks = [
      "font-fira-code-nerd-font"
    ];
  };

  # Battery Daemon import
  imports = [
    ./battery-daemon.nix
  ];
}
