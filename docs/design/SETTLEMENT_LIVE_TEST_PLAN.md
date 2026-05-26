# NexaRail Settlement Live Transfer Test Plan

**Phase:** 5F.1 — Test Design
**Date:** 2026-05-25
**Status:** Test plan complete — implementation deferred to Phase 5F.2
**Routing Option:** C — Live Merchant Transfer Only
**Reference:** SETTLEMENT_LIVE_TRANSFER_DESIGN.md, SETTLEMENT_FEE_ROUTING_OPTIONS.md

## Test Structure

Tests follow the established pattern from x/escrow and x/treasury:
- Mock `BankKeeper` injected into keeper constructor
- Each test creates a fresh keeper + context via `setup()`
- `mockBankKeeper` tracks sent coins for assertion
- Live and metadata paths tested independently

## Test Categories

### Category 1: Metadata-Only Default Path (Regression)

Verify that the existing v1 behaviour is unchanged when `LiveEnabled=false`.

| # | Test Name | Input | Expected |
|---|---|---|---|
| 1.1 | `TestCreateSettlementMetadataDefault` | LiveEnabled=false, valid payer/merchant/amount | Settlement created, status=Completed, FundsSettled=false, no bank calls |
| 1.2 | `TestCreateSettlementMetadataFeeCalculation` | LiveEnabled=false, amount=100000000unxrl (100 NXRL), feeRate=100bps, no rebate | FeeAmount=1000000unxrl (1 NXRL), TreasuryShare=200000unxrl, BurnShare=200000unxrl, ValidatorShare=600000unxrl |
| 1.3 | `TestCreateSettlementMetadataRebateApplied` | LiveEnabled=false, gold tier (1500 bps rebate) | RebateAppliedBps=1500, RebateAmount=baseFee*1500/10000, netFee=baseFee-rebateAmount |
| 1.4 | `TestCreateSettlementMetadataNoBankCalls` | LiveEnabled=false, any valid input | mockBankKeeper.sendCalled == false, settlement stored correctly |

### Category 2: LiveEnabled Gate

| # | Test Name | Input | Expected |
|---|---|---|---|
| 2.1 | `TestLiveSettlementSuccess` | LiveEnabled=true, payer has sufficient balance, valid merchant | Settlement created, status=Completed, FundsSettled=true, merchant received merchantNet |
| 2.2 | `TestLiveSettlementAmountsMatch` | LiveEnabled=true, amount=100000unxrl, feeRate=100bps | merchantNet=99000unxrl (100000 - 1000), sent amount equals calculated merchantNet |
| 2.3 | `TestLiveSettlementMerchantBalanceIncreases` | LiveEnabled=true, track mock balances | mock merchant balance increases by merchantNet |
| 2.4 | `TestLiveSettlementPayerBalanceDecreases` | LiveEnabled=true, track mock balances | mock payer balance decreases by merchantNet |
| 2.5 | `TestLiveSettlementFundsSettledFlag` | LiveEnabled=true | settlement.FundsSettled == true after CreateSettlement |
| 2.6 | `TestLiveSettlementEventIncludesFundsSettled` | LiveEnabled=true | event contains AttributeFundsSettled=true |

### Category 3: Failure Paths — No State Mutation

Verify that failed bank transfers leave no state changes.

| # | Test Name | Input | Expected |
|---|---|---|---|
| 3.1 | `TestLiveSettlementInsufficientBalance` | LiveEnabled=true, mock bank returns error | CreateSettlement returns error, settlement NOT stored, KV store has no settlement record |
| 3.2 | `TestLiveSettlementInsufficientBalanceNoFundsSettled` | LiveEnabled=true, transfer fails | No settlement record created, no FundsSettled=true anywhere |
| 3.3 | `TestLiveSettlementInvalidMerchant` | LiveEnabled=true, merchant not registered | Returns ErrInvalidMerchant, no bank calls |
| 3.4 | `TestLiveSettlementInactiveMerchant` | LiveEnabled=true, merchant status != active | Returns ErrMerchantNotActive, no bank calls |
| 3.5 | `TestLiveSettlementInvalidPayer` | LiveEnabled=true, malformed payer address | Returns error, no bank calls, no state changes |
| 3.6 | `TestLiveSettlementZeroAmount` | LiveEnabled=true, amount=0 | Returns ErrAmountNotPositive, no bank calls |
| 3.7 | `TestLiveSettlementNegativeAmount` | LiveEnabled=true, amount=-100 | Returns ErrAmountNotPositive, no bank calls |
| 3.8 | `TestLiveSettlementSettlementsDisabled` | LiveEnabled=true, Enabled=false | Returns ErrSettlementsDisabled, no bank calls |

