# NexaRail Settlement Treasury Fee Routing Test Plan

**Phase:** 5F.3 — Test Design
**Date:** 2026-05-25
**Status:** Test plan complete — implementation deferred to Phase 5F.4
**Depends on:** Phase 5F.2 (live merchant-net transfer, 51 keeper tests)
**Flag:** Separate `TreasuryRoutingEnabled` (default false)

## Test Structure

Tests extend the existing settlement keeper test suite. The `setupKeeper` function and `mockBankKeeper` from Phase 5F.2 are reused. New tests verify treasury routing behaviour.

### Required BankKeeper Interface Update (Phase 5F.4)

```go
type BankKeeper interface {
    SendCoins(ctx sdk.Context, fromAddr sdk.AccAddress, toAddr sdk.AccAddress, amt sdk.Coins) error
    SendCoinsFromAccountToModule(ctx sdk.Context, fromAddr sdk.AccAddress, recipientModule string, amt sdk.Coins) error
}
```

The mock must implement both methods.

### Helper: Enable Treasury Routing

```go
func enableTreasuryRouting(t *testing.T, k keeper.Keeper, ctx sdk.Context) {
    t.Helper()
    p := k.GetParams(ctx)
    p.LiveEnabled = true
    p.TreasuryRoutingEnabled = true
    require.NoError(t, k.SetParams(ctx, p))
}
```

## Test Categories

### Category 1: Metadata Default Path Unchanged

Verify no regression when all flags are at defaults.

| # | Test Name | Input | Expected |
|---|---|---|---|
| 1.1 | `TestTreasuryRoutingDefaultFalse` | Default params | TreasuryRoutingEnabled == false |
| 1.2 | `TestMetadataNoBankCallWithTreasuryRoutingDefault` | All defaults, create settlement | No bank calls, FundsSettled=false |
| 1.3 | `TestTreasuryRoutingDisabledMeansMetadata` | TreasuryRoutingEnabled=false (default), create settlement | Metadata-only path unchanged from v1 |

### Category 2: Merchant-Only Path Preserved

Verify that `TreasuryRoutingEnabled=false` with `LiveEnabled=true` behaves identically to Phase 5F.2.

| # | Test Name | Input | Expected |
|---|---|---|---|
| 2.1 | `TestLiveEnabledWithoutTreasuryRouting` | LiveEnabled=true, TreasuryRoutingEnabled=false | Merchant transfer only, no treasury transfer |
| 2.2 | `TestMerchantOnlySameAsPhase5F2` | LiveEnabled=true, TreasuryRoutingEnabled=false | Merchant balance +99100, treasury module balance unchanged, payer balance -99100 |
| 2.3 | `TestMerchantOnlyNoTreasuryCall` | LiveEnabled=true, TreasuryRoutingEnabled=false | mock `sendToModuleCalled` == false |
| 2.4 | `TestMerchantOnlyFundsSettledTrue` | LiveEnabled=true, TreasuryRoutingEnabled=false | settlement.FundsSettled == true |

### Category 3: Treasury Routing Enabled But Live Disabled (No-Op)

| # | Test Name | Input | Expected |
|---|---|---|---|
| 3.1 | `TestTreasuryRoutingTrueLiveDisabled` | LiveEnabled=false, TreasuryRoutingEnabled=true | Metadata-only, no bank calls |
| 3.2 | `TestTreasuryRoutingTrueLiveDisabledFundsSettled` | LiveEnabled=false, TreasuryRoutingEnabled=true | FundsSettled == false |

### Category 4: Live Merchant + Treasury Success

| # | Test Name | Input | Expected |
|---|---|---|---|
| 4.1 | `TestTreasuryRoutingSuccess` | LiveEnabled=true, TreasuryRoutingEnabled=true, amount=100000 | Settlement created, FundsSettled=true, both transfers execute |
| 4.2 | `TestTreasuryRoutingMerchantReceivesNet` | amount=100000, feeRate=100, rebateTier=2 | Merchant balance +99100 unxrl |
| 4.3 | `TestTreasuryRoutingTreasuryReceivesShare` | Same inputs | Treasury module balance +180 unxrl (netFee=900, 900*2000/10000=180) |
| 4.4 | `TestTreasuryRoutingPayerTotalDeduction` | Same inputs | Payer balance -99280 unxrl (99100 + 180) |
| 4.5 | `TestTreasuryRoutingBurnShareUnchanged` | Same inputs | BurnShare stored as metadata, no burn call, burn module balance unchanged |
| 4.6 | `TestTreasuryRoutingValidatorShareUnchanged` | Same inputs | ValidatorShare stored as metadata, no validator distribution |
| 4.7 | `TestTreasuryRoutingEventTreasuryRouted` | Same inputs | Event attribute `treasury_routed` == "true" |
| 4.8 | `TestTreasuryRoutingCorrectModuleName` | Same inputs | SendCoinsFromAccountToModule called with module name "nexarail_treasury" |
| 4.9 | `TestTreasuryRoutingTreasuryShareAmountExact` | amount=100000, feeRate=100, no rebate (tier 0) | Treasury share = (1000 * 2000 / 10000) = 200 unxrl |
| 4.10 | `TestTreasuryRoutingRoundingFloor` | amount=100001 | Treasury share = floor(1000 * 2000 / 10000) = 200 (0.01 fractional lost to burn remainder) |

