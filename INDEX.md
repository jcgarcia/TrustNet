# TrustNet Documentation Index

**Last Updated**: January 30, 2026  
**Purpose**: Master index of all TrustNet documentation  
**Status**: Living document (updated with each new document)

---

## Quick Navigation

**Starting here?** → Read in this order:
1. [README.md](README.md) - Vision & overview
2. [POC_DISTRIBUTED_NODE_NETWORK.md](POC_DISTRIBUTED_NODE_NETWORK.md) - What we're building (8-12 weeks)
3. [NODE_REGISTRY_SERVICE_ARCHITECTURE.md](NODE_REGISTRY_SERVICE_ARCHITECTURE.md) - Node registration & discovery

**Building the network?** → START HERE before coding:
1. **[ARCHITECTURE_DECISIONS.md](ARCHITECTURE_DECISIONS.md)** - 15 locked-in architectural choices (READ FIRST!)
2. [FACTORYVM_REUSE_ANALYSIS.md](FACTORYVM_REUSE_ANALYSIS.md) - Code reuse from FactoryVM (implementation reference)
3. [PROTOTYPE_INSTALLATION_WORKFLOW.md](PROTOTYPE_INSTALLATION_WORKFLOW.md) - Build Week 1 prototype (specification)

**Building the network?** → Technical deep dives (for reference):
4. [INSTALLATION_AND_DEPLOYMENT_ARCHITECTURE.md](INSTALLATION_AND_DEPLOYMENT_ARCHITECTURE.md) - Full install design
5. [NODE_REGISTRY_SERVICE_ARCHITECTURE.md](NODE_REGISTRY_SERVICE_ARCHITECTURE.md) - Registry design (weeks 3-4)
6. [NODE_NETWORK_ARCHITECTURE_PLANNING.md](NODE_NETWORK_ARCHITECTURE_PLANNING.md) - Design decisions
7. [TECHNICAL_ARCHITECTURE.md](TECHNICAL_ARCHITECTURE.md) - Full system (Phase 1+)

**Funding/pitching?** → Business documents:
1. [README.md](README.md) - Vision statement
2. [COST_ANALYSIS.md](COST_ANALYSIS.md) - Financial projections
3. [FUNDING_STRATEGY.md](FUNDING_STRATEGY.md) - How to raise money
4. [MARKET_OPPORTUNITIES.md](MARKET_OPPORTUNITIES.md) - Market sizing

**Understanding Web3?** → Learning materials:
1. [APPENDIX_WEB3_GLOSSARY.md](APPENDIX_WEB3_GLOSSARY.md) - 100+ terms explained
2. [WEB3_NATIVE_STRATEGY.md](WEB3_NATIVE_STRATEGY.md) - Why blockchain matters

---

## Documents by Category

### Vision & Strategy

#### [README.md](README.md)
- **Purpose**: Project vision, 4 core components, roadmap overview
- **Audience**: Everyone (investors, developers, community)
- **Status**: ✅ Complete
- **Key sections**:
  - TrustNet vision statement
  - 4 components: Network, Cryptocurrency, Finance, Social
  - Principles: Transparency, user ownership, community governance
  - 4-phase roadmap
  - Success metrics
- **When to read**: First document about the project
- **Size**: 8KB
- **Last updated**: Jan 27, 2026

---

### CRITICAL: Architectural Decisions (READ BEFORE WEEK 1 CODING)

#### [ARCHITECTURE_DECISIONS.md](ARCHITECTURE_DECISIONS.md) ⭐ **START HERE BEFORE CODING**
- **Purpose**: 15 locked-in architectural decisions to prevent mid-project rework
- **Audience**: Everyone involved in development (engineers, architects, leads)
- **Status**: ✅ FINAL (Jan 30, 2026) - Locked for POC phase
- **Why**: Decisions made NOW prevent costly architecture changes later
- **Key sections** (15 decisions, each with rationale, implications, validation point, fallback):
  1. Base container image: **Alpine Linux** ✅
  2. Orchestration: **Docker Compose** (K3s later) ✅
  3. Database: **SQLite** (no PostgreSQL) ✅
  4. Networking: **IPv6-only** (no IPv4 P2P) ✅
  5. Language: **Go 1.22+** (all backends) ✅
  6. Deployment: **Docker containers** (VMs optional for testing) ✅
  7. Consensus: **Tendermint preferred** (custom fallback if musl libc issues) ⏳
  8. Configuration: **Environment variables + YAML files** ✅
  9. Logging: **Structured JSON to stdout** (no external tools yet) ✅
  10. Secrets: **Env vars only** (.env.local git-ignored) ✅
  11. Versioning: **Semantic versioning with git tags** ✅
  12. Error handling: **Fail fast, Docker restart policy** ✅
  13. Testing: **Go unit tests + manual integration** (no E2E framework) ✅
  14. Deployment: **Manual with docker-compose** (Jenkins Week 11+) ✅
  15. Backups: **File-based SQLite copies** (no automated backup system) ✅
