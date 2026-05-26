# NexaRail Fees Module (x/fees)

## Purpose

The `x/fees` module manages protocol-level fee policy and fee distribution parameters for the NexaRail blockchain. It defines how transaction fees collected by the protocol are split between validators/delegators, the protocol treasury, and the burn mechanism.

## v1 Scope

- Define fee split parameters (in basis points)
- Expose governance-updatable params via `MsgUpdateParams`
- Support three fee destinations: validators/delegators, treasury, burn
- Validate that all shares total exactly 100%
- Emit events when parameters change
- Include genesis defaults
- Provide query endpoints for params and fee split proportions

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `ValidatorShareBps` | uint32 | 6000 | Validator/delegator share (basis points) |
| `TreasuryShareBps` | uint32 | 2000 | Protocol treasury share (basis points) |
| `BurnShareBps` | uint32 | 2000 | Burn share (basis points) |
| `FeeCollectorName` | string | "fee_collector" | Fee collector module account name |
| `TreasuryAccount` | string | "" | Bech32 protocol treasury address (empty = disabled) |
| `BurnEnabled` | bool | false | Enable burn mechanism |
| `MinProtocolFee` | Coin | 0unxrl | Minimum fee required for protocol fee splitting |

### Default Fee Split

| Destination | Percentage | Basis Points |
|---|---|---|
| Validators/Delegators | 60% | 6000 |
| Protocol Treasury | 20% | 2000 |
| Burn | 20% | 2000 |

### Validation Rules

1. All share values must be non-negative (uint32 is always non-negative).
2. Individual shares must not exceed 10000 (100%).
3. All three shares must total exactly 10000 basis points.
4. If `TreasuryShareBps > 0`, `TreasuryAccount` must be a valid bech32 address (or empty to allow).
5. `FeeCollectorName` must not be empty.
6. `MinProtocolFee` must not be negative.

## Messages

### MsgUpdateParams

Only the module authority (governance module account) may update parameters.

```go
type MsgUpdateParams struct {
    Authority string
    Params    Params
}
```

**CLI:**
```bash
nexaraild tx fees update-params \
  6000 2000 2000 \
  fee_collector \
  "" \
  false \
  1unxrl \
  --from gov \
  --chain-id nexarail-devnet-1 \
  --gas auto
```

Arguments:
1. `validator_share_bps` — Delegator/validator share in bps
2. `treasury_share_bps` — Treasury share in bps
3. `burn_share_bps` — Burn share in bps
4. `fee_collector_name` — Fee collector account name
5. `treasury_account` — Treasury bech32 address (use `""` to disable)
6. `burn_enabled` — Enable burn (`true`/`false`)
7. `min_fee` — Minimum protocol fee (e.g. `1unxrl`)

All three shares must total exactly 10000.

## Queries

### QueryParams

Returns the current fee module parameters.

**CLI:**
```bash
nexaraild query fees params
```

### QueryFeeSplit

Returns the current fee split proportions in basis points.

**CLI:**
```bash
nexaraild query fees fee-split
```

Example output:
```
Validator/Delegator Share: 6000 bps (60.00%)
Treasury Share:            2000 bps (20.00%)
Burn Share:                2000 bps (20.00%)
```

## Genesis

### Default Genesis

```json
{
  "params": {
    "validator_share_bps": 6000,
    "treasury_share_bps": 2000,
    "burn_share_bps": 2000,
    "fee_collector_name": "fee_collector",
    "treasury_account": "",
    "burn_enabled": false,
    "min_protocol_fee": {
      "denom": "unxrl",
      "amount": "0"
    }
  }
}
```

Genesis validation checks:
- Params must pass `Validate()`
- All share total validation

## Events

The module emits events on parameter updates:

```json
{
  "type": "fees_update_params",
  "attributes": [
    {"key": "validator_share_bps", "value": "6000"},
    {"key": "treasury_share_bps", "value": "2000"},
    {"key": "burn_share_bps", "value": "2000"},
    {"key": "fee_collector_name", "value": "fee_collector"},
    {"key": "treasury_account", "value": ""},
    {"key": "burn_enabled", "value": "false"},
    {"key": "min_protocol_fee", "value": "0unxrl"},
    {"key": "authority", "value": "nxr10d07y..."}
  ]
}
```

## Engineering Notes

### Basis Points

All fee shares are expressed in basis points (bps), where 1 bps = 0.01%. 10000 bps = 100%.

Using basis points avoids floating-point arithmetic and enables exact integer calculations.

### Module Authority

The fees module authority is set to the governance module address at genesis. Only the governance module can update parameters via `MsgUpdateParams`. This ensures parameter changes go through the on-chain governance process.

### Storage

Params are stored as JSON in the module's KV store at the `ParamsKey` prefix. No subspace is used — params are stored directly to avoid subspace double-registration risks.

### Invariants

The module registers an invariant that checks shares total exactly 10000 bps. This invariant runs during `crisis` module checks.

## Security Notes

- The v1 implementation is parameter-management only. No live fee routing is performed.
- Params are governance-controlled to prevent unauthorized changes.
- Genesis state is validated before chain start.
- All tests validate edge cases including invalid shares, empty collector names, invalid treasury addresses, and negative minimum fees.

## Future Work (Not in v1)

- Live fee routing (split collected fees according to params)
- Fee routing via hooks or ante handler modification
- Treasury auto-collection mechanism
- Burn integration with the bank module's burn function
- Commission-based validator/delegator fee distribution
- Integration with the Cosmos SDK `x/auth` fee collector
