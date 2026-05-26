# NexaRail Audit Package Index

**Document:** docs/audit/AUDIT_PACKAGE_INDEX.md
**Date:** 2026-05-25
**Purpose:** Index for external security auditors

## Repo Overview

| Item | Value |
|---|---|
| Project | NexaRail Network |
| Type | Sovereign Cosmos SDK Layer 1 |
| SDK version | v0.47.17 |
| Consensus | CometBFT v0.37.18 |
| Language | Go 1.22+ |
| Module count | 16 SDK + 6 custom |

## Module List

### Standard Cosmos SDK Modules
auth, bank, staking, slashing, gov, distribution, mint, params, crisis, upgrade, evidence, feegrant, authz, capability, vesting, genutil

### Custom NexaRail Modules

| Module | Path | Purpose | Live Funds? |
|---|---|---|---|
| x/fees | `x/fees/` | Fee split parameters (60/20/20 bps) | Policy only |
| x/merchant | `x/merchant/` | Merchant registration + tiers | N/A |
| x/settlement | `x/settlement/` | Payment settlement + fee routing | Yes — behind 3 flags |
| x/escrow | `x/escrow/` | Escrow custody | Yes — behind 1 flag |
| x/payout | `x/payout/` | Payout execution | Yes — behind 1 flag |
| x/treasury | `x/treasury/` | Treasury accounts + spend execution | Yes — behind 1 flag |

## Live Funds Flags

All default to **false**. See `docs/design/LIVE_FLAGS_MATRIX.md`.

| Module | Flag | Controls |
|---|---|---|
| x/escrow | LiveEnabled | Escrow custody |
| x/treasury | LiveEnabled | Spend execution |
| x/payout | LiveEnabled | Payout execution |
| x/settlement | LiveEnabled | Merchant-net transfer |
| x/settlement | TreasuryRoutingEnabled | Treasury-share routing |
| x/settlement | BurnRoutingEnabled | Burn-share routing + BurnCoins |

## Module Accounts

| Account | Permission | Used By |
|---|---|---|
| nexarail_escrow | nil | x/escrow |
| nexarail_treasury | nil | x/treasury, x/payout, x/settlement |
| nexarail_burner | {authtypes.Burner} | x/settlement (burn) |
| nexarail_fee_router | nil | Unused (deferred) |

All are in `blockedAddrs`. See `app/app.go` line ~220.

## Threat Models

| Document | Scope |
|---|---|
| `docs/security/LIVE_FUNDS_THREAT_MODEL.md` | General live funds (Phase 5B) |
| `docs/security/SETTLEMENT_LIVE_THREAT_MODEL.md` | Settlement merchant-net (Phase 5F.1) |
| `docs/security/SETTLEMENT_TREASURY_FEE_THREAT_MODEL.md` | Settlement treasury routing (Phase 5F.3) |
| `docs/security/SETTLEMENT_BURN_THREAT_MODEL.md` | Settlement burn routing (Phase 5F.5) |
| `docs/security/VALIDATOR_DISTRIBUTION_THREAT_MODEL.md` | Validator distribution (deferred) |
| `docs/security/PHASE_5_AUDIT_PREP.md` | Consolidated audit prep with questions |
| `docs/security/PHASE_3_THREAT_REVIEW.md` | Pre-live-funds state machine audit |

## Invariants

| Document | Scope |
|---|---|
| `docs/design/INVARIANTS.md` | All module invariants |
| Escrow: `ActiveCustodiedEscrowTotals`, `ValidateCustodyInvariant` | `x/escrow/keeper/keeper.go` |
| Treasury: `ActiveExecutedSpendTotals`, `ValidateSpendInvariant` | `x/treasury/keeper/keeper.go` |
| Payout: `ActivePaidPayoutTotals`, `ValidatePayoutFundsInvariant` | `x/payout/keeper/keeper.go` |
| Settlement: `ActiveSettledTotals`, `ValidateSettlementFundsInvariant` | `x/settlement/keeper/keeper.go` |

## Test Commands

```bash
cd ~/workspace/nexarail
go mod tidy && go mod verify
go build ./...
go vet ./...
go test ./...                              # all packages
go test ./x/settlement/keeper/... -v       # settlement-specific
go test ./x/escrow/keeper/... -v           # escrow-specific
go test ./app/... -v -run TestModuleAccount # app integration
```

Expected: 14 packages, ~332 tests, all pass.

## Known Limitations

See `docs/LIMITATIONS.md`.

- Validator distribution deferred (Phase 5F.7 design only)
- Fee router unused
- BeginBlock routing not implemented
- Stablecoin / bridge not built
- Multi-denom settlements not supported
- No external security audit yet
- Testnet only — mainnet not ready

## Deferred Features

See `docs/PHASE_5_LIVE_FUNDS_STATUS.md`.

## High-Risk Files

| File | Risk |
|---|---|
| `x/settlement/keeper/keeper.go:CreateSettlement` | Multi-transfer flow (merchant + treasury + burn) |
| `x/escrow/keeper/keeper.go` | Custody lifecycle, dispute resolution |
| `x/settlement/keeper/keeper.go:BurnCoins` call | Irreversible supply reduction |
| `app/app.go:maccPerms` | Module account permissions |

## Questions for Auditors

1. Are all `bank.SendCoins*` calls gated by correct status checks?
2. Can any live transfer be triggered with `LiveEnabled=false`?
3. Is the transfer-before-state-mutation pattern consistent across all modules?
4. Can `BurnCoins` be called with a non-burner module account?
5. Can governance enable all flags and drain treasury/escrow in one block?
6. Are supply invariants maintained after progressive settlement transfers?
7. Is double-execution prevented for escrow release, treasury spend, and payout pay?
8. Are all module accounts correctly blocked from direct user sends?
9. Can a failed intermediate transfer leave inconsistent state?
