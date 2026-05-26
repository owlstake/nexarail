# NexaRail Live Funds Test Plan

## Unit Tests

Per keeper, test each fund-moving method:

### x/escrow
- CreateEscrow funds escrow module account
- Escrow balance matches funded amount
- ReleaseEscrow transfers to seller
- RefundEscrow transfers to buyer
- Dispute resolution transfers to correct party
- Insufficient buyer balance → creation fails
- Release without funded status → fails
- Double release → fails
- Module account balance invariant maintained

### x/settlement
- CreateSettlement transfers fee portions correctly
- Merchant receives net amount
- Treasury share reaches treasury module account
- Burn share reduces supply
- Validator share reaches distribution
- Failed transfer → settlement status FAILED
- All or nothing (no partial settlement)

### x/payout (Phase 5E implemented)
- `MarkPayoutPaid` sends from `nexarail_treasury` to recipient (LiveEnabled=true) ✓
- Treasury module balance decreases, recipient balance increases ✓
- FundsPaid=true after successful transfer ✓
- Insufficient treasury balance → fails, state unchanged (still APPROVED, FundsPaid=false) ✓
- Double mark-paid rejected (FundsPaid + status guard) ✓
- Cancelled / failed / non-approved payout cannot be paid ✓
- Metadata-only path (LiveEnabled=false, default) preserves existing behaviour, no bank call ✓
- `ActivePaidPayoutTotals` helper sums funded+paid net amounts ✓
- `ValidatePayoutFundsInvariant` catches FundsPaid=true with non-PAID status ✓
- Budget spent_amount increments — future work (payout↔budget linkage not in v1)
- Batch live execution — future work (per-payout only in v1)

### x/treasury (Phase 5D implemented)
- MarkSpendExecuted sends from treasury module account to recipient (LiveEnabled=true)
- Insufficient balance → fail, no state change ✓
- Double execute rejected (status check) ✓
- Non-approved execute rejected ✓
- Metadata-only path (LiveEnabled=false) preserves existing behaviour ✓
- FundsExecuted tracks whether bank transfer occurred ✓
- Budget capacity respected
- Nominal balance tracking matches module account balance
- ActiveExecutedSpendTotals invariant helper ✓
- ValidateSpendInvariant catches anomalous state ✓

### x/fees
- BeginBlock routes fees correctly
- Fee split proportions match params
- Burn share reduces total supply
- Treasury share increases treasury balance
- Rounding errors don't accumulate beyond 1 uxrl per split

## Balance Before/After Tests

For each flow:
```go
func TestEscrowBalanceBeforeAfter(t *testing.T) {
    buyerBalanceBefore := bank.GetBalance(buyer)
    escrowBalanceBefore := bank.GetBalance(nexarail_escrow)
    sellerBalanceBefore := bank.GetBalance(seller)

    // Execute: fund + release
    CreateEscrow(fund=true)
    ReleaseEscrow()

    buyerBalanceAfter := bank.GetBalance(buyer)
    escrowBalanceAfter := bank.GetBalance(nexarail_escrow)
    sellerBalanceAfter := bank.GetBalance(seller)

    require.Equal(t, buyerBalanceBefore - amount, buyerBalanceAfter)
    require.Equal(t, escrowBalanceBefore, escrowBalanceAfter) // 0
    require.Equal(t, sellerBalanceBefore + amount, sellerBalanceAfter)
}
```

## Failure Mode Tests

- Buyer sends but merchant is inactive → funds returned
- Escrow dispute with no resolution → funds stuck (timeout future)
- Treasury spend exceeds balance → rejected, state unchanged
- Double execution → rejected, state unchanged
- Module account balance falls below required → panic/prevention
- Denom mismatch in multi-denom flow → rejected

## Invariant Tests

- Supply invariant: run before/after each flow
- Escrow balance invariant: check after each escrow operation
- Budget consistency: check after each grant/spend
- Fee split total: check after param change

## Integration Tests

- Full devnet: fund escrow → release → verify balances
- Full devnet: settlement → fee routing → treasury increase → burn supply decrease
- Full devnet: treasury spend → payout → recipient receives funds

## Simulation/Fuzz Tests

- Random amounts within valid range
- Random status transitions + fund movements
- Verify invariants after each random operation

## Genesis Migration Tests

- Start chain with metadata-only state
- Upgrade to live-transfer params
- Verify module account balances initialized correctly
- Existing metadata records unaffected

## Regression Tests

- All existing Phase 3 tests continue to pass
- Metadata-only paths unchanged
- Existing query paths unchanged
