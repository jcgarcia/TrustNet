# TrustNet

Distributed blockchain infrastructure with Tendermint consensus and container registry. Production-ready setup with Alpine Linux 3.22.2 ARM64, IPv6 ULA networking, and automated QEMU virtualization.

## 🚀 Quick Start

### Prerequisites

The installer needs QEMU:

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y qemu-system-arm qemu-efi-aarch64 qemu-utils
```

**RHEL/Rocky/AlmaLinux:**
```bash
sudo dnf install -y qemu-system-aarch64 qemu-efi-aarch64 qemu-img
```

**Arch Linux:**
```bash
sudo pacman -S qemu-system-aarch64 edk2-armvirt
```

### One-Liner Installation

Install with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/jcgarcia/TrustNet/main/install.sh | bash
```

This will:
- ✅ Download and cache Alpine Linux 3.22.2 ARM64 ISO
- ✅ Create QEMU virtual machines (trustnet-node: 50GB, trustnet-registry: 30GB)
- ✅ Configure IPv6 ULA networking (fd10:1234::/32)
- ✅ Deploy Tendermint consensus validator
- ✅ Setup container image registry with HTTP API
- ✅ Generate VM startup scripts in ~/vms/

Installation takes approximately **20-30 minutes** depending on system speed and network.

**Or manually:**
```bash
git clone https://github.com/jcgarcia/TrustNet.git
cd TrustNet
bash tools/setup-vms.sh --auto
```

## What is TrustNet?

TrustNet is a distributed consensus network built on Tendermint, providing:

- **Decentralized consensus** - BFT consensus engine via Tendermint/CometBFT
- **Container registry** - Distributed image repository for containerized applications
- **IPv6 ULA networking** - Secure inter-node communication via unique local addresses
- **Automated deployment** - Single-command installation on any Linux system with QEMU
- **Production-ready** - Alpine Linux base, optimized for minimal resource usage

## 📋 What's Included

### trustnet-node VM
| Component | Details |
|-----------|---------|
| **Purpose** | Tendermint consensus validator |
| **Disk** | 50GB QCOW2 (vda) |
| **RAM** | 8GB |
| **CPUs** | 4 cores |
| **Network** | IPv6 ULA fd10:1234::1 |
| **RPC Port** | 26657 (blockchain queries) |
| **P2P Port** | 26656 (validator communication) |
| **User** | warden (node operations) |

### trustnet-registry VM
| Component | Details |
|-----------|---------|
| **Purpose** | Container image registry |
| **Disk** | 30GB QCOW2 (vda) |
| **RAM** | 4GB |
| **CPUs** | 2 cores |
| **Network** | IPv6 ULA fd10:1234::2 |
| **HTTP Port** | 8000 (registry API) |
| **Health Check** | /health endpoint |
| **User** | keeper (registry operations) |

### Common Features
- **OS**: Alpine Linux 3.22.2 ARM64 (5MB base image)
- **Networking**: IPv6 ULA (Unique Local Address) - no external dependency
- **Virtualization**: QEMU/KVM with QCOW2 disk images
- **SSH Access**: Ports 2222 (node), 2223 (registry)
- **Caching**: ISO images and binaries cached in ~/.vms/cache/ for fast reinstalls

## 🔌 Network Architecture

```
Network: fd10:1234::/32 (IPv6 ULA)
├── fd10:1234::1 (trustnet-node)
│   ├── RPC:  26657 (Tendermint queries)
│   └── P2P:  26656 (Validator communication)
└── fd10:1234::2 (trustnet-registry)
    └── HTTP: 8000 (Registry API)

SSH Access (via host forwarding):
├── localhost:2222 → node SSH
└── localhost:2223 → registry SSH
```

## 🛠️ Using TrustNet

### Start the VMs

After installation completes:

```bash
# Start both VMs
~/vms/trustnet-node/start-trustnet-node.sh
~/vms/trustnet-registry/start-trustnet-registry.sh

# Wait ~30 seconds for services to start
sleep 30
```

