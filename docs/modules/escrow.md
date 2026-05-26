# NexaRail Escrow Module (x/escrow)

## Purpose

The `x/escrow` module provides protocol-level escrow records for buyer/seller payments on the NexaRail protocol. It tracks the full escrow lifecycle — creation, release, refund, dispute, and resolution — with authority/arbitrator oversight.

## v1 Scope

- Create escrow records between buyers and sellers via registered merchants
- Full lifecycle: CREATED → RELEASED/REFUNDED/DISPUTED/CANCELLED
- Dispute subsystem: OPEN → BUYER_WINS/SELLER_WINS/SETTLED/REJECTED
- Authority-gated dispute resolution, status management, and parameter updates
- Buyer/seller-gated release, refund, dispute, and cancel actions
- Indexed queries by escrow ID, buyer, seller, and merchant
- Genesis import/export with duplicate rejection

### Metadata-Only v1

This module records escrow state and lifecycle decisions only. No coins are moved, no module accounts are created for custody, and no balance transfers occur. Live escrow custody with actual fund locking will be implemented in a future phase.

### What This Module Does Not Do

- Custodial fund locking
- Automated payouts
- Marketplace payout splitting
- Milestone-based partial release
- KYC/AML identity verification (verification status is metadata only)
- Arbitrator registry (single authority in v1)
- Dispute evidence uploads
- Time-based auto-expiry enforcement (expiry timestamp is recorded but not actively enforced by begin blocker)

## State Model

### Escrow

| Field | Type | Default | Description |
|---|---|---|---|
| `escrow_id` | string | | Unique ID (lowercase alphanumeric + hyphens, 3-80 chars) |
| `buyer_address` | string | | Bech32 buyer address |
| `seller_address` | string | | Bech32 seller address (must differ from buyer) |
| `merchant_id` | string | | Merchant identifier (from x/merchant) |
| `asset_denom` | string | | Asset denomination |
| `amount` | Coin | | Escrow amount |
| `platform_fee` | Coin | 0 | Platform fee (reserved, v1 zero) |
| `seller_amount` | Coin | 0 | Seller net amount (reserved, v1 zero) |
| `status` | int32 | 1 | EscrowStatus enum |
| `dispute_status` | int32 | 1 | DisputeStatus enum |
| `arbitrator_address` | string | | Arbitrator address |
| `payment_reference` | string | | External payment reference (≤120 chars) |
| `memo` | string | | Memo (≤280 chars) |
| `release_reference` | string | | Release reference |
| `refund_reference` | string | | Refund reference |
| `dispute_reason` | string | | Dispute reason (≤1000 chars) |
| `resolution_note` | string | | Resolution note (≤1000 chars) |
| `created_at` | int64 | | Unix timestamp |
| `updated_at` | int64 | | Last update timestamp |
| `expires_at` | int64 | | Expiry timestamp |

### Params

| Parameter | Type | Default | Description |
|---|---|---|---|
| `escrows_enabled` | bool | true | Allow escrow creation |
| `max_reference_length` | uint32 | 120 | Maximum reference length |
| `max_memo_length` | uint32 | 280 | Maximum memo length |
| `max_dispute_reason_length` | uint32 | 1000 | Maximum dispute reason length |
| `max_resolution_note_length` | uint32 | 1000 | Maximum resolution note length |
| `min_escrow_amount` | Coin | 1unxrl | Minimum escrow amount |
| `default_expiry_seconds` | uint64 | 2592000 (30 days) | Default escrow duration |

## Status Lifecycle

```
Create → CREATED ──buyer/authority─→ RELEASED (terminal)
                  ──seller/authority→ REFUNDED (terminal)
                  ──buyer/seller───→ DISPUTED
                  ──buyer/authority→ CANCELLED (terminal)
                                     
DISPUTED ──authority──→ RELEASED (buyer_wins, seller_wins, settled)
                     → REFUNDED (buyer_wins)
                     → CREATED (rejected)
```

### Terminal Statuses
RELEASED, REFUNDED, and CANCELLED cannot transition to other statuses. Only CREATED escrows can be cancelled.

## Dispute Lifecycle

```
NONE → [dispute opened by buyer/seller] → OPEN
OPEN → [authority resolves] → BUYER_WINS → escrow status = REFUNDED
                            → SELLER_WINS → escrow status = RELEASED
                            → SETTLED → escrow status = RELEASED
                            → REJECTED → escrow status = CREATED
```

