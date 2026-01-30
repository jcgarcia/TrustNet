# TrustNet Installation & Deployment Architecture

**Purpose**: Complete specification for automated installation script and deployment patterns  
**Status**: ✅ Complete (Jan 29, 2026)  
**Audience**: DevOps engineers, system architects, implementation team  
**Timeline**: Implementation for Weeks 1-2 and Phase 1+

---

## Overview: Automated Installation Philosophy

**Core Principle**: **Questions at the start, automation throughout**

All configuration decisions made via CLI parameters or initial prompts. Once installation begins, **zero user intervention** until completion.

**Installation Phases**:
1. **Pre-flight (interactive)**: Gather parameters, show DNS instructions, wait for confirmation
2. **Execution (automated)**: IPv6 setup, registry start, node creation, registration
3. **Post-flight (automated)**: Service verification, peer discovery

---

## Part 1: Installation Parameters

### CLI Parameters (All at startup)

```bash
trustnet install \
  --domain=bucoto.com \
  --registry-type=integrated|independent|root \
  --node-name=node-1 \
  --ipv6-auto-enable=true|false \
  --deployment=vm|kubernetes \
  --registry-vm-ip=<IPv6> \        # Optional: if independent, where to run it
  --root-registry-ip=<IPv6> \      # Optional: for secondary registries
  --dns-provider=route53|manual    # Default: manual (user updates DNS)
  --aws-profile=default            # Optional: for Route53 automation
  --verbose=true|false
```

### Interactive Phase (Before automated execution)

```
=== TrustNet Installation Wizard ===

Domain name: bucoto.com
Registry type: independent
Node name: node-1
Deployment: kubernetes
IPv6 auto-enable: true

[Checking IPv6...]
✓ IPv6 available on eth0: 2001:db8::1/64

[Generating DNS record requirement...]
```

---

## Part 2: IPv6 Validation & Auto-Enable

### Step 1: Check IPv6 Status

```bash
# Script checks:
1. IPv6 kernel module loaded: ip6_modules
2. IPv6 address assigned to interface
3. IPv6 connectivity to gateway
4. IPv6 DNS resolution (/etc/resolv.conf has IPv6 nameservers)
```

### Step 2: Show IPv6 Info to User

```
═════════════════════════════════════════════════════════════
[SYSTEM INFORMATION]
═════════════════════════════════════════════════════════════

IPv6 Status: ✓ ENABLED
├─ Interface: eth0
├─ IPv6 Address: 2001:db8::1/64
├─ Gateway: fe80::1
└─ DNS: 2001:4860:4860::8888 (Google DNS)

Operating System: Ubuntu 22.04
Deployment Target: Kubernetes
Container Runtime: Docker

═════════════════════════════════════════════════════════════
[DNS RECORD REQUIRED]
═════════════════════════════════════════════════════════════

For domain: bucoto.com
Create DNS record:

  Name: tnr
  Type: AAAA (IPv6)
  Value: 2001:db8::1
  TTL: 300

Provider: route53
Record Name: tnr.bucoto.com

How to add this record:
1. Go to AWS Route53 console
2. Find hosted zone: bucoto.com
3. Create new AAAA record
   Name: tnr
   Value: 2001:db8::1
   Type: AAAA
4. Save and wait 1-2 minutes for DNS propagation

═════════════════════════════════════════════════════════════
[NEXT STEPS]
═════════════════════════════════════════════════════════════

1. Add DNS record (see above)
2. Verify DNS: dig +short tnr.bucoto.com AAAA
3. Continue installation when ready

Press Enter to continue (after DNS is updated)...
```

### Step 3: If IPv6 Missing (Auto-Enable)

```bash
# If IPv6 not available and --ipv6-auto-enable=true:

# Ubuntu/Debian
echo "net.ipv6.conf.all.disable_ipv6 = 0" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Enable DHCPv6
sudo apt-get install -y dibbler-client

# Re-detect IPv6 address (retry 5 times, wait 10s between)
```

---

## Part 3: DNS Record Requirements

### DNS Record Format (Provider-Agnostic)

**What the user needs to create**:

