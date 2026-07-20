# Host System & Hardware Configuration (nix-darwin)

## 1\. macOS Power & Sleep Settings

-   Configure `system.defaults.pmset`: Set `sleep = 0`, `displaysleep = 0`, `powernap = 1`, and `autorestart = 1` (critical to boot headless after power failure).
-   Enable SSH natively: This must be done manually via GUI during setup (System Settings -> General -> Sharing -> Remote Login) to avoid macOS SIP/TCC blocks.

## 2\. Host Tailscale Integration

-   Enable the Tailscale daemon via `services.tailscale.enable = true;`.
-   Use a `nix-darwin` activation script (or an additional LaunchDaemon) to automatically authenticate the Mac host.
-   Read the `tailscale_host_auth_key` decrypted by `sops-nix` to run: `tailscale up --authkey=$(cat /path/to/host/secret) --ssh --hostname=m1-host`

## 3\. Battery Hysteresis Daemon

To prevent lithium-ion degradation while plugged in 24/7, implement a custom `LaunchDaemon`.

-   Create an immutable script using `pkgs.writeShellScriptBin`.
-   Logic: Read `/usr/bin/pmset -g batt`.
-   -   Lower bound: 40% (execute ON webhook if discharging).
    -   Upper bound: 80% (execute OFF webhook if charging).
-   The Smart Switch webhook URLs must be passed into the script via `sops-nix` decrypted paths.
-   Run this script via a system `LaunchDaemon` (Label: `org.nixos.battery-manager`) every 5 minutes.
