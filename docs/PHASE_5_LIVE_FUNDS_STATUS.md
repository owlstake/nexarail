# NexaRail Phase 5 — Live Funds Status

**Date:** 2026-05-25
**Version:** Phase 5 Complete
**Next milestone:** Phase 6 — Public Testnet Preparation

## Overview

Phase 5 implemented live fund movement across four NexaRail business modules. All live transfers are gated behind per-module governance-controlled flags that default to **false**. With all defaults unchanged, the system behaves as metadata-only (Phase 3/4 behaviour).

## Module-by-Module Status

### x/escrow — Live Custody

| Aspect | Status |
|---|---|
| Live flag | `LiveEnabled` (default false) |
| Module account | `nexarail_escrow` (nil permissions, blocked) |
| Live behaviour | CreateEscrow: buyer → escrow module account (status FUNDED). Release: escrow → seller. Refund/Cancel: escrow → buyer. ResolveDispute: based on outcome. |
| Metadata fallback | When LiveEnabled=false: all escrow lifecycle events are metadata-only. No coin movement. |
| Invariants | `ActiveCustodiedEscrowTotals`, `ValidateCustodyInvariant` |
| Tests | 68 (incl. live custody + hardening) |
| Risk | Low. Funds held in module account. Resolution paths always progress. |

### x/treasury — Live Spend Execution

| Aspect | Status |
|---|---|
| Live flag | `LiveEnabled` (default false) |
| Module account | `nexarail_treasury` (nil permissions, blocked) |
| Live behaviour | MarkSpendExecuted: treasury module → recipient. Status APPROVED → EXECUTED. FundsExecuted=true on success. |
| Metadata fallback | When LiveEnabled=false: spend lifecycle is metadata-only. No coin movement. |
| Invariants | `ActiveExecutedSpendTotals`, `ValidateSpendInvariant` |
| Tests | 63 (incl. live spend execution + hardening) |
| Risk | Low. Status-gated. Double-execution prevented. |

### x/payout — Live Payout Transfers

| Aspect | Status |
|---|---|
| Live flag | `LiveEnabled` (default false) |
| Source | `nexarail_treasury` module account |
| Live behaviour | MarkPayoutPaid: treasury → recipient. Status APPROVED → PAID. FundsPaid=true on success. Per-payout only (no batch live execution). |
| Metadata fallback | When LiveEnabled=false: payout lifecycle is metadata-only. No coin movement. |
| Invariants | `ActivePaidPayoutTotals`, `ValidatePayoutFundsInvariant` |
| Tests | 70 (incl. live transfers) |
| Risk | Low. Status-gated. Per-payout only (batch deferred). |

### x/settlement — Live Fee Routing

| Flag | Default | Dependencies | Behaviour |
|---|---|---|---|
| `LiveEnabled` | false | None | payer → merchant (merchant net) |
| `TreasuryRoutingEnabled` | false | LiveEnabled=true | payer → nexarail_treasury (treasury share) |
| `BurnRoutingEnabled` | false | LiveEnabled + TreasuryRouting both true | payer → nexarail_burner → BurnCoins (burn share) |
| *(none)* | N/A | N/A | Validator share: metadata-only (deferred, Phase 5F.7) |

| Aspect | Status |
|---|---|
| Module accounts used | `nexarail_treasury`, `nexarail_burner` (burner permission) |
| Live behaviour | Progressive: merchant → merchant+treasury → merchant+treasury+burn. All bank transfers before state mutation. SDK atomicity guarantees rollback. |
| Metadata fallback | When all flags false: full metadata-only. When only LiveEnabled: merchant-only. |
| Invariants | `ActiveSettledTotals`, `ValidateSettlementFundsInvariant` (incl. BurnExecuted checks) |
| Tests | 122 (93 keeper + 29 types). Progressive test coverage for all flag combinations. |
| Risk | Low-Medium. Burn is irreversible but gated behind 3 flags. Validator distribution deferred. |

## Live Flags Summary

| Module | Flag | Default | Controls |
|---|---|---|---|
| x/escrow | `LiveEnabled` | false | Escrow custody (buyer → module account) |
| x/treasury | `LiveEnabled` | false | Spend execution (treasury → recipient) |
| x/payout | `LiveEnabled` | false | Payout execution (treasury → recipient) |
| x/settlement | `LiveEnabled` | false | Merchant-net transfer (payer → merchant) |
| x/settlement | `TreasuryRoutingEnabled` | false | Treasury-share routing (payer → treasury) |
| x/settlement | `BurnRoutingEnabled` | false | Burn-share routing (payer → burner → BurnCoins) |

**Total: 6 live flags, all defaulting to false.**

## What Remains Metadata-Only

| Component | Reason |
|---|---|
| Validator share (60% of net fee) | Deferred — requires Cosmos SDK distribution specialist review |
| Fee router account | Registered but unused. Deferred until BeginBlock routing is implemented |
| BeginBlock fee routing | Not implemented. Settlement fees are in-message only |
| Automated refunds for live settlements | Live-settled records blocked from status changes |
| Multi-denom settlements | Single-denom (unxrl) only |
| Batch payout live execution | Per-payout only |

## What Is Deferred

| Feature | Phase | Reason |
|---|---|---|
| Validator distribution | 5F.8+ | Requires x/distribution specialist review |
| Fee router BeginBlock routing | 5F.9+ | Inter-block fee routing complexity |
| Stablecoin registry | Future | New module, not designed |
| Bridge (IBC or custom) | Future | New module, not designed |
| CosmWasm / EVM | Future | New runtime, not designed |
| Public mainnet | Phase 7+ | After testnet, audits, legal review |
| External security audit | Phase 6+ | Before mainnet |

## Risk Levels by Flow

| Flow | Risk | Notes |
|---|---|---|
| Escrow custody | Low | Single module account. Resolution paths always available. |
| Treasury spend execution | Low | Status-gated. Module account to recipient only. |
| Payout execution | Low | Status-gated. Same treasury source as spends. |
| Settlement merchant transfer | Low | Single bank call. Account-to-account. |
| Settlement treasury routing | Low | Two bank calls. Both atomic. Separate flag. |
| Settlement burn routing | Low-Medium | Three bank calls + BurnCoins. Burn is irreversible but triple-gated. |
| Settlement validator distribution | DEFERRED | Requires specialist review before any implementation. |

## External Review Requirements

| Review | Required For | Priority |
|---|---|---|
| Cosmos SDK distribution specialist | Validator distribution | Before Phase 5F.8 |
| Security auditor | All live fund flows | Before mainnet |
| Economic / tokenomics review | Fee split proportions, burn rate | Before mainnet |
| Governance review | Flag enablement process | Before public testnet |
| Legal review | Regulatory compliance | Before mainnet |

## Current Code Quality

| Metric | Value |
|---|---|
| Total packages with tests | 14 |
| Settlement keeper tests | 93 |
| Settlement types tests | 29 |
| Escrow tests | 68 |
| Treasury tests | 63 |
| Payout tests | 70 |
| App integration tests | ~9 |
| Build | Passes |
| Vet | Passes |
| All tests | Pass (14 packages) |