### Category 4: Fee Calculation Accuracy

| # | Test Name | Input | Expected |
|---|---|---|---|
| 4.1 | `TestLiveFeeCalculationExactDivision` | amount=100000000unxrl, feeRate=100bps | merchantNet=99000000unxrl, no rounding error |
| 4.2 | `TestLiveFeeCalculationRoundingFloor` | amount=100000001unxrl, feeRate=100bps | merchantNet=99000001unxrl (floor — 0.99999999 gets truncated, so 100000001 - floor(100000001*100/10000) = 100000001 - 1000000 = 99000001) |
| 4.3 | `TestLiveFeeCalculationZeroFee` | feeRateBps=0 | netFee=0, merchantNet=gross, treasuryShare=0, burnShare=0, validatorShare=0 |
| 4.4 | `TestLiveFeeCalculationMaxFee` | feeRateBps=10000 (100%) | netFee=gross, merchantNet=0 |
| 4.5 | `TestLiveProtocolFeePlusMerchantNetEqualsGross` | any valid inputs | merchantNet + netFee == grossAmount |
| 4.6 | `TestLiveFeeSplitSumsToNetFee` | any valid inputs | valShare + treasuryShare + burnShare == netFee |
| 4.7 | `TestLiveRebateAppliedBeforeFeeSplit` | rebateTier=500bps | rebateAmount=baseFee*500/10000, netFee=baseFee-rebateAmount, split applied to netFee (not baseFee) |
| 4.8 | `TestLiveDustGoesToBurn` | amount that produces rounding remainder | valShare + treasuryShare < netFee, burnShare = remainder |

### Category 5: Double-Completion Prevention

| # | Test Name | Input | Expected |
|---|---|---|---|
| 5.1 | `TestLiveSettlementIdempotencyViaId` | Create settlement, then attempt duplicate ID | Each CreateSettlement gets new auto-increment ID, no conflict |
| 5.2 | `TestLiveSettlementCannotRecomplete` | Settlement already Completed, attempt to re-run CreateSettlement with same params | New settlement created (new ID), not an overwrite |
| 5.3 | `TestLiveSettlementSamePayerMerchantAmountOK` | Two settlements with identical payer/merchant/amount | Both created with different IDs — legitimate repeat payments |

### Category 6: Status Transition Rules

| # | Test Name | Input | Expected |
|---|---|---|---|
| 6.1 | `TestLiveSettlementStatusIsCompleted` | LiveEnabled=true, successful | Settlement.Status == SettlementCompleted |
| 6.2 | `TestLiveSettlementCompletedNotTerminal` | Query terminal statuses | Completed not in TerminalStatuses() |
| 6.3 | `TestLiveSettlementCanTransitionToRefunded` | Authority updates status to Refunded | UpdateSettlementStatus succeeds, status=Refunded |
| 6.4 | `TestLiveSettlementRefundedIsTerminal` | Status=Refunded | Settlement.IsTerminal() == true |
| 6.5 | `TestLiveSettlementCannotTransitionFromRefunded` | Status=Refunded, attempt UpdateSettlementStatus to Completed | Returns ErrInvalidStatusTransition |
| 6.6 | `TestLiveSettlementCannotTransitionFromFailed` | Status=Failed, attempt UpdateSettlementStatus to Completed | Returns ErrInvalidStatusTransition |
| 6.7 | `TestLiveSettlementCannotTransitionFromCancelled` | Status=Cancelled, attempt UpdateSettlementStatus to Completed | Returns ErrInvalidStatusTransition |
| 6.8 | `TestLiveSettlementCompletedToFailed` | Authority updates Completed to Failed | Succeeds — Completed is not terminal |

