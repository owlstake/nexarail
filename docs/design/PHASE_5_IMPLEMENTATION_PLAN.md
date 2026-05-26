# NexaRail Phase 5 Implementation Plan

## Phase 5A: Design (current — COMPLETE)

- Produce all architecture docs ✓
- No code changes ✓
- Verify existing build/test suite ✓

## Phase 5B: Module Accounts + Blocked Addresses — **COMPLETE (2026-05-25)**

**Status:** ✓ Complete. Three module accounts registered with nil permissions: `nexarail_escrow`, `nexarail_treasury`, `nexarail_fee_router`. Blocked addresses auto-populated from maccPerms. No business flow changes. All 11 app tests pass.

**Scope:** Add module accounts to genesis and blocked address lists. No business logic changes.

### Steps
1. Define module account names and permissions in `app/app.go`
2. Register module accounts: `nexarail_escrow`, `nexarail_treasury`
3. Add module account addresses to `blockedAddrs` map
4. Add module account permissions to `maccPerms`
5. Update genesis with initial module account balances (zero)
6. Verify all existing tests pass
7. Add tests for module account creation

**Risk:** Low. No fund movement. Only account registration.

## Phase 5C: Live Escrow Custody — **COMPLETE (2026-05-25)**

**Status:** ✓ Complete. Live escrow custody implemented behind `params.LiveEnabled` (default false). Buyer funds transferred to `nexarail_escrow` module account on creation. Release/refund/cancel/dispute-resolution transfer back to appropriate party. Metadata-only path preserved when LiveEnabled=false. 6 new live custody tests pass alongside all 36 existing escrow tests.

**Phase 5C.1 hardening complete:** 5 additional safety tests added. Two invariant helpers implemented: `ActiveCustodiedEscrowTotals(ctx)` and `ValidateCustodyInvariant(ctx)`. Terminal-custodied-invariant, double-release, double-refund, module-balance tracking, and metadata-no-bank-calls tests all pass.

**Scope:** Implement `bank.SendCoins` calls in x/escrow keeper.

### Steps
1. Add `bankKeeper` to escrow keeper constructor
2. Implement funding transfer in `CreateEscrow` (behind `live_enabled` param gate)
3. Implement release transfer in `ReleaseEscrow`
4. Implement refund transfer in `RefundEscrow`
5. Implement dispute resolution transfers
6. Update escrow status to FUNDED after successful transfer
7. Add balance checks before transfers
8. Add escrow balance invariant
9. Add balance before/after tests
10. Add failure mode tests

**Risk:** Medium. First live fund movement. Test thoroughly.

## Phase 5D: Treasury Module Account Balance Tracking — **COMPLETE (2026-05-25)**

**Status:** ✓ Complete. Treasury live spend execution implemented behind `params.LiveEnabled` (default false). When enabled, `MarkSpendExecuted` transfers from `nexarail_treasury` module account to recipient. `FundsExecuted` field tracks whether bank transfer occurred. Metadata-only path preserved when LiveEnabled=false. 3 new live tests pass alongside all 30 existing treasury tests.

**Scope:** Treasury module account spend execution with live bank transfers.

### Steps
1. Add `LiveEnabled` param to treasury (default false) ✓
2. Add `FundsExecuted` field to SpendRequest ✓
3. Add `BankKeeper` interface to expected_keepers ✓
4. Add `TreasuryModuleAccount` constant ✓
5. Inject `app.BankKeeper` into treasury keeper constructor ✓
6. Implement live transfer in `MarkSpendExecuted` when LiveEnabled=true ✓
7. Add live spend execution tests (3) ✓
8. Full verification ✓

**Risk:** Low. Metadata-only default. Live path gated by governance param.

## Phase 5E: Payout Execution — **COMPLETE (2026-05-25)**

**Status:** ✓ Complete. Live payout transfers implemented behind `x/payout` `params.LiveEnabled` (default false). When enabled, `MarkPayoutPaid` transfers `net_amount` from `nexarail_treasury` to the recipient before any state mutation; the new `FundsPaid` field tracks whether the transfer occurred. Metadata-only path preserved when LiveEnabled=false. Two invariant/helper methods added: `ActivePaidPayoutTotals(ctx)` and `ValidatePayoutFundsInvariant(ctx)`. 11 new tests (metadata regression + live success/insufficient/double/cancelled/failed/non-approved/invariant/totals) pass alongside all existing payout tests. Full suite green; settlement and fee routing remain non-live.

**Scope:** Payout execution with live transfers from treasury.

### Steps
1. Add `LiveEnabled` param to payout (default false) ✓
2. Add `FundsPaid` field to Payout; genesis-safety rule in `ValidateWithParams` ✓
3. Add `BankKeeper` interface to expected_keepers; local `TreasuryModuleAccount` constant ✓
4. Inject `app.BankKeeper` into payout keeper constructor ✓
5. Implement live transfer in `MarkPayoutPaid` when LiveEnabled=true (transfer before status mutation) ✓
6. Add `ActivePaidPayoutTotals` + `ValidatePayoutFundsInvariant` helpers ✓
7. Add live + metadata-regression tests; balance before/after assertions ✓
8. Full verification (tidy/verify/build/vet/test) ✓

**Deferred to future work:** live batch payout execution (per-payout only in v1); budget `spent_amount` linkage for payouts.

**Risk:** Low–Medium. Metadata-only default; live path gated by governance param. Depends on treasury having funds.

## Phase 5F: Settlement Live Transfer + Fee Routing

**Scope:** Settlement fee collection and routing.

