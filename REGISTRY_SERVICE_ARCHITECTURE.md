# TrustNet Registry Service Architecture

**Date**: January 28, 2026  
**Purpose**: Node registration, discovery, and status tracking service  
**Status**: Design specification (ready for implementation)  
**Integration**: Part of POC Phase (Weeks 3-4)

---

## Overview

The **TrustNet Registry Service** is a centralized service that:
1. **Registers nodes** when they join the network
2. **Tracks status** (active, inactive, banned)
3. **Enables discovery** (nodes find each other through registry)
4. **Maintains reputation** (reputation scores stored here)
5. **Provides heartbeats** (detects when nodes go offline)

**Why needed**:
- Nodes need to find each other (peer discovery)
- Network needs to know which nodes are healthy (status tracking)
- Foundation for reputation system (banned nodes)
- Stepping stone to blockchain (later migrate registry on-chain)

---

## Architecture

### High-Level Design

```
┌───────────────────────────────────────────────────────┐
│          TrustNet Registry Service                    │
│          (Your laptop, Port 8000)                     │
│                                                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │  REST API Layer                                 │ │
│  │  POST /api/nodes/register                       │ │
│  │  GET  /api/nodes/active                         │ │
│  │  GET  /api/nodes/{nodeId}                       │ │
│  │  PUT  /api/nodes/heartbeat/{nodeId}             │ │
│  │  PUT  /api/nodes/{nodeId}/status                │ │
│  │  GET  /api/nodes/{nodeId}/peers                 │ │
│  └─────────────────────────────────────────────────┘ │
│                          ▲                            │
│  ┌─────────────────────────────────────────────────┐ │
│  │  Business Logic Layer                           │ │
│  │  - Node Registration                            │ │
│  │  - Peer Discovery                               │ │
│  │  - Status Management                            │ │
│  │  - Heartbeat Tracking                           │ │
│  │  - Reputation Calculation                       │ │
│  └─────────────────────────────────────────────────┘ │
│                          ▲                            │
│  ┌─────────────────────────────────────────────────┐ │
│  │  Data Layer                                     │ │
│  │  SQLite Database                                │ │
│  │  - nodes table                                  │ │
│  │  - heartbeats table                             │ │
│  │  - reputation table                             │ │
│  └─────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────┘
       ▲              ▲              ▲
       │              │              │
    Node-1         Node-2         Node-3
  (register)     (discover)      (heartbeat)
```

---

## Data Model

### Table 1: Nodes

```sql
CREATE TABLE nodes (
  id INTEGER PRIMARY KEY,
  nodeId VARCHAR(255) UNIQUE NOT NULL,      -- "0xa3f2b9c1..."
  owner VARCHAR(255) NOT NULL,               -- "alice"
  status VARCHAR(50) NOT NULL,               -- "ACTIVE", "INACTIVE", "BANNED"
  reputation INT DEFAULT 50,                 -- 0-100 score
  address VARCHAR(255) NOT NULL,             -- "your-laptop.local:9090"
  joinedAt TIMESTAMP DEFAULT NOW(),
  lastHeartbeat TIMESTAMP,
  uptime FLOAT DEFAULT 0.0,                  -- 0-100%
  transactionsValidated INT DEFAULT 0,
  createdAt TIMESTAMP DEFAULT NOW(),
  updatedAt TIMESTAMP DEFAULT NOW()
);

Example:
  nodeId: "0xa3f2b9c1d4e6f8h2j9k0l1m2n3o4p5q6"
  owner: "alice"
  status: "ACTIVE"
  reputation: 85
  address: "your-laptop.local:9090"
  lastHeartbeat: 2026-01-28 14:35:22
  uptime: 99.8
```

### Table 2: Heartbeats

```sql
CREATE TABLE heartbeats (
  id INTEGER PRIMARY KEY,
  nodeId VARCHAR(255) NOT NULL,
  status VARCHAR(50),                        -- "ALIVE", "SLOW", "DEAD"
  responseTime INT,                          -- milliseconds
  receivedAt TIMESTAMP DEFAULT NOW(),
  
  FOREIGN KEY (nodeId) REFERENCES nodes(nodeId)
);

Purpose: Track node responsiveness
Example:
  nodeId: "0xa3f2b9c1..."
  status: "ALIVE"
  responseTime: 45 (ms)
  receivedAt: 2026-01-28 14:35:22
```

### Table 3: Reputation Changes

