# NexaRail Settlement Treasury Fee Routing Design

**Phase:** 5F.3 — Design
**Date:** 2026-05-25
**Status:** Design complete — awaiting implementation gate (Phase 5F.4)
**Depends on:** Phase 5F.2 (live merchant-net transfer) complete
**Routing Option:** Extension of Option C → Option D (merchant + treasury)

## 1. Current Phase 5F.2 Behaviour

### 1.1 Live Merchant-Net Transfer Only

```
LiveEnabled=true:
  payer → merchant (SettlementAddress): merchantNet = gross - netFee
  treasuryShare: metadata only (stored on settlement record)
  burnShare: metadata only
  validatorShare: metadata only
  FundsSettled: true
```

### 1.2 Current Params

```go
type Params struct {
    Enabled     bool     // settlements enabled
    LiveEnabled bool     // merchant-net live transfer gate (default false)
    FeeRateBps  uint32   // protocol fee rate (default 100 = 1%)
    RebateTiers []uint32 // merchant rebate tiers
}
```

### 1.3 Current BankKeeper Interface

```go
type BankKeeper interface {
    SendCoins(ctx sdk.Context, fromAddr sdk.AccAddress, toAddr sdk.AccAddress, amt sdk.Coins) error
}
```

Single method — direct account-to-account transfer. Used for payer → merchant.

## 2. Target Phase 5F.3 Behaviour

### 2.1 Merchant + Treasury Live Transfer

```
LiveEnabled=true + TreasuryRoutingEnabled=true:
  payer → merchant (SettlementAddress): merchantNet = gross - netFee
  payer → nexarail_treasury:             treasuryShare
  burnerShare: metadata only
  validatorShare: metadata only
  FundsSettled: true
```

### 2.2 Backward Compatibility

When `TreasuryRoutingEnabled=false` (default), behaviour is identical to Phase 5F.2:
- `LiveEnabled=true` + `TreasuryRoutingEnabled=false` → merchant-only transfer (unchanged)
- `LiveEnabled=false` → metadata-only (unchanged)

### 2.3 Flag Independence

| LiveEnabled | TreasuryRoutingEnabled | Behaviour |
|---|---|---|
| false | false | Metadata-only (v1) |
| false | true | No-op — treasury routing requires live |
| true | false | Merchant-net only (Phase 5F.2) |
| true | true | Merchant + treasury (Phase 5F.3) |

`TreasuryRoutingEnabled=true` is only effective when `LiveEnabled=true`. If `LiveEnabled=false`, treasury routing is ignored (no bank keeper calls at all).

## 3. Flag Design Decision

### Selected: Separate `TreasuryRoutingEnabled` flag (default false)

**New params struct:**

```go
type Params struct {
    Enabled                bool     // settlements enabled
    LiveEnabled            bool     // merchant-net live transfer gate
    TreasuryRoutingEnabled bool     // NEW — treasury share routing gate (default false)
    FeeRateBps             uint32   // protocol fee rate
    RebateTiers            []uint32 // merchant rebate tiers
}
```

### Rationale for separate flag

1. **Independent governance control.** Merchant live settlement can be enabled without enabling treasury fee routing. A governance proposal can enable merchant payments first, observe behaviour, then enable treasury routing separately.
2. **Fault isolation.** If treasury routing has a bug, disabling `TreasuryRoutingEnabled` restores merchant-only behaviour without disabling merchant payments.
3. **Matches per-module pattern.** Escrow, treasury, and payout each have their own `LiveEnabled`. Settlement's `LiveEnabled` controls merchant transfers; `TreasuryRoutingEnabled` controls the treasury extension of the same module.
4. **Testing surface.** Each flag toggle can be independently tested. `TreasuryRoutingEnabled=false` tests stay unchanged from Phase 5F.2.
5. **Future extensibility.** A `BurnRoutingEnabled` flag or `ValidatorRoutingEnabled` flag can be added similarly without touching the existing flags.

### Rejected alternatives

- **Same LiveEnabled flag (Option A):** Couples merchant payments and treasury routing. A treasury bug breaks merchant payments. Governance loses granular control.
- **Defer entirely (Option C):** Delays treasury fee accumulation. The code change is small (one additional bank call); deferring provides no safety benefit while delaying protocol revenue.

## 4. BankKeeper Interface Expansion

### Current (Phase 5F.2)

```go
type BankKeeper interface {
    SendCoins(ctx sdk.Context, fromAddr sdk.AccAddress, toAddr sdk.AccAddress, amt sdk.Coins) error
}
```

### Required for Phase 5F.3

