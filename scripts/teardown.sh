#!/bin/bash
# scripts/teardown.sh

echo "Tearing down Lima Linux Dev Machine..."

launchctl unload ~/Library/LaunchAgents/org.nixos.lima-linux-dev-machine.plist 2>/dev/null || true
limactl stop linux-dev-machine 2>/dev/null || true
limactl delete linux-dev-machine 2>/dev/null || true

echo "Teardown complete. VM destroyed."
