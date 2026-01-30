#!/bin/bash
#
# TrustNet One-Liner Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/jcgarcia/TrustNet/main/install.sh | bash
#

set -e

REPO_URL="https://github.com/Ingasti/trustnet-wip.git"
RAW_URL="https://raw.githubusercontent.com/Ingasti/trustnet-wip"
REPO_DIR="$HOME/trustnet-setup"
BRANCH="${TRUSTNET_BRANCH:-main}"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║                                                          ║"
echo "║        TrustNet One-Liner Installer                      ║"
echo "║        Phase 2: QEMU VM Setup                            ║"
echo "║                                                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "Branch: $BRANCH"
echo "Setup directory: $REPO_DIR"
echo ""

# Create directory structure
mkdir -p "$REPO_DIR"
cd "$REPO_DIR"

# Download Phase 2 setup script
echo "→ Downloading TrustNet Phase 2 setup..."

if ! curl -fsSL "$RAW_URL/$BRANCH/tools/phase2-qemu-setup.sh?nocache=$(date +%s)" -o phase2-qemu-setup.sh.tmp; then
    echo "ERROR: Failed to download Phase 2 setup script"
    exit 1
fi

mv phase2-qemu-setup.sh.tmp phase2-qemu-setup.sh
chmod +x phase2-qemu-setup.sh
sed -i 's/\r$//' phase2-qemu-setup.sh 2>/dev/null || dos2unix phase2-qemu-setup.sh 2>/dev/null || true

echo "✓ Phase 2 setup downloaded"
echo ""
echo "→ Starting Phase 2 installation..."
echo ""

# Run Phase 2 with --auto flag
exec ./phase2-qemu-setup.sh --auto
