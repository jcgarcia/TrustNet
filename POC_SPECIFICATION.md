# TrustNet Proof of Concept (POC) Specification

**Date**: January 28, 2026  
**Purpose**: Validate Web3 architecture, smart contracts, and user flows before full Phase 1 build  
**Status**: Pre-development planning

---

## Executive Summary

**POC Objective**: Prove TrustNet's core Web3 technology works and has product-market fit

**Scope**: Minimal but functional
- Smart contracts for identity & trust scoring
- Basic web app connecting to wallets
- Testnet payments (no real money)
- 100-500 beta users
- Real trust scoring algorithm in action

**Timeline**: 10-12 weeks (2.5-3 months)

**Cost**: £200-300K

**Outcome**: 
- Validated smart contracts
- User testimonials & feedback
- De-risked roadmap for Series A/Phase 1
- PR/marketing material ("building Web3 trust")

---

## POC vs. Phase 1: What's Different?

| Aspect | POC | Phase 1 |
|--------|-----|--------|
| **Timeline** | 10-12 weeks | 6 months |
| **Team** | 4-5 people | 9 people |
| **Cost** | £200-300K | £1,023K |
| **Users** | 100-500 beta | 5,000+ public |
| **Blockchain** | Testnet (free) | Polygon mainnet (real £) |
| **Scope** | Core features only | Full product |
| **Payment** | Fake tokens (no real £) | Real money (Polygon) |
| **KYC** | Simplified/manual | Automated (Jumio) |
| **Code Quality** | MVP (good enough) | Production (audited) |
| **Security** | Basic testing | Full audit |

---

## POC Scope: What Gets Built

### Smart Contracts (Testnet Ethereum)

#### 1. Identity Registry Contract
```solidity
pragma solidity ^0.8.0;

contract IdentityRegistry {
  struct User {
    address wallet;
    string username;
    uint256 joinDate;
    bool verified;
  }
  
  mapping(address => User) public users;
  
  function register(string memory username) public {
    require(bytes(username).length > 0);
    users[msg.sender] = User(msg.sender, username, block.timestamp, false);
    emit UserRegistered(msg.sender, username);
  }
  
  function verifyUser(address user) public onlyAdmin {
    users[user].verified = true;
    emit UserVerified(user);
  }
  
  event UserRegistered(address indexed user, string username);
  event UserVerified(address indexed user);
}
```

**What it does:**
- Users register with wallet + username
- Admin manually verifies (for POC, no automated KYC)
- On-chain record of all users (immutable)
- Cost to deploy: ~£20

#### 2. Trust Scoring Contract
```solidity
pragma solidity ^0.8.0;

contract TrustScoring {
  struct TrustRecord {
    address user;
    uint256 score;  // 0-100
    uint256 timestamp;
    string reason;  // "transaction", "review", "dispute"
  }
  
  mapping(address => uint256) public trustScores;
  mapping(address => TrustRecord[]) public trustHistory;
  
  function updateTrustScore(address user, uint256 newScore, string memory reason) 
    public onlyOracle {
    require(newScore <= 100);
    trustScores[user] = newScore;
    trustHistory[user].push(
      TrustRecord(user, newScore, block.timestamp, reason)
    );
    emit TrustScoreUpdated(user, newScore, reason);
  }
  
  function getTrustScore(address user) public view returns (uint256) {
    return trustScores[user];
  }
  
  event TrustScoreUpdated(address indexed user, uint256 newScore, string reason);
}
```

