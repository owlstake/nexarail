# NexaRail Validator Distribution Test Plan

**Phase:** 5F.7 — Test Design
**Date:** 2026-05-25
**Status:** Test plan complete — implementation DEFERRED pending distribution review
**Recommended option:** A (defer) / B (fee_collector) if required

## Test Scenarios for Option B (fee_collector)

If validator distribution is implemented later via Option B:

### Category 1: Flag Control

| # | Test Name | Expected |
|---|---|---|
| 1.1 | `TestValidatorRoutingDefaultFalse` | ValidatorRoutingEnabled == false |
| 1.2 | `TestValidatorRoutingRequiresAllFlags` | ValidatorRoutingEnabled=true but LiveEnabled=false → no bank calls |
| 1.3 | `TestValidatorRoutingDisabledNoFeeCollectorCall` | Fee collector balance unchanged when flag is false |

### Category 2: fee_collector Integration

| # | Test Name | Expected |
|---|---|---|
| 2.1 | `TestValidatorRoutingFeeCollectorReceivesShare` | fee_collector module balance += validatorShare |
| 2.2 | `TestValidatorRoutingCorrectModuleName` | SendCoinsFromAccountToModule called with "fee_collector" |
| 2.3 | `TestValidatorRoutingPayerTotalDeduction` | Payer balance -= merchantNet + treasuryShare + burnShare + validatorShare |
| 2.4 | `TestValidatorRoutingZeroShareSkips` | FeeRateBps=0 → validatorShare=0 → no fee_collector transfer |
| 2.5 | `TestValidatorRoutingSupplyConserved` | Total supply unchanged (payer→fee_collector is supply-conserving) |

### Category 3: Failure Paths

| # | Test Name | Expected |
|---|---|---|
| 3.1 | `TestValidatorRoutingInsufficientBalance` | Payer can't cover full amount → error, no settlement stored |
| 3.2 | `TestValidatorRoutingFeeCollectorTransferFails` | fee_collector transfer fails → all roll back, no settlement stored |
| 3.3 | `TestValidatorRoutingNotStoredAfterFailure` | Failed validator transfer → GetAllSettlements empty |

### Category 4: No Double-Counting Gas Fees

| # | Test Name | Expected |
|---|---|---|
| 4.1 | `TestValidatorRoutingFeeCollectorAggregates` | Multiple settlements → fee_collector balance = sum of all validator shares |
| 4.2 | `TestValidatorRoutingFeeCollectorIndependentOfGas` | Gas fees in fee_collector are additive, not conflicting |

### Category 5: Distribution Module Integration (Integration Test)

| # | Test Name | Expected |
|---|---|---|
| 5.1 | `TestAllocateTokensIncludesSettlementFees` | After AllocateTokens, fee_collector balance = 0, validator rewards increased |
| 5.2 | `TestProposerRewardAppliesToSettlementFees` | Proposer receives bonus proportional to total fee_collector balance |
| 5.3 | `TestCommunityTaxAppliesToSettlementFees` | Community tax (if set) reduces validator share proportionally |

### Category 6: Regression

| # | Test Name | Expected |
|---|---|---|
| 6.1 | All 93 existing settlement tests | All pass (ValidatorRoutingEnabled defaults false) |
| 6.2 | All x/distribution tests | Unchanged |
| 6.3 | All x/staking tests | Unchanged |
| 6.4 | All app integration tests | Unchanged |

### Category 7: BeginBlock Routing (Option D only — deferred)

| # | Test Name | Expected |
|---|---|---|
| 7.1 | `TestFeeRouterBalanceZeroAfterBeginBlock` | fee_router emptied after distribution |
| 7.2 | `TestCustomDistributionMatchesVotingPower` | Validator rewards proportional to voting power |
| 7.3 | `TestCustomDistributionCommissionApplied` | Commission deducted before delegator shares |

## Test Count Summary

| Category | Count |
|---|---|
| Flag control | 3 |
| fee_collector integration | 5 |
| Failure paths | 3 |
| No double-counting | 2 |
| Distribution integration | 3 |
| Regression | 93 existing + all other modules |
| **Total new tests (Option B)** | **~16** |

## Verification Commands (if implemented)

```bash
cd ~/workspace/nexarail
go mod tidy && go mod verify && go build ./... && go vet ./... && go test ./...
```

## Pass Criteria

- [ ] All ~16 new tests pass
- [ ] All 93 existing settlement tests pass
- [ ] All distribution, staking, escrow, treasury, payout tests pass
- [ ] `go build ./...` exit 0
- [ ] `go vet ./...` exit 0
- [ ] Distribution specialist review completed
- [ ] Testnet AllocateTokens behaviour verified