```
Record Name:    tnr
Domain:         bucoto.com
Full FQDN:      tnr.bucoto.com
Record Type:    AAAA (IPv6 only)
TTL:            300 seconds
Values:         2001:db8::1 (root registry)
                2001:db8::2 (secondary-1, if exists)
                2001:db8::3 (secondary-2, if exists)
```

### Provider-Specific Instructions

**Route53 (AWS)**:
```
1. AWS Console → Route53
2. Find hosted zone: bucoto.com
3. Click "Create record"
4. Record name: tnr
5. Record type: AAAA - IPv6 address
6. Value: 2001:db8::1
7. TTL: 300
8. Create records
```

**Cloudflare**:
```
1. Cloudflare Dashboard → DNS
2. Click "Add record"
3. Type: AAAA
4. Name: tnr
5. IPv6 address: 2001:db8::1
6. TTL: Auto
7. Save
```

**Manual (any provider)**:
```
Contact your DNS provider and request:
- Record: tnr.bucoto.com
- Type: AAAA (IPv6)
- Value: 2001:db8::1
```

### DNS Verification Script

```bash
# User can verify DNS is working:
dig +short tnr.bucoto.com AAAA

# Expected output:
# 2001:db8::1
```

---

## Part 4: Registry Type Selection

### Registry Types & Purposes

```
┌─────────────────────────────────────────────────────┐
│           Registry Type Selection                    │
└─────────────────────────────────────────────────────┘

1. ROOT REGISTRY (First time only)
   ├─ Purpose: Authority for node list
   ├─ Location: Independent VM or Kubernetes pod
   ├─ Deployment: Standalone (no node attached)
   ├─ DNS: Advertised as tnr.{domain}
   ├─ Sync: None (it's the source of truth)
   └─ Use case: "I'm setting up the network"
   
2. INDEPENDENT SECONDARY REGISTRY
   ├─ Purpose: Redundancy + node list backup
   ├─ Location: Independent VM or Kubernetes pod
   ├─ Deployment: Standalone (no node attached)
   ├─ DNS: Advertised as tnr.{domain}
   ├─ Sync: Syncs from root via DNS lookup
   └─ Use case: "I want to run a public registry for the network"
   
3. INTEGRATED REGISTRY (Default)
   ├─ Purpose: Private node registry
   ├─ Location: Same VM or pod as node
   ├─ Deployment: Integrated process (node + registry)
   ├─ DNS: Not advertised (private)
   ├─ Sync: Syncs node list from root via DNS lookup
   └─ Use case: "I'm just running a node" (most common)
```

### User Selection Flow

```bash
trustnet install --domain=bucoto.com

=== Registry Type ===

What would you like to run?

1. Root Registry (first time only)
   ├─ Independent VM/pod
   ├─ No node attached
   └─ For: Setting up the network

2. Standalone Secondary Registry
   ├─ Independent VM/pod
   ├─ No node attached
   ├─ Syncs from root
   └─ For: Network redundancy

3. Node with Integrated Registry (recommended)
   ├─ Integrated with node process
   ├─ Private (not advertised)
   ├─ Syncs node list from root
   └─ For: Most users

Select [1/2/3, default 3]: 3
```

---

## Part 5: Automated Installation Flow

### Complete Execution Timeline

