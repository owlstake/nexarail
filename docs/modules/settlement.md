# NexaRail Settlement Module (x/settlement)

## Purpose

The `x/settlement` module records payment settlements between payers and registered merchants on the NexaRail protocol. It calculates protocol fees, applies merchant rebates, and splits fees to validators, treasury, and burn according to the x/fees fee policy.

## v1 Scope

- Record payer-to-merchant settlement events with full fee calculation
- Apply merchant rebate tier discounts against protocol fees
- Split fees to validator share, treasury share, and burn share per x/fees params
- Authority-gated status updates (pending → completed → failed/refunded/cancelled)
- Authority-gated parameter updates
- Indexed queries by settlement ID, merchant, and payer
- Genesis state with configurable params and optional initial settlements

### v1 Limitation

This is **metadata-only** settlement in v1. No live coin movement is performed. The settlement record captures the calculated fee breakdown and the settlement status, but actual fund transfers, escrow, and payouts will be implemented in future phases (x/escrow, x/payout, x/treasury).

**Phase 5F.2 update:** Live merchant-net transfer is now implemented behind `LiveEnabled` param (default false). When enabled by governance, `MsgCreateSettlement` transfers the merchant net amount from payer to merchant via `bank.SendCoins`. Treasury share, burn share, and validator share remain metadata-only.

**Phase 5F.4 update:** Treasury-share routing is now implemented behind `TreasuryRoutingEnabled` param (default false). When both `LiveEnabled=true` AND `TreasuryRoutingEnabled=true`, the treasury share is also transferred from payer to `nexarail_treasury` via `bank.SendCoinsFromAccountToModule`.

**Phase 5F.6 update:** Burn-share routing is now implemented behind `BurnRoutingEnabled` param (default false). When all three flags are enabled, the burn share is routed from payer to `nexarail_burner` and burned via `bank.BurnCoins`, permanently reducing total NXRL supply. Burn and validator shares remain metadata-only. See `docs/design/SETTLEMENT_BURN_ROUTING_DESIGN.md`.

## State Model

### Settlement

| Field | Type | Description |
|---|---|---|
| `Id` | uint64 | Auto-increment settlement ID |
| `Payer` | string | Bech32 payer address |
| `MerchantOwner` | string | Bech32 merchant owner address |
| `MerchantId` | string | Merchant identifier (from x/merchant) |
| `SettlementAddress` | string | Merchant settlement address at time of settlement |
| `Amount` | Coin | Settlement amount |
| `FeeAmount` | Coin | Net protocol fee after rebate |
| `ValidatorShare` | Coin | Validator/delegator share of fee |
| `TreasuryShare` | Coin | Treasury share of fee |
| `BurnShare` | Coin | Burn share of fee |
| `RebateAppliedBps` | uint32 | Merchant rebate applied (basis points) |
| `RebateAmount` | Coin | Rebate discount amount |
| `Status` | int32 | 0=pending, 1=completed, 2=failed, 3=refunded, 4=cancelled |
| `FundsSettled` | bool | Whether the live merchant-net transfer was executed (Phase 5F.2) |
| `PaymentReference` | string | External payment reference |
| `Memo` | string | Settlement memo |
| `Metadata` | string | Free-form metadata |
| `CreatedAt` | int64 | Unix timestamp |
| `UpdatedAt` | int64 | Last update timestamp |

### Status Lifecycle

```
Create → Completed (auto, v1 metadata-only)
       ↓
   [authority] → Failed (terminal)
               → Refunded (terminal)
               → Cancelled (terminal)
```

Terminal statuses (Failed, Refunded, Cancelled) cannot transition to other statuses. Completed cannot transition back to Pending.

### Params

