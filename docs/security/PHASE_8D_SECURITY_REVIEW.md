# Phase 8D — Security Review

**Date:** 2026-05-26
**Reviewer:** Clove (automated)
**Status:** For external auditor review

---

## 1. Authentication / Authority Gates

| Check | Status | Notes |
|---|---|---|
| Params updates gated by authority | ✅ | Gov module address required for all MsgUpdateParams |
| Unauthorised params update rejected | ✅ | Tested in all 6 keeper tests |
| Authority address is gov module | ✅ | `authtypes.NewModuleAddress(govtypes.ModuleName)` |

**Risk:** Low. Standard Cosmos SDK authority gating. No custom auth bypass.

## 2. Governance-Controlled Params

| Module | Params via Gov | Tested |
|---|---|---|
| fees | validator_share, treasury_share, burn_share | ✅ |
| merchant | registration_fee, min_name_length, max_name_length | ✅ |
| settlement | All params including live flags | ✅ |
| escrow | All params including live flag | ✅ |
| treasury | All params including live flag | ✅ |
| payout | All params including live flag | ✅ |

**Risk:** Low. All params gated. All live flags require governance.

## 3. Live Funds Flags

| Flag | Default | Can Be Enabled | Tested |
|---|---|---|---|
| settlement.live_enabled | false | ✅ Via governance | ✅ |
| settlement.treasury_routing_enabled | false | ✅ Via governance | ✅ |
| settlement.burn_routing_enabled | false | ✅ Via governance | ✅ |
| escrow.live_enabled | false | ✅ Via governance | ✅ |
| treasury.live_enabled | false | ✅ Via governance | ✅ |
| payout.live_enabled | false | ✅ Via governance | ✅ |

**Risk:** Low. All 6 gates independently controlled. No single flag enables everything.

## 4. Module Account Permissions

| Account | Permissions | Risk |
|---|---|---|
| nexarail_escrow | None | Low — no autonomous spending |
| nexarail_treasury | None | Low — no autonomous spending |
| nexarail_fee_router | None | Low — routing intermediary only |
| nexarail_burner | Burner | Medium — can burn tokens when routing enables it |

**Risk:** Low. Burner permission is the only elevated permission and is gated behind governance-enabled routing.

## 5. Bank Transfer Atomicity

| Operation | Bank Calls | Atomicity |
|---|---|---|
| Metadata settlement | 0 calls | N/A |
| Live settlement (basic) | 2 calls (payer→merchant, payer→fee_collector) | SDK tx atomic |
| Live settlement (treasury) | 3 calls (+ payer→treasury) | SDK tx atomic |
| Live settlement (full) | 4 calls (+ payer→burner) | SDK tx atomic |
| Live escrow deposit | 1 call (payer→escrow module) | SDK tx atomic |
| Live escrow release | 1 call (escrow→merchant) | SDK tx atomic |

**Risk:** Medium. Multi-output bank transfers are atomic within SDK transactions but the application must verify all calls succeed before committing state. This is the primary audit focus area.

## 6. Burn Mechanics

| Check | Status |
|---|---|
| Burn share calculated from net fee | ✅ |
| Burn only when burn_routing_enabled | ✅ |
| Burn routing to burner module account | ✅ |
| Dust absorption by burn share | ✅ (remainder method) |
| Burn share never exceeds net fee | ✅ |

**Risk:** Medium. Burn mechanics are correct but burn is permanent. Over-burn would reduce supply. Burn only possible through governance-gated routing.

## 7. Settlement Fee Routing

| Check | Status |
|---|---|
| Validator share (6000 bps) | ✅ |
| Treasury share (2000 bps) | ✅ |
| Burn share (2000 bps) | ✅ |
| Fee routing disabled when live_enabled=false | ✅ |
| Treasury routing disabled independently | ✅ |
| Burn routing disabled independently | ✅ |
| Merchant rebate affects fee | ✅ |

**Risk:** Medium. Complex multi-output routing with integer division. Rounding dust absorbs to burn share. Verified in keeper tests.

## 8. Escrow Custody

