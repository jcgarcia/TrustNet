# TrustNet POC: Distributed Node Network (Trust-First)

**Date**: January 28, 2026  
**Phase**: Proof of Concept (before public launch)  
**Status**: Architecture finalized, ready for implementation  
**Team**: 2 engineers (you + Copilot), community members (friends, testers)  
**Timeline**: 8-12 weeks to working MVP  
**Cost**: £0 (use free/cheap cloud, local machines)  

---

## Executive Summary

**Build a distributed network of nodes that score trust relationships**, without blockchain or cryptocurrency initially.

**3-Node MVP**:
- Node #1: Your local machine (development)
- Node #2: Cloud instance (AWS free tier or similar)
- Node #3: Friend's computer (optional, proves distribution)

**All nodes run Tendermint consensus** → agree on current trust state  
**All nodes have reputation** → scored by uptime, reliability, behavior  
**Full automation** → one command to provision, zero manual intervention  
**No blockchain yet** → add later when TrustCoin is ready  

**Why this approach**:
- Simpler than blockchain (test consensus without smart contracts)
- Proves distributed trust scoring works (core value of TrustNet)
- Can show working demo to friends/community in 8-12 weeks
- Foundation for later adding TrustCoin on top

---

## Architecture Decisions (Finalized)

### Decision 1: TrustCoin Location
**DECIDED**: Build TrustCoin on TrustNet distributed network (not Ethereum/Polygon)
- Ethereum/Polygon are external dependencies
- TrustNet network is self-contained
- True peer-to-peer cryptocurrency
- Add after POC proves value

### Decision 2: Blockchain Dependency
**DECIDED**: Start WITHOUT blockchain, add later
- POC Phase: Local ledger (consensus enough)
- Phase 1+: Deploy nodes on blockchain (Ethereum, Polygon, or own)
- Advantage: Faster POC, simpler testing, add blockchain when needed

### Decision 3: Team
**DECIDED**: You + Copilot + friends (no hiring, no budget)
- You: Architecture decisions, testing, community
- Copilot: Code implementation
- Friends: Test nodes, early feedback

### Decision 4: Infrastructure
**DECIDED**: Local machines + free/cheap cloud
- Node #1: Your laptop (development)
- Node #2: AWS free tier (or DigitalOcean £3/mo)
- Node #3: Friend's computer (SSH accessible)

### Decision 5: Automation
**DECIDED**: FactoryVM level (zero user intervention)
- Single command: `trustnet-node provision`
- Outputs: Running node, connected to network, ready to use
- No manual configuration files
- No service restarts
- No SSH access needed (unless debugging)

### Decision 6: MVP Nodes
**DECIDED**: Start with 3, scale to 10 before public
- Phase 0 POC (weeks 1-8): 3 nodes (internal testing)
- Phase 0.5 (weeks 9-12): 10 nodes (friends, advisors, stress testing)
- Public launch (Phase 1): Open to community

---

## Core Concept: Trust-First Network

**What is a transaction?** (POC version)

NOT: "Alice sends Bob 10 coins" (financial transaction)  
BUT: "Alice rates Bob 4 stars for reliability" (trust transaction)

**Example Transaction**:
```json
{
  "type": "trust_rating",
  "from": "Alice",
  "to": "Bob",
  "rating": 4,
  "category": "reliability",
  "timestamp": 1706480000,
  "reason": "Bob's node stayed online for 30 days"
}
```

**Network Effect**:
- All nodes see all trust ratings
- Nodes calculate Bob's reputation: (4 + 5 + 3 + 4.5) / 4 = 4.1 / 5.0 stars
- If reputation drops below threshold → Bob's node gets warned/banned
- Nodes with high reputation earn rewards (later, TrustCoin)

---

## Data Model (POC)

### Entity 1: Node
```
Node {
  nodeId: "0xa3f2b9c1..."           // Immutable identifier
  owner: "Alice"                    // Human-readable name (POC)
  status: "ACTIVE" | "INACTIVE" | "BANNED"
  reputation: 85                    // 0-100 score
  lastHeartbeat: 1706480000         // Unix timestamp
  uptime: 99.8                      // Percentage
  transactionsValidated: 1234       // Count
  joinDate: 1706000000
}
```

### Entity 2: Trust Rating
```
TrustRating {
  id: "tr-12345"
  fromNode: "0xa3f2b9c1..."
  toNode: "0xb4g3c2d9..."
  rating: 4                         // 1-5 stars
  category: "reliability" | "performance" | "honesty"
  reason: "Node stayed online for 30 days"
  timestamp: 1706480000
  signature: "..."                  // Cryptographic proof
}
```

