# TrustNet Prototype Installation Workflow

**Purpose**: Detailed specification for prototype phase (Week 1-2)  
**Status**: ✅ Complete (Jan 30, 2026)  
**Audience**: Implementation team (building install script)  
**Scope**: Single install script that creates root registry VM + first node  
**Test Domain**: bucoto.com

---

## Overview: One Script, Two Machines

**Goal**: Prove the architecture works with:
1. Root registry running independently
2. First node connecting to registry
3. Both sharing DNS record for domain

**Execution**:
```bash
trustnet-install bucoto.com
```

**Result**:
- Root Registry VM created (if needed)
- Node VM created
- DNS record information provided to user
- Network operational

---

## Part 1: Install Script Invocation

### Command
```bash
trustnet-install <domain>
```

### Example
```bash
trustnet-install bucoto.com
```

### Parameters
```bash
# Required
DOMAIN="bucoto.com"

# Optional (with defaults)
--registry-vm-image=ubuntu-22.04      # Container/VM image for root registry
--registry-vm-name=trustnet-root-1    # Name of registry VM
--registry-vm-ipv6=auto               # Auto-detect or specify
--node-vm-image=ubuntu-22.04
--node-vm-name=node-1
--node-vm-ipv6=auto
--deployment-target=vm|docker|k8s     # Default: vm
--dns-provider=route53|manual          # Default: manual (user action)
--verbose=true|false                  # Default: false
```

---

## Part 2: Discovery Phase (DNS Lookup)

### Step 1: Resolve Domain
```bash
# Check if domain resolves
dig +short bucoto.com A AAAA

# Expected results:
# - Domain name resolves (can be A or AAAA, doesn't matter yet)
# - If not: Exit with "Domain not found"
```

### Step 2: Check for tnr Record
```bash
# Look for tnr.bucoto.com AAAA record
dig +short tnr.bucoto.com AAAA

# Result 1: Empty (record doesn't exist)
#   → Script will create root registry
#   → Provide DNS record info to user
#
# Result 2: Returns IPv6 (record exists)
#   → Script will create secondary/node
#   → Root registry already exists elsewhere
#   → Skip registry creation
```

---

## Part 3: Scenario A - First Install (No tnr Record)

**Flow**: Domain exists, but no tnr record yet

### Step 1: Display Welcome Message
```
═════════════════════════════════════════════════════════
     TrustNet Prototype Installation
═════════════════════════════════════════════════════════

Domain: bucoto.com
Status: New network (no tnr record found)

This script will:
1. Create Root Registry VM
2. Provide DNS record to add
3. Create First Node VM
4. Test network connectivity

═════════════════════════════════════════════════════════
```

### Step 2: Validate Prerequisites
```bash
Check:
  ✓ Sudo access (can create VMs/containers)
  ✓ Docker running (if deployment=docker)
  ✓ Kubernetes access (if deployment=k8s)
  ✓ IPv6 enabled on this machine
  ✓ Disk space available (>5GB)
  ✓ Ports 8000, 9000 available
```

### Step 3: Create Root Registry VM

```bash
# Generate configuration
registry_config="""
registry:
  role: "root"
  ipv6_address: "${REGISTRY_IPV6}"
  port: 8000
  
database:
  type: sqlite
  path: /data/registry.db
  
replication:
  enabled: false
  
heartbeat:
  interval: 30
"""

# Create VM (or container)
# Pseudocode:
IF deployment_target == "docker":
  docker run -d \
    --name trustnet-root-1 \
    --ipv6 \
    -p 8000:8000 \
    -v /data/registry.db:/data/registry.db \
    trustnet:root-registry \
    --config registry_config.yml

ELIF deployment_target == "vm":
  # Create VM via cloud provider / local hypervisor
  vm_output = create_vm(
    name: "trustnet-root-1",
    image: "ubuntu-22.04",
    ipv6: true,
    script: install_registry.sh
  )
  REGISTRY_IPV6 = vm_output.ipv6_address

# Wait for registry to start
Wait for endpoint: [${REGISTRY_IPV6}]:8000 to respond (retry 30 times, 2s apart)
IF timeout:
  Exit with error: "Registry failed to start"
```

### Step 4: Extract Registry IPv6 Address

```bash
# If running in container, get its IPv6:
REGISTRY_IPV6=$(docker inspect trustnet-root-1 | grep IPv6Address)

# If VM, get from cloud provider API:
REGISTRY_IPV6=$(aws ec2 describe-instances --instance-ids i-xxx | grep Ipv6Address)

# Validate it works:
curl -s http://[${REGISTRY_IPV6}]:8000/api/health
Expected response: {"status":"ok"}
```

