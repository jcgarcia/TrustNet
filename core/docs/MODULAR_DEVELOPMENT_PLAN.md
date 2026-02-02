# TrustNet Modular Development Plan

**Date**: February 2, 2026  
**Status**: Architecture Planning  
**Core Branch**: `core` (preserves base VM infrastructure)

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Core vs Feature Separation](#core-vs-feature-separation)
3. [Development Workflow](#development-workflow)
4. [Module Structure](#module-structure)
5. [Implementation Plan](#implementation-plan)
6. [Deployment Strategy](#deployment-strategy)

---

## Architecture Overview

### Problem Statement
Currently, any change to TrustNet functionality requires:
- Modifying VM installation scripts
- Rebuilding the entire VM
- Testing complete VM installation
- Risk of breaking the base infrastructure

### Solution: Three-Layer Architecture

```
┌─────────────────────────────────────────────┐
│         LAYER 1: CORE (VM Base)             │
│  Alpine Linux + Caddy + SSH + Certificates  │
│  Branch: core (NEVER MODIFY DIRECTLY)       │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│      LAYER 2: RUNTIME (Hot-Swappable)       │
│  Frontend modules, API services, configs    │
│  Developed on HOST, synced to VM            │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│       LAYER 3: DATA (Persistent)            │
│  Blockchain data, user identities, keys     │
│  Survives VM rebuilds                       │
└─────────────────────────────────────────────┘
```

---

## Core vs Feature Separation

### CORE (Rarely Changes)
**Git Branch**: `core`  
**Location**: VM base infrastructure  
**Update Frequency**: Only for critical fixes or Alpine/Caddy upgrades

**Includes**:
- Alpine Linux base installation
- Caddy web server setup
- SSL certificate generation
- SSH access configuration
- QEMU VM configuration
- Network setup (port forwarding)
- User/permission setup

**Files** (Protected):
- `tools/setup-trustnet-node.sh` (VM creation)
- `tools/lib/install-caddy.sh` (Caddy installation)
- `tools/lib/install-certificates.sh` (SSL setup)
- `tools/lib/create-vm.sh` (QEMU setup)
- `/etc/caddy/Caddyfile` (base configuration)

### FEATURES (Frequent Changes)
**Git Branch**: `main` (feature branches)  
**Location**: Host machine with sync to VM  
**Update Frequency**: Daily/hourly during development

**Includes**:
- Web UI (HTML/CSS/JS)
- Backend API services
- Module-specific functionality
- Business logic
- Database schemas

**Directories**:
- `frontend/` - Web interface modules
- `api/` - Backend services
- `modules/` - Feature modules
- `config/` - Runtime configurations

---

## Development Workflow

### Method 1: SSH + Rsync (RECOMMENDED)
**Best for**: Quick development iterations without VM rebuild

```bash
# 1. Develop on host machine
cd ~/GitProjects/TrustNet/trustnet-wip/frontend/

# 2. Edit files locally (VSCode, any editor)
vim src/identity/register.html

# 3. Auto-sync to VM on save (watch script)
./tools/dev-sync.sh

# 4. Test immediately in browser
# https://trustnet.local (refresh browser)

# 5. No VM rebuild needed!
```

**How it works**:
```bash
# Watch script (tools/dev-sync.sh)
while inotifywait -r -e modify,create,delete frontend/; do
    rsync -avz --delete \
        frontend/src/ \
        warden@127.0.0.1:/var/www/html/ \
        -e "ssh -p 2223"
    echo "✅ Synced to VM at $(date)"
done
```

**Advantages**:
- ✅ Instant feedback (edit → sync → refresh)
- ✅ No VM rebuild
- ✅ Work in familiar host environment
- ✅ Keep all host tools (VSCode, Git, etc.)

**Disadvantages**:
- ❌ Requires VM to be running
- ❌ Network dependency (SSH)

---

### Method 2: Shared Folder (QEMU 9P)
**Best for**: Zero-latency development

```bash
# 1. Mount host directory in VM
-virtfs local,path=/host/trustnet-wip/frontend/src,\
         mount_tag=hostshare,security_model=mapped-xattr,id=hostshare

# 2. Inside VM, mount to web root
mount -t 9p -o trans=virtio hostshare /var/www/html

# 3. Edit on host, instant reflection in VM
# No sync needed - files are shared!
```

**Advantages**:
- ✅ Instant - no sync delay
- ✅ No rsync overhead
- ✅ Simplest architecture

**Disadvantages**:
- ❌ Requires VM restart to enable
- ❌ Performance slightly slower than native
- ❌ Needs modification to start-trustnet.sh (touches core)

---

### Method 3: Separate Dev Server + API Proxy
**Best for**: Complex frontend development (React/Vue)

```bash
# 1. Run frontend dev server on host
cd frontend/
pnpm dev
# → http://localhost:5173

# 2. API requests proxy to VM
# vite.config.js:
proxy: {
  '/api': 'https://trustnet.local:1317',
  '/rpc': 'https://trustnet.local:26657'
}

# 3. Full hot-reload, fast iteration
# 4. Build and deploy to VM when ready
```

**Advantages**:
- ✅ Modern dev experience (Vite HMR)
- ✅ Fast framework development (React/Vue)
- ✅ Independent of VM state
- ✅ Full debugging tools

**Disadvantages**:
- ❌ More complex setup
- ❌ Need to build before VM deployment
- ❌ CORS configuration needed

---

## Module Structure

### Proposed Directory Layout

```
trustnet-wip/
├── core/                           # Core VM infrastructure (protected)
│   ├── alpine-setup/
│   ├── caddy-config/
│   └── network-config/
│
├── modules/                        # Feature modules (hot-swappable)
│   ├── identity/                   # Identity registration
│   │   ├── frontend/
│   │   │   ├── register.html
│   │   │   ├── register.js
│   │   │   └── register.css
│   │   ├── api/
│   │   │   └── identity-service.go
│   │   └── module.json             # Module metadata
│   │
│   ├── transactions/               # Transaction viewer
│   │   ├── frontend/
│   │   ├── api/
│   │   └── module.json
│   │
│   ├── keys/                       # Key management
│   │   ├── frontend/
│   │   ├── api/
│   │   └── module.json
│   │
│   └── governance/                 # Future: governance module
│       ├── frontend/
│       ├── api/
│       └── module.json
│
├── frontend/                       # Main web interface
│   ├── src/
│   │   ├── index.html             # Current dashboard
│   │   ├── main.js
│   │   ├── styles/
│   │   └── components/            # Shared UI components
│   │       ├── navbar.js
│   │       ├── modal.js
│   │       └── button.js
│   ├── package.json
│   └── vite.config.js             # Build configuration
│
├── api/                            # Backend API gateway
│   ├── src/
│   │   ├── main.go                # API server entry
│   │   ├── router.go              # Route definitions
│   │   ├── middleware/            # Auth, CORS, logging
│   │   └── handlers/              # Request handlers
│   ├── go.mod
│   └── Dockerfile                 # API container (optional)
│
├── tools/
│   ├── dev-sync.sh                # Auto-sync to VM
│   ├── module-install.sh          # Install module to VM
│   ├── module-remove.sh           # Remove module from VM
│   └── setup-trustnet-node.sh     # Core VM setup (protected)
│
└── docs/
    ├── MODULAR_DEVELOPMENT_PLAN.md  # This file
    └── MODULE_DEVELOPMENT_GUIDE.md  # How to create modules
```

---

## Module Specification

### module.json Schema

```json
{
  "name": "identity",
  "version": "1.0.0",
  "description": "Identity registration and management",
  "author": "TrustNet Team",
  "type": "full-stack",
  
  "frontend": {
    "entry": "frontend/register.html",
    "assets": ["frontend/*.css", "frontend/*.js"],
    "routes": [
      { "path": "/register", "file": "frontend/register.html" },
      { "path": "/profile", "file": "frontend/profile.html" }
    ]
  },
  
  "api": {
    "language": "go",
    "entry": "api/identity-service.go",
    "endpoints": [
      { "method": "POST", "path": "/api/identity/register" },
      { "method": "GET", "path": "/api/identity/:id" }
    ],
    "dependencies": ["github.com/cosmos/cosmos-sdk"]
  },
  
  "install": {
    "scripts": {
      "pre": "scripts/pre-install.sh",
      "post": "scripts/post-install.sh"
    },
    "systemd": "services/identity.service",
    "caddy": "config/Caddyfile.identity"
  },
  
  "dependencies": {
    "modules": [],
    "external": ["cosmos-sdk", "tendermint"]
  }
}
```

---

## Implementation Plan

### Phase 1: Development Infrastructure (Week 1)

**Goal**: Set up hot-reload development environment

**Tasks**:
1. ✅ Create `core` branch (DONE)
2. Create `tools/dev-sync.sh` script for auto-sync
3. Test rsync to running VM
4. Document sync workflow in README
5. Create first test module (simple "Hello World")

**Deliverables**:
- Working dev-sync script
- Test module successfully synced to VM
- Developer can edit → sync → see changes in <30 seconds

**Branch**: `feature/dev-infrastructure`

---

### Phase 2: Frontend Module System (Week 2)

**Goal**: Modular frontend with component loading

**Tasks**:
1. Create `frontend/src/` base structure
2. Build component loader (dynamic module import)
3. Convert current dashboard to base template
4. Create shared UI components (button, modal, navbar)
5. Build module registration system

**Example**:
```javascript
// frontend/src/main.js
import { ModuleLoader } from './core/module-loader.js';

const modules = [
  { name: 'identity', path: '/modules/identity/frontend/register.js' },
  { name: 'transactions', path: '/modules/transactions/frontend/viewer.js' }
];

ModuleLoader.load(modules).then(() => {
  console.log('All modules loaded');
});
```

**Deliverables**:
- Dynamic module loading system
- Base UI template with module slots
- 3 working buttons: Register Identity, View Transactions, Manage Keys

**Branch**: `feature/frontend-modules`

---

### Phase 3: Backend API System (Week 3)

**Goal**: API gateway that routes to module services

**Tasks**:
1. Create Go API server in `api/src/`
2. Build router with module endpoint registration
3. Implement authentication middleware
4. Create module service interface
5. Test with identity registration endpoint

**Example**:
```go
// api/src/main.go
func main() {
    r := gin.Default()
    
    // Load modules
    moduleLoader := modules.NewLoader()
    moduleLoader.Register("identity", identity.NewService())
    moduleLoader.Register("transactions", transactions.NewService())
    
    // Register module routes
    moduleLoader.AttachRoutes(r.Group("/api"))
    
    r.Run(":1317")
}
```

**Deliverables**:
- API server running on port 1317
- Module registration system
- Identity registration endpoint working
- Integrated with Cosmos SDK

**Branch**: `feature/api-gateway`

---

### Phase 4: First Complete Module - Identity (Week 4)

**Goal**: Fully functional identity registration module

**Tasks**:
1. Build identity registration frontend
2. Implement backend identity service
3. Integrate with Cosmos SDK identity chain
4. Add key generation and storage
5. Test complete flow: UI → API → Blockchain

**Features**:
- User enters name/email
- System generates public/private key pair
- Stores identity on blockchain
- Displays identity DID (Decentralized ID)
- Shows reputation score (0 initially)

**Deliverables**:
- Working "Register Identity" button
- Complete identity creation flow
- Identity displayed on dashboard
- Module can be installed/removed without touching core

**Branch**: `feature/identity-module`

---

### Phase 5: Module Management Tools (Week 5)

**Goal**: Easy install/remove/update modules

**Tasks**:
1. Create `tools/module-install.sh`
2. Create `tools/module-remove.sh`
3. Create `tools/module-list.sh`
4. Build module dependency resolver
5. Test installing identity module to fresh VM

**Usage**:
```bash
# Install module
./tools/module-install.sh identity

# Module automatically:
# 1. Copies frontend to /var/www/html/modules/identity/
# 2. Builds and starts API service
# 3. Updates Caddy routes
# 4. Registers in module registry
# 5. No VM rebuild needed!

# Remove module
./tools/module-remove.sh identity

# List installed modules
./tools/module-list.sh
```

**Deliverables**:
- Module install/remove scripts
- Dependency checking
- Rollback on failed install
- Module registry database

**Branch**: `feature/module-tools`

---

## Deployment Strategy

### Development Environment
```
Host Machine (Ubuntu)
├── VSCode editing ~/GitProjects/TrustNet/trustnet-wip/
├── dev-sync.sh watching for changes
└── Auto-rsync to VM on file save

TrustNet VM (Alpine)
├── Receives synced files at /var/www/html/
├── Caddy serves updated files
└── API services auto-reload (if using air/nodemon)
```

### Module Installation Flow
```bash
# 1. Developer creates module
cd modules/identity/
# Edit files...

# 2. Test module locally (on host)
cd frontend/
pnpm dev
# → http://localhost:5173/identity

# 3. Install to VM
./tools/module-install.sh identity
# → Module synced to VM
# → API service started
# → Routes registered

# 4. Test in VM
curl https://trustnet.local/api/identity/register

# 5. Commit module
git add modules/identity/
git commit -m "Add identity registration module"

# 6. Module can be installed on any TrustNet node
```

### Core Update Flow (Rare)
```bash
# Only for critical VM infrastructure changes

# 1. Create feature branch from core
git checkout core
git checkout -b feature/caddy-update

# 2. Make minimal change (e.g., update Caddy version)
# Edit tools/lib/install-caddy.sh

# 3. Test full VM rebuild
./tools/setup-trustnet-node.sh

# 4. If works, merge to core
git checkout core
git merge feature/caddy-update

# 5. Merge core changes to main
git checkout main
git merge core
```

---

## File Organization Rules

### DO NOT TOUCH (Core Files)
```
tools/setup-trustnet-node.sh        # Core VM setup
tools/lib/install-caddy.sh          # Caddy installation
tools/lib/install-certificates.sh   # SSL setup
tools/lib/create-vm.sh              # QEMU configuration
```

**Rule**: Changes require:
1. Branch from `core`
2. Full VM rebuild test
3. User approval
4. Merge to `core` then `main`

### SAFE TO MODIFY (Feature Files)
```
frontend/src/**/*                   # All frontend code
api/src/**/*                        # All API code
modules/**/*                        # All modules
config/**/*                         # Runtime configs
docs/**/*                           # Documentation
```

**Rule**: Changes require:
1. Feature branch from `main`
2. Sync to VM test
3. Commit to `main`
4. NO VM rebuild needed

---

## Technology Stack

### Frontend (Host + VM)
- **Framework**: Vite + Vanilla JS (can upgrade to React later)
- **CSS**: Tailwind CSS (for rapid UI development)
- **Build**: pnpm (monorepo support)
- **Dev Server**: Vite dev server on host:5173
- **Production**: Static files served by Caddy in VM

### Backend API (VM)
- **Language**: Go (aligns with Cosmos SDK)
- **Framework**: Gin (lightweight, fast)
- **Database**: SQLite (simple) or PostgreSQL (production)
- **Blockchain**: Cosmos SDK + Tendermint BFT
- **Auto-reload**: Air (for development)

### Sync Tools
- **Method 1**: rsync over SSH (proven, reliable)
- **Method 2**: inotify-tools (watch file changes)
- **Method 3**: QEMU 9P shared folders (future)

---

## Success Metrics

### Development Speed
- **Before**: 30-60 minutes to rebuild VM and test change
- **After**: 5-10 seconds to sync and test change
- **Target**: 1000% faster iteration

### Code Safety
- **Before**: One broken script = entire VM broken
- **After**: Core protected, features isolated
- **Target**: Zero core breakage from feature development

### Module Reusability
- **Before**: Hard-coded functionality
- **After**: Install/remove modules independently
- **Target**: 5+ installable modules by end of month

---

## Next Steps

### Immediate (Today)
1. ✅ Create `core` branch (DONE)
2. Create `tools/dev-sync.sh` script
3. Test syncing a simple HTML file to VM
4. Verify browser shows updated file

### This Week
1. Set up frontend development structure
2. Create first module: Identity Registration
3. Test complete edit → sync → view cycle
4. Document developer workflow

### This Month
1. Complete all 5 implementation phases
2. Have 3 working modules (Identity, Transactions, Keys)
3. Full module install/remove tooling
4. Documentation for module developers

---

## Questions for User

Before implementing, please confirm:

1. **Development Method Preference?**
   - Option 1: Rsync (recommended - simple, reliable)
   - Option 2: Vite dev server (modern, full features)
   - Option 3: QEMU shared folder (requires core change)

2. **Frontend Technology?**
   - Plain HTML/CSS/JS (simple, lightweight)
   - Vite + Modern JS (better DX, build step)
   - React/Vue (full framework, more setup)

3. **Backend Language?**
   - Go (aligns with Cosmos SDK)
   - Node.js (easier for JS developers)
   - Python (rapid prototyping)

4. **First Module to Build?**
   - Identity Registration (most critical)
   - Transaction Viewer (most visible)
   - Key Management (most complex)

5. **Priority?**
   - Speed of development (dev-sync first)
   - Feature completeness (identity module first)
   - Architecture perfection (all tools first)

---

*Document created: February 2, 2026*  
*Status: Awaiting user decisions on technology choices*  
*Next: Implement chosen development method*
