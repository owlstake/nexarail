# NexaRail Merchant Module (x/merchant)

## Purpose

The `x/merchant` module manages on-chain merchant registration for the NexaRail protocol. Merchants register to receive payments and participate in the NexaRail settlement system.

## v1 Scope

- Register a merchant with profile data (name, description, website)
- Update an existing merchant's profile (owner-only; closed merchants reject updates)
- Collect a registration fee (governance-updatable)
- Authority-controlled operations: set status, verification status, rebate tier, update params
- Validate merchant data against module params
- Emit events on all state changes
- Include genesis state with initial merchants
- Expose query endpoints: params, merchant by owner, all merchants

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `RegistrationFee` | Coin | 1000000unxrl (1 NXR) | Fee to register a new merchant |
| `MinNameLength` | uint32 | 3 | Minimum merchant name length |
| `MaxNameLength` | uint32 | 64 | Maximum merchant name length |
| `MaxDescriptionLength` | uint32 | 256 | Maximum description length |

## Merchant Record

| Field | Type | Description |
|---|---|---|
| `Owner` | string (bech32) | Merchant owner address (primary key) |
| `Name` | string | Display name (3-64 chars) |
| `Description` | string | Business description (≤256 chars) |
| `Website` | string | Optional website URL |
| `Status` | int32 | 0=active, 1=inactive, 2=closed |
| `VerificationStatus` | int32 | 0=unverified, 1=verified, 2=rejected |
| `RebateTier` | int32 | 0=none, 1=bronze, 2=silver, 3=gold, 4=platinum |
| `CreatedAt` | int64 | Unix timestamp of registration |
| `UpdatedAt` | int64 | Unix timestamp of last update |

## Status Lifecycle

```
Register → Active ────────[authority]→ Inactive → Active
                ─────────[authority]→ Closed   (terminal)
                ─────────[authority or owner]→ ...updates allowed...
```

- `Active` (0): Merchant can receive payments and is visible.
- `Inactive` (1): Merchant is visible but cannot receive new payments. Can be reactivated.
- `Closed` (2): Terminal state. Merchant cannot be updated. Cannot be reactivated.

Only the module authority can change a merchant's status. Closed merchants cannot be updated by anyone (including the owner).

## Verification Status

Three verification states exist, all set by the module authority:

- `Unverified` (0): Default state for new merchants.
- `Verified` (1): Authority has verified the merchant's identity/credentials.
- `Rejected` (2): Authority has rejected the merchant's verification.

**Compliance note:** Verification status is metadata only. It does NOT perform KYC/AML on-chain. It is an informational field set by the protocol authority. It does not replace off-chain legal compliance obligations.

## Rebate Tiers

Five tiers exist, all set by the module authority:

- `None` (0): No rebate. Default for new merchants.
- `Bronze` (1)
- `Silver` (2)
- `Gold` (3)
- `Platinum` (4)

Rebate tiers affect fee discounts in the settlement system (x/settlement). Tier assignment is at the authority's discretion.

## Messages

### Owner-initiated

#### MsgRegisterMerchant

Register a new merchant. The sender pays the registration fee.

```bash
nexaraild tx merchant register "Acme Rail" "Rail logistics" "https://acme.com" \
  --from merchant-owner --chain-id nexarail-devnet-1 --gas auto
```

#### MsgUpdateMerchant

Update an existing merchant profile. Only the owner can update. Closed merchants reject updates.

```bash
nexaraild tx merchant update nxr1... "New Name" "New desc" "https://new.com" \
  --from merchant-owner --chain-id nexarail-devnet-1 --gas auto
```

### Authority-only

All authority-gated messages must be sent by the governance module address.

#### MsgUpdateParams

Update module parameters.

```bash
nexaraild tx merchant update-params 2000000unxrl 3 64 256 \
  --from gov --chain-id nexarail-devnet-1 --gas auto
```

#### MsgSetMerchantStatus

Set a merchant's status (0=active, 1=inactive, 2=closed).

```bash
nexaraild tx merchant set-status nxr1... 2 \
  --from gov --chain-id nexarail-devnet-1 --gas auto
```

#### MsgSetVerificationStatus

Set a merchant's verification status (0=unverified, 1=verified, 2=rejected).

```bash
nexaraild tx merchant set-verification nxr1... 1 \
  --from gov --chain-id nexarail-devnet-1 --gas auto
```

#### MsgSetRebateTier

Set a merchant's rebate tier (0=none, 1=bronze, 2=silver, 3=gold, 4=platinum).

```bash
nexaraild tx merchant set-rebate-tier nxr1... 3 \
  --from gov --chain-id nexarail-devnet-1 --gas auto
```

## Queries

```bash
nexaraild query merchant params              # module parameters
nexaraild query merchant merchant nxr1...    # merchant by owner address
nexaraild query merchant merchants           # all registered merchants
```

## Owner Index

Merchants are stored in the KV store under the `MerchantKeyPrefix || owner_bytes` key. This is the canonical owner index. The `InitGenesis` handler writes each genesis merchant into the store using `SetMerchant`, which builds this index. The `GetMerchant(owner)` query uses this index for O(1) lookup.

## Events

| Event | When |
|---|---|
| `merchant_registered` | New merchant registered |
| `merchant_updated` | Profile, status, verification, or tier updated |

## Genesis

Default genesis:
```json
{
  "params": {
    "registration_fee": {"denom": "unxrl", "amount": "1000000"},
    "min_name_length": 3,
    "max_name_length": 64,
    "max_description_length": 256
  },
  "merchants": []
}
```

Genesis validation checks:
- Params pass `Validate()`
- No duplicate merchant owners
- Every merchant passes `Validate()`

## Security Notes

- Only the merchant owner can update their profile.
- Closed merchants cannot be updated by anyone.
- Registration fee is collected at registration time.
- Status, verification, rebate tier, and params are authority-gated (governance only).
- Genesis validation rejects duplicates and invalid profiles.
- Verification status is metadata only — does not perform KYC/AML.
