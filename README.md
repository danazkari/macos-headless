# Headless macOS Virtualization Node

A fully declarative, GitOps-managed headless macOS server running Ubuntu VMs via Lima, with Tailscale VPN for remote access.

## Overview

This project transforms an Apple Silicon MacBook into a zero-maintenance, headless virtualization server. The entire system state is defined in a Git repository using Nix Flakes:

- **Host**: `nix-darwin` manages macOS system settings, Tailscale, and daemons
- **User Environment**: `home-manager` manages development tools, shell, editor, and VMs
- **VMs**: Lima runs Ubuntu VMs with Apple Virtualization.Framework (vz)
- **Secrets**: `sops-nix` with age encryption for all credentials
- **Networking**: Dual Tailscale architecture (host + guest) for secure remote access

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    macOS Host (M1 Pro)                  │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  nix-darwin (configuration.nix)                  │  │
│  │  - Power management (headless boot)              │  │
│  │  - Tailscale daemon (m1-host)                    │  │
│  │  - Battery hysteresis daemon                     │  │
│  │  - Homebrew (Nerd Fonts)                         │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  home-manager (home.nix)                         │  │
│  │  - Lima + VM definitions                         │  │
│  │  - Dev tools (Rust, Go, Python, Node, etc.)      │  │
│  │  - Tmux + Dracula theme                          │  │
│  │  - Oh-My-Zsh + agnoster theme                    │  │
│  │  - Neovim + LazyVim                              │  │
│  │  - Podman (no Docker)                            │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Lima VM (linux-dev-machine)                            │  │
│  │  - Ubuntu 24.04 ARM64                            │  │
│  │  - 8 CPU / 8GB RAM / 100GB disk                  │  │
│  │  - Tailscale (m1-linux-dev)                      │  │
│  │  - Accessible via Tailscale SSH                  │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Dual-Tailscale Architecture

| Level | Host | Guest (VM) |
|-------|------|------------|
| **Tailscale Hostname** | `m1-host` | `m1-linux-dev` |
| **Access** | Admin/management | Associate/sandboxed |
| **SSH** | Direct SSH | Tailscale SSH |
| **Fallback** | N/A | `limactl shell linux-dev-machine` via host |

**Operational Note**: If the guest Tailscale fails, SSH into the host via its Tailscale IP and run `limactl shell <vm-name>` to debug.

## Repository Structure

```
.
├── flake.nix                          # Flake definition (inputs + outputs)
├── flake.lock                         # Pinned dependencies
├── .sops.yaml                         # SOPS encryption rules
├── scripts/
│   ├── setup.sh                       # Bootstrap script for fresh Mac
│   └── teardown.sh                    # Destroy VM and clean state
├── secrets/
│   └── secrets.yaml                   # Encrypted secrets (SOPS)
├── hosts/
│   └── m1-server/
│       ├── configuration.nix          # nix-darwin system config
│       └── battery-daemon.nix         # Battery hysteresis daemon
└── users/
    └── dprado/
        ├── home.nix                   # Home Manager user config
        └── vms/
            └── linux-dev-machine.nix # Lima VM definition
```

## Prerequisites

- Apple Silicon Mac (M1/M2/M3)
- macOS fresh install or factory reset
- Internet connection
- Another machine on the same network (for initial SSH)

## Complete Setup Guide

### Phase 1: Initial Mac Setup (Manual)

1. **Complete macOS Setup Assistant**
   - Create your user account (e.g., `dprado`)
   - Skip Apple ID if desired (can add later)

2. **Enable Remote Login (SSH)**
   - System Settings → General → Sharing → Remote Login → ON
   - Note the SSH command shown (e.g., `ssh dprado@192.168.x.x`)

3. **Set Up SSH Key Authentication** (recommended over passwords)

   From your other machine, copy your public key to the Mac:

   ```bash
   # If you don't have an SSH key yet, generate one:
   ssh-keygen -t ed25519 -C "your-email@example.com"

   # Copy your public key to the Mac:
   ssh-copy-id dprado@<mac-ip>
   ```

   Enter your password when prompted. After this, you can SSH without passwords:

   ```bash
   ssh dprado@<mac-ip>
   ```

   **Verify it works** (should connect without asking for password):

   ```bash
   ssh dprado@<mac-ip> "echo 'SSH key auth works!'"
   ```

4. **Disable Sleep/Auto-Lock**
   - System Settings → Lock Screen → Turn OFF all options:
     - "Turn display off on battery when inactive" → Never
     - "Turn display off on power adapter when inactive" → Never
     - "Require password after screen saver begins" → Never

