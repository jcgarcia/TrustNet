# TrustNet - Trust System Deep Dive

---

## Trust Score Overview

Trust is the foundation of TrustNet. Unlike traditional reputation systems, trust scores are:
- **Earned through consistent behavior**
- **Lost through violations**
- **Determined by users, not algorithms**
- **Immutable and transparent**
- **Tied to real-world identity**

---

## Trust Score Components

### Base Score: 100/100
Every new verified user starts with maximum trust. This reflects our belief that people are trustworthy until proven otherwise.

```
Initial State:
- Account Created: Day 0
- Email Verified: ✓
- Phone Verified: ✓
- KYC Completed: ✓
- Identity Confirmed: ✓
- Trust Score: 100/100
```

---

## Trust Score Formula

```
TrustScore(User) = BaseScore + ActivityDelta + CommunityDelta + TimeBonus - Penalties

Where:

BaseScore = 100 (constant)

ActivityDelta = Sum of:
  - Successful transactions: +0.5 per transaction (max +50)
  - Completed escrows: +1 per escrow (max +20)
  - On-time payments: +1 per payment (max +15)
  - Dispute resolution (won): +5 per case (max +25)
  - Failed transactions: -5 per failure
  - Chargebacks: -10 per chargeback

CommunityDelta = Sum of:
  - Upvotes on activities: +0.1 per upvote (max +10)
  - Helpful community posts: +1 per post (max +20)
  - Reports filed against user: -1 to -10 per report
  - Appeals won: +5 per appeal (max +15)
  - Community moderation decisions: -5 to -20

TimeBonus = Min(12, Months of Activity * 0.1)
  - New users: 0 bonus
  - 1 year user: +1.0 bonus
  - 10 years user: +1.2 bonus

Penalties:
  - Account closure by user: 0 (account history preserved)
  - Dispute lost: -10 to -50 depending on severity
  - Fraud detected: -50 to -100
  - Law enforcement action: -100 (possible account freeze)

Maximum = 100 (capped at start, cannot exceed)
Minimum = 0 (frozen account at this level)
```

### Trust Score Ranges

```
┌─────────────────────────────────────────────────────────────┐
│                     TRUST TIERS                             │
├─────────────────────────────────────────────────────────────┤

90-100: "EXEMPLARY"                               [██████████]
  Color: Green
  Status: Premium member
  Perks:
    ✓ All features unlocked
    ✓ 25% lower transaction fees (0.075% instead of 0.1%)
    ✓ Can serve as dispute arbiters
    ✓ Priority customer support (1h response)
    ✓ Can create private communities
    ✓ Can be featured in "Trusted Members"
    ✓ Higher daily transaction limits
    ✓ Access to beta features
  Restrictions: None

80-89: "GOOD STANDING"                            [████████  ]
  Color: Light green
  Status: Active, reliable member
  Perks:
    ✓ All features available
    ✓ Standard transaction fees (0.1%)
    ✓ Can vote in governance
    ✓ Can participate in disputes as arbiter if score > 85
    ✓ Standard support (24h response)
    ✓ Normal transaction limits
  Restrictions: None

70-79: "CAUTION"                                  [██████    ]
  Color: Yellow
  Status: Recent issues, monitor activity
  Perks:
    ✓ Basic features available
    ✓ Standard transaction fees (0.1%)
    ✓ Can still transact normally
    ✓ Can vote in governance
  Restrictions:
    ✗ Cannot serve as dispute arbiter
    ✗ Cannot create communities
    ✗ Cannot be featured
    ⚠ Subject to closer monitoring

60-69: "HIGH RISK"                                [████      ]
  Color: Orange
  Status: Significant issues, restricted access
  Perks:
    ✓ Basic features work
    ✓ Can still receive payments
  Restrictions:
    ✗ Cannot create disputes
    ✗ 25% elevated fees (0.125%)
    ✗ Daily transaction limits (max $1,000/day)
    ✗ Cannot vote in governance
    ✗ Cannot serve as arbiter
    ✗ Manual review for large transactions
    ✗ Limited to essential transactions only

<60: "SUSPENDED"                                  [██        ]
  Color: Red
  Status: Critical issues, account frozen
  Perks:
    ✓ Can receive payments
  Restrictions:
    ✗ Cannot send transactions
    ✗ Cannot access most features
    ✗ Account under investigation/review
    ✗ Must appeal to regain access
    ✗ May result in permanent account closure
```

---

## Community Trust Rating System

Beyond the automated score, users rate each other manually on a **1-10 scale**:

```
Rating Scale:
  1: "Fraudulent" (scammer, criminal)
  2: "Dishonest" (repeatedly lies)
  3: "Unreliable" (frequently defaults)
  4: "Questionable" (poor history)
  5: "Neutral" (minimal interaction)
  6: "Okay" (mostly acceptable)
  7: "Good" (reliable, honest)
  8: "Very Good" (trustworthy)
  9: "Excellent" (exemplary behavior)
  10: "Outstanding" (role model)

Rating Weight = Function of Rater's Trust Score
  - High trust raters (>85): Rating counts as 1.0x
  - Medium trust (70-85): Rating counts as 0.75x
  - Low trust (<70): Rating counts as 0.25x

Display:
  - Profile shows average rating and number of ratings
  - Last rating visible from each connection
  - Ratings older than 2 years have reduced weight
  - Can rate after interaction (transaction or dispute)
```

