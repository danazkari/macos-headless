{ config, pkgs, ... }:

let
  vmName = "linux-dev-machine";
  vmYamlPath = "${config.xdg.configHome}/lima/${vmName}.yaml";

  limaConfig = ''
    vmType: "vz"
    os: "Linux"
    arch: "aarch64"
    images:
      - location: "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-arm64.img"
        arch: "aarch64"
    cpus: 8
    memory: "8GiB"
    disk: "100GiB"
    portForwards: []
    provision:
      - mode: system
        script: |
          #!/bin/bash
          apt-get update && apt-get install -y curl vim git
          curl -fsSL https://tailscale.com/install.sh | sh
          if ! tailscale status &> /dev/null; then
            TS_AUTHKEY=$(cat /mnt/lima-secrets/tailscale_oauth_client_secret)
            tailscale up --authkey="$TS_AUTHKEY" --ssh --hostname=m1-linux-dev
          fi
    mounts:
      - location: "/var/lib/sops-nix/mountable"
        mountPoint: "/mnt/lima-secrets"
        writable: false
  '';

  wrapperScript = pkgs.writeShellScriptBin "lima-wrapper-${vmName}" ''
    export PATH=${pkgs.lima}/bin:$PATH

    # Copy SOPS secrets to a real directory so VZ can mount them
    # (Nix store symlinks can't be mounted by VZ)
    sudo mkdir -p /var/lib/sops-nix/mountable
    sudo cp /run/secrets/* /var/lib/sops-nix/mountable/ 2>/dev/null || true
    sudo chmod 755 /var/lib/sops-nix/mountable
    sudo chmod 444 /var/lib/sops-nix/mountable/*

    if limactl list -q | grep -q "^${vmName}$"; then
      exec limactl start --foreground ${vmName}
    else
      exec limactl start --foreground ${vmYamlPath}
    fi
  '';
in {
  xdg.configFile."lima/${vmName}.yaml".text = limaConfig;

  launchd.agents."lima-${vmName}" = {
    enable = true;
    config = {
      ProgramArguments = [ "${wrapperScript}/bin/lima-wrapper-${vmName}" ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
