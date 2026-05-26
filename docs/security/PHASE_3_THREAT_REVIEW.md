# Phase 3 — Threat Review

**Scope:** All six custom NexaRail modules (x/fees, x/merchant, x/settlement, x/escrow, x/payout, x/treasury)
**Date:** 2026-05-25
**Status:** Pre-audit — internal review only

## 1. Authority-Gated Methods

All authority-gated operations check `msg.Authority == k.authority`:

- x/fees: MsgUpdateParams ✓
- x/merchant: MsgUpdateParams, MsgSetMerchantStatus, MsgSetVerificationStatus, MsgSetRebateTier ✓
- x/settlement: MsgUpdateSettlementStatus, MsgUpdateParams ✓
- x/escrow: MsgResolveDispute, MsgUpdateParams, MsgReleaseEscrow (authority path), MsgRefundEscrow (authority path), MsgCancelEscrow (authority path) ✓
- x/payout: MsgMarkPayoutPaid, MsgFailPayout, MsgUpdateParams, MsgApprovePayout (authority path) ✓
- x/treasury: All 8 creation/update messages (CreateTreasuryAccount, CreateBudget, UpdateBudgetStatus, CreateGrant, UpdateGrantStatus, ApproveSpendRequest, RejectSpendRequest, MarkSpendExecuted), MsgUpdateParams ✓

**Risk:** If the authority account is compromised, an attacker could manipulate all six modules' parameters and records. Mitigation: The authority is set to the governance module address, which requires on-chain proposal + voting.

## 2. Metadata-Only Design

All four stateful modules (settlement, escrow, payout, treasury) are metadata-only in v1. No module accounts are created. No coins are held or moved. This limits blast radius if the module state is corrupted — only accounting records are affected, not actual user funds.

**Risk of future live transfers:** When live fund movement is added, careful balance accounting and invariant checks must be implemented. Escrow custody must use separate module accounts with withdrawal gating. Treasury must enforce spending limits beyond budget capacity.

## 3. Treasury Abuse Risks

The treasury module allows the authority to:
- Create unlimited budgets with arbitrary amounts ✓ (by design)
- Create unlimited grants ✓ (by design, constrained by budget capacity)
- Execute unlimited spends ✓ (by design, constrained by budget capacity)

**Risk:** If budget capacity checks are bypassed or budgets are created with unrealistic amounts, the treasury records could show misleading accounting. Mitigation: Spend execution increments `budget.spent_amount` with capacity checks. Future: Add spending rate limits per time period.

## 4. Merchant Verification Limitations

Merchant verification status (unverified/verified/rejected) is set by authority as metadata only. No on-chain identity verification, no KYC/AML checks, no credential verification.

**Risk:** A malicious or compromised authority could falsely verify merchants. Mitigation: Verification is clearly documented as metadata-only. Real identity verification must happen off-chain. Future: Consider oracle-based or multi-signature verification.

## 5. Status Transition Risks

### x/settlement
- Terminal statuses (Failed, Refunded, Cancelled) correctly block further transitions ✓
- Completed → Pending transition correctly blocked ✓

### x/escrow
- Terminal statuses (Released, Refunded, Cancelled) correctly block further transitions ✓
- Disputed escrows require authority resolution before status can change ✓
- ResolveDispute maps dispute status to correct escrow status ✓

### x/payout
- Paid/Cancelled/Failed statuses correctly block further transitions ✓
- Only CREATED/APPROVED can be cancelled/failed ✓

### x/treasury
- Closed budgets cannot reopen ✓
- Executed spends cannot be cancelled ✓
- Only REQUESTED/APPROVED spends can be cancelled ✓

**Risk:** All status transitions are enforced at the keeper level. gRPC handlers validate basic message structure. If a keeper method is called directly (bypassing gRPC), the validation still applies. ✓

## 6. Index Consistency

Each module maintains secondary indexes (by merchant, by payer, by buyer, by recipient, etc.) as KV store entries alongside primary records.

**Risk:** If a primary record is stored but its index entry fails (e.g., partial write), queries may return incomplete results. Current mitigation: Indexes are rebuilt during `InitGenesis`. Future: Add invariant checks that verify all primary records have corresponding index entries.

## 7. Genesis Import Risks

Genesis validation rejects duplicates and invalid records for all six modules.

**Risk:** If a genesis file contains valid but malicious data (e.g., 10M escrow records), the chain will import them all. No size limits on genesis state arrays. Mitigation: Genesis validation ensures state consistency. Future: Add practical size limits on genesis arrays.

## 8. gRPC Handler Risks

All gRPC service descriptors are hand-coded (not generated from protobuf). The `_h` handler pattern uses a switch-based dispatch.

**Risk:** If the proto service name changes or the method numbering shifts, handlers may silently route to wrong methods. Current mitigation: Handler numbering is documented in code. Future: Generate gRPC code from proto files using protoc when tooling is available.

## 9. Nil Coin Risks

Several keeper methods initialize coin values. If `sdk.Coin{}` (nil Amount) is passed to arithmetic operations or comparisons, it causes nil pointer dereference (panic).

**Risk:** Batch processing in payout keeper had this bug (fixed with sentinel variable). Settlement batch also had this issue in tests (fixed by test refactor). New code using `sdk.Coin` arithmetic must always initialize with `sdk.NewInt64Coin(denom, 0)`.

## 10. Denom Migration Risks

The NXR → NXRL ticker migration was completed with `sed` based replacements across all files.

**Risk:** If a new module or test references the old denom string `"unxr"`, tests may pass with a different test denom, creating a false sense of correctness. Current mitigation: Regular `grep` audits for stale denom strings. Phase 4 audit confirmed clean.

## 11. Audit Priorities

If an external security audit is planned, prioritize:

1. **Authority gating**: Verify all authority checks are correct and complete.
2. **Status transitions**: Verify no state machine bugs allow illegal transitions.
3. **Fee calculation**: Verify basis-point arithmetic for settlement fee splits.
4. **Escrow dispute resolution**: Verify buyer_wins/seller_wins/settled/rejected paths.
5. **Treasury budget capacity**: Verify allocated + spent ≤ total enforcement.
6. **Index consistency**: Verify indexes are complete and queryable.
7. **Genesis integrity**: Verify genesis validation catches all invalid states.
8. **Nil coin safety**: Verify no uninitialized coin arithmetic paths remain.
