# Phase 8C — Integration Test Plan

**Date:** 2026-05-26
**Phase:** 8C

---

## Scope

Integration tests that exercise multiple NexaRail modules together, verifying realistic flows rather than isolated unit behaviour.

## Modules in Scope

| Module | Role |
|---|---|
| x/merchant | Merchant registration, activation, rebate tiers |
| x/settlement | Payment settlement with fee routing |
| x/escrow | Payment escrow custody |
| x/payout | Automated payouts |
| x/treasury | Treasury accounts, budgets, spend requests |
| x/fees | Fee split parameters (cross-cutting) |

## Happy Paths

### Flow 1: Merchant → Metadata Settlement
1. Register merchant via msg server
2. Verify merchant active
3. Create metadata-only settlement (LiveEnabled=false)
4. Verify fee split metadata correct (validator/treasury/burn shares)
5. Verify rebate tier applied to settlement fee

### Flow 2: Merchant → Escrow Lifecycle
1. Register and activate merchant
2. Create escrow linked to merchant
3. Verify escrow stored with correct metadata
4. Release escrow (metadata-only)
5. Verify escrow state transitions correctly

### Flow 3: Treasury → Budget → Spend
1. Create treasury account
2. Create budget for account
3. Create spend request against budget
4. Verify spend stored with correct metadata
5. Verify budget remaining updated

### Flow 4: Payout → Mark Paid
1. Register merchant
2. Create payout linked to merchant
3. Mark payout as paid (metadata-only)
4. Verify payout state updated
5. Verify payout appears in merchant queries

## Failure Paths

| Scenario | Expected |
|---|---|
| Settlement for missing merchant | Error: merchant not found |
| Escrow for inactive merchant | Error: merchant not active |
| Payout for inactive merchant | Error: merchant not active |
| Treasury spend without budget | Error: budget not found |
| Invalid denom in any module | Error: invalid denom |
| Duplicate escrow ID | Error: already exists |
| Settlement below min amount | Error: below minimum |

## Live Flags Off-By-Default

All integration tests run with LiveEnabled=false. Live modes tested separately:
- Settlement live transfer only when LiveEnabled + TreasuryRoutingEnabled + BurnRoutingEnabled
- Escrow real custody only when LiveEnabled
- Treasury real transfer only when LiveEnabled
- Payout real transfer only when LiveEnabled

## Bank Balance Expectations

| Operation | Expected Balance Change |
|---|---|
| Metadata settlement | No bank calls |
| Metadata escrow create | No bank calls |
| Metadata escrow release | No bank calls |
| Metadata payout mark-paid | No bank calls |
| Live settlement | Payer balance decreases, merchant increases |
| Live escrow deposit | Payer balance decreases, escrow module increases |
| Live escrow release | Escrow module decreases, merchant increases |

## Performance Checks

Benchmark baselines for:
- Settlement fee calculation (100K iterations)
- Merchant listing (100 merchants)
- Settlement listing (100 settlements)
- Escrow listing (100 escrows)
- Treasury summary (10 accounts, 10 budgets)
- Index lookup by merchant/payer/recipient

## Runtime Harness

Keeper-level integration tests using shared test context:
- One `testing.T` with multiple keepers initialised together
- Shared `sdk.Context` and `sdk.Coins`
- Message server invocation through keeper methods
- Balance tracking through mock bank keeper

If full app harness (NewNexaRailApp in test) is feasible, use it. If not, use keeper-level shared mocks.

## Deferred

- IBC integration (no IBC module)
- Bridge testing (no bridge)
- Validator distribution (deferred feature)
- Stablecoin registry (deferred feature)
- Multi-node consensus testing (Docker rehearsal covers this)