### Step 5: Display DNS Record Instructions

```
═════════════════════════════════════════════════════════
     DNS RECORD REQUIRED
═════════════════════════════════════════════════════════

Root Registry Created Successfully!
├─ Name: trustnet-root-1
├─ IPv6: 2001:db8::1 (example)
└─ Status: Running, listening on port 8000

Now you must add a DNS record:

Record Name:    tnr
Domain:         bucoto.com
Full FQDN:      tnr.bucoto.com
Record Type:    AAAA
Value:          2001:db8::1
TTL:            300

═════════════════════════════════════════════════════════
     Instructions by DNS Provider
═════════════════════════════════════════════════════════

AWS Route53:
  1. Go to AWS Console → Route53
  2. Find hosted zone: bucoto.com
  3. Click "Create record"
  4. Record name: tnr
  5. Record type: AAAA - IPv6 address
  6. Value: 2001:db8::1
  7. TTL: 300
  8. Click "Create records"
  9. Wait 1-2 minutes for propagation

Cloudflare:
  1. Login to Cloudflare Dashboard
  2. Select domain: bucoto.com
  3. Go to DNS records
  4. Click "Add record"
  5. Type: AAAA
  6. Name: tnr
  7. IPv6 address: 2001:db8::1
  8. TTL: Auto
  9. Click "Save"
  10. Wait 1-2 minutes

Manual / Other Provider:
  Contact your DNS provider with:
  - Record: tnr.bucoto.com
  - Type: AAAA (IPv6)
  - Value: 2001:db8::1
  - TTL: 300 seconds

═════════════════════════════════════════════════════════

Verify DNS is working:
  dig +short tnr.bucoto.com AAAA

When you see the IPv6 address in response, DNS is ready.

═════════════════════════════════════════════════════════
```

### Step 6: Wait for DNS Confirmation

```bash
Prompt: "Press Enter when DNS record is added and propagated..."
User adds DNS record to their provider
User verifies with: dig +short tnr.bucoto.com AAAA
User presses Enter to continue

Script verifies DNS:
  while true:
    RESULT=$(dig +short tnr.bucoto.com AAAA)
    if RESULT == "2001:db8::1":
      echo "✓ DNS verified"
      break
    else:
      echo "DNS not yet propagated, retrying in 5 seconds..."
      sleep 5
  
  Timeout: 60 seconds (12 retries)
  If timeout: Warn user but continue anyway (DNS might be cached)
```

### Step 7: Create First Node VM

```bash
# Wait a moment to ensure DNS is globally propagated
sleep 10

# Node configuration will reference registry via DNS
node_config="""
node:
  name: "node-1"
  domain: "bucoto.com"
  ipv6_address: "${NODE_IPV6}"
  port: 9000

registry:
  type: "integrated"
  address: "127.0.0.1:8000"
  fallback_domain: "bucoto.com"
  fallback_lookup: "dns"
"""

# Create Node VM
IF deployment_target == "docker":
  docker run -d \
    --name node-1 \
    --ipv6 \
    -p 9000:9000 \
    -e DOMAIN=bucoto.com \
    -e REGISTRY_LOOKUP=dns \
    trustnet:node:latest

ELIF deployment_target == "vm":
  node_output = create_vm(
    name: "node-1",
    image: "ubuntu-22.04",
    ipv6: true,
    script: install_node.sh
  )
  NODE_IPV6 = node_output.ipv6_address

# Wait for node to start
Wait for endpoint: [${NODE_IPV6}]:9000 to respond (retry 30 times, 2s apart)
IF timeout:
  Exit with error: "Node failed to start"
```

### Step 8: Verify Network Connectivity

```bash
# Check registry health
echo "Testing registry..."
curl -s http://[2001:db8::1]:8000/api/health
Expected: {"status":"ok"}

# Check node is running
echo "Testing node..."
curl -s http://[${NODE_IPV6}]:9000/api/health
Expected: {"status":"ok", "node_id":"0x..."}

# Check node registered with registry
echo "Checking node registration..."
curl -s http://[2001:db8::1]:8000/api/nodes
Expected: [{"node_id":"0x...", "name":"node-1", "status":"ACTIVE"}]

# Check peer discovery
echo "Checking peer discovery..."
curl -s http://[${NODE_IPV6}]:9000/api/peers
Expected: (empty initially, since only 1 node)
```

### Step 9: Display Success Message

