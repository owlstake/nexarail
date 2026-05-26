# NexaRail Settlement Live Transfer Threat Model

**Phase:** 5F.1 — Security Design
**Date:** 2026-05-25
**Status:** Threat model complete
**Routing Option:** C — Live Merchant Transfer Only
**Scope:** Phase 5F.2 implementation

## Threat Surface

For Phase 5F.2 (Option C), the attack surface is:

```
MsgCreateSettlement (LiveEnabled=true)
  └─ bank.SendCoins(payer, merchant, merchantNet)
       └─ No other transfers, no burn, no treasury movement
```

Single transfer, single message handler. Minimal surface.

---

## 1. Incorrect Fee Split

**Threat ID:** SET-001
**Severity:** Medium
**Likelihood:** Low
**Impact:** Merchant receives wrong amount; fee accounting is incorrect

**Description:**
Fee calculation uses integer arithmetic with basis points. If the formula is wrong, the merchant net could be miscalculated, or fee shares could not sum correctly.

**Current Mitigation (v1, carried forward):**
- `burnShare = netFee - valShare - treasuryShare` — remainder approach ensures exact split
- `merchantNet = grossAmount - netFee` — straightforward subtraction
- Fee params validated in `Params.Validate()` — shares must sum to 10000 bps, fee rate must not exceed 10000 bps

**New Mitigation (Phase 5F.2):**
- Settlement tests verify `merchantNet + netFee == grossAmount` for various inputs
- Settlement tests verify `valShare + treasuryShare + burnShare == netFee`
- Live transfer tests verify bank.SendCoins amount == calculated merchantNet
- Mock bank keeper records exact amounts transferred

**Residual Risk:** Rounding dust accumulates across many settlements (max 2 unxrl per settlement from integer division). Acceptable — 2 unxrl = 0.000002 NXRL. At 1M settlements, maximum accumulated dust = 2 NXRL.

---

## 2. Rounding / Dust Loss

**Threat ID:** SET-002
**Severity:** Low
**Likelihood:** High (happens on every settlement with non-round amounts)
**Impact:** Negligible (< 0.000003 NXRL per settlement)

**Description:**
Integer division truncates (floor). Three divisions occur: baseFee calculation, valShare calculation, treasuryShare calculation. Each division loses at most `(denominator - 1) / denominator` of the unit.

**Mitigation:**
- Burn share absorbs remainder: `burnShare = netFee - valShare - treasuryShare`
- Merchant net is exact: `grossAmount - netFee` (no division)
- Dust goes to burn share, not lost
- At 1 unxrl = 0.000001 NXRL, even 1M settlements produce < 3 NXRL in burn dust

**Residual Risk:** None. Burn share is specifically designed as the dust collector.

---

## 3. Double Settlement

**Threat ID:** SET-003
**Severity:** Low
**Likelihood:** Very Low
**Impact:** Payer pays merchant twice for the same payment

**Description:**
A payer accidentally or maliciously sends two `MsgCreateSettlement` messages with the same parameters, resulting in two bank transfers.

**Mitigation:**
- Each `CreateSettlement` generates a new auto-increment ID — no overwrite risk
- Two identical settlements produce two distinct settlement records with different IDs
- Cosmos SDK sequence numbers prevent transaction replay
- No "complete an existing pending settlement" message exists — each CreateSettlement is a new settlement

**Residual Risk:** Payer can genuinely want to pay the same merchant twice (e.g., two separate invoices). This is legitimate behaviour, not a threat. If the payer wants idempotency, they should use a client-side idempotency key in the Metadata field and check for duplicates before signing.

---

## 4. Failed Transfer After State Mutation

**Threat ID:** SET-004
**Severity:** High
**Likelihood:** Very Low (mitigated by design)
**Impact:** Settlement record shows Completed but funds never moved

**Description:**
If state is written before the bank transfer, and the bank transfer fails, the settlement record would show FundsSettled=true but the merchant never received funds.

**Mitigation (enforced by design):**
- Bank transfer happens BEFORE any state mutation
- Settlement record is not written to KV store until after successful transfer
- Cosmos SDK transaction atomicity: if bank.Send fails, the entire handler returns error and KV writes are discarded
- Pattern: `validate → calculate → transfer → store → emit`

