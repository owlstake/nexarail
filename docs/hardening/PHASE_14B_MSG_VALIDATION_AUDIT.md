# Phase 14B — Message Validation Audit

**Date:** 2026-05-28
**Scope:** All 6 NexaRail chain modules (merchant, fees, settlement, escrow, treasury, payout)
**Method:** Static code inspection of `x/*/types/msg.go` ValidateBasic implementations

---

## Module: x/merchant — Messages

### MsgRegisterMerchant
- **ValidateBasic exists:** yes
- **Rejects empty owner:** yes (AccAddressFromBech32 parse fails on empty string)
- **Rejects empty name:** yes (`len(msg.Name) == 0` check)
- **Rejects empty description:** no — description is not checked
- **Rejects overly long names:** no — max name length is stored in Params but not checked in ValidateBasic
- **Rejects overly long descriptions:** no — max description length is stored in Params but not checked in ValidateBasic
- **Rejects invalid website:** no — website field is not validated at all
- **Test coverage:** partial — coverage exists in keeper tests but ValidateBasic edge cases (long name, long description) are not tested

### MsgUpdateMerchant
- **ValidateBasic exists:** yes
- **Rejects empty owner:** yes (AccAddressFromBech32 parse)
- **Rejects empty name:** no
- **Rejects empty description:** no
- **Rejects overly long names:** no
- **Rejects overly long descriptions:** no
- **Rejects invalid website:** no
- **Test coverage:** partial — only checks owner address

### MsgUpdateParams
- **ValidateBasic exists:** yes
- **Rejects invalid authority:** yes (AccAddressFromBech32 parse)
- **Validates params:** yes (calls `msg.Params.Validate()`)
- **Rejects invalid RegistrationFee:** yes (via Params.Validate)
- **Rejects invalid MinNameLength:** yes (via Params.Validate — must be >= 1)
- **Rejects invalid MaxNameLength:** yes (via Params.Validate — must be >= MinNameLength)
- **Rejects invalid MaxDescriptionLength:** yes (via Params.Validate — must be >= 1)
- **Test coverage:** partial

### MsgSetMerchantStatus (authority-only)
- **ValidateBasic exists:** yes
- **Rejects invalid authority:** yes
- **Rejects invalid owner:** yes
- **Rejects invalid status:** yes (range 0–2)
- **Test coverage:** partial

### MsgSetVerificationStatus (authority-only)
- **ValidateBasic exists:** yes
- **Rejects invalid authority:** yes
- **Rejects invalid owner:** yes
- **Rejects invalid status:** yes (range 0–2)
- **Test coverage:** partial

### MsgSetRebateTier (authority-only)
- **ValidateBasic exists:** yes
- **Rejects invalid authority:** yes
- **Rejects invalid owner:** yes
- **Rejects invalid tier:** yes (range 0–4)
- **Test coverage:** partial

---

## Module: x/fees — Messages

### MsgUpdateParams
- **ValidateBasic exists:** yes
- **Rejects invalid authority:** yes (AccAddressFromBech32 parse)
- **Validates params:** yes (calls `msg.Params.Validate()`)
- **Rejects mis-totaled shares:** yes (must sum to 10000 bps)
- **Rejects negative share bps:** yes (checked as > BasisPointsMax = 10000, but also negative values would fail since uint32)
- **Rejects empty FeeCollectorName:** yes
- **Rejects invalid TreasuryAccount:** yes (bech32 parse if non-empty)
- **Rejects negative MinProtocolFee:** yes
- **Test coverage:** partial

---

## Module: x/settlement — Messages

### MsgCreateSettlement
- **ValidateBasic exists:** yes
- **Rejects invalid payer:** yes (AccAddressFromBech32 with `ErrInvalidPayer`)
- **Rejects invalid merchant owner:** yes (AccAddressFromBech32 with `ErrInvalidMerchant`)
- **Rejects non-positive amount:** yes (zero or negative check with `ErrAmountNotPositive`)
- **Rejects empty metadata:** no
- **Test coverage:** adequate — keeper tests exercise various paths

