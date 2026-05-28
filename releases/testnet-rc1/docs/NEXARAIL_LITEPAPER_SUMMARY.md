# NexaRail Network — Litepaper Summary

**Chain:** NexaRail Network | **Framework:** Cosmos SDK + CometBFT | **Coin:** NXRL / `unxrl` | **Prefix:** `nxr`

---

## What is NexaRail?

A sovereign Layer 1 blockchain purpose-built for payment and settlement infrastructure: merchant onboarding, programmable settlement, escrow custody, automated payouts, and governance-controlled treasury management.

## Current Status

- **Testnet preparation.** Mainnet is not live. Controlled agent testnet running.
- **~500+ tests passing.** Six custom modules implemented and tested.
- **Agent testnet runtime readiness advanced.** The 5-agent local testnet has passed block production, full query/readback, governance final-state readback, runtime bank tx inclusion, a 60-minute soak, a restart matrix, and a full local product-flow rehearsal with 469 checks passing.
- **External validator onboarding pending.** Current validators are development-operated agents.
- **Live funds disabled by default.** All fund-moving flags default to `false`.

## Modules

| Module | Purpose | Live funds default |
|---|---|---|
| x/fees | Fee split parameters (60/20/20 bps) | N/A — policy only |
| x/merchant | Merchant registration and rebate tiers | N/A — metadata only |
| x/settlement | Payment settlement + fee routing | `false` (3 flags) |
| x/escrow | Payment escrow custody | `false` |
| x/payout | Automated payouts | `false` |
| x/treasury | Protocol treasury + spend execution | `false` |

## Live Funds Safety Model

Six governance-controlled flags, all defaulting to `false`. No fund movement occurs without a governance proposal passing. Module accounts (escrow, treasury) are in the bank blocked-recipients list.

## Validator & Consensus

CometBFT validator set, currently 5 autonomous development-operated agents. The local agent runtime passed the Phase 9W evidence package, including 1-hour soak and restart recovery. Target for external validators: 3 minimum, 5 preferred, 7 strong. Onboarding process designed but not yet executed.

## Roadmap

| Phase | Status |
|---|---|
| A — Agent testnet hardening | **Current** |
| B — External validator cohort | Design complete, pending execution |
| C — Controlled public testnet | Planned |
| D — External security + legal review | Required before mainnet candidate |
| E — Mainnet candidate | Only after Phases A–D |

## Critical Disclaimers

- **A** No public mainnet exists. **B** No token sale — NXRL has never been offered for sale. **C** Testnet tokens have zero monetary value. **D** Not an investment — no returns promised. **E** Not externally decentralised — agent validators do not represent external validator distribution. **F** No external security audit completed. **G** Legal review pending. **H** Roadmap is provisional — no timeline commitments.

## Full litepaper

`docs/NEXARAIL_LITEPAPER.md`
