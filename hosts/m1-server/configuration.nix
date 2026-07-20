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

  # Tailscale activation on boot (using OAuth client - never expires)
  system.activationScripts.tailscale-auth = ''
    TAILSCALE_OAUTH_SECRET=$(cat ${config.sops.secrets.tailscale_oauth_client_secret.path})
    /run/current-system/sw/bin/tailscale up --authkey="$TAILSCALE_OAUTH_SECRET" --ssh --hostname=m1-host
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
