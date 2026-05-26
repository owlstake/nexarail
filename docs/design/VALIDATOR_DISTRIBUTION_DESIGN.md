# NexaRail Validator Distribution Design

**Phase:** 5F.7 — Design
**Date:** 2026-05-25
**Status:** Design complete — implementation deferred pending distribution review
**Depends on:** Phase 5F.6 (merchant + treasury + burn routing complete)
**Validator share:** 6000 bps of net fee (60% of protocol fee after rebate)

## 1. Current State

### 1.1 Validator Share is Metadata-Only

```go
valShare = netFee * ValidatorShareBps / 10000  // 6000 bps default
```

The `valShare` is calculated during `MsgCreateSettlement` and stored on the `Settlement.ValidatorShare` field as an `sdk.Coin`. It is never transferred, never distributed, and never burned. It is purely informational — an auditable record of what should eventually go to validators.

### 1.2 Current Settlement Flag Matrix

| Flag | Default | Controls |
|---|---|---|
| `LiveEnabled` | false | Merchant-net transfer |
| `TreasuryRoutingEnabled` | false | Treasury-share routing |
| `BurnRoutingEnabled` | false | Burn-share routing |
| *(none)* | N/A | Validator share routing |

### 1.3 Fee Split Proportions

| Share | BPS | % of Net Fee | Routed? |
|---|---|---|---|
| Validator | 6000 | 60% | ❌ Metadata only |
| Treasury | 2000 | 20% | ✅ Behind flag |
| Burn | 2000 | 20% | ✅ Behind flag |

The validator share is the LARGEST component (60%) and the LAST to be routed.

## 2. Why Validator Distribution is Different

### 2.1 Previous Phases: Simple Bank Transfers

| Phase | Mechanism | Complexity |
|---|---|---|
| 5F.2 Merchant | `SendCoins(payer, merchant, coins)` | 1 call, account-to-account |
| 5F.4 Treasury | `SendCoinsFromAccountToModule(payer, "nexarail_treasury", coins)` | 1 call, account-to-module |
| 5F.6 Burn | `SendCoinsFromAccountToModule` + `BurnCoins` | 2 calls, account-to-module + burn |

All three are deterministic, single-destination operations with no per-validator logic.

### 2.2 Validator Distribution: Multi-Party Reward Splitting

Validator distribution requires:
1. **Knowing the active validator set** at the time of distribution
2. **Splitting rewards proportionally** by voting power
3. **Applying commission rates** (validator operator cut vs delegator share)
4. **Integrating with x/distribution accounting** (outstanding rewards, validator accumulators)
5. **Handling changing validator sets** between settlement creation and distribution

This is fundamentally different from sending coins to a single known address. Validator rewards are computed by `x/distribution.AllocateTokens`, which operates on the fee_collector balance in BeginBlock — not at individual message time.

### 2.3 The "When" Problem

- **Merchant:** Immediately on settlement creation. Merchant address is known.
- **Treasury:** Immediately on settlement creation. Treasury address is known.
- **Burn:** Immediately on settlement creation. Burner account exists.
- **Validators:** Cannot be determined at settlement creation time. The validator set changes every block. The correct time to distribute is in BeginBlock, when the active validator set and voting power are finalised for that block.

## 3. Cosmos x/distribution Architecture

### 3.1 Standard Fee Distribution Flow

```
Every BeginBlock:
  fee_collector balance → AllocateTokens()
    → Proposer reward (1-5% of collected fees, configurable)
    → Remaining split to all bonded validators:
      → Commission (validator operator)
      → Delegator shares (proportional to delegation)
```

### 3.2 Key Module Accounts

| Account | Module | Purpose |
|---|---|---|
| `fee_collector` | auth | Collects transaction gas fees. Emptied in BeginBlock by distribution. |
| `distribution` | distribution | Holds undistributed rewards. AllocateTokens moves fees here temporarily. |
| `gov` / community pool | distribution | Receives community tax from block rewards and fees. |

### 3.3 Relevant Keeper Methods

```go
// Moves ALL coins from fee_collector to distribution, then splits to validators
distrKeeper.AllocateTokens(ctx, totalPreviousPower, bondedVotes)

// Directly funds the community pool from any sender
distrKeeper.FundCommunityPool(ctx, amount sdk.Coins, sender sdk.AccAddress)
```

## 4. Routing Options Summary

| Option | Description | Complexity |
|---|---|---|
| A | Keep metadata-only | None |
| B | Send to `fee_collector` → distributed via existing AllocateTokens | Low |
| C | Send to community pool via `FundCommunityPool` | Low |
| D | Accumulate in `nexarail_fee_router` → custom BeginBlock distribution | High |
| E | Custom distribution keeper logic | Very High |

Full comparison in `VALIDATOR_DISTRIBUTION_OPTIONS.md`.

## 5. Key Design Questions

### 5.1 Should validators/delegators or the community pool receive settlement fees?

**Validators/delegators** (Option B): Settlement fees are protocol revenue from payment processing. Like gas fees, they compensate validators for securing the network. Sending them to fee_collector → distribution aligns with the standard Cosmos incentive model.

**Community pool** (Option C): Settlement fees fund public goods, governance-approved spending, or community initiatives. This decouples validator compensation from payment volume.

**Recommendation:** Validators/delegators. Settlement fees are transaction-related revenue. Validators process the settlement transactions. The fee_collector path is the standard pattern. The community pool already receives block rewards and community tax.

### 5.2 Should settlement validator shares go through fee_collector?

