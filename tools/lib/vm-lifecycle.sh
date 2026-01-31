#!/bin/bash
# vm-lifecycle.sh - VM creation and lifecycle management
# Part of Phase 3.5 modular architecture

# Prevent direct execution
if [ "${BASH_SOURCE[0]}" -ef "$0" ]; then
    echo "Error: This script should be sourced, not executed directly"
    exit 1
fi

ensure_qemu() {
    log "Checking QEMU installation..."
    
    if command -v qemu-system-x86_64 &> /dev/null; then
        log "  ✓ QEMU already installed"
        return 0
    fi
    
    log "Installing QEMU..."
    
    if [ -f "${SCRIPT_DIR}/install-qemu.sh" ]; then
        "${SCRIPT_DIR}/install-qemu.sh"
    else
        log_error "QEMU not found. Please install manually:"
        log_info "  Ubuntu: sudo apt-get install qemu-system-x86 qemu-utils"
        log_info "  macOS: brew install qemu"
        exit 1
    fi
}

check_dependencies() {
    log "Checking dependencies..."
    
    local missing=()
    
    for cmd in curl sshpass ssh-keygen expect nc; do
        if ! command -v $cmd &> /dev/null; then
            missing+=($cmd)
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_info "Missing dependencies: ${missing[*]}"
        log_info "Installing missing packages..."
        
        # Detect package manager and install
        if command -v apt-get &> /dev/null; then
            sudo apt-get update -qq
            sudo apt-get install -y -qq ${missing[*]}
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y -q ${missing[*]}
        elif command -v yum &> /dev/null; then
            sudo yum install -y -q ${missing[*]}
        elif command -v brew &> /dev/null; then
            brew install ${missing[*]}
        else
            log_error "Unable to auto-install dependencies. Package manager not found."
            log_info "Please install manually: ${missing[*]}"
            exit 1
        fi
        
        # Verify installation
        local still_missing=()
        for cmd in ${missing[@]}; do
            if ! command -v $cmd &> /dev/null; then
                still_missing+=($cmd)
            fi
        done
        
        if [ ${#still_missing[@]} -gt 0 ]; then
            log_error "Failed to install: ${still_missing[*]}"
            log_info "Please install manually and try again"
            exit 1
        fi
        
        log "  ✓ All dependencies installed successfully"
    else
        log "  ✓ All dependencies satisfied"
    fi
}

setup_ssh_keys() {
    log "Setting up SSH keys for foreman user..."
    
    local ssh_dir="${HOME}/.ssh"
    local private_key="${ssh_dir}/${SSH_KEY_NAME}"
    local public_key="${ssh_dir}/${SSH_KEY_NAME}.pub"
    
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    
    if [ -f "$private_key" ]; then
        log "  ✓ SSH key already exists: $private_key"
    else
        log "  Generating SSH key pair..."
        ssh-keygen -t ed25519 -f "$private_key" -N "" -C "foreman@factory"
        log "  ✓ SSH key generated"
    fi
    
    # Export for later use
    export VM_SSH_PRIVATE_KEY="$private_key"
    export VM_SSH_PUBLIC_KEY="$public_key"
}

download_alpine() {
    log "Downloading Alpine Linux ISO..."
    
    # Auto-detect latest Alpine version if not already set
    if [ -z "$ALPINE_VERSION" ]; then
        ALPINE_VERSION=$(get_latest_alpine_version)
        log_info "  Auto-detected Alpine version: ${ALPINE_VERSION}"
    fi
    
    # Get the latest patch version from Alpine's latest-releases.yaml
    local full_version=$(curl -s https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/releases/${ALPINE_ARCH}/latest-releases.yaml 2>/dev/null | grep -m1 'version:' | awk '{print $2}')
    
    # Fallback to .1 if detection fails
    if [ -z "$full_version" ]; then
        full_version="${ALPINE_VERSION}.1"
        log_info "  Using fallback version: ${full_version}"
    else
        log_info "  Latest release: ${full_version}"
    fi
    
    # Set ISO name and URL
    ALPINE_ISO="alpine-virt-${full_version}-${ALPINE_ARCH}.iso"
    ALPINE_ISO_URL="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/releases/${ALPINE_ARCH}/${ALPINE_ISO}"
    
    # Check cache first (in repository directory)
    local cached_iso="${CACHE_DIR}/alpine/${ALPINE_ISO}"
    if [ -f "$cached_iso" ]; then
        log_info "  Using cached Alpine ISO: ${ALPINE_ISO}"
        mkdir -p "${VM_DIR}/isos"
        cp "$cached_iso" "${VM_DIR}/isos/${ALPINE_ISO}"
        log "  ✓ ISO copied from cache"
        return 0
    fi
    
    # Download to cache, then copy to VM directory
    mkdir -p "${CACHE_DIR}/alpine"
    mkdir -p "${VM_DIR}/isos"
    
    log_info "  Downloading from: ${ALPINE_ISO_URL}"
    log_info "  Caching to: ${cached_iso}"
    curl -L --progress-bar -o "$cached_iso" "${ALPINE_ISO_URL}"
    cp "$cached_iso" "${VM_DIR}/isos/${ALPINE_ISO}"
    log "  ✓ ISO downloaded and cached"
}

create_disks() {
    log "Creating VM disks..."
    
    if [ ! -f "$SYSTEM_DISK" ]; then
        qemu-img create -f qcow2 "$SYSTEM_DISK" "$SYSTEM_DISK_SIZE"
        log "  ✓ System disk created (${SYSTEM_DISK_SIZE})"
    else
        log "  ✓ System disk exists"
    fi
    
    # Check for preserved cache disk from previous test
    local cache_disk_backup="${HOME}/.factory-vm/cache-backup.qcow2"
    
    if [ ! -f "$CACHE_DISK" ]; then
        # Check if we have a preserved cache disk to restore
        if [ -f "$cache_disk_backup" ]; then
            log_info "Restoring preserved cache disk from previous installation..."
            cp "$cache_disk_backup" "$CACHE_DISK"
            rm -f "$cache_disk_backup"
            local size=$(du -h "$CACHE_DISK" | cut -f1)
            log_success "Cache disk restored (${size}) - cache will be reused!"
        else
            qemu-img create -f qcow2 "$CACHE_DISK" "$CACHE_DISK_SIZE"
            log "  ✓ Cache disk created (${CACHE_DISK_SIZE})"
        fi
    else
        log "  ✓ Cache disk exists"
    fi
    
    # Create data disk for Jenkins workspaces
    if [ ! -f "$DATA_DISK" ]; then
        qemu-img create -f qcow2 "$DATA_DISK" "$DATA_DISK_SIZE"
        log "  ✓ Data disk created (${DATA_DISK_SIZE})"
    else
        log "  ✓ Data disk exists"
    fi
}

find_uefi_firmware() {
    # x86_64 uses default BIOS, no UEFI firmware file needed
    if [ "${ALPINE_ARCH}" = "x86_64" ]; then
        echo ""  # Empty string means use default BIOS
        return 0
    fi
    
    # ARM64 UEFI firmware (for future cloud deployment)
    # UEFI firmware requires both CODE (read-only) and VARS (read-write) files
    # We'll return the CODE file path and create a writable VARS copy
    local firmware_paths=(
        "/usr/share/AAVMF/AAVMF_CODE.fd"
        "/usr/share/qemu-efi-aarch64/QEMU_EFI.fd"
        "/usr/share/edk2/aarch64/QEMU_EFI.fd"
        "/opt/homebrew/share/qemu/edk2-aarch64-code.fd"
        "/usr/share/qemu/edk2-aarch64-code.fd"
    )
    
    for path in "${firmware_paths[@]}"; do
        if [ -f "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    log_error "UEFI firmware not found"
    log_info "Install: sudo apt-get install qemu-efi-aarch64"
    exit 1
}

find_uefi_vars() {
    # Find the corresponding VARS file for the firmware
    local vars_paths=(
        "/usr/share/AAVMF/AAVMF_VARS.fd"
        "/usr/share/qemu-efi-aarch64/QEMU_VARS.fd"
        "/usr/share/edk2/aarch64/QEMU_VARS.fd"
        "/opt/homebrew/share/qemu/edk2-arm-vars.fd"
        "/usr/share/qemu/edk2-arm-vars.fd"
    )
    
    for path in "${vars_paths[@]}"; do
        if [ -f "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    # VARS file not critical if not found
    echo ""
    return 0
}

start_vm_for_install() {
    log "Starting VM for Alpine installation..."
    
    local uefi_fw=$(find_uefi_firmware)
    local iso_path="${VM_DIR}/isos/${ALPINE_ISO}"
    
    # Check UEFI firmware exists (only needed for ARM64)
    if [ "${ALPINE_ARCH}" = "aarch64" ] && [ ! -f "$uefi_fw" ]; then
        log_error "UEFI firmware not found at $uefi_fw"
        log_info "Install with: sudo apt-get install qemu-efi-aarch64"
        exit 1
    fi
    
    # Determine QEMU acceleration
    # KVM only works when host and guest architectures match
    local host_arch=$(uname -m)
    local qemu_accel=""
    
    if [ "$host_arch" = "x86_64" ] && [ "${ALPINE_ARCH}" = "x86_64" ] && [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
        # x86_64 host with KVM support - use KVM for x86_64 guest (FAST!)
        qemu_accel="-accel kvm"
        log_info "  Using KVM acceleration (x86_64 native - FAST!)"
    elif [ "$host_arch" = "aarch64" ] && [ "${ALPINE_ARCH}" = "aarch64" ] && [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
        # ARM64 host with KVM support - use KVM for ARM64 guest
        qemu_accel="-accel kvm"
        log_info "  Using KVM acceleration (ARM64 native)"
    else
        # Cross-architecture or no KVM - use TCG (software emulation, slow)
        qemu_accel="-accel tcg"
        log_info "  Using TCG emulation ($host_arch host → ${ALPINE_ARCH} guest)"
        log_info "  Note: Builds will be slower than native ARM64"
    else
        # Fallback to TCG for any other scenario
        qemu_accel="-accel tcg"
        log_info "  Using TCG emulation"
    fi
    
    log ""
    log "═══════════════════════════════════════════════════════════"
    log "  Starting automated Alpine installation"
    log "═══════════════════════════════════════════════════════════"
    log ""
    
    if [ "$qemu_accel" = "-accel tcg" ]; then
        log "  Installing Alpine Linux to disk (TCG emulation - SLOW)..."
        log "  ⚠️  WARNING: TCG emulation is 10-20x slower than KVM"
        log "  This will take 15-20 minutes (automated)"
        log "  Alpine boot alone can take 10-15 minutes with TCG emulation"
        log ""
        log "  Please be patient - the installation is working, just very slow"
    else
        log "  Installing Alpine Linux to disk (KVM acceleration - FAST!)..."
        log "  ✓ Using native virtualization"
        log "  This will take 2-3 minutes (automated)"
    fi
    log ""
    
    # Build QEMU command based on architecture
    local qemu_cmd
    if [ "${ALPINE_ARCH}" = "x86_64" ]; then
        # x86_64: Use KVM acceleration (native), default BIOS, q35 machine
        qemu_cmd="qemu-system-x86_64 -M q35 $qemu_accel -cpu host -smp $VM_CPUS -m $VM_MEMORY -drive file=$SYSTEM_DISK,if=virtio,format=qcow2 -cdrom $iso_path -device virtio-net-pci,netdev=net0 -netdev user,id=net0,hostfwd=tcp::${VM_SSH_PORT}-:22 -nographic"
    else
        # ARM64: Use TCG emulation (or KVM on ARM hosts), UEFI firmware, virt machine
        qemu_cmd="qemu-system-aarch64 -M virt $qemu_accel -cpu cortex-a72 -smp $VM_CPUS -m $VM_MEMORY -bios $uefi_fw -drive file=$SYSTEM_DISK,if=virtio,format=qcow2 -cdrom $iso_path -device virtio-net-pci,netdev=net0 -netdev user,id=net0,hostfwd=tcp::${VM_SSH_PORT}-:22 -nographic"
    fi
    
    # Export variables for expect script
    export VM_HOSTNAME VM_ROOT_PASSWORD
    export VM_SSH_PUBLIC_KEY_CONTENT="$(cat "$VM_SSH_PUBLIC_KEY")"
    export QEMU_COMMAND="$qemu_cmd"
    
    # Run automated installation using external expect script (in parent tools/ directory)
    # Filter output to remove terminal escape sequences that can corrupt the terminal
    # The ^[[...R sequences are cursor position responses from the VM's terminal
    if ! expect "$(dirname "$SCRIPT_DIR")/alpine-install.exp" 2>&1 | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g; s/;[0-9]*R//g'; then
        # Reset terminal in case expect left it in a bad state
        stty sane 2>/dev/null || true
        log_error "Alpine installation failed"
        exit 1
    fi
    
    # Reset terminal to clean state after expect/QEMU
    stty sane 2>/dev/null || true
    
    log ""
    log "✓ Alpine installation complete"
    log "  VM has been powered off"
}

# Export functions
export -f ensure_qemu check_dependencies setup_ssh_keys download_alpine
export -f create_disks find_uefi_firmware find_uefi_vars start_vm_for_install