```
START: trustnet install --domain=bucoto.com --registry-type=integrated --node-name=node-1

┌─────────────────────────────────────────────────────────┐
│ PHASE 1: PRE-FLIGHT (Interactive, 2-5 minutes)          │
└─────────────────────────────────────────────────────────┘

[1/6] IPv6 Check
  ✓ IPv6 enabled
  ✓ Local IPv6: 2001:db8::100/64
  
[2/6] DNS Record Instructions
  ✓ Showing DNS record to create
  ✓ Provider-specific instructions
  
[3/6] Wait for DNS Confirmation
  Prompt: "Add the DNS record, then press Enter to continue"
  User adds tnr.bucoto.com AAAA 2001:db8::1 to their DNS
  User presses Enter
  
[4/6] Verify DNS Propagation
  Script runs: dig +short tnr.bucoto.com AAAA
  ✓ DNS resolves to 2001:db8::1
  
[5/6] Show Configuration Summary
  Domain: bucoto.com
  Registry Type: Integrated
  Node Name: node-1
  Local IPv6: 2001:db8::100
  Root Registry IPv6: 2001:db8::1 (from DNS)
  Deployment: VM
  
[6/6] Confirm & Proceed
  Prompt: "Ready to install? (yes/no)"
  User types: yes
  
╔═════════════════════════════════════════════════════════╗
│ PROCEEDING TO AUTOMATED INSTALLATION                    │
│ (No more user interaction required)                      │
╚═════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────┐
│ PHASE 2: EXECUTION (Fully Automated)                    │
└─────────────────────────────────────────────────────────┘

[1/7] Install Dependencies
  ✓ docker
  ✓ golang
  ✓ trustnet-cli
  
[2/7] Create Registry Configuration
  ✓ registry-config.yml generated
  ├─ role: secondary
  ├─ root_registry: 2001:db8::1:8000
  ├─ sync_interval: 60
  └─ database: /data/registry.db
  
[3/7] Pull Container Image
  ✓ trustnet:v0.1.0-registry
  
[4/7] Start Registry Service
  ✓ Registry listening on [2001:db8::100]:8000
  ✓ Database initialized: /data/registry.db
  
[5/7] Create Node Configuration
  ✓ node-config.yml generated
  ├─ node_name: node-1
  ├─ registry: 127.0.0.1:8000 (local integrated registry)
  ├─ domain: bucoto.com
  └─ public_ipv6: 2001:db8::100
  
[6/7] Start Node Service
  ✓ Node started (PID: 12345)
  ✓ Registering with local registry...
  ✓ Node registered (nodeId: 0x7f...)
  ✓ Discovering peers from registry...
  ✓ Found 0 peers (first node in network)
  
[7/7] System Verification
  ✓ Registry health: OK (response time: 12ms)
  ✓ Node health: OK (heartbeat interval: 30s)
  ✓ IPv6 connectivity: OK
  ✓ DNS resolution: OK

┌─────────────────────────────────────────────────────────┐
│ INSTALLATION COMPLETE ✓                                 │
└─────────────────────────────────────────────────────────┘

Node: node-1
├─ Status: ACTIVE
├─ NodeID: 0x7f8a9b1c2d3e4f5a
├─ Registry: 127.0.0.1:8000 (integrated)
├─ Domain: bucoto.com
├─ IPv6: 2001:db8::100
└─ Peers: 0 (will increase as more nodes join)

Registry (Integrated):
├─ Status: ACTIVE
├─ Type: Secondary (syncs from root)
├─ Address: [2001:db8::100]:8000
├─ Root Registry: [2001:db8::1]:8000
├─ Nodes tracked: 1 (node-1)
└─ Sync status: Connected to root

Next steps:
1. Install another node: trustnet install --domain=bucoto.com --node-name=node-2
2. View node status: trustnet status node-1
3. View registry status: trustnet registry status
4. View peers: trustnet peers node-1
```

---

## Part 6: Registry Startup Sequence

### Root Registry (First Install)

```go
// root-registry-startup.go

func (r *RootRegistry) Start(config RootRegistryConfig) error {
  log.Info("Starting Root Registry")
  
  // 1. Load configuration
  r.Config = config
  r.IPv6Address = config.IPv6  // e.g., 2001:db8::1
  r.Port = 8000
  
  // 2. Initialize database
  err := r.InitializeDatabase("registry.db")
  if err != nil {
    return fmt.Errorf("database init failed: %w", err)
  }
  log.Info("Database ready")
  
  // 3. Create advertised secondaries list (initially empty)
  r.Secondaries = []string{}
  // Will be populated when other secondaries register
  
  // 4. Start HTTP server
  r.server = &http.Server{
    Addr:    fmt.Sprintf("[%s]:%d", r.IPv6Address, r.Port),
    Handler: r.Router(),
  }
  
  go func() {
    log.Infof("Root Registry listening on [%s]:%d", r.IPv6Address, r.Port)
    if err := r.server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
      log.Errorf("Server error: %v", err)
    }
  }()
  
  // 5. Start heartbeat monitor
  go r.MonitorHeartbeats()
  
  // 6. Ready
  log.Info("✓ Root Registry ready")
  return nil
}
```

### Secondary Registry (Integrated or Independent)

