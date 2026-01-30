# FactoryVM Code Reuse Analysis for TrustNet Prototype

**Purpose**: Identify reusable components from FactoryVM for TrustNet prototype  
**Status**: ✅ Complete analysis (Jan 30, 2026)  
**Audience**: Implementation team  

---

## Executive Summary

FactoryVM has **excellent, production-tested** code for:
1. ✅ VM creation & lifecycle management
2. ✅ Cache management & binary downloads
3. ✅ SSH-based remote configuration
4. ✅ Multi-disk setup (system, cache, data)
5. ✅ Service installation patterns
6. ✅ Error handling & logging

**Recommendation**: Copy and adapt FactoryVM's modular architecture for TrustNet. **Don't reinvent** VM management.

---

## Part 1: FactoryVM Project Structure

```
FactoryVM-wip/
├── tools/
│   ├── setup-factory-vm.sh          ← Main entry point
│   ├── cache-manager.sh             ← Download & cache binaries
│   ├── install-remote-certs.sh
│   ├── lib/
│   │   ├── common.sh                ← Logging, colors, utilities
│   │   ├── vm-bootstrap.sh          ← VM post-install setup
│   │   ├── vm-lifecycle.sh          ← Start/stop/status
│   │   ├── cache-manager.sh         ← Cache operations
│   │   ├── install-base.sh          ← Base OS packages
│   │   ├── install-docker.sh        ← Docker installation
│   │   ├── install-go.sh            ← Go installation
│   │   ├── install-caddy.sh         ← Caddy reverse proxy
│   │   ├── install-jenkins.sh       ← Jenkins CI/CD
│   │   ├── install-kubernetes.sh    ← k8s tools
│   │   ├── install-terraform.sh     ← Terraform
│   │   └── [others...]
│   └── cache/                       ← Downloaded binaries cached here
└── alpine-install.exp               ← Alpine ISO automatic installation
```

---

## Part 2: Reusable Components for TrustNet

### 2.1 Logging & Utilities (REUSE AS-IS)

**File**: `lib/common.sh` (180 lines)

**What it provides**:
```bash
log()           # Green timestamp message
log_error()     # Red error message
log_warning()   # Yellow warning
log_info()      # Blue info
log_success()   # Green success with checkmark

# Color codes
RED, GREEN, YELLOW, BLUE, NC

# SSH helper
ssh_exec()      # Execute command on VM
generate_password()
```

**For TrustNet**: Copy entire file, add TrustNet-specific variables (REGISTRY_IPV6, NODE_IPV6, DOMAIN, etc.)

---

### 2.2 VM Lifecycle Management (ADAPT)

**Files**: `lib/vm-lifecycle.sh`, `lib/vm-bootstrap.sh`

**What it does**:
```bash
start_vm()              # Start VM from disk image
stop_vm()               # Stop VM gracefully
get_vm_status()         # Check if running
wait_for_ssh()          # Wait for SSH port to open
setup_cache_disk()      # Mount cache disk (/var/cache)
setup_data_disk()       # Mount data disk (/var/lib)
configure_installed_vm()  # Post-install setup
```

**For TrustNet**: 
- Adapt for **Docker containers** instead of VMs (simpler for prototype)
- If using VMs: Copy and customize for Registry and Node VMs
- Key reusable patterns:
  - SSH key setup
  - Disk mounting
  - Service startup
  - Health checks

---

### 2.3 Cache Management (REUSE WITH MODS)

**File**: `lib/cache-manager.sh` (404 lines)

**What it does**:
```bash
download_and_cache_terraform()      # Cache binary downloads
download_and_cache_kubectl()
download_and_cache_helm()
download_and_cache_jenkins_image()  # Cache Docker images

# Version detection
get_latest_terraform_version()
get_latest_kubectl_version()
```

**For TrustNet** (High priority):
```bash
# Add to cache-manager.sh:
download_and_cache_trustnet_registry()
  └─ Downloads: registry service binary or Docker image
  └─ Caches to: ~/.trustnet/cache/registry/

download_and_cache_trustnet_node()
  └─ Downloads: node software binary
  └─ Caches to: ~/.trustnet/cache/node/

download_and_cache_trustnet_cli()
  └─ Downloads: CLI tools
  └─ Caches to: ~/.trustnet/cache/cli/

cache_docker_images()  # If using Docker
  └─ Pre-pull registry image
  └─ Pre-pull node image
```

**Why this matters**:
- Prototype script can run offline (after first download)
- Fast re-runs (no network latency)
- Works in environments with limited bandwidth
- FactoryVM already tested this pattern extensively

