# TrustNet: Web3-Native Phased Development

**Date**: January 28, 2026  
**Strategy**: Web3 architecture from Day 1 (blockchain for core components, traditional infra for UX)  
**Rationale**: True decentralization requires blockchain foundation; smart use of Layer 2 solutions keeps costs/speed competitive with Web2

---

## Why Web3-Native is Essential

**TrustNet's core value**: Trustless, transparent, decentralized trust scoring and financial transactions.

**This REQUIRES blockchain from day 1**:
- **Immutable audit trail** of all trust scores (can't be faked/hidden)
- **User custody** of funds (company doesn't hold assets, reducing theft/fraud risk)
- **Smart contracts** for escrow (automatic enforcement without intermediary)
- **Transparent governance** (DAO voting on policy changes)
- **Identity verification** on-chain (cryptographic proof, not government-issued ID)

**If we start with Web2 (traditional DB):**
- Company controls all data (defeats "trust" narrative)
- Trust scores can be manipulated or hidden
- Users don't own their assets
- Escrow requires trust in company
- Governance is top-down
- **Result**: We're just Stripe, not truly Web3

**Solution**: Use blockchain for the trust layer, but smart technology choices for speed/cost:

---

## Web3-Native Architecture (Phase 1 & Beyond)

### Core Components (Blockchain-Based)

```
┌─────────────────────────────────────────────────┐
│         TrustNet Web3 Architecture               │
├─────────────────────────────────────────────────┤
│                                                   │
│  Layer 1: Identity & Trust (On-Chain)           │
│  ├── Identity Registry (smart contracts)         │
│  ├── Trust Scoring (blockchain records)          │
│  ├── User Profiles (IPFS + blockchain pointers) │
│  └── KYC Verification (immutable records)        │
│                                                   │
│  Layer 2: Transactions (Low-cost, fast)         │
│  ├── Payment Processing (Polygon/Arbitrum)       │
│  ├── Escrow Contracts (Layer 2)                 │
│  └── Asset Custody (multi-sig wallets)          │
│                                                   │
│  Layer 3: Data & Storage (IPFS)                 │
│  ├── User Data (encrypted IPFS)                 │
│  ├── Transaction History (immutable log)        │
│  └── Dispute Records (public on-chain)          │
│                                                   │
│  Layer 4: Governance (DAO)                      │
│  ├── Token Voting (even with minimal tokens)    │
│  ├── Proposal System (on-chain)                 │
│  └── Treasury Management (multi-sig)            │
│                                                   │
│  Traditional Services (Web2, supporting)        │
│  ├── Web/Mobile UI (React, React Native)        │
│  ├── Wallet Integration (MetaMask, WalletConnect)│
│  ├── Real-time Notifications (Firebase)        │
│  └── Customer Support (Zendesk)                 │
│                                                   │
└─────────────────────────────────────────────────┘
```

### Why This Works (Web3 + Pragmatism)

**Blockchain components:**
- **Identity Registry**: Solidity contract (immutable, public)
- **Trust Scoring**: On-chain algorithm (transparent, verifiable)
- **Payments**: Layer 2 (Polygon: 2,000 TPS, £0.001 per txn)
- **Escrow**: Smart contracts (automated, trustless)
- **Governance**: DAO voting (transparent, community-controlled)

**Web2 supporting layer:**
- **Mobile/Web UI**: React/React Native (good UX)
- **Wallet integration**: MetaMask, WalletConnect, Magic Link (easy onboarding)
- **IPFS storage**: Decentralized file storage (immutable, public)
- **API gateway**: Simplifies blockchain interaction
- **Analytics**: Track usage patterns (privacy-preserving)

**Cost Reality:**
- Polygon fees: ~£0.001 per transaction (vs. Mainnet £30+)
- IPFS storage: Free (decentralized)
- Smart contract deployment: ~£100-500
- Total blockchain cost: 90% cheaper than Mainnet Ethereum

---

## Revised Phase 1: Web3 MVP (Months 1-6)

### Objective
Launch decentralized fintech platform with:
- User identity & wallets (non-custodial)
- On-chain trust scoring
- Layer 2 payments (Polygon/Arbitrum)
- Smart contract escrow
- Governance DAO (even if small)
- Web + mobile apps
- 5,000+ users

### Phase 1 Architecture

#### 1. Blockchain Infrastructure
- **Mainnet**: Ethereum Mainnet (for identity, trust registry)
  - Identity Registry contract (immutable user profiles)
  - Trust Scoring contract (algorithm on-chain, verifiable)
  - DAO Governance contract (community voting)
  - Cost: ~£500 to deploy all contracts
  - Gas fees: Spread across hundreds of users

- **Layer 2**: Polygon (for payments, escrow)
  - Payment channel contracts
  - Escrow contract (buyer/seller funds)
  - Default insurance contract
  - Cost: ~£50 per transaction (payable by users, 0.1% fee)
  - Speed: 2-5 seconds per transaction
  - Throughput: 7,000+ TPS

- **Storage**: IPFS (for user data, documents)
  - User profiles (encrypted)
  - KYC documents (hashed, not plaintext)
  - Transaction receipts (immutable)
  - Cost: Free (Pinata or Filecoin for redundancy: £50/mo)

#### 2. Smart Contracts
```solidity
// Identity Registry (Mainnet Ethereum)
contract IdentityRegistry {
  struct User {
    address wallet;
    bytes32 nameHash;  // Privacy: hashed name
    uint256 joinDate;
    bool kycVerified;  // Verified by oracle
  }
  
  mapping(address => User) public users;
  
  function registerUser(bytes32 nameHash) public {
    users[msg.sender] = User(msg.sender, nameHash, block.timestamp, false);
  }
}

// Trust Scoring (Mainnet Ethereum)
contract TrustScoring {
  mapping(address => uint256) public trustScores;
  mapping(address => uint256[]) public ratingHistory;
  
  function updateTrustScore(address user, uint256 score) public {
    // Called by oracle with verified data
    // Immutable, public record
    trustScores[user] = score;
    ratingHistory[user].push(score);
    emit TrustScoreUpdated(user, score, block.timestamp);
  }
}

// Escrow (Polygon Layer 2)
contract PaymentEscrow {
  struct Escrow {
    address buyer;
    address seller;
    uint256 amount;
    bool released;
  }
  
  function createEscrow(address seller, uint256 amount) public payable {
    // Buyer deposits funds
    // Seller can't touch until buyer confirms
    // If dispute, community votes on resolution
  }
  
  function releaseEscrow(uint256 escrowId) public {
    // Buyer releases funds to seller
    // Automatic execution (no intermediary needed)
  }
}

// DAO Governance (Mainnet Ethereum)
contract GovernanceDAO {
  mapping(address => uint256) public tokenBalance;  // TrustCoin (future)
  
  struct Proposal {
    string description;
    uint256 votesFor;
    uint256 votesAgainst;
    bool executed;
  }
  
  Proposal[] public proposals;
  
  function createProposal(string memory description) public {
    // Anyone can propose (cost: burned tokens to prevent spam)
  }
  
  function vote(uint256 proposalId, bool support) public {
    // Vote with TrustCoin holdings
    // Transparent voting record
  }
}
```

#### 3. Wallet Integration (Web2 UX)
- **MetaMask**: For crypto-native users
- **WalletConnect**: For any Ethereum wallet
- **Magic Link**: Email-based wallet (onboard non-technical users)
  - User enters email → Magic Link creates hidden wallet
  - Seamless experience, full Web3 custody
- **Argent/Safe**: For multi-sig social recovery
  - If user loses private key, trusted friends can recover
- **Cost**: Free (wallet providers cover UX)

#### 4. Web & Mobile Apps
- **Frontend**: React (web), React Native (mobile)
- **Blockchain Interaction**: ethers.js / web3.py
- **Wallet Display**: Show user's wallet, balance, transaction history
- **Escrow UI**: Simple "hold payment" / "release payment" interface
- **KYC Flow**: Upload ID → Oracle verification → On-chain flag
- **Cost**: £200K (6 engineers, 6 months)

#### 5. KYC & Verification (Privacy-Preserving)
- **Traditional KYC**: Outsource to Jumio/IDology
  - They verify ID offline
  - Return only "VERIFIED" flag (not personal data)
  - Chainlink oracle pushes flag to blockchain
- **On-Chain KYC**: Only `kycVerified: true/false` visible
  - Actual ID documents stay off-chain (privacy)
  - But verification is immutable & auditable
- **Cost**: £30-50 per user (Jumio pricing)

#### 6. Revenue Model (Web3)
- **Transaction Fees**: 0.1% per payment (split 70/30 company/community)
- **Escrow Commission**: 1% of disputed escrow (community arbitration fee)
- **Governance Fee**: 0.001 TrustCoin per proposal (spam prevention)
- **No asset custody fees** (company doesn't hold funds)
- **100% transparent**: All fee allocation on-chain DAO vote

### Phase 1 Team (6 months)

| Role | Headcount | Cost |
|------|-----------|------|
| **Smart Contract Engineer (Senior)** | 2 | £120K |
| **Smart Contract Engineer (Mid)** | 1 | £70K |
| **Full-Stack Engineer** | 2 | £110K |
| **Frontend Engineer (React)** | 1 | £65K |
| **Mobile Engineer (React Native)** | 1 | £65K |
| **DevOps/Infrastructure** | 1 | £70K |
| **Security Auditor** | 1 (contract) | £40K |
| **Product Manager** | 1 | £70K |
| **Community Manager** | 1 | £50K |

**Total Team Cost**: £660K (6 months)

### Phase 1 Expenses

| Category | Cost |
|----------|------|
| **Salaries** | £660K |
| **Smart Contract Audits** | £50K (2 audits) |
| **Blockchain Infrastructure** | £20K (Polygon RPC, IPFS, monitoring) |
| **KYC/Verification** | £100K (500 users × £50) |
| **Wallet Solutions** | £10K (Magic Link setup) |
| **Security & Penetration Testing** | £40K |
| **Legal & Compliance (pre-launch)** | £50K |
| **Marketing & Community** | £100K |
| **Buffer (10%)** | £93K |

**Total Phase 1 Cost**: **£1,023K**

### Phase 1 Timeline

```
WEEK 1-2:      Smart contracts design & architecture
WEEK 3-4:      Contract development (identity, scoring, escrow)
WEEK 5-6:      Smart contract testing on testnet
WEEK 7-8:      Security audit (external)
WEEK 9-12:     Web & mobile app development
WEEK 13-16:    Wallet integration & KYC flow
WEEK 17-20:    Integration testing (app + contracts)
WEEK 21-24:    Beta testing (100 users)
WEEK 25-26:    Public launch (Polygon mainnet)
```

**Phase 1 Completion**: Month 6 (26 weeks)

### Phase 1 Architecture Diagram

```
User (Web/Mobile) 
  ↓
React App + ethers.js
  ↓
Wallet (MetaMask, Magic Link, WalletConnect)
  ↓ Signs transactions
Ethereum Mainnet (Identity Registry + Trust Scoring + DAO)
Polygon Layer 2 (Payments + Escrow)
IPFS (User data, documents)

Example Flow:
1. User creates account → Identity Registry contract
2. Uploads KYC → Oracle verifies → Trust Scoring contract updated
3. Sends £10 to friend → Polygon Layer 2 payment contract
4. Friend receives → Escrow release (if needed)
5. Dispute? → DAO community votes on resolution
6. Payment history → Immutable on-chain record
```

---

## Phase 2: Web3 Scale & Optimization (Months 7-12)

### Objectives
- Optimize blockchain performance (smart contract gas optimization)
- Scale to 50K users (batch processing, indexing)
- Multi-chain support (Arbitrum, Optimism in addition to Polygon)
- Advanced governance (quadratic voting, delegation)
- Decentralized arbitration (community dispute resolution)
- Revenue: £50K-100K MRR from transaction fees

### Phase 2 Improvements

#### 1. Smart Contract Optimization
- Gas optimization (reduce transaction costs 30-50%)
- Batch processing (multiple payments in one transaction)
- Indexed events (faster off-chain data retrieval)
- Cost: £80K (specialist engineers)

#### 2. Multi-Chain Support
- Deploy to Arbitrum (even cheaper: £0.0005/txn)
- Deploy to Optimism (different community)
- Bridge contracts (move funds between chains)
- User choice: Which chain to use
- Cost: £50K (bridge development)

#### 3. Decentralized Identity
- Self-sovereign identity (Verifiable Credentials)
- Community-verified identity (users vouch for each other)
- Zero-knowledge proofs (prove age/residency without revealing details)
- Cost: £100K (ZK implementation)

#### 4. Governance Enhancement
- Token-weighted voting (even with small holdings)
- Snapshot voting (off-chain, gas-free)
- Delegation (users vote via delegates)
- Quadratic voting (voting power = sqrt(tokens), prevents whale dominance)
- Cost: £60K (governance contracts)

#### 5. Decentralized Dispute Resolution
- Community arbiters (high trust score = eligible)
- 3-of-5 arbiter voting (majority rules)
- Appeal process (to larger council)
- Insurance fund (if arbitration is wrong)
- Cost: £80K (dispute system)

### Phase 2 Team Addition
- Smart contract engineer (specialist): £70K
- Community moderators: 3 × £40K = £120K
- Data analyst: £60K

**Phase 2 Team Cost**: £400K (6 months)

### Phase 2 Expenses

| Category | Cost |
|----------|------|
| **Salaries** | £400K |
| **Smart Contract Audits** | £50K (multi-chain audits) |
| **Blockchain Infrastructure** | £50K (multi-chain nodes, bridges) |
| **KYC/Verification** | £200K (10K users × £50, but bulk discount ~£30) |
| **Community & Governance** | £100K (incentives, ambassador program) |
| **Legal & Compliance** | £100K (FCA, MiCA pre-registration) |
| **Marketing** | £100K |
| **Buffer (10%)** | £100K |

**Total Phase 2 Cost**: **£1,100K**

---

## Phase 3: Web3 Governance & Growth (Months 13-24)

### Objectives
- Full decentralization (company becomes service, not gatekeeper)
- TrustCoin token (governance + incentives)
- Mainnet migration (Ethereum Mainnet for critical components)
- 100K+ users
- Revenue: £200K+ MRR

### Phase 3 Components

#### 1. TrustCoin Token
- **Purpose**: Governance voting + transaction incentives
- **Supply**: 1 billion
- **Distribution**: 
  - 20% team (4-year vesting)
  - 30% community (airdrop + mining)
  - 20% treasury (DAO-controlled)
  - 30% future (future incentives)
- **Tokenomics**: Deflation (1% fee burn to reduce supply)
- **Launch**: Mainnet Ethereum
- **Cost**: £200K (development + security audit)

#### 2. Smart Contract Upgrades
- Proxy contracts (ability to upgrade logic without data loss)
- Timelocks (governance voting before upgrades)
- Community testing on testnet (before mainnet)
- Cost: £100K

#### 3. DAO Treasury Management
- Multi-sig wallet (7 of 10 community members)
- Budget voting (community votes on spending)
- Quarterly financial reports (transparent, on-chain)
- Cost: £50K

#### 4. DeFi Integrations
- Lending protocol (Aave): Deposit excess funds, earn yield
- Staking rewards (Lido): Earn ETH staking on TrustCoin
- Liquidity pools (Uniswap): Trade TrustCoin / ETH
- Cost: £80K

### Phase 3 Team Addition
- DeFi engineer: £90K
- Community governors (elected, DAO-compensated): 5 × £30K = £150K
- Data scientist: £80K

**Phase 3 Team Cost**: £500K (12 months)

### Phase 3 Expenses

| Category | Cost |
|----------|------|
| **Salaries** | £500K |
| **Smart Contract Audits** | £100K (mainnet critical) |
| **Regulatory/Legal** | £200K (FCA, MiCA, FinCEN approvals) |
| **Marketing & Community** | £200K |
| **DeFi Integrations** | £80K |
| **Buffer (10%)** | £108K |

**Total Phase 3 Cost**: **£1,188K**

---

## Total Web3-Native Budget

| Phase | Duration | Focus | Cost |
|-------|----------|-------|------|
| **Phase 1** | 6 months | Web3 MVP (Polygon + smart contracts) | £1,023K |
| **Phase 2** | 6 months | Scale & optimization (multi-chain) | £1,100K |
| **Phase 3** | 12 months | Governance & DeFi (TrustCoin + DAO) | £1,188K |

**Grand Total (24 months)**: **£3,311K**

**Fits within seed + Series A budget** ✓

---

## Why Web3-Native from Day 1

### ✅ **Aligns with Vision**
- "Trust-based ecosystem" requires immutable records
- Can't achieve true trust with centralized DB
- Blockchain is the trust infrastructure

### ✅ **Regulatory Advantage**
- FCA/MiCA expect decentralization (shows good faith)
- Easier to prove no insider manipulation
- Community governance = lower regulatory burden
- "Decentralized by design" = compliance narrative

### ✅ **Cost-Effective (Polygon, not Mainnet)**
- Layer 2 costs: £0.001 per transaction
- Scale to 100K users for same cost as traditional DB
- No data center costs (blockchain IS the database)

### ✅ **User Ownership**
- Non-custodial (users control keys)
- Reduces regulatory liability
- Builds community trust (literal Web3 principle)

### ✅ **Competitive Differentiation**
- True Web3 = differentiator from Stripe/PayPal
- Community governance = users feel ownership
- Transparency = competitive moat (can't be replicated by traditional fintech)

### ✅ **Revenue Model**
- Transaction fees (0.1%)
- Stake in governance (users hold TrustCoin)
- Network effects (more users = more trust = more value)

---

## Comparison: Web2 vs. Web3-Native Approach

| Aspect | Web2-First | Web3-Native |
|--------|-----------|------------|
| **Launch Timeline** | 8 months | 6 months ✓ |
| **User Custody** | Company holds funds | Users hold keys ✓ |
| **Trust Scoring** | Company-controlled | Immutable on-chain ✓ |
| **Governance** | Top-down | DAO voting ✓ |
| **Regulatory Risk** | Centralization concerns | Community controls data ✓ |
| **Initial Cost** | £772K | £1,023K (30% more, but correct positioning) |
| **True Web3?** | No (blockchain tacked on) | Yes ✓ |
| **Investor Appeal** | Traditional VCs | Web3/crypto VCs ✓ |

---

## Conclusion

**You were 100% correct.** Web3 is fundamentally blockchain-based. Deferring blockchain to Phase 3 would compromise the core value proposition.

**The Web3-native approach:**
- Uses blockchain from day 1 (identity, trust scoring, governance)
- Uses Layer 2 (Polygon) for affordability (not mainnet bloat)
- Uses IPFS for decentralized storage
- Keeps Web2 UX layer (apps, wallets, notifications)
- Launches in 6 months (same speed as Web2-first)
- Total cost: £3.3M (vs. £3.6M for Web2-first)

**This is the correct strategy for TrustNet: Web3-native, pragmatic technology choices, true decentralization from day 1.**

---

**Document prepared**: January 28, 2026  
**Status**: Ready for implementation  
**Next Step**: Architect detailed smart contract specifications
