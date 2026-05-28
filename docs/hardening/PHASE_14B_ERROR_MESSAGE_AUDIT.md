# Phase 14B — Error Message Audit

**Date:** 2026-05-28
**Scope:** All 6 modules — verify that error messages do not leak sensitive information and are appropriate for end-users.

---

## Module: x/merchant — Errors

| Code | Variable | Message | Assessment |
|---|---|---|---|
| 1 | `ErrMerchantAlreadyExists` | `"merchant already registered"` | ✅ safe |
| 2 | `ErrMerchantNotFound` | `"merchant not found"` | ✅ safe — confirms non-existence only |
| 3 | `ErrNameTooShort` | `"merchant name too short"` | ✅ safe |
| 4 | `ErrNameTooLong` | `"merchant name too long"` | ✅ safe |
| 5 | `ErrDescriptionTooLong` | `"merchant description too long"` | ✅ safe |
| 6 | `ErrInvalidOwner` | `"invalid merchant owner address"` | ✅ safe |
| 7 | `ErrInsufficientFee` | `"insufficient registration fee"` | ✅ safe |
| 8 | `ErrUnauthorized` | `"unauthorized: sender is not the merchant owner"` | ✅ safe — generic |
| 9 | `ErrInvalidParams` | `"invalid parameters"` | ✅ safe — generic |
| 10 | `ErrMerchantClosed` | `"merchant is closed and cannot be updated"` | ✅ safe |

**Total: 10 error types, 0 sensitive**

---

## Module: x/fees — Errors

| Code | Variable | Message | Assessment |
|---|---|---|---|
| 1 | `ErrInvalidShareBps` | `"share basis points must total 10000"` | ✅ safe |
| 2 | `ErrNegativeShareBps` | `"share basis points must not be negative"` | ✅ safe — descriptive of validation rule |
| 3 | `ErrInvalidTreasuryAccount` | `"invalid treasury account address"` | ✅ safe |
| 4 | `ErrEmptyFeeCollector` | `"fee collector name must not be empty"` | ✅ safe |
| 5 | `ErrNegativeMinFee` | `"minimum protocol fee must not be negative"` | ✅ safe |
| 6 | `ErrInvalidAuthority` | `"invalid authority address"` | ✅ safe |
| 7 | `ErrUnauthorized` | `"unauthorized: message sender is not the module authority"` | ✅ safe — identifies caller type without specifics |
| 8 | `ErrInvalidParams` | `"invalid parameters"` | ✅ safe — generic |
| 9 | `ErrInternal` | `"internal error"` | ✅ safe — generic, no stack trace |

**Total: 9 error types, 0 sensitive**

---

## Module: x/settlement — Errors

| Code | Variable | Message | Assessment |
|---|---|---|---|
| 1 | `ErrSettlementNotFound` | `"settlement not found"` | ✅ safe |
| 2 | `ErrInvalidPayer` | `"invalid payer address"` | ✅ safe |
| 3 | `ErrInvalidMerchant` | `"invalid merchant address"` | ✅ safe |
| 4 | `ErrAmountNotPositive` | `"amount must be positive"` | ✅ safe |
| 5 | `ErrMerchantNotActive` | `"merchant is not active"` | ✅ safe — reveals merchant status rule |
| 6 | `ErrUnauthorized` | `"unauthorized sender"` | ✅ safe — generic |
| 7 | `ErrInvalidParams` | `"invalid parameters"` | ✅ safe — generic |
| 8 | `ErrInvalidStatusTransition` | `"invalid status transition"` | ✅ safe |
| 9 | `ErrInvalidStatus` | `"invalid settlement status"` | ✅ safe |
| 10 | `ErrSettlementsDisabled` | `"settlements are disabled"` | ✅ safe — reveals feature state (public) |

**Total: 10 error types, 0 sensitive**

---

## Module: x/escrow — Errors

| Code | Variable | Message | Assessment |
|---|---|---|---|
| 1 | `ErrInvalidEscrowID` | `"invalid escrow ID"` | ✅ safe |
| 2 | `ErrInvalidBuyer` | `"invalid buyer address"` | ✅ safe |
| 3 | `ErrInvalidSeller` | `"invalid seller address"` | ✅ safe |
| 4 | `ErrInvalidMerchantID` | `"invalid merchant ID"` | ✅ safe |
| 5 | `ErrInvalidDenom` | `"invalid asset denom"` | ✅ safe |
| 6 | `ErrAmountNotPositive` | `"amount must be positive"` | ✅ safe |
| 7 | `ErrInvalidFee` | `"invalid platform fee or seller amount"` | ✅ safe |
| 8 | `ErrInvalidStatus` | `"invalid escrow status"` | ✅ safe |
| 9 | `ErrInvalidDisputeStatus` | `"invalid dispute status"` | ✅ safe |
| 10 | `ErrEscrowExists` | `"escrow already exists"` | ✅ safe |
| 11 | `ErrEscrowNotFound` | `"escrow not found"` | ✅ safe |
| 12 | `ErrEscrowsDisabled` | `"escrows are disabled"` | ✅ safe — public config |
| 13 | `ErrMerchantNotActive` | `"merchant is not active"` | ✅ safe |
| 14 | `ErrUnauthorized` | `"unauthorized"` | ✅ safe — generic |
| 15 | `ErrInvalidTransition` | `"invalid status transition"` | ✅ safe |
| 16 | `ErrReferenceTooLong` | `"reference too long"` | ✅ safe |
| 17 | `ErrMemoTooLong` | `"memo too long"` | ✅ safe |
| 18 | `ErrDisputeReasonTooLong` | `"dispute reason too long"` | ✅ safe |
| 19 | `ErrResolutionNoteTooLong` | `"resolution note too long"` | ✅ safe |
| 20 | `ErrInvalidExpiry` | `"invalid expiry"` | ✅ safe |
| 21 | `ErrInvalidParams` | `"invalid parameters"` | ✅ safe — generic |