---

## Activities That Affect Trust

### Positive Activities

#### Transactions
```
Successful Transaction:
  - Amount: Any
  - Outcome: Completed on time
  - Impact: +0.5 to trust score
  - Frequency: Per transaction (max +50)

Example:
  User A sends $50 to User B
  → Both users complete transaction
  → Both can rate the other
  → Both gain +0.5 trust score
  → Ratings visible in profile
```

#### Dispute Resolution
```
Winning Appeal/Dispute:
  - Filed complaint: True
  - Evidence provided: Sufficient
  - Outcome: Won the case
  - Impact: +5 to +25 trust score
  - Frequency: Per dispute (capped)

Losing Appeal/Dispute:
  - Filed complaint: True
  - Evidence provided: Insufficient
  - Outcome: Lost the case
  - Impact: -5 to -50 trust score
  - Frequency: Per dispute (cumulative)
```

#### Community Contributions
```
Helpful Post/Comment:
  - Content: Educational, valuable
  - Upvotes received: 10+
  - Impact: +1 per 10 upvotes (max +20)
  - Frequency: Per post

Moderation/Arbitration:
  - Role: Dispute arbiter
  - Quality of decision: Both parties satisfied
  - Impact: +5 per dispute
  - Frequency: Per resolved case
```

### Negative Activities

#### Failed Transactions
```
Transaction Failure:
  - Reversal: User initiated
  - Reason: Any (non-completion)
  - Impact: -5 to trust score
  - Frequency: Per failure

Chargeback:
  - Reversal: Bank/provider initiated
  - Reason: Fraud claim or dispute
  - Impact: -10 to trust score
  - Frequency: Per chargeback
```

#### Disputes & Reports
```
Report Filed Against User:
  - Reporter: Other user
  - Type: Fraud, abuse, non-delivery
  - Severity: Low/Medium/High
  - Impact: -1 to -10 per report
  - Frequency: Cumulative

Dispute Lost:
  - Type: Payment dispute
  - Outcome: Arbiter sided with other party
  - Impact: -10 to -50
  - Frequency: Per lost dispute
```

---

## Dispute Resolution Impact on Trust

### Case Study Examples

#### Example 1: Honest Dispute (Winner)
```
Scenario:
  - Buyer purchases item for $100
  - Item never arrives
  - Buyer files dispute with evidence
  - Arbiter reviews and sides with buyer
  
Trust Impact on Buyer:
  ✓ +5 trust (won dispute with good evidence)
  ✓ Can rate seller (likely negative rating)
  
Trust Impact on Seller:
  ✗ -20 trust (lost dispute, poor conduct)
  ✗ Receives negative rating (1-3 stars)
  
Overall System Effect:
  - Trust system punishes bad behavior
  - Honest users are protected
  - Reputation reflects reality
```

#### Example 2: Fraudulent Dispute (Loser)
```
Scenario:
  - Buyer receives item in good condition
  - Buyer claims "never received"
  - Arbiter reviews and finds evidence of delivery
  - Dispute decided against buyer
  
Trust Impact on Buyer:
  ✗ -30 trust (lost frivolous dispute)
  ✗ "Fraudulent" rating likely
  
Trust Impact on Seller:
  ✓ +5 trust (won dispute legitimately)
  ✓ Receives positive rating
  
Overall System Effect:
  - Fraudsters face increasing costs
  - Honest sellers are protected
  - System self-regulates
```

#### Example 3: Successful Appeal
```
Scenario:
  - Initial dispute decided against User A
  - User A provides additional evidence
  - Appeal committee reviews new evidence
  - Appeal decided in User A's favor
  
Trust Impact on User A:
  ✓ +15 trust (overturned initial decision)
  ✓ Original -20 penalty partially reversed
  ✓ Final score impact: -5 (net)
  
Trust Impact on Arbiter (if at fault):
  ✗ -5 trust (poor initial decision)
  
Overall System Effect:
  - Appeal process corrects mistakes
  - Users get second chance if evidence supports it
  - Arbiters held accountable
```

---

## Trust Recovery

Users with low trust scores have a path to recovery:

### Recovery Process

```
Step 1: Understanding
  - Review detailed activity that led to score
  - Understand what went wrong
  - Receive guidance on improvement

Step 2: Remediation
  - Make right with affected parties (if possible)
  - Pay restitution for damages
  - Complete required training/verification

Step 3: Appeal
  - File formal appeal with new evidence
  - Community votes on appeal (if trust score <70)
  - New investigation by designated arbiter

Step 4: Verification
  - Monitor account for 30-90 days
  - Trust score gains +0.5 per clean day
  - Can return to good standing with effort

Recovery Rate:
  - Average: +1 trust per month (with good behavior)
  - Can regain from 50 to 80 in ~2.5 years
  - Fraud cases: Much harder (requires 5+ years)
```