4. **Enable Auto-Login**
   - System Settings → Users & Groups → Automatic login → Select your user

5. **Turn OFF FileVault** (critical for headless boot)
   - System Settings → Privacy & Security → FileVault → Turn Off
   - **WARNING**: If FileVault is on, the Mac cannot boot headlessly after power failure

### Phase 2: Install Nix (SSH into the Mac)

From another machine, SSH into your Mac:

```bash
ssh dprado@<mac-ip>
```

Install Nix (multi-user, recommended for macOS):

```bash
sh <(curl -L https://nixos.org/nix/install)
```

When prompted, type `yes` to proceed.

Add flakes support:

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

Restart your shell:

```bash
source ~/.zshrc
```

Verify installation:

```bash
nix --version
```

### Phase 3: Clone Repository & Place Secrets

Clone the repository:

```bash
cd ~
git clone <your-repo-url> projects/macos-headless
cd projects/macos-headless
```

Create the age key directory:

```bash
sudo mkdir -p /var/lib/sops-nix
sudo chown $(whoami) /var/lib/sops-nix
```

Generate an age key pair:

```bash
nix-shell -p age --run "age-keygen -o /var/lib/sops-nix/key.txt"
```

Copy the **public key** from the output. It will look like:

```
Public key: age1aydc8plt60r6gcyedfxd9dtqmlh2u493yy8gr0eznvtycr5ytqxse3drfl
```

If your public key is different from what's in `.sops.yaml`, update it:

```bash
nano .sops.yaml
```

Replace the public key with yours, then set permissions:

```bash
sudo chmod 600 /var/lib/sops-nix/key.txt
```

### Phase 4: Create Tailscale OAuth Client

1. Go to: **https://login.tailscale.com/admin/settings/oauth**

2. Click **Generate OAuth client...**

3. Fill in:
   - **Description**: `m1-headless-server`
   - **Scopes**:
     - ☑️ Devices: Core (read + write)
     - ☑️ Keys: Auth Keys (read + write)

4. Click **Generate client**

5. **Copy immediately** (shown only once!):
   - **Client ID**: `k10...`
   - **Client Secret**: `tskey-client-...`

6. Edit your secrets file:

```bash
sops secrets/secrets.yaml
```

7. Replace the placeholder values:

```yaml
tailscale_oauth_client_id: "k10YOUR_CLIENT_ID_HERE"
tailscale_oauth_client_secret: "tskey-client-YOUR_CLIENT_SECRET_HERE"
smart_switch_on_url: "https://your-smart-switch-webhook/on"
smart_switch_off_url: "https://your-smart-switch-webhook/off"
```

8. Save and exit:
   - Vim: `:wq`
   - Nano: `Ctrl+O`, `Enter`, `Ctrl+X`

**Note**: The `smart_switch_on_url` and `smart_switch_off_url` are for the battery daemon. If you're not using a smart switch for battery management, you can leave them as placeholder values.

### Phase 5: Generate Lock File & Run Setup

Generate the flake.lock file (pins all dependencies):

```bash
cd ~/projects/macos-headless
nix flake lock
```

Run the setup script:

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

The script will:
1. Verify age key exists
2. Verify Nix is installed
3. Run `darwin-rebuild switch --flake .#m1-server`
4. Prompt to install Homebrew if needed
5. Install kubectl Krew plugins

### Phase 6: Post-Setup Configuration

**Install Homebrew** (if prompted):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Install Krew plugins** (if not done by script):

```bash
kubectl krew install ctx
kubectl krew install ns
kubectl krew install stern
kubectl krew install kubecolor
```

**Configure Terminal Font**:

1. Open Terminal → Settings → Profiles → Text
2. Set Font to **FiraCode Nerd Font** (size 14 recommended)
3. Enable ligatures if desired

### Phase 7: Verify Everything

Check Tailscale status:

```bash
tailscale status
```

You should see:

```
m1-host        user@     linux   -
m1-linux-dev   user@     linux   -
```

Check Lima VM:

```bash
limactl list
```

Expected output:

```
NAME       STATUS     SSH                VMTYPE    ARCH      CPUS    MEMORY    DISK      DIR
linux-dev-machine  Running    127.0.0.1:60022    vz        aarch64   8       8GiB      100GiB    ~/.lima/linux-dev-machine
```

SSH into the VM via Tailscale:

```bash
ssh m1-linux-dev
```

Or from your other machine:

```bash
ssh m1-host    # First hop to the Mac
ssh m1-linux-dev      # Then to the VM
```

### Phase 8: Enable Headless Boot

**Critical**: Turn OFF FileVault