### Verify Installation

```bash
# Check Tendermint node status
curl http://localhost:26657/status | jq .

# Check registry health
curl http://localhost:8000/health | jq .

# SSH into node VM
ssh -p 2222 warden@127.0.0.1

# SSH into registry VM
ssh -p 2223 keeper@127.0.0.1
```

### Common Operations

**Push image to registry:**
```bash
docker tag myapp:latest 127.0.0.1:8000/myapp:latest
docker push 127.0.0.1:8000/myapp:latest
```

**Query blockchain:**
```bash
# Get current block height
curl -s http://localhost:26657/status | jq .result.sync_info.latest_block_height

# Get validator info
curl -s http://localhost:26657/validators | jq .
```

**Check node logs:**
```bash
ssh -p 2222 warden@127.0.0.1 'tail -f /opt/trustnet/node/logs/tendermint.log'
```

## 📚 Documentation

Comprehensive guides for all aspects of TrustNet:

- **[Installation Guide](docs/INSTALLATION.md)** - Detailed setup instructions and prerequisites
- **[Architecture Overview](docs/ARCHITECTURE.md)** - System design, networking, and storage layout
- **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)** - Common issues with solutions and diagnostics

## 📁 File Structure

**Repository:**
```
TrustNet/
├── install.sh                    # One-liner entry point
├── LICENSE                       # MIT license
├── README.md                     # This file
├── docs/
│   ├── INSTALLATION.md          # Step-by-step setup
│   ├── ARCHITECTURE.md          # System design details
│   └── TROUBLESHOOTING.md       # Diagnostic guide
└── tools/
    ├── setup-vms.sh             # Main installer (creates VMs)
    ├── publish-TrustNet         # Publish script (WIP → public)
    └── ... (other utilities)
```

**After Installation:**
```
~/vms/
├── trustnet-node/
│   ├── trustnet-node.qcow2      # Node disk image (50GB)
│   ├── start-trustnet-node.sh   # Start script
│   ├── trustnet-node.pid        # Process ID file
│   └── ...
├── trustnet-registry/
│   ├── trustnet-registry.qcow2  # Registry disk image (30GB)
│   ├── start-trustnet-registry.sh
│   ├── trustnet-registry.pid
│   └── ...
├── isos/
│   └── alpine-virt-3.22.2-aarch64.iso  # Cached Alpine ISO
└── cache/
    ├── tendermint              # Tendermint binary
    ├── registry                # Registry binary
    └── ...
```

## 🔧 VM Management

**Convenience Scripts:**

All management scripts are generated in `~/vms/trustnet-{node,registry}/`:

```bash
# Start VMs
~/vms/trustnet-node/start-trustnet-node.sh
~/vms/trustnet-registry/start-trustnet-registry.sh

# Stop VMs
pkill -f qemu-system-aarch64

# Check VM status
ps aux | grep qemu | grep trustnet
```

## 🐳 Technology Stack

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **OS** | Alpine Linux | 3.22.2 ARM64 | Lightweight base OS |
| **Consensus** | Tendermint/CometBFT | Latest | Byzantine Fault Tolerant consensus |
| **Registry** | Go Registry | Latest | Container image storage and distribution |
| **Networking** | IPv6 ULA | Standard | Secure inter-node communication |
| **Virtualization** | QEMU/KVM | 8.2+ | Hardware virtualization |
| **Disk Format** | QCOW2 v3 | Standard | Copy-on-write disk images |

## 📊 Performance

| Metric | Target | Notes |
|--------|--------|-------|
| Network Latency | <10ms | IPv6 ULA, local network |
| Block Time | <1s | Tendermint native consensus |
| Storage I/O | 200+ MB/s | QCOW2 on SSD |
| Boot Time | <30s | Alpine lightweight |
| Installation | 20-30 min | First install on typical system |
| Reinstall | <5 min | With cached downloads |

## 🆘 Troubleshooting

**Common Issues:**