```go
type BankKeeper interface {
    SendCoins(ctx sdk.Context, fromAddr sdk.AccAddress, toAddr sdk.AccAddress, amt sdk.Coins) error
    SendCoinsFromAccountToModule(ctx sdk.Context, fromAddr sdk.AccAddress, recipientModule string, amt sdk.Coins) error
}
```

**Why `SendCoinsFromAccountToModule` is needed:**

The treasury module account (`nexarail_treasury`) is registered in `blockedAddrs` in `app/app.go`. Direct `SendCoins` to a blocked address is rejected by the bank module. `SendCoinsFromAccountToModule` bypasses the blocked-address check for module accounts — it is the canonical way to send coins into a module account from a user account.

**Account address construction in the keeper:**

```go
import authtypes "github.com/cosmos/cosmos-sdk/x/auth/types"

treasuryAddr := authtypes.NewModuleAddress(treasurytypes.TreasuryModuleAccount)
// But SendCoinsFromAccountToModule takes the module NAME string, not the address
k.bankKeeper.SendCoinsFromAccountToModule(ctx, payerAddr, treasurytypes.TreasuryModuleAccount, coins)
```

The treasury module constant `"nexarail_treasury"` is already defined in `x/treasury/types/keys.go`.

## 5. Transfer Order

### Recommended Order

```
1. Calculate all amounts (pure function, no side effects)
   - merchantNet = gross - netFee
   - treasuryShare = netFee * TreasuryShareBps / 10000

2. Validate all addresses
   - payerAddr (from msg.Payer)
   - merchantSettlementAddr (from settlementAddress)
   - treasury module name (constant — always valid)

3. Transfer 1: payer → merchant (merchantNet)
   via bank.SendCoins(ctx, payerAddr, merchantAddr, coins)

4. Transfer 2: payer → nexarail_treasury (treasuryShare)
   via bank.SendCoinsFromAccountToModule(ctx, payerAddr, "nexarail_treasury", coins)

5. Only after BOTH succeed:
   - Set FundsSettled = true
   - Set Status = Completed
   - Store settlement record
   - Emit event
```

### Why Merchant First, Treasury Second

1. **Semantic priority.** The merchant is the primary beneficiary of a settlement. If either transfer fails, both roll back (SDK atomicity), so the order is cosmetic within a single transaction. But merchant-first communicates intent.
2. **Balance sufficiency.** The payer must have enough balance for `merchantNet + treasuryShare`. The merchant transfer is larger (typically ~99% of gross for 1% fee). If the payer has insufficient funds, the larger transfer fails first, providing a clearer error.
3. **Consistency with Phase 5F.2.** The merchant transfer path is unchanged from the proven implementation.

### Atomicity Guarantee

Cosmos SDK transactions are atomic — all state changes within a single `DeliverTx` either commit or roll back together. In `CreateSettlement`:

```
if transfer1 fails → return error → entire message handler reverts → no state written
if transfer2 fails → return error → entire message handler reverts → no state written
```

The SDK's `RunMsgs` wraps message execution in a `CacheTx` — state writes are only committed if all messages succeed. Both bank transfers and the settlement KV write happen within the same transaction.

**Key invariant:** State mutation (SetSettlement) happens AFTER all bank transfers. This is already the pattern in Phase 5F.2 and is unchanged.

### Edge Case: Transfer 1 Succeeds, Transfer 2 Fails

```
transfer1: payer → merchant ✓ (bank state mutated in cache)
transfer2: payer → treasury ✗ (error returned)
→ message handler returns error
→ CacheTx discarded
→ transfer1 is rolled back (never committed to bank store)
→ settlement NOT stored
```

No partial execution. No state inconsistency. The Cosmos SDK guarantees this.

## 6. Code Structure (Phase 5F.4)

```go
// In CreateSettlement, after fee calculation:

fundsSettled := false
if params.LiveEnabled {
    merchantNet := amount.Sub(netFee)
    if merchantNet.IsNegative() {
        return nil, fmt.Errorf("merchant net amount is negative: %w", types.ErrAmountNotPositive)
    }

    // Validate merchant settlement address
    merchantSettlementAddr, addrErr := sdk.AccAddressFromBech32(settlementAddress)
    if addrErr != nil {
        return nil, fmt.Errorf("invalid settlement address: %w", addrErr)
    }

    // Transfer 1: payer → merchant
    if err := k.bankKeeper.SendCoins(ctx, payerAddr, merchantSettlementAddr,
        sdk.NewCoins(sdk.NewCoin(denom, merchantNet))); err != nil {
        return nil, fmt.Errorf("live settlement merchant transfer failed: %w", err)
    }

    // Transfer 2: payer → treasury (only if TreasuryRoutingEnabled)
    if params.TreasuryRoutingEnabled {
        if err := k.bankKeeper.SendCoinsFromAccountToModule(ctx, payerAddr,
            treasurytypes.TreasuryModuleAccount,
            sdk.NewCoins(sdk.NewCoin(denom, treasuryShare))); err != nil {
            return nil, fmt.Errorf("live settlement treasury routing failed: %w", err)
        }
    }

    fundsSettled = true
}

// State mutation (after all transfers)
settlement.FundsSettled = fundsSettled
settlement.Status = int32(types.SettlementCompleted)
settlement.UpdatedAt = now

if err := k.SetSettlement(ctx, settlement); err != nil {
    return nil, err
}

// Emit event with treasury_routed attribute
```

