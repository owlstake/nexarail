# NexaRail Settlement Live Transfer Design

**Phase:** 5F.1 — Design
**Date:** 2026-05-25
**Status:** Design complete — awaiting implementation gate (Phase 5F.2)
**Depends on:** Phases 5A–5D.1 complete; x/escrow live custody; x/treasury live spend

## 1. Current State (Metadata-Only v1)

### 1.1 Settlement Flow

```
Payer invokes MsgCreateSettlement
  → Validate payer address
  → Verify merchant exists and is active (x/merchant)
  → Read fee rate params (x/settlement)
  → Read fee split params (x/fees)
  → Calculate fees in-memory (no coin movement)
  → Store Settlement record with status = Completed
  → Emit event
```

### 1.2 Existing Settlement Struct

```go
type Settlement struct {
    Id                uint64   // auto-increment
    Payer             string   // bech32
    MerchantOwner     string   // bech32
    MerchantId        string   // merchant name
    SettlementAddress string   // destination for funds (currently = merchant.Owner)
    Amount            sdk.Coin // gross settlement amount
    FeeAmount         sdk.Coin // net fee (baseFee - rebate)
    ValidatorShare    sdk.Coin // 60% of net fee (metadata)
    TreasuryShare     sdk.Coin // 20% of net fee (metadata)
    BurnShare         sdk.Coin // 20% of net fee (metadata)
    RebateAppliedBps  uint32   // tier rebate in bps
    RebateAmount      sdk.Coin // rebate discount amount
    Status            int32    // Pending(0), Completed(1), Failed(2), Refunded(3), Cancelled(4)
    PaymentReference  string
    Memo              string
    Metadata          string
    CreatedAt         int64
    UpdatedAt         int64
}
```

### 1.3 Current Status Model

| Status | Value | Terminal | Meaning |
|---|---|---|---|
| Pending | 0 | No | Created, not yet completed |
| Completed | 1 | **No** | Settlement recorded, funds NOT moved |
| Failed | 2 | Yes | Terminal failure |
| Refunded | 3 | Yes | Refunded back to payer |
| Cancelled | 4 | Yes | Cancelled by authority |

**Critical note:** Completed is NOT terminal in the current model. This allows Completed → Refunded transitions for dispute resolution. This has implications for live transfers — if funds have already moved to the merchant, a refund must move them back.

### 1.4 Fee Calculation (Current, from keeper.go)

```
amount        = msg.Amount.Amount (sdk.Int)
feeRateBps    = params.FeeRateBps (default 100 = 1%)
bpsFactor     = 10,000

baseFee       = amount * feeRateBps / 10000
rebateBps     = params.GetRebateBps(merchant.RebateTier)  // 0-2000
rebateAmount  = baseFee * rebateBps / 10000
netFee        = baseFee - rebateAmount

// From x/fees params: 6000/2000/2000 bps
valBps        = feesParams.ValidatorShareBps  // 6000
treasuryBps   = feesParams.TreasuryShareBps   // 2000

valShare      = netFee * valBps / 10000
treasuryShare = netFee * treasuryBps / 10000
burnShare     = netFee - valShare - treasuryShare  // remainder → burn

merchantNet   = amount - netFee
```

**Rounding model (current):** Integer division truncates (floor). Burn share absorbs remainder to ensure exact split: `burnShare = netFee - valShare - treasuryShare`.

## 2. Target Live Behaviour

### 2.1 Desired Live Flow

```
Payer invokes MsgCreateSettlement
  → Same validation as v1
  → Calculate fees identically to v1
  → IF LiveEnabled:
      1. Transfer merchant_net from payer → merchant/SettlementAddress
      2. Optionally transfer treasury_share from payer → nexarail_treasury
      3. Optionally burn burn_share via bank.BurnCoins
      4. Set FundsSettled = true
      5. Store Settlement with status = Completed
  → IF NOT LiveEnabled:
      Metadata-only path (unchanged from v1)
```

### 2.2 Phase 5F Scope

**In scope for Phase 5F.2:**
- `LiveEnabled` param (default false) on settlement params
- `FundsSettled` boolean field on Settlement struct
- BankKeeper interface injection
- Live merchant transfer: payer → merchant/SettlementAddress (amount - netFee = merchant net)
- All existing metadata paths preserved

**Deferred to later phases (NOT in 5F.2):**
- Treasury share routing (5F.3)
- Burn share routing via bank.BurnCoins (5F.3)
- Validator share routing to distribution module (5F.4 or later)
- Fee router intermediate account (5F.3 if needed)
- BeginBlock fee routing handler (Phase 5F.4+)
- Multi-denom settlement
- Auto-refund on merchant dispute

### 2.3 Conservative Transfer Model (Recommended)

**Single transfer only in Phase 5F.2:**

