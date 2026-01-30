# TrustNet Installation Architecture & Plan
**Date**: Jan 30, 2026 | **Status**: PLANNING PHASE | **Base**: FactoryVM Patterns

---

## Overview

TrustNet installation follows **FactoryVM's proven cache-based approach**:
1. **Cache Phase**: Download all components to local cache (once)
2. **OS Phase**: Install Alpine Linux base image
3. **Deploy Phase**: Copy cache to VM, install components
4. **Verify Phase**: Health checks and functional testing

This minimizes network traffic, enables offline installation, and ensures reproducibility.

---

## User Configuration

### Node VM
**Primary user**: `warden` (equivalent to `foreman` in FactoryVM)
- UID: 1000
- Group: wheel
- Privilege: doas (passwordless sudo equivalent)
- Purpose: Run Tendermint node software
- Home: `/home/warden`
- Shell: `/bin/sh`

### Registry VM
**Primary user**: `keeper` (equivalent to registry manager)
- UID: 1000
- Group: wheel
- Privilege: doas (passwordless sudo equivalent)
- Purpose: Run registry service
- Home: `/home/keeper`
- Shell: `/bin/sh`

### Commonalities
Both follow FactoryVM pattern:
- Non-root users (security)
- doas for privilege escalation (Alpine-native)
- Passwordless doas for CI/CD automation
- Docker group membership (if containerized)

---

## Installation Phases

### Phase 1: Cache Preparation (Local machine, one-time)

**Purpose**: Download all components once, reuse across multiple VMs

**Components to cache** (Alpine 3.22.2 ARM64):
```
├── Go 1.22.0 binary (65MB)
│   └── go1.22.0.linux-arm64.tar.gz
├── Docker (if needed for registry)
│   └── docker-static binary
├── Tendermint library (via go get)
│   └── Downloaded as go.mod dependency
├── SQLite (pure Go driver, no downloads)
├── Build tools (apk packages, list-based)
│   ├── gcc
│   ├── musl-dev
│   ├── make
│   ├── git
│   └── curl
└── FactoryVM scripts (copied and adapted)
    ├── install-common.sh (base)
    ├── cache-manager.sh (cache handling)
    ├── user-setup.sh (warden/keeper users)
    ├── doas-config.sh (privilege escalation)
    └── tendermint-install.sh (node-specific)
```

**Cache location**: `/tmp/trustnet-cache/` (on host machine)
**Cache structure**:
```
trustnet-cache/
├── go/
│   └── go1.22.0.linux-arm64.tar.gz
├── scripts/
│   ├── install-common.sh
│   ├── cache-manager.sh
│   ├── user-setup.sh
│   ├── doas-config.sh
│   └── node-install.sh (or registry-install.sh)
├── configs/
│   ├── doas.conf
│   ├── tendermint-config.toml
│   └── registry-config.yaml
└── checksums.txt (SHA256 validation)
```

**Action items**:
- [ ] Download Go 1.22.0 binary for ARM64
- [ ] Create script directory with FactoryVM adaptations
- [ ] Create config templates
- [ ] Generate SHA256 checksums for integrity validation

---

### Phase 2: Alpine OS Installation

**Purpose**: Minimal base system, ready for cache injection

**Installation method**: QEMU ARM64 VM (~/vms/trustnet-node, ~/vms/trustnet-registry)

**Alpine setup steps**:
1. Create QEMU VM (ARM64, 20GB disk, 4GB RAM)
2. Boot Alpine 3.22.2 installation media
3. Run `setup-alpine` with minimal configuration
   - Keyboard: detect or manual
   - Network: DHCP (auto)
   - Hostname: trustnet-node or trustnet-registry
   - Disk: /dev/vda (auto-partition)
   - Root password: temporary (will be disabled)
   - Timezone: UTC (for consistency)
   - NTP: chrony (time sync)
4. Reboot into installed system
5. Add user group: `addgroup wheel`
6. Enable SSH (apk add openssh, rc-service sshd start)

**Result**: Clean Alpine VM with SSH access, ready for Phase 3

---

### Phase 3: Cache Deployment to VM

**Purpose**: Copy all pre-downloaded components to VM (fast, minimal network usage)

**Process**:
1. **SSH access**: Verify SSH is running on Alpine VM
2. **Create cache directory**: `ssh vm 'mkdir -p /opt/trustnet-cache'`
3. **SCP cache**: `scp -r trustnet-cache/ vm:/opt/`
4. **Verify checksums**: `ssh vm 'sha256sum -c /opt/trustnet-cache/checksums.txt'`
5. **Set permissions**: `ssh vm 'chmod +x /opt/trustnet-cache/scripts/*.sh'`

