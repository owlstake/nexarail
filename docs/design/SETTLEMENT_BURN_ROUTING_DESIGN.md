# NexaRail Settlement Burn Routing Design

**Phase:** 5F.5 — Design
**Date:** 2026-05-25
**Status:** Design complete — awaiting implementation gate (Phase 5F.6)
**Depends on:** Phase 5F.4 (merchant + treasury live transfers)
**Previous pattern:** Phase 5F.3 (separate flag, bank method expansion, design-before-implement)

## 1. Current Phase 5F.4 Behaviour

```
LiveEnabled=true + TreasuryRoutingEnabled=true:
  payer → merchant:             merchantNet = gross - netFee
  payer → nexarail_treasury:    treasuryShare
  burnShare:                    metadata only (stored on settlement record)
  validatorShare:               metadata only
  FundsSettled:                 true
```

### Current Params

```go
type Params struct {
    Enabled                bool    // settlements enabled
    LiveEnabled            bool    // merchant-net gate
    TreasuryRoutingEnabled bool    // treasury-share gate
    FeeRateBps             uint32  // 100 = 1%
    RebateTiers            []uint32
}
```

### Current BankKeeper Interface

```go
type BankKeeper interface {
    SendCoins(ctx, from, to, coins) error
    SendCoinsFromAccountToModule(ctx, from, moduleName, coins) error
}
```

## 2. Target Phase 5F.6 Behaviour

### Full Live Settlement (Merchant + Treasury + Burn)

```
LiveEnabled=true + TreasuryRoutingEnabled=true + BurnRoutingEnabled=true:
  payer → merchant:             merchantNet
  payer → nexarail_treasury:    treasuryShare
  bank.BurnCoins(nexarail_burner, burnShare)     ← NEW
  validatorShare:               metadata only
  FundsSettled:                 true
  BurnExecuted:                 true (new field)
```

### Flag Independence

| LiveEnabled | TreasuryRoutingEnabled | BurnRoutingEnabled | Transfers |
|---|---|---|---|
| false | * | * | None (metadata-only) |
| true | false | false | Merchant only (Phase 5F.2) |
| true | true | false | Merchant + Treasury (Phase 5F.4) |
| true | true | true | Merchant + Treasury + Burn (Phase 5F.6) |

Burn requires both `LiveEnabled=true` AND `TreasuryRoutingEnabled=true`. This is because:
1. If the treasury share isn't being routed, burning the burn share in isolation is inconsistent
2. All three shares (treasury, burn, validator) share the same net fee — they make sense as a unit
3. Governance should enable treasury routing before enabling burn (nested dependency)

## 3. Flag Design

### Selected: Separate `BurnRoutingEnabled` flag (default false)

```go
type Params struct {
    Enabled                bool    // settlements enabled
    LiveEnabled            bool    // merchant-net gate
    TreasuryRoutingEnabled bool    // treasury-share gate
    BurnRoutingEnabled     bool    // NEW — burn routing gate (default false)
    FeeRateBps             uint32
    RebateTiers            []uint32
}
```

**Effective only when `LiveEnabled=true` AND `TreasuryRoutingEnabled=true`.**

## 4. Burn Mechanism Selection

### Option A: `bank.BurnCoins` via Dedicated Burner Module Account

**Requires:** A module account with `authtypes.Burner` permission.

```
1. Register "nexarail_burner" in app.go with {authtypes.Burner} permission
2. Add to blockedAddrs to prevent direct user sends
3. Expand BankKeeper interface: SendCoinsFromAccountToModule + BurnCoins
4. Flow:
   a. payer → nexarail_burner (SendCoinsFromAccountToModule)
   b. BurnCoins(ctx, "nexarail_burner", burnCoins)
```

**Pros:**
- True supply reduction — total NXRL supply decreases
- Auditable on-chain (supply invariant changes)
- Matches Cosmos SDK convention (x/bank Burner pattern)

**Cons:**
- Requires new module account registration in app.go
- Requires burner module account to exist in genesis
- Two bank calls (send + burn)
- Supply invariant must be verified

### Option B: Dead Address Send

```
payer → sdk.AccAddress{} (all-zero address): burnShare
```