**Code pattern:**
```go
// Transfer FIRST
if err := k.bankKeeper.SendCoins(ctx, payer, merchant, coins); err != nil {
    return nil, err  // state NOT written
}
// State AFTER
settlement.FundsSettled = true
k.SetSettlement(ctx, settlement)
```

**Residual Risk:** None. This is the same proven pattern used in x/escrow (Phase 5C) and x/treasury (Phase 5D).

---

## 5. Treasury Overpayment

**Threat ID:** SET-005
**Severity:** N/A for Phase 5F.2
**Likelihood:** N/A
**Impact:** N/A

**Description:**
Treasury share is NOT routed in Phase 5F.2 (Option C). This threat applies only to Phase 5F.3+ (Option D or A).

**Mitigation (deferred):**
- When treasury routing is added, use the same pattern: bank.Send before state mutation
- Treasury transfer amount matches settlement.TreasuryShare exactly
- Settlement invariant will validate treasury module balance against sum of treasury shares

---

## 6. Merchant Underpayment

**Threat ID:** SET-006
**Severity:** Medium
**Likelihood:** Low
**Impact:** Merchant receives less than the calculated merchant_net

**Description:**
A bug in the bank transfer amount calculation sends less than `grossAmount - netFee` to the merchant.

**Mitigation:**
- Bank transfer uses the same calculated `merchantNet` stored in settlement metadata
- Test `TestLiveSettlementCorrectAmount` verifies bank.Send amount matches calculated merchantNet
- Fee calculation is deterministic — same inputs produce same outputs
- Mock bank keeper assertions verify exact amounts

**Residual Risk:** If x/fees params change between calculation and transfer (same-transaction, same snapshot — not possible). If x/merchant rebate tier changes after merchant lookup but before transfer (same transaction — not possible).

---

## 7. Burn Accounting Error

**Threat ID:** SET-007
**Severity:** N/A for Phase 5F.2
**Likelihood:** N/A
**Impact:** N/A

**Description:**
Burn is NOT executed in Phase 5F.2 (Option C). BurnShare is stored as metadata only. This threat applies only to Phase 5F.3+.

**Mitigation (deferred):**
- When burn routing is added via `bank.BurnCoins`, supply invariant must verify total supply reduction
- Burn amount must exactly match settlement.BurnShare
- Failed burn must roll back the entire settlement (same atomicity as other transfers)

---

## 8. Validator Share Ambiguity

**Threat ID:** SET-008
**Severity:** Low
**Likelihood:** N/A in Phase 5F.2
**Impact:** Validator rewards not distributed

**Description:**
Validator share (6000 bps of net fee) is metadata-only in all current options (A, B, C, D). Validators do not receive settlement fee revenue on-chain.

**Mitigation:**
- Explicitly documented as deferred (Phase 5F.4+)
- Validator share amount is stored on every settlement record — auditable
- No false claim that validators are being paid
- x/fees params document that validator_share_bps is informational until live distribution is implemented

**Residual Risk:** Governance might misinterpret validator_share_bps as "active" when it is not. Mitigated by: x/settlement docs explicitly state "validators do not receive settlement fees on-chain until Phase 5F.4+".

---

## 9. Insufficient Funds

**Threat ID:** SET-009
**Severity:** Medium
**Likelihood:** Medium (common user error)
**Impact:** Settlement fails, but no state corruption

**Description:**
Payer does not have enough balance to cover the merchant net transfer.

**Mitigation:**
- Bank.SendCoins fails if payer balance < merchantNet
- Handler returns error — no state mutation
- Transaction is rejected by the mempool if the payer's balance is known to be insufficient (AnteHandler check)
- Cosmos SDK AnteHandler deducts gas fees first, then checks message balances

**Residual Risk:** Payer's balance could change between mempool check and block execution (frontrunning). This is a general Cosmos SDK concern, not specific to settlement. Mitigated by: if balance drops below required amount, the transfer fails atomically with no state change.

---

## 10. Denom Mismatch

**Threat ID:** SET-010
**Severity:** Low
**Likelihood:** Low
**Impact:** Settlement in wrong denomination

**Description:**
Settlement amount denom differs from what the merchant expects, or fee calculation uses wrong denom.