```sql
CREATE TABLE reputation_changes (
  id INTEGER PRIMARY KEY,
  nodeId VARCHAR(255) NOT NULL,
  changeAmount INT,                          -- +5, -10, etc
  reason VARCHAR(255),                       -- "good_uptime", "misbehavior", etc
  changedBy VARCHAR(255),                    -- Which system/node caused change
  timestamp TIMESTAMP DEFAULT NOW(),
  
  FOREIGN KEY (nodeId) REFERENCES nodes(nodeId)
);

Purpose: Audit trail of reputation changes
Example:
  nodeId: "0xa3f2b9c1..."
  changeAmount: +1
  reason: "24h_uptime_bonus"
  changedBy: "reputation_system"
  timestamp: 2026-01-28 14:35:22
```

---

## REST API Specification

### Endpoint 1: Register Node

```http
POST /api/nodes/register
Content-Type: application/json

Request:
{
  "nodeId": "0xa3f2b9c1d4e6f8h2j9k0l1m2n3o4p5q6",
  "owner": "alice",
  "address": "your-laptop.local:9090"
}

Response (201 Created):
{
  "registered": true,
  "nodeId": "0xa3f2b9c1...",
  "status": "ACTIVE",
  "reputation": 50,
  "knownPeers": [
    { "nodeId": "0xb4g3c2d9...", "address": "cloud-instance.aws:9090" },
    { "nodeId": "0xc5h4d3e8...", "address": "friend-computer.local:9090" }
  ]
}

Error Cases:
  400 Bad Request: Missing required fields
  409 Conflict: NodeId already registered
  500 Server Error: Database error
```

### Endpoint 2: Get All Active Nodes

```http
GET /api/nodes/active

Response (200 OK):
{
  "total": 3,
  "nodes": [
    {
      "nodeId": "0xa3f2b9c1...",
      "owner": "alice",
      "address": "your-laptop.local:9090",
      "status": "ACTIVE",
      "reputation": 85,
      "uptime": 99.8,
      "lastHeartbeat": "2026-01-28T14:35:22Z"
    },
    {
      "nodeId": "0xb4g3c2d9...",
      "owner": "bob",
      "address": "cloud-instance.aws:9090",
      "status": "ACTIVE",
      "reputation": 78,
      "uptime": 98.2,
      "lastHeartbeat": "2026-01-28T14:35:19Z"
    },
    {
      "nodeId": "0xc5h4d3e8...",
      "owner": "charlie",
      "address": "friend-computer.local:9090",
      "status": "INACTIVE",
      "reputation": 65,
      "uptime": 45.3,
      "lastHeartbeat": "2026-01-26T08:12:00Z"
    }
  ]
}
```

### Endpoint 3: Get Recommended Peers

```http
GET /api/nodes/{nodeId}/peers?count=5

Parameters:
  nodeId: Node requesting peers
  count: How many peers to return (default 5)

Response (200 OK):
{
  "nodeId": "0xa3f2b9c1...",
  "peers": [
    { "nodeId": "0xb4g3c2d9...", "address": "cloud-instance.aws:9090" },
    { "nodeId": "0xc5h4d3e8...", "address": "friend-computer.local:9090" }
  ]
}

Logic:
  - Return list of ACTIVE nodes only
  - Exclude requesting node (don't connect to yourself)
  - Prefer high-reputation nodes
  - Randomize to avoid thundering herd (all nodes trying to connect to same peer)
```

### Endpoint 4: Send Heartbeat

```http
PUT /api/nodes/heartbeat/{nodeId}
Content-Type: application/json

Request:
{
  "status": "ALIVE",
  "latestBlockHeight": 1234,
  "peersConnected": 2,
  "signature": "..."  // Cryptographic proof
}

Response (200 OK):
{
  "received": true,
  "nextHeartbeatExpected": "2026-01-28T14:36:22Z"
}

Error Cases:
  404 Not Found: NodeId not registered
  400 Bad Request: Invalid signature
```

### Endpoint 5: Get Node Status

```http
GET /api/nodes/{nodeId}

Response (200 OK):
{
  "nodeId": "0xa3f2b9c1...",
  "owner": "alice",
  "address": "your-laptop.local:9090",
  "status": "ACTIVE",
  "reputation": 85,
  "uptime": 99.8,
  "transactionsValidated": 1234,
  "joinedAt": "2026-01-20T10:00:00Z",
  "lastHeartbeat": "2026-01-28T14:35:22Z",
  "reputationHistory": [
    { "change": +1, "reason": "24h_uptime_bonus", "timestamp": "2026-01-28T14:00:00Z" },
    { "change": +5, "reason": "1000_transactions", "timestamp": "2026-01-27T18:30:00Z" }
  ]
}
```

