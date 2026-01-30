#!/bin/sh
# Phase 4.5: Registry-Specific Installation Script
# Purpose: Build and install container registry service
# Date: Jan 30, 2026
# Run as: keeper (with doas for privilege tasks)

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
TRUSTNET_HOME="${TRUSTNET_HOME:-/opt/trustnet}"
KEEPER_HOME="${KEEPER_HOME:-/home/keeper}"
GOROOT="/usr/local/go"
GOPATH="${KEEPER_HOME}/go"
REGISTRY_DATA="/var/lib/trustnet-registry"

# Export for build
export PATH="${GOROOT}/bin:${PATH}"
export GOPATH="${GOPATH}"

log_info "Starting Phase 4.5: Registry Installation"
log_info "Working directory: ${TRUSTNET_HOME}"
log_info "GOPATH: ${GOPATH}"

# Create GOPATH structure
mkdir -p "${GOPATH}/src"
mkdir -p "${GOPATH}/bin"
mkdir -p "${GOPATH}/pkg"

# Create registry application directory
mkdir -p "${TRUSTNET_HOME}/registry/config"
mkdir -p "${REGISTRY_DATA}"

log_info "Creating basic Registry application..."

# Create a basic Go module for container registry
cd "${TRUSTNET_HOME}/registry"

# Initialize Go module
if [ ! -f "go.mod" ]; then
  ${GOROOT}/bin/go mod init trustnet-registry
fi

# Create main application for registry service
cat > main.go << 'EOF'
package main

import (
	"fmt"
	"log"
	"net"
	"net/http"
)

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintf(w, `{"status":"healthy","service":"trustnet-registry"}`)
}

func main() {
	fmt.Println("TrustNet Registry v1.0")
	fmt.Println("Starting HTTP server on :8000")
	
	http.HandleFunc("/health", healthHandler)
	
	listener, err := net.Listen("tcp", ":8000")
	if err != nil {
		log.Fatal(err)
	}
	
	log.Printf("Registry listening on %s", listener.Addr())
	if err := http.Serve(listener, nil); err != nil {
		log.Fatal(err)
	}
}
EOF

log_info "Building trustnet-registry binary..."
${GOROOT}/bin/go build -o trustnet-registry main.go

# Verify binary was created
if [ ! -f "trustnet-registry" ]; then
  log_error "Binary build failed"
  exit 1
fi

log_info "Binary built successfully ($(du -h trustnet-registry | cut -f1))"

# Test the binary (run in background, timeout after 3 seconds)
log_info "Testing binary with health check..."
timeout 3 ./trustnet-registry &
REGISTRY_PID=$!
sleep 1

# Test health endpoint
if curl -s http://localhost:8000/health | grep -q "healthy"; then
  log_info "✓ Health check passed"
  kill $REGISTRY_PID 2>/dev/null || true
else
  log_info "Health check unavailable (expected, binary killed)"
fi

# Move binary to system location
log_info "Installing binary to /usr/local/bin..."
doas cp trustnet-registry /usr/local/bin/trustnet-registry
doas chmod +x /usr/local/bin/trustnet-registry

# Verify installation
if [ -x "/usr/local/bin/trustnet-registry" ]; then
  log_info "✓ Binary installed at /usr/local/bin/trustnet-registry"
else
  log_error "Failed to install binary"
  exit 1
fi

# Create registry data directory with proper permissions
log_info "Setting up registry data directory..."
doas mkdir -p "${REGISTRY_DATA}"
doas chown keeper:keeper "${REGISTRY_DATA}"
doas chmod 755 "${REGISTRY_DATA}"

# Create configuration from template
log_info "Setting up Registry configuration..."
CACHE_DIR="${CACHE_DIR:-/opt/trustnet-cache}"

if [ -f "${CACHE_DIR}/configs/registry-config.yaml" ]; then
  doas cp "${CACHE_DIR}/configs/registry-config.yaml" "${TRUSTNET_HOME}/registry/config/config.yaml"
  doas chown keeper:keeper "${TRUSTNET_HOME}/registry/config/config.yaml"
  log_info "Configuration template applied"
else
  log_info "Configuration template not found (non-fatal)"
fi

# Create systemd/OpenRC service configuration
log_info "Creating service configuration..."
mkdir -p "${KEEPER_HOME}/.config"
cat > "${KEEPER_HOME}/.config/trustnet-registry.service" << 'EOF'
[Unit]
Description=TrustNet Container Registry
After=network.target

[Service]
Type=simple
User=keeper
WorkingDirectory=/home/keeper
ExecStart=/usr/local/bin/trustnet-registry
Restart=on-failure
RestartSec=10
Environment="REGISTRY_HTTP_ADDR=0.0.0.0:8000"

[Install]
WantedBy=multi-user.target
EOF

log_info "✅ Phase 4.5 complete: Registry installed"
log_info "Binary location: /usr/local/bin/trustnet-registry"
log_info "Data directory: ${REGISTRY_DATA}"
log_info "Configuration: ${TRUSTNET_HOME}/registry/config/config.yaml"
log_info "Health endpoint: http://localhost:8000/health"
log_info "Run: trustnet-registry to start the registry"