**Total: 21 error types, 0 sensitive**

---

## Module: x/treasury — Errors

| Code | Variable | Message | Assessment |
|---|---|---|---|
| 1 | `ErrInvalidID` | `"invalid ID"` | ✅ safe |
| 2 | `ErrInvalidCategory` | `"invalid category"` | ✅ safe |
| 3 | `ErrInvalidRequester` | `"invalid requester"` | ✅ safe |
| 4 | `ErrInvalidRecipient` | `"invalid recipient"` | ✅ safe |
| 5 | `ErrInvalidAmount` | `"invalid amount"` | ✅ safe |
| 6 | `ErrInvalidStatus` | `"invalid status"` | ✅ safe |
| 7 | `ErrRecordExists` | `"record exists"` | ✅ safe |
| 8 | `ErrRecordNotFound` | `"record not found"` | ✅ safe |
| 9 | `ErrTreasuryDisabled` | `"treasury disabled"` | ✅ safe — public config |
| 10 | `ErrBudgetsDisabled` | `"budgets disabled"` | ✅ safe — public config |
| 11 | `ErrGrantsDisabled` | `"grants disabled"` | ✅ safe — public config |
| 12 | `ErrSpendDisabled` | `"spend requests disabled"` | ✅ safe — public config |
| 13 | `ErrBudgetCapacity` | `"budget capacity exceeded"` | ✅ safe |
| 14 | `ErrUnauthorized` | `"unauthorized"` | ✅ safe — generic |
| 15 | `ErrInvalidTransition` | `"invalid transition"` | ✅ safe |
| 16 | `ErrInvalidParams` | `"invalid params"` | ✅ safe — generic |
| 17 | `ErrAccountNotFound` | `"account not found"` | ✅ safe |

**Total: 17 error types, 0 sensitive**

---

## Module: x/payout — Errors

| Code | Variable | Message | Assessment |
|---|---|---|---|
| 1 | `ErrInvalidPayoutID` | `"invalid payout ID"` | ✅ safe |
| 2 | `ErrInvalidInitiator` | `"invalid initiator"` | ✅ safe |
| 3 | `ErrInvalidRecipient` | `"invalid recipient"` | ✅ safe |
| 4 | `ErrInvalidMerchantID` | `"invalid merchant ID"` | ✅ safe |
| 5 | `ErrInvalidDenom` | `"invalid denom"` | ✅ safe |
| 6 | `ErrAmountNotPositive` | `"amount not positive"` | ✅ safe |
| 7 | `ErrInvalidFee` | `"invalid fee/net"` | ✅ safe |
| 8 | `ErrInvalidStatus` | `"invalid status"` | ✅ safe |
| 9 | `ErrInvalidPayoutType` | `"invalid payout type"` | ✅ safe |
| 10 | `ErrPayoutExists` | `"payout exists"` | ✅ safe |
| 11 | `ErrPayoutNotFound` | `"payout not found"` | ✅ safe |
| 12 | `ErrPayoutsDisabled` | `"payouts disabled"` | ✅ safe — public config |
| 13 | `ErrBatchDisabled` | `"batch payouts disabled"` | ✅ safe — public config |
| 14 | `ErrMerchantNotActive` | `"merchant not active"` | ✅ safe |
| 15 | `ErrUnauthorized` | `"unauthorized"` | ✅ safe — generic |
| 16 | `ErrInvalidTransition` | `"invalid transition"` | ✅ safe |
| 17 | `ErrReferenceTooLong` | `"ref too long"` | ✅ safe |
| 18 | `ErrMemoTooLong` | `"memo too long"` | ✅ safe |
| 19 | `ErrFailureReasonTooLong` | `"failure reason too long"` | ✅ safe |
| 20 | `ErrInvalidParams` | `"invalid params"` | ✅ safe — generic |
| 21 | `ErrBatchNotFound` | `"batch not found"` | ✅ safe |
| 22 | `ErrAlreadyPaid` | `"payout funds already paid"` | ✅ safe |
| 23 | `ErrLiveTransferFailed` | `"live payout transfer failed"` | ✅ safe — generic, no details on the failure |

**Total: 23 error types, 0 sensitive**

---

## Summary

| Metric | Count |
|---|---|
| **Total error types across all modules** | **90** |
| Non-sensitive errors | 90 |
| Errors that could leak sensitive info | 0 |
| Errors with wrapped messages (`%w`) | many — wrapped with registered errors, so the registered message is preserved |

### Overall Assessment

**SAFE** — All error messages are appropriate for public consumption. Key observations:

1. **No leaking of internal state.** Errors like `"merchant not found"` confirm non-existence but don't reveal internals like storage keys, DB structure, or code paths.

2. **Consistent wrapping pattern with `%w`.** Many keeper functions use `fmt.Errorf("context: %w", ErrFoo)` which preserves the root error code while adding context. This is good — the SDK-level error code is still the root sentinel.

3. **No debug/stack trace leakage.** No error messages include file paths, line numbers, memory addresses, or Go runtime details.

4. **Feature state errors are acceptable.** Errors like `"settlements are disabled"` or `"treasury disabled"` reveal the current feature flag state, but this is public on-chain state anyway.

5. **Generic fallback patterns used.** `ErrInvalidParams` and `ErrUnauthorized` are kept generic across all modules, following best practices.

6. **No credential/secrets leakage.** No error message includes private keys, API keys, seed phrases, or connection strings.

**Rating: ✅ PASS — all clear.**