- **Alpine-specific validation**:
  - Week 3-4: Build registry on Alpine, test musl libc compatibility
  - If issues: Add gcompat layer (still lightweight)
  - Fallback: Ubuntu 22.04 (last resort)
- **Consensus-specific decision**:
  - Week 3-4: Evaluate Tendermint library on Alpine
  - Decision locked in Week 4 (custom consensus if needed)
- **When to read**: BEFORE Week 1 coding starts (non-negotiable)
- **Size**: 40KB (comprehensive, one decision per section)
- **Before approval**:
  - [ ] Do you agree with Alpine choice?
  - [ ] Any concern about SQLite for POC?
  - [ ] Any preference for consensus algorithm?
  - [ ] Any blocking issues with these decisions?
- **How to use**:
  - Engineers: Reference when making implementation choices
  - Decision makers: Review core decisions (1-6), validate others at checkpoints
  - No changes without documented evidence of failure
- **Last updated**: Jan 30, 2026

---

### Proof of Concept (POC) - Current Focus

#### [POC_DISTRIBUTED_NODE_NETWORK.md](POC_DISTRIBUTED_NODE_NETWORK.md)
- **Purpose**: MVP specification (3-node network with trust scoring)
- **Audience**: Developers building the POC
- **Status**: ✅ Complete, implements user feedback
- **Timeline**: 8-12 weeks to working MVP
- **Key sections**:
  - Core concept (trust-first, not cryptocurrency yet)
  - Data model (Node, TrustRating, Ledger, Block)
  - 8-12 week implementation plan (week-by-week)
  - Success criteria & checklist
  - Risks & mitigation
  - Why this POC matters
- **Decision points resolved**:
  - TrustCoin on TrustNet network (not Ethereum)
  - No blockchain initially (add later)
  - Trust-first approach (rating relationships)
  - 3 → 10 node scaling
  - Total automation (FactoryVM level)
- **When to read**: Before starting any code
- **Size**: 30KB
- **Relevant for**: Weeks 1-12 (entire POC phase)
- **Next phases**: See [TECHNICAL_ARCHITECTURE.md](TECHNICAL_ARCHITECTURE.md) for Phase 1+
- **Last updated**: Jan 28, 2026

---

#### [PROTOTYPE_INSTALLATION_WORKFLOW.md](PROTOTYPE_INSTALLATION_WORKFLOW.md)
- **Purpose**: Detailed specification for prototype install script (Week 1-2)
- **Audience**: Implementation team (building the install script)
- **Status**: ✅ Complete (Jan 30, 2026)
- **Timeline**: Week 1-2 implementation
- **Key sections**:
  - One script, two VMs (root registry + first node)
  - Scenario A: New network (no tnr record, create registry)
  - Scenario B: Existing network (tnr record exists, add node)
  - Discovery phase (check for tnr record)
  - Root registry creation (Docker or VM)
  - DNS record instructions (provider-agnostic)
  - DNS verification loop (auto-detect propagation)
  - First node creation (integrated registry, DNS fallback)
  - Network verification (health checks, registration, peer discovery)
  - Error handling (domain not found, registry timeout, DNS propagation, etc.)
  - Configuration file templates (registry-config.yml, node-config.yml)
  - Testing steps (manual verification)
  - Directory structure post-install
  - Success criteria checklist
- **Command**:
  ```bash
  trustnet-install bucoto.com
  ```
- **What it does**:
  1. Checks if domain exists
  2. Looks for tnr.bucoto.com AAAA record
  3. If missing: Creates root registry VM, shows DNS instructions, waits for user
  4. If found: Skips registry (already exists)
  5. Creates first node VM
  6. Node starts with integrated registry
  7. Node discovers root via DNS lookup
  8. Node registers itself
  9. Verifies everything works
  10. Done!
