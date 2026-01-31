#!/bin/bash
# common.sh - Shared utilities for Factory VM setup
# 
# Provides:
# - Logging functions (log, log_error, log_warning, log_info, log_success)
# - Color codes for terminal output
# - SSH execution wrapper (ssh_exec)
# - Password generation
# - Configuration variables

################################################################################
# Color Codes
################################################################################

# ANSI color codes for terminal output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'  # No Color / Reset

################################################################################
# Configuration Variables
################################################################################

# VM Basic Configuration
export VM_DIR="${VM_DIR:-${HOME}/vms/factory}"
export VM_NAME="${VM_NAME:-factory}"
export VM_MEMORY="${VM_MEMORY:-4G}"
export VM_CPUS="${VM_CPUS:-4}"
export VM_SSH_PORT="${VM_SSH_PORT:-2222}"

# VM Network and Identity
export VM_HOSTNAME="${VM_HOSTNAME:-factory.local}"
export VM_USERNAME="${VM_USERNAME:-foreman}"
export SSH_KEY_NAME="${SSH_KEY_NAME:-factory-foreman}"

# Disk Configuration
export SYSTEM_DISK_SIZE="${SYSTEM_DISK_SIZE:-50G}"
export DATA_DISK_SIZE="${DATA_DISK_SIZE:-50G}"
export SYSTEM_DISK="${SYSTEM_DISK:-${VM_DIR}/${VM_NAME}.qcow2}"
export DATA_DISK="${DATA_DISK:-${VM_DIR}/${VM_NAME}-data.qcow2}"

# SSH Configuration
export VM_SSH_PRIVATE_KEY="${VM_SSH_PRIVATE_KEY:-${HOME}/.ssh/${SSH_KEY_NAME}}"
export VM_SSH_PUBLIC_KEY="${VM_SSH_PUBLIC_KEY:-${HOME}/.ssh/${SSH_KEY_NAME}.pub}"

# Security - Passwords generated at runtime
export JENKINS_FOREMAN_PASSWORD="${JENKINS_FOREMAN_PASSWORD:-}"

# Alpine Configuration
export ALPINE_VERSION="${ALPINE_VERSION:-3.22}"
export ALPINE_ARCH="${ALPINE_ARCH:-aarch64}"

################################################################################
# Logging Functions
################################################################################

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

################################################################################
# Utility Functions
################################################################################

# Generate cryptographically secure random password
generate_secure_password() {
    # Generate 20-character password with letters, numbers, and safe symbols
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-20
}

# Execute command via SSH with standard options
# Usage: ssh_exec "command to run"
ssh_exec() {
    ssh -i "$VM_SSH_PRIVATE_KEY" \
        -p "$VM_SSH_PORT" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=60 \
        -o ServerAliveInterval=30 \
        "${VM_USERNAME}@localhost" "$@"
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Wait with timeout
wait_with_timeout() {
    local timeout=$1
    local check_command=$2
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        if eval "$check_command"; then
            return 0
        fi
        sleep 1
        ((elapsed++))
    done
    
    return 1
}

################################################################################
# Validation Functions
################################################################################

# Validate VM configuration
validate_config() {
    local errors=0
    
    if [[ ! "$VM_MEMORY" =~ ^[0-9]+[GMK]$ ]]; then
        log_error "Invalid VM_MEMORY format: $VM_MEMORY (should be like 4G, 2048M)"
        ((errors++))
    fi
    
    if [[ ! "$VM_CPUS" =~ ^[0-9]+$ ]] || [ "$VM_CPUS" -lt 1 ]; then
        log_error "Invalid VM_CPUS: $VM_CPUS (should be a positive integer)"
        ((errors++))
    fi
    
    if [[ ! "$VM_SSH_PORT" =~ ^[0-9]+$ ]] || [ "$VM_SSH_PORT" -lt 1024 ] || [ "$VM_SSH_PORT" -gt 65535 ]; then
        log_error "Invalid VM_SSH_PORT: $VM_SSH_PORT (should be 1024-65535)"
        ((errors++))
    fi
    
    return $errors
}

# Show current configuration
show_config() {
    log_info "Factory VM Configuration:"
    echo "  VM Name:          $VM_NAME"
    echo "  VM Hostname:      $VM_HOSTNAME"
    echo "  VM Username:      $VM_USERNAME"
    echo "  VM Memory:        $VM_MEMORY"
    echo "  VM CPUs:          $VM_CPUS"
    echo "  VM SSH Port:      $VM_SSH_PORT"
    echo "  System Disk Size: $SYSTEM_DISK_SIZE"
    echo "  Data Disk Size:   $DATA_DISK_SIZE"
    echo "  VM Directory:     $VM_DIR"
}

################################################################################
# Module Initialization
################################################################################

# Verify this module is being sourced, not executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: common.sh should be sourced, not executed directly"
    echo "Usage: source ${BASH_SOURCE[0]}"
    exit 1
fi

# Export all functions for use by other modules
export -f log log_error log_warning log_info log_success
export -f generate_secure_password
export -f ssh_exec
export -f command_exists wait_with_timeout
export -f validate_config show_config
