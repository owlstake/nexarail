# NexaRail Settlement Treasury Fee Routing Threat Model

**Phase:** 5F.3 — Security Design
**Date:** 2026-05-25
**Status:** Threat model complete
**Scope:** Phase 5F.4 implementation (merchant + treasury live transfers)
**Flag design:** Separate `TreasuryRoutingEnabled` (default false)

## Threat Surface

For Phase 5F.4, the attack surface expands from one transfer to two:

```
MsgCreateSettlement (LiveEnabled=true, TreasuryRoutingEnabled=true)
  ├─ bank.SendCoins(payer, merchant, merchantNet)           // existing (Phase 5F.2)
  └─ bank.SendCoinsFromAccountToModule(payer, "nexarail_treasury", treasuryShare)  // NEW
```

---

## 1. Partial Transfer Failure (Critical)

**Threat ID:** SET-TR-001
**Severity:** High
**Likelihood:** Low (mitigated by SDK atomicity)
**Impact:** Merchant paid, treasury not paid — or vice versa

**Description:**
If the merchant transfer succeeds but the treasury transfer fails (or vice versa), and the settlement record is stored, the system would have an inconsistent state where one party received funds but the other did not, and the settlement record claims both were transferred.

**Mitigation (by design):**
- Cosmos SDK transaction atomicity: all state changes within a single `DeliverTx` are committed or rolled back together
- `CreateSettlement` message handler returns an error if EITHER transfer fails
- The SDK wraps message execution in a `CacheTx` — bank state mutations from a successful first transfer are discarded if the handler returns an error
- Settlement record is ONLY written after BOTH transfers succeed (code structure enforces this)

**Code structure guarantee:**
```go
if err := transfer1; err != nil { return nil, err }  // rolls back everything
if err := transfer2; err != nil { return nil, err }  // rolls back everything
// Only reachable if both succeeded:
store.Set(...)  // state committed
```

**Test coverage:** `TestTreasuryRoutingTreasuryTransferFails` — verifies that when treasury transfer fails, settlement is not stored and merchant balance is unchanged.

**Residual Risk:** None within Cosmos SDK's execution model. The SDK guarantees atomicity for single-message transactions.

---

## 2. Merchant Paid But Treasury Not Paid (Double-Check)

**Threat ID:** SET-TR-002
**Severity:** High
**Likelihood:** Very Low (same as TR-001, examined separately for clarity)

**Description:**
This is the specific case of TR-001 where merchant receives funds but treasury does not. It is called out separately because it's the most likely partial-failure scenario — the payer has exactly enough for the merchant net but not enough for the treasury share.

**Specific scenario:**
```
payer balance = 99100 unxrl (exactly merchant net, not enough for treasury)
transfer1: payer → merchant (99100) ✓ (payer now has 0)
transfer2: payer → treasury (180) ✗ (insufficient funds)
→ Cosmos SDK rolls back transfer1
→ payer balance restored to 99100
→ merchant never received anything
→ settlement not stored
```

**Mitigation:**
- Cosmos SDK `bank.SendCoins` checks balance before debiting
- If second transfer fails, first transfer is in the same transaction cache — rolled back
- The payer must have `merchantNet + treasuryShare` total balance for the settlement to succeed
- The AnteHandler should check that the payer has enough for the full amount (gas + merchant + treasury)

**Residual Risk:** If the AnteHandler only checks `msg.Amount` (gross amount) but the actual transfers total `merchantNet + treasuryShare` (less than gross), the AnteHandler check is conservative (passes with more than needed). This is safe — it over-checks rather than under-checks.

---

## 3. Treasury Overpayment

**Threat ID:** SET-TR-003
**Severity:** Medium
**Likelihood:** Low
**Impact:** Treasury receives more than the calculated treasuryShare

**Description:**
A bug in the treasury transfer amount calculation sends more than `treasuryShare` to the treasury module account.

**Mitigation:**
- Treasury share is calculated once from x/fees params (read at start of handler, consistent snapshot)
- The same `treasuryShare` variable is used for both the settlement record field AND the bank transfer amount
- Test `TestTreasuryRoutingTreasuryShareAmountExact` verifies the transferred amount matches the calculated share
- Test `TestTreasuryRoutingFeeSplitExact` verifies `valShare + treasuryShare + burnShare == netFee`
- The settlement record provides an auditable trail: `TreasuryShare` field = transferred amount

