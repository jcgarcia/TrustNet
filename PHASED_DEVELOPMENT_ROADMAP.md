# TrustNet Phased Development Roadmap

**Date**: January 28, 2026  
**Strategy**: Infrastructure-first approach (Blockchain/Crypto deferred to Phase 3)  
**Rationale**: Build core platform with traditional tech first, integrate blockchain after PMF achieved

---

## Executive Summary

Instead of attempting full blockchain + crypto + fintech simultaneously, TrustNet will:

1. **Phase 1 (Months 1-8)**: Core Infrastructure & MVP
   - User authentication & profile management
   - Trust scoring system (centralized database)
   - Payment processing (traditional: Stripe, Wise)
   - Social network basics (profiles, messaging, trust ratings)
   - Web + mobile apps
   - **Launch**: "TrustNet Finance App" (traditional fintech)

2. **Phase 2 (Months 9-14)**: Scale & Optimization
   - Scaling infrastructure for higher throughput
   - Advanced features (lending, escrow, dispute resolution)
   - Geographic expansion (EU, US, Singapore)
   - Community building & partnerships
   - **Checkpoint**: 50K+ active users, £100K+ monthly revenue

3. **Phase 3 (Months 15-24)**: Blockchain Integration
   - Smart contract development
   - TrustCoin token deployment (testnet)
   - Decentralized trust scoring
   - Community governance (DAO)
   - Gradual migration to blockchain

**Benefits**:
- Faster MVP launch (8 months vs. 14 months)
- Proven product-market fit before blockchain complexity
- Lower initial risk (traditional fintech easier to regulate)
- Easier to pivot if needed
- Blockchain becomes feature, not foundation

---

## Phase 1: Core Infrastructure & MVP (Months 1-8)

### Objective
Launch functional fintech platform with:
- User accounts & verification (KYC-lite)
- Trust scoring algorithm (centralized)
- Payment transfers (fiat-based)
- Social network basics
- Mobile + web apps
- £50-100K MRR potential

### Technology Stack (Phase 1)

**Backend:**
- Node.js + Express (API)
- PostgreSQL (user data, transactions, trust scores)
- Redis (caching, real-time notifications)
- AWS/OCI hosting (Kubernetes)
- Stripe API (payment processing)
- Wise API (international transfers)

**Frontend:**
- React (web app)
- React Native (iOS/Android)
- TypeScript
- Redux (state management)

**Infrastructure:**
- Kubernetes (container orchestration)
- Terraform (IaC)
- GitHub Actions (CI/CD)
- PostgreSQL (primary DB)
- ElasticSearch (user search)

**No blockchain components** (yet)

### Phase 1 Features

#### 1. User Management & Profiles
- Sign up / login (email + password)
- KYC verification (ID scan, address proof)
- Profile creation (name, photo, bio)
- User discovery & search
- Block/report functionality
- Cost: £60K (2 backend engineers, 1 mobile engineer)
- Timeline: Weeks 1-4

#### 2. Trust Scoring System (Centralized)
- Calculate trust score based on:
  - Payment history (on-time rate)
  - User ratings (1-5 star)
  - Community feedback
  - Account age & activity
- Score ranges: 0-100
- Monthly recalculation
- Dashboard showing score factors
- Cost: £40K (1 senior engineer, 2 weeks analysis)
- Timeline: Weeks 2-6

#### 3. Payment Processing (Fiat-Based)
- Stripe integration (card payments)
- Wise integration (international transfers)
- Bank account linking (ACH/SEPA)
- Transaction history & receipts
- Fee structure: 2-3% per transaction (revenue model)
- Cost: £80K (payment systems engineer, 4 weeks)
- Timeline: Weeks 3-8

#### 4. Social Features
- User profiles with trust score display
- Messaging between users
- Activity feed ("X sent Y £100")
- User ratings & reviews
- Cost: £60K (2 frontend engineers, 4 weeks)
- Timeline: Weeks 5-8

#### 5. Web Application (React)
- Dashboard (balance, recent activity, trust score)
- Send/receive money interface
- User directory & search
- Messages inbox
- Settings & KYC management
- Cost: £80K (2 frontend engineers, 6 weeks)
- Timeline: Weeks 3-8