### MsgUpdateSettlementStatus (authority-only)
- **ValidateBasic exists:** yes
- **Rejects invalid authority:** yes
- **Rejects invalid status:** yes (range 0–3)
- **Test coverage:** partial

### MsgUpdateParams
- **ValidateBasic exists:** yes
- **Rejects invalid authority:** yes
- **Validates params:** yes (calls `msg.Params.Validate()`)
- **Rejects invalid FeeRateBps:** yes (max 10000)
- **Rejects invalid RebateTiers length:** yes (must be 5 entries)
- **Test coverage:** partial

---

## Module: x/escrow — Messages

### MsgCreateEscrow
- **ValidateBasic exists:** yes
- **Rejects invalid buyer:** yes
- **Rejects invalid seller:** yes
- **Rejects buyer == seller:** yes (safe guard against self-dealing)
- **Rejects zero/negative amount:** yes
- **Rejects invalid escrow_id:** no (not checked)
- **Rejects invalid merchant_id:** no (not checked)
- **Rejects invalid asset denom:** no (not checked)
- **Rejects empty/invalid payment reference:** no
- **Rejects invalid memo:** no
- **Rejects expired/invalid expires_at:** no
- **Test coverage:** partial — amount and address checks covered, missing edge cases for string fields

### MsgReleaseEscrow
- **ValidateBasic exists:** yes
- **Rejects invalid signer:** yes
- **Rejects missing escrow_id:** no
- **Test coverage:** minimal — just signer address

### MsgRefundEscrow
- **ValidateBasic exists:** yes
- **Rejects invalid signer:** yes
- **Test coverage:** minimal

### MsgOpenDispute
- **ValidateBasic exists:** yes
- **Rejects invalid signer:** yes
- **Rejects empty dispute reason:** no
- **Test coverage:** minimal

### MsgResolveDispute (authority-only)
- **ValidateBasic exists:** yes
- **Rejects invalid authority:** yes
- **Rejects invalid dispute status:** yes (checks valid status map + range 3–6)
- **Rejects empty resolution note:** no
- **Test coverage:** partial

### MsgCancelEscrow
- **ValidateBasic exists:** yes
- **Rejects invalid signer:** yes
- **Test coverage:** minimal

### MsgUpdateParams
- **ValidateBasic exists:** yes
- **Rejects invalid authority:** yes
- **Validates params:** yes (calls `m.Params.Validate()`)
- **Rejects zero MaxReferenceLength:** yes
- **Rejects zero MaxMemoLength:** yes
- **Rejects negative MinEscrowAmount:** yes
- **Rejects zero DefaultExpirySeconds:** yes
- **Test coverage:** partial

---

## Module: x/treasury — Messages

### All 11 Msg types (MsgCreateTreasuryAccount, MsgCreateBudget, MsgUpdateBudgetStatus, MsgCreateGrant, MsgUpdateGrantStatus, MsgCreateSpendRequest, MsgApproveSpendRequest, MsgRejectSpendRequest, MsgMarkSpendExecuted, MsgCancelSpendRequest, MsgUpdateParams)
- **ValidateBasic exists:** yes — all 11 have ValidateBasic
- **What they validate:** Each calls `sdk.AccAddressFromBech32()` on the Authority/Requester/Signer field and returns on error. That's **all** they do.
- **NOT validated in any treasury ValidateBasic:**
  - AccountId / BudgetId / GrantId / SpendId — not checked for empty or invalid
  - Category — not checked for valid range
  - Name / Title / Description — not checked for empty or length
  - Amount / TotalAmount / NominalBalance — not checked for zero/negative
  - StartTime / EndTime — not checked for ordering
  - MetadataUri / Reference / Purpose / Memo — not checked
  - RecipientAddress — not checked in messages where present (e.g. MsgCreateGrant.MsgCreateSpendRequest)
- **Test coverage:** minimal — most tests skip ValidateBasic or only check the happy path

---

## Module: x/payout — Messages