### Category 5: Fee Calculation With Treasury Routing

| # | Test Name | Input | Expected |
|---|---|---|---|
| 5.1 | `TestTreasuryRoutingFeeSplitExact` | amount=1000000 | TreasuryShare = (10000-1000)*2000/10000 = 1800 (with tier 2 rebate) |
| 5.2 | `TestTreasuryRoutingRebateReducesTreasury` | Same amount, rebateTier=0 vs rebateTier=4 (2000bps) | Higher rebate → lower treasury share |
| 5.3 | `TestTreasuryRoutingGrossMinusTransfersEqualsDust` | Any amount | gross - merchantNet - treasuryShare = valShare + burnShare (metadata) |
| 5.4 | `TestTreasuryRoutingZeroFeeRate` | FeeRateBps=0 | netFee=0, treasuryShare=0, merchantNet=gross, treasury transfer amount=0 |
| 5.5 | `TestTreasuryRoutingZeroTreasuryShareBps` | TreasuryShareBps=0 in x/fees | treasuryShare=0, no treasury transfer (or zero-amount transfer skipped) |

### Category 6: Failure Paths

| # | Test Name | Input | Expected |
|---|---|---|---|
| 6.1 | `TestTreasuryRoutingInsufficientBalanceForBoth` | Payer balance < merchantNet + treasuryShare | Both transfers fail, error returned, no settlement stored |
| 6.2 | `TestTreasuryRoutingInsufficientBalanceForTreasury` | Payer balance enough for merchant but not treasury | Treasury transfer fails, both roll back, no settlement stored |
| 6.3 | `TestTreasuryRoutingMerchantTransferFails` | Mock merchant transfer error | Treasury never attempted, settlement not stored |
| 6.4 | `TestTreasuryRoutingTreasuryTransferFails` | Mock treasury transfer error after merchant succeeds | Both roll back (SDK atomicity), settlement not stored, merchant balance unchanged |
| 6.5 | `TestTreasuryRoutingNoSettlementAfterFailedTreasurySend` | Treasury transfer fails | GetAllSettlements empty, no FundsSettled=true record exists |
| 6.6 | `TestTreasuryRoutingMerchantBalanceUnchangedAfterTreasuryFail` | Treasury transfer fails | Mock merchant balance returns to pre-transfer level (rollback) |

### Category 7: Double-Completion and Replay

| # | Test Name | Input | Expected |
|---|---|---|---|
| 7.1 | `TestTreasuryRoutingUniqueIDs` | Two identical settlements with treasury routing | Different IDs, both complete |
| 7.2 | `TestTreasuryRoutingCannotRecomplete` | Create then attempt status change | Status change blocked (FundsSettled=true guard) |
| 7.3 | `TestTreasuryRoutingSamePayerMerchantRepeated` | Three identical settlements | All three succeed with different IDs |

### Category 8: Status Guards (Extended from Phase 5F.2)

| # | Test Name | Input | Expected |
|---|---|---|---|
| 8.1 | `TestTreasuryRoutingStatusChangeBlocked` | Live treasury-settled record | UpdateSettlementStatus to Refunded/Failed/Cancelled all blocked |
| 8.2 | `TestTreasuryRoutingCompletedNotTerminal` | Live treasury-settled | IsTerminal() == false (Completed is not terminal) |
| 8.3 | `TestTreasuryRoutingMetadataStatusChangeAllowed` | TreasuryRoutingEnabled=false | Metadata settlements can still transition (unchanged) |

### Category 9: Invariant Helpers