```go
// secondary-registry-startup.go

func (r *SecondaryRegistry) Start(config SecondaryRegistryConfig) error {
  log.Info("Starting Secondary Registry")
  
  // 1. Load configuration
  r.Config = config
  r.IPv6Address = config.IPv6              // e.g., 2001:db8::100
  r.RootRegistryAddr = config.RootRegistry // e.g., 2001:db8::1:8000
  r.Port = 8000
  
  // 2. Initialize database (replica)
  err := r.InitializeDatabase("registry-replica.db")
  if err != nil {
    return fmt.Errorf("database init failed: %w", err)
  }
  log.Info("Replica database ready")
  
  // 3. Do initial sync from root
  log.Info("Syncing from root registry...")
  snapshot, err := r.FetchInitialSnapshot(r.RootRegistryAddr)
  if err != nil {
    log.Warnf("Initial sync failed (root may not be ready): %v", err)
    log.Info("Continuing without initial snapshot (will sync on first heartbeat)")
  } else {
    log.Infof("Loaded %d nodes from root", len(snapshot.Nodes))
    r.ApplySnapshot(snapshot)
  }
  
  // 4. Start HTTP server
  r.server = &http.Server{
    Addr:    fmt.Sprintf("[%s]:%d", r.IPv6Address, r.Port),
    Handler: r.Router(),
  }
  
  go func() {
    log.Infof("Secondary Registry listening on [%s]:%d", r.IPv6Address, r.Port)
    if err := r.server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
      log.Errorf("Server error: %v", err)
    }
  }()
  
  // 5. Start replication loop (sync from root every 60 seconds)
  go r.ReplicationLoop()
  
  // 6. Ready
  log.Info("✓ Secondary Registry ready (syncing from root)")
  return nil
}

// Replication loop (every 60 seconds)
func (r *SecondaryRegistry) ReplicationLoop() {
  ticker := time.NewTicker(60 * time.Second)
  defer ticker.Stop()
  
  for range ticker.C {
    delta, err := r.FetchDelta(r.RootRegistryAddr)
    if err != nil {
      log.Warnf("Sync failed: %v (will retry in 60s)", err)
      continue
    }
    
    log.Debugf("Received delta: %d changes", len(delta.Changes))
    r.ApplyDelta(delta)
    log.Debugf("✓ Synced to version %d", delta.ToVersion)
  }
}
```

---

## Part 7: Node Creation & Registry Assignment

### Node Startup with Integrated Registry

```go
// node-startup.go

func (n *Node) Start(config NodeConfig) error {
  log.Info("Starting TrustNet Node")
  
  // 1. Load configuration
  n.NodeName = config.NodeName          // e.g., "node-1"
  n.NodeID = GenerateNodeID()           // e.g., 0x7f...
  n.PublicIPv6 = config.PublicIPv6      // e.g., 2001:db8::100
  n.Domain = config.Domain              // e.g., "bucoto.com"
  
  // 2. If using integrated registry, start it first
  if config.RegistryType == "integrated" {
    log.Info("Starting integrated registry...")
    
    // Fetch root registry address from DNS
    rootAddrs, err := n.LookupTrustNetRegistry(n.Domain)
    if err != nil {
      log.Errorf("Failed to lookup root registry: %v", err)
      return err
    }
    
    registryConfig := SecondaryRegistryConfig{
      IPv6:          n.PublicIPv6,
      Port:          8000,
      RootRegistry:  rootAddrs[0], // Use first (primary) root
      SyncInterval:  60,
    }
    
    n.Registry = &SecondaryRegistry{}
    err = n.Registry.Start(registryConfig)
    if err != nil {
      return fmt.Errorf("registry startup failed: %w", err)
    }
    
    // Registry is now running locally at localhost:8000
    n.RegistryAddr = "127.0.0.1:8000" // Local reference
  } else {
    // External registry provided in config
    n.RegistryAddr = config.ExternalRegistry
  }
  
  // 3. Register with registry
  log.Info("Registering node with registry...")
  err := n.RegisterWithRegistry(n.RegistryAddr)
  if err != nil {
    log.Errorf("Registration failed: %v", err)
    return err
  }
  log.Infof("✓ Node registered: %s (%s)", n.NodeName, n.NodeID)
  
  // 4. Discover peers
  peers, err := n.DiscoverPeers(n.RegistryAddr)
  if err != nil {
    log.Warnf("Peer discovery failed: %v", err)
    // Not fatal - will discover via gossip protocol later
  } else {
    log.Infof("Discovered %d peers", len(peers))
  }
  
  // 5. Start node services
  n.StartConsensusEngine()
  n.StartTransactionPool()
  n.StartGossipProtocol()
  
  // 6. Start heartbeat loop (every 30 seconds)
  go n.HeartbeatLoop(n.RegistryAddr)
  
  // 7. Ready
  log.Info("✓ Node ready and operational")
  return nil
}

// Registry lookup via DNS
func (n *Node) LookupTrustNetRegistry(domain string) ([]string, error) {
  // Lookup tnr.{domain} AAAA records
  fqdn := fmt.Sprintf("tnr.%s", domain)
  
  addrs, err := net.LookupHost(fqdn)
  if err != nil {
    return nil, fmt.Errorf("DNS lookup failed for %s: %w", fqdn, err)
  }
  
  // Filter IPv6 addresses and add port
  var registries []string
  for _, addr := range addrs {
    registries = append(registries, fmt.Sprintf("[%s]:8000", addr))
  }
  
  return registries, nil
}
```