```
// LiveEnabled = true:
payer → merchant (SettlementAddress): merchantNet = gross_amount - netFee

// Everything else stays metadata:
//   treasury_share, burn_share, validator_share → stored on Settlement record only
```

**Rationale:**
1. Single bank.Send call — simplest atomicity guarantee
2. No multi-party transfer coordination
3. No burn accounting to prove
4. No treasury balance tracking needed (existing treasury module has its own live path)
5. Merchant gets paid immediately — core value proposition
6. Fee accounting is still recorded for future routing
7. Matches escrow pattern: one primary transfer per message

**Optional extension (Phase 5F.3 only if tests pass):**
Add a second transfer for treasury share:
```
payer → nexarail_treasury: treasuryShare
```
This requires two bank.Send calls in sequence — both must succeed for the settlement to complete.

## 3. Implementation Plan (Phase 5F.2)

### 3.1 Params Changes

```go
// Add to types/params.go
type Params struct {
    Enabled     bool     // existing
    LiveEnabled bool     // NEW — default false
    FeeRateBps  uint32   // existing
    RebateTiers []uint32 // existing
}

func DefaultParams() Params {
    return Params{
        Enabled:     true,
        LiveEnabled: false,  // NEW — off by default
        FeeRateBps:  DefaultFeeRateBps,
        RebateTiers: tiers,
    }
}
```

`LiveEnabled` added as a first-class param field (not piggybacking on `Enabled`). This allows independent governance control: settlements can be enabled for metadata recording while live transfers remain off.

### 3.2 Settlement Struct Changes

```go
// Add field to types/settlement.go
type Settlement struct {
    // ... all existing fields ...
    FundsSettled bool `json:"funds_settled" yaml:"funds_settled"` // NEW
}
```

`NewSettlement()` sets `FundsSettled: false` by default.

### 3.3 Module Account

Settlement does NOT need its own module account. All transfers are direct:
- payer → merchant
- payer → nexarail_treasury (deferred)
- payer → burn (deferred)

No `nexarail_settlement` account required.

### 3.4 Expected Keepers

```go
// Add to types/expected_keepers.go
import banktypes "github.com/cosmos/cosmos-sdk/x/bank/types"

type BankKeeper interface {
    SendCoins(ctx sdk.Context, fromAddr sdk.AccAddress, toAddr sdk.AccAddress, amt sdk.Coins) error
}
```

Settlement only needs `SendCoins` (direct account-to-account), not module account methods. The payer is always a user account, and the merchant destination is always a user account.

### 3.5 Keeper Changes

```go
type Keeper struct {
    storeKey       storetypes.StoreKey
    authority      string
    merchantKeeper types.MerchantKeeper
    feesKeeper     types.FeesKeeper
    bankKeeper     types.BankKeeper  // NEW
}

func NewKeeper(
    storeKey storetypes.StoreKey,
    authority string,
    merchantKeeper types.MerchantKeeper,
    feesKeeper types.FeesKeeper,
    bankKeeper types.BankKeeper,  // NEW
) Keeper { ... }
```

### 3.6 CreateSettlement Live Path

```go
func (k Keeper) CreateSettlement(ctx sdk.Context, msg *types.MsgCreateSettlement) (*types.Settlement, error) {
    params := k.GetParams(ctx)

    // Existing validation path (unchanged)
    if !params.Enabled { ... }
    // payer validation
    // amount validation
    // merchant lookup + active check
    // fee calculation (identical to v1)

    // Generate ID
    id := k.getNextSettlementID(ctx)

    // Build settlement record (with all fee fields)
    settlement := types.NewSettlement(...)
    // merchant_net = amount - netFee

    // ---- LIVE TRANSFER (new) ----
    if params.LiveEnabled {
        payerAddr, _ := sdk.AccAddressFromBech32(msg.Payer)
        merchantAddr, _ := sdk.AccAddressFromBech32(settlementAddress)
        merchantNet := amount.Sub(netFee)  // gross - protocol fee

        // Transfer merchant net from payer to merchant
        // This happens BEFORE state mutation
        if err := k.bankKeeper.SendCoins(ctx, payerAddr, merchantAddr,
            sdk.NewCoins(sdk.NewCoin(denom, merchantNet))); err != nil {
            return nil, fmt.Errorf("live settlement transfer failed: %w", err)
        }

        settlement.FundsSettled = true
    }

    // State mutation (same as v1 — happens after transfer)
    settlement.Status = int32(types.SettlementCompleted)
    settlement.UpdatedAt = now

    if err := k.SetSettlement(ctx, settlement); err != nil {
        return nil, err
    }

    // Emit event (enhanced with FundsSettled attribute)
    ...
}
```

### 3.7 Transfer Order (Critical)

