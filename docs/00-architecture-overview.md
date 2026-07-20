# Project Specification: Headless macOS Virtualization Node

## 1\. System Context & Goals

The objective is to transform an Apple Silicon (M1 Pro) MacBook into a headless, zero-maintenance virtualization server. The entire system state will be defined in a Git repository using Nix Flakes (`nix-darwin` for the host, `home-manager` for the user environment).

## 2\. Dual-Tailscale Architecture

To ensure maximum resilience and security, the system utilizes a "Best of Both Worlds" Tailscale deployment:

-   ****Host Level (God Mode):**** Tailscale runs natively on the macOS host via `nix-darwin`. The administrator connects to the Mac's Tailscale IP to manage the host hardware, daemons, and debug Lima if it crashes.
-   ****Guest Level (Associate Access):**** Tailscale runs independently __inside__ the Ubuntu VM. The VM gets its own distinct IP and hostname on the Tailnet. Associates connect directly to the VM via Tailscale SSH, remaining entirely sandboxed from the macOS host.

> **Operational Fallback Note:** Because VMs do not expose local SSH ports, if the guest Tailscale fails, the fallback is to SSH into the macOS Host via its Tailscale IP and run `limactl shell <vm-name>` to gain a local root shell for debugging.

## 3\. Infrastructure as Code (GitOps) Core Principles

-   ****Declarative:**** Every package, daemon, and VM configuration must be defined in Nix.
-   ****Stateless Boot:**** Daemons and VMs must spin up automatically on power-cycle without GUI interaction.
-   ****Secretless Repo:**** No plaintext secrets in the Git repo. Use `sops-nix` with the `age` cryptographic backend.
