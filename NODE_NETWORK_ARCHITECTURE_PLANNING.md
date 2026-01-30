# TrustNet Distributed Node Network Architecture Planning

**Date**: January 28, 2026  
**Purpose**: Strategic planning for node-based distributed network (inspired by FactoryVM automation)  
**Status**: Pre-implementation planning (no code yet, discussion phase)

---

## Executive Summary

**Core Concept**: Move TrustNet from "blockchain + Web2 apps" to "**distributed node network** + blockchain"

**Key Insight**: Just as FactoryVM automates factory VM provisioning end-to-end with Jenkins CI/CD, TrustNet should automate node creation, deployment, and lifecycle management.

**What This Means**:
- Each network participant runs a **node** (validator, service provider, user)
- Nodes have **immutable unique IDs** (registered on blockchain)
- Nodes have **reputation** (linked to trust scores)
- Nodes can be **active/inactive/banned**
- Node creation & deployment is **fully automated** (like FactoryVM)
- Network topology is **self-managing** (nodes discover each other automatically)

**Why This Matters**:
- True Web3 decentralization (not just blockchain, but actual distributed network)
- Network resilience (no single point of failure)
- Economic incentives (nodes earn fees for operating)
- Community participation (anyone can run a node)
- Prevents Sybil attacks (nodes have reputation, can't just create infinite fake nodes)

---

## Part 1: Learning from FactoryVM

### What FactoryVM Does (Current)

**FactoryVM Overview**:
- Automated VM provisioning (from bare Alpine Linux to fully operational)
- Complete end-to-end automation (no user intervention)
- Creates fully functional Jenkins CI/CD server
- With components:
  - Operating system (Alpine Linux 3.21)
  - Docker runtime
  - Jenkins server
  - Git integration
  - Build tools (Node, Go, Python, etc.)
  - Deploy tooling (kubectl, Terraform, etc.)
  - Monitoring & logging
  - SSL certificates (self-signed)
  - Network configuration

**Key Architecture Principles**:
1. **Infrastructure as Code**: Everything defined in scripts
2. **Idempotent**: Can run repeatedly, always safe
3. **Self-Contained**: No external dependencies (except base OS)
4. **Reproducible**: Same scripts = same result every time
5. **Automated**: Zero manual intervention
6. **Documented**: Scripts are self-documenting
7. **Versioned**: All scripts in Git
8. **Testable**: Scripts can be tested on different base images

**FactoryVM Process**:
```
1. Base Alpine Linux VM
   ↓
2. Run bootstrap script (install Docker, basic tools)
   ↓
3. Run Jenkins setup script (install Jenkins, plugins)
   ↓
4. Run configuration script (network, SSL, permissions)
   ↓
5. Run verification script (test all components)
   ↓
6. Fully operational factory VM (ready for projects)
```

**Result**: Any engineer can spin up a complete factory VM with one command, identical every time.

### FactoryVM Strengths (Apply to TrustNet Nodes)

✅ **Automation First**: Humans can't make mistakes if machines do the work  
✅ **Infrastructure as Code**: Version control everything; rollback if needed  
✅ **Self-Service**: Team members can provision without ops team  
✅ **Reproducibility**: Same setup everywhere; no "works on my machine"  
✅ **Scalability**: Spin up 100 nodes with same confidence as 1 node  
✅ **Reliability**: Idempotent scripts handle failures gracefully  
✅ **Documentation**: Code is the documentation (no outdated wiki)  

### What FactoryVM Could Do Better

Based on FactoryVM design, TrustNet Node Network should improve:

1. **Health Monitoring**: FactoryVM doesn't auto-heal; TrustNet nodes should
2. **Automatic Updates**: FactoryVM requires manual updates; nodes should auto-update
3. **Distributed Coordination**: FactoryVM is standalone; nodes need to discover & communicate
4. **Reputation System**: FactoryVM has no reputation; TrustNet nodes need this
5. **On-Chain Registration**: FactoryVM doesn't register on blockchain; nodes must
6. **Network Topology**: FactoryVM is flat; TrustNet needs dynamic peer discovery
7. **Reward Distribution**: FactoryVM doesn't earn anything; nodes should be incentivized

---

## Part 2: TrustNet Node Network Architecture (Proposed)

### 2.1 What is a "Node"?

**Definition**: A distributed, autonomous software component that:
- Validates transactions (like blockchain validators)
- Maintains a copy of network state
- Participates in consensus
- Has a unique, immutable identity
- Can earn reputation (and lose it)
- Can be banned from network if reputation depletes

**Types of Nodes** (initially):

| Node Type | Purpose | Quantity | Hardware | Rewards |
|-----------|---------|----------|----------|---------|
| **Validator** | Validate transactions, maintain blockchain | 50+ | £500/mo | 2-5% of fees |
| **Archive** | Store complete history (optional) | 5-10 | £1000/mo | 0.5% of fees |
| **RPC** | Serve blockchain queries to users | 10-20 | £100/mo | 1% of fees |
| **Service** | Run special services (KYC, oracles) | 10+ | £200/mo | Variable |
| **User** | Ordinary TrustNet users (optional) | 100K+ | Laptop/phone | Micro-rewards |

**Node Registration** (on blockchain):
```solidity
contract NodeRegistry {
  struct Node {
    bytes32 nodeId;        // Unique, immutable ID
    address owner;         // Node operator (Ethereum address)
    uint256 joinDate;      // When registered
    uint256 reputation;    // 0-100 score
    bool active;           // Currently participating?
    bool banned;           // Permanently removed?
    uint256 lastHeartbeat; // Last time node communicated
  }
}
```

### 2.2 Node Lifecycle

```
CREATION → PROVISIONING → ACTIVE → INACTIVE → (BANNED or REACTIVATE)

Detailed Flow:

1. CREATION
   - User/operator registers intent to create node
   - Creates wallet + keypair
   - Blockchain records unique nodeId
   - Status: PENDING

2. PROVISIONING
   - Automated provisioning script downloads & runs
   - Node software deployed (validator, RPC, service)
   - Configuration generated from blockchain registration
   - Network identity established
   - Status: INITIALIZING

3. ACTIVE
   - Node starts participating in network
   - Validates transactions
   - Earns reputation & rewards
   - Sends periodic heartbeats
   - Status: ACTIVE

4. INACTIVE (Voluntary)
   - Operator pauses node (maintenance, upgrade)
   - Node stops validating
   - Reputation frozen (doesn't decrease)
   - Can reactivate anytime
   - Status: INACTIVE

5. BANNED (Involuntary)
   - Reputation reaches 0 (misbehavior, downtime)
   - Node automatically kicked from network
   - Cannot reactivate (banned permanently)
   - Operator must register new node
   - Status: BANNED

6. DESTROYED
   - Operator manually removes node
   - Records stay on blockchain (immutable)
   - Can reference for history/audits
   - Status: DESTROYED
```

### 2.3 Node Identity (Immutable)

**Node ID Generation**:
```
nodeId = sha256(operator_address + timestamp + random_nonce)
```

**Properties**:
- Unique globally (collision probability: 1 in 2^256)
- Immutable (cannot be changed after registration)
- Public (visible on blockchain)
- Deterministic (same input always produces same ID)
- Verifiable (anyone can verify it's legitimate)

**Example**:
```
nodeId: 0xa3f2b9c1d4e6f8h2j9k0l1m2n3o4p5q6a7s8d9f0g1h2j3k4
operator: 0x742d35Cc6634C0532925a3b844Bc186e2d195F5e
joinDate: 1706480000
reputation: 92/100
status: ACTIVE
```

**Blockchain Storage** (immutable):
- Node ID → stored on Ethereum Mainnet (permanent record)
- Cannot be deleted or modified
- Available for audits, history, recovery

### 2.4 Reputation System

**Reputation Score**: 0-100 (linked to trust scores)

**How Reputation Increases**:
- Valid transactions validated: +0.1 point per 1000 transactions
- Uptime (99%+): +1 point per day
- Peer reviews (other nodes rate this node): +5 points max per review
- Community votes: +10 points (DAO proposal passes)
- Maximum gain: +5 points per month (prevents gaming)

**How Reputation Decreases**:
- Invalid transaction validated: -10 points (critical error)
- Downtime (missed heartbeats): -1 point per 24 hours
- Peer complaints (other nodes report bad behavior): -5 points per complaint
- Double-spending attempt: -50 points (immediate ban)
- Network abuse: -25 points

**Banning Threshold**:
- Reputation < 10: Node automatically banned
- Cannot recover (must create new node)
- Operator can appeal (DAO voting)

**Examples**:

| Scenario | Reputation Change | Reason |
|----------|-------------------|--------|
| Node offline 1 day | -1 | Missed heartbeats |
| Node offline 30 days | -30 | Severe downtime → banned |
| Validates 1000 txns error-free | +0.1 | Good performance |
| Receives 5 peer reviews (5 stars) | +25 | Community trust |
| Double-spends funds | -50 | Critical fraud → banned |
| Operator appeals ban | TBD | DAO votes |

### 2.5 Node Network Topology

**Peer Discovery** (how nodes find each other):

```
Method 1: DNS Seed Nodes (hardcoded list)
- 5-10 well-known DNS names (trustnet-seed-1.com, etc.)
- Every new node queries DNS seeds to find other nodes
- Returns IP addresses of active nodes

Method 2: Blockchain Registry
- All active nodes' IPs stored on blockchain
- New node queries blockchain for node list
- Connects to random subset (20-30 peers)

Method 3: Gossip Protocol
- Node A learns about Node B from Node C
- Shares peer list with Node D
- Propagates through network organically
- Decentralized, no central directory needed

Network Size Growth:
- 5 seed nodes (month 1)
- 50 validator nodes (month 6)
- 500 service nodes (month 12)
- 100K user nodes (year 2+)
```

**Node Communication Protocol**:

```
Protocol: libp2p (like Ethereum, IPFS use)

1. Node Announcement
   - New node: "Hello, I'm nodeId X, I'm a validator"
   - Existing nodes: Accept or reject based on reputation

2. Heartbeat (every 30 seconds)
   - Node sends: "I'm alive, my latest block hash is X"
   - Network confirms: Node is still responsive

3. Transaction Gossip
   - Node receives transaction: "Alice sends Bob £10"
   - Rebroadcasts to 10 random peers
   - Propagates through network in seconds

4. Block Proposal
   - Validator proposes new block: "Block #1000, 500 transactions"
   - Other validators verify & vote
   - 2/3 consensus → block finalized

5. Peer Sync
   - New node: "What blocks do you have?"
   - Existing node: "I have blocks 1-10000"
   - New node syncs from block 1
   - Full sync: ~30 minutes for 1 million blocks
```

### 2.6 Automated Node Provisioning (Like FactoryVM)

**Goal**: User runs one command → fully operational node in 15 minutes

**Provisioning Process**:

```
STEP 1: Registration (Manual)
$ trustnet-node register
  → Creates wallet
  → Registers on blockchain (txn fee: ~£5)
  → Saves nodeId: 0xa3f2b9c1...
  → Output: node-setup.sh script

STEP 2: Infrastructure (Automated via Script)
$ bash node-setup.sh
  
  a) Environment Setup
     - Download base OS image (Alpine Linux, ~150MB)
     - Create VM or container
     - Network configuration
     - Security hardening (firewall, SSH)
     
  b) Node Software Installation
     - Download TrustNet node binary
     - Verify signature (security)
     - Install to /opt/trustnet/node/
     
  c) Configuration
     - Generate nodeId config file
     - Set operator wallet address
     - Configure peer discovery
     - Set reputation/fee parameters
     
  d) Runtime Setup
     - Install systemd service (auto-restart on reboot)
     - Configure logging to syslog
     - Set up monitoring agents (Prometheus)
     - Install auto-update mechanism
     
  e) Security
     - Generate SSL certificates (self-signed initially)
     - Create operator keypair
     - Lock down file permissions
     - Enable UFW firewall
     
  f) Verification
     - Start node service
     - Verify blockchain connection
     - Check peer discovery (can find other nodes?)
     - Test heartbeat (sending/receiving)
     - Health checks: Memory OK? Disk OK? Network OK?

STEP 3: Activation (Automatic)
  - Node contacts blockchain registry
  - Registers as ACTIVE
  - Joins validator set (if eligible)
  - Starts earning reputation & rewards

RESULT: Fully operational TrustNet node, ready to validate transactions
```

**Provisioning Script Features** (like FactoryVM):

✅ **Idempotent**: Run 1x or 100x, same result  
✅ **Error Recovery**: Handles failures, continues where it left off  
✅ **Offline Capable**: Works without internet (pre-downloaded packages)  
✅ **Logging**: Complete audit trail of everything installed/configured  
✅ **Rollback**: Can revert to previous state if needed  
✅ **Customizable**: Operator can override defaults (memory, disk, peers)  
✅ **Tested**: Validated on multiple OS versions (Alpine, Ubuntu, Debian)  

### 2.7 Automated Operations & Monitoring

**Health Monitoring** (like FactoryVM but enhanced):

```
Metric: Node Uptime
- Sends heartbeat every 30 seconds
- Misses heartbeat → reputation -1 point after 24h downtime
- Auto-restart if crashed (systemd)
- Alerts operator if chronic downtime

Metric: Network Participation
- Validates transactions: +0.1 rep per 1000 txns
- Syncs blocks: Must stay within 1 block of tip
- Falls 10 blocks behind → suspected downtime
- Disconnected >1 hour → kicked (can rejoin)

Metric: Resource Usage
- Memory: Alert if >80% (might be memory leak)
- Disk: Alert if >90% (blockchain growing)
- Network: Alert if traffic >1 Gbps (potential attack)
- CPU: Alert if >95% sustained (might be DOS)

Metric: Peer Connections
- Should maintain 20-30 active peer connections
- If <10 peers for >1h → issue warning
- If no peers for >3h → assume network down, stop validating

Metric: Consensus Participation
- Should vote on every block
- Missed votes → reputation hit
- Double-voting attempt → banned
```

**Automatic Updates** (improved over FactoryVM):

```
Update Process:
1. TrustNet team publishes new release (e.g., v1.1.0)
2. Release signed cryptographically (security)
3. Nodes check for updates hourly
4. If update available:
   - Download new version (hash verified)
   - Run integration tests (safety)
   - Pause validation (ensure clean stop)
   - Backup current version
   - Install new version
   - Restart node service
   - Run health checks
   - Resume validation
5. If health checks fail:
   - Automatically rollback to previous version
   - Alert operator (escalation)
   - Stop validating (safe mode)

Safety Measures:
- Never update during critical network period (voting)
- Stagger updates (not all nodes at once)
- Canary: 10% of nodes test new version first
- Rollback: Easy revert if issue found
```

**Monitoring Dashboard** (visualize network health):

```
Operator Dashboard:
┌─────────────────────────────────────────────┐
│ TrustNet Node Status Dashboard              │
├─────────────────────────────────────────────┤
│ Node ID: 0xa3f2b9c1d4e6...                  │
│ Status: ACTIVE                              │
│ Reputation: 92/100                          │
│ Uptime: 99.8% (29 days)                     │
│ Peers Connected: 24/30                      │
│ Blocks Synced: 1000000/1000000              │
│ Transactions Validated: 157,234              │
│ Earnings (This Month): £234.56              │
├─────────────────────────────────────────────┤
│ Recent Events:                              │
│ ✓ Validated block #1000000 (15 mins ago)    │
│ ✓ Received reputation +1 (1h ago)           │
│ ✓ Updated to v1.1.0 (2h ago)                │
│ ⚠ Peer connection lost (5h ago, recovered)  │
├─────────────────────────────────────────────┤
│ Next Actions:                               │
│ [ ] Maintenance: Node requires restart      │
│ [ ] Security: Update available (v1.2.0)     │
│ [ ] Economics: Earn higher reward on SSD    │
└─────────────────────────────────────────────┘
```

---

## Part 3: Strategic Architecture Questions

**Before we build, we need to decide:**

### Question 1: Node Software Architecture

**Options**:

**Option A: Monolithic Node**
- Single binary: validator + RPC + storage
- ~500MB download
- Works for all node types
- Simpler for operators
- Less flexible

**Option B: Modular Node** (Recommended)
- Pluggable components
- Operators choose: validator? RPC? Archive? Service?
- Download only what you need
- Flexible, composable
- More complex

**Recommendation**: Start with **Option B (Modular)** because:
- Different node types have different hardware requirements
- Operators should choose their role (reduce waste)
- Enables specialized nodes (KYC verification nodes, oracle nodes, etc.)
- Easier to add new node types later

---

### Question 2: Node Software Language

**Options**:

**Option A: Rust** (Like Polkadot, Solana)
- Fast, efficient, memory-safe
- Hard to learn, long compilation times
- Popular in blockchain (easier recruiting)
- Can run on minimal hardware

**Option B: Go** (Like Ethereum, Cosmos)
- Fast, simple, great for networking
- Easier to maintain, faster iteration
- Popular in infrastructure (easy recruiting)
- Good balance of speed/simplicity

**Option C: TypeScript/Node.js** (Like Hardhat)
- Easiest to develop, fastest iteration
- Slower, memory inefficient
- Fine for light nodes, not validators
- Easy for Web3 devs

**Recommendation**: **Option B (Go)**
- Matches existing TrustNet ecosystem (could integrate with existing Go code)
- Good balance of performance + maintainability
- Proven in production (Ethereum, Cosmos)
- Easier to find Go developers than Rust

---

### Question 3: Consensus Algorithm

**Options**:

**Option A: Tendermint PBFT** (Byzantine Fault Tolerant)
- Already decided (in technical architecture)
- ~1-2 second block time
- 2/3 honest nodes required
- Good for 50-100 validators
- Doesn't scale to 1000s (too much communication)

**Option B: Proof of Stake (Like Ethereum 2.0)**
- Simpler consensus
- Can scale to 1000s of validators
- Longer block time (~12 seconds)
- More complex (slashing, penalties)

**Option C: Hybrid**
- Tendermint for consensus
- Proof of Stake for incentives
- Validators stake TrustCoin to join
- Lose stake if misbehave (slashing)

**Recommendation**: **Option C (Hybrid: Tendermint + PoS)**
- Use existing Tendermint consensus (proven)
- Add Proof of Stake incentives (validators stake TrustCoin)
- Validators earn rewards + lose stake if misbehave
- Combines best of both

---

### Question 4: Network Bootstrap (How Many Initial Nodes?)

**Options**:

**Option A: Start with Few (5-10)**
- Faster to launch POC
- Easier to manage early
- Risk: Small network is fragile
- Risk: Centralized (few operators control network)

**Option B: Start with Many (50+)**
- Decentralized from day 1
- More resilient
- Harder to coordinate
- Expensive (must run initial nodes or incentivize)

**Option C: Gradual Growth**
- Phase 1 POC: 5 validator nodes (TrustNet team runs)
- Phase 1 Public: 20-30 validator nodes (invite community)
- Phase 2: 50+ validator nodes (open to public)
- Phase 3: 100+ validator nodes (full decentralization)

**Recommendation**: **Option C (Gradual Growth)**
- Phase 1 POC: 3 nodes (internal testing)
- Phase 1 Public: 10 nodes (friends & advisors)
- Phase 2: 30 nodes (community & early investors)
- Phase 3: 50+ nodes (open to anyone)

---

### Question 5: Node Economics (How Do Nodes Earn?)

**Revenue Streams**:

**1. Transaction Fees**
- Every transaction: 0.1-0.5% fee
- Example: £100 transaction = £0.10 fee
- Fee split: 70% to node operators, 20% to treasury, 10% burned

**2. Block Rewards**
- Every block validated: Fixed reward (e.g., 100 TrustCoin)
- Example: 10 blocks/minute × 1440 min/day × 100 = 1.44M TrustCoin/day to validators
- Distributed proportional to validator stake

**3. Service Rewards**
- KYC verification nodes: £5-10 per user verified
- Oracle nodes: £1 per data feed
- Archive nodes: £0.50 per query answered

**Example Economics (Validator Node)**:
```
Hardware Cost: £400/month (server)
Bandwidth: £100/month
Operator Labor: £1000/month (monitoring)
Total Cost: £1500/month

Revenue (assuming 100K users):
- Transaction fees: 50,000 txns/day × £0.001 = £50/day = £1500/month
- Block rewards: 10 TrustCoin/block × 144 blocks/day × £0.10/coin = £144/month
- Total Revenue: ~£1700/month

Net Profit: £200/month (modest, but decentralizes network)
```

**Recommendation**: 
- Use multi-stream model (fees + block rewards + service rewards)
- Adjust rewards based on network participation
- Ensure profitability for professional operators
- Keep barriers to entry low (anyone can run a node)

---

### Question 6: Node Deployment Environments

**Options**:

**Option A: Cloud Only**
- AWS, Google Cloud, OCI
- Managed infrastructure
- Easy scaling
- Centralization risk (most nodes on same cloud)

**Option B: On-Premise Only**
- Self-hosted servers
- True decentralization
- Harder to operate
- Geographic spread

**Option C: Hybrid** (Recommended)
- Support both cloud and on-premise
- Operators choose what suits them
- Default provisioning scripts for both
- Docker support (any OS/platform)

**Recommendation**: **Option C (Hybrid)**
- Provide provisioning scripts for:
  - AWS (t3.medium, t3.large)
  - Google Cloud (e2-standard-2)
  - OCI (t2.micro free tier)
  - DigitalOcean (5/10 USD droplets)
  - Bare metal (Ubuntu, CentOS, Alpine)
  - Docker (any Docker host)
  - Kubernetes (any k8s cluster)
- Operators run nodes wherever makes sense
- Network gains geographic diversity

---

### Question 7: Governance of Node Network

**Who decides**:
- Node requirements (hardware specs)?
- Block rewards (economics)?
- Update timeline (when new version?)?
- Ban appeals (should banned nodes be reinstated)?
- Fee changes (increase from 0.1% to 0.2%)?

**Options**:

**Option A: TrustNet Team Decides**
- Fastest decisions
- Risk: Centralized (not Web3)
- Risk: Team makes poor decisions
- Violates principle of decentralization

**Option B: Node Operators Vote**
- Slow decisions (must coordinate)
- True decentralization
- Risk: Operators have financial incentives (might vote for higher rewards)
- Each node = 1 vote (or weighted by stake?)

**Option C: Community DAO**
- TrustCoin holders vote (not just validators)
- Broader representation
- More voices but slower
- Needs quorum to avoid voter apathy

**Option D: Hybrid**
- Team proposes, community votes
- Team can veto dangerous proposals
- Balanced approach
- Best for transitioning to full decentralization

**Recommendation**: **Option D (Hybrid, evolving)**
- **Phase 1 (POC)**: Team decides (fast iteration)
- **Phase 2 (Public)**: Team proposes + node operators vote
- **Phase 3 (Mature)**: Full community DAO (TrustCoin holders vote)

---

## Part 4: Implementation Roadmap (Phased)

### Phase 0: Architecture & Planning (Weeks 1-4)

**Goals**:
- Finalize all architecture decisions above
- Design database schema for node registry
- Design smart contracts for node management
- Create provisioning scripts (like FactoryVM)
- Plan testing strategy

**Deliverables**:
- Detailed node specification document
- Database schema diagram
- Smart contract specifications
- Provisioning script framework
- Testing plan

**Team**: 2 architects, 1 engineer

**Cost**: £20K

---

### Phase 1A: Node Provisioning (Weeks 5-12)

**Goals**:
- Build automated node provisioning (like FactoryVM)
- Create node software (basic validator, RPC, archive nodes)
- Implement node heartbeat (simple health check)
- Test provisioning on multiple platforms

**Deliverables**:
- Working provisioning scripts
- Basic node software (Go binary)
- Node heartbeat mechanism
- Documented setup process

**Team**: 2 engineers, 1 DevOps

**Cost**: £40K

---

### Phase 1B: Blockchain Integration (Weeks 8-16)

**Goals**:
- Build smart contracts for node registry
- Implement on-chain node registration
- Node ID generation & immutability
- Status tracking (active/inactive/banned)

**Deliverables**:
- NodeRegistry smart contract
- Node registration UI (web form)
- Blockchain verification tools
- Documentation

**Team**: 1 smart contract engineer, 1 frontend engineer

**Cost**: £25K

---

### Phase 1C: Reputation System (Weeks 12-20)

**Goals**:
- Implement on-chain reputation tracking
- Create reputation oracle (updates scores)
- Build reputation dashboard
- Implement banning logic

**Deliverables**:
- Reputation smart contract
- Oracle mechanism (off-chain updates on-chain)
- Reputation dashboard
- Banning automation

**Team**: 1 smart contract engineer, 1 backend engineer

**Cost**: £30K

---

### Phase 2: Network Communication (Weeks 17-24)

**Goals**:
- Implement peer discovery (DNS seeds, blockchain registry)
- Add P2P communication (libp2p)
- Node-to-node consensus
- Transaction gossip

**Deliverables**:
- P2P networking layer
- Consensus protocol implementation
- Peer discovery mechanism
- Network monitoring tools

**Team**: 2 engineers, 1 DevOps

**Cost**: £50K

---

### Phase 3: Decentralization (Weeks 25-32)

**Goals**:
- Enable operator nodes (not just TrustNet-run)
- Launch open node registration
- Begin bootstrap network
- Economic incentives (rewards)

**Deliverables**:
- Public node registration open
- Reward distribution system
- Network monitoring dashboard
- Community operator handbook

**Team**: 2 engineers, 1 community manager

**Cost**: £40K

---

## Part 5: Critical Discussion Questions

**Before we proceed, we need to discuss:**

1. **Scope Expansion**: Is this node network component replacing the blockchain layer, or complementary to it?
   - Original plan: Ethereum Mainnet (identity) + Polygon (payments) + IPFS (storage)
   - New plan: Add TrustNet native network (validators, P2P, consensus)
   - Question: Do we need both Ethereum AND our own validators?

2. **Timing**: Does this delay Phase 1 launch?
   - Original Phase 1: 6 months, focus on smart contracts + web/mobile apps
   - New Phase 1: Could be 6-9 months (add node provisioning + P2P layer)
   - Question: Is this worth the delay? Can we do it in parallel?

3. **Team Skills**: Do we have/need expertise?
   - Node development: Need Go expertise
   - Distributed systems: Need networking expertise
   - DevOps: Need provisioning/automation expertise
   - Question: Should we hire/partner for this?

4. **Hardware**: Who runs the nodes?
   - Option A: TrustNet team runs initial nodes (centralized)
   - Option B: Community operators from day 1 (decentralized but harder)
   - Question: Which approach fits our values?

5. **Automation Level**: How much can we automate?
   - FactoryVM automates everything, zero intervention
   - Can we do same for TrustNet nodes?
   - Question: What degree of automation should we target?

6. **Blockchain Dependency**: Do nodes need blockchain?
   - Tendermint has its own consensus (doesn't need Ethereum)
   - But we want immutable audit trail (blockchain useful)
   - Question: Use blockchain only for registry/reputation, or full integration?

7. **Cost Impact**: Does this increase budget?
   - Original POC: £324K
   - With node provisioning: £324K + £25K (infrastructure for initial 3 nodes)
   - Question: Should we include node infrastructure in POC?

8. **MVP Definition**: What's minimal viable node network?
   - Option A: 3 nodes (TrustNet team), works, not decentralized
   - Option B: 10 nodes (community + team), more decentralized, harder
   - Question: Which for MVP?

---

## Conclusion: Next Steps

**To proceed, we should:**

1. **Decide on node scope**: Full P2P network, or simpler centralized validators initially?
2. **Clarify blockchain role**: How much on Ethereum vs. own network?
3. **Timeline impact**: Adjust roadmap if node network is critical path
4. **Team requirements**: Identify hiring needs (Go, distributed systems, DevOps)
5. **Budget impact**: Include node provisioning costs in financial planning

**Once decided**, we can:
- Create detailed node specifications
- Build provisioning scripts (learning from FactoryVM)
- Implement Phase 1A (provisioning) in parallel with smart contracts
- Have working prototype in 12-16 weeks

---

**Document prepared**: January 28, 2026  
**Status**: Planning discussion (awaiting decisions)  
**Next**: Schedule architecture review session to address questions above

**Reference**: FactoryVM project location: `/home/jcgarcia/GitProjects/FactoryVM/`
