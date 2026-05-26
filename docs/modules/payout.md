# NexaRail Payout Module (x/payout)

## Purpose

The `x/payout` module records and manages payout instructions for merchants, creators, affiliates, suppliers, and marketplace participants. It supports single and batch payouts with full lifecycle tracking, approvals, and reconciliation metadata.

## v1 Scope

- Create single and batch payout records
- Full lifecycle: CREATED → APPROVED → PAID/CANCELLED/FAILED
- Authority-gated approval, mark-paid, cancel, and fail operations
- Indexed queries by payout ID, merchant, recipient, and initiator
- Batch payout aggregation with total tracking
- Genesis import/export with duplicate rejection

### Metadata-Only by Default (with optional live transfers — Phase 5E)

This module is metadata-only by default: it records payout instructions and lifecycle decisions, and no coins move. Payout live transfers exist but are **disabled by default** behind the governance-controlled `live_enabled` parameter.

When `live_enabled = true`, `MsgMarkPayoutPaid` transfers the payout's net amount from the `nexarail_treasury` module account to the recipient **before** any status mutation; the `funds_paid` flag is then set true. When `live_enabled = false` (default), behaviour is unchanged: the payout transitions to PAID, `funds_paid` stays false, and the bank keeper is never called. Governance can enable payout `live_enabled` via `MsgUpdateParams`.

The live payout funding source in v1 is `nexarail_treasury`. Batch live payout execution is **not** implemented in v1 (future work); `MsgMarkPayoutPaid` remains per-payout.

### What This Module Does Not Do

- Live **batch** payout execution (future work — per-payout only in v1)
- Settlement live transfers and fee routing (separate phases)
- Payroll-style automated payouts
- Approval workflows by role
- Evidence and reconciliation attachments

## State Model

### Payout

| Field | Type | Description |
|---|---|---|
| `payout_id` | string | Unique ID (lowercase alphanumeric + hyphens, 3-80 chars) |
| `batch_id` | string | Optional batch link |
| `merchant_id` | string | Merchant identifier |
| `initiator_address` | string | Bech32 initiator address |
| `recipient_address` | string | Bech32 recipient address |
| `asset_denom` | string | Asset denomination |
| `amount` | Coin | Payout amount |
| `fee_amount` | Coin | Fee (v1 default 0) |
| `net_amount` | Coin | Net (v1 default = amount) |
| `status` | int32 | PayoutStatus enum |
| `funds_paid` | bool | True once treasury→recipient transfer succeeded (live mode only); always false in metadata mode |
| `payout_type` | int32 | PayoutType enum |
| `payout_reference` | string | Reference (≤120 chars) |
| `memo` | string | Memo (≤280 chars) |
| `external_reference` | string | External reconciliation ref |
| `failure_reason` | string | Failure reason (≤1000 chars) |
| `created_at` | int64 | Unix timestamp |
| `updated_at` | int64 | Last update |
| `approved_at` | int64 | Approval timestamp |
| `paid_at` | int64 | Payment timestamp |
| `cancelled_at` | int64 | Cancellation timestamp |
| `failed_at` | int64 | Failure timestamp |

### PayoutStatus

| Value | Meaning |
|---|---|
| 0 | unspecified |
| 1 | created |
| 2 | approved |
| 3 | paid |
| 4 | cancelled |
| 5 | failed |

### PayoutType

| Value | Meaning |
|---|---|
| 1 | creator |
| 2 | affiliate |
| 3 | supplier |
| 4 | marketplace_seller |
| 5 | refund |
| 6 | other |

### BatchPayout

| Field | Description |
|---|---|
| `batch_id` | Unique batch ID |
| `merchant_id` | Merchant identifier |
| `initiator_address` | Initiator |
| `payout_ids` | Linked payout IDs |
| `total_amount` | Aggregated total |
| `total_fee` | Aggregated fee |
| `total_net` | Aggregated net |
| `status` | BatchStatus enum |
| `batch_reference` | Reference |
| `memo` | Memo |
| `created_at` | Timestamp |
| `updated_at` | Timestamp |

