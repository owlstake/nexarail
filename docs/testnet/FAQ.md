# FAQ — NexaRail Controlled Testnet

**Chain:** nexarail-testnet-1
**Last Updated:** 2026-05-26

---

## General

### What is NexaRail?

NexaRail is a sovereign Layer 1 blockchain built with Cosmos SDK, designed for decentralised railway settlement and payments. It provides modules for fee splitting, merchant registration, payment settlement, escrow custody, automated payouts, and treasury management.

### What is NXRL?

NXRL is the display ticker for NexaRail's native token. 1 NXRL = 1,000,000 unxrl (the base denom). NXRL is used for staking, governance, fees, and protocol operations on the NexaRail network.

### Is this mainnet?

**No.** NexaRail has no public mainnet. The current testnet (`nexarail-testnet-1`) is for infrastructure testing and validator coordination only.

### Are testnet tokens worth money?

**No.** NexaRail testnet tokens have zero monetary value. They cannot be exchanged, traded, or transferred for value. They exist solely for testing purposes.

### Can I buy NXRL?

**No.** NXRL has not been offered for sale through any mechanism (ICO, IEO, IDO, private sale, or otherwise). There is no way to purchase NXRL. Any claim to the contrary is fraudulent.

### Is NexaRail an investment?

**No.** Participation in the NexaRail testnet is not an investment. No financial returns are promised, expected, or implied. Testnet participation is for technical testing only.

## Validator Registration

### Can I run a validator?

Validator registration is **controlled** — not permissionless. You must apply, be reviewed, and be accepted by the genesis coordinator. See `docs/testnet/CONTROLLED_VALIDATOR_REGISTRATION.md` for requirements.

### What hardware do I need?

Minimum: 4 vCPU, 8 GB RAM, 100 GB SSD, Linux (Ubuntu 22.04+ or equivalent), static public IP, ports 26656 and 26657 open.

**Docker Desktop on macOS is NOT suitable** for validator operation due to P2P networking instability. Linux hosts only.

### What does "controlled registration" mean?

It means validator applications are manually reviewed and approved by the genesis coordinator. Only approved validators are included in the genesis. The testnet is not open to anyone without application and approval.

### How many validators will there be?

The initial testnet targets 3-7 validators. The minimum for consensus is 3. More validators improve fault tolerance (4+ recommended).

### Is there a token requirement to become a validator?

Accepted validators receive testnet tokens from the coordinator for self-delegation. The minimum self-delegation is 500,000,000 unxrl (500 NXRL equivalent). These are testnet tokens with no monetary value.

## Technical

### What modules does NexaRail have?

**Standard Cosmos SDK modules:** auth, bank, staking, slashing, gov, distribution, mint, params, crisis, upgrade, evidence, feegrant, authz, capability, vesting, genutil.

**Custom NexaRail modules:**
- x/fees — Fee split parameters (60/20/20 bps default)
- x/merchant — Merchant registration and rebate tiers
- x/settlement — Payment settlement with fee routing
- x/escrow — Payment escrow custody
- x/payout — Automated payouts
- x/treasury — Protocol treasury and spend execution

### Are live funds enabled?

**No.** All live fund modules have their `LiveEnabled` flags set to `false` by default. These can only be enabled through on-chain governance. The current status:

| Module | LiveEnabled | Default |
|---|---|---|
| Settlement | false | ✅ |
| Escrow | false | ✅ |
| Treasury | false | ✅ |
| Payout | false | ✅ |

Additional routing flags (settlement.treasury_routing_enabled, settlement.burn_routing_enabled) are also `false`.

### Is the code audited?

**No.** A formal third-party security audit has not been completed. Internal threat models and an audit preparation package are available (`docs/audit/`). An external audit is required before any consideration of mainnet.

### Is the project legally reviewed?

**No.** A formal legal review has not been completed. A legal review preparation package is available (`docs/legal/LEGAL_REVIEW_PACKAGE.md`). Independent legal counsel review is required before any consideration of mainnet.

### What's the tech stack?

- Cosmos SDK v0.47.17
- CometBFT v0.37.18
- Go 1.22+
- IAVL state storage
- gRPC + REST API + CometBFT RPC

### Will the testnet be reset?

**Yes.** Testnet state may be wiped or reset at any time. No data persistence is guaranteed. Validators should expect resets during early testing phases.

## Participation

### Is there a reward for running a validator?

**No financial reward.** Validators earn testnet tokens through block rewards and fees, but these tokens have zero monetary value. Participation is for technical contribution and ecosystem building.

### What are the slashing conditions?

- Downtime: 0.01% slash (testnet parameter)
- Double-sign: 5% slash
- These apply to testnet tokens (no monetary value)

### What happens if my validator goes offline?

If your validator is offline for an extended period, it may be jailed or removed from the active set via governance. This affects your testnet participation but carries no financial penalty.

### Can I leave the testnet?

Yes. Notify the coordinator, stop your node, and you will be removed from validator coordination. Give 48+ hours notice if possible.

### How do I report a bug?

For non-security bugs: GitHub Issues with reproduction steps, logs, and environment details.

For security issues: Contact the security email (TBC). Do NOT file public issues for security vulnerabilities.

## Legal & Compliance

### Is NexaRail regulated?

NexaRail is testnet infrastructure under development. No regulated activities are being conducted. The project has not sought regulatory approval in any jurisdiction because no mainnet, token sale, or financial service is being offered.

### Can I participate from any country?

Validator applications are reviewed individually. Applications from jurisdictions presenting unacceptable legal risk may be declined. If you are uncertain, consult your own legal counsel before applying.

### Will there be a token sale in the future?

No token sale has been announced, planned, or committed to. Any future decision about token distribution would be made through proper legal and regulatory channels with appropriate disclosures.

---

**Have a question not answered here?** Contact the genesis coordinator through the testnet communication channel.
