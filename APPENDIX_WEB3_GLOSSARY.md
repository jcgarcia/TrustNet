# TrustNet Web3 & Blockchain Terminology Glossary

**Date**: January 28, 2026  
**Purpose**: Reference guide for Web3/blockchain terminology used throughout TrustNet documentation  
**Audience**: Team members, investors, community members new to crypto/Web3

---

## Table of Contents
1. [Blockchain Fundamentals](#blockchain-fundamentals)
2. [Cryptocurrency & Tokens](#cryptocurrency--tokens)
3. [Smart Contracts & DeFi](#smart-contracts--defi)
4. [Web3 Concepts](#web3-concepts)
5. [Governance & DAOs](#governance--daos)
6. [Infrastructure & Networks](#infrastructure--networks)
7. [Security & Privacy](#security--privacy)
8. [Financial & Legal Terms](#financial--legal-terms)

---

## Blockchain Fundamentals

### Blockchain
A distributed ledger (database) where records are stored in "blocks" linked together cryptographically. Each block contains transactions that are immutable (can't be changed). No single entity controls it; thousands of computers maintain copies.

**Example**: TrustNet uses Ethereum blockchain to store identity and trust scores permanently.

### Block
A batch of transactions bundled together and added to the blockchain. Each block contains:
- Transactions (e.g., "Alice sent Bob £10")
- Timestamp (when the block was created)
- Hash (unique identifier)
- Previous block's hash (links them together)

**Block Time**: How long it takes to create a new block.
- Ethereum: ~12 seconds
- Polygon: ~2 seconds
- Bitcoin: ~10 minutes

### Ledger
A record-keeping system. Traditional ledgers are centralized (one company controls it). Blockchain is a distributed ledger (thousands of computers maintain it).

### Hash
A unique fingerprint of data. If you change even one character, the hash completely changes. Used to verify data hasn't been tampered with.

**Example**: 
```
Original: "Alice sent Bob £10" 
Hash: a3f2b9c1d4e6f8h2j9k0l1m2n3o4p5q6

If changed: "Alice sent Bob £11"
Hash: x1y2z3a4b5c6d7e8f9g0h1i2j3k4l5m6
(completely different)
```

### Immutable / Immutability
Data that cannot be changed once recorded on blockchain. TrustNet's trust scores are immutable (permanent audit trail).

### Distributed / Decentralized
Instead of one central server, data is stored on many computers (nodes) around the world. No single point of failure; no single entity controls it.

**Example**: Traditional bank (centralized): One server holds all account data.  
TrustNet (decentralized): Trust scores stored on thousands of Ethereum nodes worldwide.

### Consensus
Agreement mechanism for all nodes on what transactions are valid. Different blockchains use different consensus methods:
- **Proof of Work (PoW)**: Miners solve math puzzles (Bitcoin, Ethereum pre-2022)
- **Proof of Stake (PoS)**: Validators stake crypto to earn right to add blocks (Ethereum post-2022, Polygon)
- **Tendermint PBFT**: Byzantine Fault Tolerant consensus (TrustNet uses this)

### Node
A computer that maintains a copy of the blockchain. Nodes validate transactions and reach consensus on new blocks.

**Full Node**: Stores entire blockchain history (~350GB for Ethereum)  
**Light Node**: Stores only essential data, queries full nodes

---

## Cryptocurrency & Tokens

### Cryptocurrency
Digital money that uses cryptography for security. Examples: Bitcoin, Ethereum, TrustCoin (future).

**Key features:**
- Decentralized (no central bank)
- Secure (cryptographic)
- Fast transactions (no intermediary)
- Transparent (all transactions visible)

### Token
A digital asset representing value, stored on blockchain. Tokens are NOT currencies; they represent:
- Utility (voting rights, access to service)
- Ownership (stocks, NFTs)
- Currency (stablecoins, cryptocurrencies)

**Types:**
- **ERC-20**: Standard token (tradeable, like currency)
- **NFT**: Unique token (art, collectibles)
- **Governance Token**: Voting rights (TrustCoin)

### TrustCoin
TrustNet's native token (planned for Phase 3). 
- **Supply**: 1 billion tokens
- **Purpose**: Governance voting, transaction incentives, staking
- **Distribution**: 30% community, 20% team, 20% treasury, 30% future
- **Launch Price**: £0.01 per token (estimated)

### Stablecoin
A cryptocurrency designed to maintain stable value (e.g., £1 = 1 coin always).
- **Fiat-backed** (USDC, USDT): Backed by real pounds/dollars
- **Algorithmic**: Maintains stability through smart contracts
- **Use**: Avoid price volatility for payments

**Example**: TrustNet payments could use USDC (stable at £1) instead of volatile ETH.

### ERC-20
Ethereum standard for fungible tokens (interchangeable, like currency). All Ethereum tokens follow this standard.

**Standard functions:**
- `transfer(recipient, amount)` - Send tokens
- `approve(spender, amount)` - Allow someone to spend your tokens
- `transferFrom(from, to, amount)` - Transfer on behalf of someone

**TrustCoin will be ERC-20 standard** (allows trading on Uniswap, Aave, etc.)

### Fungible vs. Non-Fungible
- **Fungible**: Interchangeable (1 bitcoin = 1 bitcoin). Money is fungible.
- **Non-Fungible**: Unique (your passport ≠ someone else's passport). NFTs are non-fungible.

**TrustCoin**: Fungible (1 TrustCoin = 1 TrustCoin)  
**Trust Scores**: Non-fungible (Alice's score ≠ Bob's score)

### HODL
"Hold On for Dear Life" - Strategy of holding cryptocurrency long-term instead of trading. Community culture in crypto.

### Airdrop
Free tokens distributed to users/community. TrustNet plans airdrop of TrustCoin to early users.

---

## Smart Contracts & DeFi

### Smart Contract
Self-executing code on blockchain. Once deployed, it runs automatically without intermediaries.

**Logic**: "If X happens, automatically do Y"

**Example**:
```solidity
// If buyer releases escrow, automatically send funds to seller
function releaseEscrow(uint256 escrowId) public {
  require(msg.sender == buyer);
  payable(seller).transfer(amount);
}
```

**Advantages:**
- Transparent (code is visible)
- Trustless (executed automatically, no intermediary)
- Immutable (can't be changed after deployment)
- Fast (runs instantly on blockchain)

**TrustNet Smart Contracts:**
1. Identity Registry (stores user profiles)
2. Trust Scoring (calculates & stores trust scores)
3. Payment Escrow (holds funds until release)
4. DAO Governance (manages voting & treasury)

### Solidity
Programming language for writing smart contracts on Ethereum. Similar to JavaScript/Java.

**TrustNet uses Solidity** for all smart contracts.

### Contract Address
Unique identifier for a deployed smart contract on blockchain (like a bank account number).

**Example Ethereum contract address:**
```
0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984
```

Anyone can verify the contract code by looking it up on Etherscan (blockchain explorer).

### Gas
Fee paid to execute transactions on Ethereum. Different operations cost different amounts:
- Simple transfer: ~21,000 gas
- Smart contract interaction: ~50,000-200,000 gas

**Gas Price**: Cost per unit of gas (varies by network congestion)

**Mainnet**: £1-50 per transaction (expensive)  
**Layer 2 (Polygon)**: £0.001-0.01 per transaction (cheap)  
**Testnet**: Free

**TrustNet uses Polygon Layer 2** to keep gas costs low for users.

### DeFi (Decentralized Finance)
Financial services built on blockchain without traditional intermediaries.

**Services:**
- **Lending**: Deposit crypto, earn interest (Aave)
- **Trading**: Exchange tokens peer-to-peer (Uniswap)
- **Staking**: Lock crypto, earn rewards (Lido)
- **Insurance**: Decentralized insurance (Nexus Mutual)

**TrustNet includes DeFi features:**
- Escrow (trustless payments)
- Lending (peer-to-peer with collateral)
- Staking (earn TrustCoin rewards)

### Escrow
Payment held by third party until transaction conditions are met.

**Traditional**: Bank holds money from buyer, releases to seller after confirmation.

**Smart Contract Escrow**: Smart contract holds funds automatically.
```
1. Buyer deposits £10 in contract
2. Seller provides service/goods
3. Buyer clicks "release payment"
4. Contract automatically sends £10 to seller
```

**Advantage**: No intermediary needed; automatic enforcement.

### Liquidity Pool
Pool of tokens that users trade against. Enables trading on decentralized exchanges.

**Example**: Uniswap has a pool of 1 million USDC + 1 million USDT. Users trade between them. Pool creators earn fees.

### Flash Loan
Uncollateralized loan that must be repaid within same transaction. Used for arbitrage, liquidations.

### Oracle
External service that provides real-world data to smart contracts (contracts can't access internet).

**Example**: Chainlink oracle provides:
- Asset prices (USD/ETH rate)
- Weather data
- Sports scores
- Custom API data

**TrustNet uses oracles:**
- KYC verification result (is user verified? yes/no)
- Trust score updates (user received rating, update score)

---

## Web3 Concepts

### Web3
Decentralized internet built on blockchain. No intermediaries; users own their data & assets.

**Comparison:**
- **Web1 (1990s)**: Read-only internet (websites)
- **Web2 (2000s)**: Read-write internet (social media, cloud storage) - companies own data
- **Web3 (now)**: Read-write-own internet - users own data via blockchain

**TrustNet is Web3**: Users own their identity, assets, and data. Not controlled by company.

### Decentralization
Power distributed across many parties instead of one central authority.

**Centralized**: One company (Facebook) controls all user data.  
**Decentralized**: Users control own data; network consensus validates transactions.

**Benefits:**
- No single point of failure (can't be shut down by censoring one company)
- Transparency (all transactions visible)
- User ownership (you own your identity, assets)

### Trustless
System that doesn't require trust in intermediaries. Smart contracts enforce rules automatically.

**Traditional Trust**: "Trust your bank not to steal your money"  
**Trustless**: "Math proves your money is in smart contract, no one can steal it"

**TrustNet is trustless**: Trust scores, escrow, payments enforced by code, not people.

### Self-Sovereign Identity
User owns their identity without depending on government or company.

**Traditional**: Government issues passport, controls your identity.  
**Self-Sovereign**: You control your identity cryptographically; government/company can't revoke it.

**TrustNet plans**: Users control identity via wallet; optional KYC verification adds credibility.

### Wallet
Software that stores cryptocurrency private keys and signs transactions.

**Types:**
- **Hot Wallet**: Connected to internet (MetaMask, Trust Wallet) - convenient, less secure
- **Cold Wallet**: Offline storage (hardware wallet, USB drive) - secure, less convenient
- **Custodial**: Company holds your keys (Coinbase, Kraken) - easy, not true Web3
- **Non-Custodial**: You control keys (MetaMask, hardware wallets) - true Web3

**TrustNet uses non-custodial wallets:**
- **MetaMask** (desktop/browser)
- **WalletConnect** (any Ethereum wallet)
- **Magic Link** (email-based, beginner-friendly)

### Private Key / Secret Key
Cryptographic key that proves ownership of assets. Like ultra-secure password.

**If you lose it**: You lose access to all assets forever  
**If someone gets it**: They can steal all your assets

**Never share your private key with anyone, ever.**

### Public Key / Wallet Address
Cryptographic key that identifies you on blockchain. Like your bank account number; safe to share.

**Example Ethereum address:**
```
0x742d35Cc6634C0532925a3b844Bc186e2d195F5e
```

**How it works:**
- Everyone can see what assets you own (on blockchain)
- Everyone can send you crypto (to your address)
- Only you can spend it (need private key to sign transaction)

### Seed Phrase / Mnemonic
12-24 words that generate your private key. Recovery method if you lose your wallet.

**Example:**
```
correct horse battery staple into the future never forget
... (12 or 24 words)
```

**Security rules:**
- Write down on paper, keep safe
- Never share with anyone
- Never take screenshot or photo
- Anyone with these words can steal your crypto

### Gas Fee
Cost to execute transaction on blockchain.

**Who gets the fee:**
- Validators/miners (for maintaining network)
- TrustNet (transaction fee goes to company/DAO)

**Example:**
- Send £10 on Ethereum: costs £30 gas (expensive)
- Send £10 on Polygon: costs £0.001 gas (cheap)

**TrustNet uses Polygon** to keep fees low.

### MEV (Maximal Extractable Value)
Profit validators can make by reordering transactions. Can be unfair to users.

**Example**: Validator sees your pending trade, executes their own trade first to get better price, then executes yours. Steals your profit.

**TrustNet mitigation**: Use private mempools (hide pending transactions).

---

## Governance & DAOs

### DAO (Decentralized Autonomous Organization)
Organization run by smart contracts, governed by community voting.

**Structure:**
- **Members**: Token holders
- **Voting**: One token = one vote
- **Treasury**: DAO funds (controlled by voting)
- **Proposals**: Anyone can propose changes
- **Execution**: Smart contracts automatically execute approved changes

**TrustNet DAO:**
- Members vote on fee changes
- Members vote on new features
- Members vote on budget allocation
- Treasury managed by multi-sig wallet (5 of 7 signers required)

### Proposal
Suggestion for change (fee adjustment, new feature, budget allocation). Members vote yes/no.

**Proposal lifecycle:**
1. Member creates proposal with description & voting period
2. Members vote (yes/no) for 7 days
3. If majority votes yes, proposal passes
4. Smart contract automatically executes

### Voting
Members participate in governance by voting on proposals.

**Voting methods:**
- **Simple**: 1 member = 1 vote
- **Token-weighted**: Voting power = tokens held (TrustNet Phase 2)
- **Quadratic**: Voting power = sqrt(tokens) - prevents whale dominance (TrustNet Phase 3)
- **Delegation**: Vote through representative (TrustNet Phase 2)

### Quorum
Minimum participation required for vote to be valid.

**Example**: Proposal requires 10% of token holders to vote (quorum). If only 5% vote, proposal is rejected regardless of yes/no.

**TrustNet**: Flexible quorum (starts at 20%, can be adjusted by DAO)

### Treasury
Shared funds controlled by DAO through voting.

**TrustNet Treasury:**
- Funded by transaction fees (1-2% of transactions)
- Controlled by multi-sig wallet (7 of 10 community members)
- Voting on allocation (marketing, development, community rewards)
- Quarterly public reports

### Multi-Signature Wallet (Multi-Sig)
Requires multiple signatures to approve transactions (like joint bank account).

**TrustNet uses 5-of-7 multi-sig:**
- 7 community members have keys
- 5 of 7 must approve any treasury transaction
- Prevents single bad actor from stealing funds
- Also prevents company from unilaterally changing things

### Delegation
Giving your voting power to someone else (like proxy voting).

**Example**: You trust Alice to vote on your behalf, so you delegate to her. Your tokens count toward Alice's voting power.

**TrustNet Phase 2**: Enables delegation so users don't have to vote on every proposal.

---

## Infrastructure & Networks

### Ethereum
Blockchain that supports smart contracts. Owned by no one; run by thousands of validators.

**Key features:**
- Proof of Stake consensus
- ~12 second block time
- Expensive gas fees (£1-50 per transaction)
- Most popular smart contract platform

**TrustNet uses Ethereum** for:
- Identity Registry (immutable)
- Trust Scoring (permanent audit trail)
- DAO Governance (transparent voting)

### Polygon
Layer 2 blockchain built on Ethereum. Inherits Ethereum's security but much cheaper/faster.

**Specs:**
- ~2 second block time
- ~£0.001 per transaction (99% cheaper than Ethereum)
- 7,000+ transactions per second
- Full Ethereum compatibility

**TrustNet uses Polygon** for:
- Payments (escrow, transfers)
- All user transactions
- High throughput without high cost

### Arbitrum / Optimism
Alternative Layer 2 blockchains (like Polygon). TrustNet may add support.

### Mainnet / Testnet
- **Mainnet**: Real blockchain where real transactions happen. Real money at stake.
- **Testnet**: Practice blockchain. Free tokens. No real value. Used for development & testing.

**TrustNet POC uses testnet** (Ethereum Goerli, Polygon Mumbai)  
**TrustNet Phase 1 uses mainnet** (Ethereum Mainnet, Polygon Mainnet)

### Goerli / Sepolia / Mumbai
Popular testnets:
- **Goerli**: Ethereum testnet (free ETH from faucets)
- **Mumbai**: Polygon testnet (free MATIC from faucets)

### Layer 1 vs. Layer 2
- **Layer 1**: Main blockchain (Ethereum Mainnet) - secure, expensive
- **Layer 2**: Built on Layer 1 (Polygon, Arbitrum) - cheaper, faster, less secure but still secure enough

**TrustNet uses both:**
- Layer 1 (Ethereum) for critical data (identity, governance)
- Layer 2 (Polygon) for everything else (payments, trust updates)

### Bridge
Technology to move assets between blockchains.

**Example**: Move ETH from Ethereum to Polygon
1. Lock ETH on Ethereum
2. Mint wrapped token on Polygon
3. Can trade/use on Polygon
4. Burn wrapped token, unlock ETH on Ethereum

### RPC (Remote Procedure Call)
Interface to communicate with blockchain nodes. Allows apps to query blockchain, send transactions.

**Example**: MetaMask uses Infura's RPC to connect to Ethereum.

### Etherscan / Block Explorer
Website to explore blockchain. View transactions, contracts, addresses.

**URL**: etherscan.io (Ethereum), polygonscan.com (Polygon)

**What you can see:**
- All transactions (public)
- Contract code (public)
- Wallet balances (public)
- Smart contract execution logs

**TrustNet transparency**: Anyone can verify trust scores, transactions, governance votes on Etherscan.

### Node
Computer running blockchain software. Validates transactions, maintains blockchain copy.

**Types:**
- **Full Node**: Stores all blockchain data (~350GB Ethereum)
- **Light Node**: Stores minimal data, queries full nodes
- **Archive Node**: Stores all historical data (expensive)

**TrustNet infrastructure**: Runs Ethereum & Polygon full nodes.

---

## Security & Privacy

### Cryptography
Mathematical system for securing data. Makes data tamper-proof & verifiable.

**Uses:**
- Hashing (verify data hasn't changed)
- Encryption (hide data from unauthorized access)
- Digital signatures (prove you authorized transaction)

### Hash Function
One-way function that converts data to fixed-length fingerprint. Impossible to reverse.

**Properties:**
- Same input = same output always
- Different input = completely different output (avalanche effect)
- Impossible to reverse (can't get input from output)

**Example**: SHA-256 hash
```
Input: "TrustNet"
Output: a1b2c3d4e5f6...
```

### Public Key Cryptography
System where you have two keys:
- **Public Key**: Safe to share, identifies you
- **Private Key**: Secret, proves ownership

**How it works:**
1. Private key + message = Digital signature
2. Public key + signature = Verification (proves you signed it)

**TrustNet**: Blockchain uses public key cryptography. Your wallet address is your public key.

### Digital Signature
Cryptographic proof that you authorized a transaction.

**How to send £10:**
1. Create transaction: "Alice sends Bob £10"
2. Sign with private key
3. Broadcast to network with signature
4. Network verifies signature with your public key
5. Transaction is valid (only you could create this signature)

### Encryption
Scrambling data so only authorized person can read it.

**Example**: IPFS files can be encrypted before uploading, only owner can decrypt.

### Zero-Knowledge Proof (ZKP)
Prove something is true without revealing details.

**Example:** "Prove you're over 21 without showing your ID"
- Prove age without revealing identity
- Prove you have £1000 without revealing exact amount

**TrustNet Phase 2**: Use ZK proofs to keep KYC private while proving you're verified.

### Audit / Code Audit
Professional review of smart contract code for security vulnerabilities.

**TrustNet:**
- POC: Internal code review (free)
- Phase 1: Professional security audit (£50K)
- Phase 2: Annual audits (£25K/year)

### Vulnerability / Bug
Flaw in smart contract code that could allow theft or malfunction.

**Examples:**
- Reentrancy attack (withdraw from contract before updating balance)
- Integer overflow (number too large, wraps to negative)
- Unprotected function (anyone can call admin function)

### Formal Verification
Mathematical proof that smart contract code is correct (beyond just testing).

**Very expensive** but used for critical contracts (lending protocols, DEXes).

### Private Key
See "Self-Sovereign Identity" section.

### Phishing
Tricking users into revealing private keys or passwords.

**Protections:**
- Verify URLs (phishing sites look similar)
- Never enter seed phrase anywhere
- Use hardware wallets
- Enable 2FA where available

---

## Financial & Legal Terms

### Token Sale / ICO / IDO
Process of selling tokens to raise funds.

**Types:**
- **ICO (Initial Coin Offering)**: Direct sale to public (old, now regulated heavily)
- **IDO (Initial DEX Offering)**: Sale through decentralized exchange (newer)
- **Private Sale**: Sale to select investors (TrustNet Phase 3)
- **Public Sale**: Sale to general public (TrustNet Phase 3)

**TrustNet Token Sale (Phase 3):**
- Seed round: £0.01 per token (50M tokens = £500K)
- Private round: £0.015 per token (50M tokens = £250K)

### SAFT (Simple Agreement for Future Tokens)
Legal agreement for token purchases before token exists.

**Protects investors:**
- Token price locked in (not at launch price, at agreed price)
- Vesting schedule (tokens released over time)
- Token rights defined (governance, utility, dividend?)

**TrustNet uses SAFT** for pre-sale investors.

### Tokenomics
Token supply, distribution, incentives. How tokens create value.

**TrustNet Tokenomics:**
- Total supply: 1 billion TrustCoin
- 30% community (airdrop, rewards)
- 20% team (4-year vesting)
- 20% treasury (DAO-controlled)
- 30% future (incentives, partnerships)
- Deflationary (1% of transactions burned)

### Vesting / Lock-up
Schedule for when tokens become available.

**Example**: Team gets 100K tokens over 4 years
- Year 1: 25K tokens released
- Year 2: 25K tokens released
- Year 3: 25K tokens released
- Year 4: 25K tokens released

**Protects community**: Team can't dump all tokens immediately after launch.

### Airdrop
Free token distribution to users/community.

**Types:**
- **Retroactive**: Reward past users (Uniswap airdropped to past traders)
- **Prospective**: Incentivize future behavior (Polygon airdrops for development)
- **Announcement**: Marketing (airdrop to newsletter subscribers)

**TrustNet airdrop (Phase 3):**
- Early users (beta testers) get free TrustCoin
- Community contributors get free TrustCoin
- Referral rewards (£10 = 1000 TrustCoin airdrop)

### Staking
Locking up tokens to earn rewards.

**How it works:**
1. Deposit tokens in staking contract
2. Earn rewards (APY 5-20% typical)
3. Tokens locked for period (7 days, 30 days, etc.)
4. After lock-up, withdraw tokens + rewards

**TrustNet staking (Phase 3):**
- Stake TrustCoin, earn 10% APY
- Rewards come from transaction fees
- Minimum stake: 100 TrustCoin

### APY (Annual Percentage Yield)
Annual return on investment, accounting for compound interest.

**Example**: 10% APY on £100 = £10 earned per year (£110 total)

### Liquidity / Liquidity Provider
Liquidity = how easy it is to buy/sell asset without price slipping.

**Liquidity Provider**: Deposits crypto to pool to enable trading, earns fees.

**Example**: Uniswap pool with £1M USDC + £1M USDT has good liquidity (can trade large amounts without big price slips).

### Yield Farming
Earning returns by providing liquidity to DeFi protocols.

**How it works:**
1. Deposit £1000 in Uniswap USDC/USDT pool
2. Earn £0.50/day in trading fees (0.05% of trades)
3. Also earn UNI tokens (Uniswap rewards)
4. Total yield: ~20% APY

**TrustNet Phase 3**: Could enable yield farming with TrustCoin.

### Market Cap
Total value of all tokens: Token Price × Total Supply

**Example**: 
- TrustCoin: £0.01 price × 1 billion supply = £10M market cap
- At mainnet launch: Target £50M market cap (£0.05 per token)

### Market Cycle / Bull / Bear
- **Bull Market**: Rising prices, optimism
- **Bear Market**: Falling prices, pessimism
- **Bull Run**: Sustained price increase
- **Crash**: Sudden price drop

**TrustNet reality**: Crypto is volatile. Price will fluctuate. Focus on product, not price.

### Utility Token vs. Security Token
- **Utility**: Gives access to service (governance, transactions) - less regulated
- **Security**: Represents ownership/investment - heavily regulated

**TrustCoin is utility token** (governance + transaction access), NOT security.

### Regulation / Compliance
Legal requirements for operating in different jurisdictions.

**TrustNet complies with:**
- **UK**: FCA regulations
- **EU**: MiCA regulations
- **US**: FinCEN / SEC regulations
- **Singapore**: MAS regulations

### KYC / AML
- **KYC (Know Your Customer)**: Verify user identity
- **AML (Anti-Money Laundering)**: Prevent illegal financial activity

**TrustNet implements:**
- ID verification (Jumio)
- Address verification (Proof of residence)
- Sanctions screening (OFAC lists)
- Transaction monitoring (Chainalysis)

### Patent / IP
Intellectual property protection.

**TrustNet IP:**
- Trust scoring algorithm (may patent)
- Smart contract code (open source, not patented)
- Trademark: "TrustNet", "TrustCoin" (filed with UK IPO)

---

## Common Acronyms

| Acronym | Meaning | Context |
|---------|---------|---------|
| **DeFi** | Decentralized Finance | Financial services on blockchain |
| **DAO** | Decentralized Autonomous Organization | Community-governed organization |
| **DEX** | Decentralized Exchange | Blockchain-based trading (Uniswap) |
| **KYC** | Know Your Customer | Identity verification |
| **AML** | Anti-Money Laundering | Prevent illegal finance |
| **DApp** | Decentralized Application | App running on blockchain |
| **TPS** | Transactions Per Second | Network throughput |
| **TVL** | Total Value Locked | Amount of crypto in DeFi protocol |
| **APY** | Annual Percentage Yield | Annual return % |
| **MEV** | Maximal Extractable Value | Validator profit from transaction ordering |
| **RPC** | Remote Procedure Call | Interface to blockchain |
| **EVM** | Ethereum Virtual Machine | Blockchain that executes smart contracts |
| **ZK** | Zero-Knowledge | Cryptographic proof technique |
| **NFT** | Non-Fungible Token | Unique digital asset |
| **HODL** | Hold On for Dear Life | Long-term investment strategy |
| **FOMO** | Fear Of Missing Out | Trading based on emotion |
| **FUD** | Fear, Uncertainty, Doubt | Negative sentiment/rumors |
| **Rekt** | Wrecked | Lost money in bad investment |

---

## Glossary Cross-References by Topic

### For New Users
- Start: [Blockchain Fundamentals](#blockchain-fundamentals)
- Then: [Cryptocurrency & Tokens](#cryptocurrency--tokens)
- Then: [Wallet](#wallet)
- Then: [Web3 Concepts](#web3-concepts)

### For Developers
- Smart Contracts: [Smart Contracts & DeFi](#smart-contracts--defi)
- Infrastructure: [Infrastructure & Networks](#infrastructure--networks)
- Security: [Security & Privacy](#security--privacy)
- Solidity: [Solidity](#solidity)

### For Community/Governance
- DAO: [Governance & DAOs](#governance--daos)
- Voting: [Voting](#voting)
- Treasury: [Treasury](#treasury)
- Tokenomics: [Tokenomics](#tokenomics)

### For Investors
- Token Sale: [Token Sale / ICO / IDO](#token-sale--ico--ido)
- Tokenomics: [Tokenomics](#tokenomics)
- Market: [Market Cap](#market-cap)
- Valuation: [Market Cap](#market-cap)

---

## Additional Resources

### Learning More
- **Ethereum.org**: https://ethereum.org/en/developers/
- **Polygon Docs**: https://polygon.technology/
- **CryptoZombies**: Interactive Solidity tutorial
- **OpenZeppelin**: Smart contract libraries & best practices

### Tools
- **MetaMask**: https://metamask.io (wallet)
- **Etherscan**: https://etherscan.io (Ethereum explorer)
- **Hardhat**: https://hardhat.org (smart contract framework)
- **Truffle**: Smart contract development suite

### Community
- **Discord**: TrustNet community (coming Phase 1)
- **Twitter**: @TrustNetApp
- **GitHub**: github.com/Ingasti/trustnet-wip

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Jan 28, 2026 | Initial glossary created |

---

**Document prepared**: January 28, 2026  
**Status**: Living document (updated as needed)  
**Maintained by**: TrustNet team