- **VMs won't start** → Check QEMU installed: `qemu-system-aarch64 --version`
- **No disk space** → Need 100GB free: `df -h ~`
- **Can't reach services** → Verify VMs running: `ps aux | grep qemu`
- **Network issues** → Check IPv6 ULA: `ip -6 addr | grep fd10`

Full troubleshooting guide: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## 🔄 Caching Architecture

TrustNet uses multi-tier caching for fast installations:

| Cache Location | Purpose | Preserved |
|---|---|---|
| `~/.vms/cache/` | Host-side downloads (ISO, binaries) | ✅ Yes |
| `~/vms/trustnet-node/` | Node disk and startup scripts | ✅ Yes |
| `~/vms/trustnet-registry/` | Registry disk and startup scripts | ✅ Yes |

**After first install**, subsequent reinstalls reuse cached downloads, reducing setup time from 20-30 minutes to under 5 minutes.

## 💡 Use Cases

- **Development** - Local blockchain testing and container registry
- **Testing** - CI/CD pipeline validation with Tendermint consensus
- **Learning** - Understanding Byzantine Fault Tolerant consensus and distributed systems
- **Prototyping** - Building distributed applications with container support
- **Research** - Experimenting with consensus mechanisms and network topologies

## 📞 Support

For issues or questions:

1. Check [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common problems
2. Review logs inside VM: `ssh -p 2222 warden@127.0.0.1 'tail -f /opt/trustnet/node/logs/*'`
3. Verify installation with commands in [docs/INSTALLATION.md](docs/INSTALLATION.md#verifying-installation)
4. Check [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for system design details
5. Open issue on [GitHub repository](https://github.com/jcgarcia/TrustNet)

## 📝 License

MIT License - See LICENSE file for details.

## 🤝 Contributing

Contributions welcome! The project is organized as:

- **WIP Repository** (Ingasti/trustnet-wip) - Development and planning
- **Public Repository** (jcgarcia/TrustNet) - Distribution and installation

For questions or contributions, visit the [GitHub repository](https://github.com/jcgarcia/TrustNet).

---

**TrustNet** - Distributed blockchain infrastructure for modern decentralized applications
- Community decides on spending
- Transparent treasury (on-chain)
- Annual budget cycles

---

## Technology Stack

### Blockchain Layer
- **Primary Chain**: Custom PoS chain (or Cosmos SDK)
- **Smart Contracts**: Solidity (with audits)
- **Token Standard**: ERC-20 + governance extensions
- **Cross-Chain Bridge**: Axelar or Wormhole
- **Consensus**: Tendermint/CometBFT

### Backend Services
- **Identity Service**: Decentralized identity (DID)
- **Trust Calculation**: Graph database for relationships
- **Payment Processing**: SPV wallet integration
- **Dispute System**: Multi-signature escrow contracts
- **Messaging**: Encrypted protocol (Signal-compatible)

### Frontend Applications
- **Web App**: React/TypeScript (Vite)
- **Mobile App**: React Native (iOS + Android)
- **Desktop App**: Electron (Mac/Windows/Linux)

### Infrastructure
- **Nodes**: Run on 50+ validators worldwide
- **API Gateway**: Load-balanced RPC endpoints
- **Storage**: IPFS for content (pinned on Arweave)
- **CDN**: Cloudflare for static assets
- **Database**: PostgreSQL for app data (replicated)

---

## Regulatory Considerations

### Jurisdictions to Support Initially
1. **EU**: GDPR, MiCA compliance
2. **US**: FinCEN MSB, SAC compliance
3. **Singapore**: MAS guidelines
4. **Switzerland**: FINMA guidance
5. **UK**: FCA crypto rules

### Compliance Requirements
- KYC/AML (threshold: $10k accumulated)
- Transaction reporting (100%+ thresholds vary)
- Privacy (data minimization, user rights)
- Consumer protection (dispute resolution)
- Security (SOC 2 Type II, regular audits)

### Legal Structure
- Foundation in Switzerland (nonprofit governance)
- Company in Singapore (operations)
- Regional entities for compliance
- DAO treasury for community funds

---

## Phase Roadmap

### Phase 0: Foundation (Months 1-3)
- [ ] Smart contract design and security audit
- [ ] Trust score algorithm finalization
- [ ] Legal framework and entity setup
- [ ] Core team assembly
- [ ] Whitepaper finalization

### Phase 1: MVP (Months 4-8)
- [ ] Basic blockchain network (testnet)
- [ ] Identity verification system
- [ ] TrustCoin token deployment
- [ ] Simple transfer functionality
- [ ] Basic trust scoring
- [ ] User onboarding flow
- [ ] **Target**: 1,000 users

### Phase 2: Social & Finance (Months 9-14)
- [ ] TrustPay app launch
- [ ] TrustHub social features
- [ ] Dispute resolution system
- [ ] Governance voting
- [ ] Mobile app (iOS/Android)
- [ ] **Target**: 10,000 users

### Phase 3: Expansion (Months 15-20)
- [ ] Cross-chain bridges
- [ ] Merchant integrations
- [ ] Premium features
- [ ] Enterprise tools
- [ ] Staking/rewards
- [ ] **Target**: 100,000 users

### Phase 4: Scale (Months 21+)
- [ ] Global expansion
- [ ] Regional compliance
- [ ] Advanced features
- [ ] Partner integrations
- [ ] **Target**: 1M+ users

---

## Success Metrics

### User Adoption
- Month 1: 100 beta testers
- Month 6: 1,000 active users
- Month 12: 10,000 active users
- Month 18: 100,000 active users
- Year 2: 1M+ active users

### Economic Activity
- Daily transactions: 1M+ (goal by Year 2)
- Transaction volume: $1B+ (goal by Year 2)
- Average trust score: >80 (goal)
- Trust stability: <10% monthly volatility

### System Health
- Network uptime: 99.99%
- Transaction finality: <1 second
- Smart contract security: Zero exploits
- User satisfaction: >4.5/5 stars
- Dispute resolution rate: >95% without escalation

---

## Critical Success Factors

1. **Trust Credibility**: System must be fair, transparent, immutable
2. **User Experience**: Onboarding must be simple despite complexity
3. **Security**: No vulnerabilities, regular audits, insurance
4. **Regulation**: Full compliance while maintaining decentralization
5. **Community**: Users must believe in the mission and governance
6. **Network Effects**: Each user makes platform more valuable

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Smart contract exploit | Medium | Critical | Multi-sig governance, formal verification, insurance |
| Regulatory crackdown | Medium | Critical | Compliance-first design, legal team, regional offices |
| Identity spoofing | Medium | High | Multi-factor KYC, liveness checks, periodic reverification |
| Trust gaming/manipulation | High | Medium | Advanced detection, community voting, penalties |
| Low user adoption | High | High | Strong community, partnerships, incentives |
| Scalability bottleneck | Medium | Medium | Layer 2 solutions, sharding, performance optimization |

---

## Questions to Resolve

1. **Blockchain Choice**: Custom chain vs. Layer 2 vs. Cosmos?
2. **Identity Provider**: Which KYC provider? Decentralized identity?
3. **Initial Token Distribution**: How many tokens? Sale vs. mining?
4. **Trust Adjustment Range**: Should users be able to change trust -10 to +10 per action?
5. **Appeal Process**: How many levels? Who decides on appeals?
6. **Monetary Policy**: Inflation rate? Staking rewards?
7. **Privacy**: How much on-chain vs. private?
8. **Partnerships**: Early partners for adoption?

---

## Next Steps

1. **Create Detailed Whitepaper** (Technical + Economic)
2. **Design Smart Contracts** (Identity, Token, Trust, Escrow)
3. **Build Trust Algorithm** (Formula + verification)
4. **Set Up Legal Structure** (Foundation + Company)
5. **Assemble Core Team** (Engineers, designers, legal)
6. **Community Building** (Discord, social media, early adopters)

---

**This is the foundation. Let's build the future of trust.** 🚀
