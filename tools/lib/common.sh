#!/bin/bash
#
# TrustNet Common Utilities
# Shared functions for all setup scripts
#

set -euo pipefail

################################################################################
# Colors & Logging
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}→${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_warn()    { echo -e "${YELLOW}⚠${NC} $*"; }
log_error()   { echo -e "${RED}✗${NC} $*"; }
log_header()  { echo -e "\n${CYAN}=== $* ===${NC}\n"; }

################################################################################
# DNS & Registry Utilities
################################################################################

# Check if TNR DNS record exists
check_tnr_record() {
    local domain="${1:-trustnet.local}"
    
    log_info "Checking DNS for TNR record in $domain..."
    
    # Try dig first, fallback to nslookup
    if command -v dig &>/dev/null; then
        local result=$(dig +short AAAA tnr.$domain 2>/dev/null || echo "")
        if [[ -n "$result" ]]; then
            echo "$result"
            return 0
        fi
    elif command -v nslookup &>/dev/null; then
        local result=$(nslookup -type=AAAA tnr.$domain 2>/dev/null | grep -oE '[0-9a-f:]+' || echo "")
        if [[ -n "$result" ]]; then
            echo "$result"
            return 0
        fi
    fi
    
    return 1
}

# Parse TNR record and return comma-separated addresses
parse_tnr_addresses() {
    local tnr_record="$1"
    
    # TNR record format: comma-separated IPv6 addresses
    # fd10:1234::253,fd10:1234::254
    echo "$tnr_record" | tr ' ' ',' | sed 's/,$//'
}

# Query root registry for existing nodes
query_registry_nodes() {
    local registry_addr="$1"
    
    log_info "Querying registry at [$registry_addr]:8053 for existing nodes..."
    
    # This would call the registry API
    # For now, placeholder - will be implemented when registry API is defined
    # Expected: curl -k https://[$registry_addr]:8053/v2/nodes
    
    # Placeholder: return empty list for bootstrap
    echo ""
}

# Validate node name against registry
validate_node_name() {
    local node_name="$1"
    local registry_addr="${2:-}"
    
    # Check format: region-city-name
    if ! [[ "$node_name" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
        log_error "Invalid node name: $node_name (use lowercase alphanumeric and hyphens)"
        return 1
    fi
    
    if [[ -n "$registry_addr" ]]; then
        # Query registry to check if name exists
        local existing_nodes=$(query_registry_nodes "$registry_addr" 2>/dev/null || echo "")
        if echo "$existing_nodes" | grep -q "^$node_name\$"; then
            log_error "Node name already exists: $node_name"
            return 1
        fi
    fi
    
    return 0
}

# Suggest next node number
suggest_node_number() {
    local registry_addr="${1:-}"
    
    if [[ -z "$registry_addr" ]]; then
        echo "1"
        return 0
    fi
    
    # Query registry for existing nodes and find highest number
    local existing=$(query_registry_nodes "$registry_addr" 2>/dev/null || echo "")
    if [[ -z "$existing" ]]; then
        echo "1"
        return 0
    fi
    
    # Extract numbers from names like "node-1", "node-2"
    local max_num=$(echo "$existing" | grep -oE 'node-[0-9]+' | grep -oE '[0-9]+' | sort -n | tail -1)
    echo $((max_num + 1))
}

################################################################################
# VM & QEMU Utilities
################################################################################

check_qemu() {
    log_info "Checking QEMU installation..."
    
    if ! command -v qemu-system-aarch64 &>/dev/null; then
        log_error "QEMU not installed"
        return 1
    fi
    
    local version=$(qemu-system-aarch64 --version | head -1)
    log_success "QEMU found: $version"
    return 0
}

check_disk_space() {
    local required_gb="${1:-100}"
    local path="${2:-$HOME}"
    
    log_info "Checking disk space (need ${required_gb}GB)..."
    
    local available=$(df "$path" | awk 'NR==2 {printf "%.0f", $4 / 1024 / 1024}')
    
    if [[ $available -lt $required_gb ]]; then
        log_error "Insufficient disk space: ${available}GB available, need ${required_gb}GB"
        return 1
    fi
    
    log_success "Disk space OK: ${available}GB available"
    return 0
}

################################################################################
# IPv6 & Network Utilities
################################################################################

# Calculate next available IPv6 address in ULA
next_ipv6_address() {
    local current="$1"  # e.g., fd10:1234::1
    local base="${current%%::*}::"  # fd10:1234::
    
    # Extract hex number after ::
    local hex_part="${current##*::}"
    local dec_num=$((16#$hex_part))
    local next_num=$((dec_num + 1))
    local next_hex=$(printf '%x' $next_num)
    
    echo "${base}${next_hex}"
}

# Validate IPv6 ULA address
validate_ipv6_ula() {
    local addr="$1"
    
    # Check if it's a valid IPv6 address starting with fd or fc
    if [[ $addr =~ ^[fc][df][0-9a-f]{2}:[0-9a-f]{4}::[0-9a-f]+$ ]]; then
        return 0
    fi
    
    return 1
}

################################################################################
# User Interaction
################################################################################

# Ask for confirmation
confirm() {
    local prompt="$1"
    local default="${2:-y}"
    
    if [[ "$default" == "y" ]]; then
        read -p "$(echo -e ${BLUE}→${NC} $prompt [Y/n] )" -n 1 -r
    else
        read -p "$(echo -e ${BLUE}→${NC} $prompt [y/N] )" -n 1 -r
    fi
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Read input with prompt
read_input() {
    local prompt="$1"
    local default="${2:-}"
    
    if [[ -n "$default" ]]; then
        read -p "$(echo -e ${BLUE}→${NC} $prompt [$default]: )" input
        echo "${input:-$default}"
    else
        read -p "$(echo -e ${BLUE}→${NC} $prompt: )" input
        echo "$input"
    fi
}

################################################################################
# Configuration Management
################################################################################

# Save installation config for reference
save_config() {
    local config_file="$1"
    local node_name="$2"
    local node_ipv6="$3"
    local registry_ipv6="$4"
    local root_registry="${5:-}"
    
    cat > "$config_file" << EOF
# TrustNet Node Configuration
# Generated: $(date)

NODE_NAME=$node_name
NODE_IPV6=$node_ipv6
INTERNAL_REGISTRY_IPV6=$registry_ipv6
ROOT_REGISTRY=$root_registry
INSTALLATION_DATE=$(date '+%Y-%m-%d %H:%M:%S')
EOF
    
    log_success "Configuration saved to $config_file"
}

# Load existing config
load_config() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        return 1
    fi
    
    source "$config_file"
    return 0
}

################################################################################
# Export functions for sourcing
################################################################################

export -f log_info log_success log_warn log_error log_header
export -f check_qemu check_disk_space
export -f validate_ipv6_ula next_ipv6_address
export -f confirm read_input
export -f save_config load_config
export -f check_tnr_record parse_tnr_addresses query_registry_nodes
export -f validate_node_name suggest_node_number