---

### 2.4 Service Installation (ADAPT)

**Files**: `lib/install-docker.sh`, `lib/install-go.sh`, `lib/install-jenkins.sh`

**Pattern** (from install-docker.sh):
```bash
install_docker_via_ssh() {
    log_info "Installing Docker..."
    
    ssh -i "$VM_SSH_PRIVATE_KEY" -p "$VM_SSH_PORT" \
        foreman@localhost << 'EOF'
# Commands to execute on remote VM
echo "Installing Docker..."
sudo apk add docker docker-compose
# ... configure ...
sudo service docker start
EOF
    
    log_success "Docker installed"
}
```

**For TrustNet**: Create similar patterns:
```bash
install_registry_via_ssh() {
    # Use cached registry binary/image
    # Configure with registry-config.yml
    # Start service
    # Health check
}

install_node_via_ssh() {
    # Use cached node binary
    # Configure with node-config.yml
    # Start service
    # Verify registration with registry
}

install_ipv6_via_ssh() {
    # Enable IPv6 on system
    # Configure DHCPv6
    # Verify connectivity
}
```

---

## Part 3: TrustNet Prototype Architecture (Based on FactoryVM)

### Directory Structure to Create

```
~/.trustnet/                          ← User's TrustNet workspace
├── cache/                            ← Downloaded binaries (persistent)
│   ├── registry/
│   │   ├── registry-service-v0.1.0
│   │   └── registry-docker-image.tar
│   ├── node/
│   │   ├── node-v0.1.0
│   │   └── node-docker-image.tar
│   └── cli/
│       └── trustnet-cli-v0.1.0
├── scripts/
│   ├── trustnet-install              ← Main installation script
│   ├── lib/
│   │   ├── common.sh                 ← Copy from FactoryVM
│   │   ├── cache-manager.sh          ← Adapted for TrustNet
│   │   ├── registry-installer.sh     ← New: install registry
│   │   ├── node-installer.sh         ← New: install node
│   │   ├── ipv6-setup.sh             ← New: IPv6 configuration
│   │   ├── dns-manager.sh            ← New: DNS verification
│   │   └── vm-lifecycle.sh           ← Copy from FactoryVM (if VMs)
│   └── alpine-install.exp            ← Copy from FactoryVM (if VMs)
├── vms/                              ← (If using VMs)
│   ├── registry/
│   │   ├── registry.qcow2
│   │   └── registry-data.qcow2
│   └── node-1/
│       └── node-1.qcow2
└── config/
    ├── registry-config.yml           ← Generated during install
    └── node-config.yml               ← Generated during install
```

---

## Part 4: Reusable Code Files

### Core Files to Copy from FactoryVM

| File | Size | Use Case | Modification Level |
|------|------|----------|-------------------|
| `common.sh` | 180 lines | Logging, utilities | **Minimal** - Add TrustNet variables |
| `cache-manager.sh` | 404 lines | Cache mgmt | **Moderate** - Add TrustNet downloads |
| `vm-lifecycle.sh` | 300+ lines | VM management | **High** - Adapt for Docker or VMs |
| `vm-bootstrap.sh` | 300+ lines | Post-install setup | **High** - Adapt for TrustNet services |
| `install-docker.sh` | 87 lines | Pattern reference | **High** - Create registry/node installers |

