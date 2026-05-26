# NexaRail Settlement Burn Routing Test Plan

**Phase:** 5F.5 — Test Design
**Date:** 2026-05-25
**Status:** Test plan complete — implementation deferred to Phase 5F.6
**Depends on:** Phase 5F.4 (73 keeper tests)

## Test Structure

Extends the settlement keeper test suite. Mock bank keeper gains `BurnCoins` method and `moduleBalances` for burner account tracking.

### Required BankKeeper Interface Update (Phase 5F.6)

```go
type BankKeeper interface {
    SendCoins(ctx, from, to, coins) error
    SendCoinsFromAccountToModule(ctx, from, moduleName, coins) error
    BurnCoins(ctx, moduleName string, amt sdk.Coins) error  // NEW
}
```

### Helper

```go
func enableBurnRouting(t *testing.T, k keeper.Keeper, ctx sdk.Context) {
    t.Helper()
    p := k.GetParams(ctx)
    p.LiveEnabled = true
    p.TreasuryRoutingEnabled = true
    p.BurnRoutingEnabled = true
    require.NoError(t, k.SetParams(ctx, p))
}
```

## Test Categories

### Category 1: Metadata Default Path

| # | Test Name | Expected |
|---|---|---|
| 1.1 | `TestBurnRoutingDefaultFalse` | BurnRoutingEnabled == false |
| 1.2 | `TestBurnRoutingDisabledMeansMetadata` | No bank calls, FundsSettled=false |
| 1.3 | `TestBurnRoutingTrueLiveDisabledNoOp` | LiveEnabled=false → no bank calls even with BurnRoutingEnabled=true |

### Category 2: Merchant-Only and Merchant+Treasury Paths Preserved

| # | Test Name | Expected |
|---|---|---|
| 2.1 | `TestBurnRoutingDisabledMerchantOnlyWorks` | LiveEnabled=true only → merchant transfer, no burn |
| 2.2 | `TestBurnRoutingDisabledTreasuryWorks` | Treasury routing on → merchant+treasury, no burn call |
| 2.3 | `TestBurnRoutingDisabledNoBurnCall` | BurnCoins not called when flag is false |

### Category 3: Burn Success

| # | Test Name | Expected |
|---|---|---|
| 3.1 | `TestBurnRoutingSuccess` | All three transfers: merchant, treasury, burn |
| 3.2 | `TestBurnRoutingBurnAmountExact` | BurnCoins called with exact burnShare |
| 3.3 | `TestBurnRoutingPayerTotalDeduction` | Payer balance -= merchantNet + treasuryShare + burnShare |
| 3.4 | `TestBurnRoutingMerchantReceivesNet` | Merchant balance unchanged by burn (only receives merchantNet) |
| 3.5 | `TestBurnRoutingTreasuryReceivesShare` | Treasury balance unchanged by burn (only receives treasuryShare) |
| 3.6 | `TestBurnRoutingBurnExecutedTrue` | Settlement.BurnExecuted == true |
| 3.7 | `TestBurnRoutingValidatorShareMetadata` | ValidatorShare stored, no validator routing |
| 3.8 | `TestBurnRoutingBurnerModuleName` | BurnCoins called with module name "nexarail_burner" |
| 3.9 | `TestBurnRoutingEventBurnRouted` | Event attribute burn_routed=true |
| 3.10 | `TestBurnRoutingZeroBurnShareSkips` | FeeRateBps=0 → burnShare=0 → BurnCoins not called |

### Category 4: Failure Paths

| # | Test Name | Expected |
|---|---|---|
| 4.1 | `TestBurnRoutingInsufficientBalance` | Payer can't cover merchant+treasury+burn → error, no settlement stored |
| 4.2 | `TestBurnRoutingBurnTransferFails` | SendCoinsFromAccountToModule to burner fails → error, all roll back |
| 4.3 | `TestBurnRoutingBurnCoinsFails` | BurnCoins fails → error, settlement not stored |
| 4.4 | `TestBurnRoutingNotStoredAfterBurnFail` | Failed burn → GetAllSettlements empty |

### Category 5: Supply Invariant

| # | Test Name | Expected |
|---|---|---|
| 5.1 | `TestBurnRoutingSupplyHelper` | Helper returns correct cumulative burn total |
| 5.2 | `TestBurnRoutingSupplyAfterSingleBurn` | Cumulative burn equals burnShare |
| 5.3 | `TestBurnRoutingSupplyAfterMultipleBurns` | Cumulative burn = sum of all burnShares |
| 5.4 | `TestBurnRoutingSupplyExcludesMetadata` | Metadata-only records not counted in burn totals |

### Category 6: Status Guards

| # | Test Name | Expected |
|---|---|---|
| 6.1 | `TestBurnRoutingStatusChangeBlocked` | Live burn-settled → UpdateSettlementStatus blocked |
| 6.2 | `TestBurnRoutingMetadataStatusChangeAllowed` | Metadata records still transitionable |

### Category 7: Invariant Helpers

| # | Test Name | Expected |
|---|---|---|
| 7.1 | `TestBurnRoutingFundsInvariantClean` | ValidateSettlementFundsInvariant returns nil |
| 7.2 | `TestBurnRoutingBurnExecutedRequiresFundsSettled` | BurnExecuted=true implies FundsSettled=true |

### Category 8: Fee Calculation

| # | Test Name | Expected |
|---|---|---|
| 8.1 | `TestBurnRoutingFeeSplit` | valShare + treasuryShare + burnShare == netFee |
| 8.2 | `TestBurnRoutingBurnAbsorbsRoundingDust` | Burn share captures remainder from integer division |

### Category 9: Regression

| # | Test Name | Expected |
|---|---|---|
| 9.1 | All 73 existing tests | All pass (BurnRoutingEnabled defaults false) |

## Mock BankKeeper Updates

```go
type mockBankKeeper struct {
    // ... existing fields ...
    burnCalled      bool
    burnError       error
    lastBurnModule  string
    lastBurnAmount  sdk.Coins
    totalBurned     sdk.Coins  // cumulative
}

func (m *mockBankKeeper) BurnCoins(ctx sdk.Context, moduleName string, amt sdk.Coins) error {
    m.burnCalled = true
    m.lastBurnModule = moduleName
    m.lastBurnAmount = amt
    if m.burnError != nil {
        return m.burnError
    }
    // Burn from module balance
    modBal := m.moduleBalances[moduleName]
    m.moduleBalances[moduleName] = modBal.Sub(amt...)
    m.totalBurned = m.totalBurned.Add(amt...)
    return nil
}
```

## Test Count

| Category | Count |
|---|---|
| Metadata defaults | 3 |
| Preserved paths | 3 |
| Burn success | 10 |
| Failure paths | 4 |
| Supply invariant | 4 |
| Status guards | 2 |
| Invariant helpers | 2 |
| Fee calculation | 2 |
| Regression | 73 (existing) |
| **Total new tests** | **30** |
| **Expected total** | **~103** |

## Verification

```bash
cd ~/workspace/nexarail
go mod tidy && go mod verify && go build ./... && go vet ./... && go test ./...
```

## Pass Criteria

- [ ] All 30 new tests pass
- [ ] All 73 existing settlement tests pass
- [ ] All escrow/treasury/payout/fees/merchant tests pass
- [ ] `go build ./...` exit 0
- [ ] `go vet ./...` exit 0