```
1. Validate all inputs (payer, merchant, amount, params)
2. Calculate fees (pure function, no state changes)
3. IF LiveEnabled:
   a. Transfer merchant_net: payer → merchant (bank keeper)
   b. If transfer fails → return error (rolls back entire tx)
   c. Set FundsSettled = true (in-memory, not yet stored)
4. Set Status = Completed
5. Store settlement record (KV write)
6. Emit event
```

**Principle:** All bank transfers happen BEFORE any KV state mutations. Cosmos SDK guarantees atomicity — if step 3a fails, steps 4-6 never execute.

### 3.8 Refund Handling (Future Concern)

The current model allows Completed → Refunded transitions (Completed is NOT terminal). For live settlements where funds have moved to the merchant:

**Phase 5F.2 answer:** Refunds remain manual/off-chain. The `UpdateSettlementStatus` authority function can mark a settlement as Refunded (recording the fact) but does NOT reverse the on-chain transfer. This matches the current design where Completed → Refunded is a metadata transition.

**Future (Phase 5F.4+):** A `MsgRefundSettlement` could:
1. Transfer from merchant/SettlementAddress back to payer
2. Set FundsSettled = false
3. Set Status = Refunded

This is out of scope for Phase 5F.

## 4. Fee Calculation Model (Unchanged from v1)

### 4.1 Formula Reference

```
GROSS     = msg.Amount
FEE_RATE  = params.FeeRateBps (bps, default 100 = 1%)
REBATE    = params.GetRebateBps(merchant.RebateTier) (bps, 0-2000)

baseFee      = GROSS * FEE_RATE / 10000
rebateAmount = baseFee * REBATE / 10000
netFee       = baseFee - rebateAmount

// From x/fees:
valShare      = netFee * ValidatorShareBps / 10000   // 6000 bps default
treasuryShare = netFee * TreasuryShareBps / 10000    // 2000 bps default
burnShare     = netFee - valShare - treasuryShare    // remainder

merchantNet   = GROSS - netFee
```

### 4.2 Rounding Model

- All divisions are integer floor (Go `/` with `sdk.Int`)
- `burnShare` absorbs remainder: `netFee - valShare - treasuryShare`
- This guarantees `valShare + treasuryShare + burnShare == netFee`
- `merchantNet = GROSS - netFee` — exact, no rounding loss
- Maximum rounding error per settlement: < 3 unxrl (from three integer divisions)
- At 1 unxrl = 0.000001 NXRL, maximum loss per settlement < 0.000003 NXRL

### 4.3 Invariant

```
// For any settlement with FundsSettled = true:
//   merchantNet + netFee == GROSS
//   valShare + treasuryShare + burnShare == netFee
//
// Supply conservation (Phase 5F.2, single-transfer mode):
//   payer_balance_before - payer_balance_after == merchantNet
//   merchant_balance_after - merchant_balance_before == merchantNet
//   => payer delta + merchant delta == 0 (supply conserved)
```

## 5. State Mutation Order

### 5.1 Happy Path

```
START
  1. Read params (KV read)
  2. Read merchant (via x/merchant keeper)
  3. Read fee params (via x/fees keeper)
  4. Calculate fees (in-memory)
  5. LiveEnabled?
     YES → bank.SendCoins(payer, merchant, merchantNet)
            if err: ABORT, return error
  6. Set settlement.FundsSettled = true/false (in-memory)
  7. Set settlement.Status = Completed (in-memory)
  8. KV write: SetSettlement(ctx, settlement)  ← FIRST state mutation
  9. Emit event
END
```

### 5.2 Failure Paths

| Failure Point | Behaviour |
|---|---|
| Invalid payer | Return error, no state changes |
| Merchant not found/inactive | Return error, no state changes |
| Amount invalid | Return error, no state changes |
| Bank transfer fails (insufficient balance) | Return error, no state changes (tx atomic) |
| KV write fails | Return error, bank transfer reverts (tx atomic) |

## 6. Invariants

### 6.1 Supply Invariant

For Phase 5F.2 (single-transfer, no treasury/burn routing):
```
Σ(user_balances) = constant  // no supply change
// payer balance decreases by merchantNet
// merchant balance increases by merchantNet
// net: 0
```

For future phases with burn:
```
Σ(user_balances) + Σ(module_balances) + burned_amount = initial_supply
```

### 6.2 Settlement Invariant Helpers