| # | Test Name | Input | Expected |
|---|---|---|---|
| 9.1 | `TestTreasuryRoutingActiveSettledTotals` | One treasury-routed settlement | Totals == merchantNet (treasury share not included — totals track merchant net) |
| 9.2 | `TestTreasuryRoutingValidateFundsInvariantClean` | Treasury-routed settlement | ValidateSettlementFundsInvariant returns nil |
| 9.3 | `TestTreasuryRoutingInvariantMultipleRecords` | Mix of metadata, merchant-only, and treasury-routed | Invariant clean; totals sum only live-settled records |

### Category 10: Module Account Safety

| # | Test Name | Input | Expected |
|---|---|---|---|
| 10.1 | `TestTreasuryModuleAccountReceivesOnlyViaMsg` | Direct SendCoins to nexarail_treasury from user | Blocked by bank module's blockedAddrs (not settlement-specific) |
| 10.2 | `TestTreasuryRoutingUsesCorrectModuleName` | TreasuryRoutingEnabled=true | SendCoinsFromAccountToModule recipientModule == "nexarail_treasury" |
| 10.3 | `TestTreasuryRoutingCoinsReceivedByModule` | TreasuryRoutingEnabled=true | Mock module balance for "nexarail_treasury" increases by treasuryShare |

### Category 11: Denom Handling

| # | Test Name | Input | Expected |
|---|---|---|---|
| 11.1 | `TestTreasuryRoutingDenomMatchesSettlement` | Settlement in unxrl | Treasury transfer in unxrl |
| 11.2 | `TestTreasuryRoutingDenomConsistent` | Settlement denom = unxrl | merchant transfer denom = unxrl, treasury transfer denom = unxrl |

### Category 12: Regression — All Previous Tests Still Pass

| # | Test Name | Input | Expected |
|---|---|---|---|
| 12.1 | All 51 existing settlement keeper tests | Unchanged setup | All pass (TreasuryRoutingEnabled defaults to false) |

## Mock BankKeeper Updates (Phase 5F.4)

```go
type mockBankKeeper struct {
    balances           map[string]sdk.Coins
    moduleBalances     map[string]sdk.Coins  // NEW: module account balances
    sendCalled         bool
    sendToModuleCalled bool                   // NEW
    sendError          error
    sendToModuleError  error                  // NEW
    lastFrom           sdk.AccAddress
    lastTo             sdk.AccAddress
    lastAmount         sdk.Coins
    lastToModule       string                 // NEW
    lastModuleAmount   sdk.Coins              // NEW
}

func (m *mockBankKeeper) SendCoinsFromAccountToModule(ctx sdk.Context, from sdk.AccAddress, recipientModule string, amt sdk.Coins) error {
    m.sendToModuleCalled = true
    m.lastFrom = from
    m.lastToModule = recipientModule
    m.lastModuleAmount = amt
    if m.sendToModuleError != nil {
        return m.sendToModuleError
    }
    // Update mock balances
    fromBal := m.balances[from.String()]
    modBal := m.moduleBalances[recipientModule]
    m.balances[from.String()] = fromBal.Sub(amt...)
    m.moduleBalances[recipientModule] = modBal.Add(amt...)
    return nil
}
```

## Test Count Summary

| Category | Count |
|---|---|
| 1. Metadata default path unchanged | 3 |
| 2. Merchant-only path preserved | 4 |
| 3. TreasuryRouting + LiveDisabled (no-op) | 2 |
| 4. Live merchant + treasury success | 10 |
| 5. Fee calculation | 5 |
| 6. Failure paths | 6 |
| 7. Double-completion / replay | 3 |
| 8. Status guards | 3 |
| 9. Invariant helpers | 3 |
| 10. Module account safety | 3 |
| 11. Denom handling | 2 |
| 12. Regression (existing tests) | 51 (existing) |
| **Total new tests** | **44** |
| **Total after Phase 5F.4** | **~95** |

## Verification Commands (post-implementation)

```bash
cd ~/workspace/nexarail
go mod tidy
go mod verify
go build ./...
go vet ./...
go test ./...                    # all packages
go test ./x/settlement/... -v    # settlement-specific verbose
```

## Pass Criteria

- [ ] All 44 new tests pass
- [ ] All 51 existing settlement tests still pass
- [ ] All escrow tests pass (no regression)
- [ ] All treasury tests pass (no regression)
- [ ] All payout tests pass (no regression)
- [ ] `go build ./...` exit 0
- [ ] `go vet ./...` exit 0
- [ ] `go mod verify` exit 0