#### 6. Mobile Application (React Native)
- iOS + Android from single codebase
- All web features + push notifications
- Biometric auth (fingerprint, face)
- QR code payment initiation
- Cost: £100K (2 mobile engineers, 6 weeks)
- Timeline: Weeks 5-8

#### 7. Compliance & KYC (Phase 1 Lite)
- Basic identity verification (Jumio)
- Address verification
- PEP/sanctions screening (Chainalysis lite)
- AML transaction monitoring (manual flagging initially)
- Privacy policy & terms
- Cost: £50K (compliance officer, legal review)
- Timeline: Weeks 1-4

#### 8. DevOps & Infrastructure
- Kubernetes cluster setup
- PostgreSQL database
- Redis cache
- GitHub Actions CI/CD
- Monitoring (Datadog/New Relic)
- Logging (ELK stack)
- Cost: £70K (DevOps engineer, infrastructure)
- Timeline: Weeks 1-8 (ongoing)

### Phase 1 Team (8 months)

| Role | Headcount | Cost |
|------|-----------|------|
| **Backend Engineer (Senior)** | 1 | £100K/8mo = £66K |
| **Backend Engineer (Mid)** | 1 | £70K/8mo = £47K |
| **Mobile Engineer (Senior)** | 1 | £90K/8mo = £60K |
| **Mobile Engineer (Mid)** | 1 | £65K/8mo = £43K |
| **Frontend Engineer** | 2 | £140K/8mo = £93K |
| **DevOps Engineer** | 1 | £80K/8mo = £53K |
| **Product Manager** | 1 | £70K/8mo = £47K |
| **Compliance Officer** | 1 (part-time) | £40K/8mo = £27K |
| **QA Engineer** | 1 | £50K/8mo = £33K |
| **Designer (UX/UI)** | 1 | £60K/8mo = £40K |

**Total Team Cost**: £509K (8 months)

### Phase 1 Expenses

| Category | Cost |
|----------|------|
| **Salaries** | £509K |
| **Infrastructure** | £40K (AWS/OCI, CDN) |
| **Third-party APIs** | £20K (Stripe, Wise, KYC vendors) |
| **Legal & Compliance** | £50K (FCA pre-registration, legal review) |
| **Security & Testing** | £30K (penetration testing, code audit) |
| **Marketing & Launch** | £50K (website, social media, beta user acquisition) |
| **Buffer (10%)** | £73K |

**Total Phase 1 Cost**: **£772K**

### Phase 1 Timeline

```
WEEK 1-2:      Setup, Infrastructure, KYC planning
WEEK 3-4:      Backend API foundation, User management
WEEK 5-6:      Payment integration (Stripe, Wise)
WEEK 7-8:      Trust scoring algorithm (centralized)
WEEK 9-12:     Web app (React) development
WEEK 13-16:    Mobile app (React Native) development
WEEK 17-24:    Integration, testing, bug fixes, optimization
WEEK 25-28:    Beta testing (internal + 100 external users)
WEEK 29-32:    Final QA, security audit, compliance prep
WEEK 33-35:    Public launch (testnet phase)
```

**Phase 1 Completion**: Month 8 (end of week 32)

### Phase 1 Success Metrics

| Metric | Target |
|--------|--------|
| **Users** | 5,000+ (beta) → 10,000+ at launch |
| **Daily Active Users** | 500+ at launch |
| **Transactions/Day** | 100+ at launch |
| **Monthly Recurring Revenue** | £5-10K at launch |
| **App Store Rating** | 4.0+ stars |
| **Uptime** | 99.5%+ |
| **Payment Success Rate** | 98%+ |
| **User Satisfaction** | NPS 40+ |

---

## Phase 2: Scale & Geographic Expansion (Months 9-14)

### Objective
Scale Phase 1 to multi-region operation with:
- 50K+ active users
- £100K+ monthly revenue
- EU + US + SG presence
- Regulatory approvals (FCA, MiCA, FinCEN)
- Advanced features (lending, escrow)

### Phase 2 Features