**Yes, if Option B is chosen.** The fee_collector → AllocateTokens path is battle-tested in every Cosmos chain. Settlement fees would be indistinguishable from gas fees — they arrive in fee_collector, get swept in the next BeginBlock, and are distributed to validators/delegators.

**Risk:** If fee_collector already receives gas fees, adding settlement fees increases the collector balance. This is fine — AllocateTokens sweeps the entire balance every block. No double-counting.

### 5.3 Should distribution happen in BeginBlock or at settlement time?

**BeginBlock** is correct for Option B. The AllocateTokens function is a BeginBlocker. Settlement validator shares should be sent to fee_collector at settlement creation time, then distributed in the NEXT block's BeginBlock. This is identical to how gas fees flow.

**At settlement time** would require a custom distribution loop — iterating the validator set, computing shares, calling AllocateTokensToValidator individually. This is fragile and duplicates distribution logic.

### 5.4 Governance Controls

| Control | Purpose |
|---|---|
| `ValidatorRoutingEnabled` flag | Separate flag to enable validator routing (default false) |
| `x/fees.ValidatorShareBps` | Proportion of net fee allocated to validators (6000 bps default) |
| `x/distribution.CommunityTax` | Existing param: fraction of fees sent to community pool (0% by default in many chains) |

A `ValidatorRoutingEnabled` flag follows the established pattern. Even with the flag, validator routing should NOT be enabled without a distribution module specialist review.

## 6. Token Flow for Recommended Option B

```
MsgCreateSettlement (all flags enabled):
  payer → merchant:             merchantNet
  payer → nexarail_treasury:    treasuryShare
  payer → nexarail_burner:      burnShare → BurnCoins
  payer → fee_collector:        validatorShare      ← NEW

Next BeginBlock:
  AllocateTokens()
    fee_collector balance (gas fees + settlement validator shares)
    → Proposer reward (1-5%)
    → Remaining → all bonded validators
      → Commission (validator operator)
      → Delegator shares (proportional to delegation)
```

## 7. Migration Path

### Phase 5F.8 (if approved): Validator Routing Implementation

1. Add `ValidatorRoutingEnabled` flag to settlement params (default false)
2. Expand BankKeeper interface with `SendCoinsFromAccountToModule` (already exists)
3. Send validator share to `fee_collector` when `ValidatorRoutingEnabled=true`
4. No changes to x/distribution or BeginBlock — existing AllocateTokens handles the rest
5. ~20 new tests
6. Supply invariant: validator share is supply-conserving (payer → fee_collector → validators)

### Phase 5F.9+: Fee Router for BeginBlock (future enhancement)

If custom distribution logic is needed (e.g., different commission rules for settlement fees vs gas fees), a BeginBlock handler in x/fees could intercept settlement fees in fee_collector and route them differently. This is Phase 5F.9+ scope.

## 8. Risks and Mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| Double-counting gas fees and settlement fees | Low | AllocateTokens sweeps entire fee_collector balance — no per-source tracking needed |
| Validator share stuck in fee_collector | Low | AllocateTokens runs every BeginBlock guaranteed by SDK |
| Community tax reduces validator share | Low | Configurable via x/distribution CommunityTax param; governance controls |
| Changing validator set between settlement and distribution | None | This is normal Cosmos behaviour — distribution uses the validator set at BeginBlock time |
| Settlement fees inflate proposer reward | Very Low | Proposer reward is a percentage of fee_collector balance — larger balance, slightly larger proposer reward. Economically trivial. |
| Governance enables validator routing without review | High | Document that a distribution specialist must review before enabling |
| Incompatibility with slashing | None | Validator rewards post-distribution; slashing applies to staked tokens, not pending rewards |

## 9. Supply Invariant

```
// Settlement validator routing is supply-conserving:
// payer_balance -= validatorShare
// fee_collector_balance += validatorShare
// → total supply unchanged (coins move, not minted or burned)

// After BeginBlock AllocateTokens:
// fee_collector_balance → 0
// validator/delegator balances += validatorShare (minus community tax if any)
// → total supply unchanged
```

## 10. Why Fee Router is Still Deferred

The `nexarail_fee_router` module account exists but is unused. In the current design:
- Settlement fees are routed directly: payer → merchant, payer → treasury, payer → burner
- Validator shares would go payer → fee_collector (not fee_router)

The fee_router was originally conceived as an intermediate account for BeginBlock fee routing from fee_collector. It is not needed for in-message settlement transfers and is deferred to Phase 5F.9+.

## 11. Verification Gates (Phase 5F.8)

- [ ] `ValidatorRoutingEnabled` defaults to false
- [ ] Validator routing only active when all four flags are enabled
- [ ] Validator share sent to fee_collector
- [ ] fee_collector balance increases by validatorShare
- [ ] Supply invariant: validator routing is supply-conserving
- [ ] No double-counting with gas fees
- [ ] No regression in existing settlement tests
- [ ] External distribution module specialist review completed

## 12. Recommendation

**Defer validator distribution implementation.** Keep validator share metadata-only until:

1. A Cosmos SDK distribution module specialist reviews this design
2. The economic implications of sending 60% of net fees to validators are assessed
3. The interaction with staking rewards and community tax is modelled
4. The BeginBlock AllocateTokens integration is verified against testnet behaviour

**If implementation is required before specialist review:** Use Option B (send to fee_collector) behind a `ValidatorRoutingEnabled` flag. This is the simplest, safest integration with Cosmos distribution — one additional bank call, no custom distribution logic, leveraging the existing AllocateTokens path.

**Do not implement custom distribution logic (Options D/E).** The complexity of replicating or modifying x/distribution's reward allocation is not justified for settlement fee routing. The standard fee_collector path is sufficient.