### MsgCreatePayout
- **ValidateBasic exists:** yes
- **Rejects invalid initiator:** yes
- **Rejects invalid recipient:** yes
- **Rejects zero/negative amount:** yes
- **Rejects invalid payout_id:** no
- **Rejects invalid merchant_id:** no
- **Rejects invalid denom:** no
- **Rejects invalid payout_type:** no
- **Test coverage:** partial

### MsgCreateBatchPayout
- **ValidateBasic exists:** yes
- **Rejects invalid initiator:** yes
- **Rejects empty payouts list:** yes
- **Validates individual PayoutInput entries:** no — each entry's recipient, amount, etc. are NOT validated
- **Test coverage:** partial

### MsgApprovePayout
- **ValidateBasic exists:** yes
- **Rejects invalid signer:** yes
- **Test coverage:** minimal

### MsgMarkPayoutPaid
- **ValidateBasic exists:** yes
- **Rejects invalid authority:** yes
- **Test coverage:** minimal

### MsgCancelPayout
- **ValidateBasic exists:** yes
- **Rejects invalid signer:** yes
- **Test coverage:** minimal

### MsgFailPayout
- **ValidateBasic exists:** yes
- **Rejects invalid authority:** yes
- **Test coverage:** minimal

### MsgUpdateParams
- **ValidateBasic exists:** yes
- **Rejects invalid authority:** yes (address format only)
- **Validates params:** no — does NOT call `m.Params.Validate()` unlike other modules
- **Test coverage:** partial

---

## Summary

| Metric | Count |
|---|---|
| **Total Msg types** | **35** |
| With ValidateBasic | 35 (100%) |
| Missing ValidateBasic | 0 |
| **Rejecting invalid owner/signer/authority** | **35** (all check address via AccAddressFromBech32) |
| **Rejecting non-positive amounts** | 4 (settlement MsgCreateSettlement, escrow MsgCreateEscrow, payout MsgCreatePayout; others with amounts skip this check) |
| **Rejecting empty names/IDs** | 1 (merchant MsgRegisterMerchant checks empty name only) |
| **Rejecting invalid categories** | 0 |
| **Validating params via Params.Validate()** | 5/6 (merchant ✓, fees ✓, settlement ✓, escrow ✓, payout **FAILS** to call Params.Validate, treasury does call but only after address check) |

### Gaps Found

1. **CRITICAL: MsgUpdateMerchant ValidateBasic is too weak.** It only checks the owner address. Name, description, website are not validated at the message level, leaving all validation to the keeper. This means invalid data can pass `ValidateBasic` and reach the keeper without early rejection.

2. **CRITICAL: Payout MsgUpdateParams does NOT call `Params.Validate()`.** Unlike the other 5 modules, the payout module's MsgUpdateParams.ValidateBasic only checks the authority address format and does not validate the params struct. Invalid params would pass the message-level check.

3. **HIGH: Treasury ValidateBasic methods are stubs.** All 11 treasury messages only check the Authority/Requester/Signer address format. Fields like amount, account ID, budget ID, grant ID, recipient address, category, dates, and string lengths are not validated at the message level. This means many invalid messages will pass ValidateBasic and must be caught by the keeper instead.

4. **HIGH: MsgCreateBatchPayout does not validate individual payout entries.** The batch message checks that the payouts list is non-empty and that the initiator is valid, but does not validate each PayoutInput's recipient address, amount, denom, or payout type.

5. **MEDIUM: MsgRegisterMerchant doesn't enforce name/description length limits.** The Params define MinNameLength (3), MaxNameLength (64), and MaxDescriptionLength (256), but these are not checked in ValidateBasic. They are presumably checked in the keeper.

6. **MEDIUM: Escrow MsgCreateEscrow does not validate escrow_id, merchant_id, asset denom, reference, memo, or expiry.** Many string fields are left unchecked at the ValidateBasic level.

7. **LOW: Several messages have no validation beyond address format.** Escrow ReleaseEscrow, RefundEscrow, OpenDispute, CancelEscrow; Payout's ApprovePayout, CancelPayout, FailPayout, MarkPayoutPaid; Treasury's many stub ValidateBasic methods — all only check that the signer/authority is a valid bech32 address.
