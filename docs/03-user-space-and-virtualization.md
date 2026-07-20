# User Space & Virtualization General Rules (home-manager)

## 1\. Lima Orchestration Rules

Home Manager is responsible for provisioning the virtualization layer.

-   Ensure `pkgs.lima` is installed via `home.packages`.
-   VM configurations will be written to `~/.config/lima/<vm-name>.yaml` using `xdg.configFile`.
-   ****Network Constraint:**** All VMs must explicitly define `portForwards: []` to disable default port forwarding. Remote access will be exclusively handled by the in-guest Tailscale daemon.

## 2\. The Daemonization Wrapper

Because the host macOS operates headlessly, VMs must automatically recover if the machine reboots.

-   For every defined VM, Home Manager must create a corresponding `launchd.agents.lima-<vm-name>`.
-   Set `RunAtLoad = true` and `KeepAlive = true` (to ensure it restarts on crash).
-   The `ProgramArguments` wrapper script must run Lima in the foreground for `launchd` supervision:
    
    if limactl list -q | grep -q "^<vm-name>$"; then  
      exec limactl start --foreground <vm-name>  
    else  
      exec limactl start --foreground ~/.config/lima/<vm-name>.yaml  
    fi
