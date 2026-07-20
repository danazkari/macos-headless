# Sample First VM Definition (`test-vm.nix`)

OpenCode should generate a `test-vm.nix` module for Home Manager that creates a fully functional development VM.

## 1\. Lima YAML Specification (`~/.config/lima/test-vm.yaml`)

-   ****OS:**** Ubuntu 24.04 server arm64.
-   ****Resources:**** 8 CPUs, 8GiB Memory, 100GiB Disk.
-   ****Networking:**** `portForwards: []` (All access must route through Tailscale).
-   ****Mounts:**** Map the host's `sops-nix` secret directory containing `tailscale_vm_auth_key` to `/mnt/lima-secrets` inside the VM.

## 2\. Provisioning Script

The `provision` block must run as `root` (system mode) and execute:

#!/bin/bash  
\# 1. Install prerequisites  
apt-get update && apt-get install -y curl vim git  
  
\# 2. Install Tailscale  
curl -fsSL \[https://tailscale.com/install.sh\](https://tailscale.com/install.sh) | sh  
  
\# 3. Read secret and authenticate safely (state-aware)  
if ! tailscale status &> /dev/null; then
  TS\_AUTHKEY=$(cat /mnt/lima-secrets/tailscale\_vm\_auth\_key)  
  tailscale up --authkey=$TS\_AUTHKEY --ssh --hostname=m1-test-node  
fi

## 3\. Daemonization

-   Create a Home Manager `launchd.agents.lima-test-vm` adhering to the wrapper logic defined in the `03-User-Space-and-VM.md` documentation.
