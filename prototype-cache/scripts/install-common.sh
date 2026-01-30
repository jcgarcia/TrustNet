#!/bin/sh
# Phase 4.1: Common Setup Script (runs as root)
# Purpose: Install base packages, extract Go, create directories
# Date: Jan 30, 2026
# Based on: FactoryVM install-common.sh

set -e

# Configuration
GO_VERSION="1.22.0"
CACHE_DIR="${CACHE_DIR:-/opt/trustnet-cache}"
TRUSTNET_HOME="/opt/trustnet"

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

log_info "Starting Phase 4.1: Common Setup (as root)"

# Update package manager
log_info "Updating apk package manager..."
apk update

# Install required packages
log_info "Installing build tools and dependencies..."
apk add --no-cache \
  gcc \
  musl-dev \
  make \
  git \
  curl \
  openssl-dev \
  ca-certificates \
  tzdata \
  bash

# Create cache directory for future use
log_info "Creating cache directory /var/cache/trustnet..."
mkdir -p /var/cache/trustnet
chmod 755 /var/cache/trustnet

# Create application home
log_info "Creating TrustNet home directory..."
mkdir -p "${TRUSTNET_HOME}"
chmod 755 "${TRUSTNET_HOME}"

# Extract Go binary
log_info "Extracting Go ${GO_VERSION}..."
GO_FILE="${CACHE_DIR}/go/go${GO_VERSION}.linux-arm64.tar.gz"

if [ ! -f "${GO_FILE}" ]; then
  log_error "Go binary not found at ${GO_FILE}"
  exit 1
fi

tar -xzf "${GO_FILE}" -C /usr/local
log_info "Go extracted to /usr/local/go"

# Create Go symlinks
ln -sf /usr/local/go/bin/go /usr/local/bin/go 2>/dev/null || true
ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt 2>/dev/null || true

# Verify Go installation
log_info "Verifying Go installation..."
GO_PATH="/usr/local/go/bin/go"
if [ ! -x "${GO_PATH}" ]; then
  log_error "Go binary not executable at ${GO_PATH}"
  exit 1
fi

GO_VERSION_OUTPUT=$("${GO_PATH}" version)
log_info "Go installed: ${GO_VERSION_OUTPUT}"

# Verify checksums (if file exists)
if [ -f "${CACHE_DIR}/checksums.txt" ]; then
  log_info "Verifying component checksums..."
  cd "${CACHE_DIR}"
  if sha256sum -c checksums.txt > /dev/null 2>&1; then
    log_info "Checksums verified ✓"
  else
    log_warn "Some checksums could not be verified (non-fatal)"
  fi
fi

# Set environment variables for future use
log_info "Setting environment variables..."
cat > /etc/profile.d/trustnet.sh << 'EOF'
export GOROOT=/usr/local/go
export GOPATH=/opt/trustnet/go
export PATH=$GOROOT/bin:$GOPATH/bin:$PATH
EOF

log_info "✅ Phase 4.1 complete: Common setup finished"
log_info "Next step: Run Phase 4.2 (user setup)"
