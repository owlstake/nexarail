# NexaRail Controlled Validator Registration — NOW OPEN

**Date:** 2026-05-26
**Status:** Published — controlled registration open
**Channel:** To be posted in Discord/Telegram/GitHub

---

NexaRail — a sovereign Layer 1 blockchain for decentralised railway settlement and payments — is opening **controlled validator registration** for its initial testnet, `nexarail-testnet-1`.

## What This Is

We are onboarding a controlled group of validators to test consensus stability, governance workflows, and infrastructure readiness. This is a **technical testing phase** — not a network launch.

**Validator slots are limited** in this controlled intake round. Applications are reviewed individually by the genesis coordinator.

## What This Is NOT

- **Not mainnet.** NexaRail has no public mainnet. No launch date has been set.
- **Not a token sale.** No ICO, IEO, IDO, or private sale has occurred. NXRL is not offered for purchase.
- **Not an investment.** Testnet tokens have zero monetary value. They cannot be exchanged, traded, or transferred for value.
- **Not permissionless.** Validator registration is controlled — all applications are reviewed and approved.

## Current Status

| Metric | Status |
|---|---|
| Chain ID | `nexarail-testnet-1` |
| SDK | Cosmos SDK v0.47.17 + CometBFT v0.37.18 |
| Custom modules | 6 (fees, merchant, settlement, escrow, payout, treasury) |
| Live funds | **All disabled by default** |
| Build/vet/test | ✅ 14 packages, all pass |
| Docker rehearsal | ✅ 3 validators, height > 20, peers ≥ 2 |
| Code audit | External audit required before mainnet |
| Legal review | External legal review required before mainnet |
| Registration | **Controlled — application required** |

## Validator Requirements

| Requirement | Minimum |
|---|---|
| Operating System | **Linux** (Ubuntu 22.04+ or equivalent) |
| CPU | 4 vCPU |
| RAM | 8 GB |
| Disk | 100 GB SSD |
| Network | Static public IP, ports 26656/26657 open |
| Experience | Validator experience preferred |
| Commitment | Testnet-only participation acknowledged |

**Docker Desktop on macOS is not suitable** for validator operation. Linux hosts only.

## How to Apply

1. **Read the registration guide:** `docs/testnet/CONTROLLED_VALIDATOR_REGISTRATION.md`
2. **Complete the application form:** `docs/testnet/VALIDATOR_APPLICATION_FORM.md`
3. **Submit your application** via [application channel — GitHub Issues or form link]

## What Happens After You Apply

1. Application acknowledged within 48 hours
2. Initial screening (3 days)
3. Technical review (5 days)
4. Decision: accepted / more info needed / not accepted for this round
5. If accepted: complete the acceptance checklist, generate keys, submit gentx
6. Genesis built, launch coordinated

## Documentation

| Document | Link |
|---|---|
| Registration Guide | `docs/testnet/CONTROLLED_VALIDATOR_REGISTRATION.md` |
| Application Form | `docs/testnet/VALIDATOR_APPLICATION_FORM.md` |
| Acceptance Checklist | `docs/testnet/VALIDATOR_ACCEPTANCE_CHECKLIST.md` |
| Gentx Instructions | `docs/testnet/GENESIS_SUBMISSION_INSTRUCTIONS.md` |
| FAQ | `docs/testnet/FAQ.md` |

## Timeline

- **Applications open:** Now
- **Application review:** Rolling (3-5 day response target)
- **Gentx deadline:** To be announced to accepted validators
- **Coordinated launch:** To be announced

## Contact & Community

- **Application channel:** [GitHub Issues / form link — placeholder]
- **Community channel:** [Discord/Telegram invite — placeholder]
- **Security reports:** [security contact — placeholder]
- **Repository:** https://github.com/Bookings-cpu/nexarail

---

**NexaRail is infrastructure under development.** Participation is for technical testing only. No financial value accrues to testnet tokens. No mainnet launch date has been set. No token sale has occurred or is planned through this announcement. Controlled validator registration does not constitute an offer of investment, securities, or financial services.