```
═════════════════════════════════════════════════════════
     ✓ PROTOTYPE INSTALLATION COMPLETE
═════════════════════════════════════════════════════════

Root Registry:
├─ Name: trustnet-root-1
├─ IPv6: 2001:db8::1
├─ Port: 8000
├─ Status: ✓ ACTIVE
├─ Health: ✓ OK (response time: 12ms)
└─ DNS: tnr.bucoto.com → 2001:db8::1

First Node:
├─ Name: node-1
├─ IPv6: 2001:db8::100
├─ Port: 9000
├─ Status: ✓ ACTIVE
├─ Health: ✓ OK (response time: 8ms)
├─ Registry: 127.0.0.1:8000 (integrated)
├─ NodeID: 0x7f8a9b1c2d3e4f5a
└─ Peers: 0 (will increase when more nodes join)

Network Status:
├─ Registry ↔ Node: ✓ Connected
├─ Node registration: ✓ OK
├─ Peer discovery: ✓ OK (0 peers, as expected)
├─ IPv6 connectivity: ✓ OK
└─ DNS resolution: ✓ OK (tnr.bucoto.com)

═════════════════════════════════════════════════════════

Next Steps:

1. Add another node:
   trustnet-install bucoto.com --node-name=node-2

2. Monitor network:
   trustnet logs registry
   trustnet logs node-1

3. View network status:
   trustnet status
   
4. View nodes:
   curl -s http://[2001:db8::1]:8000/api/nodes

═════════════════════════════════════════════════════════
```

---

## Part 4: Scenario B - Subsequent Install (tnr Record Exists)

**Flow**: User runs script again to add second node (tnr record already exists)

### Step 1: Detect Existing Network
```bash
dig +short tnr.bucoto.com AAAA

# Returns: 2001:db8::1 (root registry exists)
# Script recognizes: Network already exists

Display:
  "Root registry found at [2001:db8::1]:8000"
  "Creating secondary node..."
```

### Step 2: Create Node Only
```bash
# Skip registry creation
# Just create node that will:
#   1. Start integrated registry
#   2. Lookup root via DNS: dig +short tnr.bucoto.com AAAA
#   3. Sync node list from root
#   4. Register itself
```

### Step 3: Verify Peer Discovery
```bash
# After node startup, check it discovered peers:
curl -s http://[${NODE2_IPV6}]:9000/api/peers

# Expected: [{"node_id":"0x...node-1...", "ipv6":"2001:db8::100"}]
```

---

## Part 5: Error Handling

### Error 1: Domain Not Found
```bash
IF dig bucoto.com returns NXDOMAIN:
  Exit with: "Domain 'bucoto.com' not found in DNS"
  Action: "Check domain name or ask DNS admin"
  Exit code: 1
```

### Error 2: Registry VM Creation Failed
```bash
IF docker/vm creation fails:
  Exit with: "Failed to create registry VM"
  Logs: Show container/VM creation error
  Action: "Check Docker/hypervisor status"
  Exit code: 2
```

### Error 3: Registry Won't Start
```bash
IF registry endpoint doesn't respond after 60s:
  Exit with: "Registry failed to start (timeout)"
  Logs: Show container logs
  Action: "Check logs: docker logs trustnet-root-1"
  Exit code: 3
```

### Error 4: DNS Not Propagated
```bash
IF dig tnr.bucoto.com doesn't return expected IP after 60s:
  Warn: "DNS still not propagated"
  Offer: "Wait longer? (Y/n) or continue anyway? (y/N)"
  If user continues: Proceed with node creation
  If timeout: Log warning and continue
```

### Error 5: Node Registration Failed
```bash
IF node can't register with registry:
  Exit with: "Node failed to register"
  Debug info: Show curl response
  Check:
    1. Registry is running: curl [${REGISTRY_IPV6}]:8000/api/health
    2. DNS resolves correctly: dig tnr.bucoto.com AAAA
    3. Network connectivity: ping -6 [${REGISTRY_IPV6}]
```

---

## Part 6: Script Implementation Checklist

### Phase 1: Parameter Parsing
- [ ] Accept domain as first argument
- [ ] Accept optional parameters (--deployment-target, --node-name, etc.)
- [ ] Validate domain name format
- [ ] Show help with --help

### Phase 2: Discovery
- [ ] Check if domain resolves (dig bucoto.com A AAAA)
- [ ] Check if tnr record exists (dig tnr.bucoto.com AAAA)
- [ ] Determine scenario (A = new network, B = add node)

### Phase 3: Registry Creation (Scenario A only)
- [ ] Validate prerequisites (docker, sudo, ipv6, disk space)
- [ ] Create registry configuration
- [ ] Create registry container/VM
- [ ] Wait for registry endpoint to respond
- [ ] Extract registry IPv6 address
- [ ] Display DNS record instructions

