#!/bin/sh
# Phase 4.2: User Setup Script (runs as root)
# Purpose: Create user account with proper permissions
# Date: Jan 30, 2026
# Based on: FactoryVM user-setup.sh
# Usage: user-setup.sh <username>

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
  echo "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

log_error() {
  echo "${RED}[$(date +'%H:%M:%S')]${NC} $1"
}

# Configuration
USERNAME="${1:-warden}"
UID="${UID:-1000}"
SHELL="/bin/sh"
HOME_DIR="/home/${USERNAME}"

# Verify running as root
if [ "$(id -u)" != "0" ]; then
  log_error "This script must run as root"
  exit 1
fi

if [ -z "$USERNAME" ]; then
  log_error "Usage: user-setup.sh <username>"
  exit 1
fi

log_info "Starting Phase 4.2: User Setup for '${USERNAME}'"

# Create wheel group if not exists
if ! getent group wheel > /dev/null; then
  log_info "Creating wheel group..."
  addgroup wheel
else
  log_info "wheel group already exists"
fi

# Create user if not exists
if getent passwd "$USERNAME" > /dev/null; then
  log_info "User ${USERNAME} already exists, skipping creation"
else
  log_info "Creating user ${USERNAME}..."
  adduser \
    --disabled-password \
    --gecos "TrustNet ${USERNAME} user" \
    --home "${HOME_DIR}" \
    --shell "${SHELL}" \
    --uid "${UID}" \
    "${USERNAME}"
  
  log_info "User ${USERNAME} created (UID ${UID})"
fi

# Add user to wheel group
log_info "Adding ${USERNAME} to wheel group..."
addgroup "${USERNAME}" wheel

# Create home directory structure
log_info "Setting up home directory..."
mkdir -p "${HOME_DIR}/.ssh"
mkdir -p "${HOME_DIR}/.tendermint"  # For node-specific setup
mkdir -p "${HOME_DIR}/.local/bin"

# Set proper permissions
chown -R "${USERNAME}:${USERNAME}" "${HOME_DIR}"
chmod 700 "${HOME_DIR}"
chmod 700 "${HOME_DIR}/.ssh"
chmod 700 "${HOME_DIR}/.tendermint"
chmod 755 "${HOME_DIR}/.local/bin"

# Configure SSH (if needed for key-based auth)
log_info "SSH directory ready at ${HOME_DIR}/.ssh"

# Set environment for user
log_info "Setting up user environment..."
cat > "${HOME_DIR}/.profile" << 'EOF'
# TrustNet user profile

export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOROOT/bin:$GOPATH/bin:$HOME/.local/bin:$PATH

# Aliases
alias ll='ls -la'
alias la='ls -A'
EOF

chown "${USERNAME}:${USERNAME}" "${HOME_DIR}/.profile"
chmod 644 "${HOME_DIR}/.profile"

log_info "✅ Phase 4.2 complete: User ${USERNAME} setup finished"
log_info "Home directory: ${HOME_DIR}"
log_info "Next step: Run Phase 4.3 (doas configuration)"
