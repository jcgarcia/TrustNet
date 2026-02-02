# TrustNet Modules

This directory contains **hot-swappable feature modules** for TrustNet.

## Module Structure

Each module follows this structure:

```
module-name/
├── frontend/           # UI components (HTML/CSS/JS)
├── api/               # Backend services
├── module.json        # Module metadata
└── README.md          # Module documentation
```

## Available Modules

### web-ui/
**Status**: In Development  
**Description**: Main web interface dashboard  
**Features**: Node status, navigation, module loading

### identity/
**Status**: Planned  
**Description**: Identity registration and management  
**Features**: Register identity, view profile, manage reputation

### transactions/
**Status**: Planned  
**Description**: Transaction viewer and history  
**Features**: View transactions, transaction details, search

### keys/
**Status**: Planned  
**Description**: Cryptographic key management  
**Features**: Generate keys, view keys, export/import

### blockchain/
**Status**: Planned  
**Description**: Blockchain node integration  
**Features**: Node status, sync progress, peer info

## Installing Modules

Modules can be installed/removed without rebuilding the VM:

```bash
# Install a module
./tools/module-install.sh identity

# Remove a module
./tools/module-remove.sh identity

# List installed modules
./tools/module-list.sh
```

## Creating New Modules

See [MODULE_DEVELOPMENT_GUIDE.md](../docs/MODULE_DEVELOPMENT_GUIDE.md) for:
- Module specification
- Development workflow
- API integration
- Testing guidelines

## Module Development

Modules are developed on the host machine and synced to the VM:

```bash
# Start dev sync
./tools/dev-sync.sh

# Edit module files
vim modules/identity/frontend/register.html

# Changes auto-sync to VM → refresh browser to see updates
```

No VM rebuild needed!
