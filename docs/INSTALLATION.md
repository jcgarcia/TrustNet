# Installation Guide

## Prerequisites

- Linux system with QEMU/KVM
- 8GB+ RAM (16GB+ recommended)
- 100GB+ available disk space
- Internet connection

## Automatic Installation (Recommended)

The one-liner installer handles everything:

```bash
curl -fsSL https://raw.githubusercontent.com/jcgarcia/TrustNet/main/install.sh | bash
```

This will:
1. Download installation scripts
2. Create QEMU VM disk images
3. Generate startup scripts
4. Configure networking

**Installation time**: ~5-10 minutes

## Manual Installation

If you prefer step-by-step control:

```bash
# 1. Clone the repository
git clone https://github.com/Ingasti/trustnet-wip.git trustnet-setup
cd trustnet-setup

# 2. Run VM setup
bash tools/setup-vms.sh --auto

# 3. Start the VMs
~/vms/trustnet-node/start-trustnet-node.sh
~/vms/trustnet-registry/start-trustnet-registry.sh

# 4. Install Alpine Linux on VMs
bash tools/install-alpine.sh --auto

# 5. Deploy services
bash tools/deploy-services.sh --auto

# 6. Verify installation
bash tools/verify-installation.sh --auto
```

## Starting the VMs

After installation, start the VMs:

```bash
# Terminal 1: Start node
~/vms/trustnet-node/start-trustnet-node.sh

# Terminal 2: Start registry
~/vms/trustnet-registry/start-trustnet-registry.sh
```

The VMs will start in daemon mode and listen on:
- **Node**: localhost:2222 (SSH)
- **Registry**: localhost:2223 (SSH)

## Accessing the VMs

SSH into the VMs:

```bash
# Node VM
ssh -p 2222 warden@localhost

# Registry VM
ssh -p 2223 keeper@localhost
```

## Verifying Services

```bash
# Check Tendermint node status
curl http://localhost:26657/status

# Check registry health
curl http://localhost:8000/health
```

## Network Connectivity

The VMs communicate via IPv6 ULA:
- **Network**: fd10:1234::/32
- **Node**: fd10:1234::1
- **Registry**: fd10:1234::2

## Stopping the VMs

```bash
# Kill node VM
sudo kill $(cat ~/vms/trustnet-node/trustnet-node.pid)

# Kill registry VM
sudo kill $(cat ~/vms/trustnet-registry/trustnet-registry.pid)
```

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.
