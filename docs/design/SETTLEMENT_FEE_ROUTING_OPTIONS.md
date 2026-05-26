# NexaRail Settlement Fee Routing Options

**Phase:** 5F.1 — Design
**Date:** 2026-05-25
**Status:** Analysis complete — recommendation below
**Decision required:** Yes (for Phase 5F.2)

## Context

Settlement fee routing determines how the protocol fee, calculated during `MsgCreateSettlement`, is distributed to:
- **Merchant** (net amount after fee deduction)
- **Treasury** (protocol treasury share, 2000 bps of net fee)
- **Burn** (deflationary burn share, 2000 bps of net fee)
- **Validators** (validator reward share, 6000 bps of net fee)

Three routing strategies are evaluated below.

---

## Option A — Direct Split in MsgCreateSettlement

### Description

The payer's account is debited for multiple outputs in a single message handler:
```
payer → merchant:          (GROSS - netFee)      // merchant net
payer → nexarail_treasury: (treasuryShare)        // protocol treasury
burn via bank.BurnCoins:   (burnShare)            // deflationary
validator share:           metadata only           // deferred
```

### Implementation

```go
// In MsgCreateSettlement, LiveEnabled=true:
payerAddr, _ := sdk.AccAddressFromBech32(msg.Payer)
merchantAddr, _ := sdk.AccAddressFromBech32(settlementAddress)
treasuryAddr := authtypes.NewModuleAddress(types.TreasuryModuleAccount)

// Transfer 1: payer → merchant (merchant net)
merchantNet := grossAmount.Sub(netFee)
k.bankKeeper.SendCoins(ctx, payerAddr, merchantAddr,
    sdk.NewCoins(sdk.NewCoin(denom, merchantNet)))

// Transfer 2: payer → treasury (treasury share)
k.bankKeeper.SendCoins(ctx, payerAddr, treasuryAddr,
    sdk.NewCoins(sdk.NewCoin(denom, treasuryShare)))

// Transfer 3: burn from payer
k.bankKeeper.BurnCoins(ctx, types.ModuleName,
    sdk.NewCoins(sdk.NewCoin(denom, burnShare)))

// State: mark settlement completed, FundsSettled=true
```

### Scoring

| Criterion | Score | Notes |
|---|---|---|
| Security | 7/10 | Three bank calls must all succeed; atomicity guaranteed by SDK. Multi-output increases surface area. |
| Simplicity | 5/10 | Three separate transfers + burn. More code paths. BurnCoins requires fee_collector or module permission. |
| Testability | 7/10 | Each transfer testable independently. Multi-call testing harder. |
| Accounting Clarity | 8/10 | Each share explicitly transferred. On-chain balances reflect actual distribution. |
| Cosmos Distribution Compat | 6/10 | Validator share metadata-only. No integration with x/distribution. |
| Audit Complexity | 5/10 | Three transfer points + burn. Each needs invariant. BurnCoins supply change must be verified. |
| User Experience | 7/10 | Payer sees single transaction with 3 outputs. Clear on explorers. |
| Future Upgrade Path | 8/10 | Each share already routed; enabling validator share just adds one more transfer. |

**Total: 53/80**

---

## Option B — Fee Router Account

### Description

The payer sends the full gross amount to an intermediate `nexarail_fee_router` module account, which then distributes to all parties:
```
payer → nexarail_fee_router:  GROSS (full amount)
nexarail_fee_router → merchant:          merchantNet
nexarail_fee_router → nexarail_treasury: treasuryShare
bank.BurnCoins(fee_router):              burnShare
validator share:                         metadata only
```

### Implementation

```go
// In MsgCreateSettlement, LiveEnabled=true:
feeRouterAddr := authtypes.NewModuleAddress(types.FeeRouterModuleAccount)

// Step 1: Payer sends full gross amount to fee router
k.bankKeeper.SendCoins(ctx, payerAddr, feeRouterAddr,
    sdk.NewCoins(sdk.NewCoin(denom, grossAmount)))

// Step 2: Fee router distributes to merchant
k.bankKeeper.SendCoinsFromModuleToAccount(ctx, types.FeeRouterModuleAccount,
    merchantAddr, sdk.NewCoins(sdk.NewCoin(denom, merchantNet)))

// Step 3: Fee router distributes to treasury
k.bankKeeper.SendCoinsFromModuleToAccount(ctx, types.FeeRouterModuleAccount,
    treasuryAddr, sdk.NewCoins(sdk.NewCoin(denom, treasuryShare)))

// Step 4: Burn from fee router
k.bankKeeper.BurnCoins(ctx, types.FeeRouterModuleAccount,
    sdk.NewCoins(sdk.NewCoin(denom, burnShare)))

// Invariant: fee router balance after distribution must be validatorShare
// (which is deferred/metadata for now)
expectedRemaining := validatorShare
actualBalance := k.bankKeeper.GetBalance(ctx, feeRouterAddr, denom)
if !actualBalance.Amount.Equal(expectedRemaining) {
    return error // distribution math error
}
```

