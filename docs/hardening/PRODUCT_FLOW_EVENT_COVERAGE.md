# Product Flow Event Coverage

**Date:** 2026-05-28  
**Scope:** Event coverage review for Phase 10B full product-flow evidence  
**Evidence root:** `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/`

## Summary

Direct user/module transactions emit useful module-specific events. Governance-wrapped authority actions are now indexed by `governance-product-evidence.json`, but they remain weaker from a protocol event-indexing perspective: the proposal submit transaction records `submit_proposal` and `proposal_messages`, while the authority action is proven through proposal final status plus state/balance readback.

No descriptor, `unknownproto`, `index out of range`, gzip/invalid-header, `CheckTx`, or panic signatures appeared in the final full-suite descriptor scan.

Phase 10B.2 also generates `event-summary.json` and `event-summary.md` automatically. The final run grouped events as follows:

| Group | Events |
|---|---:|
| Merchant | 12 |
| Settlement | 15 |
| Escrow | 15 |
| Treasury | 208 |
| Payout | 9 |
| Bank transfer | 586 |
| Burn | 5 |
| Governance | 308 |
| Param/live-flag | 16 |
| Other | 668 |

## Direct Transaction Coverage

| Flow | Tx | Code | Event coverage | Evidence |
|---|---:|---:|---|---|
| Bank smoke | `MsgSend` | 0 | `coin_spent`, `coin_received`, `transfer`, `message` | `txs/smoke-bank-send/included-tx.json` |
| Merchant register | `MsgRegisterMerchant` | 0 | `merchant_registered` plus fee/tx events | `merchant/register/included-tx.json` |
| Merchant update | `MsgUpdateMerchant` | 0 | `merchant_updated` plus fee/tx events | `merchant/update/included-tx.json` |
| Settlement create metadata | `MsgCreateSettlement` | 0 | `settlement_created`, `funds_settled=false` attributes | `settlement/metadata/create/included-tx.json` |
| Settlement create live | `MsgCreateSettlement` | 0 | `settlement_created`, transfer events, `funds_settled=true` attributes | `settlement/live/create/included-tx.json` |
| Settlement treasury routing | `MsgCreateSettlement` | 0 | `settlement_created`, transfer events, treasury-routed attributes | `settlement/treasury-routing/create/included-tx.json` |
| Settlement burn routing | `MsgCreateSettlement` | 0 | `settlement_created`, transfer events, bank `burn` event | `settlement/burn-routing/create/included-tx.json` |
| Escrow create | `MsgCreateEscrow` | 0 | `escrow_created`, transfer events | `escrow/create-release/included-tx.json`, `escrow/create-refund/included-tx.json`, `escrow/create-cancel/included-tx.json` |
| Escrow release | `MsgReleaseEscrow` | 0 | `escrow_released`, transfer events | `escrow/release/included-tx.json` |
| Escrow refund | `MsgRefundEscrow` | 0 | `escrow_refunded`, transfer events | `escrow/refund/included-tx.json` |
| Escrow cancel | `MsgCancelEscrow` | 0 | `escrow_cancelled`, transfer events | `escrow/cancel/included-tx.json` |
| Treasury create spend | `MsgCreateSpendRequest` | 0 | `spend_request_created` plus fee/tx events | `treasury/create-spend/included-tx.json` |
| Payout recipient merchant register | `MsgRegisterMerchant` | 0 | `merchant_registered` | `payout/register-recipient-merchant/included-tx.json` |
| Payout create | `MsgCreatePayout` | 0 | `payout_created` | `payout/create/included-tx.json` |
| Payout approve | `MsgApprovePayout` | 0 | `payout_approved` | `payout/approve/included-tx.json` |

## Governance-Wrapped Authority Action Coverage

| Action | Proof captured | Event gap |
|---|---|---|
| Merchant set inactive/active | Proposal IDs `1`, `2`, vote tx hashes, final status passed, later rejection/acceptance behavior | Submit tx events show gov `submit_proposal`; module-specific `merchant_updated` execution event is not isolated in evidence |
| Settlement live flag changes | Proposal IDs `3`-`8`, final status passed, params readback after each flow | Submit tx events show gov `submit_proposal`; module-specific param-update event is not isolated in evidence |
| Escrow live flag changes | Proposal IDs `9`, `10`, final status passed, params readback | Same gov execution event visibility gap |
| Treasury live/account/budget/approve/execute | Proposal IDs `11`-`15`, final status passed, state/balance readback | Account/budget/approve/execute module events are not directly captured as standalone execution tx events |
| Payout live/mark-paid | Proposal IDs `16`-`18`, final status passed, payout state and balance deltas | `payout_paid` execution event is not directly isolated in the evidence |
| Final restore false | Proposal IDs `19`-`22`, final status passed, `final-live-flags.json` | Restore action relies on params readback and gov final status |

## Rejection Coverage

| Rejection | Code | Evidence | Notes |
|---|---:|---|---|
| Inactive merchant settlement | 1 | `merchant/inactive-settlement-reject/included-tx.json` | Error log is specific: merchant not active |
| Invalid merchant settlement | 1 | `merchant/invalid-merchant-reject/included-tx.json` | Error log is specific: merchant not found |
| Double escrow release | 1 | `escrow/double-release-reject/included-tx.json` | Error log is specific: invalid status transition |
| Double treasury execute | 14 | `treasury/double-execute-reject/included-tx.json` | Error log is generic: unauthorized |
| Double payout mark-paid | 15 | `payout/double-pay-reject/included-tx.json` | Error log is generic: unauthorized |
| Unauthorized settlement params | 1 | `safety/unauthorized-settlement-params/included-tx.json` | Error log names expected authority and signer |
| Payout after disable | 15 | `safety/failed-transfer-payout/included-tx.json` | Error log is generic: unauthorized |

## Findings

### Covered Well

- Direct merchant, settlement, escrow, treasury spend-request, and payout create/approve txs emit module-specific events.
- Settlement events include enough attributes to distinguish metadata, live, treasury-routed, and burn-routed cases.
- Bank transfer and burn events appear where live fund movement happens.
- Rejected txs include deterministic tx result codes and logs.

### Remaining Gaps

- Governance-executed authority actions are not easy to index as product events from the proposal submit tx alone.
- Final proposal execution is proven through final status and state readback, with a generated governance index, not a single module-specific execution event artifact.
- Some rejection paths return generic `unauthorized`, which is mechanically correct but less useful for operators.

## Phase 10B.2 Result

Event extraction is now harness-owned:

- `scripts/testnet/extract-product-flow-events.sh` creates `event-summary.json` and `event-summary.md`.
- `scripts/testnet/index-governance-product-evidence.sh` creates `governance-product-evidence.json` and `governance-product-evidence.md`.
- Burn routing now has explicit supply-delta evidence via `burn-supply-delta.json`: total supply delta `-2000`, burner module delta `0`.

## Phase 10B.3 Improvement

Governance-executed event indexing improved:
- Evidence classification: `direct_event` / `indirect_proposal_state` / `missing`
- Expected before/after values parsed from proposal labels
- Proposal tx links as explicit field
- Related product flow tx discovery (searches sibling evidence directories)
- Classification summary in output JSON

Next hardening should focus on protocol/indexer-level event semantics for governance-executed product actions and clearer product-specific rejection strings where doing so does not weaken authorization behavior.
