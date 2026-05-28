# Phase 8E — Stress Test Plan

**Date:** 2026-05-26
**Phase:** 8E

---

## Scope

Deeper automated correctness testing beyond unit/integration tests. Focus on invariants, fuzzing, randomized operations, and failure injection.

## Modules Covered

| Module | Invariants | Fuzz | Randomized | Failure Injection |
|---|---|---|---|---|
| x/fees | ✅ | ✅ | ✅ | ✅ |
| x/merchant | ✅ | ✅ | ✅ | ✅ |
| x/settlement | ✅ | ✅ | ✅ | ✅ |
| x/escrow | ✅ | ✅ | ✅ | ✅ |
| x/payout | ✅ | ✅ | ✅ | ✅ |
| x/treasury | ✅ | ✅ | ✅ | ✅ |

## Invariant Scope

### x/fees
- Fee shares sum to 10000 bps
- No negative fee components
- Treasury/burn/validator shares cannot individually exceed fee total

### x/merchant
- Owner index points to existing merchant
- Closed merchants cannot update
- Status enum valid

### x/settlement
- FundsSettled=true requires completed status
- BurnExecuted=true requires FundsSettled=true
- Merchant net + fee <= gross amount
- Live flags default false
- No settlement stored after failed transfer

### x/escrow
- Released/refunded escrows cannot retain custodied funds
- Terminal statuses cannot transition improperly
- Buyer/seller/merchant indexes point to existing escrows

### x/payout
- FundsPaid=true requires paid status
- Paid/cancelled payouts cannot be paid again
- Batch total equals sum of child payouts

### x/treasury
- FundsExecuted=true requires executed status
- Spent amount cannot exceed budget
- Cancelled/completed grants cannot transition

## Fuzzing Scope

| Target | Type |
|---|---|
| Fee split arithmetic | uint32 overflow/underflow |
| Settlement fee/rebate calculation | Integer division correctness |
| Escrow ID validation | Empty/malformed IDs |
| Payout ID validation | Empty/malformed IDs |
| Treasury budget validation | Negative/zero amounts |
| Address parsing | Invalid Bech32 |
| Coin amount validation | Negative/overflow amounts |

## Randomized Operations

Keeper-level randomized tests with seeded RNG:
- Random merchant create/update/status transitions
- Random settlement creation with random amounts
- Random escrow lifecycle transitions
- Random payout lifecycle transitions
- Random treasury budget/grant/spend transitions

Deterministic seeds for reproducibility. Assert invariants after each operation.

## Failure Injection

Mock-based failure injection:
- Bank.SendCoins failure → no state mutation
- Insufficient balance → error, no state change
- Duplicate ID → error, no state change
- Invalid denom → error, no state change
- Missing merchant → error, no state change
- Unauthorized authority → error, no state change

## Excluded / Deferred

- Full Cosmos SDK simulation framework (too heavy for current phase)
- Race detector testing (heavy resource usage, CI-unfriendly)
- Multi-node consensus fault injection (requires running network)
- Performance fuzzing (not about correctness)

## Success Criteria

- [ ] All existing tests still pass
- [ ] ≥ 1 invariant added per module
- [ ] ≥ 2 fuzz tests added
- [ ] ≥ 1 randomized test per module
- [ ] ≥ 3 failure injection tests
- [ ] `run-stress-tests.sh` exits 0
