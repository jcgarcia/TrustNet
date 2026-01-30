#!/bin/bash
#
# TrustNet: Create Root Registry VM
# Bootstrap: Creates the authoritative registry at fd10:1234::253
#
# Usage: setup-root-registry.sh [--auto|-y]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$SCRIPT_DIR"
PROJECT_ROOT="$(dirname "$TOOLS_DIR")"

# Load common utilities
source "${TOOLS_DIR}/lib/common.sh"

AUTO_MODE=false
for arg in "$@"; do
    case $arg in
        --auto|-y) AUTO_MODE=true ;;
    esac
done

VM_DIR="${HOME}/vms"
CACHE_DIR="${VM_DIR}/cache"
CONFIG_DIR="${HOME}/.trustnet"

################################################################################
# Bootstrap Root Registry
################################################################################

main() {
    echo ""
    log_header "TrustNet: Root Registry Bootstrap"
    
    # Prerequisites
    check_qemu || exit 1
    check_disk_space 100 "$HOME" || exit 1
    
    mkdir -p "$VM_DIR" "$CACHE_DIR" "$CONFIG_DIR"
    
    echo ""
    log_info "This is the first TrustNet installation"
    log_info "Creating root registry at fd10:1234::253"
    echo ""
    
    if [ "$AUTO_MODE" != "true" ]; then
        if ! confirm "Continue with root registry bootstrap?"; then
            log_warn "Bootstrap cancelled"
            exit 0
        fi
    fi
    
    echo ""
    log_header "Creating Root Registry VM"
    
    # For now, placeholder - actual VM creation happens in setup-vms.sh logic
    # This script orchestrates, actual QEMU setup in separate script
    
    # Create directories for root registry
    mkdir -p "$VM_DIR/root-registry"
    
    log_success "Root registry VM structure created at $VM_DIR/root-registry"
    log_info "Root registry IPv6: fd10:1234::253"
    log_info "Root registry port: 8053 (HTTPS via Caddy + Let's Encrypt)"
    
    # Save bootstrap config
    save_config "$CONFIG_DIR/bootstrap.conf" \
        "root-registry" \
        "fd10:1234::253" \
        "fd10:1234::253" \
        ""
    
    log_success "Bootstrap configuration saved"
    
    echo ""
    log_info "Next: Create first node via setup-node.sh"
    echo ""
}

main "$@"