### Category 7: Denom Handling

| # | Test Name | Input | Expected |
|---|---|---|---|
| 7.1 | `TestLiveSettlementUnxrlDenom` | amount=100unxrl | Settlement stored with denom=unxrl |
| 7.2 | `TestLiveSettlementDenomMismatch` | amount=100unxrl, merchant denom=other | All fee fields use settlement denom (unxrl), no cross-denom transfer |
| 7.3 | `TestLiveSettlementDenomConsistency` | LiveEnabled=true | bank.SendCoins denom matches settlement.Amount.Denom |

### Category 8: Invariant Helpers

| # | Test Name | Input | Expected |
|---|---|---|---|
| 8.1 | `TestActiveSettledTotalsEmpty` | No settlements | ActiveSettledTotals returns empty Coins |
| 8.2 | `TestActiveSettledTotalsSingleLive` | One live settlement | Totals equal merchantNet of that settlement |
| 8.3 | `TestActiveSettledTotalsMultipleLive` | Three live settlements | Totals equal sum of all merchantNet amounts |
| 8.4 | `TestActiveSettledTotalsExcludesMetadata` | One live settlement, one metadata-only | Totals only includes the live settlement |
| 8.5 | `TestActiveSettledTotalsExcludesNonCompleted` | One live settlement, one Failed settlement with FundsSettled=true | Totals only includes Completed (not Failed) |
| 8.6 | `TestActiveSettledTotalsExcludesRefunded` | One live Completed, one Refunded | Totals only includes Completed |
| 8.7 | `TestValidateSettlementInvariantClean` | All settlements consistent | ValidateSettlementInvariant returns nil |
| 8.8 | `TestValidateSettlementInvariantFundsSettledNotCompleted` | Settlement with FundsSettled=true, Status=Refunded | Returns error describing violation |
| 8.9 | `TestValidateSettlementInvariantMetadataOnlyClean` | All metadata-only settlements, no live | ValidateSettlementInvariant returns nil |

### Category 9: BankKeeper Integration

| # | Test Name | Input | Expected |
|---|---|---|---|
| 9.1 | `TestLiveSettlementBankKeeperCalled` | LiveEnabled=true | mockBankKeeper.sendCalled == true |
| 9.2 | `TestLiveSettlementBankKeeperNotCalledMetadata` | LiveEnabled=false | mockBankKeeper.sendCalled == false |
| 9.3 | `TestLiveSettlementCorrectRecipient` | LiveEnabled=true, valid merchant | bank.SendCoins recipient == settlement.SettlementAddress |
| 9.4 | `TestLiveSettlementCorrectAmount` | LiveEnabled=true, amount=100000unxrl, feeRate=100bps | bank.SendCoins amount == 99000unxrl (merchantNet) |
| 9.5 | `TestLiveSettlementBankErrorPropagation` | LiveEnabled=true, mock bank returns specific error | CreateSettlement returns error containing bank error text |

### Category 10: Indexes

| # | Test Name | Input | Expected |
|---|---|---|---|
| 10.1 | `TestLiveSettlementIndexedByMerchant` | Live settlement | GetSettlementsByMerchant includes it |
| 10.2 | `TestLiveSettlementIndexedByPayer` | Live settlement | GetSettlementsByPayer includes it |
| 10.3 | `TestLiveSettlementInGetAll` | Live settlement | GetAllSettlements includes it |

### Category 11: App Integration (in app_test.go)

| # | Test Name | Input | Expected |
|---|---|---|---|
| 11.1 | `TestSettlementKeeperHasBankKeeper` | App initialised | app.SettlementKeeper has non-nil bankKeeper |
| 11.2 | `TestSettlementModuleRegistered` | App initialised | Settlement module in ModuleManager |
| 11.3 | `TestSettlementDefaultParamsLiveEnabledFalse` | App genesis | DefaultParams().LiveEnabled == false |

