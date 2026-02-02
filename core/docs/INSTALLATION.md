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

The VMs will start in daemon mode with:
- **Node**: IPv6 fd10:1234::1 (port 22 SSH), localhost:3222 (testing)
- **Registry**: IPv6 fd10:1234::2 (port 22 SSH), localhost:3223 (testing), HTTPS on 8053

## Accessing the VMs

### Preferred: Direct IPv6 ULA Access

```bash
# Node VM (via IPv6 - recommended)
ssh -6 warden@fd10:1234::1

# Registry VM (via IPv6 - recommended)
ssh -6 keeper@fd10:1234::2
```

### Fallback: Localhost Testing Access

```bash
# Node VM (testing)
ssh -p 3222 warden@127.0.0.1

# Registry VM (testing)
ssh -p 3223 keeper@127.0.0.1
```

## HTTPS & Security Configuration

### Let's Encrypt Certificates (Automatic)

The registry uses **Caddy** reverse proxy with automatic Let's Encrypt certificate management:

```bash
# SSH into registry VM
ssh -6 keeper@fd10:1234::2

# Check certificate status
ls -la /etc/caddy/certs/

# View Caddy logs
journalctl -u caddy -f
```

**Features**:
- ✅ Automatic certificate renewal (90 days before expiry)
- ✅ HTTPS enforced on port 8053
- ✅ HTTP → HTTPS redirect
- ✅ No self-signed warnings
- ✅ Valid for domain `registry.trustnet.local`

### Localhost Testing with Self-Signed Fallback

For IPv4-only testing, use hostname verification bypass:

```bash
# Access registry via localhost (testing)
curl -k -H 'Host: registry.trustnet.local' https://localhost:8053/health | jq .

# Or import CA certificate
ssh -6 keeper@fd10:1234::2 'cat /etc/caddy/certs/registry-ca.crt' > /tmp/registry-ca.crt
curl --cacert /tmp/registry-ca.crt https://registry.trustnet.local:8053/health | jq .
```

### Tendermint RPC HTTPS

Tendermint RPC also uses HTTPS via Caddy frontend:

```bash
# Query RPC via IPv6 HTTPS
curl -k https://[fd10:1234::1]:26657/status | jq .

# Or via hostname
curl -k https://node.trustnet.local:26657/status | jq .
```

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