### Scoring

| Criterion | Score | Notes |
|---|---|---|
| Security | 6/10 | Fee router account is a new attack surface. Must be blocked from direct sends. Invariant required to catch stuck funds. |
| Simplicity | 4/10 | Four bank calls + intermediate account + balance invariant check. Most complex option. |
| Testability | 5/10 | Intermediate account state must be verified. Balance assertions needed after each step. |
| Accounting Clarity | 9/10 | Fee router balance = unallocated fees. Clean separation of "collected" vs "distributed". |
| Cosmos Distribution Compat | 7/10 | Validator share sits in fee_router awaiting distribution. Natural integration point for BeginBlock routing. |
| Audit Complexity | 3/10 | Highest audit burden. Fee router balance invariant, stuck-fund risk, blocked address config, four transfer points. |
| User Experience | 6/10 | Payer sends to fee_router (less intuitive). Two-hop transfer visible on-chain. |
| Future Upgrade Path | 9/10 | Best for future: validator distribution naturally pulls from fee_router. Supports BeginBlock fee routing. |

**Total: 49/80**

---

## Option C — Live Merchant Transfer Only (Recommended)

### Description

In live mode, only the merchant net is transferred. All fee shares remain metadata on the settlement record. No treasury transfer, no burn, no fee router.

```
payer → merchant:  (GROSS - netFee)  // merchant net only
treasury share:     metadata only
burn share:         metadata only
validator share:    metadata only
```

### Implementation

```go
// In MsgCreateSettlement, LiveEnabled=true:
payerAddr, _ := sdk.AccAddressFromBech32(msg.Payer)
merchantAddr, _ := sdk.AccAddressFromBech32(settlementAddress)

// Single transfer: payer → merchant (merchant net)
merchantNet := grossAmount.Sub(netFee)
k.bankKeeper.SendCoins(ctx, payerAddr, merchantAddr,
    sdk.NewCoins(sdk.NewCoin(denom, merchantNet)))

// State: mark settlement completed, FundsSettled=true
// Fee shares stored on record as metadata (unchanged from v1)
```

### Scoring

| Criterion | Score | Notes |
|---|---|---|
| Security | 9/10 | Single bank call. Minimal attack surface. No new module account. |
| Simplicity | 10/10 | One transfer. Same fee calc as v1. Minimal code delta. |
| Testability | 10/10 | Trivial: test one transfer succeeds, one fails. No multi-party coordination. |
| Accounting Clarity | 8/10 | Settlement record contains full fee breakdown. On-chain balances reflect merchant payment only. Fee accounting is off-chain-readable. |
| Cosmos Distribution Compat | 5/10 | No integration. Validator share is purely informational. Requires future phase for distribution. |
| Audit Complexity | 9/10 | Lowest audit burden. One transfer point. No burn to verify. No treasury balance to reconcile. |
| User Experience | 9/10 | Payer sees single transfer to merchant. Matches payment UX. Fee breakdown visible in settlement query. |
| Future Upgrade Path | 7/10 | Additional transfers can be added incrementally without changing existing flow. Treasury routing added as second transfer in future phase. |

**Total: 67/80**

---

## Option D — Merchant + Treasury Only (Conservative A-lite)

### Description

A middle ground: transfer merchant net AND treasury share, but defer burn and validator shares.

```
payer → merchant:          merchantNet
payer → nexarail_treasury: treasuryShare
burn share:         metadata only
validator share:    metadata only
```

### Scoring

| Criterion | Score | Notes |
|---|---|---|
| Security | 8/10 | Two bank calls. Still atomic. No burn complexity. |
| Simplicity | 8/10 | Two transfers, clear purpose. No intermediate accounts. |
| Testability | 8/10 | Two transfer tests. Treasury balance verification adds test depth. |
| Accounting Clarity | 8/10 | Treasury balance reflects actual protocol revenue. Burn deferred. |
| Cosmos Distribution Compat | 5/10 | Same as Option C — no validator integration. |
| Audit Complexity | 8/10 | Two transfer points. No burn audit needed. |
| User Experience | 8/10 | Payer sees two outputs. Treasury accumulation visible on-chain. |
| Future Upgrade Path | 8/10 | Burn can be added as third transfer. Treasury routing already live. |