## Merchant Validation

Escrow creation requires:
1. Seller address must match a registered merchant in x/merchant
2. Merchant status must be Active (0)
3. Seller address must differ from buyer address

## Authority Policy

The module authority (governance address) controls:
- Dispute resolution (buyer_wins, seller_wins, settled, rejected)
- Release and refund (authority can override buyer/seller restrictions)
- Cancellation (authority can cancel any CREATED escrow)
- Parameter updates

## Messages

### MsgCreateEscrow

Buyer creates an escrow referencing a seller/merchant.

```bash
nexaraild tx escrow create order-123 nxr1seller merchant-1 1000000unxrl \
  --payment-reference "Invoice ABC" --memo "30-day net" \
  --expires-at 1717200000 --from buyer --gas auto
```

### MsgReleaseEscrow

Buyer or authority releases an escrow.

```bash
nexaraild tx escrow release order-123 \
  --release-reference "TX-456" --from buyer --gas auto
```

### MsgRefundEscrow

Seller or authority refunds an escrow.

```bash
nexaraild tx escrow refund order-123 \
  --refund-reference "Refund-789" --from seller --gas auto
```

### MsgOpenDispute

Buyer or seller opens a dispute.

```bash
nexaraild tx escrow dispute order-123 "Item not as described" --from buyer --gas auto
```

### MsgResolveDispute

Authority resolves a dispute with a resolution status and note.

```bash
nexaraild tx escrow resolve-dispute order-123 3 \
  --resolution-note "Evidence supports buyer" --from gov --gas auto
```

Resolutions: 3=buyer_wins, 4=seller_wins, 5=settled, 6=rejected

### MsgCancelEscrow

Buyer or authority cancels a CREATED escrow.

```bash
nexaraild tx escrow cancel order-123 --memo "Order cancelled" --from buyer --gas auto
```

### MsgUpdateParams

Authority updates module parameters.

```bash
nexaraild tx escrow update-params true --from gov --gas auto
```

## Queries

```bash
nexaraild query escrow params
nexaraild query escrow escrow order-123
nexaraild query escrow list
nexaraild query escrow by-buyer nxr1buyer
nexaraild query escrow by-seller nxr1seller
nexaraild query escrow by-merchant merchant-1
nexaraild query escrow exists order-123
```

## Events

| Event | When |
|---|---|
| `escrow_created` | Escrow created |
| `escrow_released` | Escrow released |
| `escrow_refunded` | Escrow refunded |
| `escrow_disputed` | Dispute opened |
| `escrow_dispute_resolved` | Dispute resolved |
| `escrow_cancelled` | Escrow cancelled |
| `escrow_params_updated` | Parameters updated |

## Indexes

- **By ID**: `EscrowKeyPrefix || escrow_id`
- **By Buyer**: `0x11 || buyer || escrow_id`
- **By Seller**: `0x12 || seller || escrow_id`
- **By Merchant**: `0x13 || merchant_id || escrow_id`

All indexes are rebuilt during `InitGenesis`.

## Genesis

Default genesis:
```json
{
  "params": {
    "escrows_enabled": true,
    "max_reference_length": 120,
    "max_memo_length": 280,
    "max_dispute_reason_length": 1000,
    "max_resolution_note_length": 1000,
    "min_escrow_amount": {"denom": "unxrl", "amount": "1"},
    "default_expiry_seconds": 2592000
  },
  "escrows": []
}
```

Validation: duplicate escrow IDs rejected, invalid escrows rejected, params validated.

## Security Notes

- Escrow ID must be unique (lowercase alphanumeric + hyphens, 3–80 chars)
- Buyer and seller must be different addresses
- Only buyer or authority can release/cancel
- Only seller or authority can refund
- Only buyer or seller can open a dispute
- Only authority can resolve disputes
- v1 is metadata-only: no funds are held by the protocol
- Length limits enforced on all string fields (references, memo, dispute reason, resolution note)

## Future Work

- Live escrow custody with module accounts
- Balance movement on release/refund
- Payouts integration (x/payout)
- Milestone-based partial release
- Arbitrator registry (multi-arbitrator)
- Dispute evidence uploads (IPFS/on-chain)
- Time-based auto-expiry enforcement
- Treasury integration (x/treasury)
- Stablecoin registry integration
- Automated refund processing
