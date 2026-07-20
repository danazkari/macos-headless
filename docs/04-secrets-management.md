Secrets Management (sops-nix)

1. Global Configuration

The repository root must contain a .sops.yaml mapping the regex secrets/.*\.yaml$ to an age public key.

2. Expected Secrets in secrets.yaml

OpenCode must write the modules to expect and decrypt the following keys:

tailscale_host_auth_key: Used by nix-darwin to authenticate the Mac (must be marked Reusable in admin console).

tailscale_vm_auth_key: Used by the Lima guest (must be marked Reusable in admin console).

smart_switch_on_url: Used by the Battery Daemon.

smart_switch_off_url: Used by the Battery Daemon.

3. Secret Plumbing Context

Host Secrets: Decrypted to /run/secrets/ on the Mac host for darwin.nix consumption.

VM Secrets: For the tailscale_vm_auth_key, Home Manager must configure Lima to mount the directory containing this decrypted secret into the VM as read-only. This securely bridges the gap, allowing the VM's provisioning script to authenticate on first boot.
