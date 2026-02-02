# TrustNet Core

This directory contains the **core VM infrastructure** for TrustNet nodes.

## ⚠️ CRITICAL - DO NOT MODIFY WITHOUT APPROVAL

The core directory contains critical VM base setup:
- Alpine Linux installation
- Caddy web server configuration
- SSL certificate generation
- SSH access setup
- QEMU VM configuration
- Network setup

**Any changes to core require**:
1. Branch from `core` git branch
2. Full VM rebuild testing
3. User approval
4. Merge to `core` then `main`

## Contents

### tools/
VM installation and setup scripts:
- `setup-trustnet-node.sh` - Main VM installer
- `lib/` - Installation library modules
  - `install-caddy.sh` - Caddy setup
  - `install-certificates.sh` - SSL certificates
  - `create-vm.sh` - QEMU configuration
  - etc.

### docs/
Core infrastructure documentation:
- Installation guides
- Architecture documents
- Troubleshooting

## Installation

To install a TrustNet node, use the one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/jcgarcia/TrustNet/main/install.sh | bash
```

Or clone and run manually:

```bash
git clone https://github.com/jcgarcia/TrustNet.git
cd TrustNet/core
./tools/setup-trustnet-node.sh
```

## Version

Core infrastructure version: 1.0.0  
Last updated: February 2, 2026
