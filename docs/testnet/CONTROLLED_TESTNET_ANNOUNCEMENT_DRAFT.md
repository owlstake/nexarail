# Controlled Testnet Announcement — DRAFT

**Status:** Draft — not yet published
**Date:** 2026-05-26
**Audience:** Validator operators, Cosmos ecosystem, blockchain infrastructure community
**Purpose:** Announce controlled validator registration for NexaRail testnet

---

## Subject: NexaRail Controlled Validator Registration Now Open

NexaRail — a sovereign Layer 1 blockchain for controlled testnet evaluation of railway settlement and payments — is opening controlled validator registration for its initial testnet, `nexarail-testnet-1`. External validator distribution is not yet live.

### What This Is

We are onboarding a controlled group of validators to test consensus stability, governance workflows, and infrastructure readiness. This is a technical testing phase, not a network launch.

### What This Is Not

- **Not mainnet.** NexaRail has no public mainnet.
- **Not a token sale.** No ICO, IEO, IDO, or private sale has occurred. NXRL is not offered for purchase.
- **Not an investment.** Testnet tokens have zero monetary value. They cannot be exchanged, traded, or transferred for value.
- **Not a permissionless network.** Validator registration is controlled — all applications are reviewed and approved by the genesis coordinator.

### Current Status

NexaRail is in testnet preparation. Key facts:

- **Chain ID:** nexarail-testnet-1
- **SDK:** Cosmos SDK v0.47.17 + CometBFT v0.37.18
- **Modules:** 16 standard Cosmos modules + 6 custom modules (fees, merchant, settlement, escrow, payout, treasury)
- **Live funds:** All 6 live fund flags are **disabled by default**. No real value flows on the testnet.
- **Build verification:** `go build/vet/test` all pass — 14 packages, ~332 tests
- **Docker rehearsal:** 3-validator testnet produced blocks with correct chain ID, validator set, and peer connectivity
- **Code quality:** Full module test suite passing; architecture docs, security threat models, and audit package prepared

### What We're Testing

- Multi-validator consensus stability
- P2P networking across diverse infrastructure
- Governance proposal lifecycle
- Module parameter management
- Upgrade coordination
- Monitoring and alerting

### Who Should Apply

Validator operators with:

- Linux infrastructure (amd64 or arm64, 4+ vCPU, 8+ GB RAM, 100+ GB SSD)
- Prior experience running validators (Cosmos, Tendermint, or equivalent)
- Commitment to testnet-only participation
- Understanding that testnet tokens have no monetary value

### How to Apply

1. Review the controlled validator registration document: `docs/testnet/CONTROLLED_VALIDATOR_REGISTRATION.md`
2. Complete the application form: `docs/testnet/VALIDATOR_APPLICATION_FORM.md`
3. Submit your application via the designated channel

### Timeline

- **Applications open:** Now
- **Application review:** Rolling (3-5 day response target)
- **Gentx collection:** After acceptance
- **Coordinated launch:** To be announced

### Resources

- Repository: https://github.com/Bookings-cpu/nexarail
- Registration: `docs/testnet/CONTROLLED_VALIDATOR_REGISTRATION.md`
- Application: `docs/testnet/VALIDATOR_APPLICATION_FORM.md`
- FAQ: `docs/testnet/FAQ.md`
- Genesis instructions: `docs/testnet/GENESIS_SUBMISSION_INSTRUCTIONS.md`

### Contact

- Technical: GitHub Issues
- Registration: Testnet communication channel (to be announced)
- Security: security@nexarail.network (TBC)

---

**NexaRail is infrastructure under development.** Participation is for technical testing only. No financial value accrues to testnet tokens. No mainnet launch date has been set. No token sale has occurred or is planned through this announcement.