### Registry Storage of Node Information

```
Registry Database Schema:

nodes table:
├─ node_id (PK): 0x7f8a9b1c2d3e4f5a
├─ node_name: "node-1"
├─ status: "ACTIVE"
├─ ipv6_address: 2001:db8::100
├─ domain: "bucoto.com"
├─ registry_address: [2001:db8::100]:8000  ← Node's nearest registry (integrated)
├─ reputation: 50
├─ uptime_pct: 98.5
├─ first_seen: 2026-01-29T10:00:00Z
├─ last_heartbeat: 2026-01-29T10:15:23Z
└─ peer_information_source: "registry"     ← How node discovers peers

Registry stores each node's "nearest registry" so:
- Nodes can advertise it to peers
- Other nodes can learn about registries through peers
- All nodes sync from root via DNS (not via other nodes)
```

---

## Part 8: Service Discovery for Nodes

### Node Finding Registries (Two Paths)

```
PATH 1: Direct Registry Lookup (Integrated Registry)
┌──────────┐
│  Node    │
└────┬─────┘
     │ "I need a registry"
     │
     ├─→ Check: Do I have an integrated registry?
     │   YES → Use 127.0.0.1:8000 (local)
     │   NO  → Go to PATH 2
     │
     └─→ Ready to register


PATH 2: DNS Lookup (First time or no integrated registry)
┌──────────┐
│  Node    │
└────┬─────┘
     │ "I need a registry, let me check DNS"
     │
     ├─→ DNS Lookup: tnr.{domain}
     │   Response: [2001:db8::1, 2001:db8::2, 2001:db8::3]
     │
     ├─→ Try first: [2001:db8::1]:8000
     │   Success? Register
     │   Timeout? Try next
     │
     └─→ Once registered, store registry address
        (can share with peers via gossip)
```

### Nodes Never Query DNS for Other Nodes

```
What nodes DON'T do:
  ❌ Look up: node-1.bucoto.com
  ❌ Query: query.bucoto.com
  ❌ Ask DNS for peer list

What nodes DO do:
  ✓ Query registry: "Give me list of nodes"
  ✓ Share registry address with peers
  ✓ Peer-to-peer communication: Direct IPv6
  ✓ Only use DNS for: tnr.{domain} (registries only)
```

### Node Registration Request

```
Node → Registry:

POST [registry]:8000/api/register
{
  "node_name": "node-1",
  "ipv6_address": "2001:db8::100",
  "domain": "bucoto.com",
  "registry_address": "2001:db8::100:8000",  ← My nearest registry
  "port": 9000                                ← Port I'm listening on
}

Registry → Node:

{
  "status": "success",
  "node_id": "0x7f8a9b1c2d3e4f5a",
  "peers": [
    {
      "node_id": "0x2a3b4c5d6e7f8a9b",
      "node_name": "node-2",
      "ipv6_address": "2001:db8::101",
      "port": 9000,
      "registry_address": "[2001:db8::100]:8000"  ← Its nearest registry
    }
  ],
  "heartbeat_interval": 30
}
```

---