**SCP command example**:
```bash
scp -r /tmp/trustnet-cache/ root@trustnet-node:/opt/
```

**Result**: All components on VM, ready for Phase 4

---

### Phase 4: Installation & Configuration (On VM)

**Purpose**: Execute installation scripts, configure users, services

**Execution sequence** (CRITICAL ORDER):

#### Step 4.1: Common Setup (runs as root)
```bash
ssh root@vm '/opt/trustnet-cache/scripts/install-common.sh'
```
**What it does**:
- Install apk packages (gcc, make, git, curl, openssl-dev, musl-dev)
- Create cache-manager directory (/var/cache/trustnet)
- Extract Go 1.22.0 to /usr/local/go
- Create /opt/trustnet directory (application home)
- Validate checksums of all components

**Expected output**: No errors, all packages installed, Go version confirmed

#### Step 4.2: User Setup (runs as root)
```bash
ssh root@vm '/opt/trustnet-cache/scripts/user-setup.sh warden'  # for node VM
ssh root@vm '/opt/trustnet-cache/scripts/user-setup.sh keeper'  # for registry VM
```
**What it does**:
- Create user (warden/keeper)
- Add to wheel group
- Set up home directory (/home/warden or /home/keeper)
- Create .ssh directory for key auth
- Set shell to /bin/sh

**Expected output**: User created, home directory initialized

#### Step 4.3: Privilege Escalation (doas) Setup
```bash
ssh root@vm '/opt/trustnet-cache/scripts/doas-config.sh'
```
**What it does**:
- Install doas (already in apk)
- Configure /etc/doas.conf for passwordless execution
- Rules for warden/keeper: `permit nopass :<user> as root cmd apk`
- Enable tty for manual auth if needed

**Expected output**: doas.conf configured, test with `doas whoami`

#### Step 4.4: Node-Specific Install (runs as warden, uses doas)
```bash
ssh warden@vm 'doas /opt/trustnet-cache/scripts/node-install.sh'
```
**What it does**:
- Clone or copy TrustNet source code
- Create tendermint config directory
- Build trustnet-node binary
- Set up systemd service (or OpenRC)
- Test binary execution

**Expected output**: Binary builds, `/usr/local/bin/trustnet-node` available

#### Step 4.5: Registry-Specific Install (runs as keeper, uses doas)
```bash
ssh keeper@vm 'doas /opt/trustnet-cache/scripts/registry-install.sh'
```
**What it does**:
- Clone or copy registry source code
- Create registry config directory
- Build registry binary
- Set up systemd service (or OpenRC)
- Create data directory (/var/lib/trustnet-registry)
- Test registry health endpoint

**Expected output**: Registry binary available, listening on configured port

---

### Phase 5: Verification & Testing

**Purpose**: Ensure all components work correctly

#### Node VM Verification:
```bash
# Test user access
ssh warden@trustnet-node 'whoami'  # Should output: warden

# Test doas (passwordless)
ssh warden@trustnet-node 'doas whoami'  # Should output: root

# Test Go installation
ssh warden@trustnet-node 'go version'  # Should output: go version go1.22.0 linux/arm64

# Test Tendermint import (from earlier validation script)
ssh warden@trustnet-node '/tmp/test-tendermint-build'  # Should run successfully

# Verify trustnet-node binary
ssh warden@trustnet-node 'trustnet-node --version'  # Should show version
```

#### Registry VM Verification:
```bash
# Test user access
ssh keeper@trustnet-registry 'whoami'  # Should output: keeper

# Test doas (passwordless)
ssh keeper@trustnet-registry 'doas whoami'  # Should output: root

# Test registry health
ssh keeper@trustnet-registry 'curl http://localhost:8000/health'  # JSON response

# Verify registry binary
ssh keeper@trustnet-registry 'trustnet-registry --version'
```

---

## FactoryVM Code Reuse

### Directly Reusable (with zero changes):
- `install-common.sh`: Package installation patterns
- `cache-manager.sh`: Cache handling logic
- `doas-config.sh`: Privilege escalation setup
- `user-setup.sh`: User creation patterns

### Adaptations Needed:
1. **User names**: `foreman` → `warden` (node), `keeper` (registry)
2. **Service names**: FactoryVM services → TrustNet services
3. **Binaries**: Factory VMs → trustnet-node, trustnet-registry
4. **Config paths**: /opt/factory → /opt/trustnet

### File mapping:
```
FactoryVM                               TrustNet
────────────────────────────────────────────────────
install-alpine.sh (Alpine-specific)  → Adapt for node/registry
install-common.sh                    → Reuse as-is
user-setup.sh                        → Reuse, update username
doas-config.sh                       → Reuse as-is
cache-manager.sh                     → Reuse as-is
```

