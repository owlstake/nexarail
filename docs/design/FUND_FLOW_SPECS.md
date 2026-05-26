# NexaRail Live Fund Flow Specifications

## A. Settlement Live Transfer

**Status:** Phase 5F.4 live — merchant + treasury routing behind separate governance flags.

### State
- `Settlement` record with status, amount, fee split values, `FundsSettled`, `BurnExecuted`
- NO fee router usage (deferred)

### Current Live Flow (Phase 5F.4)

1. **MsgCreateSettlement** received
2. Validate: settlements enabled (`Enabled`), merchant active, amount positive, denom matches
3. Calculate fee: `baseFee = amount × feeRateBps ÷ 10000`
4. Apply merchant rebate: `discount = baseFee × tierBps ÷ 10000`, `netFee = baseFee - discount`
5. Split netFee: `valShare = netFee × valBps ÷ 10000`, `treasuryShare = netFee × treasBps ÷ 10000`, `burnShare = netFee - valShare - treasuryShare`
6. Calculate merchant net: `merchantNet = amount - netFee`
7. **Transfer step (gated by LiveEnabled and TreasuryRoutingEnabled):**
   a. `bank.SendCoins(payer → merchant, merchantNet)` ← always if LiveEnabled=true
   b. `bank.SendCoinsFromAccountToModule(payer → nexarail_treasury, treasuryShare)` ← if TreasuryRoutingEnabled=true AND treasuryShare > 0
   c. Burn share: metadata only (deferred to Phase 5F.6)
   d. Validator share: metadata only (deferred to Phase 5F.6+)
8. Set settlement status to COMPLETED, FundsSettled=true
9. Store settlement record, update indexes
10. Emit `settlement_created` event with `funds_settled` and `treasury_routed` attributes

### Flag Matrix

| LiveEnabled | TreasuryRoutingEnabled | Transfers |
|---|---|---|
| false | * | None (metadata-only) |
| true | false | payer → merchant |
| true | true | payer → merchant, payer → nexarail_treasury |

### Failure Handling
- All bank transfers happen BEFORE state mutation
- Any transfer failure → error returned → SDK transaction rolls back entirely
- No partial execution possible (Cosmos SDK atomicity)
- Settlement record only stored after all transfers succeed

## B. Escrow Live Custody

### Create + Fund

1. **MsgCreateEscrow** received with `fund_now = true` (or separate funding step)
2. Validate: escrows enabled, merchant active, buyer != seller, amount positive
3. Create escrow record with status = CREATED
4. **Transfer:** `bank.SendCoinsFromAccountToModule(buyer, nexarail_escrow, amount)`
5. Set escrow status = FUNDED
6. Store escrow record, update indexes
7. Emit `escrow_funded` event

### Release

1. **MsgReleaseEscrow** received (buyer or authority)
2. Validate: escrow exists, status = FUNDED, signer authorized
3. **Transfer:** `bank.SendCoinsFromModuleToAccount(nexarail_escrow, seller, amount)`
4. Set escrow status = RELEASED
5. Update record with release metadata
6. Emit `escrow_released` event

### Refund

1. **MsgRefundEscrow** received (seller or authority)
2. Validate: escrow exists, status = FUNDED, signer authorized
3. **Transfer:** `bank.SendCoinsFromModuleToAccount(nexarail_escrow, buyer, amount)`
4. Set escrow status = REFUNDED
5. Emit `escrow_refunded` event

### Dispute Resolution

1. **MsgResolveDispute** received (authority only)
2. Validate: escrow status = DISPUTED
3. If BUYER_WINS: transfer from `nexarail_escrow` to buyer
4. If SELLER_WINS: transfer from `nexarail_escrow` to seller
5. If REJECTED: escrow returns to FUNDED status (no transfer needed)
6. Set dispute status and escrow status accordingly
7. Emit `escrow_dispute_resolved` event

## C. Payout Live Transfer — IMPLEMENTED (Phase 5E)

Gated by `x/payout` `params.live_enabled` (default false). Funding source: `nexarail_treasury`.

### Mark Paid (Treasury-funded)

1. **MsgMarkPayoutPaid** received (authority only)
2. Validate: payout exists, not already `funds_paid`, status = APPROVED
3. Read params. If `live_enabled = false`: metadata-only — set status = PAID, record external reference, `funds_paid` stays false, no bank call. Done.
4. If `live_enabled = true`:
   a. Resolve recipient bech32; verify `net_amount` is positive
   b. **Transfer (before any state mutation):** `bank.SendCoinsFromModuleToAccount(nexarail_treasury, recipient, net_amount)`
   c. Only on success: `funds_paid = true`
5. Set status = PAID, record `paid_at`/`updated_at`, external reference, optional memo
6. Store payout, emit `payout_paid` event with `funds_paid` attribute

### Failure

- If the transfer fails (e.g. insufficient treasury balance), the message errors with `ErrLiveTransferFailed` and the payout state is left **unchanged** (still APPROVED, `funds_paid=false`). Cosmos SDK transaction atomicity also reverts any partial writes.
- No partial execution; no double-pay (`funds_paid` + status guard).

### Not in v1

- Live **batch** payout execution — `MarkPayoutPaid` is per-payout. Batch records do not auto-transition.
- Budget `spent_amount` linkage for payouts (treasury spends handle budgets; payout↔budget linkage is future work).

## D. Treasury Live Spending

### Execute Spend

1. **MsgMarkSpendExecuted** received (authority)
2. Validate: spend exists, status = APPROVED
3. Check treasury balance: `bank.GetBalance(nexarail_treasury, denom) >= spend.amount`
4. **Transfer:** `bank.SendCoinsFromModuleToAccount(nexarail_treasury, recipient, spend.amount)`
5. Set spend status = EXECUTED, record executed_at
6. If linked to budget: increment `budget.spent_amount`
7. If linked to grant: increment `grant.completed_milestones`
8. Emit `spend_executed` event

## E. Fee Routing (Per Block)

### BeginBlock Handler

1. Read `fee_collector` balance
2. If balance > 0 and live fee routing enabled:
   a. Read fee split params from x/fees (validatorShare, treasuryShare, burnShare)
   b. Calculate amounts for each destination
   c. Route treasury share to `nexarail_treasury`
   d. Burn burn share via `bank.BurnCoins`
   e. Validator share: leave with distribution module (existing SDK behaviour)
3. Ensure fee_router balance is zero after routing (if intermediate account used)

### What Remains Metadata-Only

- Fee split params continue to be governance-updatable (already live)
- Actual fee routing is new functionality
