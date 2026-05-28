# Phase 14B — Event Coverage Audit

**Date:** 2026-05-28
**Scope:** Event emission in all 6 module keepers. Verify events are emitted for all state changes and carry relevant attributes.

---

## Module: x/merchant

### Events Emitted

**`merchant_registered`**
- Emitted: yes — in `Keeper.RegisterMerchant()`
- Attributes: `owner`, `name`, `description`, `website`, `status`
- Assessment: adequate — all registration details included

**`merchant_updated`**
- Emitted: yes — in `Keeper.UpdateMerchant()`
- Attributes: `owner`, `name`, `description`, `website`
- Assessment: adequate

**`merchant_updated` (status change — authority-gated)**
- Emitted: yes — in `Keeper.SetMerchantStatus()`
- Attributes: `owner`, `status`
- Assessment: adequate — distinguishes from profile update via status value

**`merchant_updated` (verification status change — authority-gated)**
- Emitted: yes — in `Keeper.SetVerificationStatus()`
- Attributes: `owner`, `status` (as `"verification:N"`)
- Assessment: adequate — uses same event type with differentiated status attribute

**`merchant_updated` (rebate tier change — authority-gated)**
- Emitted: yes — in `Keeper.SetRebateTier()`
- Attributes: `owner`, `status` (as `"rebate:N"`)
- Assessment: adequate

**No params update event** — `Keeper.UpdateParams()` calls `SetParams()` which does not emit an event. This is a gap.

### Assessment
- **Total event types declared:** 2 (RegisterMerchant, UpdateMerchant)
- **Total distinct state-change paths with events:** 5 (all use the 2 event types)
- **Params update event:** ❌ MISSING — no event emitted when params change
- **Gap:** `MsgUpdateParams` in merchant module does not emit an event after updating params

---

## Module: x/fees

### Events Emitted

**`fees_update_params`**
- Emitted: yes — in `MsgServer.UpdateParams()`
- Attributes: `validator_share_bps`, `treasury_share_bps`, `burn_share_bps`, `fee_collector_name`, `treasury_account`, `burn_enabled`, `min_protocol_fee`, `authority`
- Assessment: **excellent** — emits all params plus the authority who changed them

### Assessment
- **Total event types declared:** 1
- **Attributes:** full coverage of all params
- **Info leakage:** none — only public config data
- **Gap:** none identified

---

## Module: x/settlement

### Events Emitted

**`settlement_created`**
- Emitted: yes — in `Keeper.CreateSettlement()`
- Attributes: `settlement_id`, `payer`, `merchant_owner`, `amount`, `fee_amount`, `validator_share`, `treasury_share`, `burn_share`, `rebate_bps`, `status`, `funds_settled`, `treasury_routed`, `burn_routed`, `metadata`
- Assessment: **excellent** — 14 attributes covering every detail of the settlement lifecycle including the routing state

**`settlement_status_updated`**
- Emitted: yes — in `Keeper.UpdateSettlementStatus()`
- Attributes: `settlement_id`, `status`, `authority`
- Assessment: adequate — includes ID, new status, and authority who performed the change

### Assessment
- **Total event types declared:** 2
- **Attributes:** exceptional — `settlement_created` is the richest event in the codebase
- **Info leakage:** none — all attributes are part of the public state
- **Gap:** no params update event emitted (same as merchant)

---

## Module: x/escrow

### Events Emitted

**`escrow_created`**
- Emitted: yes — in `Keeper.CreateEscrow()`
- Attributes: `escrow_id`, `buyer_address`, `seller_address`, `amount`, `status`
- Assessment: adequate — key fields included; missing `asset_denom` and `merchant_id`

**`escrow_released`**
- Emitted: yes — in `Keeper.ReleaseEscrow()`
- Attributes: `escrow_id`, `signer`, `status`
- Assessment: adequate

**`escrow_refunded`**
- Emitted: yes — in `Keeper.RefundEscrow()`
- Attributes: `escrow_id`, `signer`, `status`
- Assessment: adequate

**`escrow_disputed`**
- Emitted: yes — in `Keeper.OpenDispute()`
- Attributes: `escrow_id`, `signer`, `reason`, `dispute_status`
- Assessment: adequate — includes dispute reason

**`escrow_dispute_resolved`**
- Emitted: yes — in `Keeper.ResolveDispute()`
- Attributes: `escrow_id`, `dispute_status`, `status`, `resolution_note`
- Assessment: adequate — includes resolution note

**`escrow_cancelled`**
- Emitted: yes — in `Keeper.CancelEscrow()`
- Attributes: `escrow_id`, `signer`, `status`
- Assessment: adequate

### Assessment
- **Total event types declared:** 7 (including `escrow_params_updated`)
- **`escrow_params_updated`:** ❓ declared in events.go but no emit found in keeper — this event type is defined but never used
- **Missing attributes:** `escrow_created` event does not include `asset_denom` or `merchant_id`, which are useful for filtering
- **Gap:** defined `escrow_params_updated` event constant but never emitted from the keeper
- **Info leakage:** none identified

---

## Module: x/treasury

### Events Emitted

