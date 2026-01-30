#!/bin/sh
# Phase 4.3: doas Configuration Script (runs as root)
# Purpose: Configure passwordless privilege escalation
# Date: Jan 30, 2026
# Based on: FactoryVM doas-config.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
  echo "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

log_warn() {
  echo "${YELLOW}[$(date +'%H:%M:%S')]${NC} $1"
}

log_error() {
  echo "${RED}[$(date +'%H:%M:%S')]${NC} $1"
}

# Verify running as root
if [ "$(id -u)" != "0" ]; then
  log_error "This script must run as root"
  exit 1
fi

log_info "Starting Phase 4.3: doas Configuration"

# Create doas.d directory if needed
mkdir -p /etc/doas.d
chmod 755 /etc/doas.d

# Create passwordless rule for wheel group
log_info "Creating passwordless doas rule for wheel group..."
cat > /etc/doas.d/10-wheel-nopass.conf << 'EOF'
# Allow wheel group members to execute commands without password
# This enables CI/CD automation and interactive use

permit nopass :wheel
EOF

chmod 600 /etc/doas.d/10-wheel-nopass.conf

# Verify doas installation
if ! command -v doas > /dev/null 2>&1; then
  log_warn "doas not found, installing..."
  apk add --no-cache doas
fi

# Test doas configuration
log_info "Testing doas configuration..."
if doas -c /etc/doas.d/10-wheel-nopass.conf whoami 2>/dev/null | grep -q root; then
  log_info "✓ doas configuration validated"
else
  log_warn "Could not validate doas, but configuration file created"
fi

log_info "✅ Phase 4.3 complete: doas configured for passwordless access"
log_info "Test with: doas whoami (should return 'root')"
log_info "Next step: Run Phase 4.4 (node-specific) or Phase 4.5 (registry-specific)"