**Total reusable LOC**: ~1,200 lines
**Time saved**: ~3-4 weeks (don't build VM infrastructure from scratch)

---

## Part 5: Implementation Plan

### Week 1: Copy & Adapt FactoryVM Code

#### Step 1: Copy Core Infrastructure
```bash
cp -r FactoryVM-wip/tools/lib ~/.trustnet/lib/
cp FactoryVM-wip/tools/lib/common.sh ~/.trustnet/scripts/lib/
cp FactoryVM-wip/tools/lib/cache-manager.sh ~/.trustnet/scripts/lib/
```

#### Step 2: Create TrustNet-Specific Modules
```
~/.trustnet/scripts/lib/
├── common.sh                    ← FROM FactoryVM (minimal mods)
├── cache-manager.sh             ← FROM FactoryVM (add TrustNet downloads)
├── registry-installer.sh        ← NEW (based on install-docker.sh pattern)
├── node-installer.sh            ← NEW (based on install-docker.sh pattern)
├── ipv6-setup.sh                ← NEW (IPv6 detection/enabling)
├── dns-manager.sh               ← NEW (DNS lookup, verification)
└── vm-lifecycle.sh              ← FROM FactoryVM (if using VMs)
```

#### Step 3: Write Main Install Script
```bash
~/.trustnet/scripts/trustnet-install
└─ Parse domain parameter
└─ Source lib/common.sh
└─ Source lib/cache-manager.sh
└─ Source lib/dns-manager.sh
└─ Source lib/registry-installer.sh
└─ Source lib/node-installer.sh
└─ Execute installation
```

---

## Part 6: Specific Code Patterns to Reuse

### Pattern 1: Logging (From common.sh)
```bash
#!/bin/bash
# From FactoryVM's common.sh - COPY AS-IS

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}
```

### Pattern 2: SSH Execution (From vm-bootstrap.sh)
```bash
# COPY THIS PATTERN for remote installation

ssh -i "$VM_SSH_PRIVATE_KEY" -p "$VM_SSH_PORT" \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=60 -o ServerAliveInterval=30 \
    foreman@localhost << 'EOF'

# Commands here execute on remote VM
echo "Setting up service..."
sudo apk add required-packages
sudo mkdir -p /var/lib/service
sudo chown -R foreman:foreman /var/lib/service

EOF
```

### Pattern 3: Cache Management (From cache-manager.sh)
```bash
# ADAPT THIS PATTERN for TrustNet

download_and_cache_trustnet_registry() {
    local version="$1"
    local cache_file="${CACHE_DIR}/registry/registry-${version}"
    
    if [ -f "$cache_file" ]; then
        log_info "Registry ${version} already cached"
        return 0
    fi
    
    log_info "Downloading Registry ${version}..."
    mkdir -p "${CACHE_DIR}/registry"
    if curl -sL "https://github.com/Ingasti/trustnet/releases/download/${version}/registry-linux-arm64" \
        -o "$cache_file"; then
        chmod +x "$cache_file"
        log_success "Registry ${version} cached"
    else
        log_error "Failed to download Registry"
        return 1
    fi
}
```

### Pattern 4: Service Installation (From install-docker.sh)
```bash
# ADAPT THIS PATTERN for TrustNet

install_registry_via_ssh() {
    log_info "Installing TrustNet Registry..."
    
    ssh -i "$VM_SSH_PRIVATE_KEY" -p "$VM_SSH_PORT" \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        foreman@localhost << 'EOF'

# Copy cached registry binary
sudo cp /tmp/registry-v0.1.0 /usr/local/bin/trustnet-registry
sudo chmod +x /usr/local/bin/trustnet-registry

# Create config
sudo tee /etc/trustnet/registry-config.yml > /dev/null << 'CONFIG'
registry:
  role: "root"
  ipv6_address: "REGISTRY_IPV6_HERE"
  port: 8000
CONFIG

# Start service
sudo mkdir -p /var/lib/trustnet/registry
sudo trustnet-registry --config /etc/trustnet/registry-config.yml &

EOF

    log_success "Registry installed"
}
```

---

## Part 7: File-by-File Implementation Guide

### File 1: `~/.trustnet/scripts/lib/common.sh`

**Action**: Copy from FactoryVM, add these variables at top:
```bash
# TrustNet Variables
export DOMAIN="${DOMAIN:-}"
export REGISTRY_IPV6="${REGISTRY_IPV6:-}"
export NODE_IPV6="${NODE_IPV6:-}"
export REGISTRY_VM_NAME="${REGISTRY_VM_NAME:-trustnet-root-1}"
export NODE_VM_NAME="${NODE_VM_NAME:-node-1}"

# Paths
export TRUSTNET_CACHE_DIR="${HOME}/.trustnet/cache"
export TRUSTNET_CONFIG_DIR="${HOME}/.trustnet/config"
export TRUSTNET_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
```

**Size**: ~200 lines (minimal changes)

---

### File 2: `~/.trustnet/scripts/lib/cache-manager.sh`

**Action**: Copy from FactoryVM, add:
```bash
# Add to cache-manager.sh

download_and_cache_trustnet_registry() {
    local version="${1:-v0.1.0}"
    local cache_file="${TRUSTNET_CACHE_DIR}/registry/registry-${version}"
    
    if [ -f "$cache_file" ]; then
        log_info "Registry ${version} already cached"
        return 0
    fi
    
    log_info "Downloading Registry ${version}..."
    mkdir -p "${TRUSTNET_CACHE_DIR}/registry"
    
    # Download from your TrustNet repo
    if curl -sL "https://github.com/Ingasti/trustnet-registry/releases/download/${version}/registry-linux-arm64" \
        -o "$cache_file"; then
        chmod +x "$cache_file"
        log_success "Registry ${version} cached"
    else
        log_error "Failed to download Registry"
        return 1
    fi
}

download_and_cache_trustnet_node() {
    local version="${1:-v0.1.0}"
    local cache_file="${TRUSTNET_CACHE_DIR}/node/node-${version}"
    
    if [ -f "$cache_file" ]; then
        log_info "Node ${version} already cached"
        return 0
    fi
    
    log_info "Downloading Node ${version}..."
    mkdir -p "${TRUSTNET_CACHE_DIR}/node"
    
    # Download from your TrustNet repo
    if curl -sL "https://github.com/Ingasti/trustnet-node/releases/download/${version}/node-linux-arm64" \
        -o "$cache_file"; then
        chmod +x "$cache_file"
        log_success "Node ${version} cached"
    else
        log_error "Failed to download Node"
        return 1
    fi
}

cache_docker_images_for_trustnet() {
    log_info "Pre-pulling Docker images..."
    
    if command -v docker &> /dev/null; then
        docker pull registry:latest || log_warning "Could not pull registry image"
        docker pull trustnet-node:latest || log_warning "Could not pull node image"
    fi
}
```

**Size**: +100 lines (additions only)

---

### File 3: `~/.trustnet/scripts/lib/dns-manager.sh` (NEW)

**Action**: Create new file (uses FactoryVM patterns)
```bash
#!/bin/bash
# dns-manager.sh - DNS lookup and verification for TrustNet

source "$(dirname "$0")/common.sh"

check_domain_exists() {
    local domain="$1"
    log_info "Checking if domain exists: $domain"
    
    if dig +short "$domain" A AAAA 2>/dev/null | grep -q .; then
        log_success "Domain resolves"
        return 0
    else
        log_error "Domain '$domain' not found in DNS"
        return 1
    fi
}

check_tnr_record_exists() {
    local domain="$1"
    log_info "Checking for tnr record: tnr.$domain"
    
    local result=$(dig +short "tnr.$domain" AAAA 2>/dev/null)
    
    if [ -z "$result" ]; then
        log_warning "tnr record not found (new network)"
        return 1
    else
        log_success "tnr record found: $result"
        echo "$result" | head -1  # Return first IP
        return 0
    fi
}

verify_dns_propagation() {
    local domain="$1"
    local expected_ip="$2"
    local max_attempts=12  # ~60 seconds
    local attempt=1
    
    log_info "Verifying DNS propagation (${domain} → ${expected_ip})..."
    
    while [ $attempt -le $max_attempts ]; do
        local result=$(dig +short "tnr.$domain" AAAA 2>/dev/null)
        
        if [ "$result" = "$expected_ip" ]; then
            log_success "DNS verified: tnr.$domain → $expected_ip"
            return 0
        fi
        
        log_warning "DNS not yet propagated (attempt $attempt/$max_attempts), retrying in 5s..."
        sleep 5
        ((attempt++))
    done
    
    log_error "DNS verification timeout"
    return 1
}

show_dns_instructions() {
    local domain="$1"
    local registry_ipv6="$2"
    
    cat << EOF

═════════════════════════════════════════════════════════════
     DNS RECORD REQUIRED
═════════════════════════════════════════════════════════════

Add this DNS record to your provider:

Record Name:    tnr
Domain:         ${domain}
Full FQDN:      tnr.${domain}
Record Type:    AAAA (IPv6)
Value:          ${registry_ipv6}
TTL:            300

AWS Route53:
  1. Go to AWS Console → Route53
  2. Find hosted zone: ${domain}
  3. Create new AAAA record
     Name: tnr
     Value: ${registry_ipv6}
     Type: AAAA
     TTL: 300

Cloudflare:
  1. Cloudflare Dashboard → DNS
  2. Add record
     Type: AAAA
     Name: tnr
     IPv6 address: ${registry_ipv6}
     TTL: Auto

═════════════════════════════════════════════════════════════

Verify with: dig +short tnr.${domain} AAAA

EOF
}
```

**Size**: ~100 lines (NEW)

---

### File 4: `~/.trustnet/scripts/lib/registry-installer.sh` (NEW)

**Action**: Create (based on install-docker.sh pattern)
```bash
#!/bin/bash
# registry-installer.sh - Install TrustNet Registry

source "$(dirname "$0")/common.sh"

install_registry_docker() {
    local registry_ipv6="$1"
    local domain="$2"
    
    log_info "Starting Registry Docker container..."
    
    # Create config
    mkdir -p "${TRUSTNET_CONFIG_DIR}"
    cat > "${TRUSTNET_CONFIG_DIR}/registry-config.yml" << EOF
registry:
  role: "root"
  ipv6_address: "${registry_ipv6}"
  port: 8000

database:
  type: sqlite
  path: /data/registry.db

replication:
  enabled: false

heartbeat:
  interval: 30
  timeout: 5
  missing_threshold: 10
EOF

    # Run registry container
    docker run -d \
        --name trustnet-root-1 \
        --ipv6 \
        -p 8000:8000 \
        -v /data/registry.db:/data/registry.db \
        -v "${TRUSTNET_CONFIG_DIR}:/etc/trustnet:ro" \
        trustnet-registry:latest \
        --config /etc/trustnet/registry-config.yml

    if [ $? -ne 0 ]; then
        log_error "Failed to start registry container"
        return 1
    fi
    
    log_success "Registry container started"
    
    # Wait for health endpoint
    log_info "Waiting for registry to be ready..."
    local attempts=0
    while [ $attempts -lt 30 ]; do
        if curl -s "http://localhost:8000/api/health" | grep -q "ok"; then
            log_success "Registry is ready"
            return 0
        fi
        sleep 2
        ((attempts++))
    done
    
    log_error "Registry failed to start (health check timeout)"
    return 1
}
```

**Size**: ~80 lines (NEW)

---

### File 5: `~/.trustnet/scripts/trustnet-install` (MAIN SCRIPT)

**Action**: Create main script that orchestrates everything
```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source modules
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/cache-manager.sh"
source "${SCRIPT_DIR}/lib/dns-manager.sh"
source "${SCRIPT_DIR}/lib/registry-installer.sh"
source "${SCRIPT_DIR}/lib/node-installer.sh"

# Parse arguments
DOMAIN="${1:-}"
if [ -z "$DOMAIN" ]; then
    log_error "Usage: trustnet-install <domain>"
    exit 1
fi

log "TrustNet Prototype Installation"
log "Domain: $DOMAIN"

# Step 1: Check domain exists
check_domain_exists "$DOMAIN" || exit 1

# Step 2: Check for existing tnr record
EXISTING_REGISTRY=$(check_tnr_record_exists "$DOMAIN" || echo "")

if [ -z "$EXISTING_REGISTRY" ]; then
    log "Creating new network (no tnr record found)"
    
    # Step 3a: Create root registry
    install_registry_docker "2001:db8::1" "$DOMAIN" || exit 1
    
    # Step 3b: Show DNS instructions and wait
    show_dns_instructions "$DOMAIN" "2001:db8::1"
    read -p "Press Enter when DNS record is added..."
    
    # Step 3c: Verify DNS
    verify_dns_propagation "$DOMAIN" "2001:db8::1" || log_warning "Continuing anyway..."
else
    log "Using existing root registry at: $EXISTING_REGISTRY"
fi

# Step 4: Create node
install_node_docker "$DOMAIN" || exit 1

log_success "Installation complete!"
```

**Size**: ~60 lines (NEW, orchestration only)

---

## Part 8: Timeline

### Week 1: Setup & Adapt FactoryVM Code
- [ ] Day 1-2: Copy FactoryVM files, understand patterns
- [ ] Day 3-4: Create TrustNet-specific modules (dns-manager.sh, registry-installer.sh, node-installer.sh)
- [ ] Day 5: Create main install script
- [ ] Day 6-7: Test with Docker containers

### Week 2: Testing & Polish
- [ ] Test install with bucoto.com domain
- [ ] Add error handling
- [ ] Test DNS verification
- [ ] Test node registration
- [ ] Document all steps

---

## Part 9: What NOT to Reuse

**Don't copy from FactoryVM**:
- ❌ Alpine automatic installation (too VM-specific for prototype)
- ❌ Kubernetes cluster setup (not needed for prototype)
- ❌ Jenkins CI/CD setup (we're using different CI)
- ❌ Terraform provisioning (too cloud-specific)

**Why**: Prototype is simpler - Docker containers + DNS + SSH for provisioning

---

## Summary

**FactoryVM gives us**:
✅ Proven logging & utilities (common.sh)
✅ Proven cache management (cache-manager.sh)
✅ Proven SSH-based provisioning patterns
✅ Proven error handling
✅ ~1,200 lines of tested code

**We build**:
✅ TrustNet-specific DNS management
✅ TrustNet registry installer
✅ TrustNet node installer
✅ Main install orchestration script
✅ ~300-400 lines of NEW code

**Time saved**: ~3-4 weeks (don't rebuild VM infrastructure)

---

**Document prepared**: January 30, 2026  
**Status**: Ready to implement  
**Next**: Start building trustnet-install script using FactoryVM patterns