#### 1. Lending/Credit System
- Peer-to-peer lending (with collateral)
- Escrow for transactions
- Default insurance (bought from third-party)
- Interest rates (5-15% based on trust score)
- Cost: £80K
- Timeline: Weeks 5-14

#### 2. Dispute Resolution
- Built-in arbitration system
- Community arbiters (trust score 80+)
- Dispute timeline: 14 days
- Appeal process
- Cost: £40K
- Timeline: Weeks 5-10

#### 3. Regulatory Compliance (Full)
- FCA authorization (UK)
- MiCA compliance (EU)
- FinCEN MSB registration (US)
- AML/KYC at enterprise scale
- Compliance monitoring dashboards
- Cost: £400K (regulatory team + legal)
- Timeline: Months 1-6

#### 4. Geographic Expansion
- EU deployment (Dublin data center)
- US deployment (AWS us-east)
- Singapore deployment (OCI SG region)
- Localization (currencies, languages)
- Compliance by region
- Cost: £150K (ops + localization)
- Timeline: Months 2-5

#### 5. Advanced Features
- Recurring payments (subscriptions)
- Bill splitting
- Group payments
- Notifications & alerts
- Advanced analytics dashboard
- Cost: £100K
- Timeline: Weeks 5-12

#### 6. Security Hardening
- Penetration testing (comprehensive)
- Bug bounty program
- Security audit (third-party)
- Incident response plan
- Cost: £80K
- Timeline: Weeks 1-8

#### 7. Community Features
- Referral program (10% commission)
- Ambassador program (free accounts)
- Community forum (discourse)
- User feedback system
- Cost: £50K
- Timeline: Weeks 8-14

### Phase 2 Team Addition

| Role | Headcount | Duration |
|------|-----------|----------|
| **Compliance Manager** | 1 | Full 6 months |
| **Backend Engineer (Senior)** | 1 | Full 6 months |
| **Frontend Engineer** | 1 | Full 6 months |
| **DevOps/SRE** | 1 | Full 6 months |
| **Security Engineer** | 1 | Full 6 months |
| **Product Manager** | 1 | Full 6 months |
| **Community Manager** | 1 | Full 6 months |

**Phase 2 Team Cost**: £600K (6 months)

### Phase 2 Expenses

| Category | Cost |
|----------|------|
| **Salaries** | £600K |
| **Regulatory/Legal** | £400K (FCA, MiCA, FinCEN approvals) |
| **Infrastructure** | £100K (multi-region setup) |
| **Compliance Software** | £80K (monitoring, reporting) |
| **Security** | £80K (audit, testing, bounty) |
| **Marketing** | £100K (geographic launch campaigns) |
| **Contingency (10%)** | £136K |

**Total Phase 2 Cost**: **£1,496K**

### Phase 2 Timeline

```
MONTH 9:       FCA/MiCA/FinCEN applications
MONTH 10:      EU/US/SG infrastructure setup, regulatory review
MONTH 11-12:   Feature development (lending, escrow, disputes)
MONTH 13:      Regulatory approvals (expected)
MONTH 14:      Multi-region launch, marketing push
```

### Phase 2 Success Metrics

| Metric | Target |
|--------|--------|
| **Total Users** | 50,000+ |
| **Daily Active Users** | 10,000+ |
| **Monthly Transactions** | 50,000+ |
| **Monthly Revenue** | £100,000+ |
| **Geographic Coverage** | UK, EU, US, Singapore |
| **Regulatory Status** | Licensed in 4+ jurisdictions |
| **Customer Satisfaction** | NPS 50+ |

---

## Phase 3: Blockchain Integration (Months 15-24)

### Objective
Integrate blockchain layer while maintaining functional traditional fintech:
- TrustCoin token deployment (testnet)
- Decentralized trust scoring (hybrid)
- Smart contracts for escrow/lending
- Community governance (DAO)
- Gradual blockchain migration

### Phase 3 Blockchain Components

#### 1. Smart Contract Development
- Identity Registry contract
- Trust Scoring contract (hybrid)
- TrustCoin ERC-20 contract
- Payment Escrow contract
- Governance DAO contract
- Token Bridge contract
- Cost: £200K (2 senior smart contract engineers)
- Timeline: Months 1-4