## 7. Fee Calculation (Unchanged)

### Treasury Share Formula

```
treasuryShare = netFee * TreasuryShareBps / 10000
```

Where:
- `netFee = baseFee - rebateAmount` (after merchant rebate)
- `TreasuryShareBps = 2000` (default, from x/fees params)
- Division is integer floor

### Rebate Effect on Treasury Share

Rebates reduce the protocol fee BEFORE the fee split. This means treasury share is calculated on the net fee, not the gross fee:

```
Without rebate: baseFee = 1000, treasuryShare = 1000 * 2000/10000 = 200
With 10% rebate: netFee = 900, treasuryShare = 900 * 2000/10000 = 180
```

The merchant gets the rebate benefit. Treasury, validators, and burn all share the reduced fee proportionally. This is correct — the rebate is a discount to the merchant, not a subsidy from treasury.

### Payer Total Deduction

```
payer_total = merchantNet + treasuryShare
            = (gross - netFee) + (netFee * TreasuryShareBps / 10000)
```

For gross=100000, feeRate=100bps, rebateTier=2 (1000bps):
```
baseFee = 100000 * 100 / 10000 = 1000
rebate = 1000 * 1000 / 10000 = 100
netFee = 900
merchantNet = 100000 - 900 = 99100
treasuryShare = 900 * 2000 / 10000 = 180
payer_total = 99100 + 180 = 99280
```

The payer sends 99280 unxrl total. 99100 to merchant, 180 to treasury. 720 unxrl (netFee - treasuryShare) remains as metadata (validator + burn shares).

## 8. Rounding / Dust Policy

### Current Policy (unchanged from Phase 5F.2)

- All divisions are integer floor (Go `/` with `sdk.Int`)
- `burnShare = netFee - valShare - treasuryShare` — absorbs remainder
- `merchantNet = gross - netFee` — exact, no division
- Maximum rounding error: < 3 unxrl per settlement (< 0.000003 NXRL)

### Treasury Share Rounding

Treasury share is calculated as `netFee * 2000 / 10000`. Integer division floors towards zero. The lost fractional unxrl goes to burn share (via remainder absorption).

**Example where treasury share loses dust:**
```
netFee = 9999
treasuryShare = 9999 * 2000 / 10000 = 1999 (floor, loses 0.8)
valShare      = 9999 * 6000 / 10000 = 5999 (floor, loses 0.4)
burnShare     = 9999 - 1999 - 5999 = 2001 (absorbs both fractions)
```

Treasury receives exactly `treasuryShare` unxrl. The dust stays in burn share (metadata in Phase 5F.3). When burn routing is implemented (Phase 5F.5+), the dust is burned — supply reduction, not treasury leakage.

## 9. Why Burn and Validator Shares Remain Metadata

### Burn Share

- `bank.BurnCoins` requires a module account with burn permissions
- Burn reduces total supply — requires supply invariant verification
- Supply invariant testing is deferred to Phase 5F.5+
- Burn is irreversible — higher audit bar than sending to treasury

### Validator Share

- Validator distribution requires integration with Cosmos SDK `x/distribution`
- Cannot simply `SendCoins` to validators — must go through distribution module's `AllocateTokens` or `FundCommunityPool`
- Distribution module has complex accounting (validator commission, delegator shares)
- Requires understanding of the validator set and commission structure
- Deferred to Phase 5F.6+

## 10. Why Fee Router is Still Deferred

The `nexarail_fee_router` module account exists (registered in Phase 5B) but is unused. It was designed as an intermediate account for fee splitting:

```
payer → fee_router → {merchant, treasury, burn, validators}
```

Phase 5F.3 does NOT use it because:
1. Direct transfers (payer → merchant, payer → treasury) are simpler
2. Fee router adds an intermediate account balance that must be zeroed after each settlement (invariant burden)
3. Fee router is primarily useful for BeginBlock fee routing (SDK fee_collector → fee_router → distribution), not for in-message settlement transfers
4. If BeginBlock routing is implemented later, the fee_router can receive from fee_collector without changing settlement's direct-transfer pattern

