#!/bin/bash
#
# TrustNet: Create Node + Internal Registry VM
# Creates node-N with internal registry at fd10:1234::10N
#
# Usage: setup-node.sh [--node-name NAME] [--region REGION] [--city CITY] [--auto|-y]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$SCRIPT_DIR"
PROJECT_ROOT="$(dirname "$TOOLS_DIR")"

# Load common utilities
source "${TOOLS_DIR}/lib/common.sh"

VM_DIR="${HOME}/vms"
CACHE_DIR="${VM_DIR}/cache"
CONFIG_DIR="${HOME}/.trustnet"

# Parameters
NODE_NAME=""
REGION=""
CITY=""
AUTO_MODE=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --node-name=*) NODE_NAME="${arg#*=}" ;;
        --node-name) shift; NODE_NAME="$1" ;;
        --region=*) REGION="${arg#*=}" ;;
        --region) shift; REGION="$1" ;;
        --city=*) CITY="${arg#*=}" ;;
        --city) shift; CITY="$1" ;;
        --auto|-y) AUTO_MODE=true ;;
    esac
done

################################################################################
# Collect Node Information
################################################################################

collect_node_info() {
    echo ""
    log_header "Node Configuration"
    
    # Check for root registry
    if [ ! -f "$CONFIG_DIR/bootstrap.conf" ]; then
        log_error "Bootstrap configuration not found"
        log_info "Run setup-root-registry.sh first"
        exit 1
    fi
    
    # Load bootstrap config
    source "$CONFIG_DIR/bootstrap.conf"
    
    # Get existing nodes for numbering
    local next_num
    next_num=$(suggest_node_number "$ROOT_REGISTRY_IP")
    
    # Region
    if [ -z "$REGION" ]; then
        if [ "$AUTO_MODE" = "true" ]; then
            REGION="default"
        else
            read_input "Region (e.g., us-west, eu-central)" "default" REGION
        fi
    fi
    
    # City
    if [ -z "$CITY" ]; then
        if [ "$AUTO_MODE" = "true" ]; then
            CITY="node${next_num}"
        else
            read_input "City/Location (e.g., portland, dublin)" "node${next_num}" CITY
        fi
    fi
    
    # Node name (user provided, derived from region/city, or interactive)
    if [ -z "$NODE_NAME" ]; then
        if [ "$AUTO_MODE" = "true" ]; then
            NODE_NAME="${REGION}-${CITY}-${next_num}"
        else
            NODE_NAME="${REGION}-${CITY}-${next_num}"
            read_input "Node name (leave blank for auto)" "" NODE_NAME
            if [ -z "$NODE_NAME" ]; then
                NODE_NAME="${REGION}-${CITY}-${next_num}"
            fi
        fi
    fi
    
    echo ""
    log_info "Region: $REGION"
    log_info "City: $CITY"
    log_info "Node Name: $NODE_NAME"
    
    # Validate node name
    if ! validate_node_name "$NODE_NAME" "$ROOT_REGISTRY_IP"; then
        log_error "Node name validation failed"
        log_info "Name must match pattern: region-city-number"
        log_info "Name must be unique (not already in registry)"
        exit 1
    fi
    
    log_success "Node name validated: $NODE_NAME"
}

################################################################################
# Calculate Node Address
################################################################################

calculate_node_ipv6() {
    local node_num=$1
    local base_addr="fd10:1234::"
    
    # Node address: fd10:1234::N
    NODE_IPV6="${base_addr}${node_num}"
    
    # Internal registry: fd10:1234::10N
    REGISTRY_IPV6="${base_addr}$((100 + node_num))"
    
    log_info "Node IPv6 address: $NODE_IPV6"
    log_info "Internal registry IPv6: $REGISTRY_IPV6"
}

################################################################################
# Create Node VM
################################################################################

create_node_vm() {
    echo ""
    log_header "Creating Node VM: $NODE_NAME"
    
    local node_dir="$VM_DIR/$NODE_NAME"
    mkdir -p "$node_dir"
    
    log_info "Node directory: $node_dir"
    
    # Create configuration file for this node
    cat > "$node_dir/node.conf" << EOF
# TrustNet Node Configuration
# Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')

NODE_NAME="$NODE_NAME"
NODE_NUMBER=${NODE_NUM}
REGION="$REGION"
CITY="$CITY"

# IPv6 Addresses
NODE_IPV6="$NODE_IPV6"
INTERNAL_REGISTRY_IPV6="$REGISTRY_IPV6"
ROOT_REGISTRY_IPV6="$ROOT_REGISTRY_IP"

# Networking
ULA_PREFIX="fd10:1234::"
REGISTRY_PORT=8053
TENDERMINT_RPC_PORT=26657
TENDERMINT_P2P_PORT=26656
TENDERMINT_P2P_LADDR_PORT=26656

# Caddy reverse proxy
CADDY_DOMAIN="${NODE_NAME}.trustnet.local"
CADDY_REGISTRY_URL="https://${REGISTRY_IPV6}:${REGISTRY_PORT}"

# Let's Encrypt (via Caddy)
LETSENCRYPT_EMAIL="admin@trustnet.local"

# Bootstrap
ROOT_REGISTRY_HTTPS="https://[${ROOT_REGISTRY_IPV6}]:${REGISTRY_PORT}"
BOOTSTRAP_PEERS="${ROOT_REGISTRY_IP}:26656"
EOF
    
    log_success "Node configuration created"
    
    # Save to system config
    save_config "$CONFIG_DIR/${NODE_NAME}.conf" \
        "$NODE_NAME" \
        "$NODE_IPV6" \
        "$REGISTRY_IPV6" \
        "$ROOT_REGISTRY_IP"
}

################################################################################
# Main
################################################################################

main() {
    echo ""
    log_header "TrustNet: Node Setup"
    
    # Prerequisites
    check_qemu || exit 1
    check_disk_space 50 "$HOME" || exit 1
    
    mkdir -p "$VM_DIR" "$CACHE_DIR" "$CONFIG_DIR"
    
    # Collect information
    collect_node_info
    
    # Extract node number from name (last part after last dash)
    NODE_NUM=$(echo "$NODE_NAME" | awk -F'-' '{print $NF}')
    if ! [[ "$NODE_NUM" =~ ^[0-9]+$ ]]; then
        NODE_NUM=1
    fi
    
    # Calculate IPv6 addresses
    calculate_node_ipv6 "$NODE_NUM"
    
    # Confirm
    echo ""
    if [ "$AUTO_MODE" != "true" ]; then
        if ! confirm "Create node with above configuration?"; then
            log_warn "Node creation cancelled"
            exit 0
        fi
    fi
    
    # Create VM
    create_node_vm
    
    echo ""
    log_success "Node configuration ready: $NODE_NAME"
    log_info "Next: Run setup-vms.sh to create the actual VMs"
    log_info "  cd ~/vms && bash $PROJECT_ROOT/tools/setup-vms.sh"
    echo ""
}

main "$@"