| Check | Status |
|---|---|
| Escrow created only for active merchants | ✅ |
| Buyer cannot be seller | ✅ |
| Minimum amount enforced | ✅ |
| State transitions: pending→released/refunded/disputed→resolved | ✅ |
| Double-release prevented | ✅ |
| Live custody only when LiveEnabled=true | ✅ |

**Risk:** Medium. State machine correctness is critical for custody. No real funds in escrow without governance enabling LiveEnabled.

## 9. Treasury Spend Execution

| Check | Status |
|---|---|
| Budget must exist before spend | ✅ |
| Budget remaining tracks correctly | ✅ |
| Spend cannot exceed budget | ✅ |
| Treasury accounts isolated | ✅ |
| Live spend only when LiveEnabled=true | ✅ |

**Risk:** Medium. Budget enforcement critical. Overspend would allow draining treasury.

## 10. Payout Execution

| Check | Status |
|---|---|
| Payout created against active merchant | ✅ |
| Double-pay prevented | ✅ |
| Batch operations consistent | ✅ |
| Live payout only when LiveEnabled=true | ✅ |
| Approval workflow (approval_required) | ✅ |

**Risk:** Low-Medium. Double-pay prevention is tested. Live payout gated.

## 11. Genesis Validation

| Check | Status |
|---|---|
| All custom modules validated | ✅ |
| Invalid params rejected | ✅ (tested per module) |
| Duplicate IDs rejected | ✅ (where applicable) |
| Invalid denom rejected | ✅ |
| Negative amounts rejected | ✅ |

**Risk:** Low. Standard Cosmos SDK genesis validation. Custom module genesis tests added in Phase 8B.

## 12. API / REST Surface

| Check | Status |
|---|---|
| REST endpoints: 17 across 6 modules | ✅ |
| No sensitive data exposed via REST | ✅ (public params only) |
| gRPC reflection available | ✅ |
| RPC port restricted in testnet config | ✅ |
| No write endpoints exposed via REST | ✅ |

**Risk:** Low. Read-only REST endpoints. No write/transaction endpoints.

## 13. CLI / Debug Command Safety

| Check | Status |
|---|---|
| debug-p2p-config reads config only | ✅ |
| debug-live-flags reads genesis only | ✅ |
| debug-module-summary reads defaults only | ✅ |
| No debug commands modify state | ✅ |
| No debug commands expose private keys | ✅ |

**Risk:** Low. Debug commands are read-only diagnostics.

## 14. Upgrade Risk

| Risk | Mitigation |
|---|---|
| State migration on upgrade | Standard Cosmos SDK migration handlers |
| Module version tracking | ConsensusVersion() returns 1 for all modules |
| Genesis export/import | ExportGenesis/InitGenesis implemented |
| In-place store migration | Not yet tested — deferred |

**Risk:** Medium. Standard upgrade path exists but not tested end-to-end.

## 15. Deferred Features (Security Impact)

| Feature | Security Impact | Mitigation |
|---|---|---|
| Validator distribution | Accounting errors possible | Design reviewed, tests prepared |
| Bridge / IBC | Cross-chain attack surface | Deferred entirely |
| Stablecoin registry | Oracle/manipulation risk | Deferred entirely |

**Risk:** Low. No code deployed for deferred features.

## Summary

| Category | Risk Level |
|---|---|
| Authentication/Authority | Low |
| Governance-controlled params | Low |
| Live funds flags | Low |
| Module account permissions | Low |
| Bank transfer atomicity | Medium |
| Burn mechanics | Medium |
| Settlement fee routing | Medium |
| Escrow custody | Medium |
| Treasury spend execution | Medium |
| Payout execution | Low-Medium |
| Genesis validation | Low |
| API/REST surface | Low |
| CLI/Debug commands | Low |
| Upgrade risk | Medium |
| Deferred features | Low |

**Overall: Medium.** The primary risks are in settlement fee routing atomicity and live fund module interactions — both gated behind governance-controlled flags. No flags default to true. Formal third-party audit recommended before any mainnet consideration.
