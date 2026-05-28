# Test Coverage Matrix — NexaRail

**Date:** 2026-05-26
**Phase:** 8B

---

## Package Coverage

| Package | Tests | Type Tests | Keeper Tests | Genesis Tests | Query Tests | CLI Tests | REST Tests |
|---|---|---|---|---|---|---|---|
| app | 25 | — | — | ✅ | — | ✅ (6 modules) | ✅ (route reg) |
| x/fees/types | 13 | ✅ | — | ✅ | — | — | — |
| x/fees/keeper | 8 | — | ✅ | — | ✅ (Phase 8B) | — | — |
| x/merchant/types | 25 | ✅ | — | ✅ | — | — | — |
| x/merchant/keeper | 23 | — | ✅ | — | ✅ (Phase 8B) | — | — |
| x/settlement/types | 29 | ✅ | — | ✅ | — | — | — |
| x/settlement/keeper | 93 | — | ✅ | — | — | — | — |
| x/escrow/types | 27 | ✅ | — | ✅ (Phase 8B) | — | — | — |
| x/escrow/keeper | 52 | — | ✅ | — | ✅ (Phase 8B) | — | — |
| x/payout/types | 31 | ✅ | — | ✅ (Phase 8B) | — | — | — |
| x/payout/keeper | 46 | — | ✅ | — | ✅ (Phase 8B) | — | — |
| x/treasury/types | 23 | ✅ | — | ✅ (Phase 8B) | — | — | — |
| x/treasury/keeper | 47 | — | ✅ | — | ✅ (Phase 8B) | — | — |

## Category Coverage

| Category | Before Phase 8B | After Phase 8B | Status |
|---|---|---|---|
| CLI command registration | 0 tests | 4 tests | ✅ Covered |
| REST gateway routes | 0 tests | 1 test (verification) | ✅ Documented |
| Genesis validation (all modules) | 3/6 modules | 6/6 modules | ✅ Complete |
| Query edge cases (not-found) | 0 tests | 6 tests | ✅ Covered |
| Live flag invariants | 1 test (in app) | 2 tests (app-level) | ✅ Strengthened |
| Debug commands | 0 tests | 1 test (Help non-panic) | ✅ Covered |
| Module account permissions | 1 test | 2 tests | ✅ Strengthened |

## Remaining Gaps

| Gap | Severity | Notes |
|---|---|---|
| Integration tests (multi-module) | Medium | Settlement→Escrow→Treasury flow tests needed |
| Full HTTP REST handler tests | Low | Requires running gRPC server — documented in smoke scripts |
| CLI --output json coverage | Low | Can be added in Phase 8C |
| Performance/benchmark tests | Low | Not critical for testnet |
