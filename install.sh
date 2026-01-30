#!/bin/bash
# TrustNet One-Liner Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/jcgarcia/TrustNet/main/install.sh | bash
# Version: 1.0.0
#

set -e

RAW_URL="https://raw.githubusercontent.com/Ingasti/trustnet-wip"
REPO_DIR="${HOME}/trustnet-setup"
BRANCH="${TRUSTNET_BRANCH:-main}"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║                                                          ║"
echo "║        TrustNet One-Liner Installer                      ║"
echo "║                                                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "Branch: $BRANCH"
echo ""

# Create directory structure
mkdir -p "$REPO_DIR"
cd "$REPO_DIR"

# Download latest scripts (always get fresh version)
echo "→ Downloading latest scripts..."

# Download setup-vms script
if ! curl -fsSL "$RAW_URL/$BRANCH/tools/setup-vms.sh?nocache=$(date +%s)" -o setup-vms.sh.tmp; then
    echo "ERROR: Failed to download setup-vms.sh"
    exit 1
fi
mv setup-vms.sh.tmp setup-vms.sh
chmod +x setup-vms.sh
sed -i 's/\r$//' setup-vms.sh 2>/dev/null || dos2unix setup-vms.sh 2>/dev/null || true

echo "✓ Scripts downloaded"
echo ""
echo "→ Starting VM setup..."
echo ""

# Run the setup script with --auto flag
exec ./setup-vms.sh --auto