```go
// ActiveSettledTotals returns the sum of merchant_net across all live-settled records.
func (k Keeper) ActiveSettledTotals(ctx sdk.Context) sdk.Coins {
    totals := sdk.Coins{}
    for _, s := range k.GetAllSettlements(ctx) {
        if s.FundsSettled && s.Status == int32(types.SettlementCompleted) {
            merchantNet := s.Amount.Sub(s.FeeAmount)
            totals = totals.Add(sdk.NewCoin(s.Amount.Denom, merchantNet))
        }
    }
    return totals
}

// ValidateSettlementInvariant checks consistency of FundsSettled vs Status.
func (k Keeper) ValidateSettlementInvariant(ctx sdk.Context) error {
    for _, s := range k.GetAllSettlements(ctx) {
        // A settlement with FundsSettled=true must be Completed
        // (Refunded/Cancelled/Failed should have had funds reversed)
        if s.FundsSettled && s.Status != int32(types.SettlementCompleted) {
            return fmt.Errorf(
                "invariant violation: settlement %d has FundsSettled=true but status=%s",
                s.Id, types.SettlementStatus(s.Status),
            )
        }
        // Terminal settlements should not have FundsSettled=true
        // unless we implement automated refund transfers (future)
        if s.IsTerminal() && s.FundsSettled {
            // Flagged but not rejected in Phase 5F.2 — refund is manual
        }
    }
    return nil
}
```

## 7. Replay / Double-Completion Prevention

### 7.1 Settlements are Immutable on Creation

- `CreateSettlement` generates a new ID each call (auto-increment counter)
- No update-an-existing-settlement path in CreateSettlement
- Each call creates a NEW settlement record — duplicate prevention is by ID uniqueness, not by dedup
- The same payer/merchant/amount can create multiple settlements (legitimate: repeat payments)

### 7.2 Status Guard on Completion

- CreateSettlement always sets status = Completed (both metadata and live paths)
- No "complete an existing pending settlement" message exists in v1/v2
- Settlement status can only be changed via `UpdateSettlementStatus` (authority-only)
- Completed → Refunded is the only allowed post-completion transition (authority-gated)

### 7.3 Transaction Replay

- Cosmos SDK account sequences prevent replay by default
- Sequence numbers increment on each transaction
- No custom nonce or idempotency key needed

## 8. Terminal Status Rules

| Status | Terminal | Can Transition To |
|---|---|---|
| Pending (0) | No | Completed, Failed, Cancelled |
| Completed (1) | **No** | Refunded, Failed |
| Failed (2) | Yes | (none) |
| Refunded (3) | Yes | (none) |
| Cancelled (4) | Yes | (none) |

**Live transfer impact:** Completed is NOT terminal, meaning a live-settled record could later be marked Refunded. In Phase 5F.2, this is a metadata-only status change — funds remain with the merchant. A future phase would add automated refund transfers.

`FundsSettled` should be set to `false` if/when an automated refund transfer occurs. Until then, `FundsSettled=true` + `Status=Refunded` indicates that the on-chain refund has not been executed (flagged by invariant helper, not rejected).

## 9. Audit Risks

| Risk | Severity | Phase 5F.2 Mitigation |
|---|---|---|
| Merchant address is not the actual merchant | Low | SettlementAddress defaults to merchant.Owner; validated via x/merchant |
| Payer balance insufficient | Medium | Bank transfer fails before state mutation; tx atomic |
| Completed → Refunded without fund reversal | Low | Phase 5F.2: refunds are metadata-only; invariant helper flags discrepancy |
| Fee params changed mid-block | Low | All reads happen within same transaction; consistent snapshot |
| Integer overflow in fee calculation | Low | sdk.Int is arbitrary-precision; no overflow |
| Denom mismatch between amount and merchant denom | Low | Settlement denom is msg.Amount.Denom; no cross-denom logic yet |
| Double spend via sequence replay | Low | Cosmos SDK sequence numbers |
| Governance enables LiveEnabled without treasury balance | N/A | Phase 5F.2: treasury is NOT involved in settlement transfers |
| Governance enables LiveEnabled without burn accounting | N/A | Phase 5F.2: burn is NOT executed |
| Migration from metadata-only records | Low | No state migration needed; FundsSettled defaults to false for old records |

## 10. App Wiring (Phase 5F.2)

```go
// app/app.go
app.SettlementKeeper = settlementkeeper.NewKeeper(
    keys[settlementtypes.StoreKey],
    authtypes.NewModuleAddress(govtypes.ModuleName).String(),
    app.MerchantKeeper,
    app.FeesKeeper,
    app.BankKeeper,  // NEW
)
```

## 11. Verification Gates (Phase 5F.2)

After implementation, before marking complete:

- [ ] `go build ./...` passes
- [ ] `go vet ./...` passes
- [ ] `go test ./...` passes with all new live settlement tests
- [ ] Metadata-only path unchanged — all existing settlement tests pass
- [ ] LiveEnabled=false → no bank keeper calls
- [ ] LiveEnabled=true → single SendCoins from payer to merchant
- [ ] Insufficient payer balance → error, no state mutation
- [ ] FundsSettled field correctly set on live settlements
- [ ] Invariant helpers produce correct totals
- [ ] No regression in escrow, treasury, payout, fees, merchant tests
