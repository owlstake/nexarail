# NexaRail Live Fund Invariants

## Supply Invariants

1. **Total supply conservation:** `totalSupply(before) == totalSupply(after) - burnedAmount`
   - Every transfer moves coins; only `bank.BurnCoins` reduces supply.
   - No unauthorised minting. Module accounts do not have `minter` permission.

2. **Escrow balance:** `nexarail_escrow.balance == sum(e.amount for all e in escrows where e.status IN (FUNDED))`
   - Escrow module account holds exactly the sum of all funded, unreleased escrow amounts.
   - Release/refund removes from both the account and the escrow total.

3. **Treasury balance ≥ sum of approved but unexecuted spends and payouts.**
   - Before executing a spend, check `treasury.balance >= spend.amount`.
   - `treasury.balance` should never go negative.

4. **Fee split totals:** `validatorShareBps + treasuryShareBps + burnShareBps == 10000`
   - Enforced at parameter update time (existing invariant from x/fees).
   - Enforced at routing time (BeginBlock check).

## State Machine Invariants

5. **No terminal transition:** Settlement, escrow, and payout statuses in terminal states (FAILED, REFUNDED, RELEASED, CANCELLED, PAID) cannot transition to non-terminal states.

6. **Double execution prevention:** A spend or payout in EXECUTED status cannot be executed again.

7. **Treasury spend FundsExecuted consistency (Phase 5D):** `FundsExecuted=true` must only exist on spends with `Status=SpendExecuted`. Enforced by `ValidateSpendInvariant(ctx)`.

8. **Treasury executed spend totals (Phase 5D):** `ActiveExecutedSpendTotals(ctx)` returns the sum of all spends with `FundsExecuted=true` and `Status=SpendExecuted`.

8a. **Payout funds-paid consistency (Phase 5E):** `FundsPaid=true` must only exist on payouts with `Status=PayoutPaid`, and such payouts must carry a valid recipient and a positive net amount. Enforced by `ValidatePayoutFundsInvariant(ctx)`. A paid payout cannot transition back to an active state (terminal-state rule), and no payout can be paid twice (`FundsPaid` + status guard in `MarkPayoutPaid`).

8b. **Payout paid totals (Phase 5E):** `ActivePaidPayoutTotals(ctx)` returns the sum of net amounts of all payouts with `FundsPaid=true` and `Status=PayoutPaid` — total live treasury outflow via payouts.

8c. **Settlement FundsSettled consistency (Phase 5F.2):** `FundsSettled=true` must only exist on settlements with `Status=Completed`, and such settlements must have a positive merchant net and `protocol_fee + merchant_net == gross`. Enforced by `ValidateSettlementFundsInvariant(ctx)`.

8d. **Settlement active settled totals (Phase 5F.2):** `ActiveSettledTotals(ctx)` returns the sum of merchant net across all settlements with `FundsSettled=true` and `Status=Completed` — total live settlement volume.

8e. **Settlement treasury routing (Phase 5F.4):** When `TreasuryRoutingEnabled=true`, treasury share is routed from payer to `nexarail_treasury` via `SendCoinsFromAccountToModule`. Treasury transfer only occurs when `LiveEnabled=true` AND `TreasuryRoutingEnabled=true` AND `treasuryShare > 0`. Failed treasury transfer → entire settlement rolls back (SDK atomicity). Treasury routed amount equals `settlement.TreasuryShare`.

9. **Settlement completion precondition:** Settlement status becomes COMPLETED only after all transfer steps succeed.

8. **Escrow custody precondition:** Escrow status becomes FUNDED only after buyer's coins are received in the escrow module account.

## Transfer Invariants

9. **No unauthorised sends from module accounts:** Module account sends only through authorised keeper methods with status guards.

10. **Amount sign check:** All transfer amounts must be positive.

11. **Denom match:** All transfers within a flow must use the same denomination.

12. **Balance sufficiency:** Before any send from a module account, verify the module account has sufficient balance.

## Accounting Invariants

13. **Budget consistency:** `budget.allocated_amount + budget.spent_amount ≤ budget.total_amount`

14. **Grant within budget:** `grant.amount ≤ budget.total_amount - budget.allocated_amount - budget.spent_amount` (at creation time)

15. **Treasury nominal tracking:** When treasury module account is active, nominal balances in TreasuryAccount records should track the actual module account balance.

## Fee Routing Invariants

16. **Fee router zero balance:** If intermediate fee router account is used, its balance should be zero after BeginBlock routing.

17. **Burn accounting:** Total burned supply should equal the cumulative sum of all burn shares from fee routing.

## Invariant Check Implementation

Invariants 1-4, 6, 13-17 can be checked via Cosmos SDK invariant hooks in BeginBlock/EndBlock.

Invariants 5, 7, 8, 9, 10, 11, 12 are enforced in keeper methods at execution time.

Recommended implementation:
```go
func RegisterInvariants(ir sdk.InvariantRegistry, k Keeper) {
    ir.RegisterRoute(types.ModuleName, "escrow-balance", EscrowBalanceInvariant(k))
    ir.RegisterRoute(types.ModuleName, "supply-conservation", SupplyConservationInvariant(k))
    // etc.
}
```
