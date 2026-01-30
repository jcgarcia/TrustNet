# TrustNet Node Registry Service Architecture

**Date**: January 28, 2026  
**Purpose**: Central registry for node discovery, registration, and reputation tracking  
**Timeline**: Weeks 3-4 of POC (after foundational node software)  
**Status**: Architecture finalized, ready for implementation  
**Team**: You + Copilot  

---

## Executive Summary

**Problem**: How do nodes discover each other in a distributed network?

**Solution**: A lightweight registry service that:
1. **Registers** new nodes when they join
2. **Discovers** active nodes (nodes find each other automatically)
3. **Tracks status** (active/inactive/banned)
4. **Manages reputation** (uptime, reliability, behavior)
5. **Provides peer lists** (which nodes should you connect to?)

**Why not just hardcoded seeds?**
- Hardcoded = not scalable beyond 10 nodes
- Doesn't track which nodes are alive
- No way to ban bad nodes
- Can't discover new nodes dynamically

**Why registry is better**:
- ✅ Dynamic discovery (add nodes anytime)
- ✅ Status tracking (who's online?)
- ✅ Reputation system (who's trustworthy?)
- ✅ Scalable (works for 3 nodes or 1000)
- ✅ Stepping stone to blockchain (can migrate to blockchain later)

---

## Architecture Overview

### High-Level View (Distributed Like DNS)

```
┌──────────────────────────────────────────────────────────────────────┐
│                    TrustNet Registry Network                         │
│                                                                      │
│  ┌─────────────────────────┐                                        │
│  │  Root Registry          │  (Authority, Master)                   │
│  │  your-laptop:8000       │  - Canonical node data                 │
│  │  SQLite DB              │  - Syncs to secondary registries       │
│  │  Authority              │  - Validates updates                   │
│  └─────────────────────────┘                                        │
│           ▲                                                         │
│           │ replication (sync every 60 sec)                        │
│           │                                                         │
│  ┌────────┴──────────┬──────────────────┐                          │
│  ▼                   ▼                  ▼                           │
│┌──────────────────┐┌──────────────────┐┌──────────────────┐       │
│ Secondary #1     ││ Secondary #2     ││ Secondary #3     │       │
│ cloud-aws:8001   ││ friend-pc:8002   ││ local-backup:8003│       │
│ (Read-only copy) ││ (Read-only copy) ││ (Read-only copy) │       │
└──────────────────┘└──────────────────┘└──────────────────┘       │
└──────────────────────────────────────────────────────────────────────┘
       ▲                      ▲                      ▲
       │                      │                      │
       │ register/query       │ heartbeat            │ discover peers
       │ (queries go to       │ (to any registry)    │ (any registry)
       │  nearest registry)   │                      │
       │                      │                      │
    Node-1                 Node-2                  Node-3
 (your-laptop)          (cloud-instance)        (friend's-computer)
```

**How it works**:
1. Nodes can register/query/heartbeat to ANY registry (primary or secondary)
2. All registries eventually have same data (replication)
3. If primary goes down, secondary becomes primary
4. Nodes discover all registries, pick nearest/fastest

### Service Components

```
Registry Network (Root + Secondary Replicas)
│
├─ Root Registry (Master/Authority)
│  ├─ HTTP Server (Express.js, Port 8000)
│  │  ├─ Request router
│  │  ├─ Input validation
│  │  └─ Response formatter
│  ├─ Database (SQLite, master copy)
│  │  ├─ nodes table (who, status, reputation)
│  │  ├─ heartbeats table (when was last seen)
│  │  └─ reputation_changes table (why reputation changed)
│  ├─ Replication Engine
│  │  ├─ Change log (track updates)
│  │  ├─ Sync to secondaries every 60 seconds
│  │  └─ Conflict resolution (if secondary diverges)
│  └─ Business Logic
│     ├─ Registration handler (writes to master)
│     ├─ Status tracker
│     ├─ Reputation calculator
│     └─ Cleanup handler
│
├─ Secondary Registry #1 (Read-only replica)
│  ├─ HTTP Server (Express.js, Port 8001)
│  │  ├─ Routes queries only (no writes)
│  │  └─ Falls back to root for updates
│  ├─ Database (SQLite, read-only copy from root)
│  ├─ Sync Receiver
│  │  ├─ Listens for updates from root
│  │  ├─ Applies changes to local DB
│  │  └─ Maintains version number (sync state)
│  └─ Fallback Logic
│     ├─ If root unreachable, forwards updates to queue
│     └─ Syncs queue when root comes back
│
└─ Secondary Registry #2, #3, etc...
   └─ (Same as Secondary #1)
```

---

## Distributed Registry Design (Like DNS)

### Why Distributed?

**Problem with single registry**:
- Single point of failure (registry goes down = nodes can't join)
- Bottleneck (all queries hit one server)
- Single operator risk (only you can maintain it)

**Solution: Distributed like DNS**:
- Root Registry (authoritative source)
- Secondary Registries (read-only replicas)
- Nodes query nearest registry
- Root syncs to secondaries regularly
- If root fails, secondaries still serve queries

### Architecture: Root + Secondary Replicas

**Root Registry** (your laptop initially):
- Master copy of all node data
- Only place that accepts writes
- Syncs to secondary registries every 60 seconds
- Source of truth

**Secondary Registries** (friends, cloud instances):
- Read-only copies of root data
- Answer queries (register, discover, heartbeat)
- Forward writes to root
- Sync from root automatically

**How queries work**:
```
User's Node queries:
  "Who's online?" → Asks nearest registry

If nearest registry has data:
  Return immediately (fast)
  
If registry is stale:
  Either serve stale data (return anyway)
  Or forward to root (slower but current)
  
If registry is dead:
  Node tries next-nearest registry
  Fall back to hardcoded seed nodes
```

### Replication Protocol (Root → Secondary)

**Every 60 seconds, root sends**:
```json
{
  "version": 12345,           // Version number (increment on each sync)
  "timestamp": 1706480000,
  "changes": [
    {
      "type": "node_registered",
      "nodeId": "0xabc123...",
      "data": { /* node data */ }
    },
    {
      "type": "reputation_changed",
      "nodeId": "0xabc123...",
      "oldRep": 90,
      "newRep": 92
    },
    {
      "type": "node_banned",
      "nodeId": "0xdef456...",
      "reason": "Double-spending"
    }
  ]
}
```

**Secondary registry**:
1. Receives changes from root
2. Applies to local database
3. Updates version number
4. Sends ACK back to root

**If secondary falls behind**:
- Stops serving queries
- Asks root: "Send me full snapshot from version X"
- Root sends all data since version X
- Secondary catches up, resumes serving

### Failover: What If Root Goes Down?

**Scenario 1: Temporary outage (root down for 5 minutes)**
- Secondaries continue serving reads
- Writes to secondaries are queued
- When root comes back, queued writes are synced

**Scenario 2: Permanent failure (root server destroyed)**
- Secondaries still work (can answer all queries)
- Promote one secondary to new root
- Other secondaries sync from new root
- Minimal disruption

**For Phase 1 POC**: This is future-proofing. Start with single root, add secondaries later.

---

## Data Model

### Table 1: Nodes

Tracks all nodes and their current status.

```sql
CREATE TABLE nodes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nodeId TEXT UNIQUE NOT NULL,           -- "0xa3f2b9c1..." (immutable)
  owner TEXT NOT NULL,                    -- "alice" (human-readable)
  address TEXT NOT NULL,                  -- "your-laptop.local:9090"
  status TEXT DEFAULT 'ACTIVE',           -- "ACTIVE", "INACTIVE", "BANNED"
  reputation INTEGER DEFAULT 50,          -- 0-100 score
  uptime REAL DEFAULT 100.0,              -- 99.8% (calculated)
  transactionsValidated INTEGER DEFAULT 0, -- count
  joinedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  lastHeartbeat DATETIME,
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

**Example row**:
```
nodeId: "0xa3f2b9c1d4e6f8h2j9k0l1m2n3o4p5q6"
owner: "alice"
address: "192.168.1.100:9090"
status: "ACTIVE"
reputation: 92
uptime: 99.8
joinedAt: 2026-01-28 10:30:00
lastHeartbeat: 2026-01-28 15:45:30
```

### Table 2: Heartbeats

Records every heartbeat for uptime calculation.

```sql
CREATE TABLE heartbeats (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nodeId TEXT NOT NULL REFERENCES nodes(nodeId),
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  latency_ms INTEGER,                     -- How long response took
  status TEXT DEFAULT 'HEALTHY',          -- "HEALTHY", "DEGRADED", "SLOW"
  FOREIGN KEY (nodeId) REFERENCES nodes(nodeId)
);
```

**Why track heartbeats?**
- Calculate uptime percentage (missed heartbeats = downtime)
- Detect slow nodes (latency_ms > threshold)
- Generate alerts if node becomes unresponsive
- Historical data for reputation decisions

### Table 3: Reputation Changes

Audit trail of why reputation changed.

```sql
CREATE TABLE reputation_changes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nodeId TEXT NOT NULL REFERENCES nodes(nodeId),
  oldReputation INTEGER,
  newReputation INTEGER,
  change INTEGER,                         -- +5 or -10 (the delta)
  reason TEXT NOT NULL,                   -- "uptime", "missed_heartbeat", "peer_complaint"
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (nodeId) REFERENCES nodes(nodeId)
);
```

**Example**:
```
nodeId: "0xa3f2b9c1..."
oldReputation: 90
newReputation: 92
change: +2
reason: "30 days uptime bonus"
timestamp: 2026-01-28 10:00:00
```

---

## REST API Specification

### 1. Register Node

**Endpoint**: `POST /api/nodes/register`

**Request**:
```json
{
  "nodeId": "0xa3f2b9c1d4e6f8h2j9k0l1m2n3o4p5q6",
  "owner": "alice",
  "address": "192.168.1.100:9090"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "nodeId": "0xa3f2b9c1d4e6f8h2j9k0l1m2n3o4p5q6",
  "message": "Node registered successfully",
  "knownPeers": [
    {
      "nodeId": "0xb4g3c2d9...",
      "address": "your-laptop.local:9090",
      "status": "ACTIVE"
    },
    {
      "nodeId": "0xc5h4d3e0...",
      "address": "cloud.aws:9090",
      "status": "ACTIVE"
    }
  ],
  "seedNodes": ["your-laptop.local:9090"],
  "registryVersion": "1.0.0"
}
```

**When called**: Node startup (Week 1 code: when node boots)

---

### 2. Discover Peers

**Endpoint**: `GET /api/nodes/active`

**Query parameters**:
- `limit` (optional, default 20): How many peers to return
- `exclude` (optional): Exclude specific nodeId

**Request**:
```
GET /api/nodes/active?limit=10&exclude=0xa3f2b9c1...
```

**Response** (200 OK):
```json
{
  "success": true,
  "totalNodes": 5,
  "activeNodes": 4,
  "peers": [
    {
      "nodeId": "0xb4g3c2d9...",
      "address": "your-laptop.local:9090",
      "reputation": 95,
      "status": "ACTIVE",
      "uptime": 99.9
    },
    {
      "nodeId": "0xc5h4d3e0...",
      "address": "cloud.aws:9090",
      "reputation": 88,
      "status": "ACTIVE",
      "uptime": 98.2
    },
    ...
  ]
}
```

**When called**: Node startup (connect to random 5-10 peers)

---

### 3. Send Heartbeat

**Endpoint**: `PUT /api/nodes/heartbeat/{nodeId}`

**Request**:
```json
{
  "latency_ms": 45
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "nodeId": "0xa3f2b9c1...",
  "status": "ACTIVE",
  "reputation": 92,
  "lastHeartbeat": "2026-01-28T15:45:30Z"
}
```

**When called**: Every 30 seconds (from node's heartbeat loop)

---

### 4. Get Node Status

**Endpoint**: `GET /api/nodes/{nodeId}`

**Request**:
```
GET /api/nodes/0xa3f2b9c1d4e6f8h2j9k0l1m2n3o4p5q6
```

**Response** (200 OK):
```json
{
  "success": true,
  "node": {
    "nodeId": "0xa3f2b9c1...",
    "owner": "alice",
    "address": "192.168.1.100:9090",
    "status": "ACTIVE",
    "reputation": 92,
    "uptime": 99.8,
    "transactionsValidated": 1234,
    "joinedAt": "2026-01-28T10:30:00Z",
    "lastHeartbeat": "2026-01-28T15:45:30Z"
  }
}
```

**When called**: Dashboard queries, peer info requests

---

### 5. Get Recommended Peers

**Endpoint**: `GET /api/nodes/{nodeId}/peers`

**Request**:
```
GET /api/nodes/0xa3f2b9c1.../peers?count=10
```

**Response** (200 OK):
```json
{
  "success": true,
  "requestingNode": "0xa3f2b9c1...",
  "recommendedPeers": [
    {
      "nodeId": "0xb4g3c2d9...",
      "address": "your-laptop.local:9090",
      "reputation": 95,
      "reason": "Highest reputation"
    },
    {
      "nodeId": "0xc5h4d3e0...",
      "address": "cloud.aws:9090",
      "reputation": 88,
      "reason": "Good uptime (98.2%)"
    },
    ...
  ]
}
```

**How it works**: Returns peers sorted by reputation (highest first)

---

### 6. Update Node Status

**Endpoint**: `PUT /api/nodes/{nodeId}/status`

**Request**:
```json
{
  "status": "BANNED",
  "reason": "Double-spending attempt",
  "reputation": 5
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "nodeId": "0xa3f2b9c1...",
  "status": "BANNED",
  "reputation": 5
}
```

**Who calls it**: 
- Reputation engine (automatic banning when reputation < 10)
- Manual admin override (if needed)
- Other nodes reporting bad behavior (future)

---

## Implementation Phases

### Phase 3a: Registry Service Foundation (Week 3, Days 1-3)

**Goal**: Basic API serving requests (single root registry)

**Deliverables**:
- Express.js server running on port 8000
- SQLite database with 3 tables
- 6 REST endpoints (all stubbed to return sample data)
- Ready for later: replication code skeleton

**Testable**:
```bash
$ npm start
Server running on port 8000

# In another terminal:
$ curl http://localhost:8000/api/nodes/active
{
  "peers": [...]
}
```

**Time**: 1-2 days

**Note**: This is the Root Registry. Secondary replicas come in Phase 1+.

---

### Phase 3b: Data Persistence (Week 3, Days 4-7)

**Goal**: Actually store/retrieve data from database (single root)

**Deliverables**:
- SQLite database initialization
- CRUD operations for each table
- Data validation
- Configuration for root registry

**Testable**:
```bash
$ curl -X POST http://localhost:8000/api/nodes/register \
  -H "Content-Type: application/json" \
  -d '{
    "nodeId": "0x...",
    "owner": "alice",
    "address": "localhost:9090"
  }'

# Returns registered node with knownPeers
```

**Time**: 2-3 days

---

### Phase 3c: Reputation Engine (Week 4, Days 1-4)

**Goal**: Calculate and update reputation scores (single root)

**Deliverables**:
- Uptime calculation (% of heartbeats received)
- Reputation changes logging (audit trail)
- Auto-banning (reputation < 10)
- Status transitions (active → inactive → active)

**Testable**:
```bash
# Stop sending heartbeats for a node
# After 24 hours, reputation should drop

$ curl http://localhost:8000/api/nodes/0x...
{
  "status": "INACTIVE",
  "reputation": 40,  # Was 90, now 40
  "uptime": 50.0     # Only got 50% of expected heartbeats
}
```

**Time**: 3-4 days

---

### Phase 3d: Integration with Node Software (Week 4, Days 5-7)

**Goal**: Node software actually uses registry (single root)

**Deliverables**:
- Node registers on startup
- Node sends heartbeats every 30 seconds
- Node discovers peers from registry
- Node connects to random peers

**Testable**:
```bash
# Terminal 1: Registry service
$ npm start

# Terminal 2: Node-1
$ trustnet-node --registry=localhost:8000 --id=node-1
Node-1 registered with nodeId: 0x...
Heartbeat sent successfully

# Terminal 3: Node-2
$ trustnet-node --registry=localhost:8000 --id=node-2
Node-2 registered with nodeId: 0x...
Discovered 1 peer: node-1 at localhost:9090
Connected to node-1 ✓
```

**Time**: 1-2 days

**Note**: At this point, single root registry fully functional. Secondary registries are Phase 1+ (after POC succeeds).

---

## Reputation System Logic

### Reputation Scoring Algorithm

```
REPUTATION = BaseReputation
           + UptimeBonus
           - DowntimepenALTY
           + PeerRatings
           - BadBehavior

Where:
  BaseReputation = 50 (default when joining)
  UptimeBonus = +1 point per 24 hours online (max +30/month)
  DowntimePenalty = -1 point per 24 hours offline
  PeerRatings = +5 if other nodes rate you well
  BadBehavior = -10 if double-spend, -25 if fraud
  
Final Score: Capped at 0-100
Ban Threshold: reputation < 10 → automatically BANNED
```

### Example Reputation Journey

```
Day 1: Node joins
  Reputation: 50 (baseline)
  Status: ACTIVE

Day 2: Perfect uptime (all heartbeats received)
  Reputation: 51 (+1 for 24h uptime)
  Status: ACTIVE

Day 5: Perfect uptime for 4 days
  Reputation: 54 (+4 total)
  Status: ACTIVE

Day 6: Goes offline for 24 hours (missed all heartbeats)
  Reputation: 53 (-1 for downtime)
  Status: INACTIVE

Day 7: Comes back online
  Reputation: 53
  Status: ACTIVE (rejoined)

Day 10: Perfect uptime for 3 more days
  Reputation: 56
  Status: ACTIVE

Year 1: Consistent uptime (350 days online)
  Reputation: 95-98 (capped, high reputation)
  Status: ACTIVE (trusted node)
```

---

## Security Considerations

### Problem 1: Sybil Attack (Create Fake Nodes)

**Attack**: Attacker creates 1000 fake nodes, all rate each other as trustworthy

**Defense**:
- Reputation starts at 50 (neutral, not trusted)
- New nodes can't validate transactions immediately
- Must earn reputation through uptime/behavior
- Rate limiting (can only create 1 node per IP per day)

**Future**: Require deposits (stake TrustCoin to run validator)

---

### Problem 2: Eclipse Attack (Disconnect Node from Network)

**Attack**: Attacker controls all peers of a target node, isolates it

**Defense**:
- Nodes maintain connection to multiple peers (10-20)
- Gossip protocol auto-discovers new peers
- If peer list looks suspicious, fall back to seed nodes
- Registry tracks peer quality (reputation)

---

### Problem 3: Reputation Manipulation

**Attack**: Node's friends all rate it 5 stars to boost reputation

**Defense**:
- Reputation changes logged with reasons (audit trail)
- Peer ratings not implemented yet (for Phase 1)
- Uptime is objective (can't fake heartbeats)
- Behavior is tracked (double-spending detected)

---

### Problem 4: Registry Goes Down

**Attack**: Registry service crashes, nodes can't discover peers

**Defense**:
- Nodes cache peer list in memory (survive 1-2 hour outage)
- Fallback to hardcoded seed nodes
- Gossip protocol still works (nodes tell each other about peers)
- Long-term: Migrate registry to blockchain

---

## Critical: Registry's Primary Function

**What the registry tracks**:
- ✅ **Nodes**: Registration, status, heartbeats, reputation
- ✅ **Network topology**: Peer lists, connectivity
- ✅ **Node metadata**: IPv6 address, associated registry, domain

**What the registry does NOT track**:
- ❌ Other registries (not a registry of registries)
- ❌ Registry replication state (internal only)
- ❌ Blockchain data (stored separately by nodes)

**Registry's knowledge of other registries**:
- Independent registries only: Through DNS lookup of `tnr.{domain}`
- Integrated registries: Know root registry (via DNS), but not advertised
- Secondary registries: Sync from root for node list only

**Communication flow**:
```
Nodes ↔ Registry: Node status, peer discovery
Registries ↔ Root: Replication (delta sync every 60s)
Registries ↔ DNS: Lookup tnr.{domain} for root/secondary IPs
Nodes ↔ Nodes: Peer-to-peer (IPv6 direct, no registry involved)
```

---

## Configuration File Format

For complete installation and configuration details, see [INSTALLATION_AND_DEPLOYMENT_ARCHITECTURE.md](INSTALLATION_AND_DEPLOYMENT_ARCHITECTURE.md).

**registry-config.yml** (Root Registry):
```yaml
# Generated by: trustnet install --registry-type=root

registry:
  role: "root"
  ipv6_address: "2001:db8::1"
  port: 8000

database:
  type: sqlite
  path: /data/registry.db
  maxConnections: 20

replication:
  # Root doesn't sync from anywhere
  enabled: false

heartbeat:
  interval: 30                # seconds
  timeout: 5
  missingThreshold: 10        # miss 10 = offline
  inactiveAfter: 86400        # mark inactive after 24h

reputation:
  initialScore: 50
  uptimeBonus: 1              # +1 per 24 hours
  downtimePenalty: 1          # -1 per 24 hours
  maxScore: 100
  banThreshold: 10            # < 10 = banned

cleanup:
  removeInactiveAfter: 604800 # 7 days
  archiveHistoryAfter: 2592000 # 30 days
```

**registry-config.yml** (Secondary Registry - Integrated):
```yaml
# Generated by: trustnet install --registry-type=integrated --domain=bucoto.com

registry:
  role: "secondary"
  ipv6_address: "2001:db8::100"
  port: 8000

database:
  type: sqlite
  path: /var/lib/trustnet/registry-replica.db
  maxConnections: 10

replication:
  enabled: true
  root_refresh_interval: 60  # seconds (sync from root)
  sync_timeout: 10
  max_queued_writes: 1000    # if root temporarily down
  
root_registry:
  domain: "bucoto.com"
  lookup_method: "dns"       # Dynamically lookup tnr.{domain}

heartbeat:
  interval: 30
  timeout: 5
  missingThreshold: 10

node_sync:
  enabled: true
  sync_interval: 60          # sync node list from root
```

---

## Node Integration Code

**How node software uses registry**:

```go
// node-startup.go
func (n *Node) Start(registryAddr string) error {
  // 1. Register with registry
  nodeId, peers, err := n.registerWithRegistry(registryAddr)
  if err != nil {
    return fmt.Errorf("failed to register: %w", err)
  }
  n.NodeID = nodeId
  
  // 2. Connect to peers
  for _, peer := range peers {
    if err := n.ConnectToPeer(peer); err != nil {
      log.Warnf("failed to connect to %s: %v", peer, err)
    }
  }
  
  // 3. Start heartbeat loop
  go n.heartbeatLoop(registryAddr)
  
  // 4. Start node services
  n.startConsensus()
  n.startTransactionPool()
  
  return nil
}

// Heartbeat every 30 seconds
func (n *Node) heartbeatLoop(registryAddr string) {
  ticker := time.Tick(30 * time.Second)
  for range ticker {
    start := time.Now()
    err := n.sendHeartbeat(registryAddr)
    latency := time.Since(start).Milliseconds()
    
    if err != nil {
      log.Warnf("heartbeat failed: %v", err)
    } else {
      log.Debugf("heartbeat sent (latency: %dms)", latency)
    }
  }
}
```

---

## Monitoring & Observability

### Registry Health Dashboard

```
Registry Status Dashboard
└─ Service Health
   ├─ API Response Time: 45ms (good)
   ├─ Database Queries/sec: 234 (normal)
   ├─ Connection Pool: 7/10 (healthy)
   └─ Uptime: 99.8%

└─ Network Health
   ├─ Total Nodes: 5
   ├─ Active: 4 (80%)
   ├─ Inactive: 1 (20%)
   ├─ Banned: 0
   └─ Average Reputation: 84/100

└─ Recent Events
   ├─ node-3 registered (5 mins ago)
   ├─ node-2 missed heartbeat (2 mins ago)
   ├─ node-1 reputation +1 (1 min ago)
   └─ node-4 came online (just now)

└─ Alerts
   ├─ ⚠️ node-2 offline (check if dead?)
   ├─ 🚨 None currently
```

---

## Future: Blockchain Migration

**Path to decentralization**:

**Phase 1 (Current POC)**: Registry Service (centralized, your laptop)

**Phase 2 (After POC)**: Move to blockchain
```
Today:  Node registers with Registry Service (REST API)
Later:  Node registers with NodeRegistry smart contract

Today:  Node heartbeat to Registry Service
Later:  Node submits proof-of-work, other validators agree

Result: Immutable, decentralized node registry
        No single point of failure
```

**No changes to node software**: Only registry address changes from `localhost:8000` to blockchain address

---

## Phase 1+: Distributed Registry (Root + Secondaries)

**Timeline**: After POC succeeds (Months 4-6), before scaling beyond 10 nodes

**Goal**: Add secondary registries for redundancy, scalability, and geographic distribution (like DNS)

**Why distributed**:
- ✅ No single point of failure (multiple registries)
- ✅ Faster peer discovery (nodes use nearest registry)
- ✅ Geographic distribution (registries in different continents)
- ✅ Aligns with Web3 principles (decentralized, resilient)
- ✅ Scales to 100+ nodes (multiple registries handle load)

**Architecture**:

```
┌─────────────────────────────────────────────────────────────────┐
│                      TrustNet Node Registry                      │
│                    (Distributed DNS-Like)                        │
└─────────────────────────────────────────────────────────────────┘

     ┌─────────────────────────────────────────────────────┐
     │         Root Registry                               │
     │  (Your Laptop, authoritative source)                │
     │  ├─ Accepts node registrations                      │
     │  ├─ Processes reputation changes                    │
     │  ├─ Syncs to secondaries every 60 seconds           │
     │  └─ Role: Master/authority                          │
     └───────────────┬──────────────────────────────────────┘
                     │ Replicate every 60 sec
          ┌──────────┴──────────┐
          │                     │
    ┌─────▼────────┐    ┌──────▼──────────┐
    │ Secondary #1 │    │ Secondary #2    │
    │ (Friend's    │    │ (Cloud Backup)  │
    │  Cloud)      │    │                 │
    ├─────────────┤    ├─────────────────┤
    │ Read-only   │    │ Read-only       │
    │ replica     │    │ replica         │
    │ Serves      │    │ Serves          │
    │ queries     │    │ queries         │
    │             │    │                 │
    │ Updates     │    │ Updates         │
    │ forwarded   │    │ forwarded       │
    │ to root     │    │ to root         │
    └─────────────┘    └─────────────────┘

        Nodes query any registry, writes go to root
        If root down: Secondaries queue updates locally
```

**How replication works**:

```
Timeline:
  t=0:    Root has 5 nodes (versions 1.0)
          Secondary #1 has 5 nodes (version 0.9) - slightly stale
          Secondary #2 has 5 nodes (version 0.9)

  t=30s:  New node registers with root
          Root now has 6 nodes (version 1.1)

  t=60s:  Root: "I've changed since version 1.0"
          Root sends delta to secondaries (1 new node)
          Secondary #1: Applies changes, now at version 1.1
          Secondary #2: Applies changes, now at version 1.1

  t=90s:  Node queries Secondary #1
          Secondary #1: Returns all 6 nodes (up-to-date)

Replication protocol (JSON):
{
  "type": "sync_request",
  "from_version": 0.9,
  "timestamp": 1234567890
}

Root responds:
{
  "type": "sync_response",
  "to_version": 1.1,
  "changes": [
    {
      "action": "insert",
      "table": "nodes",
      "data": {"nodeId": "0x123...", "status": "ACTIVE"}
    }
  ],
  "timestamp": 1234567890
}

If Secondary falls behind:
{
  "type": "full_snapshot_request",
  "from_version": 0.7
}

Root responds with all data since version 0.7 (or full dump if too far behind)
```

**Configuration examples**:

```yaml
# root-registry-config.yml
# Run on: Your Laptop
registry:
  role: "root"
  port: 8000
  database: "./registry.db"
  replicationInterval: 60    # Sync to secondaries every 60 seconds
  
  secondaries:
    - name: "secondary-1"
      host: "friend-server.local"
      port: 8001
      priority: 1             # Try this one first
    - name: "secondary-2"
      host: "cloud-backup.aws"
      port: 8002
      priority: 2
```

```yaml
# secondary-1-config.yml
# Run on: Friend's Cloud Server
registry:
  role: "secondary"
  port: 8001
  database: "./registry-replica.db"
  
  rootRegistry:
    host: "your-laptop.local"
    port: 8000
  
  syncInterval: 60           # Check for updates every 60 seconds
  syncTimeout: 10            # Timeout if root doesn't respond
  
  maxQueuedWrites: 1000      # If root down, queue this many updates
```

```yaml
# secondary-2-config.yml
# Run on: Cloud Backup
registry:
  role: "secondary"
  port: 8002
  database: "./registry-replica.db"
  
  rootRegistry:
    host: "your-laptop.local"
    port: 8000
  
  syncInterval: 60
  syncTimeout: 10
```

**Node discovers all registries**:

```go
// node/registry-client.go
// All registry addresses (root first, secondaries as fallback)
registryAddresses := []string{
  "your-laptop.local:8000",    // Root registry
  "friend-server.local:8001",  // Secondary #1
  "cloud-backup.aws:8002",     // Secondary #2
}

// On startup
func (n *Node) RegisterAndDiscoverPeers() error {
  // 1. Register with root (ensure consistency)
  resp, err := n.registerWithRegistry(registryAddresses[0])
  if err != nil {
    log.Errorf("Failed to register with root: %v", err)
    return err  // Can't proceed without registering
  }
  
  // 2. Cache all registry addresses for later use
  n.RegistryCache = registryAddresses
  
  // 3. Discover peers (can use any registry)
  peers, err := n.discoverPeersFromNearest()
  if err != nil {
    log.Errorf("Failed to discover peers: %v", err)
  }
  
  return nil
}

// Try nearest registry first, fall back to others
func (n *Node) discoverPeersFromNearest() ([]Peer, error) {
  for _, addr := range n.RegistryCache {
    peers, latency, err := n.queryRegistry(addr, "/api/nodes")
    if err == nil {
      log.Infof("Discovered %d peers from %s (latency: %dms)", len(peers), addr, latency)
      return peers, nil
    }
    log.Warnf("Registry %s failed: %v, trying next", addr, err)
  }
  
  // If all registries down, use hardcoded seed nodes
  log.Warnf("All registries down, using seed nodes as fallback")
  return n.SeedNodes, nil
}
```

**Query behavior (improved)**:

```
1. Node needs to register or heartbeat:
   └─ ALWAYS use root (write consistency)

2. Node needs to discover peers:
   ├─ Use nearest registry (lowest latency)
   ├─ If times out: Try next registry
   └─ If all down: Use hardcoded seeds

3. If root registry is down:
   ├─ Secondary #1 queues registration locally
   ├─ Secondary #2 queues registration locally
   └─ When root comes back up: Secondaries sync queued updates
   └─ Root applies all updates in order

4. If secondary is down:
   └─ No impact (root and other secondaries work fine)
```

**Benefits checklist**:
- ✅ No single point of failure (multiple registries)
- ✅ Faster peer discovery (3 registries = 3x query capacity)
- ✅ Geographic distribution (you, friend, cloud provider)
- ✅ Fault tolerance (works if one registry down)
- ✅ Audit trail (every change logged with source)
- ✅ Scalability (add more secondaries as network grows)
- ✅ Web3-aligned (decentralized, no central authority)

**Implementation plan**:
1. Keep Week 3-4 single-root design (POC scope)
2. Add secondary registry code in Phase 1 (months 4-6)
3. Deploy to friend's server + cloud backup
4. Test failover scenarios
5. Update node software to support multiple registries
6. Monitor replication lag and catchup

**Success criteria for Phase 1+**:
- [ ] Secondary #1 syncs all changes from root
- [ ] Secondary #2 syncs all changes from root
- [ ] Replication lag < 5 minutes under normal load
- [ ] If root down: Secondaries queue up to 1000 updates
- [ ] If root back: Queued updates apply in order
- [ ] Nodes use nearest registry (lower latency)
- [ ] 99.9% uptime (measured across all 3 registries)

---

## Implementation Checklist

### Week 3 (Foundation)
- [ ] Express.js server scaffolding
- [ ] SQLite database schema
- [ ] 6 REST endpoints (stubbed)
- [ ] Input validation middleware
- [ ] Error handling
- [ ] Logging setup
- [ ] Docker container (optional)
- [ ] Unit tests (basic)

### Week 4 (Persistence + Reputation)
- [ ] Node registration logic
- [ ] Heartbeat processing
- [ ] Uptime calculation
- [ ] Reputation calculation
- [ ] Auto-banning logic
- [ ] Peer discovery algorithm
- [ ] Integration tests
- [ ] Performance testing

### Success Criteria
- [ ] Registry starts without errors
- [ ] Node can register and get peer list
- [ ] Node sends heartbeats every 30 seconds
- [ ] Reputation changes logged
- [ ] Node banned when reputation < 10
- [ ] 3 nodes can discover each other
- [ ] Registry survives node crashes
- [ ] <100ms response time for API calls

---

**Document prepared**: January 28, 2026  
**Status**: Architecture finalized, ready for Week 3 implementation  
**Next**: Update INDEX.md, then start coding

