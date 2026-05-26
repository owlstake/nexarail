# NexaRail Settlement Burn Routing Threat Model

**Phase:** 5F.5 — Security Design
**Date:** 2026-05-25
**Status:** Threat model complete
**Scope:** Phase 5F.6 (burn routing via bank.BurnCoins)

## Threat Surface

```
MsgCreateSettlement (LiveEnabled + TreasuryRouting + BurnRouting all true)
  ├─ bank.SendCoins(payer, merchant, merchantNet)
  ├─ bank.SendCoinsFromAccountToModule(payer, "nexarail_treasury", treasuryShare)
  ├─ bank.SendCoinsFromAccountToModule(payer, "nexarail_burner", burnShare)     ← NEW
  └─ bank.BurnCoins("nexarail_burner", burnShare)                                ← NEW
```

Three existing bank calls + two new. The burner module account holds coins for zero blocks (transferred and immediately burned in the same transaction).

---

## 1. Irreversible Supply Reduction

**Threat ID:** SET-BRN-001
**Severity:** Critical
**Likelihood:** Very Low (mitigated by design)
**Impact:** Permanent, irrecoverable loss of NXRL from total supply

**Description:**
`bank.BurnCoins` permanently destroys coins and reduces total supply. There is no "unburn" mechanism. If the wrong amount is burned, or burn is triggered by a bug, the supply reduction cannot be reversed.

**Mitigation:**
- `BurnRoutingEnabled` defaults to `false` — opt-in via governance
- Burn amount is exactly `burnShare`, calculated from the same formula as the settlement record's `BurnShare` field
- The settlement record provides an auditable trail: `BurnShare` field = burned amount
- `BurnExecuted` field is set to true only after successful burn — invariant can reconcile burned amounts against records
- Governance voting period + deposit + quorum prevent accidental enablement

**Residual Risk:** If governance enables burn and a bug burns the wrong amount, supply is permanently affected. Mitigated by: separate flag, extensive test coverage, and the governance process itself.

---

## 2. Burn from Wrong Account

**Threat ID:** SET-BRN-002
**Severity:** High
**Likelihood:** Very Low
**Impact:** User funds destroyed instead of dedicated burner account funds

**Description:**
If `BurnCoins` is called with a non-burner module account name, or if the burner module account doesn't have `Burner` permission, the call panics.

**Mitigation:**
- `bank.BurnCoins` requires `moduleName string` — cannot accidentally pass a user address
- The module account must be registered with `authtypes.Burner` permission in `maccPerms`
- Panic on invalid module account is caught by Cosmos SDK's recovery middleware — returns an error rather than crashing the node
- Constant `BurnerModuleAccount = "nexarail_burner"` used consistently — no string literal drift

**Residual Risk:** None. The type system and SDK permission checks prevent this.

---

## 3. Double Burn

**Threat ID:** SET-BRN-003
**Severity:** High
**Likelihood:** Very Low
**Impact:** Burn share burned twice, double supply reduction

**Description:**
A settlement is created with burn routing, then re-executed (somehow), causing the burn to happen again.

**Mitigation:**
- Each `CreateSettlement` generates a new auto-increment ID — no re-execution of the same settlement
- Cosmos SDK sequence numbers prevent transaction replay
- `BurnExecuted` field provides an invariant check: if a settlement somehow has `BurnExecuted=true` and the burn is attempted again, the system can detect it
- No "re-burn" or "burn existing settlement" message exists

**Residual Risk:** None. Settlement creation is idempotent by ID uniqueness.

---

## 4. Partial Execution: Burner Transfer Succeeds, BurnCoins Fails

**Threat ID:** SET-BRN-004
**Severity:** Medium
**Likelihood:** Very Low
**Impact:** Coins accumulate in burner module account instead of being burned

**Description:**
The `SendCoinsFromAccountToModule` to the burner succeeds, but the subsequent `BurnCoins` fails. The burner module account now holds unburned coins.

**Mitigation:**
- Both calls are in the same Cosmos SDK transaction — if `BurnCoins` returns an error, the handler returns an error and the entire transaction rolls back
- The burner module account never has a balance in a committed block (zero-block holding period)
- Even if coins accumulate (e.g., due to a bug), the burner module account is in `blockedAddrs` — users cannot send to it directly
- Invariant: `burner_module_balance == 0` at all committed heights (can be checked in BeginBlock)

**Residual Risk:** None within SDK transaction atomicity.

---

## 5. Burner Account Direct Send

**Threat ID:** SET-BRN-005
**Severity:** Low
**Likelihood:** Very Low
**Impact:** Funds permanently locked in burner account

**Description:**
A user sends coins directly to the `nexarail_burner` module account address outside the settlement flow.

**Mitigation:**
- Module account is in `blockedAddrs` — bank module rejects direct sends
- Only `SendCoinsFromAccountToModule` can send to the burner, and only the settlement keeper uses that path
- Even if a governance proposal somehow sent coins to the burner, `BurnCoins` could be called to clean them up

**Residual Risk:** None. Bank module blocked-address enforcement prevents this.

---

## 6. Burner Permission Escalation

**Threat ID:** SET-BRN-006
**Severity:** Medium
**Likelihood:** Very Low
**Impact:** Another module gains burner permission and can burn arbitrary coins

**Description:**
A future module is registered with burner permission and burns coins maliciously.