### Endpoint 6: Update Node Status

```http
PUT /api/nodes/{nodeId}/status
Content-Type: application/json

Request:
{
  "status": "INACTIVE"  // or "ACTIVE", "BANNED"
}

Response (200 OK):
{
  "nodeId": "0xa3f2b9c1...",
  "status": "INACTIVE",
  "message": "Status updated"
}

Permissions:
  - Node can update own status
  - Registry admin can ban/reactivate (later: DAO vote)
```

---

## Node Integration (How Nodes Use Registry)

### Node Startup Flow

```go
// node.go
func (n *Node) Start(registryAddr string) error {
  // Step 1: Register with registry
  resp, err := n.registerWithRegistry(registryAddr)
  if err != nil {
    return fmt.Errorf("failed to register: %v", err)
  }
  
  // Step 2: Get list of known peers
  knownPeers := resp.KnownPeers
  log.Printf("Registry says I know about %d peers", len(knownPeers))
  
  // Step 3: Connect to peers
  for _, peer := range knownPeers {
    go n.connectToPeer(peer)
  }
  
  // Step 4: Start heartbeat ticker
  n.startHeartbeatTicker(registryAddr, 30*time.Second)
  
  // Step 5: Start consensus engine
  return n.startConsensus()
}

func (n *Node) registerWithRegistry(registryAddr string) (*RegistryResponse, error) {
  payload := map[string]string{
    "nodeId": n.ID,
    "owner": n.Owner,
    "address": n.Address,
  }
  
  resp, err := http.PostJSON(registryAddr + "/api/nodes/register", payload)
  return resp.(*RegistryResponse), err
}

func (n *Node) startHeartbeatTicker(registryAddr string, interval time.Duration) {
  ticker := time.NewTicker(interval)
  defer ticker.Stop()
  
  for range ticker.C {
    payload := map[string]interface{}{
      "status": "ALIVE",
      "latestBlockHeight": n.Ledger.Height(),
      "peersConnected": len(n.Peers),
    }
    
    http.PutJSON(registryAddr + "/api/nodes/heartbeat/" + n.ID, payload)
  }
}
```

### Node Discovery Flow

```go
// discovery.go
func (n *Node) discoverPeers(registryAddr string) error {
  // Query registry for active nodes
  resp, err := http.Get(registryAddr + "/api/nodes/active")
  if err != nil {
    return err
  }
  
  peers := resp.Nodes
  log.Printf("Registry knows about %d active nodes", len(peers))
  
  // Connect to random subset
  maxConnections := 10
  selected := randomSubset(peers, maxConnections)
  
  for _, peer := range selected {
    go n.connectToPeer(peer)
  }
  
  return nil
}
```

---

## Reputation System Integration

### Automatic Reputation Changes

**Positive Changes**:
```
Every 24h of uptime: +1 reputation
Per 1000 transactions validated: +0.1 reputation
Per peer positive review: +5 reputation (max 2x per day)
Node reaches 30 days uptime: +10 reputation bonus

Max gain per day: +5 reputation
```

**Negative Changes**:
```
Every 24h of downtime: -1 reputation
Invalid transaction: -10 reputation
Peer reports misbehavior: -5 reputation (max 3x per day)
Attempt double-voting: -50 reputation (immediate ban)

Max loss per day: -15 reputation
```

**Automatic Banning**:
```
When reputation < 10:
  - Node status automatically set to BANNED
  - Node receives list of BANNED nodes, removes from peers
  - New nodes won't connect to BANNED nodes
  - Operator must create new nodeId to rejoin
```

### Reputation Calculation Logic

```python
def update_reputation(node_id, registry):
    node = registry.get_node(node_id)
    
    # Check uptime
    if node.last_heartbeat > 24h ago:
        change = -1  # 24h downtime penalty
    else:
        change = +1  # 24h uptime bonus
    
    # Check transaction count
    new_txns = node.transactions_since_last_check
    if new_txns >= 1000:
        change += (new_txns / 1000) * 0.1
    
    # Check peer reviews
    peer_reviews = registry.get_peer_reviews(node_id)
    avg_review = sum(reviews) / len(reviews)  # 1-5 stars
    if avg_review >= 4:
        change += 5
    elif avg_review < 2:
        change -= 5
    
    # Apply change
    new_reputation = clamp(node.reputation + change, 0, 100)
    registry.update_reputation(node_id, new_reputation, reason)
    
    # Check ban threshold
    if new_reputation < 10:
        registry.ban_node(node_id)
    
    return new_reputation
```