### Entity 3: Ledger (Node State)
```
Ledger {
  nodes: Map<nodeId, Node>
  ratings: List<TrustRating>
  blocks: List<Block>               // Consensus blocks
  currentBlock: Block
  height: 1234                      // Block number
}
```

### Entity 4: Block (Tendermint)
```
Block {
  height: 1234
  timestamp: 1706480000
  transactions: [TrustRating, TrustRating, ...]
  previousHash: "abc123..."
  hash: "def456..."
  validator: "0xa3f2b9c1..."        // Which node proposed this block
  votes: [Signature, Signature, ...]  // 2/3+ nodes must agree
}
```

---

## Network Topology

### Peer Discovery
```
1. Hardcoded Seed Nodes (for bootstrapping)
   - Node A's address stored in code
   - When Node B starts, contacts Node A
   - Node A returns list of other nodes

2. Gossip Protocol (spreading knowledge)
   - Node A learns about Node C from Node B
   - Node A shares Node C with Node D
   - Network discovers all peers organically

3. Dynamic Peer List
   - Each node maintains 5-10 active peer connections
   - Drops dead peers automatically
   - Adds new peers as they come online
```

### Communication Protocol (libp2p)
```
Heartbeat (every 30 seconds)
- Node sends: "I'm alive, my latest block is #1234"
- Network confirms node is responsive
- Reputation stays intact if heartbeat received

Trust Rating Gossip
- Node receives: "Alice rates Bob 4 stars"
- Rebroadcasts to all 10 peers
- Propagates through network in seconds
- All nodes see rating within 5 seconds

Block Proposal
- Validator node: "I propose block #1235 with these transactions"
- Other nodes: "I verify and sign"
- 2/3 consensus: Block finalized
- All nodes update their ledger
```

---

## Implementation Plan (8-12 Weeks)

### Week 1-2: Foundation
**Goal**: Basic node software that can run standalone

**Deliverables**:
- Node binary (Go application)
- Local ledger (in-memory or SQLite)
- Basic REST API (curl-able)
- Simple configuration file

**Testable**: 
```bash
$ trustnet-node --config=config.json
Node started on port 8080
Listening for peers on port 9090
Ready to accept transactions
```

### Week 3-4: Consensus Layer
**Goal**: 2 nodes can agree on transactions

**Deliverables**:
- Tendermint PBFT implementation (or use tendermint library)
- Block structure (header + transactions)
- Transaction validation
- Consensus voting

**Testable**:
```bash
# Terminal 1
$ trustnet-node --peer=localhost:9090 --id=node-1
Node 1 started

# Terminal 2
$ trustnet-node --peer=localhost:9091 --id=node-2
Node 2 started

# Both nodes see each other
# Send transaction to Node 1
# Both nodes apply it to ledger (consensus works)
```

### Week 5-6: Trust Scoring
**Goal**: Calculate reputation from ratings

**Deliverables**:
- Trust rating transactions
- Reputation calculation engine
- Automatic banning (reputation < 10)
- Dashboard showing scores

**Testable**:
```bash
$ trustnet-query reputation --node=node-1
Node-1 Reputation: 85/100
  Ratings received: 23
  Average: 4.2/5.0
  Uptime: 99.8%
  Status: ACTIVE
```

### Week 7-8: Network Scaling
**Goal**: 3 nodes on different machines

**Deliverables**:
- Peer discovery (seed nodes list)
- Multi-node consensus (2/3 voting)
- Health monitoring (heartbeats)
- Network topology visualization

**Testable**:
```bash
$ trustnet-status
Network Status:
  Total Nodes: 3
  Active: 3/3
  Consensus Height: 1234
  Last Block: 5 seconds ago
  
Nodes:
  node-1 (your-laptop.local): ACTIVE, reputation 92/100
  node-2 (cloud-instance.aws): ACTIVE, reputation 88/100
  node-3 (friend-computer): ACTIVE, reputation 81/100
```

### Week 9-10: Automation & Provisioning
**Goal**: One command spins up a node

**Deliverables**:
- Provisioning script (like FactoryVM)
- Automated setup (download, configure, start)
- Health checks (verify node is working)
- Error recovery (restarts on crash)

**Testable**:
```bash
$ trustnet-provision --owner=friend-name --cloud=aws
✓ Creating node credentials
✓ Downloading node binary
✓ Launching EC2 instance
✓ Configuring network
✓ Verifying connectivity
✓ Node ready! ID: 0x...
```

### Week 11-12: Testing & Hardening
**Goal**: POC ready for friends to run

**Deliverables**:
- Test suite (unit + integration)
- Documentation (how to run)
- Troubleshooting guide
- Performance benchmarks

