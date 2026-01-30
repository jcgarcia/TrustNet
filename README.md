# TrustNet

A distributed blockchain infrastructure for decentralized trust networks.

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/jcgarcia/TrustNet/main/install.sh | bash
```

This will:
- Create QEMU virtual machines (trustnet-node, trustnet-registry)
- Install Alpine Linux 3.22.2 ARM64
- Configure networking and storage
- Deploy Tendermint consensus node
- Setup container registry

## Requirements

- QEMU/KVM installed
- 60GB+ available disk space
- 8GB+ RAM recommended
- Linux system

## Architecture

- **trustnet-node**: Tendermint consensus validator (RPC: 26657, P2P: 26656)
- **trustnet-registry**: Container image registry (HTTP: 8000)
- **IPv6 ULA Network**: fd10:1234::/32 for inter-node communication

## Installation Phases

1. **Phase 2**: QEMU VM creation (automated)
2. **Phase 3**: Alpine Linux installation
3. **Phase 4**: Cache deployment and system setup
4. **Phase 5**: Verification and testing

## Documentation

For detailed information, visit the [GitHub repository](https://github.com/jcgarcia/TrustNet).

## License

MIT License - See LICENSE file for details.