**Mitigation:**
- Settlement amount denom comes from `msg.Amount.Denom` — set by the payer
- All fee coins use the same denom: `sdk.NewCoin(denom, amount)`
- Bank transfer uses the same denom as the settlement record
- No cross-denom conversions in v1

**Residual Risk:** Payer could settle in a denom the merchant doesn't accept. Mitigated by: merchant can reject off-chain. Future: merchant could specify accepted denoms in their profile.

---

## 11. Malicious Merchant Settlement Address

**Threat ID:** SET-011
**Severity:** Low
**Likelihood:** Low
**Impact:** Funds routed to wrong address

**Description:**
The settlement address (`SettlementAddress`) defaults to `merchant.Owner`. If the merchant record is compromised or the owner address is wrong, funds go to the wrong address.

**Mitigation:**
- Merchant registration is authority-gated (`MsgRegisterMerchant` requires authority)
- Merchant owner address is validated during registration (must be valid bech32)
- Settlement verifies merchant exists and is active before transferring
- `SettlementAddress` is set to `merchant.Owner` — no separate address override

**Residual Risk:** If the governance authority registers a merchant with a malicious owner address. Mitigated by: governance requires proposal + vote. If governance is compromised, settlement is the least of the concerns.

---

## 12. Governance Enabling Live Mode Too Early

**Threat ID:** SET-012
**Severity:** Medium
**Likelihood:** Low
**Impact:** Live settlements enabled before adequate testing

**Description:**
Governance passes a proposal to set `LiveEnabled=true` before the implementation is fully tested, audited, and reviewed.

**Mitigation:**
- `LiveEnabled` default is `false` — opt-in, not opt-out
- Governance voting period provides time for review
- Per-module LiveEnabled flags allow independent enabling (settlement can be live while payout is not)
- This threat model and test plan serve as review documents for any governance proposal

**Residual Risk:** Malicious governance proposal could enable live mode quickly. Mitigated by: governance deposit, voting period, and quorum requirements.

---

## 13. Fee Param Manipulation

**Threat ID:** SET-013
**Severity:** Medium
**Likelihood:** Low
**Impact:** Fees changed mid-operation, causing incorrect splits

**Description:**
x/fees params (validator/treasury/burn shares) or x/settlement params (FeeRateBps, RebateTiers) change during settlement processing.

**Mitigation:**
- All params are read once at the start of `CreateSettlement` and used consistently throughout
- Cosmos SDK executes transactions sequentially — no concurrent modification
- Params are read from KV store within the same block context (consistent snapshot)

**Residual Risk:** A governance proposal could change fee params in the same block as a settlement. The settlement uses the params active at execution time (correct behaviour — the new rate should apply).

---

## 14. Replayed Transaction

**Threat ID:** SET-014
**Severity:** Low
**Likelihood:** Very Low
**Impact:** Duplicate settlement payment

**Description:**
An attacker replays a signed `MsgCreateSettlement` transaction.

**Mitigation:**
- Cosmos SDK account sequences (nonces) prevent replay by default
- Each transaction includes `sequence` matching the account's current sequence
- Once included in a block, the sequence increments — replay fails with "account sequence mismatch"
- No custom replay protection needed

**Residual Risk:** None within Cosmos SDK's security model.

---

## 15. Migration from Metadata-Only Records

**Threat ID:** SET-015
**Severity:** Low
**Likelihood:** N/A (no migration needed)
**Impact:** Old settlement records have inconsistent FundsSettled field

**Description:**
Settlements created before Phase 5F.2 have `FundsSettled=false` (default value) and `Status=Completed`. After Phase 5F.2, new live settlements have `FundsSettled=true` and `Status=Completed`.

**Mitigation:**
- No state migration needed — `FundsSettled` defaults to `false` (zero value for bool)
- Old records are correctly identified as metadata-only (FundsSettled=false, Status=Completed)
- New live records are correctly identified (FundsSettled=true, Status=Completed)
- Invariant helper distinguishes between them correctly
- `ActiveSettledTotals` only sums records with `FundsSettled=true`

**Residual Risk:** None. The bool zero value naturally handles backward compatibility.

---

## 16. Supply Conservation Violation

**Threat ID:** SET-016
**Severity:** Low
**Likelihood:** Very Low
**Impact:** Total supply changes incorrectly

