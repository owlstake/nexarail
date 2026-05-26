# NexaRail Validator Distribution Options

**Phase:** 5F.7 — Design
**Date:** 2026-05-25
**Status:** Analysis complete — recommendation below

## Context

The validator share (6000 bps of net settlement fee = 60%) is the largest fee component and the last to be routed. Unlike merchant, treasury, and burn routing (simple bank transfers), validator distribution must integrate with Cosmos SDK's `x/distribution` module, which handles per-validator reward splitting, commission rates, delegator shares, and BeginBlock allocation.

---

## Option A — Keep Validator Share Metadata-Only (Defer)

### Description

No code changes. Validator share remains a metadata field on the settlement record. Governance and validators can audit the accumulated validator share off-chain.

### Implementation

None. Status quo.

### When to revisit

After mainnet launch, when on-chain validator economics are well-understood and a distribution specialist has reviewed the integration.

### Scoring

| Criterion | Score | Notes |
|---|---|---|
| Security | 10/10 | No new attack surface |
| Simplicity | 10/10 | No code changes |
| Correctness with SDK | 10/10 | No distribution integration to get wrong |
| Validator incentive alignment | 2/10 | Validators receive zero on-chain revenue from settlements |
| Testability | 10/10 | Nothing to test |
| Audit complexity | 10/10 | Nothing to audit |
| Economic clarity | 6/10 | Validator share is documented but not enforced — depends on future governance |
| Distribution compatibility | 10/10 | No conflict |
| Governance risk | 9/10 | Low risk; governance cannot accidentally enable a buggy distribution path |
| Future upgrade path | 8/10 | Any option can be implemented later without migration |

**Total: 85/100**

---

## Option B — Send to fee_collector (Recommended If Implementation Required)

### Description

Settlement validator shares are sent from payer to the standard Cosmos `fee_collector` module account. The existing `x/distribution.AllocateTokens` (called in BeginBlock) sweeps the fee_collector balance and distributes to validators/delegators based on voting power and commission rates.

### Implementation

```go
// In CreateSettlement, when ValidatorRoutingEnabled=true:
k.bankKeeper.SendCoinsFromAccountToModule(ctx, payerAddr,
    authtypes.FeeCollectorName,
    sdk.NewCoins(sdk.NewCoin(denom, validatorShare)))
```

No changes to x/distribution or BeginBlock. No custom distribution logic.

### Token Flow

```
Settlement time:
  payer → fee_collector: validatorShare

Next BeginBlock:
  AllocateTokens() sweeps fee_collector
    → Proposer reward (1-5% of total)
    → Remaining → validators/delegators (voting power + commission)
```

### Scoring

| Criterion | Score | Notes |
|---|---|---|
| Security | 8/10 | Standard Cosmos path. fee_collector is tried-and-tested. One new bank call. |
| Simplicity | 9/10 | One additional SendCoinsFromAccountToModule call. No distribution changes. |
| Correctness with SDK | 9/10 | Uses the exact same flow as gas fees. AllocateTokens handles everything. |
| Validator incentive alignment | 9/10 | Validators receive settlement revenue proportional to voting power, same as gas fees |
| Testability | 8/10 | Can test fee_collector balance increase. Full distribution test requires multi-validator setup. |
| Audit complexity | 7/10 | Must verify fee_collector balance doesn't disrupt normal gas fee distribution. Low risk. |
| Economic clarity | 9/10 | Validators compensated for processing settlement transactions. Matches gas fee model. |
| Distribution compatibility | 10/10 | No changes to x/distribution. Uses existing AllocateTokens path. |
| Governance risk | 7/10 | Separate flag required. Governance must understand distribution mechanics. |
| Future upgrade path | 9/10 | Can add custom BeginBlock routing later if needed. fee_collector is the standard entry point. |

**Total: 85/100**

---

## Option C — Send to Community Pool via FundCommunityPool

### Description

Settlement validator shares are sent directly to the Cosmos distribution community pool via `distrKeeper.FundCommunityPool`. Funds are controlled by governance, not distributed to individual validators.

### Implementation

```go
// In CreateSettlement, when ValidatorRoutingEnabled=true:
k.distrKeeper.FundCommunityPool(ctx,
    sdk.NewCoins(sdk.NewCoin(denom, validatorShare)),
    payerAddr)
```

Requires `DistrKeeper` injection into settlement keeper (new dependency).

### Scoring

| Criterion | Score | Notes |
|---|---|---|
| Security | 8/10 | Direct community pool funding. Well-tested SDK method. |
| Simplicity | 7/10 | Requires DistrKeeper injection. One call, but new keeper dependency. |
| Correctness with SDK | 9/10 | FundCommunityPool is a standard SDK method. |
| Validator incentive alignment | 3/10 | Validators receive nothing directly. Funds go to governance-controlled pool. |
| Testability | 8/10 | Testable via mock DistrKeeper. |
| Audit complexity | 7/10 | Community pool accounting must be verified. |
| Economic clarity | 5/10 | "Validator share" going to community pool is a naming mismatch. Confusing. |
| Distribution compatibility | 9/10 | FundCommunityPool is a standard method. |
| Governance risk | 6/10 | Community pool spending requires governance proposals. Slow. |
| Future upgrade path | 7/10 | Can switch to fee_collector later. No migration of existing funds needed. |

**Total: 69/100**

---

## Option D — Accumulate in nexarail_fee_router + Custom BeginBlock Distribution

