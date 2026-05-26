# NexaRail Validator Distribution Threat Model

**Phase:** 5F.7 — Security Design
**Date:** 2026-05-25
**Status:** Threat model complete — implementation DEFERRED
**Recommended option:** A (defer) / B (fee_collector) if required

## Threat Surface (Option B — fee_collector)

```
MsgCreateSettlement (all four flags enabled):
  payer → merchant:          merchantNet
  payer → nexarail_treasury: treasuryShare
  payer → nexarail_burner:   burnShare → BurnCoins
  payer → fee_collector:     validatorShare     ← NEW

Next BeginBlock:
  AllocateTokens() sweeps fee_collector
    → Proposer reward
    → Commission → validator operator
    → Delegator shares → delegators
```

---

## 1. Double Payment to Validators

**Threat ID:** VAL-001
**Severity:** High
**Likelihood:** Very Low (mitigated by AllocateTokens design)
**Impact:** Validators receive settlement fees twice

**Description:**
Settlement fees are sent to fee_collector, then AllocateTokens distributes them. If settlement fees are somehow also distributed through another path, validators could be paid twice.

**Mitigation:**
- `AllocateTokens` sweeps the ENTIRE fee_collector balance each BeginBlock — leaves zero
- Settlement fees arrive in fee_collector exactly once (at settlement creation)
- No secondary distribution path for settlement validator shares
- Validator share is NOT also sent to treasury, burner, or merchant

**Residual Risk:** If a future module also sends to fee_collector for the same settlement, double-payment could occur. Mitigated by code review of any module that touches fee_collector.

---

## 2. Bypassing Distribution Module Accounting

**Threat ID:** VAL-002
**Severity:** High
**Likelihood:** Low
**Impact:** Validator rewards not tracked correctly by x/distribution

**Description:**
If settlement fees are sent directly to validators (bypassing fee_collector/AllocateTokens), the distribution module's reward accounting (outstanding rewards, validator accumulators) is bypassed. Validators could withdraw rewards that the distribution module doesn't know about.

**Mitigation (Option B):**
- Settlement fees go through fee_collector → AllocateTokens, NOT directly to validators
- AllocateTokens updates distribution module accounting (validator accumulators, outstanding rewards)
- No custom validator payment logic
- Delegator reward queries (distribution module gRPC) correctly reflect settlement fees

**Residual Risk:** None if Option B is followed exactly. If custom distribution (Option D/E) is attempted, this threat becomes critical.

---

## 3. Validator Share Stuck in Module Account

**Threat ID:** VAL-003
**Severity:** Medium
**Likelihood:** Very Low
**Impact:** Coins permanently locked in fee_collector or fee_router

**Description:**
Coins are sent to an intermediate account (fee_collector or fee_router) but never distributed.

**Mitigation (Option B):**
- `AllocateTokens` is a mandatory BeginBlocker — runs every block, cannot be skipped
- `AllocateTokens` sweeps ALL coins from fee_collector (uses `GetAllBalances`)
- Even if no validators are bonded (edge case), coins are burned or sent to community pool by the SDK

**Mitigation (Option D, rejected):**
- Custom BeginBlock handler could have a bug that leaves coins in fee_router
- Mitigated by invariant: fee_router balance must be zero after BeginBlock
- This is an additional invariant burden compared to Option B

---

## 4. fee_collector Misuse

**Threat ID:** VAL-004
**Severity:** Low
**Likelihood:** Very Low
**Impact:** Unauthorised sends to fee_collector distort distribution

**Description:**
A user sends coins directly to fee_collector outside the settlement flow, inflating the fee_collector balance and causing over-distribution to validators.

**Mitigation:**
- fee_collector is in `blockedAddrs` — bank module rejects direct user sends
- Only `SendCoinsFromAccountToModule` can send to fee_collector (used by AnteHandler for gas fees and settlement for validator share)
- Any coins sent to fee_collector are distributed to validators — economically, the sender is gifting to validators. Not a security issue, just uneconomical behaviour.
- No funds are lost — they reach validators/delegators

**Residual Risk:** Governance could register a module that sends arbitrary amounts to fee_collector. Same as any governance risk — mitigated by proposal review.

---

## 5. Reward Manipulation

**Threat ID:** VAL-005
**Severity:** Medium
**Likelihood:** Low
**Impact:** Validator gaming settlement fees for disproportionate rewards

**Description:**
A validator (who is also a merchant or payer) creates fake settlements to inflate the fee_collector balance before a BeginBlock where they are the proposer, capturing the proposer reward.

**Mitigation:**
- Settlements require actual coin transfers (merchant net, treasury share, burn share) — creating fake settlements costs real NXRL in fees
- Proposer reward is 1-5% of fee_collector balance — the cost of creating fake settlements exceeds the proposer bonus
- The remaining 95-99% is distributed to all validators, diluting the proposer's gain
- This is the same risk as gas fee manipulation — not specific to settlement fees

**Residual Risk:** Acceptable. The economics make manipulation unprofitable.

---

## 6. Governance Enables Validator Routing Too Early

**Threat ID:** VAL-006
**Severity:** High
**Likelihood:** Low (mitigated by explicit deferral recommendation)
**Impact:** Validator distribution active without distribution specialist review

**Mitigation:**
- This design document explicitly recommends DEFERRING validator distribution
- `ValidatorRoutingEnabled` (if implemented) defaults to false
- Governance proposal must explicitly enable it
- Review gate: "A Cosmos SDK distribution specialist must review before enabling"