### Phase 4: DNS Verification
- [ ] Wait for user to add DNS record
- [ ] Verify DNS propagation (retry loop)
- [ ] Handle timeout (warn but continue)

### Phase 5: Node Creation
- [ ] Create node configuration
- [ ] Create node container/VM
- [ ] Wait for node endpoint to respond
- [ ] Extract node IPv6 address

### Phase 6: Network Verification
- [ ] Test registry health endpoint
- [ ] Test node health endpoint
- [ ] Test node registration (GET /api/nodes)
- [ ] Test peer discovery (GET /api/peers)

### Phase 7: Output & Cleanup
- [ ] Display success message
- [ ] Show next steps
- [ ] Save configuration to file
- [ ] Log installation details
- [ ] Exit with code 0

---

## Part 7: Directory Structure After Install

### Root Registry VM
```
/opt/trustnet/
├── bin/
│   └── registry-service
├── config/
│   └── registry-config.yml
├── data/
│   ├── registry.db
│   └── backups/
├── logs/
│   └── registry.log
└── scripts/
    └── health-check.sh
```

### Node VM
```
/opt/trustnet/
├── bin/
│   ├── node
│   └── registry-service (integrated)
├── config/
│   ├── node-config.yml
│   └── registry-config.yml
├── data/
│   ├── node.db
│   ├── registry-replica.db
│   └── ledger/
├── logs/
│   ├── node.log
│   └── registry.log
└── scripts/
    ├── health-check.sh
    └── peer-discovery.sh
```

---

## Part 8: Testing the Prototype

### Manual Verification Steps

```bash
# 1. Verify registries are running
docker ps | grep trustnet

# 2. Check registry health
curl -s http://[2001:db8::1]:8000/api/health

# 3. Check node health
curl -s http://[2001:db8::100]:9000/api/health

# 4. View registered nodes
curl -s http://[2001:db8::1]:8000/api/nodes | jq

# 5. View node's peers
curl -s http://[2001:db8::100]:9000/api/peers | jq

# 6. Verify DNS
dig +short tnr.bucoto.com AAAA

# 7. View logs
docker logs trustnet-root-1
docker logs node-1

# 8. Add second node (repeat install)
trustnet-install bucoto.com --node-name=node-2

# 9. Verify both nodes see each other
curl -s http://[2001:db8::100]:9000/api/peers
curl -s http://[2001:db8::101]:9000/api/peers
```

### Success Criteria
- [ ] Root registry starts and responds to health checks
- [ ] DNS record can be added to domain
- [ ] First node starts and registers with registry
- [ ] Node-to-registry communication works
- [ ] Second node can be added
- [ ] Nodes discover each other via registry
- [ ] All peer-to-peer communication uses IPv6
- [ ] No errors in logs

---

## Part 9: Configuration Files Generated

### registry-config.yml (Root)
```yaml
registry:
  role: "root"
  ipv6_address: "2001:db8::1"
  port: 8000

database:
  type: sqlite
  path: /data/registry.db
  max_connections: 20

replication:
  enabled: false

heartbeat:
  interval: 30
  timeout: 5
  missing_threshold: 10
  inactive_after: 86400

reputation:
  initial_score: 50
  uptime_bonus: 1
  downtime_penalty: 1
  max_score: 100
  ban_threshold: 10

logging:
  level: info
  format: json
  output: /var/log/registry.log
```

### node-config.yml
```yaml
node:
  name: "node-1"
  domain: "bucoto.com"
  ipv6_address: "2001:db8::100"
  port: 9000

registry:
  type: "integrated"
  address: "127.0.0.1:8000"
  fallback_domain: "bucoto.com"
  fallback_lookup: "dns"

consensus:
  engine: "tendermint"
  block_time: 1000

gossip:
  enabled: true
  interval: 30

logging:
  level: info
  format: json
  output: /var/log/node.log
```

---

## Summary: Prototype Install Flow

```
START: trustnet-install bucoto.com

1. Parse domain: bucoto.com
2. Validate domain resolves
3. Check for tnr record

   IF tnr record missing:
     4a. Create root registry VM
     4b. Extract its IPv6
     4c. Show DNS instructions
     4d. Wait for user to add DNS record
     4e. Verify DNS propagation
   
   ELSE (tnr record exists):
     4f. Use existing root registry

5. Create first/next node VM
6. Node starts with integrated registry
7. Node looks up root registry via DNS
8. Node registers with registry
9. Node discovers peers from registry

10. Verify all components
11. Display success
12. Exit (code 0 = success)
```

---

**Document prepared**: January 30, 2026  
**Status**: Ready for implementation (Week 1)  
**Next**: Build install script using this specification