- System Settings → Privacy & Security → FileVault → Turn Off

**Test reboot**:

1. Shut down the Mac: `sudo shutdown -h now`
2. Unplug power for 10 seconds
3. Plug back in
4. Wait 2-3 minutes for boot
5. Check Tailscale from another machine: `tailscale status`
6. Both `m1-host` and `m1-linux-dev` should appear

## Secrets Management

### How SOPS Works

- **Public key** (in `.sops.yaml`): Used to encrypt files
- **Private key** (at `/var/lib/sops-nix/key.txt`): Used to decrypt on the Mac

### Editing Secrets

```bash
sops secrets/secrets.yaml
```

### Secrets in This Project

| Secret | Purpose |
|--------|---------|
| `tailscale_oauth_client_id` | Tailscale OAuth client identifier (reference only) |
| `tailscale_oauth_client_secret` | Tailscale OAuth client secret (never expires) |
| `smart_switch_on_url` | Webhook URL to turn ON smart switch (battery daemon) |
| `smart_switch_off_url` | Webhook URL to turn OFF smart switch (battery daemon) |

### Adding New Secrets

1. Add to `secrets/secrets.yaml` (via `sops`)
2. Add sops config in the consuming module:

```nix
sops.secrets.my_new_secret = {
  sopsFile = ../../secrets/secrets.yaml;
  owner = "root";
  group = "wheel";
  mode = "0400";
};
```

3. Reference in your config:

```nix
MY_VAR=$(cat ${config.sops.secrets.my_new_secret.path})
```

## Development Environment

### Installed Languages

| Language | Packages |
|----------|----------|
| **Rust** | rustc, cargo |
| **Go** | go, golangci-lint |
| **Python** | python3, pip, uv, ruff, pyright, jupyter, notebook, ipython |
| **Node.js** | nodejs, yarn, pnpm |
| **Lua** | lua, luajit |
| **Perl** | perl |

### Dev Tools

- **Editor**: Neovim + LazyVim (with language extras for Python, Go, Rust, Nix, TypeScript, Lua, YAML, JSON, Markdown)
- **Terminal Multiplexer**: Tmux with Dracula theme (RAM usage, git, kubernetes context, time)
- **Shell**: Zsh with Oh-My-Zsh (agnoster theme, 13 plugins)
- **Version Control**: git, gh (GitHub CLI), lazygit
- **Search**: ripgrep, fd
- **JSON/YAML**: jq, yq
- **Containers**: Podman, podman-compose, buildah, skopeo (no Docker)
- **Kubernetes**: kubectl, kubectx, kubens, stern, helm, krew plugins (ctx, ns, stern, kubecolor)
- **Database**: PostgreSQL, SQLite, Redis

### Tmux Keybindings

| Key | Action |
|-----|--------|
| `Ctrl+b` | Prefix key |
| `Prefix + \|` | Split pane horizontally |
| `Prefix + -` | Split pane vertically |
| `Alt + Arrow` | Switch panes (no prefix needed) |
| `Prefix + c` | New window |
| `Prefix + n/p` | Next/previous window |
| `Prefix + 1-9` | Switch to window by number |

### Zsh Aliases

| Alias | Command |
|-------|---------|
| `ns` | `darwin-rebuild switch --flake ~/projects/macos-headless` |
| `k` | `kubectl` |
| `kgp` | `kubectl get pods` |
| `kgs` | `kubectl get services` |
| `kgn` | `kubectl get nodes` |
| `kns` | `kubectl get namespaces` |
| `pod` | `podman` |
| `dc` | `podman-compose` |

## VM Management

### List VMs

```bash
limactl list
```

### Stop a VM

```bash
limactl stop linux-dev-machine
```

### Start a VM

```bash
limactl start linux-dev-machine
```

### Shell into a VM

```bash
limactl shell linux-dev-machine
```

### Delete a VM

```bash
limactl delete linux-dev-machine
```

### Tear Down Everything

```bash
./scripts/teardown.sh
```

This will:
1. Unload the LaunchAgent
2. Stop the VM
3. Delete the VM disk and state

## Rebuilding After Changes

After modifying any Nix files, rebuild:

```bash
# Quick alias (if zsh is configured)
ns

# Or full command
darwin-rebuild switch --flake .#m1-server
```

## Troubleshooting

### VM won't start

```bash
# Check Lima status
limactl list

# Check VM logs
limactl logs linux-dev-machine

# Try starting manually
limactl start linux-dev-machine --foreground
```

### Tailscale not connecting