**`treasury_account_created`**
- Emitted: yes
- Attributes: `account_id`, `category`, `amount`
- **Missing:** `name`, `description` — useful for audit trails

**`budget_created`**
- Emitted: yes
- Attributes: `budget_id`, `amount`, `status`
- **Missing:** `account_id`, `title`, start/end time

**`budget_status_updated`**
- Emitted: yes
- Attributes: `budget_id`, `status`
- Assessment: adequate

**`grant_created`**
- Emitted: yes
- Attributes: `grant_id`, `amount`, `status`
- **Missing:** `budget_id`, `recipient`, `title`

**`grant_status_updated`**
- Emitted: yes
- Attributes: `grant_id`, `status`
- Assessment: adequate

**`spend_request_created`**
- Emitted: yes
- Attributes: `spend_id`, `amount`, `status`
- **Missing:** `requester`, `recipient`, `account_id`, `budget_id`, `grant_id`, `purpose`

**`spend_request_approved`**
- Emitted: yes
- Attributes: `spend_id`, `status`
- Assessment: adequate

**`spend_request_rejected`**
- Emitted: yes
- Attributes: `spend_id`, `status`
- Assessment: adequate

**`spend_request_executed`**
- Emitted: yes
- Attributes: `spend_id`, `status`
- Assessment: adequate

**`spend_request_cancelled`**
- Emitted: yes
- Attributes: `spend_id`, `status`
- Assessment: adequate

### Assessment
- **Total event types declared:** 11 (including `treasury_params_updated`)
- **`treasury_params_updated`:** ❓ declared in events.go but never emitted from the keeper
- **Missing attributes across events:** many creation events omit contextual IDs (budget_id in grant, account_id in budget, requester/recipient in spend) which would make event-driven indexing harder
- **Info leakage:** none identified

---

## Module: x/payout

### Events Emitted

**`payout_created`**
- Emitted: yes
- Attributes: `payout_id`, `initiator`, `recipient`, `amount`, `status`
- Assessment: adequate — all key fields

**`batch_payout_created`**
- Emitted: yes
- Attributes: `batch_id`, `initiator`, `amount`, `status`
- Assessment: adequate

**`payout_approved`**
- Emitted: yes
- Attributes: `payout_id`, `status`
- Assessment: adequate

**`payout_paid`**
- Emitted: yes
- Attributes: `payout_id`, `status`, `funds_paid`
- Assessment: adequate — includes the live transfer status

**`payout_cancelled`**
- Emitted: yes
- Attributes: `payout_id`, `status`
- Assessment: adequate

**`payout_failed`**
- Emitted: yes
- Attributes: `payout_id`, `status`, `reason`
- Assessment: adequate — includes failure reason

### Assessment
- **Total event types declared:** 7 (including `payout_params_updated`)
- **`payout_params_updated`:** ❓ declared in events.go but never emitted from the keeper
- **Missing attributes:** `batch_payout_created` doesn't include `merchant_id` which is part of the message
- **Info leakage:** failure reason is emitted — ensure it doesn't contain sensitive data (it comes from `FailureReason` field which is user-provided, so it could theoretically contain anything)
- **Gap:** defined `payout_params_updated` event constant but never emitted

---

## Summary

| Metric | Count |
|---|---|
| **Total declared event types (all modules)** | **31** |
| Events actually emitted from keeper | 28 |
| Events declared but never emitted | 3 (`escrow_params_updated`, `treasury_params_updated`, `payout_params_updated`) |
| Events with all relevant attributes | 12 |
| Events missing important attributes | 5+ |

### Events Missing Important Attributes

| Module | Event | Missing Attributes |
|---|---|---|
| escrow | `escrow_created` | `asset_denom`, `merchant_id` |
| treasury | `treasury_account_created` | `name`, `description` |
| treasury | `budget_created` | `account_id`, `title` |
| treasury | `grant_created` | `budget_id`, `recipient` |
| treasury | `spend_request_created` | `requester`, `recipient`, `account_id` |
| payout | `batch_payout_created` | `merchant_id` |

### Events Declared But Not Emitted

- `escrow_params_updated` — defined in `x/escrow/types/events.go` but never emitted in keeper
- `treasury_params_updated` — defined in `x/treasury/types/events.go` but never emitted in keeper
- `payout_params_updated` — defined in `x/payout/types/events.go` but never emitted in keeper

Additionally, **merchant** and **settlement** modules also lack params-update events (no event type even declared for them).

### Info Leakage Assessment

- **No unsafe info leaked** in any event — all emitted attributes are public state (addresses, amounts, statuses, metadata)
- **One note:** payout `fail_payout` event includes `failure_reason` which is user-supplied text — this could theoretically contain problematic content if not sanitized, but it's a risk of misuse rather than a code vulnerability

### Recommendations

1. Add params-update events for merchant, settlement, escrow, treasury, and payout (either emit the existing declared constants or add new ones)
2. Add `asset_denom` and `merchant_id` to escrow `escrow_created` event
3. Add `account_id` to treasury `budget_created` event, `budget_id` to `grant_created`, and `requester`/`recipient` to `spend_request_created`
4. Clean up unused event constants in escrow, treasury, and payout events.go files