**Pros:**
- Simplest — one bank call, no module account
- No permission changes needed
- Effectively removes coins from circulation
- No supply invariant changes needed

**Cons:**
- Does not reduce `totalSupply` — coins exist but are permanently inaccessible
- Less clean than true burn for audit/reporting
- Not standard Cosmos practice (dead address sends are discouraged)
- All-zero address is not a valid bech32 — `SendCoins` may reject it

### Recommendation: Option A (bank.BurnCoins)

`bank.BurnCoins` with a `nexarail_burner` module account is the correct Cosmos pattern. It requires more infrastructure but produces clean supply accounting. The burner module account registration is small (one permission entry in app.go).

### Implementation (two-step burn):

```go
if params.BurnRoutingEnabled && burnShare.IsPositive() {
    // Step 1: Transfer burn share from payer to burner module
    if err := k.bankKeeper.SendCoinsFromAccountToModule(ctx, payerAddr,
        BurnerModuleAccount,
        sdk.NewCoins(sdk.NewCoin(denom, burnShare))); err != nil {
        return nil, fmt.Errorf("live settlement burn routing failed: %w", err)
    }
    // Step 2: Burn the coins from the burner module  
    if err := k.bankKeeper.BurnCoins(ctx, BurnerModuleAccount,
        sdk.NewCoins(sdk.NewCoin(denom, burnShare))); err != nil {
        return nil, fmt.Errorf("burn execution failed: %w", err)
    }
}
```

## 5. BankKeeper Interface Expansion

```go
// Phase 5F.6 — adds BurnCoins
type BankKeeper interface {
    SendCoins(ctx, from, to, coins) error
    SendCoinsFromAccountToModule(ctx, from, moduleName, coins) error
    BurnCoins(ctx sdk.Context, moduleName string, amt sdk.Coins) error  // NEW
}
```

## 6. Module Account Infrastructure

### New Account Registration (app.go)

```go
const NexaRailBurnerModuleAccount = "nexarail_burner"

// In maccPerms:
maccPerms = map[string][]string{
    authtypes.FeeCollector: nil,
    // ... existing ...
    NexaRailBurnerModuleAccount: {authtypes.Burner},
}

// In blockedAddrs loop (auto-blocked via GetMaccPerms())
```

### Constant in Settlement Keeper

```go
// Must match app.NexaRailBurnerModuleAccount
const BurnerModuleAccount = "nexarail_burner"
```

## 7. State Fields

### New Field: `BurnExecuted bool`

```go
type Settlement struct {
    // ... existing fields ...
    FundsSettled      bool  // true when merchant (and optionally treasury+burn) transferred
    BurnExecuted      bool  // NEW — true when burn share was actually burned
}
```

**Why a separate field?** `FundsSettled` tracks merchant payment. `BurnExecuted` tracks supply reduction. Future phases may enable merchant-only settlement with burn (unlikely but possible). The separate field also aids invariant checking and audit.

### Validation

```go
// BurnExecuted=true requires FundsSettled=true (burn only happens after merchant paid)
// BurnExecuted=true requires status=Completed
```

## 8. Event Attributes

```go
AttributeKeyBurnRouted   = "burn_routed"    // "true"/"false"
AttributeKeyBurnAmount   = "burn_amount"    // string coin
```

## 9. Transfer Order

```
1. Calculate all amounts (merchantNet, treasuryShare, burnShare)
2. Transfer 1: payer → merchant (SendCoins)
3. Transfer 2: payer → nexarail_treasury (SendCoinsFromAccountToModule)
4. Transfer 3a: payer → nexarail_burner (SendCoinsFromAccountToModule)  ← NEW
5. Transfer 3b: BurnCoins(nexarail_burner, burnShare)                    ← NEW
6. Only after ALL succeed: store settlement
```

Transfer 3a and 3b are a unit — if 3a succeeds but 3b fails, the entire transaction rolls back (SDK atomicity). The burner module account holds the burn share for zero blocks (transferred and immediately burned in the same transaction).

## 10. Burn Share Formula (Unchanged)

