# NexaRail Live Funds Threat Model

## 1. Unauthorised Module Account Spend

**Threat:** A malicious keeper method or gRPC handler sends coins from a module account without proper authorisation or state validation.

**Mitigation:**
- All `bank.SendCoinsFromModule*` calls are wrapped in keeper methods with explicit validation
- Status guards check the state before any transfer
- No raw `bank.SendCoins` calls in gRPC handlers — all go through keeper
- Unit tests verify that unauthorised callers cannot trigger sends

## 2. Incorrect Fee Split

**Threat:** Fee routing produces incorrect splits due to rounding errors, param changes mid-block, or arithmetic bugs.

**Mitigation:**
- Integer arithmetic only (basis points)
- Burn share = total - validator - treasury (enforces exact split)
- Fee split params are checked by invariant in BeginBlock
- Dust (< 1 uxrl) from integer division goes to burn share

## 3. Double Execution

**Threat:** A payout or spend request is executed twice, double-spending treasury funds.

**Mitigation:**
- Status guard: only APPROVED → EXECUTED transition allowed
- Status check happens BEFORE the bank transfer
- Bank transfer and status update happen atomically (same transaction)
- Transaction sequence numbers (Cosmos SDK) prevent replay

## 4. Replayed Messages

**Threat:** An old signed message is re-broadcast to trigger a second transfer.

**Mitigation:**
- Cosmos SDK account sequences prevent replay by default
- Once a message is included in a block, the sequence number increments
- No custom replay protection needed

## 5. Stuck Funds

**Threat:** Escrow funds become permanently locked with no resolution path.

**Mitigation:**
- Authority can always resolve disputes (buyer_wins, seller_wins, rejected)
- Expired escrows (future): auto-refund or auto-release based on params
- Emergency governance can force-release all escrows by updating module params

## 6. Failed Send After State Mutation

**Threat:** The bank transfer fails after the module state was already updated, leaving state inconsistent.

**Mitigation:**
- All state mutations happen AFTER successful bank transfers
- Pattern: `bank.Send → updateStatus → storeRecord → emitEvent`
- If bank.Send fails, the entire transaction reverts (Cosmos SDK atomicity)

## 7. Reentrancy-Style Logic

**Threat:** A keeper method calls another keeper method which calls back, causing unexpected state changes.

**Mitigation:**
- Cosmos SDK transactions are not reentrant (single-threaded execution)
- Keeper methods do not call other keeper methods that could trigger the same flow
- Escrow release only sends coins; it does not call settlement or payout keepers

## 8. Authority Compromise

**Threat:** The governance module address is compromised, allowing an attacker to change params and execute arbitrary treasury spends.

**Mitigation:**
- Governance requires proposal + voting period + threshold
- Spending limits per time period (future enhancement)
- Multi-sig governance for large spends (future enhancement)
- Emergency pause params stop all transfers

## 9. Governance Attack

**Threat:** A malicious governance proposal enables live transfers and immediately drains all module accounts.

**Mitigation:**
- Governance voting period provides time for community review
- Live transfer params are per-module (can enable escrow independently of treasury)
- Treasury spends are individually gated by spend request approval

## 10. Blocked Address Mistakes

**Threat:** A module account is missing from `blockedAddrs`, allowing users to send coins directly to it outside message paths.

**Mitigation:**
- All module accounts are added to `blockedAddrs` at genesis
- Runtime invariant checks module account balances against expected state
- Any discrepancy is flagged

## 11. Burn Accounting Errors

**Threat:** Burn amount is incorrectly calculated, burning more or less than intended.

**Mitigation:**
- Burn calculation uses the same integer arithmetic as fee split
- Total supply invariant catches over-burn
- Burn happens in the same BeginBlock as fee routing — consistent params

## 12. Rounding/Dust Issues

**Threat:** Integer division in fee splitting produces dust amounts that accumulate over time.

**Mitigation:**
- Base unit is `unxrl` (6 decimal places from NXRL) — dust at 1 unxrl is 0.000001 NXRL
- Any remainder from division goes to burn (eliminates dust tracking)
- Periodic invariant checks catch significant accumulation

## 13. Denom Mismatch

**Threat:** A settlement in one denom routes fees in a different denom, causing incorrect accounting.

**Mitigation:**
- All transfers within a flow use the same denom (checked at message validation)
- Module account balance checks use the correct denom
- Future multi-denom support requires explicit denom parameters

## 14. Migration Failure

**Threat:** State migration from v1 (metadata-only) to v2 (live transfers) corrupts balances.

**Mitigation:**
- Migration does not touch existing records — only adds module accounts
- Module accounts start with zero balance
- Existing metadata-only state continues to function
- Live transfers are opt-in via governance params

## 15. Emergency Pause Abuse

**Threat:** Authority pauses live transfers to freeze user funds in escrow.

**Mitigation:**
- Pause only prevents NEW transfers — existing escrows can still be released/refunded
- Pause is a governance action requiring proposal + vote
- Community can propose unpause

## 16. Malicious Merchant/Payout Records

**Threat:** A merchant creates fake settlement records, or an attacker creates payout records to themselves.

**Mitigation:**
- Settlements require valid, active merchants
- Payouts require approved status and authority execution
- Treasury spends require spend request approval
- All fund movement is gated by status checks

## 17. Treasury Spend Double-Execution (Phase 5D)

**Threat:** A treasury spend is marked executed twice, resulting in double disbursement of funds.

**Mitigation:**
- `MarkSpendExecuted` requires `Status=SpendApproved`; after execution, status is `SpendExecuted`
- Second call fails with invalid transition error
- `FundsExecuted` field provides secondary guard — invariant rejects `FundsExecuted=true` on non-EXECUTED spends
- `ValidateSpendInvariant(ctx)` catches anomalous state

## 18. Treasury Spend Without Live Funds (Phase 5D)

**Threat:** Governance enables `LiveEnabled` but treasury module account has no balance; spend execution transfers nothing or panics.

**Mitigation:**
- Bank transfer is checked before state mutation; if it fails, the entire transaction rolls back
- `FundsExecuted` is only set to `true` after successful bank transfer
- Metadata-only path (LiveEnabled=false) remains the default and does not touch bank keeper

## 19. Payout Double-Pay / Failed Transfer (Phase 5E)

**Threat:** A live payout is paid twice (double-draining treasury), or the treasury→recipient transfer fails after state was already mutated, leaving an inconsistent record.

**Mitigation:**
- `MarkPayoutPaid` requires `Status=PayoutApproved` and `FundsPaid=false`; after payment, status is `PayoutPaid` and `FundsPaid=true`, so a second call fails on both guards
- The bank transfer happens **before** any state mutation; on failure the message returns `ErrLiveTransferFailed` and the payout is left untouched (still APPROVED, `FundsPaid=false`). SDK transaction atomicity reverts partial writes
- `FundsPaid` is only set `true` after a successful transfer; `ValidatePayoutFundsInvariant(ctx)` rejects `FundsPaid=true` on non-PAID payouts
- Cancelled, failed, and non-approved payouts cannot be paid (status guard)

## 20. Payout Live Funding Scope (Phase 5E)

**Threat:** Enabling payout `live_enabled` inadvertently activates settlement live transfers or fee routing, or drains accounts other than the treasury.

**Mitigation:**
- Payout `live_enabled` is independent and per-module; it only affects `MarkPayoutPaid`
- The only funding source is `nexarail_treasury` via `SendCoinsFromModuleToAccount`; no other module account is touched
- Settlement live transfers and fee routing remain non-live (separate, later phases)
- Live **batch** execution is not implemented — only individually approved, per-payout transfers occur