- **User flow**:
  - Week 1: Run script → Creates root registry + node-1 → Adds DNS record manually
  - Week 2: Run script again → Creates node-2 → DNS record already exists
  - Nodes discover each other automatically
- **When to read**: Before implementing install script (Week 1)
- **Size**: 20KB
- **Relevant for**: Week 1-2 (prototype phase)
- **Prerequisites**: Docker/VM creation capability, sudo access, IPv6 enabled
- **Success metrics**: Script runs end-to-end, root registry and node-1 operational, health checks pass
- **Last updated**: Jan 30, 2026

---

#### [NODE_REGISTRY_SERVICE_ARCHITECTURE.md](NODE_REGISTRY_SERVICE_ARCHITECTURE.md)
- **Purpose**: Central service for node registration, discovery, and reputation tracking
- **Audience**: Backend engineers (building registry service)
- **Status**: ✅ Complete (Jan 29, 2026 - Added Phase 1+ distributed design)
- **Timeline**: 
  - Weeks 3-4 of POC (single root registry)
  - Phase 1+ (months 4-6): Add secondary registries
- **Key sections**:
  - Architecture overview (Express.js + SQLite)
  - Complete data model (3 tables: nodes, heartbeats, reputation_changes)
  - 6 REST API endpoints with specifications (register, discover, heartbeat, status, peers, update)
  - Implementation phases (Week 3: foundation, Week 4: persistence + reputation)
  - Reputation system logic (scoring algorithm, examples)
  - Node integration code samples (Go code)
  - Security considerations (Sybil attacks, eclipse attacks, reputation manipulation)
  - Configuration file format
  - Monitoring & observability
  - **NEW - Phase 1+: Distributed Registry Design** (DNS-like architecture)
    - Root Registry + Secondary Replicas (no single point of failure)
    - Replication protocol (60-second sync, delta-based)
    - Configuration examples (root, secondary-1, secondary-2)
    - Node discovery of multiple registries (Go code)
    - Failover scenarios (queuing updates, promoting secondaries)
    - Benefits checklist (resilience, scalability, geographic distribution)
  - Path to blockchain migration (Phase 2)
- **Why this matters**: 
  - Solves critical problem: How nodes discover each other
  - Enables dynamic node addition (add nodes anytime)
  - Tracks status without polling
  - Foundation for reputation/banning system
  - Stepping stone to blockchain (can migrate later)
  - Phase 1+ design: Distributed like DNS (Web3-aligned, no SPOF)