**Description:**
In Phase 5F.2 (Option C), only one transfer occurs (payer → merchant). Total supply should be conserved (no mint, no burn). If the transfer amount is wrong or the bank keeper has a bug, supply could appear to change.

**Mitigation:**
- Single `SendCoins` from payer to merchant conserves supply by definition
- Cosmos SDK bank module enforces balance conservation in `SendCoins`
- `payer_balance_before - payer_balance_after == merchant_balance_after - merchant_balance_before`
- Invariant tests verify mock balances are consistent

**Residual Risk:** None. SendCoins is a supply-conserving operation.

---

## 17. Settlement Address Not Matching Merchant Owner

**Threat ID:** SET-017
**Severity:** Low
**Likelihood:** Low
**Impact:** Funds sent to wrong address

**Description:**
`SettlementAddress` could differ from `merchant.Owner` if set incorrectly.

**Mitigation (current code):**
```go
settlementAddress := merchant.Owner
if settlementAddress == "" {
    settlementAddress = merchant.Owner
}
```
SettlementAddress always equals merchant.Owner — no override possible.

**Residual Risk:** If the settlement address field is later made configurable (e.g., merchant can specify a separate receiving address), this must be validated. Not in Phase 5F.2 scope.

---

## Risk Matrix Summary

| ID | Threat | Severity | Phase 5F.2 Status |
|---|---|---|---|
| SET-001 | Incorrect fee split | Medium | Mitigated (tests + remainder approach) |
| SET-002 | Rounding/dust loss | Low | Mitigated (burn absorbs remainder) |
| SET-003 | Double settlement | Low | Mitigated (auto-increment ID + sequences) |
| SET-004 | Failed transfer after state mutation | High | **Eliminated** (transfer before state) |
| SET-005 | Treasury overpayment | N/A | Deferred (no treasury routing in 5F.2) |
| SET-006 | Merchant underpayment | Medium | Mitigated (tests verify exact amount) |
| SET-007 | Burn accounting error | N/A | Deferred (no burn in 5F.2) |
| SET-008 | Validator share ambiguity | Low | Accepted (documented as deferred) |
| SET-009 | Insufficient funds | Medium | Mitigated (atomic failure, no state change) |
| SET-010 | Denom mismatch | Low | Mitigated (single denom per settlement) |
| SET-011 | Malicious merchant address | Low | Mitigated (authority-gated registration) |
| SET-012 | Governance enables too early | Medium | Mitigated (default false, per-module gate) |
| SET-013 | Fee param manipulation | Medium | Mitigated (consistent snapshot per tx) |
| SET-014 | Replayed transaction | Low | Mitigated (Cosmos SDK sequences) |
| SET-015 | Migration inconsistency | Low | Mitigated (bool zero value) |
| SET-016 | Supply conservation | Low | Mitigated (SendCoins conserves supply) |
| SET-017 | Settlement address mismatch | Low | Mitigated (always equals merchant.Owner) |

## Residual Risk Acceptance

**Accepted for Phase 5F.2:**
1. **Validator share is metadata-only.** Validators do not receive settlement fees on-chain. Documented. Governance must understand this before enabling LiveEnabled for mainnet.
2. **Treasury share is metadata-only.** Treasury module account does not accumulate from settlements. Acceptable because treasury has its own funding path (genesis, future fee routing).
3. **Burn share is metadata-only.** Supply is not deflationary from settlements. Acceptable for devnet/testnet.
4. **Refunds are manual/off-chain.** Completed live settlements cannot be automatically refunded on-chain. The authority can mark them Refunded (metadata change) but funds remain with merchant. Future phase will add automated refund transfers.

## Implementation Safety Assessment

**Phase 5F.2 is safe to implement.** The threat surface is minimal:
- One new param field (`LiveEnabled`, default false)
- One new struct field (`FundsSettled`, bool)
- One new keeper dependency (`BankKeeper` with `SendCoins`)
- One bank call in an existing message handler, gated by LiveEnabled
- No new module accounts
- No burn, no treasury routing, no multi-party transfers

All threats are either eliminated by design (SET-004), mitigated by tests (SET-001, SET-006), deferred to future phases (SET-005, SET-007, SET-008), or covered by Cosmos SDK guarantees (SET-014, SET-016).