**Residual Risk:** If x/fees params change between the fee calculation and the bank transfer within the same handler — not possible (same context, same KV snapshot). If x/fees params change in the same block but different transaction — the settlement uses the params active at its execution time, which is correct.

---

## 4. Payer Overcharged

**Threat ID:** SET-TR-004
**Severity:** Medium
**Likelihood:** Low
**Impact:** Payer sends more than merchantNet + treasuryShare

**Description:**
A bug causes the total deduction from the payer to exceed the intended amount.

**Mitigation:**
- Total deduction = `merchantNet + treasuryShare` (two explicit bank calls, amounts calculated from same formula)
- No hidden deductions
- Test `TestTreasuryRoutingPayerTotalDeduction` verifies payer balance decreases by exactly merchantNet + treasuryShare
- `merchantNet + treasuryShare < grossAmount` for all valid fee rates (netFee > treasuryShare because treasuryShare is only 20% of netFee)

**Proof:**
```
merchantNet + treasuryShare = (gross - netFee) + (netFee * 2000/10000)
                             = gross - netFee + 0.2*netFee
                             = gross - 0.8*netFee
                             < gross (for netFee > 0)
```

The payer always sends less than the gross settlement amount. The remainder (validator + burn shares) stays with the payer.

**Residual Risk:** None. The total is mathematically bounded.

---

## 5. Incorrect Rebate Reduces Treasury Share

**Threat ID:** SET-TR-005
**Severity:** Low
**Likelihood:** Low
**Impact:** Treasury receives less than expected if rebate calculation is wrong

**Description:**
If the merchant's rebate tier is incorrectly read or applied, the treasury share (calculated from net fee AFTER rebate) would be wrong.

**Mitigation:**
- Rebate is applied to the base fee BEFORE the fee split — same as Phase 5F.2
- Treasury share = `(baseFee - rebateAmount) * TreasuryShareBps / 10000`
- Merchant rebate tier is read from x/merchant keeper (same as Phase 5F.2)
- Test `TestTreasuryRoutingRebateReducesTreasury` verifies higher rebate = lower treasury share

**Design intent:** The rebate is a discount to the merchant, funded proportionally by all fee recipients (treasury, validators, burn). This is correct — the protocol is giving the merchant a discount, not the treasury subsidising it.

**Residual Risk:** If a malicious governance proposal sets an extreme rebate tier (e.g., 10000 bps = 100%), the net fee becomes zero and treasury receives nothing. This is a governance risk, not a code bug — governance can already set FeeRateBps=0 to eliminate all fees.

---

## 6. Rounding / Dust Leakage

**Threat ID:** SET-TR-006
**Severity:** Low
**Likelihood:** High (every settlement with non-round amounts)
**Impact:** < 1 unxrl per settlement (< 0.000001 NXRL)

**Description:**
Integer division in `treasuryShare = netFee * 2000 / 10000` floors towards zero. The fractional unxrl is not transferred to treasury.

**Example:**
```
netFee = 9999
treasuryShare = 9999 * 2000 / 10000 = 1999.8 → floor → 1999
dust = 0.8 unxrl
```

