# Architecture

## System Overview

TrustNet consists of two main components running in isolated QEMU VMs:

```
┌─────────────────────────────────────────────────────┐
│                  Host System                         │
├─────────────────────────────────────────────────────┤
│  ┌──────────────────┐    ┌──────────────────────┐   │
│  │  trustnet-node   │    │ trustnet-registry    │   │
│  ├──────────────────┤    ├──────────────────────┤   │
│  │ Alpine 3.22.2    │    │ Alpine 3.22.2        │   │
│  │ Tendermint       │    │ Registry             │   │
│  │ 50GB disk        │    │ 30GB disk            │   │
│  │ 8GB RAM / 4CPU   │    │ 4GB RAM / 2CPU       │   │
│  │ fd10:1234::1     │    │ fd10:1234::2         │   │
│  └──────────────────┘    └──────────────────────┘   │
│          │                        │                   │
│          └────────────────────────┘                   │
│              IPv6 ULA Network                         │
│           fd10:1234::/32                             │
└─────────────────────────────────────────────────────┘
```

## trustnet-node VM

**Purpose**: Tendermint consensus validator

### Services
- **Tendermint**: Consensus engine
  - RPC: 26657 (HTTPS with Let's Encrypt, queries, transactions)
  - P2P: 26656 (encrypted validator communication)

### Users
- `root`: System administration
- `warden`: Node operations and monitoring

### Storage
- `/opt/trustnet/node/`: Node data directory
  - config/ - Tendermint configuration
  - data/ - Blockchain state
  - logs/ - Service logs

### Hardware
- **Disk**: 50GB QCOW2 image
- **RAM**: 8GB
- **CPUs**: 4 cores
- **Network**: IPv6 ULA fd10:1234::1

## trustnet-registry VM

**Purpose**: Container image registry and distribution

### Services
- **Registry**: Go-based registry service (Caddy HTTPS frontend)
  - HTTPS: 8053 (API and storage with Let's Encrypt certificate)
  - /health: Health check endpoint (HTTPS)
  - Auto-renewal: Caddy manages Let's Encrypt certificate renewal

### Users
- `root`: System administration
- `keeper`: Registry operations and maintenance

### Storage
- `/var/lib/trustnet-registry/`: Image storage
  - blobs/ - Container layer blobs
  - repositories/ - Image manifests
  - logs/ - Service logs

### Hardware
- **Disk**: 30GB QCOW2 image
- **RAM**: 4GB
- **CPUs**: 2 cores
- **Network**: IPv6 ULA fd10:1234::2

## Network Architecture

### IPv6 ULA (Unique Local Address)

```
Network: fd10:1234::/32
├── fd10:1234::1 (trustnet-node)
└── fd10:1234::2 (trustnet-registry)
```

**Advantages**:
- No external network dependency
- Private addressing within organization
- Route-able if needed
- Persistent across restarts

### Port Mapping

#### IPv6 ULA (Primary - Direct Access)
| Service | IPv6 Address | Port | Protocol | Purpose |
|---------|-------------|------|----------|----------|
| Node SSH | fd10:1234::1 | 22 | SSH | VM access |
| Node RPC | fd10:1234::1 | 26657 | HTTPS | Tendermint queries |
| Node P2P | fd10:1234::1 | 26656 | Encrypted | Validator communication |
| Registry SSH | fd10:1234::2 | 22 | SSH | VM access |
| Registry API | fd10:1234::2 | 8053 | HTTPS | Image registry (Let's Encrypt) |

#### Localhost Testing (IPv4 Fallback)
| Service | Localhost | Port | Purpose |
|---------|-----------|------|----------|
| Node SSH | 127.0.0.1 | 3222 | Forward to fd10:1234::1:22 |
| Registry SSH | 127.0.0.1 | 3223 | Forward to fd10:1234::2:22 |
| Registry HTTPS | 127.0.0.1/registry.trustnet.local | 8053 | Forward to fd10:1234::2:8053 |

## Storage Layout

### Host System
```
~/vms/
├── trustnet-node/
│   ├── trustnet-node.qcow2       # 50GB disk image
│   ├── start-trustnet-node.sh    # VM startup script
│   ├── trustnet-node.pid         # Process ID
│   └── ...
├── trustnet-registry/
│   ├── trustnet-registry.qcow2   # 30GB disk image
│   ├── start-trustnet-registry.sh
│   ├── trustnet-registry.pid
│   └── ...
├── isos/
│   ├── alpine-standard-3.22.2-aarch64.iso
│   ├── alpine-virt-3.22.2-aarch64.iso
│   └── ...
├── cache/
│   ├── tendermint               # Tendermint binary
│   ├── registry                 # Registry binary
│   └── ...
└── network-setup.sh             # IPv6 ULA bridge config
```

### VM Filesystems

**trustnet-node**:
```
/
├── etc/
│   └── trustnet/              # Tendermint config
├── opt/trustnet/node/         # Node data
│   ├── config/
│   ├── data/
│   └── logs/
└── var/log/                   # System logs
```

**trustnet-registry**:
```
/
├── var/lib/trustnet-registry/ # Registry storage
│   ├── blobs/
│   ├── repositories/
│   └── logs/
└── var/log/                   # System logs
```

## Installation Flow

1. **Host Preparation**: QEMU, disk space, network
2. **VM Creation**: Create 50GB + 30GB QCOW2 images
3. **OS Installation**: Alpine 3.22.2 ARM64 on both VMs
4. **User Setup**: Create warden/keeper users with SSH keys
5. **Service Deployment**: Install Tendermint and Registry
6. **Network Configuration**: Setup IPv6 ULA bridge
7. **Verification**: Health checks and connectivity tests

## Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| OS | Alpine Linux | 3.22.2 ARM64 |
| Virtualization | QEMU | 8.2+ |
| Consensus | Tendermint/CometBFT | Latest |
| Registry | Go Registry | Latest |
| Networking | IPv6 ULA | Standard |
| Container Format | QCOW2 | v3 |

## Performance Characteristics

| Metric | Target | Notes |
|--------|--------|-------|
| Network Latency | <10ms | IPv6 ULA, local |
| Block Time | <1s | Tendermint native |
| Storage I/O | 200+ MB/s | QCOW2 on SSD |
| Memory Overhead | ~2GB | Per VM, host OS |
| Boot Time | <30s | Alpine lightweight |
