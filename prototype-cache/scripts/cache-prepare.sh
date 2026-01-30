#!/bin/sh
# Phase 1: Cache Preparation Script
# Purpose: Download all components needed for TrustNet installation
# Date: Jan 30, 2026
# Run on: Local machine (once, before VM setup)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CACHE_DIR="${1:-/tmp/trustnet-cache}"
GO_VERSION="1.22.0"
ALPINE_ARCH="arm64"
CHECKSUMS_FILE="${CACHE_DIR}/checksums.txt"

# Ensure cache directory exists
mkdir -p "${CACHE_DIR}/go"
mkdir -p "${CACHE_DIR}/scripts"
mkdir -p "${CACHE_DIR}/configs"

log_info() {
  echo "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

log_warn() {
  echo "${YELLOW}[$(date +'%H:%M:%S')]${NC} $1"
}

log_error() {
  echo "${RED}[$(date +'%H:%M:%S')]${NC} $1"
}

# Download Go binary
download_go() {
  log_info "Downloading Go ${GO_VERSION} for Linux ARM64..."
  
  GO_FILE="go${GO_VERSION}.linux-arm64.tar.gz"
  GO_URL="https://go.dev/dl/${GO_FILE}"
  GO_PATH="${CACHE_DIR}/go/${GO_FILE}"
  
  if [ -f "${GO_PATH}" ]; then
    log_warn "Go binary already exists at ${GO_PATH}, skipping download"
    return 0
  fi
  
  if ! command -v curl > /dev/null 2>&1; then
    log_error "curl not found, cannot download Go"
    return 1
  fi
  
  curl -L -o "${GO_PATH}" "${GO_URL}"
  
  if [ $? -eq 0 ]; then
    log_info "Go ${GO_VERSION} downloaded successfully ($(du -h "${GO_PATH}" | cut -f1))"
    return 0
  else
    log_error "Failed to download Go"
    return 1
  fi
}

# Create configuration templates
create_configs() {
  log_info "Creating configuration templates..."
  
  # doas.conf template
  cat > "${CACHE_DIR}/configs/doas.conf" << 'EOF'
# doas configuration for TrustNet
# Passwordless privilege escalation for wheel group

# Prevent default rule (requires password)
deny :wheel

# Allow wheel group to run all commands without password
permit nopass :wheel
EOF
  
  # Tendermint config template
  cat > "${CACHE_DIR}/configs/tendermint-config.toml" << 'EOF'
# Tendermint Configuration Template
# For TrustNet node deployment

[main]
home = "/home/warden/.tendermint"
level = "info"

[rpc]
laddr = "tcp://0.0.0.0:26657"
grpc_laddr = ""
unsafe = false

[p2p]
laddr = "tcp://0.0.0.0:26656"
persistent_peers = ""
addr_book_strict = true

[consensus]
timeout_propose = "1s"
timeout_propose_delta = "500ms"
timeout_prevote = "1s"
timeout_prevote_delta = "500ms"
timeout_precommit = "1s"
timeout_precommit_delta = "500ms"
timeout_commit = "5s"

[mempool]
version = "v1"
recheck = true
recheck_timeout = 0
max_tx_bytes = 1048576
max_batch_bytes = 0

[storage]
discard_abci_responses = false

[tx_index]
indexer = "kv"
psql_conn = ""
EOF
  
  # Registry config template
  cat > "${CACHE_DIR}/configs/registry-config.yaml" << 'EOF'
# TrustNet Registry Configuration Template

version: 0.1
log:
  level: info
storage:
  filesystem:
    rootdirectory: /var/lib/trustnet-registry
http:
  addr: 0.0.0.0:8000
  headers:
    X-Content-Type-Options:
      - nosniff
    X-Frame-Options:
      - DENY
health:
  storagedriver:
    enabled: true
    interval: 10s
EOF
  
  log_info "Configuration templates created"
}

# Generate SHA256 checksums
generate_checksums() {
  log_info "Generating SHA256 checksums..."
  
  > "${CHECKSUMS_FILE}"  # Empty the file
  
  for file in "${CACHE_DIR}"/go/* "${CACHE_DIR}"/configs/*; do
    if [ -f "$file" ]; then
      sha256sum "$file" >> "${CHECKSUMS_FILE}"
    fi
  done
  
  log_info "Checksums written to ${CHECKSUMS_FILE}"
}

# Verify checksums
verify_checksums() {
  log_info "Verifying checksums..."
  
  if [ ! -f "${CHECKSUMS_FILE}" ]; then
    log_warn "No checksums file found, skipping verification"
    return 0
  fi
  
  cd "${CACHE_DIR}"
  if sha256sum -c "${CHECKSUMS_FILE}"; then
    log_info "All checksums verified ✓"
    return 0
  else
    log_error "Checksum verification failed"
    return 1
  fi
}

# Display cache summary
show_summary() {
  log_info "Cache preparation complete!"
  echo ""
  echo "Cache directory: ${CACHE_DIR}"
  echo "Contents:"
  du -sh "${CACHE_DIR}"/*
  echo ""
  echo "Files:"
  find "${CACHE_DIR}" -type f | sort
}

# Main execution
main() {
  log_info "Starting Phase 1: Cache Preparation"
  log_info "Cache directory: ${CACHE_DIR}"
  echo ""
  
  download_go || exit 1
  create_configs
  generate_checksums
  verify_checksums || exit 1
  
  echo ""
  show_summary
  echo ""
  log_info "✅ Cache preparation complete. Ready for Phase 2 (Alpine OS installation)"
}

main "$@"