#### 2. TrustCoin Token Deployment
- Testnet deployment (Goerli testnet)
- Public testnet (4-6 months)
- Mainnet deployment with 50 validators
- Tokenomics:
  - Total supply: 1 billion TrustCoin
  - Distribution: 20% team, 30% community, 20% treasury, 30% future
  - Launch price: £0.01
- Cost: £150K (development + security audit)
- Timeline: Months 6-10

#### 3. Blockchain Infrastructure
- Tendermint node setup (50 validator network)
- IPFS integration (decentralized storage)
- Oracle integration (for real-world data)
- Cross-chain bridge (Ethereum, Polygon)
- Cost: £100K (infrastructure + DevOps)
- Timeline: Months 2-8

#### 4. Hybrid Trust System
- Migrate trust scoring to blockchain (gradual)
- Hybrid period (6 months): Centralized + blockchain in parallel
- Community voting on trust score changes
- Immutable trust audit trail
- Cost: £80K (1 senior engineer)
- Timeline: Months 8-14

#### 5. Governance DAO
- Proposal voting (on-chain)
- Token-weighted voting (1 TrustCoin = 1 vote)
- Multi-sig treasury (5 of 7 signers)
- Community proposals for:
  - Fee adjustments
  - New features
  - Policy changes
  - Dispute resolution
- Cost: £60K (governance structures)
- Timeline: Months 10-16

#### 6. Decentralized Escrow
- Smart contracts handle custody (instead of company)
- Multi-sig release of funds (buyer/seller both sign)
- Automated dispute resolution (voting)
- Insurance mechanism (community-backed)
- Cost: £80K (contract development)
- Timeline: Months 4-10

#### 7. Migration Path (Users)
- Opt-in blockchain features (Phase 1)
- Gradual wallet integration
- 2-year window: Choose centralized or blockchain
- No forced migration
- Cost: £50K (education + support)
- Timeline: Months 12-24

### Phase 3 Team

| Role | Headcount | Duration |
|------|-----------|----------|
| **Smart Contract Engineer (Senior)** | 2 | Full 10 months |
| **Blockchain Architect** | 1 | Full 10 months |
| **DevOps (Blockchain)** | 1 | Full 10 months |
| **Security Auditor** | 1 (contract) | 4 months |
| **Community Manager** | 1 | Full 10 months |
| **Product Manager** | 1 | Full 10 months |

**Phase 3 Team Cost**: £700K (10 months)

### Phase 3 Expenses

| Category | Cost |
|----------|------|
| **Salaries** | £700K |
| **Smart Contract Audit** | £100K (2 audits: testnet + mainnet) |
| **Blockchain Infrastructure** | £150K (validator nodes, IPFS, oracles) |
| **Regulatory (Blockchain)** | £100K (token legal review, MiCA compliance) |
| **Security** | £80K (penetration testing, code review) |
| **Community Incentives** | £100K (ambassador program, beta testers) |
| **Contingency (10%)** | £133K |

**Total Phase 3 Cost**: **£1,363K**

### Phase 3 Timeline

```
MONTH 15-16:   Smart contract development (identity, trust)
MONTH 17-18:   Testnet deployment, community testing
MONTH 19-20:   Security audit, mainnet prep
MONTH 21-22:   TrustCoin public sale, validator recruitment
MONTH 23-24:   Mainnet launch, gradual user migration
```

### Phase 3 Success Metrics

| Metric | Target |
|--------|--------|
| **Testnet Users** | 10,000+ |
| **Mainnet Validators** | 50+ |
| **TrustCoin Market Cap** | £50M+ |
| **Decentralized Users** | 20% of total by end of Phase 3 |
| **DAO Proposals** | 50+ community proposals |
| **Community Participation** | 5,000+ token holders voting |

---

## Total Project Budget

| Phase | Duration | Cost | Cumulative |
|-------|----------|------|-----------|
| **Phase 1** | 8 months | £772K | £772K |
| **Phase 2** | 6 months | £1,496K | £2,268K |
| **Phase 3** | 10 months | £1,363K | £3,631K |