---

## Implementation Phases

### Phase 1: Basic Registry (Weeks 3-4)

**Deliverables**:
- REST API (all 6 endpoints)
- SQLite database (nodes table)
- Node registration
- Peer discovery
- Basic heartbeat tracking

**Code Structure**:
```
trustnet-registry/
├── main.go
├── api.go              # REST endpoints
├── db.go               # Database operations
├── models.go           # Data structures
├── reputation.go       # Reputation logic
└── config.yaml         # Configuration
```

**Testing**:
```bash
# Test registration
curl -X POST http://localhost:8000/api/nodes/register \
  -d '{"nodeId":"0xa3f2b9c1...","owner":"alice","address":"localhost:9090"}'

# Test peer discovery
curl http://localhost:8000/api/nodes/active

# Test heartbeat
curl -X PUT http://localhost:8000/api/nodes/0xa3f2b9c1.../heartbeat
```

### Phase 2: Enhanced Features (Weeks 5-6)

**Additions**:
- Reputation calculation
- Automatic banning
- Uptime tracking
- Audit trail (reputation_changes table)
- Admin dashboard (view all nodes, reputation, status)

### Phase 3: Blockchain Migration (Later)

**Future upgrade**:
- Move registry to Ethereum/Polygon smart contract
- Immutable node history
- Decentralized governance (DAO votes on bans)
- But keep same REST API interface (backward compatible)

---

## Configuration

### Registry Service Config

```yaml
# registry-config.yaml
server:
  port: 8000
  host: 0.0.0.0

database:
  type: sqlite
  path: ./data/registry.db

heartbeat:
  timeout: 120  # seconds (node considered offline after 2 min of no heartbeat)
  interval: 30  # seconds (nodes send heartbeat every 30s)
  check_interval: 60  # seconds (registry checks for dead nodes every 60s)

reputation:
  initial: 50  # New nodes start at 50/100
  uptime_bonus: 1  # Per 24h
  transaction_bonus: 0.1  # Per 1000 txns
  peer_review_bonus: 5  # Per positive review
  downtime_penalty: 1  # Per 24h offline
  ban_threshold: 10  # Ban when reputation drops below this

security:
  requireSignature: true  # Verify node signatures on heartbeat
  allowUnregistered: false  # Reject unknown nodes
```

### Node Config

```yaml
# node-config.yaml
node:
  id: node-1  # Unique identifier
  owner: alice  # Human-readable owner
  listenPort: 9090

registry:
  address: your-laptop.local:8000  # Registry service address
  heartbeatInterval: 30  # seconds
  peerCount: 5  # How many peers to maintain

consensus:
  algorithm: tendermint
  blockTimeout: 1000  # milliseconds
  commitTimeout: 1000
```

---

## Security Considerations

1. **Signature Verification**
   - Nodes sign heartbeats with their private key
   - Registry verifies signature before accepting heartbeat
   - Prevents impersonation

2. **Rate Limiting**
   - Registry limits registration to 1 per IP per 10 minutes
   - Prevents registration spam

3. **Access Control**
   - Status updates can only be made by node itself or admin
   - Ban/unban only by admin (later: DAO)

4. **HTTPS for Production**
   - For POC: HTTP is fine (local network)
   - For production: Use HTTPS with certificates
   - Encrypt heartbeat data

---

## Transition to Blockchain

Once registry is working, upgrading to blockchain is straightforward:

```
Current (Centralized Registry):
  Node → HTTP → Registry Service → SQLite

Future (Blockchain Registry):
  Node → Smart Contract → Ethereum/Polygon → Immutable Ledger
  
Same node logic, different backend!
```

---

## Summary

**Registry Service**:
- Solves peer discovery (nodes find each other)
- Solves status tracking (active/inactive/banned)
- Simple to implement (one REST API + SQLite)
- Foundation for reputation system
- Easy to upgrade to blockchain later

**Timeline Impact**: +1-2 weeks (adds Weeks 3-4)  
**Complexity**: Medium (not simple, not hard)  
**Value**: Critical (enables distribution)

---

**Document prepared**: January 28, 2026  
**Status**: Specification complete, ready for implementation  
**Next**: Update POC_DISTRIBUTED_NODE_NETWORK.md to include registry service details
