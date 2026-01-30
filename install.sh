#!/bin/bash
#
# TrustNet: One-liner Installation Orchestrator
#
# Usage: bash <(curl -fsSL https://trustnet.sh) [--auto] [--node-name NAME] [--region REGION] [--city CITY]
#
# This script orchestrates the TrustNet installation by:
# 1. Checking if root registry exists (via TNR DNS record)
# 2. If missing: Bootstraps root registry
# 3. Creates node with internal registry
# 4. Optionally creates secondary registries
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$SCRIPT_DIR"

# Determine PROJECT_ROOT (handles both direct execution and curl piping)
if [ -f "$TOOLS_DIR/../trustnet-wip" ] || [ -d "$TOOLS_DIR/../trustnet-wip/.git" ]; then
    PROJECT_ROOT="$(dirname "$TOOLS_DIR")"
elif [ -f "$TOOLS_DIR/lib/common.sh" ]; then
    PROJECT_ROOT="$(dirname "$TOOLS_DIR")"
else
    # Fallback: assume we're in the trustnet-wip/tools directory
    PROJECT_ROOT="$(cd "$TOOLS_DIR/.." && pwd)"
fi

# Load common utilities
source "${TOOLS_DIR}/lib/common.sh"

CONFIG_DIR="${HOME}/.trustnet"
AUTO_MODE=false
NODE_PARAMS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto|-y)
            AUTO_MODE=true
            ;;
        --node-name|--region|--city)
            NODE_PARAMS+=("$1" "$2")
            shift
            ;;
        --node-name=*|--region=*|--city=*|--auto=*)
            NODE_PARAMS+=("$1")
            ;;
        *)
            log_warn "Unknown option: $1"
            ;;
    esac
    shift
done

################################################################################
# Bootstrap Detection & Root Registry Setup
################################################################################

setup_root_registry_if_needed() {
    echo ""
    log_header "TrustNet Bootstrap Check"
    
    # Check if TNR DNS record exists
    if check_tnr_record; then
        log_success "Root registry detected via DNS (TNR record)"
        log_info "This is not a bootstrap installation"
        return 0
    fi
    
    # Check local bootstrap config
    if [ -f "$CONFIG_DIR/bootstrap.conf" ]; then
        log_success "Root registry configuration found locally"
        log_info "Using existing bootstrap"
        return 0
    fi
    
    # No root registry - this is a bootstrap installation
    log_info "No root registry detected - this is the first installation"
    
    echo ""
    if [ "$AUTO_MODE" != "true" ]; then
        if ! confirm "Bootstrap root registry now?"; then
            log_warn "Bootstrap required before creating nodes"
            log_info "Run this script again when ready to bootstrap"
            exit 1
        fi
    fi
    
    # Run bootstrap
    bash "${TOOLS_DIR}/setup-root-registry.sh" $([ "$AUTO_MODE" = "true" ] && echo "--auto" || true)
    
    log_success "Root registry bootstrap complete"
}

################################################################################
# Node Setup
################################################################################

setup_node() {
    echo ""
    log_header "TrustNet Node Setup"
    
    # Build command
    local cmd="${TOOLS_DIR}/setup-node.sh"
    
    if [ "$AUTO_MODE" = "true" ]; then
        cmd="$cmd --auto"
    fi
    
    # Add node parameters if provided
    for param in "${NODE_PARAMS[@]}"; do
        cmd="$cmd $param"
    done
    
    # Run node setup
    bash $cmd
}

################################################################################
# Summary
################################################################################

show_summary() {
    echo ""
    log_header "Installation Complete"
    echo ""
    log_info "Next steps:"
    echo "  1. Navigate to VMs directory:"
    echo "     cd ~/vms"
    echo ""
    echo "  2. Create actual VMs (QEMU):"
    echo "     bash $PROJECT_ROOT/tools/setup-vms.sh"
    echo ""
    echo "  3. Verify deployment:"
    echo "     # Check root registry"
    echo "     curl -k https://[fd10:1234::253]:8053/health"
    echo ""
    echo "     # Check node (after VMs running)"
    echo "     ssh -p 22 root@[fd10:1234::1]"
    echo ""
    log_info "For dual-access (localhost testing):"
    echo "     # Node SSH via localhost"
    echo "     ssh -p 3222 root@localhost"
    echo ""
    echo "     # Registry via localhost"
    echo "     curl -k https://localhost:8053/health"
    echo ""
}

################################################################################
# Main
################################################################################

main() {
    echo ""
    log_header "TrustNet Installation Orchestrator"
    log_info "IPv6-first distributed registry architecture"
    echo ""
    
    # Create config directory
    mkdir -p "$CONFIG_DIR"
    
    # Check prerequisites
    check_qemu || exit 1
    
    # Bootstrap if needed
    setup_root_registry_if_needed
    
    # Setup node
    setup_node
    
    # Show summary
    show_summary
}

main "$@"
