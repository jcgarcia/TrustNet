#!/bin/bash
#
# TrustNet Phase 2: QEMU VM Installation
# Creates trustnet-node and trustnet-registry VMs with Alpine 3.22.2 ARM64
#
# Usage: ./phase2-qemu-setup.sh [--auto|-y]
#   --auto, -y    Use recommended settings without prompts
#

set -euo pipefail

trap 'echo "ERROR: Installation failed at line $LINENO" >&2; exit 1' ERR

################################################################################
# Configuration
################################################################################

AUTO_MODE=false
for arg in "$@"; do
    case $arg in
        --auto|-y) AUTO_MODE=true ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Use ~ expansion for user-agnostic paths
VM_DIR="${HOME}/vms"
CACHE_DIR="${VM_DIR}/cache"
ISO_DIR="${VM_DIR}/isos"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}→${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_warn()    { echo -e "${YELLOW}⚠${NC} $*"; }
log_error()   { echo -e "${RED}✗${NC} $*"; }

################################################################################
# Check Prerequisites
################################################################################

check_qemu() {
    log_info "Checking QEMU installation..."
    
    if command -v qemu-system-aarch64 &>/dev/null; then
        local qemu_version=$(qemu-system-aarch64 --version | head -1)
        log_success "QEMU found: $qemu_version"
        return 0
    fi
    
    log_warn "QEMU not found. Installing..."
    
    if command -v apt-get &>/dev/null; then
        sudo apt-get update
        sudo apt-get install -y qemu-system-arm qemu-utils
    elif command -v brew &>/dev/null; then
        brew install qemu
    else
        log_error "Could not install QEMU. Please install manually."
        exit 1
    fi
    
    log_success "QEMU installed"
}

check_directories() {
    log_info "Setting up directory structure..."
    
    mkdir -p "$VM_DIR"/{trustnet-node,trustnet-registry}
    mkdir -p "$CACHE_DIR"
    mkdir -p "$ISO_DIR"
    
    # Ensure directories are writable
    if ! [ -w "$VM_DIR" ]; then
        log_error "Cannot write to $VM_DIR"
        exit 1
    fi
    
    log_success "Directories ready at $VM_DIR"
}

################################################################################
# Resource Detection
################################################################################

detect_resources() {
    log_info "Detecting system resources..."
    
    local total_mem=$(free -b | awk 'NR==2 {print $2}')
    local total_cpus=$(nproc)
    local available_space=$(df "$VM_DIR" | awk 'NR==2 {print $4}')
    
    # Convert to human readable
    local mem_gb=$((total_mem / 1024 / 1024 / 1024))
    local space_gb=$((available_space / 1024 / 1024))
    
    echo ""
    echo "System Resources:"
    echo "  RAM: ${mem_gb}GB"
    echo "  CPUs: $total_cpus"
    echo "  Available Space: ${space_gb}GB"
    echo ""
    
    # Recommend configuration based on available resources
    if [ "$mem_gb" -ge 16 ]; then
        NODE_RAM="8G"
        NODE_CPUS="4"
        REGISTRY_RAM="4G"
        REGISTRY_CPUS="2"
        log_info "Recommended: Node 8G/4CPUs, Registry 4G/2CPUs (High-end)"
    elif [ "$mem_gb" -ge 12 ]; then
        NODE_RAM="6G"
        NODE_CPUS="3"
        REGISTRY_RAM="3G"
        REGISTRY_CPUS="2"
        log_info "Recommended: Node 6G/3CPUs, Registry 3G/2CPUs (Mid-range)"
    elif [ "$mem_gb" -ge 8 ]; then
        NODE_RAM="4G"
        NODE_CPUS="2"
        REGISTRY_RAM="2G"
        REGISTRY_CPUS="1"
        log_info "Recommended: Node 4G/2CPUs, Registry 2G/1CPU (Baseline)"
    else
        log_error "Insufficient RAM (minimum 8GB recommended)"
        exit 1
    fi
    
    # Check disk space (need ~160GB for both VMs + images)
    if [ "$space_gb" -lt 100 ]; then
        log_warn "Low disk space (${space_gb}GB available, ~160GB recommended)"
        if [ "$AUTO_MODE" != "true" ]; then
            read -p "Continue anyway? [y/N] " -n 1 -r
            echo
            [[ $REPLY =~ ^[Yy]$ ]] || exit 1
        fi
    fi
}

################################################################################
# Alpine Image Verification
################################################################################

verify_alpine_image() {
    # Check for existing Alpine ISO (standard preferred over virt for full install)
    local standard_iso="$ISO_DIR/alpine-standard-3.22.2-aarch64.iso"
    local virt_iso="$ISO_DIR/alpine-virt-3.22.2-aarch64.iso"
    
    if [ -f "$standard_iso" ]; then
        log_success "Using cached Alpine Standard 3.22.2 ARM64"
        echo "$standard_iso"
        return 0
    elif [ -f "$virt_iso" ]; then
        log_success "Using cached Alpine Virt 3.22.2 ARM64"
        echo "$virt_iso"
        return 0
    fi
    
    log_error "No Alpine 3.22.2 ARM64 ISO found at $ISO_DIR"
    log_info "Expected: $standard_iso or $virt_iso"
    exit 1
}

################################################################################
# VM Image Creation
################################################################################

create_vm_disk() {
    local vm_name="$1"
    local size="$2"
    local vm_path="${VM_DIR}/${vm_name}"
    local disk_image="${vm_path}/${vm_name}.qcow2"
    
    log_info "Creating $vm_name disk image (${size})..."
    
    if [ -f "$disk_image" ]; then
        log_warn "$disk_image already exists, skipping"
        echo "$disk_image"
        return 0
    fi
    
    qemu-img create -f qcow2 "$disk_image" "$size"
    log_success "Created $disk_image"
    echo "$disk_image"
}

################################################################################
# QEMU Startup Script Generator
################################################################################

generate_vm_start_script() {
    local vm_name="$1"
    local vm_path="${VM_DIR}/${vm_name}"
    local disk_image="${vm_path}/${vm_name}.qcow2"
    local ram="$2"
    local cpus="$3"
    local ssh_port="$4"
    local script_path="${vm_path}/start-${vm_name}.sh"
    
    log_info "Generating startup script for $vm_name..."
    
    cat > "$script_path" << 'EOFSCRIPT'
#!/bin/bash
# TrustNet VM Startup Script
# This script uses actual paths, not symlinks

set -euo pipefail

VM_NAME="VMNAME"
VM_DIR="${HOME}/vms/${VM_NAME}"
DISK_IMAGE="${VM_DIR}/${VM_NAME}.qcow2"
VM_RAM="RAMSIZE"
VM_CPUS="CPUCOUNT"
SSH_PORT="SSHPORT"
PID_FILE="${VM_DIR}/${VM_NAME}.pid"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if already running
if [ -f "$PID_FILE" ] && sudo kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo -e "${YELLOW}VM $VM_NAME is already running (PID: $(cat "$PID_FILE"))${NC}"
    exit 0
fi

# Check disk image exists
if [ ! -f "$DISK_IMAGE" ]; then
    echo -e "${RED}ERROR: Disk image not found: $DISK_IMAGE${NC}"
    exit 1
fi

# Detect acceleration
HOST_ARCH=$(uname -m)
if [ "$HOST_ARCH" = "aarch64" ]; then
    if [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
        ACCEL="-accel kvm"
    else
        ACCEL="-accel tcg"
    fi
else
    ACCEL="-accel tcg"
fi

# Update /etc/hosts
if ! grep -q "${VM_NAME}.local" /etc/hosts 2>/dev/null; then
    echo "127.0.0.1 ${VM_NAME}.local" | sudo tee -a /etc/hosts > /dev/null
fi

echo -e "${GREEN}Starting VM: $VM_NAME${NC}"
echo "  Disk: $DISK_IMAGE"
echo "  RAM: $VM_RAM | CPUs: $VM_CPUS"
echo "  SSH: localhost:$SSH_PORT"
echo ""

# Start QEMU
sudo qemu-system-aarch64 \
    -M virt ${ACCEL} \
    -cpu cortex-a72 \
    -m "$VM_RAM" \
    -smp "$VM_CPUS" \
    -drive file="$DISK_IMAGE",format=qcow2,if=virtio \
    -nic user,hostfwd=tcp:127.0.0.1:${SSH_PORT}-:22 \
    -nographic \
    -daemonize \
    -pidfile "$PID_FILE"

echo -e "${GREEN}✓ VM started${NC}"
sleep 2

# Verify
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if sudo kill -0 "$PID" 2>/dev/null; then
        echo -e "${GREEN}✓ Verified running (PID: $PID)${NC}"
        exit 0
    fi
fi

echo -e "${RED}✗ VM failed to start${NC}"
exit 1
EOFSCRIPT
    
    # Replace placeholders
    sed -i "s/VMNAME/$vm_name/g" "$script_path"
    sed -i "s/RAMSIZE/$ram/g" "$script_path"
    sed -i "s/CPUCOUNT/$cpus/g" "$script_path"
    sed -i "s/SSHPORT/$ssh_port/g" "$script_path"
    
    chmod +x "$script_path"
    log_success "Created: $script_path"
}

################################################################################
# Network Bridge Configuration
################################################################################

setup_network() {
    log_info "Configuring IPv6 ULA network (fd10:1234::/32)..."
    
    cat > "${VM_DIR}/network-setup.sh" << 'EOFNET'
#!/bin/bash
# IPv6 ULA Network Setup for TrustNet VMs
# Creates fd10:1234::/32 bridge for inter-VM communication

set -euo pipefail

BRIDGE_NAME="trustnet-br"
BRIDGE_IP="fd10:1234::1"
NODE_IP="fd10:1234::1"
REGISTRY_IP="fd10:1234::2"

log_info() { echo "→ $*"; }
log_success() { echo "✓ $*"; }

log_info "Setting up network bridge: $BRIDGE_NAME"

# Check if bridge already exists
if ip link show "$BRIDGE_NAME" &>/dev/null; then
    log_success "Bridge already exists"
    exit 0
fi

# Create bridge (may require sudo)
sudo ip link add "$BRIDGE_NAME" type bridge
sudo ip link set "$BRIDGE_NAME" up

# Assign IPv6 address
sudo ip -6 addr add "${BRIDGE_IP}/64" dev "$BRIDGE_NAME" scope global

log_success "Bridge created with IPv6: $BRIDGE_IP/64"
log_info "Node will be: $NODE_IP"
log_info "Registry will be: $REGISTRY_IP"
EOFNET
    
    chmod +x "${VM_DIR}/network-setup.sh"
    log_success "Network setup script created: ${VM_DIR}/network-setup.sh"
}

################################################################################
# Main Installation Flow
################################################################################

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║  TrustNet Phase 2: QEMU VM Setup                       ║"
    echo "║  Creating trustnet-node & trustnet-registry VMs        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    # Prerequisites
    check_qemu
    check_directories
    
    # Resource detection
    detect_resources
    
    # Configuration confirmation
    if [ "$AUTO_MODE" != "true" ]; then
        echo ""
        read -p "Continue with recommended configuration? [Y/n] " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Nn]$ ]] || exit 0
    fi
    
    echo ""
    log_info "Phase 2: Installation Starting"
    echo ""
    
    # Verify Alpine
    verify_alpine_image
    
    # Create VM disks
    log_info "Creating VM disks..."
    create_vm_disk "trustnet-node" "50G"
    create_vm_disk "trustnet-registry" "30G"
    log_success "VM disks created"
    
    echo ""
    
    # Generate startup scripts
    generate_vm_start_script "trustnet-node" "$NODE_RAM" "$NODE_CPUS" "3222"
    generate_vm_start_script "trustnet-registry" "$REGISTRY_RAM" "$REGISTRY_CPUS" "3223"
    
    echo ""
    
    # Setup network
    setup_network
    
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║  ✓ Phase 2 Complete                                    ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    echo "Next steps:"
    echo "  1. Start VMs:"
    echo "     ${VM_DIR}/trustnet-node/start-trustnet-node.sh"
    echo "     ${VM_DIR}/trustnet-registry/start-trustnet-registry.sh"
    echo ""
    echo "  2. Install Alpine on VMs (Phase 3)"
    echo ""
    echo "  3. Deploy cache & run installation scripts (Phase 4)"
    echo ""
}

main "$@"