```
burnShare = netFee - valShare - treasuryShare
          = netFee - (netFee * 6000/10000) - (netFee * 2000/10000)
          = netFee * 2000/10000 
```

Burn share absorbs rounding dust (remainder method). This means burn is slightly larger than the exact 2000 bps for amounts that don't divide cleanly — the entire fractional unxrl from valShare and treasuryShare calculations ends up in burnShare. This is correct — the dust is burned rather than leaked.

Default: 2000 bps of net fee = 0.2% of protocol fee after rebate.

## 11. Supply Invariant Impact

```
Before Phase 5F.6 (no burn):
  totalSupply = Σ(user_balances) + Σ(module_balances)

After Phase 5F.6 (with burn):
  totalSupply = Σ(user_balances) + Σ(module_balances) + cumulative_burned
  
  For each settlement:
    totalSupply_decrease = burnShare
    cumulative_burned += burnShare
```

The Cosmos SDK bank module maintains `totalSupply` automatically. `BurnCoins` updates it. A supply invariant check in BeginBlock can verify:
```
expected_supply = initial_supply - Σ(settlement_burn_shares where BurnExecuted=true) - other_burns
actual_supply = bankKeeper.GetSupply(ctx, denom)
```

## 12. Risks and Mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| Burner module account not registered | High | Compile-time: `BurnCoins` requires the module account to exist with Burner permission |
| Burn from user account instead of module | High | `BurnCoins` signature takes `moduleName string` — cannot accidentally burn from user |
| Double burn | Medium | SDK atomicity prevents re-execution; BurnExecuted field provides invariant check |
| Over-burn (burn > burnShare) | Medium | Same `burnShare` variable used for record AND burn call; tests verify exact amount |
| Under-burn (burn < burnShare) | Low | Dust goes to burn via remainder approach — burn is slightly larger, not smaller |
| Burner account accumulates coins if BurnCoins fails | Low | Both transfers in same tx — if BurnCoins fails, SendCoinsToModule rolls back |
| Supply tracking drift | Medium | Future: supply invariant check in BeginBlock |
| Governance enables burn without burner module | High | App.go ensures module account exists at genesis; governance cannot remove permissions |

## 13. App Wiring (Phase 5F.6)

```go
// app.go — module account registration
const NexaRailBurnerModuleAccount = "nexarail_burner"

maccPerms = map[string][]string{
    authtypes.FeeCollector:          nil,
    authtypes.Mint:                  {authtypes.Minter},
    staking.BondedPoolName:          {authtypes.Burner, authtypes.Staking},
    staking.NotBondedPoolName:       {authtypes.Burner, authtypes.Staking},
    gov.ModuleName:                  {authtypes.Burner},
    NexaRailEscrowModuleAccount:     nil,
    NexaRailTreasuryModuleAccount:   nil,
    NexaRailFeeRouterModuleAccount:  nil,
    NexaRailBurnerModuleAccount:     {authtypes.Burner},  // NEW
}

// Keeper injection — unchanged (app.BankKeeper already implements BurnCoins)
app.SettlementKeeper = settlementkeeper.NewKeeper(
    app.keys[settlementtypes.StoreKey],
    authority,
    app.MerchantKeeper,
    app.FeesKeeper,
    app.BankKeeper,  // already supports BurnCoins
)
```

## 14. Migration Impact

- **New params field:** `BurnRoutingEnabled` defaults to false — backward compatible
- **New state field:** `BurnExecuted` defaults to false (zero value) — old records are correctly identified
- **New module account:** `nexarail_burner` added to genesis export
- **Existing settlement records:** Unaffected — `BurnExecuted=false` accurately reflects that burn was not executed at creation time

## 15. Verification Gates

- [ ] `nexarail_burner` module account registered in app.go with burner permission
- [ ] Module account blocked from direct user sends
- [ ] `go build ./...` passes with expanded BankKeeper interface
- [ ] `go vet ./...` passes
- [ ] `go test ./...` — all existing tests pass
- [ ] Burn routing works: payer → burner → BurnCoins
- [ ] Burn reduces total supply
- [ ] Failed burn → settlement not stored
- [ ] Supply invariant helper added
- [ ] All 73 existing settlement tests pass
- [ ] No regression in other modules
