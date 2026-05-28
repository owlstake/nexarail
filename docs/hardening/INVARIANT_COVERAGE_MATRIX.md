# Invariant Coverage Matrix — NexaRail

**Date:** 2026-05-26
**Phase:** 8E

---

## Invariant Coverage by Module

| Module | Invariant | Test | Phase |
|---|---|---|---|
| x/fees | Shares sum to 10000 bps | TestInvariant_SharesSumTo10000Bps | 8E |
| x/fees | No negative shares | TestInvariant_NoNegativeShares | 8E |
| x/fees | No individual share exceeds total | TestFuzz_FeeSplitNoIndividualExceedsTotal | 8E |
| x/settlement | Live flags default false | TestInvariant_LiveFlagsDefaultFalse | 8E |
| x/settlement | Fee rate in valid range | TestInvariant_FeeRateBpsInRange | 8E |
| x/settlement | Rebate tiers sorted ascending | TestFuzz_RebateTiersValid | 8E |
| x/escrow | Default params valid | TestInvariant_DefaultParamsValid | 8E |
| x/payout | Default params valid | TestInvariant_DefaultParamsValid | 8E |
| x/payout | FundsPaid requires paid status | Existing keeper tests | pre-8E |
| x/treasury | Default params valid | TestInvariant_DefaultParamsValid | 8E |
| x/treasury | FundsExecuted requires executed | Existing keeper tests | pre-8E |
| x/treasury | Spend within budget | Existing keeper tests | pre-8E |
| x/merchant | Default params valid | TestInvariant_DefaultParamsValid | 8E |

## Fuzz Test Coverage

| Target | Test | Module |
|---|---|---|
| Fee split arithmetic (5 cases) | TestFuzz_FeeSplitArithmetic | x/fees |
| Fee split no exceed total | TestFuzz_FeeSplitNoIndividualExceedsTotal | x/fees |
| Settlement fee calculation (6 amounts) | TestFuzz_SettlementFeeCalculation | x/settlement |
| Rebate tier validity | TestFuzz_RebateTiersValid | x/settlement |
| Status enum validity | TestFuzz_StatusEnumsValid | x/escrow, x/payout, x/treasury, x/merchant |

## Randomized Test Coverage

| Target | Test | Module |
|---|---|---|
| Fee split permutations (6 splits) | TestRandom_FeeSplitUpdateRecovery | x/fees |
| Param get/set roundtrip | TestRandom_ParamsGetSetRoundtrip | x/escrow, x/payout, x/treasury, x/merchant |
| Settlement param update/recovery | TestRandom_ParamUpdateRecovery | x/settlement |

## Failure Injection Coverage

| Failure | Test | Module |
|---|---|---|
| Invalid zero-total fee split | TestFailure_FeeSplitInvalidRejected | x/fees |
| Live flags block transfers | TestFailure_LiveEnabledFalsePreventsTransfers | x/settlement |
| Nil param handling | TestFailure_SetParamsRejectsNil | x/escrow, x/payout, x/treasury, x/merchant |

## Test Count Summary

| Category | Tests Added (Phase 8E) |
|---|---|
| Invariant tests | 9 |
| Fuzz tests | 8 |
| Randomized tests | 6 |
| Failure injection tests | 6 |
| **Total new** | **29** |