## Part 9: Multi-Registry Network (Phase 1+)

### Adding Secondary Registries to DNS

Once network is stable (POC complete), add independent secondary registries:

```
Initial (Root only):
  tnr.bucoto.com AAAA 2001:db8::1

Phase 1+ (Add secondaries):
  tnr.bucoto.com AAAA 2001:db8::1    (root)
  tnr.bucoto.com AAAA 2001:db8::2    (secondary-1)
  tnr.bucoto.com AAAA 2001:db8::3    (secondary-2)

All three registries:
  - Sync from root (root is authority)
  - Serve peer discovery queries
  - Only root accepts writes (maintain consistency)
  - Secondaries queue writes if root is down

Installation for new secondary:

  trustnet install \
    --domain=bucoto.com \
    --registry-type=independent \
    --root-registry=2001:db8::1

  Script will:
  1. Check DNS for tnr.bucoto.com
  2. Find root at 2001:db8::1
  3. Contact root for initial sync
  4. Start secondary registry
  5. Begin replication loop (60s interval)
```

---

## Part 10: Configuration Files

### Generated Configuration Files

#### root-registry-config.yml

```yaml
# Generated during: trustnet install --registry-type=root

registry:
  role: "root"
  ipv6_address: "2001:db8::1"
  port: 8000
  
database:
  type: "sqlite"
  path: "/data/registry.db"
  max_connections: 20

replication:
  # Root doesn't sync from anywhere
  enabled: false

heartbeat:
  interval: 30  # seconds
  timeout: 5
  missing_threshold: 3  # miss 3 = offline

persistence:
  snapshot_interval: 3600  # backup every hour
  snapshot_path: "/data/snapshots"

logging:
  level: "info"
  format: "json"
```

#### secondary-registry-config.yml (Integrated)

```yaml
# Generated during: trustnet install --registry-type=integrated --domain=bucoto.com

registry:
  role: "secondary"
  ipv6_address: "2001:db8::100"
  port: 8000
  
  # Root registry discovered via DNS
  root_registry:
    domain: "bucoto.com"
    lookup_method: "dns"  # Dynamically lookup tnr.{domain}
  
database:
  type: "sqlite"
  path: "/var/lib/trustnet/registry-replica.db"
  max_connections: 10

replication:
  enabled: true
  root_refresh_interval: 60  # seconds
  sync_timeout: 10           # seconds
  max_queued_writes: 1000    # if root down
  backoff:
    initial: 1               # seconds
    max: 60
    multiplier: 2.0

heartbeat:
  interval: 30
  timeout: 5
  missing_threshold: 3

node_sync:
  # This registry tracks nodes from root
  enabled: true
  sync_interval: 60

logging:
  level: "info"
  format: "json"
```

#### secondary-registry-config.yml (Independent)

```yaml
# Generated during: trustnet install --registry-type=independent --domain=bucoto.com --root-registry=[2001:db8::1]:8000

registry:
  role: "secondary"
  ipv6_address: "2001:db8::2"
  port: 8000
  
  # Root registry specified (optional: can also use DNS)
  root_registry:
    address: "[2001:db8::1]:8000"
    domain: "bucoto.com"  # Fallback: lookup tnr.{domain} if primary fails
  
database:
  type: "sqlite"
  path: "/data/registry-replica.db"
  max_connections: 20

replication:
  enabled: true
  root_refresh_interval: 60
  sync_timeout: 10
  max_queued_writes: 5000   # Independent, can queue more
  backoff:
    initial: 1
    max: 60
    multiplier: 2.0

heartbeat:
  interval: 30
  timeout: 5
  missing_threshold: 3

persistence:
  backup_interval: 3600
  backup_path: "/data/backups"

logging:
  level: "info"
  format: "json"
```

#### node-config.yml

```yaml
# Generated during: trustnet install --node-name=node-1 --domain=bucoto.com

node:
  name: "node-1"
  domain: "bucoto.com"
  ipv6_address: "2001:db8::100"
  port: 9000

registry:
  # If integrated, registry is at localhost
  # If external, specify address
  type: "integrated"  # or "external"
  address: "127.0.0.1:8000"
  
  # Fallback: lookup from DNS if local fails
  fallback_domain: "bucoto.com"
  fallback_lookup: "dns"

consensus:
  engine: "tendermint"
  block_time: 1000    # milliseconds
  validators: 1       # Will increase as network grows

transaction_pool:
  max_size: 10000
  timeout: 300        # seconds

gossip:
  enabled: true
  peers_per_batch: 5
  interval: 30        # seconds

heartbeat:
  registry_interval: 30  # seconds
  timeout: 5

logging:
  level: "info"
  format: "json"
```