**Where does the dust go?**
The dust stays with the payer (they weren't charged for it) and is accounted for in `burnShare = netFee - valShare - treasuryShare` (the remainder absorbs the fractions from both valShare and treasuryShare calculations). When burn routing is implemented, the dust is burned. Until then, it's metadata.

**Mitigation:**
- Dust is < 1 unxrl per fee component, < 2 unxrl total per settlement
- At 1 unxrl = 0.000001 NXRL, 1 billion settlements would accumulate at most 2 NXRL in uncollected treasury dust
- The burn remainder approach ensures accounting consistency: `valShare + treasuryShare + burnShare == netFee`

**Residual Risk:** Negligible. The dust is economically insignificant and is correctly accounted for in burnShare.

---

## 7. Module Account Blocked-Address Misunderstanding

**Threat ID:** SET-TR-007
**Severity:** Medium
**Likelihood:** Low (caught at implementation if wrong method used)
**Impact:** Treasury transfer rejected by bank module

**Description:**
`nexarail_treasury` is in `blockedAddrs` in `app/app.go`. Direct `bank.SendCoins` to a blocked module account address is rejected. The implementation MUST use `SendCoinsFromAccountToModule`, which bypasses the blocked-address check for authorised module-to-module and account-to-module transfers.

**Correct usage:**
```go
// WRONG — blocked by bank module:
k.bankKeeper.SendCoins(ctx, payerAddr, treasuryAddr, coins)

// CORRECT — bypasses blocked-address check:
k.bankKeeper.SendCoinsFromAccountToModule(ctx, payerAddr, "nexarail_treasury", coins)
```

**Mitigation:**
- Design document explicitly calls out the correct method
- Test `TestTreasuryRoutingUsesCorrectModuleName` verifies the module name string
- `SendCoinsFromAccountToModule` takes a module name string, not an address — eliminates address construction errors
- The bank module's `SendCoinsFromAccountToModule` internally resolves the module name to an address and permits the transfer

**Residual Risk:** If the bank keeper interface is incorrectly defined (missing `SendCoinsFromAccountToModule`), the code won't compile. If the interface has the method but the mock doesn't implement it, tests fail at compile time. Safe.

---

## 8. Governance Enables Treasury Routing Too Early

**Threat ID:** SET-TR-008
**Severity:** Medium
**Likelihood:** Low
**Impact:** Treasury routing active before adequate testing

**Description:**
Governance passes a proposal to set `TreasuryRoutingEnabled=true` before the implementation is fully tested and audited.

**Mitigation:**
- `TreasuryRoutingEnabled` defaults to `false` — opt-in
- Separate flag from `LiveEnabled` — merchant payments can be live while treasury routing is disabled
- Governance voting period provides time for review
- This threat model and test plan serve as review documents for any governance proposal
- Treasury routing can be disabled independently of merchant payments if a bug is discovered

**Residual Risk:** Same as any governance-gated feature. Mitigated by deposit, voting period, and quorum requirements.

---

## 9. Treasury Share Denom Mismatch

**Threat ID:** SET-TR-009
**Severity:** Low
**Likelihood:** Low
**Impact:** Treasury receives coins in wrong denomination

**Description:**
The treasury transfer uses a different denom than the settlement amount, causing incorrect accounting.

**Mitigation:**
- Treasury transfer denom = settlement amount denom = `msg.Amount.Denom`
- All fee calculations use the same denom (single-denom settlements in v1)
- Coin construction: `sdk.NewCoin(denom, treasuryShare)` — denom is always `msg.Amount.Denom`
- Test `TestTreasuryRoutingDenomMatchesSettlement` verifies denom consistency

**Residual Risk:** Future multi-denom settlements would need per-denom treasury accounting. Not in scope for v1.

---

## 10. Fee Param Manipulation Between Calculations and Transfers

**Threat ID:** SET-TR-010
**Severity:** Low
**Likelihood:** Very Low
**Impact:** Treasury receives wrong amount due to param change mid-execution

**Description:**
x/fees params change between the fee calculation step and the bank transfer step within `CreateSettlement`.

**Mitigation:**
- x/fees params are read ONCE at the start of fee calculation (`feeParams := k.feesKeeper.GetParams(ctx)`)
- The same `treasuryShare` variable is used for both the settlement record field and the bank transfer amount
- Cosmos SDK executes transactions sequentially — no concurrent modification within a block
- All reads within a single `DeliverTx` use the same KV store snapshot

**Residual Risk:** None within Cosmos SDK's execution model.

---

## 11. Future Burn/Validator Integration Risks

**Threat ID:** SET-TR-011
**Severity:** N/A (deferred)
**Likelihood:** N/A
**Impact:** N/A

**Description:**
When burn and validator routing are added (Phase 5F.5+), the three-transfer or four-transfer flow introduces new failure modes.

**Identified for future:**
- Three transfers increase the atomicity surface (but still within single transaction — safe)
- `bank.BurnCoins` requires a module account with burn permissions (nexarail_fee_router or a dedicated burn module)
- Validator distribution via `x/distribution` requires integration with the distribution module's `AllocateTokens`
- Burn reduces total supply — supply invariant must be verified
- Validator distribution may require BeginBlock routing rather than in-message routing

**Mitigation (deferred):**
- Each new transfer will be added behind its own feature flag (e.g., `BurnRoutingEnabled`, `ValidatorRoutingEnabled`)
- Supply invariant tests will be added before enabling burn routing
- Distribution integration will be designed and reviewed separately

---

## 12. Treasury Module Account Balance Drift

**Threat ID:** SET-TR-012
**Severity:** Low
**Likelihood:** Very Low
**Impact:** Treasury module account balance doesn't match sum of treasury shares

**Description:**
Over time, the treasury module account balance could drift from the expected sum of all treasury shares from live-settled records, due to:
- Direct sends to the module account (blocked by `blockedAddrs`)
- Treasury spend execution (Phase 5D — reduces balance)
- Genesis allocation
- Fee routing from other sources (future)

**Mitigation:**
- `blockedAddrs` prevents unauthorised direct sends
- Treasury spends are individually tracked (Phase 5D)
- Settlement records provide a complete audit trail of treasury inflows
- Future invariant: `treasury_balance == genesis_treasury + Σ settlement_treasury_shares + other_inflows - Σ spends`

**Residual Risk:** Not a Phase 5F.4 concern. Treasury balance drift would be caught by module invariants in x/treasury, not x/settlement.

---

## Risk Matrix Summary

| ID | Threat | Severity | Phase 5F.4 Status |
|---|---|---|---|
| SET-TR-001 | Partial transfer failure | High | **Eliminated** (SDK atomicity + code structure) |
| SET-TR-002 | Merchant paid, treasury not | High | **Eliminated** (same as TR-001) |
| SET-TR-003 | Treasury overpayment | Medium | Mitigated (tests verify exact amount) |
| SET-TR-004 | Payer overcharged | Medium | Mitigated (mathematical bound + tests) |
| SET-TR-005 | Incorrect rebate effect | Low | Mitigated (same formula as Phase 5F.2) |
| SET-TR-006 | Rounding dust | Low | Mitigated (burn remainder absorption) |
| SET-TR-007 | Blocked-address confusion | Medium | Mitigated (SendCoinsFromAccountToModule + tests) |
| SET-TR-008 | Governance enables too early | Medium | Mitigated (separate flag, default false) |
| SET-TR-009 | Denom mismatch | Low | Mitigated (single denom + tests) |
| SET-TR-010 | Param manipulation | Low | Mitigated (consistent KV snapshot) |
| SET-TR-011 | Future burn/validator risks | N/A | Deferred (separate flags planned) |
| SET-TR-012 | Treasury balance drift | Low | Deferred (x/treasury invariant concern) |

## Residual Risk Acceptance

**Accepted for Phase 5F.4:**
1. **Burn share remains metadata.** Treasury module account balance does not reflect the full protocol fee — only the treasury share (20% of net fee after rebate). The other 80% (validator + burn) is not routed on-chain.
2. **Validator share remains metadata.** Validators are not compensated from settlement fees on-chain. Governance must understand this before enabling `TreasuryRoutingEnabled` for mainnet.
3. **Dust < 2 unxrl per settlement is not transferred to treasury.** Economically negligible. Burn remainder ensures accounting consistency.
4. **No supply reduction.** Burn routing is deferred. Total NXRL supply is not deflationary from settlements.

## Implementation Safety Assessment

**Phase 5F.4 is safe to implement.** The threat surface expands by exactly one transfer:

- One new params field (`TreasuryRoutingEnabled`, default false)
- One new BankKeeper interface method (`SendCoinsFromAccountToModule`)
- One additional bank call in `CreateSettlement`, gated by BOTH `LiveEnabled` AND `TreasuryRoutingEnabled`
- No new module accounts
- No new state fields on Settlement
- No change to app wiring
- Separate flag design allows disabling treasury routing without affecting merchant payments

All threats are either eliminated by SDK atomicity (TR-001, TR-002), mitigated by tests (TR-003, TR-004, TR-007), already handled by Phase 5F.2 design (TR-005, TR-006, TR-010), or deferred to future phases (TR-011, TR-012).
