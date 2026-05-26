# NexaRail — Controlled Validator Registration Open

**NexaRail** is a sovereign Layer 1 blockchain for decentralised railway settlement and payments, built with **Cosmos SDK v0.47.17** and **CometBFT v0.37.18**. We're opening controlled validator registration for our initial testnet.

## What this is

We're onboarding a small group of technical validators to test consensus stability, governance workflows, and infrastructure readiness. **This is infrastructure testing only.**

## Chain config

- **Chain ID:** `nexarail-testnet-1`
- **Denom:** `unxrl` | **Ticker:** `NXRL` | **Prefix:** `nxr`
- **16 standard modules** + **6 custom modules** (fees, merchant, settlement, escrow, payout, treasury)
- **All live fund flags default to false** — no real value flows

## What this is NOT

- ❌ Not mainnet — no mainnet is live
- ❌ Not a token sale — NXRL has not been offered for sale
- ❌ Not an investment — testnet tokens have zero monetary value
- ❌ Not permissionless — validator registration is controlled, applications are reviewed

## Who we're looking for

- Linux server experience (required — no macOS/Docker Desktop)
- Cosmos/Tendermint validator experience preferred
- Ability to build from source and submit a gentx
- Reliable communication during genesis coordination
- Understanding that this is testnet-only with no monetary value

## How to apply

**Registration guide & application form:** [GitHub repo link]/docs/testnet/CONTROLLED_VALIDATOR_REGISTRATION.md

**Quick links:**
- Application form: `docs/testnet/VALIDATOR_APPLICATION_FORM.md`
- FAQ: `docs/testnet/FAQ.md`
- Gentx instructions: `docs/testnet/GENESIS_SUBMISSION_INSTRUCTIONS.md`

## Current status

| Metric | Status |
|---|---|
| Build/vet/test | ✅ 14 packages, all pass |
| Docker rehearsal | ✅ 3 validators, height >20, peers ≥2 |
| Live fund flags | ✅ All 6 default to false |
| Validator slots | 3-7 available |

---

**NexaRail is infrastructure under development. No mainnet launch date has been set. No token sale has occurred or is planned. Participation is for technical testing only.**