---

## Part 11: Error Handling & Recovery

### Installation Error Scenarios

```
Scenario 1: IPv6 Not Available
├─ Detection: ip6_modules check fails
├─ Action: If --ipv6-auto-enable=true
│  ├─ Auto-install DHCPv6 client
│  ├─ Retry detection (5 times, 10s apart)
│  └─ If still fails: Exit with instructions
└─ Action: If --ipv6-auto-enable=false
   └─ Exit with manual setup instructions


Scenario 2: DNS Record Not Found
├─ Detection: nslookup tnr.{domain} returns NXDOMAIN
├─ For ROOT registry: Not critical (no DNS needed)
└─ For NODE/SECONDARY: 
   ├─ Show instructions to user
   ├─ Wait for confirmation
   └─ Verify before proceeding


Scenario 3: Root Registry Unreachable
├─ Detection: Connection timeout to [2001:db8::1]:8000
├─ For SECONDARY: 
│  ├─ Start anyway (will sync on retry)
│  ├─ Log warning
│  └─ Retry every 60s
└─ For NODE:
   ├─ If DNS returns multiple registries: Try next
   ├─ If only one: Continue, will register when root comes up
   └─ Log warning and retry


Scenario 4: Integrated Registry Port Conflict
├─ Detection: Port 8000 already in use
├─ Action:
│  ├─ Find next available port (8001, 8002, ...)
│  ├─ Update config
│  ├─ Log warning
│  └─ Continue with different port
└─ Node and registry communicate on same port
```

---

## Part 12: Security & Validation

### Pre-Installation Checks

```bash
# All checks run before any installation:

1. IPv6 Available
   └─ ip -6 addr show | grep inet6

2. Domain Valid
   └─ Check if domain resolves to A or AAAA record

3. Required Ports Available
   ├─ Registry: 8000
   └─ Node: 9000+

4. Disk Space
   └─ Min 1GB free for registry database

5. Memory
   └─ Min 512MB available

6. Network Connectivity
   ├─ IPv6 internet reachable
   └─ DNS resolution working
```

---

## Part 13: Implementation Checklist

### Phase 0: Installation Script (Weeks 1-2)

- [ ] CLI parameter parsing
- [ ] IPv6 detection script
- [ ] IPv6 auto-enable script (Ubuntu/Debian/CentOS)
- [ ] DNS record instruction generation
- [ ] DNS verification script (dig/nslookup)
- [ ] Configuration file generation (YAML templates)
- [ ] Docker/VM/Kubernetes detection
- [ ] Error handling and recovery
- [ ] Logging (JSON format)
- [ ] Installation wizard (interactive phase)
- [ ] Integration tests (all paths)
- [ ] Documentation (user-facing)

### Phase 1: Registry Deployment (Weeks 3-4)

- [ ] Root registry container image
- [ ] Secondary registry container image
- [ ] Database schema and migrations
- [ ] Replication protocol (delta sync)
- [ ] Health checks (registry liveness)
- [ ] Monitoring (metrics, logs)
- [ ] Configuration validation

### Phase 2: Node Integration (Weeks 5-6)

- [ ] Node startup sequence
- [ ] Registry client library
- [ ] DNS lookup for registry discovery
- [ ] Heartbeat loop
- [ ] Peer discovery from registry
- [ ] Error handling (registry unavailable)
- [ ] Local registry integration

### Phase 3: Testing (Weeks 7-12)

- [ ] Single node + root registry
- [ ] Two nodes + root registry
- [ ] Three nodes + independent secondary
- [ ] Failover scenarios (registry down)
- [ ] DNS propagation timing
- [ ] IPv6 connectivity across networks
- [ ] Performance under load

---

**Document prepared**: January 29, 2026  
**Status**: Architecture finalized, ready for implementation  
**Next**: Implement installation script (Week 1)