## Mock BankKeeper

```go
type mockBankKeeper struct {
    balances   map[string]sdk.Coins
    sentCoins  []sentCoin
    sendError  error
    sendCalled bool
}

type sentCoin struct {
    From   string
    To     string
    Amount sdk.Coins
}

func (m *mockBankKeeper) SendCoins(ctx sdk.Context, from, to sdk.AccAddress, amt sdk.Coins) error {
    m.sendCalled = true
    if m.sendError != nil {
        return m.sendError
    }
    m.sentCoins = append(m.sentCoins, sentCoin{From: from.String(), To: to.String(), Amount: amt})
    // Update mock balances
    fromBal := m.balances[from.String()]
    toBal := m.balances[to.String()]
    m.balances[from.String()] = fromBal.Sub(amt...)
    m.balances[to.String()] = toBal.Add(amt...)
    return nil
}
```

## Test Setup

```go
func setup() (keeper.Keeper, sdk.Context, *mockBankKeeper) {
    storeKey := storetypes.NewKVStoreKey(types.StoreKey)
    memKey := storetypes.NewMemoryStoreKey(types.MemStoreKey)

    // Mock merchant keeper
    merchantKeeper := &mockMerchantKeeper{
        merchants: map[string]types.Merchant{},
    }
    // Register a valid active merchant
    merchantAddr := sdk.AccAddress([]byte("merchant-address"))
    merchantKeeper.merchants[merchantAddr.String()] = types.Merchant{
        Owner:      merchantAddr.String(),
        Name:       "test-merchant",
        Status:     0,  // active
        RebateTier: 0,  // none
    }

    // Mock fees keeper
    feesKeeper := &mockFeesKeeper{
        params: feestypes.DefaultParams(),
    }

    // Mock bank keeper with sufficient payer balance
    payerAddr := sdk.AccAddress([]byte("payer-address"))
    bankKeeper := &mockBankKeeper{
        balances: map[string]sdk.Coins{
            payerAddr.String(): sdk.NewCoins(sdk.NewInt64Coin("unxrl", 1000000000)),
        },
    }

    // Create keeper
    k := keeper.NewKeeper(
        storeKey,
        "nexa1authority...",
        merchantKeeper,
        feesKeeper,
        bankKeeper,
    )

    ctx := sdk.NewContext(...)
    k.SetParams(ctx, types.DefaultParams())

    return k, ctx, bankKeeper
}
```

## Test Count Summary

| Category | Count |
|---|---|
| 1. Metadata Default Path | 4 |
| 2. LiveEnabled Gate | 6 |
| 3. Failure Paths | 8 |
| 4. Fee Calculation | 8 |
| 5. Double-Completion Prevention | 3 |
| 6. Status Transitions | 8 |
| 7. Denom Handling | 3 |
| 8. Invariant Helpers | 9 |
| 9. BankKeeper Integration | 5 |
| 10. Indexes | 3 |
| 11. App Integration | 3 |
| **Total new tests** | **60** |

Plus existing settlement tests (~51 from Phase 3.3) = ~111 total settlement tests after Phase 5F.2.

## Verification Commands (post-implementation)

```bash
cd ~/workspace/nexarail
go mod tidy
go mod verify
go build ./...
go vet ./...
go test ./...                    # all packages
go test ./x/settlement/... -v    # settlement-specific verbose
go test ./app/... -v -run Settlement  # app integration tests
```

## Pass Criteria

- [ ] All 60 new tests pass
- [ ] All ~51 existing settlement tests still pass (no regression)
- [ ] All escrow tests still pass (no regression in x/escrow)
- [ ] All treasury tests still pass (no regression in x/treasury)
- [ ] All payout tests still pass (no regression in x/payout)
- [ ] `go build ./...` exit 0
- [ ] `go vet ./...` exit 0
- [ ] `go mod verify` exit 0
