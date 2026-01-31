#!/bin/bash
# vm-bootstrap.sh - Bootstrap Factory VM after Alpine installation
# Part of Phase 3.5 modular architecture

# Prevent direct execution
if [ "${BASH_SOURCE[0]}" -ef "$0" ]; then
    echo "Error: This script should be sourced, not executed directly"
    exit 1
fi

setup_cache_disk_in_vm() {
    log "Setting up cache disk (vdb) for build cache..."
    
    # Check if cache disk has a filesystem
    if ! ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost "sudo blkid /dev/vdb" 2>/dev/null | grep -q "TYPE=\"ext4\""; then
        
        log_info "Cache disk not formatted - creating ext4 filesystem..."
        ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost "sudo mkfs.ext4 -F -L trustnet-cache /dev/vdb" >/dev/null 2>&1
        
        log_success "Cache disk formatted (ext4)"
    else
        log_info "Cache disk already formatted (reusing preserved cache)"
    fi
    
    # Create mount point and mount cache disk
    ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost "sudo mkdir -p /var/cache/trustnet-build && sudo mount /dev/vdb /var/cache/trustnet-build && sudo chown -R ${VM_USERNAME}:${VM_USERNAME} /var/cache/trustnet-build"
    
    # Add to fstab for auto-mount on boot
    ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost "grep -q '/dev/vdb' /etc/fstab || echo '/dev/vdb /var/cache/trustnet-build ext4 defaults 0 2' | sudo tee -a /etc/fstab" >/dev/null
    
    log_success "Cache disk mounted at /var/cache/trustnet-build"
}

setup_data_disk_in_vm() {
    log "Setting up data disk (vdc) for TrustNet blockchain data..."
    
    # Check if data disk has a filesystem
    if ! ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost "sudo blkid /dev/vdc" 2>/dev/null | grep -q "TYPE=\"ext4\""; then
        
        log_info "Data disk not formatted - creating ext4 filesystem..."
        ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost "sudo mkfs.ext4 -F -L trustnet-data /dev/vdc" >/dev/null 2>&1
        
        log_success "Data disk formatted (ext4)"
    else
        log_info "Data disk already formatted (reusing preserved blockchain data)"
    fi
    
    # Create mount point and mount data disk at /var/lib/trustnet
    # Set ownership to warden user
    ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost "sudo mkdir -p /var/lib/trustnet && sudo mount /dev/vdc /var/lib/trustnet && sudo chown -R ${VM_USERNAME}:${VM_USERNAME} /var/lib/trustnet"
    
    # Add to fstab for auto-mount on boot
    ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost "grep -q '/dev/vdc' /etc/fstab || echo '/dev/vdc /var/lib/trustnet ext4 defaults 0 2' | sudo tee -a /etc/fstab" >/dev/null
    
    log_success "Data disk mounted at /var/lib/trustnet"
}

configure_installed_vm() {
    log "Configuring installed TrustNet VM..."
    
    # Start VM using the start script
    log_info "Starting VM from installed system..."
    if ! "${VM_DIR}/start-trustnet.sh" >/dev/null 2>&1; then
        log_error "Failed to start TrustNet VM"
        exit 1
    fi
    
    sleep 5
    
    # Remove old SSH host key from known_hosts (VM was reinstalled)
    log_info "Removing old SSH host key from known_hosts..."
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[localhost]:${VM_SSH_PORT}" 2>/dev/null || true
    
    # Wait for SSH port to open
    log_info "Waiting for SSH port to open..."
    local count=0
    while ! nc -z localhost "$VM_SSH_PORT" 2>/dev/null && [ $count -lt 60 ]; do
        sleep 2
        ((count++))
        echo -n "."
    done
    echo ""
    
    if [ $count -ge 60 ]; then
        log_error "VM failed to start - SSH port never opened"
        exit 1
    fi
    
    # Port is open, but SSH may not be fully ready - wait for Alpine to finish booting
    # Detect acceleration type to show appropriate message
    local host_arch=$(uname -m)
    if [ "$host_arch" = "${ALPINE_ARCH}" ] && [ -e /dev/kvm ]; then
        log_info "Port open, waiting for Alpine to finish booting (KVM acceleration)..."
        log_info "This should take 30-60 seconds with native virtualization..."
    else
        log_info "Port open, waiting for Alpine to finish booting (TCG emulation)..."
        log_info "This can take 3-5 minutes on TCG emulation, please be patient..."
    fi
    local ssh_test_attempts=0
    local max_attempts=60  # 60 attempts × 5 seconds = 300 seconds (5 minutes)
    while [ $ssh_test_attempts -lt $max_attempts ]; do
        if ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 \
            -p "$VM_SSH_PORT" root@localhost "echo ready" >/dev/null 2>&1; then
            log_info "SSH is ready!"
            break
        fi
        ssh_test_attempts=$((ssh_test_attempts + 1))
        if [ $((ssh_test_attempts % 6)) -eq 0 ]; then
            log_info "Still waiting... ($((ssh_test_attempts * 5)) seconds elapsed)"
        fi
        sleep 5
    done
    
    if [ $ssh_test_attempts -ge $max_attempts ]; then
        log_error "SSH did not become ready after 300 seconds"
        log_error "This might indicate a problem with the Alpine installation"
        exit 1
    fi
    
    # Create ${VM_USERNAME} user
    log "Creating ${VM_USERNAME} user with sudo privileges..."
    if ! ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=60 -o ServerAliveInterval=5 -p "$VM_SSH_PORT" root@localhost << EOF
# Create ${VM_USERNAME} user
adduser -D ${VM_USERNAME}
echo "${VM_USERNAME}:${WARDEN_OS_PASSWORD}" | chpasswd

# Add to necessary groups
addgroup ${VM_USERNAME} wheel
addgroup ${VM_USERNAME} docker

# Configure doas (Alpine's sudo alternative)
apk add doas
echo "permit nopass :wheel" > /etc/doas.d/doas.conf
chmod 600 /etc/doas.d/doas.conf

# Configure sudoers for passwordless sudo (Alpine installs real sudo as dependency)
# Create sudoers.d directory if it doesn't exist
mkdir -p /etc/sudoers.d
# Allow wheel group to use sudo without password
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

# Setup SSH directory
mkdir -p /home/${VM_USERNAME}/.ssh
chmod 700 /home/${VM_USERNAME}/.ssh

# Copy SSH key from root to ${VM_USERNAME}
cp /root/.ssh/authorized_keys /home/${VM_USERNAME}/.ssh/authorized_keys
chmod 600 /home/${VM_USERNAME}/.ssh/authorized_keys
chown -R ${VM_USERNAME}:${VM_USERNAME} /home/${VM_USERNAME}/.ssh

# Set bash as default shell
apk add bash
sed -i "s|/home/${VM_USERNAME}:/bin/ash|/home/${VM_USERNAME}:/bin/bash|" /etc/passwd

# Install utilities needed for data disk setup and SSH commands
# - e2fsprogs-extra: provides mkfs.ext4 (for formatting if needed)
# - blkid: provides blkid command (for detecting existing filesystem)
apk add e2fsprogs-extra blkid

# Create sudo wrapper script for compatibility (Alpine uses doas)
# This works in SSH non-login shell contexts
cat > /usr/local/bin/sudo << 'SUDO_WRAPPER'
#!/bin/sh
exec doas "\$@"
SUDO_WRAPPER
chmod 755 /usr/local/bin/sudo

# Create .bashrc for ${VM_USERNAME} user
cat > /home/${VM_USERNAME}/.bashrc << 'BASHRC_INIT'
# ~/.bashrc: executed by bash for non-login shells

# If not running interactively, don't do anything
case \$- in
    *i*) ;;
      *) return;;
