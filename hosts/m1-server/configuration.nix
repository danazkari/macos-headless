{ pkgs, config, ... }: {
  system.stateVersion = 4;
  nix.settings.experimental-features = "nix-command flakes";

  # Hardware / Power Config
  system.defaults.pmset = {
    sleep = 0;
    displaysleep = 0;
    powernap = 1;
    autorestart = 1; # Critical to boot headless after power failure
  };

  # Host Tailscale
  services.tailscale.enable = true;

  # SOPS secrets for host
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