### Description

Settlement validator shares are sent to `nexarail_fee_router`. A custom BeginBlock handler distributes from fee_router to validators/delegators.

### Implementation

```go
// In CreateSettlement:
k.bankKeeper.SendCoinsFromAccountToModule(ctx, payerAddr,
    "nexarail_fee_router",
    sdk.NewCoins(sdk.NewCoin(denom, validatorShare)))

// In BeginBlock (x/fees or x/settlement):
// Read fee_router balance, iterate validator set, call AllocateTokensToValidator
// for each validator with proportional share of fee_router balance
```

### Scoring

| Criterion | Score | Notes |
|---|---|---|
| Security | 5/10 | Custom distribution logic. Risk of incorrect validator accounting. |
| Simplicity | 3/10 | New BeginBlock handler. Custom validator iteration. |
| Correctness with SDK | 4/10 | Bypasses AllocateTokens. Must manually compute validator shares. |
| Validator incentive alignment | 8/10 | Can be customised (e.g., different commission for settlement fees). |
| Testability | 5/10 | Requires multi-validator test setup. BeginBlock testing is complex. |
| Audit complexity | 3/10 | Highest audit burden. Custom distribution logic must be independently verified. |
| Economic clarity | 7/10 | Separation of gas fees and settlement fees is conceptually clean. |
| Distribution compatibility | 4/10 | Duplicates distribution logic. Risk of drift from SDK updates. |
| Governance risk | 4/10 | Custom logic increases bug surface. |
| Future upgrade path | 6/10 | Useful if settlement fees need different distribution rules. |

**Total: 49/100**

---

## Option E — Custom Distribution Keeper Logic

### Description

Fully custom distribution logic in a new or extended module. Settlement fees are distributed according to custom rules (e.g., different commission structure, staking-weighted but custom).

### Scoring

| Criterion | Score | Notes |
|---|---|---|
| Security | 3/10 | Fully custom. Highest risk of bugs. |
| Simplicity | 1/10 | Most complex. Requires deep x/distribution knowledge. |
| Correctness with SDK | 2/10 | Outside SDK patterns. High maintenance burden. |
| Validator incentive alignment | 9/10 | Maximum flexibility — can implement any incentive scheme. |
| Testability | 3/10 | Requires extensive simulation. |
| Audit complexity | 1/10 | Extremely high. Custom distribution is a full security review. |
| Economic clarity | 8/10 | Can be precisely tailored. |
| Distribution compatibility | 2/10 | Bypasses SDK distribution entirely. |
| Governance risk | 2/10 | Custom logic = maximum bug surface. |
| Future upgrade path | 5/10 | Locked into custom implementation. SDK upgrades may break. |

**Total: 36/100**

---

## Comparison Matrix

| Criterion | A (Defer) | B (fee_collector) | C (Community Pool) | D (Fee Router) | E (Custom) |
|---|---|---|---|---|---|
| Security | **10** | 8 | 8 | 5 | 3 |
| Simplicity | **10** | 9 | 7 | 3 | 1 |
| SDK Correctness | **10** | 9 | 9 | 4 | 2 |
| Validator Incentives | 2 | 9 | 3 | **8** | **9** |
| Testability | **10** | 8 | 8 | 5 | 3 |
| Audit Complexity | **10** | 7 | 7 | 3 | 1 |
| Economic Clarity | 6 | **9** | 5 | 7 | **8** |
| Distribution Compat | **10** | **10** | 9 | 4 | 2 |
| Governance Risk | **9** | 7 | 6 | 4 | 2 |
| Upgrade Path | 8 | **9** | 7 | 6 | 5 |
| **TOTAL** | **85** | **85** | **69** | **49** | **36** |

## Recommendation: Option A (Defer), Option B as Fallback

### Primary: Option A — Keep Validator Share Metadata-Only

**Score: 85/100 (tie with Option B, preferred on audit safety)**

Validator share should remain metadata-only until:
1. A Cosmos SDK distribution module specialist reviews the integration design
2. The economic model of 60% net fee → validators vs staking inflation is assessed
3. Testnet behaviour of AllocateTokens with mixed gas + settlement fees is verified
4. The validator incentive impact is modelled against existing staking rewards

The validator share is already stored on every settlement record — fully auditable. Governance and validators can see exactly how much they would have received. This is sufficient for devnet/testnet.

### Fallback: Option B — Send to fee_collector

**If implementation is required before specialist review**, Option B is the safest path:
- One additional bank call (`SendCoinsFromAccountToModule` to `fee_collector`)
- Behind a separate `ValidatorRoutingEnabled` flag (default false)
- No changes to x/distribution or BeginBlock
- `AllocateTokens` handles everything — same as gas fees
- Supply-conserving (coins move, not minted)

### Rejected

- **Option C (Community Pool):** Calling the largest fee share "validator" share but routing it to the community pool is misleading. Rename the share or route it to validators.
- **Option D (Fee Router):** Custom BeginBlock distribution duplicates x/distribution logic. High audit burden. Reserve for when settlement fees need different distribution rules than gas fees.
- **Option E (Custom):** Not justified. Cosmos SDK distribution is well-tested and sufficient.

## Decision

**Do not implement validator distribution in Phase 5F. Keep validator share metadata-only.**

**If validator distribution must be implemented (post-review):** Implement Option B with `ValidatorRoutingEnabled` flag, sending to `fee_collector`. No custom distribution logic.
