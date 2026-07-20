#!/bin/bash
# scripts/setup.sh

echo "Bootstrapping Headless macOS Node..."

if [ ! -f "/var/lib/sops-nix/key.txt" ]; then
    echo "ERROR: SOPS Age key not found at /var/lib/sops-nix/key.txt"
    echo "Please create the directory and place your age key there before continuing."
    exit 1
fi

if ! command -v nix &> /dev/null; then
    echo "ERROR: Nix is not installed. Please install Nix first."
    exit 1
fi

echo "Building and applying Nix Darwin configuration..."
darwin-rebuild switch --flake .#m1-server

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo ""
    echo "========================================================="
    echo "Homebrew is not installed."
    echo "Please install it manually before continuing:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    echo "========================================================="
    echo ""
    read -p "Press Enter after Homebrew is installed to continue..."
fi

# Install Krew plugins
echo "Installing kubectl Krew plugins..."
if command -v kubectl &> /dev/null; then
    kubectl krew install ctx
    kubectl krew install ns
    kubectl krew install stern
    kubectl krew install kubecolor
    echo "Krew plugins installed."
else
    echo "WARNING: kubectl not found, skipping Krew plugin installation."
fi

echo "========================================================="
echo "SETUP COMPLETE"
echo "WARNING: Turn OFF FileVault (System Settings -> Privacy & Security -> FileVault)."
echo "ACTION REQUIRED: Ensure Auto-Login is enabled."
echo "ACTION REQUIRED: Enable Remote Login (SSH) (System Settings -> General -> Sharing)."
echo "ACTION REQUIRED: Configure your terminal to use 'FiraCode Nerd Font' for ligatures."
echo "========================================================="