**Phase 5F.1 — Design (✅ complete):** Design documents created:
- `docs/design/SETTLEMENT_LIVE_TRANSFER_DESIGN.md`
- `docs/design/SETTLEMENT_FEE_ROUTING_OPTIONS.md`
- `docs/design/SETTLEMENT_LIVE_TEST_PLAN.md`
- `docs/security/SETTLEMENT_LIVE_THREAT_MODEL.md`

Option C selected: live merchant-net transfer only.

**Phase 5F.2 — Live Merchant-Net Transfer (✅ complete):**
1. Added `LiveEnabled` to settlement params (default false)
2. Added `FundsSettled` bool to Settlement struct
3. Added `BankKeeper` interface with `SendCoins` to expected keepers
4. Injected `app.BankKeeper` into settlement keeper
5. Live transfer: When `LiveEnabled=true`, `CreateSettlement` transfers merchant net from payer to merchant BEFORE state mutation
6. Live-settled records are blocked from status changes (no automated refunds)
7. Added invariant helpers: `ActiveSettledTotals`, `ValidateSettlementFundsInvariant`
8. 28 new tests (metadata regression, live success, failure paths, fee calculation, status guards, invariants, denom)
9. All existing settlement tests still pass (51 keeper tests total)

### Steps remaining
- [x] Add `bankKeeper` to settlement keeper constructor
- [x] Implement merchant-net transfer in `CreateSettlement`
- [ ] Implement BeginBlock fee routing handler (deferred to Phase 5F.3+)
- [ ] Route fees: collector → treasury, burn, validators (deferred)
- [x] Add fee split invariant checks
- [ ] Add supply conservation invariant (deferred — phase 5F.2 is supply-conserving by design)
- [x] Add balance before/after tests

**Risk:** Medium. Single bank call, proven escrow/treasury pattern replicated.

### Phase 5F.3 — Treasury Fee Routing Design (✅ complete)

Design documents for treasury-share live routing:
- `docs/design/SETTLEMENT_TREASURY_FEE_ROUTING_DESIGN.md`
- `docs/design/SETTLEMENT_TREASURY_FEE_TEST_PLAN.md`
- `docs/security/SETTLEMENT_TREASURY_FEE_THREAT_MODEL.md`

Decision: separate `TreasuryRoutingEnabled` flag (default false).

### Phase 5F.4 — Treasury Fee Routing Implementation (✅ complete)

1. Added `TreasuryRoutingEnabled` to settlement params (default false)
2. Expanded `BankKeeper` interface with `SendCoinsFromAccountToModule`
3. Added `TreasuryModuleAccount` constant in settlement keeper
4. Treasury transfer: payer → nexarail_treasury via `SendCoinsFromAccountToModule`
5. Gated behind BOTH `LiveEnabled=true` AND `TreasuryRoutingEnabled=true`
6. Zero treasury share → skip transfer (no unnecessary bank call)
7. Event includes `treasury_routed` attribute
8. 22 new tests (metadata, merchant-only, treasury success, failure, fee calc, invariants)
9. 73 keeper tests total, all pass

### Steps remaining
- [ ] Implement BeginBlock fee routing handler (deferred to Phase 5F.5+)
- [ ] Route burn (deferred to Phase 5F.5)
- [ ] Route validator share (deferred to Phase 5F.6+)
- [ ] Add supply conservation invariant for burn (deferred)

**Risk:** Low. Two bank calls, both atomic, separate flag isolation.

### Phase 5F.5 — Burn Routing Design (✅ complete)

Design documents for burn-share live routing:
- `docs/design/SETTLEMENT_BURN_ROUTING_DESIGN.md`
- `docs/design/SETTLEMENT_BURN_TEST_PLAN.md`
- `docs/security/SETTLEMENT_BURN_THREAT_MODEL.md`

Decision: separate `BurnRoutingEnabled` flag, `bank.BurnCoins` via `nexarail_burner` module account with `authtypes.Burner` permission.

### Phase 5F.6 — Burn Routing Implementation (✅ complete)

1. Registered `nexarail_burner` module account in app.go with `authtypes.Burner` permission
2. Added `BurnRoutingEnabled` to settlement params (default false)
3. Added `BurnExecuted bool` field to Settlement struct with validation
4. Expanded `BankKeeper` interface with `BurnCoins(ctx, moduleName, coins) error`
5. Added `BurnerModuleAccount` constant in settlement keeper
6. Burn flow: SendCoinsFromAccountToModule(payer→nexarail_burner) → BurnCoins(nexarail_burner, burnShare)
7. Gated behind LiveEnabled=true AND TreasuryRoutingEnabled=true AND BurnRoutingEnabled=true
8. Zero burn share → skip entire burn path (no unnecessary calls)
9. Event includes `burn_routed` attribute
10. 20 new tests (metadata, merchant+treasury preserved, burn success, failure, invariants, validation)
11. 93 keeper tests total, all pass

### Steps remaining
- [ ] Route validator share (deferred to Phase 5F.7+)
- [ ] Implement BeginBlock fee routing handler (deferred)
- [ ] Implement fee router account usage (deferred)

### Steps
1. Implement `bank.BurnCoins` in fee routing
2. Verify supply reduction
3. Integrate with Cosmos distribution module for validator share
4. Add burn accounting invariant
5. Add supply conservation tests

**Risk:** Medium. Burn is irreversible. Test supply checks.

## Phase 5H: Security, Simulation, Audit Prep

**Scope:** Comprehensive testing and security review.

### Steps
1. Run fuzz tests on all fund-moving flows
2. Run simulation with random operations
3. Verify all invariants under stress
4. Manual security review of all `bank.SendCoins` call sites
5. Double-execution prevention audit
6. Genesis migration test from v1 metadata-only to v2 live
7. Governance-gated enable/disable test
8. Emergency pause test
9. Prepare for external audit
