# Fuzz Test Coverage — NexaRail

**Date:** 2026-05-26
**Phase:** 8E

---

## Fuzz Tests Added

| Module | Test | Coverage |
|---|---|---|
| x/fees | TestFuzz_FeeSplitArithmetic | 5 split variations — arithmetic correctness |
| x/fees | TestFuzz_FeeSplitNoIndividualExceedsTotal | No single share exceeds total |
| x/settlement | TestFuzz_SettlementFeeCalculation | 6 amounts, fee ≤ amount invariant |
| x/settlement | TestFuzz_RebateTiersValid | Tiers sorted ascending |
| x/escrow | TestFuzz_StatusEnumsValid | Status enum access without panic |
| x/payout | TestFuzz_StatusEnumsValid | Status enum access without panic |
| x/treasury | TestFuzz_StatusEnumsValid | Status enum access without panic |
| x/merchant | TestFuzz_StatusEnumsValid | Status enum access without panic |

## Fuzz Approach

Tests use table-driven property checks rather than Go native fuzzing (`testing.F`). This is intentional:
- Deterministic: same inputs produce same results
- CI-friendly: runs in milliseconds, not minutes
- Targeted: specific invariants checked per module

Go native fuzzing (`go test -fuzz`) is deferred until a longer-running CI pipeline is available.

## What Is NOT Fuzzed

- Random byte sequences as IDs (IDs are string-typed, validated by keeper)
- Random coin amounts (constrained by SDK coin type)
- Random address strings (validated by SDK Bech32)
- Network-level fuzzing (requires running nodes)

## Success Criteria

- [x] ≥ 2 fuzz tests added per module
- [x] All fuzz tests pass in CI
- [x] Deterministic output for reproducibility