```bash
# Check Tailscale status
tailscale status

# Check Tailscale logs
journalctl -u tailscaled

# Manually authenticate
sudo tailscale up --authkey=<your-oauth-client-secret> --ssh --hostname=m1-host
```

### Nix build fails

```bash
# Check flake structure
nix flake check

# Update flake.lock
nix flake update

# Rebuild with verbose output
darwin-rebuild switch --flake .#m1-server --show-trace
```

### SOPS decryption fails

```bash
# Verify key exists
ls -la /var/lib/sops-nix/key.txt

# Test decryption
sops secrets/secrets.yaml

# Check .sops.yaml matches your public key
cat .sops.yaml
```

### Homebrew not installing casks

```bash
# Verify Homebrew is installed
brew --version

# Manually run brew bundle
brew bundle --file=$(nix build --print-out-paths .#darwinConfigurations.m1-server.config.system.build.toplevel)/sw/bin/brewfile
```

## Battery Management (Optional)

The battery daemon prevents lithium-ion degradation when the Mac is plugged in 24/7.

### How It Works

1. Reads battery level every 5 minutes
2. If battery ≤ 40% and discharging → sends ON webhook to smart switch
3. If battery ≥ 80% and charging → sends OFF webhook to smart switch

### Configuring Smart Switch

1. Set up your smart switch with webhooks
2. Add webhook URLs to `secrets/secrets.yaml`:

```yaml
smart_switch_on_url: "https://your-switch-api/on"
smart_switch_off_url: "https://your-switch-api/off"
```

3. Rebuild:

```bash
darwin-rebuild switch --flake .#m1-server
```

### Testing the Daemon

```bash
# Check daemon status
launchctl list | grep battery-manager

# Run manually
sudo /run/current-system/sw/bin/battery-monitor

# Check logs
log show --predicate 'process == "battery-monitor"' --last 1h
```

## Customization

### Adding a New VM

This section covers creating new Lima VMs declaratively with Nix.

#### Step 1: Create the VM Module

Create a new file at `users/dprado/vms/my-vm.nix`:

```nix
{ config, pkgs, ... }:

let
  vmName = "my-vm";
  vmYamlPath = "${config.xdg.configHome}/lima/${vmName}.yaml";

  limaConfig = ''
    vmType: "vz"
    os: "Linux"
    arch: "aarch64"
    images:
      - location: "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-arm64.img"
        arch: "aarch64"
    cpus: 4
    memory: "4GiB"
    disk: "50GiB"
    portForwards: []
    mounts:
      - location: "/run/secrets"
        mountPoint: "/mnt/lima-secrets"
        writable: false
    provision:
      - mode: system
        script: |
          #!/bin/bash
          apt-get update && apt-get install -y curl vim git
          curl -fsSL https://tailscale.com/install.sh | sh
          
          if ! tailscale status &> /dev/null; then
            TS_AUTHKEY=$(cat /mnt/lima-secrets/tailscale_oauth_client_secret)
            tailscale up --authkey=$TS_AUTHKEY --ssh --hostname=my-vm-node
          fi
  '';

  wrapperScript = pkgs.writeShellScriptBin "lima-wrapper-${vmName}" ''
    export PATH=${pkgs.lima}/bin:$PATH
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
```

#### Step 2: Import the Module

Edit `users/dprado/home.nix` and add to the imports:

```nix
imports = [
  ./vms/linux-dev-machine.nix
  ./vms/my-vm.nix  # Add this line
];
```

#### Step 3: Rebuild

```bash
darwin-rebuild switch --flake .#m1-server
```

The VM will start automatically on next boot (or immediately if you start it manually).

#### VM Configuration Options

**Basic Settings:**

| Option | Description | Example |
|--------|-------------|---------|
| `vmType` | Virtualization type | `vz` (Apple Virtualization) or `qemu` |
| `os` | Operating system | `Linux` or `Darwin` |
| `arch` | CPU architecture | `aarch64` (Apple Silicon) or `x86_64` |
| `cpus` | Number of CPU cores | `4`, `8` |
| `memory` | RAM allocation | `4GiB`, `8GiB`, `16GiB` |
| `disk` | Disk size | `50GiB`, `100GiB` |

**Networking:**

```yaml
portForwards: []  # Disable all port forwarding (use Tailscale instead)
```

**Mounting Host Directories:**

```yaml
mounts:
  - location: "/run/secrets"           # Host path
    mountPoint: "/mnt/lima-secrets"    # Guest path
    writable: false                    # Read-only
  - location: "/Users/dprado/projects"
    mountPoint: "/home/ubuntu/projects"
    writable: true                     # Read-write
```

**Provisioning Scripts:**

Run commands on first boot:

```yaml
provision:
  - mode: system  # Run as root
    script: |
      #!/bin/bash
      apt-get update && apt-get install -y docker.io
  - mode: user    # Run as user
    script: |
      #!/bin/bash
      curl -fsSL https://starship.rs/install.sh | sh
```

#### Common VM Configurations

**Development VM (lightweight):**

```yaml
cpus: 2
memory: "2GiB"
disk: "20GiB"
```

**ML/AI VM (heavy):**

```yaml
cpus: 8
memory: "16GiB"
disk: "200GiB"
```

**Database VM:**

```yaml
cpus: 4
memory: "8GiB"
disk: "100GiB"
provision:
  - mode: system
    script: |
      #!/bin/bash
      apt-get update && apt-get install -y postgresql redis-server
```

#### Managing VMs

**List all VMs:**

```bash
limactl list
```

**Start/Stop/Delete:**

```bash
limactl start my-vm
limactl stop my-vm
limactl delete my-vm
```

**Shell into VM:**

```bash
limactl shell my-vm
```

**View logs:**

```bash
limactl logs my-vm
```

**Manual start (foreground):**

```bash
limactl start --foreground my-vm
```

#### Adding Tailscale to a VM

The provisioning script automatically installs and authenticates Tailscale. The VM gets its own IP on the Tailnet with a unique hostname.

To customize the Tailscale hostname, change `--hostname=my-vm-node` in the provisioning script.

#### Removing a VM

1. Delete the VM module file (`users/dprado/vms/my-vm.nix`)
2. Remove the import from `users/dprado/home.nix`
3. Rebuild: `darwin-rebuild switch --flake .#m1-server`
4. The LaunchAgent will be removed, but the VM disk may persist. Clean up manually:

```bash
limactl stop my-vm 2>/dev/null || true
limactl delete my-vm 2>/dev/null || true
rm -rf ~/.lima/my-vm
```

#### Troubleshooting VMs

**VM won't start:**

```bash
# Check if resources are available
limactl list

# Start with verbose output
limactl start my-vm --foreground 2>&1 | tee /tmp/vm-debug.log

# Check macOS virtualization support
system_profiler SPFrameworksDataType | grep -i virtual
```

**Tailscale not connecting in VM:**

```bash
# Shell into VM
limactl shell my-vm

# Check Tailscale status
tailscale status

# Manually authenticate
sudo tailscale up --authkey=<oauth-client-secret> --ssh --hostname=my-vm-node
```

**VM networking issues:**

```bash
# Check port forwarding (should be empty for Tailscale-only setup)
limactl list | grep my-vm

# Test connectivity from host
ping <vm-tailscale-ip>

# Test from another machine on Tailnet
ssh my-vm-node
```

**Disk space issues:**

```bash
# Check disk usage
limactl list

# Resize disk (requires VM rebuild)
# Edit the VM module, change disk size, then rebuild
```

### Adding New Packages

Edit `users/dprado/home.nix` and add to `home.packages`:

```nix
home.packages = with pkgs; [
  # ... existing packages ...
  my-new-package
];
```

Then rebuild.

### Changing Tmux Theme

Edit the Dracula config in `users/dprado/home.nix`:

```nix
plugin = dracula;
extraConfig = ''
  # Change plugins displayed
  set -g @dracula-plugins "ram-usage cpu-usage git time"
  
  # Change colors
  set -g @dracula-cpu-usage-colors "pink dark_gray"
  set -g @dracula-ram-usage-colors "cyan dark_gray"
'';
```

### Adding LazyVim Extras

Edit `users/dprado/home.nix` and add to `programs.lazyvim.extras`:

```nix
extras = {
  # ... existing extras ...
  lang = {
    # ... existing languages ...
    terraform.enable = true;
    helm.enable = true;
  };
};
```

## Security Considerations

1. **Never commit plaintext secrets** - Always use `sops` to encrypt
2. **Rotate OAuth client secret** if compromised (create new one in Tailscale admin)
3. **Disable FileVault** for headless boot (security trade-off)
4. **Use Tailscale SSH** instead of direct SSH when possible
5. **Keep NixOS/nix-darwin updated** for security patches

## Contributing

1. Create a feature branch
2. Make changes
3. Test on a Mac with this setup
4. Submit a pull request

## License

[Your License Here]

## Acknowledgments

- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [home-manager](https://github.com/nix-community/home-manager)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [Lima](https://lima-vm.io/)
- [Tailscale](https://tailscale.com/)
- [LazyVim](https://github.com/matadaniel/LazyVim-module)
- [Dracula Tmux](https://github.com/dracula/tmux)