### Params

| Parameter | Default | Description |
|---|---|---|
| `payouts_enabled` | true | Allow payout creation |
| `batch_payouts_enabled` | true | Allow batch creation |
| `approval_required` | true | Require approval step |
| `live_enabled` | false | Enable live treasury→recipient transfers on mark-paid (governance-controlled) |
| `max_reference_length` | 120 | Max reference chars |
| `max_memo_length` | 280 | Max memo chars |
| `max_failure_reason_length` | 1000 | Max failure reason chars |
| `max_batch_size` | 100 | Max payouts per batch |
| `min_payout_amount` | 1unxrl | Minimum payout |

## Status Lifecycle

```
Create → CREATED ──approve──→ APPROVED ──mark-paid──→ PAID (terminal)
        │              │                  │
        │              └─cancel──→ CANCELLED (terminal)
        │              └─fail────→ FAILED (terminal)
        └─cancel──→ CANCELLED (terminal)
        └─fail────→ FAILED (terminal)
```

If `approval_required` is false, payouts start as APPROVED.

## CLI

```bash
nexaraild query payout params
nexaraild query payout payout pay-001
nexaraild query payout list
nexaraild query payout by-merchant merchant-1
nexaraild query payout by-recipient nxr1recipient
nexaraild query payout by-initiator nxr1initiator
nexaraild query payout batch batch-001
nexaraild query payout batches
nexaraild query payout exists pay-001

nexaraild tx payout create pay-001 merchant-1 nxr1recipient 1000000unxrl 1 --from initiator --gas auto
nexaraild tx payout create-batch batch-001 merchant-1 nxr1recipient 1000000unxrl 1 pay-001 --from initiator
nexaraild tx payout approve pay-001 --from initiator
nexaraild tx payout mark-paid pay-001 EXT-REF --from authority
nexaraild tx payout cancel pay-001 --from initiator
nexaraild tx payout fail pay-001 "Insufficient funds" --from authority
nexaraild tx payout update-params true --from authority
```

## Live Payout Transfers (Phase 5E)

- Disabled by default (`live_enabled = false`) — payouts remain metadata-only.
- When enabled, `MarkPayoutPaid` transfers `net_amount` from `nexarail_treasury` to the recipient.
- The transfer happens **before** any state mutation. If it fails (e.g. insufficient treasury balance), the payout state is left unchanged and the message errors.
- After a successful transfer: `status = PAID`, `funds_paid = true`, `paid_at`/`updated_at` set, external reference recorded, and a `payout_paid` event with `funds_paid=true` is emitted.
- A payout already marked `funds_paid` cannot be paid again; non-approved, cancelled, and failed payouts cannot be paid.
- Helpers: `ActivePaidPayoutTotals(ctx)` (sum of net amounts of funded+paid payouts) and `ValidatePayoutFundsInvariant(ctx)` (rejects `funds_paid=true` without PAID status / invalid recipient / non-positive net).
- Batch live execution is **not** implemented in v1 — `MarkPayoutPaid` is per-payout.

## Security Notes

- Payout IDs must be unique (lowercase alphanumeric + hyphens, 3-80 chars)
- Initiator and recipient must be different addresses
- Only authority can mark-paid and fail payouts
- Metadata-only by default; live transfers are governance-gated via `live_enabled`
- Live transfers move funds only from `nexarail_treasury`; settlement and fee routing remain non-live
- Length limits enforced on all string fields

## Future Work

- Live **batch** payout execution (per-payout only in v1)
- Settlement integration for settlement→payout flow
- Escrow release integration for escrow→payout flow
- Payroll-style batch payout processing
- Role-based approval workflows
- Evidence and reconciliation attachments
- Stablecoin registry for multi-denom support