**What it does:**
- Stores trust scores (0-100) for each user
- Immutable audit trail (all changes recorded)
- Weighted by transaction history + ratings
- Transparency (anyone can verify a user's score and history)
- Cost to deploy: ~£20

#### 3. Simple Escrow Contract (Polygon Testnet)
```solidity
pragma solidity ^0.8.0;

contract SimpleEscrow {
  struct Escrow {
    address buyer;
    address seller;
    uint256 amount;
    uint256 createdAt;
    bool released;
    bool disputed;
  }
  
  Escrow[] public escrows;
  
  function createEscrow(address seller, uint256 amount) public payable {
    require(msg.value == amount);
    escrows.push(Escrow(msg.sender, seller, amount, block.timestamp, false, false));
    emit EscrowCreated(escrows.length - 1, msg.sender, seller, amount);
  }
  
  function releaseEscrow(uint256 escrowId) public {
    Escrow storage escrow = escrows[escrowId];
    require(msg.sender == escrow.buyer);
    require(!escrow.released);
    escrow.released = true;
    payable(escrow.seller).transfer(escrow.amount);
    emit EscrowReleased(escrowId);
  }
  
  event EscrowCreated(uint256 indexed id, address buyer, address seller, uint256 amount);
  event EscrowReleased(uint256 indexed id);
}
```

**What it does:**
- Buyer deposits money (held in contract)
- Buyer approves release to seller
- Money automatically transferred (no middleman)
- Dispute flag (for POC: manual resolution)
- Cost to deploy: ~£5 testnet (free)

#### 4. Simple DAO Governance Contract
```solidity
pragma solidity ^0.8.0;

contract SimpleDAO {
  struct Proposal {
    string description;
    uint256 votesFor;
    uint256 votesAgainst;
    uint256 deadline;
    bool executed;
  }
  
  Proposal[] public proposals;
  mapping(address => mapping(uint256 => bool)) public voted;
  
  function createProposal(string memory description) public {
    proposals.push(Proposal(description, 0, 0, block.timestamp + 7 days, false));
    emit ProposalCreated(proposals.length - 1, description);
  }
  
  function vote(uint256 proposalId, bool support) public {
    require(!voted[msg.sender][proposalId]);
    Proposal storage proposal = proposals[proposalId];
    if (support) {
      proposal.votesFor++;
    } else {
      proposal.votesAgainst++;
    }
    voted[msg.sender][proposalId] = true;
    emit Voted(proposalId, msg.sender, support);
  }
  
  event ProposalCreated(uint256 indexed id, string description);
  event Voted(uint256 indexed proposalId, address indexed voter, bool support);
}
```

**What it does:**
- Anyone can create a proposal
- Users vote yes/no (1 person = 1 vote for POC)
- Voting lasts 7 days
- Public record of all proposals + votes
- Cost to deploy: ~£15

### Web Application (React)

#### 1. Wallet Connection
- MetaMask integration (connect button)
- Display connected wallet address
- Show wallet balance (testnet tokens)
- Auto-detect network (Ethereum testnet)

#### 2. User Dashboard
- **Profile Card**: Username, trust score, join date
- **Trust Score Breakdown**:
  - Payment history (0-30 points)
  - User ratings (0-40 points)
  - Account age (0-20 points)
  - Activity level (0-10 points)
- **Recent Activity**: Last 10 transactions/ratings
- **Edit Profile**: Change username

#### 3. Send Money (Testnet Only)
- **Input**: Recipient username, amount (testnet ETH)
- **Flow**:
  1. User enters recipient & amount
  2. App shows "this is testnet, no real money"
  3. User confirms
  4. App calls escrow contract
  5. Transaction hash displayed
  6. Recipient gets notification
  7. Escrow created (can release after 24 hours)

#### 4. Receive Money
- **Notifications**: Alert when someone sends you money
- **Pending Escrows**: List of funds held for you
- **Release Payment**: Button to confirm receipt

#### 5. Rate User
- **Star Rating**: 1-5 stars
- **Comment**: Optional text review
- **Submit**: Updates user's trust score (via oracle)

#### 6. View Proposals
- **List**: Recent governance proposals
- **Vote**: Click yes/no (calls DAO contract)
- **Results**: Real-time vote counts

#### 7. Admin Panel (POC Only)
- Verify new users (temporarily manual)
- Update trust scores (for testing)
- Trigger contract functions

### Mobile App (React Native - Optional for POC)

If included:
- Same features as web
- WalletConnect integration (mobile wallets)
- Mobile-optimized UI
- Push notifications

**Recommended**: Start with web-only for POC, add mobile in Phase 1

### Infrastructure

**Blockchain (Free/Low-Cost)**
- Ethereum Testnet (Goerli): Free
- Polygon Testnet (Mumbai): Free
- MetaMask: Free (users provide)

**Web Hosting**
- Vercel (React hosting): £10/month
- IPFS (storage): Free (Pinata free tier)

**APIs**
- Etherscan API (testnet data): Free
- MetaMask JSON-RPC: Free

**Total Infrastructure**: ~£50/month (minimal)

---

## POC Team & Timeline

### Team (4-5 People, 10-12 Weeks)

| Role | Seniority | Hours/Week | Cost |
|------|-----------|-----------|------|
| **Smart Contract Engineer** | Senior | 40 | £100K (12 weeks) |
| **Full-Stack Developer** | Mid | 40 | £60K (12 weeks) |
| **Frontend Developer** | Mid | 40 | £60K (12 weeks) |
| **DevOps/Infrastructure** | Junior | 20 | £20K (12 weeks) |
| **Product Manager** | Mid | 20 | £25K (12 weeks) |

**Total Labor**: £265K

### Timeline (10-12 Weeks)

```
WEEK 1-2:      Smart contract design & setup
├─ Architecture review
├─ Contract specifications
├─ Testnet setup (Goerli)
├─ Development environment

WEEK 3-4:      Smart contract development
├─ Identity Registry contract
├─ Trust Scoring contract
├─ Simple Escrow contract
├─ DAO Governance contract
├─ Unit tests (hardhat)

WEEK 5:        Security & testing
├─ Internal code review
├─ Test coverage (>80%)
├─ Testnet deployment
├─ Contract verification (Etherscan)

WEEK 6-8:      Web app development
├─ MetaMask integration
├─ User dashboard
├─ Send/receive money flow
├─ Rate user interface
├─ Governance voting UI

WEEK 9-10:     Integration & testing
├─ App ↔ contracts testing
├─ Transaction flow testing
├─ Error handling
├─ Mobile responsiveness

WEEK 11-12:    Beta launch & support
├─ Deploy to Vercel
├─ Recruit 100 beta testers
├─ Monitor for bugs
├─ User feedback & iterations
```

---

## POC Expenses

| Category | Cost |
|----------|------|
| **Team (5 people, 12 weeks)** | £265K |
| **Infrastructure** | £0 (testnet free) |
| **Smart Contract Audits** | £0 (internal review only) |
| **Design & UX** | £15K (Figma, basic design) |
| **Marketing/PR** | £10K (launch announcement) |
| **Tools & Services** | £5K (Hardhat, Etherscan API keys, etc.) |
| **Contingency (10%)** | £29K |

**Total POC Cost**: **£324K**

**Or Optimized (£200K)**:
- Use existing React template (save £15K design)
- 3 people instead of 5 (PM helps engineer)
- 8 weeks instead of 12
- Minimal marketing (organic launch)

---

## POC Features (In Scope)

✅ **Smart Contracts** (testnet)
- Identity registry
- Trust scoring algorithm
- Escrow contract
- Simple DAO voting

✅ **Web App**
- Wallet connection (MetaMask)
- User dashboard
- Send/receive money (testnet)
- Rate users
- Governance voting
- View transaction history

✅ **User Flows**
- Register account
- Connect wallet
- Send testnet money
- Receive confirmation
- View trust score changes
- Vote on proposals

✅ **Verification**
- Transactions on-chain (public)
- Trust scores immutable
- Voting transparent
- Code on GitHub (open source)

---

## POC Features (Out of Scope)

❌ **KYC/Verification** (manual only, no Jumio)
❌ **Real Money** (testnet only)
❌ **Mobile App** (web-only for POC)
❌ **Multi-chain** (testnet only)
❌ **Security Audit** (internal code review only)
❌ **Scalability** (no optimization)
❌ **Advanced Governance** (1 person = 1 vote, no tokens)
❌ **DeFi Integration** (escrow only)

---

## Success Metrics for POC

| Metric | Target |
|--------|--------|
| **Code Quality** | >80% test coverage, zero critical bugs |
| **Contracts Deploy** | All 4 contracts deploy to testnet successfully |
| **Transaction Success** | 98%+ of test transactions succeed |
| **Web App Performance** | <2 second load time, Lighthouse score >80 |
| **Beta Users** | 100-500 testers sign up |
| **User Feedback** | NPS 40+ from testers |
| **Time to Transaction** | User from signup to first payment <5 minutes |
| **Documentation** | Complete smart contract docs + user guide |
| **Code Cleanliness** | Pass ESLint, Solhint, SolidityCheck |

---

## Deliverables from POC

### Code
- [ ] 4 production-ready smart contracts (testnet)
- [ ] React web app source code (GitHub)
- [ ] Full test suite (hardhat)
- [ ] Deployment scripts
- [ ] API documentation

### Documentation
- [ ] Smart contract specifications
- [ ] User flow diagrams
- [ ] Architecture diagram
- [ ] Deployment guide
- [ ] Bug report & known issues

### Data & Feedback
- [ ] 100-500 beta users
- [ ] User testimonials & quotes
- [ ] Bug reports & feature requests
- [ ] Usage analytics (which features used most)
- [ ] Trust score validation (does algorithm work?)

### Marketing Assets
- [ ] Blog post ("Building Web3 trust on testnet")
- [ ] Twitter/GitHub announcements
- [ ] Demo video (15 minutes)
- [ ] Case studies (3-5 user stories)

---

## Post-POC Options

### Option A: Proceed to Phase 1
If POC is successful:
- Lock smart contract specifications
- Hire larger Phase 1 team
- Plan for mainnet migration
- Start regulatory applications
- Timeline: 6 months to Phase 1 launch
- Cost: £1,023K

### Option B: Improve POC (Extended)
If feedback suggests improvements:
- Run POC for additional 4-8 weeks
- Add features (multi-chain, mobile)
- Additional security audit
- Expand beta to 1,000 users
- Cost: £100-150K additional

### Option C: Pivot or Abandon
If POC fails:
- Learn why (contract issues? UX? no demand?)
- Cost of failure: £324K (acceptable for de-risking)
- Pivot to different approach
- Cheaper than failing after £1M Phase 1 spend

---

## POC Risk Mitigation

| Risk | POC Mitigation |
|------|---|
| **Smart contracts don't work** | Internal audit before testnet launch |
| **No user demand** | 500 beta testers validate product-market fit |
| **Security vulnerabilities** | Code review, test coverage, bug bounty |
| **Regulatory issues** | Testnet = no regulatory approval needed |
| **Technical debt** | Fresh codebase, not reusing Phase 1 code |
| **Team churn** | Short timeline, 12 weeks, low burnout risk |

---

## Budget Comparison

| Approach | Timeline | Cost | Risk |
|----------|----------|------|------|
| **Direct to Phase 1** | 6 months | £1,023K | HIGH (unvalidated) |
| **POC First** | 3 months POC + 6 months Phase 1 | £1,347K (total) | LOW (de-risked) |
| **POC Only (Demo)** | 3 months | £324K | Medium (no mainnet) |

**Recommendation**: **POC First** costs £324K extra but de-risks £1M Phase 1 investment

---

## Funding Strategy for POC

### Option 1: Bootstrap (Fastest)
- Use seed round early deployment (£300K of £2.75M)
- Fast iteration, validate concept
- Remaining £2.45M for Phase 1

### Option 2: Small Funding Round
- Raise £500K pre-seed for POC + extended runway
- De-risk before larger Series A
- Investors love "proven by POC"

### Option 3: Strategic Partner Sponsorship
- Seek sponsorship from:
  - Polygon (grants for L2 apps)
  - Chainlink (oracle sponsorship)
  - Tendermint (Cosmos sponsorship)
- Could cover £50-100K of costs

---

## Conclusion

### POC Summary
- **Timeline**: 10-12 weeks
- **Cost**: £200-300K (optimized) to £324K (full)
- **Team**: 4-5 people
- **Outcome**: Validated Web3 architecture, de-risked Phase 1

### Why Do a POC?
✅ Prove smart contracts work  
✅ Validate product-market fit  
✅ Get real user feedback  
✅ De-risk £1M Phase 1 investment  
✅ Attract better investors ("battle-tested")  
✅ Build community early (beta testers)  

### ROI
- Cost: £324K
- Benefit: De-risks £1,023K Phase 1 (prevent failure)
- Expected ROI: 3-4x (prevent expensive mistakes)

---

**Document prepared**: January 28, 2026  
**Status**: Ready for review  
**Decision Point**: Approve POC to de-risk Phase 1?