**Testable**:
```bash
$ trustnet-test
Running 45 tests...
✓ 45/45 passed
✓ No memory leaks
✓ Network resilience: OK
✓ Consensus timeout: 2 seconds
✓ Ready for production
```

---

## Proof of Concept Checklist

**Core Functionality**:
- ✅ Single node runs without errors
- ✅ 2 nodes reach consensus on transactions
- ✅ 3 nodes vote by 2/3 majority
- ✅ Trust ratings propagate to all nodes in <5 seconds
- ✅ Reputation calculated correctly (average of all ratings)
- ✅ Nodes ban when reputation < 10
- ✅ Nodes heal reputation when behavior improves (optional)

**Network**:
- ✅ Peer discovery (new node finds others automatically)
- ✅ Heartbeats (every node detects if peer is down)
- ✅ Network topology (can visualize all nodes)
- ✅ Graceful shutdown (node stops cleanly, others continue)
- ✅ Node restart (can rejoin network after downtime)

**Automation**:
- ✅ Single command to provision node
- ✅ No manual configuration needed
- ✅ Auto-restart on crash
- ✅ Auto-update when new version available

**Testing**:
- ✅ >80% code coverage
- ✅ All consensus scenarios tested
- ✅ Failure scenarios tested (node down, network partition, etc.)
- ✅ Load testing (1000 transactions/second)
- ✅ Soak testing (nodes run for 7 days without issues)

**Documentation**:
- ✅ How to provision a node
- ✅ How to add trust ratings
- ✅ How to query reputation
- ✅ How to troubleshoot issues
- ✅ Architecture diagrams (data model, network topology)

---

## Success Criteria (What "Done" Looks Like)

**Minimum Success**:
- 3 nodes on different machines
- Consensus works (all nodes agree on transactions)
- Trust ratings visible on all nodes
- Reputation calculated correctly
- Can show to 1-2 friends, they understand it

**Good Success**:
- All above, plus:
- 10 nodes running reliably
- Friends can provision their own nodes
- Uptime 99%+
- Can show to 5-10 people, they want to run nodes

**Excellent Success**:
- All above, plus:
- 20-30 nodes in test network
- Community contributing (friends testing, reporting bugs)
- Ready to make public (documentation, demo video)
- Friends are excited enough to help evangelize

---

## After POC: Phase 1 (Months 4-6)

Once POC proves the concept works:

1. **Add TrustCoin**
   - Track balances (who owns how much)
   - Transfer transactions (Alice sends Bob 10 TrustCoins)
   - Connect to reputation (high reputation = can earn more)

2. **Add Blockchain** (optional but recommended)
   - Deploy to Ethereum Mainnet (immutable registry)
   - or Polygon (cheaper transactions)
   - or own chain (if needed)
   - All previous transactions logged forever

3. **Add Web/Mobile UI**
   - Pretty dashboard (not just CLI)
   - Mobile app for rating/checking reputation
   - Easy onboarding

4. **Scale Community**
   - Open node provisioning to public
   - Community validators earn TrustCoin
   - Network grows organically

---

## Risks & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Consensus bugs (nodes disagree) | Medium | Critical | Extensive testing, run 2 weeks before opening to friends |
| Network partitions (nodes can't reach each other) | Medium | High | Implement timeout + rejoin logic, test with packet loss |
| Performance (slow consensus) | Low | Medium | Tendermint is proven, should be fine, benchmark early |
| Security (bad actor rates everyone 1-star) | High | Low | Reputation system is designed for this, reputation recovers |
| Cloud instance costs | Low | Low | Use free tier (AWS, Google Cloud, Heroku) |
| Friends' machines go down | Medium | Low | Network survives if 2/3+ nodes online, expected behavior |

---

## Why This is the Right POC

✅ **Proves core TrustNet concept**: Distributed trust scoring without centralized authority  
✅ **Simpler than blockchain**: No smart contracts, no gas fees, no Ethereum dependency  
✅ **Testable in 8-12 weeks**: Real working code, not just planning  
✅ **Can show to friends**: They can run their own nodes, see results  
✅ **Foundation for TrustCoin**: Consensus layer ready when we add cryptocurrency  
✅ **Aligned with FactoryVM**: Automated provisioning, zero intervention  
✅ **No budget needed**: Free cloud, your machines, time only  

---

## Next Steps

1. **Commit this document** (preserve ideas)
2. **Decide on Go vs Rust** (language choice for node software)
3. **Choose consensus library** (use Tendermint package or build from scratch?)
4. **Setup repository structure** (where code lives, how organized)
5. **Start Week 1** (foundation: single node that runs)

---

**Document prepared**: January 28, 2026  
**Status**: Ready for implementation  
**Next meeting**: Architecture review & language/library decisions