**Mitigation:**
- Burner permission is restricted to the `nexarail_burner` module account in `maccPerms`
- No other module uses the burner account
- Governance would need to approve a module that registers with burner permission — subject to proposal review
- The settlement keeper is the only code path that calls `BurnCoins` with the burner account

**Residual Risk:** Governance could approve a malicious module. Same as any governance risk. Mitigated by review process.

---

## 7. Supply Invariant Drift

**Threat ID:** SET-BRN-007
**Severity:** Medium
**Likelihood:** Low
**Impact:** Reported supply doesn't match actual supply after burns

**Description:**
Over time, the cumulative burn recorded on settlement records doesn't match the actual supply reduction, due to direct burns from other modules, integer overflow, or supply tracking bugs.

**Mitigation:**
- `bank.BurnCoins` automatically updates `totalSupply` in the bank module — no manual tracking needed
- Supply invariant helper in settlement: `CumulativeBurnTotal(ctx) sdk.Coins`
- Can be cross-checked: `bank.GetSupply() == initial_supply - settlement_cumulative_burn - other_module_burns`
- Cosmos SDK maintains supply tracking internally

**Residual Risk:** Supply tracking is managed by the SDK bank module, not settlement. Settlement only needs to record its own burn contributions.

---

## 8. Governance Enables Burn Prematurely

**Threat ID:** SET-BRN-008
**Severity:** Medium
**Likelihood:** Low
**Impact:** Burn active before supply invariants are verified

**Mitigation:**
- `BurnRoutingEnabled` defaults to `false` — opt-in
- Separate flag from `LiveEnabled` and `TreasuryRoutingEnabled`
- Governance proposal must explicitly set `BurnRoutingEnabled=true`
- Voting period + deposit + quorum provide review time
- Burn can be disabled independently of merchant and treasury routing

**Residual Risk:** Same as any governance-gated feature.

---

## 9. Integer Overflow in Cumulative Burn

**Threat ID:** SET-BRN-009
**Severity:** Low
**Likelihood:** Very Low
**Impact:** Cumulative burn total wraps or overflows

**Mitigation:**
- `sdk.Int` is arbitrary-precision (big.Int) — cannot overflow
- `sdk.Coins.Add` uses `sdk.Int.Add` — safe
- No fixed-size integer accumulation

**Residual Risk:** None. Arbitrary-precision integers prevent overflow.

---

## 10. Burn Amount Miscalculation

**Threat ID:** SET-BRN-010
**Severity:** Medium
**Likelihood:** Low
**Impact:** Wrong amount burned

**Description:**
If the `burnShare` variable used for `BurnCoins` differs from the `BurnShare` field on the settlement record, the audit trail is inconsistent.

**Mitigation:**
- Same `burnShare` variable used for both the settlement record field and the `BurnCoins` call
- Calculated once at the start of `CreateSettlement` — not recomputed
- Test `TestBurnRoutingBurnAmountExact` verifies the burned amount matches the settlement record
- Rounding dust goes TO burn (remainder approach), so burn is slightly larger than the exact 2000 bps proportion — this is intentional and documented

**Residual Risk:** If x/fees params change between calculation and burn in the same handler — not possible (same KV snapshot).

---

## Risk Matrix

| ID | Threat | Severity | Status |
|---|---|---|---|
| SET-BRN-001 | Irreversible supply reduction | Critical | Mitigated (governance gate + tests) |
| SET-BRN-002 | Burn from wrong account | High | **Eliminated** (type system + permissions) |
| SET-BRN-003 | Double burn | High | **Eliminated** (ID uniqueness + sequences) |
| SET-BRN-004 | Burner transfer succeeds, burn fails | Medium | **Eliminated** (SDK atomicity) |
| SET-BRN-005 | Direct send to burner | Low | **Eliminated** (blockedAddrs) |
| SET-BRN-006 | Burner permission escalation | Medium | Mitigated (governance review) |
| SET-BRN-007 | Supply invariant drift | Medium | Mitigated (SDK tracks supply) |
| SET-BRN-008 | Governance enables prematurely | Medium | Mitigated (separate flag, default false) |
| SET-BRN-009 | Integer overflow | Low | **Eliminated** (arbitrary precision) |
| SET-BRN-010 | Burn amount miscalculation | Medium | Mitigated (single variable + tests) |

## Residual Risk Acceptance

1. **Burn is irreversible.** Once enabled by governance and burn occurs, supply reduction is permanent. Governance must understand this.
2. **Burner module account must be registered.** Phase 5F.6 must add `nexarail_burner` to app.go with `Burner` permission.
3. **Validator share remains metadata.** No validator distribution yet — 6000 bps of net fee is still not distributed.

## Implementation Safety Assessment

**Phase 5F.6 is safe to implement.** The burn adds:
- One new module account (`nexarail_burner`) with burner permission
- One new params field (`BurnRoutingEnabled`, default false)
- One new state field (`BurnExecuted`)
- One new BankKeeper method (`BurnCoins`)
- Two new bank calls in `CreateSettlement` (send to burner + BurnCoins)
- ~30 new tests

All threats are eliminated by type system / SDK guarantees (BRN-002, BRN-003, BRN-004, BRN-005, BRN-009) or mitigated by governance gates + tests (BRN-001, BRN-006, BRN-007, BRN-008, BRN-010).