**Grand Total (24 months)**: **£3,631K** (vs. £2,268K seed available)

**Funding Plan**:
- **Seed Round (£2.75M)**: Covers Phase 1 + most of Phase 2
- **Series A (£2M)**: Covers Phase 3 + scaling operations
- **Token Pre-sale (£400K)**: Additional runway for Phase 2-3

**Adjusted Seed Allocation**:
- Phase 1: £772K (28%)
- Phase 2 partial: £1,496K (54%)
- Legal/Regulatory: £250K (9%)
- Marketing/Launch: £250K (9%)

**Total**: £2.75M ✓

---

## Key Advantages of This Phased Approach

### 1. **De-Risk Product**
- Prove product-market fit with traditional fintech first
- Validate trust scoring algorithm with real users
- Blockchain becomes enhancement, not requirement

### 2. **Faster MVP Launch**
- 8 months to launch vs. 14+ months if blockchain-first
- 10K users in 8 months (achievable for fintech)
- Revenue generation from month 8 (2-3% transaction fees)

### 3. **Easier Regulatory Approval**
- FCA approves traditional fintech faster than crypto
- Blockchain layer comes after regulatory foundation
- Reduces regulatory risk during early growth

### 4. **Team Efficiency**
- Phase 1: Small team (10 people)
- Phase 2: Add compliance/DevOps (7 more)
- Phase 3: Add blockchain specialists (6 more)
- Avoids early blockchain complexity

### 5. **Clearer Investor Story**
- "We're Stripe for underserved communities"
- Crypto is roadmap item, not core dependency
- VCs more comfortable funding fintech than crypto projects
- Token sale (Phase 3) funds blockchain layer naturally

### 6. **Pivot-Friendly**
- If market rejects cryptocurrency, still viable fintech
- Can raise Series A without blockchain component
- Blockchain becomes optional value-add

### 7. **Revenue Sooner**
- Phase 1: £5-10K MRR (transaction fees)
- Phase 2: £100K+ MRR (50K users × £2/month avg)
- Phase 3: Token revenue + governance fees
- Reduces future funding needs

---

## Comparison: Blockchain-First vs. Infrastructure-First

| Factor | Blockchain-First | Infrastructure-First (Recommended) |
|--------|------------------|---|
| **MVP Timeline** | 14+ months | 8 months ✓ |
| **Team Size (initial)** | 20+ people | 10 people ✓ |
| **Regulatory Ease** | Hard (FinCEN rules) | Easy ✓ |
| **Revenue Timeline** | 18+ months | 8 months ✓ |
| **Technical Risk** | High (new blockchain) | Medium ✓ |
| **Market Risk** | High (unproven) | Low ✓ |
| **VC Appeal** | Medium | High ✓ |
| **Pivot Flexibility** | Low | High ✓ |

---

## Next Steps

### Month 1-2:
1. Finalize seed funding (£2.75M target)
2. Hire Phase 1 team (10 people)
3. Begin infrastructure setup
4. Start FCA pre-registration discussions

### Month 3:
1. Begin Phase 1 development
2. Launch marketing for beta recruitment
3. Regulatory applications submitted

### Month 8:
1. Public launch ("TrustNet Finance")
2. Move to Phase 2 team expansion
3. Begin FCA/MiCA approval process

### Month 14:
1. Phase 2 completion checkpoint
2. Evaluate Series A raise need
3. Begin Phase 3 blockchain planning

### Month 15+:
1. Blockchain integration begins
2. TrustCoin token development
3. Community governance setup

---

## Conclusion

**By focusing on infrastructure first and deferring blockchain to Phase 3, TrustNet:**

✅ Launches in 8 months (not 14+)  
✅ Achieves PMF with traditional fintech  
✅ Generates revenue from day 1  
✅ Reduces regulatory and technical risk  
✅ Builds investor confidence  
✅ Creates natural timeline for blockchain integration  

**Blockchain becomes a powerful feature that enhances an already-successful product, rather than a foundation that must work perfectly before launch.**

---

**Document prepared**: January 28, 2026  
**Next review**: After seed funding secured  
**Ownership**: Product & Strategy team