## 11. State Fields

No new state fields are needed on the Settlement struct. The existing fields are sufficient:

| Field | Phase 5F.2 | Phase 5F.3 |
|---|---|---|
| `Amount` | Gross settlement amount | Unchanged |
| `FeeAmount` | Net fee after rebate | Unchanged |
| `TreasuryShare` | Metadata (calculated, stored) | Now also live-transferred |
| `BurnShare` | Metadata | Unchanged (metadata) |
| `ValidatorShare` | Metadata | Unchanged (metadata) |
| `FundsSettled` | true when merchant transferred | true when merchant + treasury transferred |
| `Status` | Completed | Unchanged |

The treasury transfer is reflected in on-chain balances (treasury module account balance increases), not in a new state field. The `TreasuryShare` field on the settlement record already captures the amount.

## 12. Event Attributes

### New Attribute

```go
AttributeKeyTreasuryRouted = "treasury_routed"
```

Emitted in `settlement_created` event:

```go
ctx.EventManager().EmitEvent(sdk.NewEvent(
    types.EventTypeCreateSettlement,
    // ... existing attributes ...
    sdk.NewAttribute(types.AttributeKeyTreasuryRouted, fmt.Sprintf("%t", treasuryWasRouted)),
))
```

`treasury_routed` is `"true"` when `TreasuryRoutingEnabled=true` and the treasury transfer succeeded. `"false"` otherwise.

## 13. Migration Impact

### State Migration

**None required.** Phase 5F.3 adds:
- One new params field (`TreasuryRoutingEnabled`) — defaults to `false`, backward compatible
- One new BankKeeper interface method (`SendCoinsFromAccountToModule`) — the real `app.BankKeeper` already implements this; only the mock in tests needs updating

Existing settlement records are unaffected. `FundsSettled=true` on old records correctly reflects that the merchant transfer happened; the treasury share was not routed (matching the params at the time).

### Genesis

```go
func DefaultParams() Params {
    return Params{
        Enabled:                true,
        LiveEnabled:            false,
        TreasuryRoutingEnabled: false,  // NEW
        FeeRateBps:             DefaultFeeRateBps,
        RebateTiers:            tiers,
    }
}
```

Default genesis produces `TreasuryRoutingEnabled=false`. Existing genesis files are compatible (the JSON unmarshal will zero-fill the missing field to `false`).

## 14. Risks and Mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| Treasury module account not funded | Low | Treasury can receive genesis funds; settlement routing is additive |
| TreasuryRoutingEnabled=true but LiveEnabled=false | None | Code explicitly checks LiveEnabled first; treasury routing is a no-op |
| Payer balance insufficient for merchant+treasury total | Medium | Both transfers fail atomically (SDK); payer must have balance for full amount |
| Treasury module account blocked from receives | None | `SendCoinsFromAccountToModule` bypasses blocked-address check by design |
| Denom mismatch between settlement and treasury | Low | Same denom used throughout (settlement.Amount.Denom) |
| Governance enables treasury routing without testing | Medium | Separate flag allows observation of merchant-only path first |
| Mock bank keeper doesn't implement new method | Low | Test compilation will fail until mock is updated |
| Existing merchant-only tests break | None | TreasuryRoutingEnabled defaults to false — no behaviour change |

## 15. App Wiring (Phase 5F.4)

No changes to `app/app.go` needed. The `BankKeeper` interface expands but `app.BankKeeper` already implements `SendCoinsFromAccountToModule`. The settlement keeper constructor signature is unchanged.

```go
// Already correct from Phase 5F.2:
app.SettlementKeeper = settlementkeeper.NewKeeper(
    app.keys[settlementtypes.StoreKey],
    authority,
    app.MerchantKeeper,
    app.FeesKeeper,
    app.BankKeeper,  // implements expanded BankKeeper interface
)
```

## 16. Verification Gates (Phase 5F.4)

- [ ] `go build ./...` passes with expanded BankKeeper interface
- [ ] `go vet ./...` passes
- [ ] `go test ./...` — all existing tests pass
- [ ] `TreasuryRoutingEnabled=false` → merchant-only behaviour unchanged
- [ ] `TreasuryRoutingEnabled=true` + `LiveEnabled=true` → both transfers execute
- [ ] Treasury module account balance increases by treasuryShare
- [ ] Failed treasury transfer → settlement not stored
- [ ] No regression in escrow, treasury, payout, fees, merchant tests