- **Connection to POC**: 
  - Weeks 1-2: Single node (doesn't need registry)
  - Weeks 3-4: Registry service (enable multiple nodes, single root)
  - Weeks 5+: Trust scoring uses registry
  - Months 4-6: Add secondary registries (Phase 1+)
- **When to read**: Week 3, before implementing registry service
- **Size**: 80KB (includes Phase 1+ distributed design)
- **Relevant for**: Weeks 3-4 (core implementation) + Phase 1+ (scalability)
- **Future work**: Phase 2 will migrate to blockchain smart contract
- **Last updated**: Jan 29, 2026

---

### Implementation & Code Reuse

#### [FACTORYVM_REUSE_ANALYSIS.md](FACTORYVM_REUSE_ANALYSIS.md)
- **Purpose**: Identify reusable code from FactoryVM for TrustNet prototype
- **Audience**: Implementation team (code review reference)
- **Status**: ✅ Complete (Jan 30, 2026)
- **Timeline**: Week 1-2 implementation reference
- **Key sections**:
  - Executive summary (reuse opportunities)
  - FactoryVM project structure analysis
  - Reusable components breakdown (logging, VM lifecycle, cache mgmt, service installation)
  - TrustNet prototype architecture (directory structure)
  - Specific code patterns to reuse (4 key patterns)
  - File-by-file implementation guide
  - Code patterns: common.sh, SSH execution, cache management, service installation
  - New files to create (dns-manager.sh, registry-installer.sh, node-installer.sh)
  - Main install script orchestration
  - Implementation timeline (Week 1-2)
  - What NOT to reuse (Alpine install, K8s, Terraform)
- **Key findings**:
  - ✅ 1,200+ lines of proven FactoryVM code we can reuse
  - ✅ Time saved: 3-4 weeks (don't rebuild VM infrastructure)
  - ✅ Copy FactoryVM patterns: logging, caching, SSH provisioning
  - ✅ Create ~300-400 lines of TrustNet-specific code
  - ✅ Reusable files: common.sh, cache-manager.sh, vm-lifecycle.sh, vm-bootstrap.sh
- **Code reuse metrics**:
  - common.sh (180 lines): **Minimal** changes needed
  - cache-manager.sh (404 lines): **Moderate** adaptations
  - vm-lifecycle.sh (300+ lines): **High** customization for TrustNet
  - install-docker.sh (87 lines): **Pattern** reference for registry/node installers
- **File structure post-implementation**:
  ```
  ~/.trustnet/
  ├── cache/                    (FROM FactoryVM pattern)
  ├── scripts/
  │   ├── trustnet-install      (NEW main script)
  │   └── lib/
  │       ├── common.sh         (COPY from FactoryVM)
  │       ├── cache-manager.sh  (ADAPT from FactoryVM)
  │       ├── dns-manager.sh    (NEW)
  │       ├── registry-installer.sh (NEW)
  │       └── node-installer.sh (NEW)
  └── config/
      ├── registry-config.yml   (Generated)
      └── node-config.yml       (Generated)
  ```
- **When to read**: Before implementing install script (Week 1)
- **Size**: 25KB
- **Relevant for**: Week 1-2 (implementation code patterns)
- **Saves time**: 3-4 weeks of infrastructure coding
- **Last updated**: Jan 30, 2026

---

### Installation & Deployment

#### [INSTALLATION_AND_DEPLOYMENT_ARCHITECTURE.md](INSTALLATION_AND_DEPLOYMENT_ARCHITECTURE.md)
- **Purpose**: Automated installation script design & deployment patterns
- **Audience**: DevOps engineers, implementation team
- **Status**: ✅ Complete (Jan 29, 2026)
- **Timeline**: Implementation for Weeks 1-2
- **Key sections**:
  - Installation philosophy: "Questions at the start, automation throughout"
  - CLI parameters and interactive phase
  - IPv6 validation & auto-enable
  - DNS record requirements (provider-agnostic instructions)
  - Registry type selection (root, independent secondary, integrated)
  - Complete automated execution flow (pre-flight → execution → post-flight)
  - Registry startup sequence (root vs. secondary)
  - Node creation & registry assignment
  - Service discovery for nodes (DNS lookup vs. integrated registry)
  - Multi-registry network (Phase 1+ with multiple secondaries)
  - Configuration file templates (YAML)
  - Error handling & recovery scenarios
  - Security & validation checks
  - Implementation checklist
- **Key concepts**:
  - Domain name provided by user at start
  - Script checks for `tnr.{domain}` IPv6 record
  - If missing: Shows DNS instructions, user adds record, script verifies
  - If found: Fetches root/secondary IPv6 addresses from DNS
  - Registries discovered via DNS, not hardcoded
  - Integrated registries: Local, private, syncs from root
  - Independent registries: Public, advertised in DNS, syncs from root
  - Nodes use local registry first, fallback to DNS lookup
  - All IPv6 (mandatory, auto-enabled if needed)
- **Connection to POC**: 
  - Week 1: Create installation script
  - Week 2: Test with root registry + first node
  - Weeks 3-4: Registry service implementation
  - Weeks 5+: Node software (uses installer output)
- **When to read**: Before implementing installation script (Week 1)
- **Size**: 50KB
- **Relevant for**: Weeks 1-2 (implementation), Phase 1+ (scalability)
- **Last updated**: Jan 29, 2026

---

### Planning & Architecture

#### [NODE_NETWORK_ARCHITECTURE_PLANNING.md](NODE_NETWORK_ARCHITECTURE_PLANNING.md)
- **Purpose**: Strategic planning with decision options
- **Audience**: Decision-makers, architects
- **Status**: ✅ Complete, reference document
- **Key sections**:
  - Learning from FactoryVM (what works, what to improve)
  - 8 critical discussion questions
  - 7 architecture decision options with pros/cons
  - Implementation roadmap (6 phases, 32 weeks)
- **Decisions made from this doc**:
  - ✅ Complementary to blockchain (not replacing it)
  - ✅ Registry service for discovery
  - ✅ You + Copilot + friends (no hiring)
  - ✅ Total automation (FactoryVM level)
  - ✅ Trust-first approach
  - ✅ Start with 3 nodes, scale to 10
- **When to read**: When making architecture decisions
- **Size**: 40KB
- **Status**: Superseded by [POC_DISTRIBUTED_NODE_NETWORK.md](POC_DISTRIBUTED_NODE_NETWORK.md) for implementation details
- **Last updated**: Jan 28, 2026

---

#### [TECHNICAL_ARCHITECTURE.md](TECHNICAL_ARCHITECTURE.md)
- **Purpose**: Complete system design for Phase 1+ (6-layer architecture)
- **Audience**: Tech leads, full-stack engineers
- **Status**: ✅ Complete (written before POC pivot)
- **Important note**: Based on original plan (before Trust-First POC)
- **Key sections**:
  - 6-layer system design
  - 6 smart contracts (Identity, Trust, TrustCoin, Escrow, DAO, Bridge)
  - 6 microservices (Auth, User, Transaction, Trust, Dispute, Social)
  - Data layer (PostgreSQL + Neo4j + IPFS)
  - Kubernetes deployment (50 validators, Tendermint consensus)
- **Relationship to POC**: 
  - POC is simpler (3 nodes, local ledger, no blockchain)
  - TECHNICAL_ARCHITECTURE is the full Phase 1+ vision
  - POC proves core concept before building this
- **When to read**: After POC succeeds, planning Phase 1
- **Size**: 20KB
- **Relevant for**: Phase 1+ (months 6-18)
- **Last updated**: Jan 27, 2026

---

### Trust & Reputation

#### [TRUST_SYSTEM.md](TRUST_SYSTEM.md)
- **Purpose**: Trust scoring algorithm & mechanics
- **Audience**: Architects, engineers building reputation
- **Status**: ✅ Complete
- **Key sections**:
  - Trust scoring formula (BaseScore + deltas + bonuses - penalties)
  - 6 reputation tiers (Exemplary, Trusted, Verified, Neutral, Caution, Suspended)
  - Community rating system (how users rate each other)
  - Dispute resolution (3-of-5 arbiter voting)
  - Fraud detection (ML pattern matching)
  - Recovery mechanisms (how to rebuild reputation)
  - Immutable audit trail (blockchain storage)
- **Direct application to POC**: 
  - Reputation system in Weeks 5-6
  - Trust ratings in Weeks 1-2
- **When to read**: When building trust scoring (Week 5+)
- **Size**: 25KB
- **Relevant for**: POC + Phase 1+
- **Last updated**: Jan 27, 2026

---

### Business & Funding

#### [COST_ANALYSIS.md](COST_ANALYSIS.md)
- **Purpose**: Financial projections (£1.55M-2.75M, GBP)
- **Audience**: Investors, business planning
- **Status**: ✅ Complete, GBP-localized
- **Key sections**:
  - 3-phase cost breakdown (Phase 0: £204K, Phase 1: £440K, Phase 2: £902K)
  - Monthly burn rate (£64-150K)
  - UK salary assumptions (realistic)
  - Infrastructure costs (£3.8-15.4K/month)
  - Revenue projections (£240/month MVP → £10K+/month Year 2)
  - Contingency planning (+20% buffer = £1.86M recommended)
- **Relevant to current project**: 
  - POC budget not included (building yourself)
  - Phase 1 costs relevant for future funding
- **When to read**: When raising money
- **Size**: 15KB
- **Last updated**: Jan 27, 2026 (GBP-converted)

---

#### [FUNDING_STRATEGY.md](FUNDING_STRATEGY.md)
- **Purpose**: 7-stream capital raising roadmap
- **Audience**: Founder, fundraisers
- **Status**: ✅ Complete
- **Key sections**:
  - 7 funding streams (VC, token pre-sale, grants, partnerships, crowdfunding, infrastructure, secondary sales)
  - VC targeting (15+ VCs identified)
  - Token mechanics (Seed @ £0.01, Private @ £0.015)
  - Monthly targets (£200K → £400K → £850K → £800K → £375K = £2.625M)
  - Contingency plans (best/base/downside case)
  - 5-month timeline (Jan-May 2026)
- **Relevant to current project**: 
  - POC doesn't need funding (you + Copilot)
  - Phase 1 will need this plan
- **When to read**: When ready to pitch for Phase 1 money
- **Size**: 8KB
- **Last updated**: Jan 27, 2026

---

#### [MARKET_OPPORTUNITIES.md](MARKET_OPPORTUNITIES.md)
- **Purpose**: Market sizing & go-to-market strategy
- **Audience**: Business development, investors
- **Status**: ✅ Complete
- **Key sections**:
  - Primary market: LGBTQ+ (£1.7T purchasing power, 1.2B people, 85%+ digital-native)
  - Secondary markets: Diaspora (£850B remittance), Women (£36B wealth), Disabled (1.3B people)
  - Go-to-market phases (testnet → MVP → growth)
  - Partnership opportunities
  - Diversity-focused grants (£100-200K)
  - Revenue projections per segment
- **Relevant to current project**: 
  - POC can focus on any segment
  - Future: market insights guide Phase 2 expansion
- **When to read**: When defining target market
- **Size**: 10KB
- **Last updated**: Jan 27, 2026

---

### Blockchain & Web3

#### [WEB3_NATIVE_STRATEGY.md](WEB3_NATIVE_STRATEGY.md)
- **Purpose**: Why blockchain matters, how to integrate it
- **Audience**: Technical architects, investors
- **Status**: ✅ Complete, philosophically corrected Jan 28
- **Key sections**:
  - Rationale: "Web3 fundamentally requires blockchain"
  - Phase 1 (6 months): Ethereum Mainnet + Polygon L2
  - 4 smart contracts (Identity, Trust, Escrow, DAO)
  - Phase 2: Multi-chain optimization
  - Phase 3: Full DAO governance
  - Total cost: £3.3M (24 months)
  - Why cheaper than infrastructure-first approach
- **Relationship to POC**: 
  - POC works WITHOUT blockchain (local ledger)
  - WEB3_NATIVE_STRATEGY shows how to add blockchain in Phase 1
- **When to read**: After POC succeeds, planning Phase 1
- **Size**: 35KB
- **Relevant for**: Phase 1+ decisions
- **Last updated**: Jan 28, 2026 (pivoted from infrastructure-first)

---

#### [APPENDIX_WEB3_GLOSSARY.md](APPENDIX_WEB3_GLOSSARY.md)
- **Purpose**: 100+ Web3/blockchain terms explained
- **Audience**: Team members, investors, community, new developers
- **Status**: ✅ Complete
- **Key sections**:
  - 8 main categories (Blockchain Fundamentals, Crypto & Tokens, Smart Contracts & DeFi, Web3 Concepts, Governance & DAOs, Infrastructure & Networks, Security & Privacy, Financial & Legal Terms)
  - 100+ terms with definitions (DAO, Smart Contract, Blockchain, Ethereum, Polygon, Wallet, etc.)
  - Common acronyms (30+: DeFi, DAO, DEX, KYC, AML, TPS, TVL, APY, MEV, RPC, EVM, ZK, NFT, HODL, FOMO, FUD, Rekt)
  - Cross-references by audience (new users, developers, community, investors)
  - Learning resources & tool links
- **When to read**: When confused about Web3 terminology
- **Size**: 60KB
- **Last updated**: Jan 28, 2026

---

### Legal & Compliance

#### [LEGAL/NDA_TEMPLATE.md](LEGAL/NDA_TEMPLATE.md)
- **Purpose**: UK jurisdiction NDA for IP protection
- **Audience**: Legal team, investors, partners
- **Status**: ✅ Complete, ready to customize
- **Key sections**:
  - 11-section legal document (UK England & Wales jurisdiction)
  - Confidentiality definitions, obligations, restrictions
  - Non-compete clause (24-48 months)
  - Permitted disclosures, remedies
  - Investment discussion provisions
  - Signature blocks & appendix
- **Relevant to current project**: 
  - Use before sharing POC details with friends/testers
  - Cost to customize: £300-800 (UK solicitor)
- **When to use**: Before showing POC to others
- **Status**: Ready to customize
- **Last updated**: Jan 27, 2026

---

#### [LEGAL/IP_PROTECTION_STRATEGY.md](LEGAL/IP_PROTECTION_STRATEGY.md)
- **Purpose**: Patents, trademarks, copyrights roadmap
- **Audience**: Legal, founder
- **Status**: ✅ Complete
- **Key sections**:
  - Immediate (Trade secrets): £0 (via NDA)
  - Month 1-2 (Domains): £500
  - Month 2-4 (UK trademark): £250-300
  - Month 6 (EU trademark): £340, Design rights: £100
  - Month 12 (International TM): £1.5-2.5K, Patents: £2-5K (optional)
  - Year 1 total: £5.3-10.5K
  - Year 2+ annual: £1.2-2.85K
- **Relevant to current project**: 
  - Protect "TrustNet" brand immediately via NDA
  - Trademark filing can start after POC shows traction
- **When to read**: When planning IP protection
- **Size**: 19KB
- **Last updated**: Jan 27, 2026

---

#### [LEGAL/REGULATORY_COMPLIANCE.md](LEGAL/REGULATORY_COMPLIANCE.md)
- **Purpose**: Multi-jurisdictional regulatory requirements
- **Audience**: Legal team, business planning
- **Status**: ✅ Complete
- **Coverage**: EU (MiCA), US (FinCEN, 50 states), UK (FCA), Singapore (MAS), Switzerland (FINMA)
- **Key sections**:
  - Per-jurisdiction requirements, timelines, costs
  - AML/KYC procedures
  - Capital requirements (£550K-£750K per jurisdiction)
  - Operational requirements
  - Phase-by-phase compliance timeline
- **Total 24-month compliance cost**: £2-3.78M
- **Relevant to current project**: 
  - POC doesn't need regulatory approval (testnet only)
  - Phase 1+ needs this framework for launch
- **When to read**: When planning Phase 1 regulatory strategy
- **Size**: 33KB
- **Last updated**: Jan 27, 2026

---

### Original Planning Documents (Reference)

#### [POC_SPECIFICATION.md](POC_SPECIFICATION.md)
- **Status**: ⚠️ Superseded by [POC_DISTRIBUTED_NODE_NETWORK.md](POC_DISTRIBUTED_NODE_NETWORK.md)
- **Reason**: Original POC spec was for blockchain-centric approach
- **Keep for**: Historical reference, comparing approaches
- **Size**: 30KB
- **Last updated**: Jan 27, 2026

---

## Document Statistics

| Category | Documents | Status | Total Size |
|----------|-----------|--------|-----------|
| Vision & Strategy | 1 | ✅ | 8KB |
| POC (Current) | 3 | ✅ | 140KB |
| Planning & Architecture | 2 | ✅ | 60KB |
| Trust & Reputation | 1 | ✅ | 25KB |
| Business & Funding | 3 | ✅ | 33KB |
| Blockchain & Web3 | 2 | ✅ | 95KB |
| Legal | 3 | ✅ | 58KB |
| **TOTAL** | **15** | **✅** | **419KB** |

---

## Reading Paths by Role

### 👨‍💻 Developer (Building POC)

**Week 1 Reading (3 hours)**:
1. [README.md](README.md) (10 min)
2. [POC_DISTRIBUTED_NODE_NETWORK.md](POC_DISTRIBUTED_NODE_NETWORK.md) (90 min)
3. [NODE_REGISTRY_SERVICE_ARCHITECTURE.md](NODE_REGISTRY_SERVICE_ARCHITECTURE.md) (80 min)

**Week 3-4 Reading (before coding registry)**:
- [NODE_REGISTRY_SERVICE_ARCHITECTURE.md](NODE_REGISTRY_SERVICE_ARCHITECTURE.md) (deep dive)
- [TRUST_SYSTEM.md](TRUST_SYSTEM.md) (reputation logic)

**Week 5+ Reading**:
- [TRUST_SYSTEM.md](TRUST_SYSTEM.md) (reputation implementation)

**Reference Materials**:
- [APPENDIX_WEB3_GLOSSARY.md](APPENDIX_WEB3_GLOSSARY.md) (terminology)
- [TECHNICAL_ARCHITECTURE.md](TECHNICAL_ARCHITECTURE.md) (future vision)

---

### 📊 Business Person (Funding/Strategy)

**Reading (4 hours)**:
1. [README.md](README.md) (10 min)
2. [COST_ANALYSIS.md](COST_ANALYSIS.md) (60 min)
3. [FUNDING_STRATEGY.md](FUNDING_STRATEGY.md) (40 min)
4. [MARKET_OPPORTUNITIES.md](MARKET_OPPORTUNITIES.md) (40 min)
5. [APPENDIX_WEB3_GLOSSARY.md](APPENDIX_WEB3_GLOSSARY.md) - skim sections 1-2 (30 min)

**For Pitching**:
- [README.md](README.md) (vision)
- [COST_ANALYSIS.md](COST_ANALYSIS.md) (financials)
- [MARKET_OPPORTUNITIES.md](MARKET_OPPORTUNITIES.md) (market)
- [POC_DISTRIBUTED_NODE_NETWORK.md](POC_DISTRIBUTED_NODE_NETWORK.md) (de-risking strategy)

---

### ⚖️ Legal / Compliance

**Reading (5 hours)**:
1. [LEGAL/NDA_TEMPLATE.md](LEGAL/NDA_TEMPLATE.md) (60 min)
2. [LEGAL/IP_PROTECTION_STRATEGY.md](LEGAL/IP_PROTECTION_STRATEGY.md) (60 min)
3. [LEGAL/REGULATORY_COMPLIANCE.md](LEGAL/REGULATORY_COMPLIANCE.md) (120 min)
4. [APPENDIX_WEB3_GLOSSARY.md](APPENDIX_WEB3_GLOSSARY.md) - Legal/Financial sections (30 min)

---

### 🏗️ Architect (System Design)

**Reading (6 hours)**:
1. [README.md](README.md) (10 min)
2. [POC_DISTRIBUTED_NODE_NETWORK.md](POC_DISTRIBUTED_NODE_NETWORK.md) (90 min)
3. [NODE_REGISTRY_SERVICE_ARCHITECTURE.md](NODE_REGISTRY_SERVICE_ARCHITECTURE.md) (90 min)
4. [TECHNICAL_ARCHITECTURE.md](TECHNICAL_ARCHITECTURE.md) (120 min)
5. [WEB3_NATIVE_STRATEGY.md](WEB3_NATIVE_STRATEGY.md) (120 min)
6. [APPENDIX_WEB3_GLOSSARY.md](APPENDIX_WEB3_GLOSSARY.md) (30 min)

---

### 👥 Community Member / Investor

**Reading (2 hours)**:
1. [README.md](README.md) (10 min)
2. [MARKET_OPPORTUNITIES.md](MARKET_OPPORTUNITIES.md) (40 min)
3. [POC_DISTRIBUTED_NODE_NETWORK.md](POC_DISTRIBUTED_NODE_NETWORK.md) - Executive summary (20 min)
4. [APPENDIX_WEB3_GLOSSARY.md](APPENDIX_WEB3_GLOSSARY.md) - Skim (20 min)
5. [WEB3_NATIVE_STRATEGY.md](WEB3_NATIVE_STRATEGY.md) - Skim Phase 1 (30 min)

---

## Document Maintenance Rules

**When creating a new document**:
1. ✅ Add entry to this INDEX (with all metadata)
2. ✅ Commit INDEX + new document together
3. ✅ Update git commit message to mention index update

**Format for new entries**:
```markdown
#### DOCUMENT_NAME {#anchor}
- **Purpose**: [1 sentence describing what it is]
- **Audience**: [Who should read this]
- **Status**: ✅ Complete / ⏳ In Progress / ⚠️ Needs Review
- **Key sections**: [Main topics covered, 3-5 bullets]
- **When to read**: [When in the project lifecycle]
- **Size**: [KB or MB]
- **Relevant for**: [Which phases/weeks]
- **Last updated**: [Date]
```

---

## Quick Reference: Project Timeline

```
WEEK 1-2:   Foundation (single node) → POC
WEEK 3-4:   Registry Service → POC
WEEK 5-6:   Trust Scoring → POC
WEEK 7-8:   Network Scaling (3 nodes) → POC
WEEK 9-10:  Automation & Provisioning → POC
WEEK 11-12: Testing & Hardening → POC
├─ Ready to show friends / community ✓

WEEK 13-16: Scale to 10 nodes → POC Phase 0.5
├─ Friends running their own nodes

WEEK 17+:   Phase 1 (Add TrustCoin, blockchain, UI)
├─ See TECHNICAL_ARCHITECTURE.md
├─ See WEB3_NATIVE_STRATEGY.md
```

---

## How to Use This Index

**In VS Code?** Simply click any document name to open it. All links are clickable!

**Quick start for building POC**:
- Click [POC_DISTRIBUTED_NODE_NETWORK.md](POC_DISTRIBUTED_NODE_NETWORK.md)
- Click [NODE_REGISTRY_SERVICE_ARCHITECTURE.md](NODE_REGISTRY_SERVICE_ARCHITECTURE.md)
- Start coding!

**Need a specific document?**
- Use Ctrl+F to search by name or keyword
- Scroll through "Documents by Category"
- Check "Reading Paths by Role" for your role

**New to TrustNet?**
- Start with [Quick Navigation](#quick-navigation) at the top
- Click links in order
- Refer back to INDEX when you need something

---

**Index Version**: 1.0  
**Last Updated**: January 28, 2026  
**Maintained by**: Copilot (updated with each new document)  
**Location**: TrustNet-wip repository root