**Total: 61/80**

---

## Comparison Matrix

| Criterion | A (Direct Split) | B (Fee Router) | C (Merchant Only) | D (Merchant + Treasury) |
|---|---|---|---|---|
| Security | 7 | 6 | **9** | 8 |
| Simplicity | 5 | 4 | **10** | 8 |
| Testability | 7 | 5 | **10** | 8 |
| Accounting Clarity | 8 | **9** | 8 | 8 |
| Cosmos Distribution | 6 | 7 | 5 | 5 |
| Audit Complexity | 5 | 3 | **9** | 8 |
| User Experience | 7 | 6 | **9** | 8 |
| Future Upgrade Path | 8 | **9** | 7 | 8 |
| **TOTAL** | **53** | **49** | **67** | **61** |

---

## Recommendation: Option C (Live Merchant Transfer Only)

### Selected for Phase 5F.2

**Why:**
1. **Highest score** (67/80) across all criteria
2. **Matches proven patterns** from x/escrow and x/treasury: single transfer per message, live_enabled gate, FundsXxx boolean
3. **Delivers core value immediately:** merchants get paid on-chain at settlement time
4. **Minimal risk:** one bank call, no burn accounting, no treasury reconciliation, no new module accounts
5. **Easy to audit:** single transfer path, clear invariant (supply conserved)
6. **Forwards-compatible:** treasury routing and burn can be added as additional transfers in the same handler without changing the merchant transfer

### Deferred to Phase 5F.3

- **Treasury share routing** (Option D extension): Add as second bank.Send call once settlement tests are stable. Requires treasury module account to exist (already registered in Phase 5B).
- **Burn share routing:** Add as third action (bank.BurnCoins) once supply invariant tests can prove correct accounting.
- **Validator share routing:** Requires x/distribution integration or fee_router account. Deferred to Phase 5F.4+.

### Deferred to Phase 5F.4+

- **Option B (Fee Router):** Worth revisiting when validator distribution is implemented. The fee router account is the natural integration point for BeginBlock fee routing from the SDK's fee_collector.
- **Full Option A:** Only if direct-split proves simpler than fee router for validator distribution.

### Migration Path (C → D → A)

```
Phase 5F.2: Option C
  payer → merchant (merchant net)

Phase 5F.3: Option D
  payer → merchant (merchant net)
  payer → nexarail_treasury (treasury share)

Phase 5F.4: Option A-lite
  payer → merchant (merchant net)
  payer → nexarail_treasury (treasury share)
  bank.BurnCoins (burn share)

Phase 5F.5: Full Option A with validator distribution
  payer → merchant (merchant net)
  payer → nexarail_treasury (treasury share)
  bank.BurnCoins (burn share)
  payer → distribution module (validator share)
  OR: fee_router → distribution via BeginBlock
```

Each step adds one transfer without changing the previous ones. Tests accumulate. No migration of existing settlement records needed.

---

## Risk of NOT routing treasury/burn now

### What we lose by deferring

- **Treasury balance does not reflect actual protocol revenue.** Treasury module account balance stays at zero until treasury share routing is enabled. Treasury budgets and grants remain nominal until then.
- **Burn does not reduce supply.** NXRL supply is not deflationary until burn routing is enabled. This is acceptable for devnet/testnet; a governance proposal enables it before mainnet.
- **Fee accounting is off-chain.** Anyone querying on-chain balances won't see treasury accumulation. They must query settlement records and sum the `TreasuryShare` field.

### Why this is acceptable

- All fee data is stored on-chain in settlement records — fully auditable
- Treasury module already has its own live spend path (Phase 5D) — it can receive funds from governance-funded genesis allocation, not just from settlement fees
- Burn is cosmetic until mainnet — no economic security depends on it in devnet
- Each deferred feature can be enabled independently via governance (per-param LiveEnabled flags in each module)

---

## Decision

**Phase 5F.2 implements Option C: Live Merchant Transfer Only.**

Implementation follows the pattern established in SETTLEMENT_LIVE_TRANSFER_DESIGN.md:
- `Params.LiveEnabled` (default false)
- `Settlement.FundsSettled` (bool)
- Single `bank.SendCoins(ctx, payer, merchant, merchantNet)` in `CreateSettlement`
- All fee shares remain metadata on the settlement record
- Invariant helper validates FundsSettled consistency
