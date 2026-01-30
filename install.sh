#!/bin/bash
#
# TrustNet One-Liner Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/Ingasti/trustnet-wip/main/install.sh | bash
#
# Creates:
#   - QEMU VMs (trustnet-node, trustnet-registry)
#   - Alpine 3.22.2 ARM64 systems
#   - Tendermint consensus node with Registry
#   - IPv6 ULA network (fd10:1234::/32)
#
# Version: 1.0.0
#

set -euo pipefail

REPO_URL="https://github.com/Ingasti/trustnet-wip.git"
RAW_URL="https://raw.githubusercontent.com/Ingasti/trustnet-wip"
REPO_DIR="${HOME}/trustnet"
BRANCH="${TRUSTNET_BRANCH:-main}"
VM_DIR="${HOME}/vms"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}→${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_error()   { echo -e "${RED}✗${NC} $*" >&2; }

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║         TrustNet One-Liner Installer                      ║"
echo "║    Distributed Blockchain Infrastructure Setup            ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Branch: $BRANCH"
echo "Repository: $REPO_URL"
echo "Install directory: $REPO_DIR"
echo "VM directory: $VM_DIR"
echo ""

# Ensure we can write to home directory
if [ ! -w "$HOME" ]; then
    log_error "Cannot write to $HOME"
    exit 1
fi

# Create repo directory
log_info "Setting up TrustNet repository..."
mkdir -p "$REPO_DIR"
cd "$REPO_DIR"

# Check for existing installation
if [ -d ".git" ]; then
    log_info "TrustNet already exists, updating..."
    git pull origin "$BRANCH" 2>/dev/null || true
else
    log_info "Cloning TrustNet repository..."
    git clone -b "$BRANCH" "$REPO_URL" . 2>/dev/null || {
        log_error "Failed to clone repository"
        exit 1
    }
fi

log_success "Repository ready at $REPO_DIR"

# Ensure tools directory exists
mkdir -p "$REPO_DIR/tools"

# Download Phase scripts if they don't exist
log_info "Ensuring installation scripts are available..."

download_script() {
    local script_name="$1"
    local local_path="$REPO_DIR/tools/$script_name"
    local remote_url="$RAW_URL/$BRANCH/tools/$script_name?nocache=$(date +%s)"
    
    if [ -f "$local_path" ]; then
        log_success "$script_name already exists"
        return 0
    fi
    
    log_info "Downloading $script_name..."
    if ! curl -fsSL "$remote_url" -o "${local_path}.tmp"; then
        log_error "Failed to download $script_name (not yet available)"
        rm -f "${local_path}.tmp"
        return 1
    fi
    
    mv "${local_path}.tmp" "$local_path"
    chmod +x "$local_path"
    
    # Fix line endings (Windows/Mac compatibility)
    sed -i 's/\r$//' "$local_path" 2>/dev/null || \
    sed -i '' 's/[[:space:]]*$//' "$local_path" 2>/dev/null || true
    
    log_success "Downloaded $script_name"
}

# Download all phase scripts
download_script "phase2-qemu-setup.sh"
download_script "phase3-alpine-install.sh" || true
download_script "phase4-cache-deploy.sh" || true
download_script "phase5-verify.sh" || true

echo ""
log_success "Installation scripts ready (available phases downloaded)"
echo ""

################################################################################
# Interactive Installation Menu
################################################################################

show_menu() {
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║               TrustNet Installation Phases                 ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    echo "  1) Phase 2: Create QEMU VMs (disk images, startup scripts)"
    echo "  2) Phase 3: Install Alpine on VMs (OS setup)"
    echo "  3) Phase 4: Deploy cache & install services"
    echo "  4) Phase 5: Verification & testing"
    echo "  5) Run all phases (2→3→4→5)"
    echo "  6) Quick summary"
    echo "  0) Exit"
    echo ""
}

show_summary() {
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                   Installation Summary                     ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    echo "  Repository: $REPO_DIR"
    echo "  VM Location: $VM_DIR"
    echo ""
    echo "  Phase 2: QEMU VM Setup"
    echo "    - Creates disk images (50GB node, 30GB registry)"
    echo "    - Generates startup scripts"
    echo "    - Configures IPv6 ULA network"
    echo ""
    echo "  Phase 3: Alpine Installation"
    echo "    - Automated Alpine 3.22.2 ARM64 install"
    echo "    - User setup (warden/keeper)"
    echo "    - SSH configuration"
    echo ""
    echo "  Phase 4: Cache Deployment"
    echo "    - SCP cache files to VMs"
    echo "    - Run installation scripts"
    echo "    - Configure services"
    echo ""
    echo "  Phase 5: Verification"
    echo "    - Test Tendermint RPC"
    echo "    - Verify Registry health"
    echo "    - Network connectivity checks"
    echo ""
    echo "  To start a VM after installation:"
    echo "    ~/vms/trustnet-node/start-trustnet-node.sh"
    echo "    ~/vms/trustnet-registry/start-trustnet-registry.sh"
    echo ""
}

run_phase() {
    local phase_num="$1"
    local script_name="phase${phase_num}-*.sh"
    local script_path="$REPO_DIR/tools/$script_name"
    
    if [ ! -f "$script_path" ]; then
        log_error "Script not found: $script_path"
        return 1
    fi
    
    log_info "Running Phase $phase_num..."
    echo ""
    bash "$script_path" --auto
    echo ""
    log_success "Phase $phase_num complete"
}

################################################################################
# Main Loop
################################################################################

AUTO_MODE="${TRUSTNET_AUTO:-false}"

if [ "$AUTO_MODE" = "true" ]; then
    log_info "Running in automatic mode (all phases)"
    echo ""
    run_phase 2 || exit 1
    run_phase 3 || exit 1
    run_phase 4 || exit 1
    run_phase 5 || exit 1
    
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║  ✓ TrustNet Installation Complete!                        ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    exit 0
fi

# Interactive mode
while true; do
    echo ""
    show_menu
    read -p "Select option [0-6]: " choice
    
    case $choice in
        1) run_phase 2 ;;
        2) run_phase 3 ;;
        3) run_phase 4 ;;
        4) run_phase 5 ;;
        5)
            log_info "Running all phases..."
            run_phase 2 || exit 1
            run_phase 3 || exit 1
            run_phase 4 || exit 1
            run_phase 5 || exit 1
            
            echo ""
            echo "╔═══════════════════════════════════════════════════════════╗"
            echo "║  ✓ TrustNet Installation Complete!                        ║"
            echo "╚═══════════════════════════════════════════════════════════╝"
            exit 0
            ;;
        6) show_summary ;;
        0) log_info "Exiting"; exit 0 ;;
        *) log_error "Invalid option" ;;
    esac
done