**Residual Risk:** Governance could ignore the recommendation. Mitigated by clear documentation and voting period review.

---

## 7. Rounding / Dust in Distribution

**Threat ID:** VAL-007
**Severity:** Low
**Likelihood:** Medium (integer division in AllocateTokens)
**Impact:** Fractional unxrl not distributed to validators

**Description:**
`AllocateTokens` uses `sdk.Dec` arithmetic for reward splitting. Fractional unxrl from proportional splits may accumulate as dust.

**Mitigation:**
- This is standard Cosmos SDK behaviour — not specific to settlement fees
- AllocateTokens handles rounding internally (dec coin truncation)
- Dust is minimal (< 1 unxrl per validator per block)
- The dust goes to the community pool or is truncated — SDK-dependent

**Residual Risk:** Negligible. This is how every Cosmos chain handles distribution rounding.

---

## 8. Denom Mismatch in Distribution

**Threat ID:** VAL-008
**Severity:** Low
**Likelihood:** Very Low
**Impact:** Validator rewards in wrong denomination

**Description:**
Settlement in one denom routes validator share in a different denom, causing distribution in the wrong token.

**Mitigation:**
- Settlement validator share uses the same denom as the settlement amount (`msg.Amount.Denom`)
- AllocateTokens handles multi-denom fee_collector balances (iterates all denoms)
- No cross-denom conversion in settlement → fee_collector path

**Residual Risk:** None. Single-denom settlements in v1. Multi-denom future would need per-denom distribution which AllocateTokens already handles.

---

## 9. Incompatibility with Slashing

**Threat ID:** VAL-009
**Severity:** None
**Likelihood:** None
**Impact:** None

**Description:**
Slashing is applied to staked tokens, not pending rewards. Settlement fees distributed to validators are reward tokens, not staked tokens. There is no interaction between settlement fee distribution and slashing.

**Mitigation:** Not applicable. No conflict.

---

## 10. BeginBlock Failure Risk

**Threat ID:** VAL-010
**Severity:** Medium
**Likelihood:** Very Low (AllocateTokens is battle-tested)
**Impact:** Settlement fees stuck in fee_collector for one extra block

**Description:**
If BeginBlock fails (e.g., due to a panic in AllocateTokens), settlement fees in fee_collector are not distributed that block.

**Mitigation:**
- `AllocateTokens` is a standard SDK BeginBlocker — extensively tested across all Cosmos chains
- If BeginBlock fails, the block is not committed — fees remain in fee_collector for the next block
- Recovery: next block's BeginBlock will sweep the accumulated balance
- No permanent loss — just delayed distribution

**Residual Risk:** None. Standard Cosmos fault tolerance.

---

## 11. Distribution Inflation / Security-Budget Confusion

**Threat ID:** VAL-011
**Severity:** Low
**Likelihood:** Medium (governance misunderstanding)
**Impact:** Confusion between staking inflation and settlement fee revenue

**Description:**
Governance or validators might confuse settlement fee revenue with staking inflation, leading to incorrect assumptions about validator income.

**Mitigation:**
- Settlement fees are transaction fee revenue (like gas fees), NOT inflation
- Staking inflation is controlled by `x/mint` params — independent of settlement volume
- Settlement fee revenue fluctuates with payment volume — not a guaranteed income stream
- Clear documentation: settlement validator share is supplemental, not a replacement for staking rewards

**Residual Risk:** Governance misunderstanding is mitigated by documentation and community education.

---

## Risk Matrix Summary

| ID | Threat | Severity | Status |
|---|---|---|---|
| VAL-001 | Double payment to validators | High | **Eliminated** (AllocateTokens sweeps entire balance) |
| VAL-002 | Bypassing distribution accounting | High | **Eliminated** (uses AllocateTokens, not custom logic) |
| VAL-003 | Validator share stuck | Medium | **Eliminated** (AllocateTokens runs every block) |
| VAL-004 | fee_collector misuse | Low | Mitigated (blockedAddrs + uneconomical) |
| VAL-005 | Reward manipulation | Medium | Mitigated (cost exceeds gain) |
| VAL-006 | Governance enables too early | High | Mitigated (deferral recommendation + flag default false) |
| VAL-007 | Rounding dust | Low | Accepted (standard Cosmos behaviour) |
| VAL-008 | Denom mismatch | Low | **Eliminated** (single denom + AllocateTokens multi-denom) |
| VAL-009 | Slashing incompatibility | None | N/A (no interaction) |
| VAL-010 | BeginBlock failure | Medium | Mitigated (next block recovery) |
| VAL-011 | Inflation confusion | Low | Mitigated (documentation) |

## Residual Risk Acceptance

1. **Validator share remains metadata-only.** Validators receive no on-chain settlement revenue. Governance and validators can audit the accumulated share from settlement records. Sufficient for devnet/testnet.
2. **AllocateTokens is not tested in the NexaRail context.** Any validator distribution implementation must include testnet verification of AllocateTokens behaviour with settlement fees.
3. **Economic model of 60% net fee → validators is not reviewed.** The proportion may need adjustment based on staking inflation rate and total fee volume.

## Recommendation

**Do not implement validator distribution. Keep validator share metadata-only.**

If implementation is required post-review, Option B (fee_collector) with a separate `ValidatorRoutingEnabled` flag is the safest path. The threat surface is minimal — one additional bank call to an existing, battle-tested module account, with distribution handled entirely by the standard Cosmos SDK BeginBlock.
