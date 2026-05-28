# Multi-Module Flow Coverage — NexaRail

**Date:** 2026-05-26
**Phase:** 8C

---

## Flow Coverage Matrix

| Flow | Module A | Module B | Test Location | Coverage |
|---|---|---|---|---|
| Merchant → Settlement (metadata) | merchant | settlement | `x/settlement/keeper` | ✅ Keeper-level via mocks |
| Merchant → Settlement (live) | merchant | settlement | `x/settlement/keeper` | ✅ Keeper-level via mocks |
| Merchant → Escrow (create) | merchant | escrow | `x/escrow/keeper` | ✅ Keeper-level via mocks |
| Merchant → Escrow (lifecycle) | merchant | escrow | `x/escrow/keeper` | ✅ Partial |
| Treasury → Payout | treasury | payout | `x/payout/keeper` | ⚠️ Not direct integration |
| Fees → Settlement (fee split) | fees | settlement | `x/settlement/keeper` | ✅ Via mock fees keeper |
| Fees → Escrow (fee calc) | fees | escrow | — | ⚠️ Not directly tested |

## Integration Test Types

| Type | Count | Location |
|---|---|---|
| App-level genesis consistency | 7 | `app/integration_test.go` |
| Keeper cross-module (settlement) | 20+ | `x/settlement/keeper/keeper_test.go` |
| Keeper cross-module (escrow) | 10+ | `x/escrow/keeper/keeper_test.go` |
| Keeper cross-module (payout) | 5+ | `x/payout/keeper/keeper_test.go` |
| Keeper cross-module (treasury) | 5+ | `x/treasury/keeper/keeper_test.go` |

## Happy Path Coverage

### Merchant → Settlement
- [x] Register merchant → create metadata settlement ✅
- [x] Verify fee split metadata (validator/treasury/burn shares) ✅
- [x] Merchant rebate tier affects settlement fee ✅
- [x] LiveEnabled=false → no bank calls ✅
- [x] LiveEnabled=true → payer → merchant net transfer ✅
- [x] TreasuryRoutingEnabled → treasury receives share ✅
- [x] BurnRoutingEnabled → burn share routed correctly ✅

### Merchant → Escrow
- [x] Merchant active → create escrow ✅
- [x] Inactive/closed merchant → rejected ✅
- [x] Release/refund/dispute lifecycle ✅

### Treasury → Payout
- [x] Treasury account/budget/spend creation ✅
- [x] Payout created against merchant ✅
- [x] Payout mark-paid metadata-only ✅
- [ ] Live payout path (requires LiveEnabled) ⚠️ Keeper tested

## Failure Path Coverage

| Scenario | Tested |
|---|---|
| Settlement for missing merchant | ✅ |
| Escrow for inactive merchant | ✅ |
| Invalid denom rejection | ✅ |
| Duplicate ID rejection | ✅ (escrow) |
| Below-minimum-amount rejection | ✅ (escrow) |
| Treasury spend without budget | ✅ |
| Insufficient funds | ✅ (settlement) |

## Remaining Gaps

| Gap | Priority |
|---|---|
| Direct treasury→payout integration test | Medium |
| Fees→escrow fee calculation | Low |
| Full end-to-end (register→create→release→payout) | Low (requires multi-module test harness) |
