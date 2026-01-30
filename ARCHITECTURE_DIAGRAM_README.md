# TrustNet Architecture Diagrams

**File**: `TrustNet_Architecture.drawio`  
**Format**: Draw.io XML (native draw.io format)  
**Diagrams**: 2 (Installation phases + Network topology)

---

## How to View & Edit

### Option 1: VS Code (Recommended)
1. Install **Draw.io Integration** extension (jgraph.drawio-integration)
2. Open `TrustNet_Architecture.drawio` in VS Code
3. Edit visually with auto-save

### Option 2: Online
1. Go to https://draw.io
2. File → Open → Select `TrustNet_Architecture.drawio`
3. Edit in browser

### Option 3: Desktop
1. Download Draw.io from https://www.diagrams.net
2. Open the file directly
3. Export as PNG, PDF, or SVG

---

## Diagram 1: Installation Architecture (5 Phases)

```
PHASE 1: Cache Preparation (Local Machine)
├─ Download Go 1.22.0 (63 MB ARM64)
├─ Create config templates
├─ Generate SHA256 checksums
└─ Result: /tmp/trustnet-cache/
    ↓
PHASE 2: Alpine OS Installation (Manual QEMU)
├─ Create trustnet-node VM (20GB, 4GB RAM)
├─ Create trustnet-registry VM (20GB, 4GB RAM)
├─ Run setup-alpine
└─ Enable SSH
    ↓
PHASE 3: Cache Deployment (SCP)
├─ scp -r cache/ root@trustnet-node:/opt/
├─ scp -r cache/ root@trustnet-registry:/opt/
├─ Verify checksums
└─ Set permissions
    ↓
PHASE 4: Installation Scripts (On VMs, as root then user)
├─ install-common.sh (packages, Go extraction)
├─ user-setup.sh (create warden/keeper)
├─ doas-config.sh (privilege escalation)
├─ node-install.sh or registry-install.sh
└─ Result: Binaries built and installed
    ↓
PHASE 5: Verification (Health Checks)
├─ User existence ✓
├─ Group membership ✓
├─ doas access ✓
├─ Go installation ✓
├─ Binary availability ✓
└─ All checks passed ✅
```

---

## Diagram 2: Network Topology & Runtime

### trustnet-node VM
**Address**: `fd10:1234::1` (IPv6)  
**User**: warden (UID 1000)

**Components**:
- Alpine Linux 3.22.2 Kernel
- Go 1.22.0 Runtime
- Tendermint Node Binary
- Application Services

**Network Ports**:
- RPC: `[fd10:1234::1]:26657` (Tendermint RPC)
- P2P: `[fd10:1234::1]:26656` (Consensus/P2P)
- Health: Internal checks

**Storage**:
- Config: `/opt/trustnet/node/config/config.toml`
- Data: `/opt/trustnet/node/data/`

**Privileges**:
- User: warden (non-root)
- doas: Passwordless privilege escalation

### trustnet-registry VM
**Address**: `fd10:1234::2` (IPv6)  
**User**: keeper (UID 1000)

**Components**:
- Alpine Linux 3.22.2 Kernel
- Go 1.22.0 Runtime
- Registry Binary (HTTP server)
- API Service

**Network Ports**:
- HTTP: `[fd10:1234::2]:8000` (Registry API)
- Health: `GET /health` endpoint
- API: `GET /v2/` endpoint

**Storage**:
- Config: `/opt/trustnet/registry/config/config.yaml`
- Data: `/var/lib/trustnet-registry/`

**Privileges**:
- User: keeper (non-root)
- doas: Passwordless privilege escalation

---

## Network: IPv6 ULA (Unique Local Address)

```
Network: fd10:1234::/32 (Unique Local Address)
├─ trustnet-node:    fd10:1234::1
└─ trustnet-registry: fd10:1234::2

IPv6 Benefits:
- Unique (no collision risk)
- Private (not routed on internet)
- Sufficient for local network
- Future-proof for scalability
```

---

## Key Features Shown in Diagrams

✅ **5-Phase Installation Workflow**
- Sequential steps from cache to verification
- Clear dependencies between phases
- Automated (no manual intervention)

✅ **VM Components**
- Alpine Linux base
- Go runtime
- Compiled binaries
- Configuration files
- Data directories
- User/privilege setup

✅ **Network Configuration**
- IPv6 addresses (ULA)
- Port assignments
- Service endpoints
- Health checks

✅ **Storage Layout**
- /usr/local/go/ (Go installation)
- /opt/trustnet/ (application home)
- /home/{user}/ (user directory)
- /var/lib/ (persistent data)
- /etc/doas.d/ (privilege config)

✅ **User & Privilege Model**
- warden user (node VM)
- keeper user (registry VM)
- wheel group membership
- doas passwordless access
- Non-root operation

---

## Exporting to Other Formats

From draw.io UI:
1. File → Export As
2. Choose format:
   - **PNG**: For presentations/documents
   - **SVG**: For web/scaling
   - **PDF**: For printing

### PNG Export
```bash
# Via draw.io desktop
# File → Export As → PNG
# Output: TrustNet_Architecture.png
```

### Command Line (with drawio-cli)
```bash
npm install -g drawio-cli

# PNG export
drawio --export --format png TrustNet_Architecture.drawio

# SVG export
drawio --export --format svg TrustNet_Architecture.drawio

# PDF export
drawio --export --format pdf TrustNet_Architecture.drawio
```

---

## Editing the Diagram

### Adding New Elements
1. Open in draw.io (VS Code or online)
2. Use toolbar to add shapes, connectors, text
3. Right-click for formatting options
4. Auto-save when using VS Code

### Common Tasks

**Change Phase Colors**:
- Select phase box → Format panel → Change Fill color

**Update Ports**:
- Select port box → Edit text → Update number/service

**Add Network Node**:
- Drag shape to network area
- Connect with arrows
- Label with IPv6 address

**Modify VM Components**:
- Edit text inside VM containers
- Update binary names, paths, ports

---

## Integration with Documentation

**Cross-references**:
- TRUSTNET_INSTALLATION_ARCHITECTURE.md (text version)
- WEEK1_SUMMARY.md (status tracking)
- PROTOTYPE_OVERVIEW.txt (ASCII dashboard)
- prototype-cache/README_PROTOTYPE.md (quick start)

This diagram provides **visual representation** of the same information documented in text.

---

## Troubleshooting

**Diagram not opening in VS Code**:
- Install: Draw.io Integration by jgraph
- Command: `ctrl+shift+p` → "Draw.io: Open"

**Changes not saving**:
- Check file is writable: `ls -la TrustNet_Architecture.drawio`
- Ensure VS Code has write permission

**Export failing**:
- Use online draw.io: https://draw.io
- Load file → Export to desired format

**Need to modify**:
- All shapes/colors/text are editable
- Save as new version to keep originals
- Git tracks changes to .drawio XML

---

## Version History

- **v1.0** (Jan 30, 2026)
  - Installation architecture (5 phases)
  - Network topology
  - VM components
  - Port assignments
  - Storage layout

Commit: `823769f` "Add TrustNet Architecture draw.io diagrams"

---

## Next Steps

After Phase 2-5 testing, consider adding:
- [ ] Kubernetes deployment diagram (Week 11-12)
- [ ] Load balancing topology (if scaling beyond 2 VMs)
- [ ] Disaster recovery architecture
- [ ] Monitoring & logging flow
- [ ] DNS discovery visualization

For now, this covers the **installation and runtime architecture** for the prototype.

---

**Status**: Ready to use  
**Last Updated**: Jan 30, 2026  
**Maintainer**: TrustNet Development Team