### Appeal Process

```
Filing an Appeal:
  1. User submits formal appeal with:
     - Statement of why score is unfair
     - New evidence or context
     - Proposed resolution
  
  2. Appeal assigned to:
     - High-trust arbiter (score >90)
     - Never the original arbiter
     - From different geographic region

  3. Review process:
     - 30-day investigation
     - Community input if needed
     - New evidence validation

  4. Outcome:
     - Score increased: Appeals win ~20% of cases
     - Score unchanged: Maintained at current level
     - Score decreased: Rare but possible if fraud evident

  5. Reputation impact:
     - Successful appeal: +5 additional trust
     - Failed appeal: -2 trust (bad faith appeals punished)
```

---

## Fraud Prevention & Detection

### Detection Mechanisms

```
Automated Systems:
  - Pattern analysis: Sudden activity changes
  - Network analysis: Suspicious connection patterns
  - Statistical anomalies: Transaction amounts/frequency
  - Velocity checks: Too many rapid transactions
  - Device fingerprinting: Unusual login locations
  - IP reputation: VPN/proxy usage
  - Biometric anomalies: Unusual facial recognition

Community Reporting:
  - User reports (with evidence)
  - Peer review of reports
  - Weighted by reporter's trust score

Manual Review:
  - Complaints from high-trust users
  - Transactions over $10k
  - Multiple disputes in 30 days
  - Law enforcement requests
```

### Fraud Penalties

```
Level 1: Suspicious Activity
  - Penalty: -5 to -10
  - Action: Account monitored, user notified
  - Recovery: Possible with good behavior

Level 2: Confirmed Fraud
  - Penalty: -50 to -75
  - Action: Transaction limits applied, investigation
  - Recovery: Difficult, requires 2+ years clean activity

Level 3: Criminal Fraud
  - Penalty: -100 (account frozen)
  - Action: Law enforcement contacted, account suspended
  - Recovery: Only with legal resolution or appeal
```

---

## Trust System Governance

### User Trust Voting

```
Users can directly adjust trust scores via voting:

Vote Mechanism:
  - Any verified user can vote
  - Each user gets 1 vote per person per quarter
  - Vote weight = 0.01 points per trust level
  - Range: -0.1 to +0.1 per quarter max per user

Vote Types:
  1. Upvote (increases trust): "This person is trustworthy"
  2. Downvote (decreases trust): "This person is untrustworthy"
  3. Report (formal complaint): Filed with evidence

Safety Measures:
  - Must have interaction history with rated user
  - Cannot vote on self
  - Vote history is public
  - False reporting reduces rater's trust
  - Voting patterns monitored for abuse
```

### Governance Parameters

```
Community can vote to adjust:
  - Trust score decay rate (currently 0.1/month with inactivity)
  - Bonus multipliers for specific activities
  - Dispute arbitration requirements
  - Appeal frequency limits
  - Community rating weights

Voting Requirements:
  - 10M token holders (governance weight)
  - >50% quorum
  - 4-day voting period
  - 2-day timelock before execution
```

---

## Privacy & Trust Balance

Trust requires transparency, but users deserve privacy:

```
Public Information:
  - Account age
  - Trust score (current)
  - Number of completed transactions
  - Average community rating
  - Reputation badges

Semi-Public Information:
  - Transaction history (partner identities hidden)
  - Disputes participated in (details private)
  - Activity timeline (amounts hidden)

Private Information:
  - Transaction amounts (visible to parties only)
  - KYC data (not visible)
  - Personal identity (except for disputes)
  - Messages (encrypted end-to-end)
```

---

## Trust System Evolution

The trust system will evolve over time based on:

1. **Community Feedback**: User surveys, proposals
2. **Data Analysis**: Transaction patterns, fraud trends
3. **Regulatory Changes**: Compliance requirements
4. **Technology Advances**: Better fraud detection, privacy tech
5. **Network Effects**: More participants = more granular trust

### Planned Enhancements (Y2-Y3)

- [ ] Machine learning fraud detection
- [ ] Zero-knowledge identity verification
- [ ] Portable reputation (interoperability)
- [ ] Specialized trust metrics (merchant, lender, arbiter)
- [ ] Automatic dispute resolution (AI mediation)
- [ ] Predictive trust scoring

---

## Trust System Guarantees

We guarantee:

1. **Transparency**: All trust impacts logged and visible
2. **Fairness**: Equal rules for all users, no special treatment
3. **Appeal**: Every score can be appealed with evidence
4. **Recovery**: Path to redemption for all (except criminals)
5. **Privacy**: Personal data protected while maintaining trust
6. **No Collusion**: Voting systems resistant to gaming
7. **Accountability**: Trust arbiters face consequences for bad decisions

---

**Trust is not given. Trust is earned. And it can be lost.** 

This system ensures that TrustNet truly becomes a network where reputation reflects reality.
