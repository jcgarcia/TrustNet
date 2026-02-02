#!/bin/bash
#
# TrustNet Node One-Liner Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/jcgarcia/TrustNet/main/install.sh | bash
# Version: 1.0.0
#

set -e

REPO_URL="https://github.com/jcgarcia/TrustNet.git"
RAW_URL="https://raw.githubusercontent.com/jcgarcia/TrustNet"
REPO_DIR="$HOME/trustnet"
BRANCH="${TRUSTNET_BRANCH:-main}"

# Setup logging
LOG_DIR="${HOME}/.trustnet/logs"
LOG_FILE="${LOG_DIR}/install-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$LOG_DIR"

# Logging functions
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg" | tee -a "$LOG_FILE"
}

log_error() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*"
    echo "$msg" | tee -a "$LOG_FILE" >&2
}

# Trap errors and log them
trap 'log_error "Installation failed at line $LINENO. Check log: $LOG_FILE"' ERR

log "╔══════════════════════════════════════════════════════════╗"
log "║                                                          ║"
log "║        TrustNet Node One-Liner Installer                 ║"
log "║        Blockchain-Based Trust Network (Web3)             ║"
log "║                                                          ║"
log "╚══════════════════════════════════════════════════════════╝"
log ""
log "Branch: $BRANCH"
log "Installation log: $LOG_FILE"
log ""

# Create directory structure
mkdir -p "$REPO_DIR"
cd "$REPO_DIR"

log "Cloning TrustNet repository..."
# Clone or update repository
if [[ -d ".git" ]]; then
    log "Repository exists, updating..."
    git fetch origin
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
else
    log "Cloning repository..."
    git clone -b "$BRANCH" "$REPO_URL" .
fi

# Check for existing data at correct location (~/.trustnet/)
DATA_PRESERVED=0
PERSISTENT_DATA_DIR="${HOME}/.trustnet/data"
IDENTITY_BACKUP="${HOME}/.trustnet/identity-backup"

if [ -d "$PERSISTENT_DATA_DIR" ]; then
    log "→ Found existing node data at ~/.trustnet/data"
    DATA_PRESERVED=1
fi

if [ -d "$IDENTITY_BACKUP" ]; then
    log "→ Found identity backup at ~/.trustnet/identity-backup"
    log "  Your identity will be restored during installation"
fi

# Download latest scripts (always get fresh version from core)
log "→ Downloading latest core scripts..."

# Download setup script from core directory
if ! curl -fsSL "$RAW_URL/$BRANCH/core/tools/setup-trustnet-node.sh?nocache=$(date +%s)" -o setup-trustnet-node.sh.tmp; then
    log_error "Failed to download setup script"
    exit 1
fi
mv setup-trustnet-node.sh.tmp setup-trustnet-node.sh
chmod +x setup-trustnet-node.sh
sed -i 's/\r$//' setup-trustnet-node.sh 2>/dev/null || dos2unix setup-trustnet-node.sh 2>/dev/null || true

# Download alpine-install.exp from core
if ! curl -fsSL "$RAW_URL/$BRANCH/core/tools/alpine-install.exp?nocache=$(date +%s)" -o alpine-install.exp.tmp; then
    log_error "Failed to download alpine-install.exp"
    exit 1
fi
mv alpine-install.exp.tmp alpine-install.exp
sed -i 's/\r$//' alpine-install.exp 2>/dev/null || dos2unix alpine-install.exp 2>/dev/null || true

# Download core modules
log "→ Downloading core modules..."
mkdir -p lib

# List of core modules to download
MODULES=(
    "common.sh"
    "cache-manager.sh"
    "vm-lifecycle.sh"
    "vm-bootstrap.sh"
    "install-caddy.sh"
    "install-cosmos-sdk.sh"
    "install-certificates.sh"
    "setup-motd.sh"
)

for module in "${MODULES[@]}"; do
    if ! curl -fsSL "$RAW_URL/$BRANCH/core/tools/lib/$module?nocache=$(date +%s)" -o "lib/$module.tmp"; then
        log_error "Failed to download core module: $module"
        exit 1
    fi
    mv "lib/$module.tmp" "lib/$module"
    chmod +x "lib/$module"
done

log "✓ Core scripts and modules downloaded"

# Notify about data preservation
if [ $DATA_PRESERVED -eq 1 ]; then
    log "✓ Node data will be preserved (~/.trustnet/data)"
fi

log ""
log "→ Starting installation..."
log "→ Detailed logs will continue in: $LOG_FILE"
log ""

# Export log file for setup script
export TRUSTNET_LOG_FILE="$LOG_FILE"

# Run the setup script with --auto flag
exec ./setup-trustnet-node.sh --auto