| Parameter | Type | Default | Description |
|---|---|---|---|
| `Enabled` | bool | true | Allow settlement creation |
| `LiveEnabled` | bool | false | Enable live merchant-net bank transfer (Phase 5F.2) |
| `TreasuryRoutingEnabled` | bool | false | Enable treasury-share routing to nexarail_treasury (Phase 5F.4) |
| `BurnRoutingEnabled` | bool | false | Enable burn-share routing via nexarail_burner + BurnCoins (Phase 5F.6) |
| `FeeRateBps` | uint32 | 100 (1%) | Protocol fee rate in basis points |
| `RebateTiers` | []uint32 | [0, 500, 1000, 1500, 2000] | Reabate per tier (none/bronze/silver/gold/platinum) |

## Fee Calculation

For a settlement of amount `A` with merchant rebate tier `T`:

```
base_fee = A × FeeRateBps ÷ 10000
rebate   = base_fee × RebateTiers[T] ÷ 10000
net_fee  = base_fee - rebate

validator_share = net_fee × validator_share_bps ÷ 10000
treasury_share  = net_fee × treasury_share_bps ÷ 10000
burn_share      = net_fee - validator_share - treasury_share
```

Where `validator_share_bps`, `treasury_share_bps`, `burn_share_bps` come from x/fees.

### Example

Settlement of 1,000,000 unxrl, silver tier merchant (10% rebate), 1% fee rate:

```
base_fee = 1,000,000 × 100 ÷ 10000 = 10,000
rebate   = 10,000 × 1000 ÷ 10000  = 1,000
net_fee  = 9,000

validator = 9,000 × 6000 ÷ 10000 = 5,400
treasury  = 9,000 × 2000 ÷ 10000 = 1,800
burn      = 9,000 − 5,400 − 1,800 = 1,800
```

## Merchant Validation

Before creating a settlement:
1. Merchant must exist in x/merchant
2. Merchant status must be Active (0)
3. Amount must be positive

## Messages

### MsgCreateSettlement

Create a new settlement (payer = signer).

```bash
nexaraild tx settlement create nxr1merchant 1000000unxrl \
  --metadata "Order #12345" \
  --from payer --chain-id nexarail-devnet-1 --gas auto
```

### MsgUpdateSettlementStatus

Authority only. Update settlement status.

```bash
nexaraild tx settlement update-status 42 2 \
  --from gov --chain-id nexarail-devnet-1 --gas auto
```

### MsgUpdateParams

Authority only. Update module parameters.

```bash
nexaraild tx settlement update-params 100 true \
  --from gov --chain-id nexarail-devnet-1 --gas auto
```

## Queries

```bash
nexaraild query settlement params                    # module parameters
nexaraild query settlement settlement 1              # settlement by ID
nexaraild query settlement list                      # all settlements
nexaraild query settlement by-merchant nxr1merchant  # by merchant owner
nexaraild query settlement by-payer nxr1payer        # by payer address
```

## Events

| Event | When |
|---|---|
| `settlement_created` | Settlement created |
| `settlement_status_updated` | Status changed by authority |

## Indexes

Three store indexes are maintained:
- **By ID**: primary key lookup via `SettlementKey(id)`
- **By merchant**: prefix scan via `0x11 || merchant_owner || id`
- **By payer**: prefix scan via `0x12 || payer || id`

Indexes are rebuilt during `InitGenesis`.

## Genesis

Default genesis:
```json
{
  "params": {
    "enabled": true,
    "fee_rate_bps": 100,
    "rebate_tiers": [0, 500, 1000, 1500, 2000]
  },
  "settlements": []
}
```

## Security Notes

- Settlement creation requires active merchant verification.
- Status updates and parameter changes are authority-gated.
- v1 is metadata-only; no coins are moved by the settlement module itself.
- No double-spend protection (v2 concern for live transfers).

## Future Work

- **Live bank transfers**: actual coin movement during settlement
- **Actual fee routing**: distribute collected fees to validators, treasury, burn
- **Treasury module integration**: automated treasury collection
- **Burn module integration**: automated protocol burn
- **Refunds**: automated refund processing
- **Escrow**: hold funds in escrow during settlement (x/escrow)
- **Payouts**: automated merchant payout splitting (x/payout)
- **Stablecoin registry**: multi-denom settlement support