esac

# Basic environment
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export EDITOR=vim

# Aliases
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'

# Command history
HISTCONTROL=ignoredups:ignorespace
HISTSIZE=1000
HISTFILESIZE=2000

# Enable bash completion
if [ -f /etc/bash/bashrc.d/bash_completion.sh ]; then
    . /etc/bash/bashrc.d/bash_completion.sh
fi
BASHRC_INIT

chown ${VM_USERNAME}:${VM_USERNAME} /home/${VM_USERNAME}/.bashrc

# Harden SSH configuration - disable password authentication
cat >> /etc/ssh/sshd_config << 'SSH_CONFIG'

# Factory VM Security Configuration
# Disable password authentication - SSH keys only
PasswordAuthentication no
PermitRootLogin prohibit-password
PubkeyAuthentication yes
ChallengeResponseAuthentication no
SSH_CONFIG

# Restart SSH to apply changes
rc-service sshd restart

# Wait for SSH to fully restart before allowing external connections
sleep 5

echo "✓ ${VM_USERNAME} user created"
echo "✓ SSH hardened (keys only, no password authentication)"
EOF
    then
        log_error "Failed to create ${VM_USERNAME} user"
        exit 1
    fi
    
    # Add SSH public key
    log "Adding SSH public key for ${VM_USERNAME}..."
    if ! ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" root@localhost << EOF
echo '$(cat "$VM_SSH_PUBLIC_KEY")' > /home/${VM_USERNAME}/.ssh/authorized_keys
chmod 600 /home/${VM_USERNAME}/.ssh/authorized_keys
chown -R ${VM_USERNAME}:${VM_USERNAME} /home/${VM_USERNAME}/.ssh
# Verify key was added
if [ -f /home/${VM_USERNAME}/.ssh/authorized_keys ]; then
    echo "✓ SSH key added successfully"
else
    echo "ERROR: Failed to create authorized_keys file"
    exit 1
fi
EOF
    then
        log_error "Failed to add SSH public key"
        exit 1
    fi

    # Wait for SSH to be fully ready after sshd restart
    log_info "Waiting for SSH to be fully ready..."
    local ssh_ready=0
    for i in {1..30}; do
        if ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -o ConnectTimeout=5 -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost "echo OK" >/dev/null 2>&1; then
            ssh_ready=1
            break
        fi
        sleep 2
    done
    
    if [ $ssh_ready -eq 0 ]; then
        log_error "SSH did not become ready for ${VM_USERNAME} user in time"
        exit 1
    fi
    
    log_success "SSH is ready"
    
    # Give SSH/SCP a bit more time to fully stabilize after restart
    sleep 5

    # Setup cache disk for persistent build cache (vdb)
    setup_cache_disk_in_vm
    
    # Setup data disk for blockchain data (vdc)
    setup_data_disk_in_vm
    
    # Prepare cache directories for blockchain tools
    log_info "Preparing cache directories..."
    ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost "mkdir -p /var/cache/trustnet-build/{go,ignite,blockchain}"
    
    log_success "VM bootstrap complete"
}

# Export functions
export -f setup_cache_disk_in_vm setup_data_disk_in_vm configure_installed_vm