**Location**: [~/.../FactoryVM](https://github.com/Ingasti/FactoryVM) source

---

## Week 1-2 Deliverables

### Week 1 (Cache & Common Scripts):
- [ ] Create `/tmp/trustnet-cache/` directory structure
- [ ] Download Go 1.22.0 binary
- [ ] Copy and adapt FactoryVM scripts:
  - [ ] `install-common.sh`
  - [ ] `cache-manager.sh`
  - [ ] `user-setup.sh` (with warden/keeper params)
  - [ ] `doas-config.sh`
- [ ] Create configuration templates:
  - [ ] `doas.conf` (passwordless rules)
  - [ ] `tendermint-config.toml` template
  - [ ] `registry-config.yaml` template
- [ ] Generate SHA256 checksums for all components
- [ ] Document: This file (you're reading it!)

### Week 2 (Deployment & Testing):
- [ ] Create Node VM (`trustnet-node` QEMU)
- [ ] Create Registry VM (`trustnet-registry` QEMU)
- [ ] Test Phase 3 (cache deployment to both VMs)
- [ ] Test Phase 4 (installation scripts on both)
- [ ] Test Phase 5 (verification and health checks)
- [ ] Document any issues and solutions
- [ ] Create runbook for reproducible installation

---

## Critical Implementation Notes

### Order Matters
Do NOT deviate from the sequence:
1. Cache phase (download once)
2. Alpine OS install (clean slate)
3. Cache deploy (network copy)
4. Common setup (root-level)
5. User setup (create warden/keeper)
6. doas setup (privilege escalation)
7. Component-specific install (node/registry)

**Why**: Each step depends on previous setup. Skipping or reordering breaks dependencies.

### Network Minimization
- First install: Full cache download (60-80MB one-time)
- Subsequent installs: Cache reuse (no re-downloads)
- Alpine OS: Download once from ISO, reuse VM snapshots
- Offline capable: Cache can be USB-copied if needed

### Security
- Root password: Disabled after setup (PermitRootLogin=no in sshd)
- User privilege: Via doas (configured, passwordless for scripts)
- SSH keys: Pre-configured for each user (warden/keeper)
- Network: Firewall rules TBD (Week 3+)

### Reproducibility
- SHA256 checksums: Verify cache integrity
- Script idempotency: Can re-run safely
- Config templates: Apply to new VMs with zero changes
- Documentation: Step-by-step with expected outputs

---

## File Structure (to be created)

```
~/trustnet-install/  (git repo, similar to FactoryVM)
├── README.md  (overview, quickstart)
├── INSTALLATION_GUIDE.md  (this file, expanded)
├── scripts/
│   ├── cache-prepare.sh  (Phase 1: download and prepare)
│   ├── install-common.sh  (Phase 4.1, adapted from FactoryVM)
│   ├── user-setup.sh  (Phase 4.2, adapted)
│   ├── doas-config.sh  (Phase 4.3, reuse from FactoryVM)
│   ├── node-install.sh  (Phase 4.4, NEW: trustnet-node specific)
│   ├── registry-install.sh  (Phase 4.5, NEW: registry specific)
│   └── verify-installation.sh  (Phase 5, health checks)
├── configs/
│   ├── doas.conf  (passwordless sudo rules)
│   ├── tendermint-config.toml  (node template)
│   └── registry-config.yaml  (registry template)
├── cache/  (generated by Phase 1)
│   ├── go/
│   ├── scripts/  (symlink to scripts/)
│   ├── configs/  (symlink to configs/)
│   └── checksums.txt  (SHA256 sums)
└── docs/
    ├── ARCHITECTURE.md  (this content)
    ├── TROUBLESHOOTING.md  (FAQ, known issues)
    └── RUNBOOK.md  (step-by-step for ops)
```

---

## Next Steps

1. **Review this plan** - Ensure alignment with requirements
2. **Confirm FactoryVM locations** - Where is the source code?
3. **Identify components to cache** - Go binary, configs, etc.
4. **Create cache directory** - Set up local structure
5. **Copy/adapt FactoryVM scripts** - Modify for TrustNet
6. **Begin Week 1 implementation** - Start with cache prep

---

**Status**: ✅ PLAN DOCUMENTED | Ready for coding phase  
**Estimated effort**: 
- Week 1: 20-25 hours (scripts, cache, documentation)
- Week 2: 15-20 hours (VM setup, testing, refinement)
- **Total**: ~40-45 hours = 1 week full-time development

**Go/No-Go**: Ready to proceed when you approve this plan ✅
