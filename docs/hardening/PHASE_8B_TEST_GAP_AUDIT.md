# Phase 8B — Test Gap Audit

**Date:** 2026-05-26
**Auditor:** Clove

---

## Overall Test Count

| Package | Tests | Status |
|---|---|---|
| app | 11 | ✅ Adequate for app-level |
| x/fees/keeper | 6 | ⚠️ Low — needs query/invariant tests |
| x/fees/types | 13 | ✅ Good |
| x/merchant/keeper | 21 | ✅ Good |
| x/merchant/types | 25 | ✅ Good |
| x/settlement/keeper | 93 | ✅ Strong |
| x/settlement/types | 29 | ✅ Good |
| x/escrow/keeper | 46 | ✅ Good |
| x/escrow/types | 22 | ⚠️ Missing genesis tests |
| x/payout/keeper | 44 | ✅ Good |
| x/payout/types | 26 | ⚠️ Missing genesis tests |
| x/treasury/keeper | 45 | ✅ Good |
| x/treasury/types | 18 | ⚠️ Missing genesis tests |
| **TOTAL** | **~420** | |

## Gaps by Category

### Critical: CLI Tests (0 tests)

| Gap | Risk | Plan |
|---|---|---|
| No CLI test files exist for any module | High — CLI could silently break | Add app-level tests verifying CLI command tree |
| `GetQueryCmd` not tested | Medium | Verify each module's query commands registered in root |
| `GetTxCmd` not tested | Medium | Verify tx commands registered |
| Help text panics untested | Low | Smoke-test help output |

### High: REST Gateway Tests (0 tests)

| Gap | Risk | Plan |
|---|---|---|
| No REST route registration tests | High — routes could break silently | Add tests in app verifying route count per module |
| No HTTP handler tests | Medium | Test that handlers return JSON not panic |
| No error-path tests | Medium | Test bad params return error JSON |

### High: Missing Genesis Tests (3 modules)

| Module | Gap | Plan |
|---|---|---|
| x/escrow/types | No genesis_test.go | Add DefaultGenesis, ValidateGenesis tests |
| x/payout/types | No genesis_test.go | Add DefaultGenesis, ValidateGenesis tests |
| x/treasury/types | No genesis_test.go | Add DefaultGenesis, ValidateGenesis tests |

### Medium: Query Server Edge Cases

| Gap | Risk | Plan |
|---|---|---|
| No not-found response tests | Medium — NPE risk | Add query tests for nonexistent IDs |
| No empty-state tests | Low | Add list tests on clean genesis |
| No by-owner/merchant with bad addresses | Medium | Add invalid-address query tests |

### Medium: Live Funds Safety

| Gap | Risk | Plan |
|---|---|---|
| Live flag cross-module invariants | Medium | Add app-level test verifying all 6 = false at genesis |
| Module account permissions | Low (already tested in app) | Verify escrow/treasury/fee_router/burner perms |
| FundsSettled ↔ BurnExecuted invariant | Medium | Already in settlement tests — verify coverage |

### Low: Debug Command Tests

| Gap | Risk | Plan |
|---|---|---|
| No tests for debug-live-flags | Low | Add test verifying reads genesis correctly |
| No tests for debug-module-summary | Low | Add test verifying outputs all sections |
| No tests for debug-p2p-config | Low | Already functional — add smoke test |

## Implementation Priority

1. **Add CLI command registration tests** in `app/app_test.go` — quick, high value
2. **Add REST route registration tests** in `app/app_test.go` — verify routes exist
3. **Add genesis tests** for escrow, payout, treasury types
4. **Add query edge-case tests** in keeper tests
5. **Add debug command tests** in cmd tests (new file)
6. **Strengthen live fund safety tests** where coverage is thin

## Success Criteria

- [ ] CLI command tree tested (all 6 modules present)
- [ ] REST routes tested (17 endpoints verified)
- [ ] Genesis tests added for escrow/payout/treasury
- [ ] Query not-found cases tested
- [ ] Live flags all false invariant tested at app level
- [ ] All tests pass
- [ ] Coverage reported
