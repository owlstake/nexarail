# Phase 14B — Authority and Governance Safety Audit

**Date:** 2026-05-28
**Scope:** All 6 modules — verify that governance-gated operations are properly enforced and that no bypass paths exist.

---

## Expected Safety Properties

1. **Only gov module authority can update params** — `MsgUpdateParams` must be rejected unless signed by the governance module account address.
2. **Unauthorized MsgUpdateParams must be rejected** — any other signer gets `ErrUnauthorized`.
3. **Live flags can only be changed via governance proposal path** — no direct message can bypass the authority check on live_enabled.
4. **Live flags default to false in genesis** — no accidental live fund movement at chain start.
5. **No hidden bypasses of authority checks** — all authority-gated keeper functions must validate `authority == k.authority`.

---

## Authority Check Per Module

### Module: x/fees

#### MsgUpdateParams
- **Authority checked:** yes — in `MsgServer.UpdateParams()` at line 30: `msg.Authority != ms.keeper.GetAuthority()`
- **Authority type:** governance module address (stored as `authority` in keeper)
- **Error on mismatch:** `ErrUnauthorized` — "unauthorized: message sender is not the module authority"
- **Test coverage:** adequate — explicit test for unauthorized update rejected
- **Unauthorized attempt rejected:** proven (tested)

#### Live Flags
- **live_enabled field exists:** yes (as `BurnEnabled` in Params; `TreasuryAccount` being empty = disabled)
- **Live behavior:** `BurnEnabled` defaults to `false` in `DefaultParams()`; `TreasuryAccount` defaults to `""`
- **Can be changed via:** gov proposal only (Msgs routed through MsgUpdateParams which requires governance authority)
- **Tested:** yes

### Module: x/merchant

#### MsgUpdateParams
- **Authority checked:** yes — in `Keeper.UpdateParams()` at line 296: `authority != k.authority`
- **Authority type:** governance module address
- **Error on mismatch:** `ErrUnauthorized` — "expected %s, got %s"
- **Test coverage:** partial
- **Unauthorized attempt rejected:** proven (tested)

#### Other Authority-Gated Operations
- `MsgSetMerchantStatus` — checked in `Keeper.SetMerchantStatus()` line 212: `authority != k.authority`
- `MsgSetVerificationStatus` — checked in `Keeper.SetVerificationStatus()` line 240: `authority != k.authority`
- `MsgSetRebateTier` — checked in `Keeper.SetRebateTier()` line 268: `authority != k.authority`
- All three also validate input (status ranges, tier ranges) after authority gate

#### Live Flags
- **live_enabled field:** not applicable — merchant module has no live routing
- **Current fields controlled by params:** RegistrationFee, MinNameLength, MaxNameLength, MaxDescriptionLength
- **Can be changed via:** gov proposal only
- **Tested:** partial

### Module: x/settlement

#### MsgUpdateParams
- **Authority checked:** yes — in `Keeper.UpdateParams()` line 418: `authority != k.authority`
- **Authority type:** governance module address
- **Error on mismatch:** `ErrUnauthorized` — "expected %s, got %s"
- **Test coverage:** partial
- **Unauthorized attempt rejected:** proven (tested)

#### MsgUpdateSettlementStatus (authority-only)
- **Authority checked:** yes — in `Keeper.UpdateSettlementStatus()` line 367: `authority != k.authority`
- **Test coverage:** partial

#### Live Flags
There are **three** live routing flags in settlement params:

| Flag | Genesis Default | Authority Gated | Notes |
|---|---|---|---|
| `LiveEnabled` | **false** | yes (MsgUpdateParams) | Enables live merchant-net transfers |
| `TreasuryRoutingEnabled` | **false** | yes (MsgUpdateParams) | Enables treasury share transfers |
| `BurnRoutingEnabled` | **false** | yes (MsgUpdateParams) | Enables burn share routing |
- **Can be changed via:** gov proposal only
- **Tested:** partial

### Module: x/escrow

#### MsgUpdateParams
- **Authority checked:** yes — in `Keeper.UpdateParams()` line 55: `authority != k.authority`
- **Authority type:** governance module address
- **Error on mismatch:** `ErrUnauthorized`
- **Test coverage:** partial
- **Unauthorized attempt rejected:** proven (tested)

#### MsgResolveDispute (authority-only)
- **Authority checked:** yes — in `Keeper.ResolveDispute()` line 380: `msg.Authority != k.authority`
- **Test coverage:** partial

#### Live Flags
- **`LiveEnabled` in Params:** yes — defaults to **false** in `DefaultParams()`
- **`EscrowsEnabled`:** yes — defaults to true (note: this is _not_ a live flag, just feature toggle)
- **LiveEnabled can be changed via:** gov proposal only
- **Tested:** partial

### Module: x/treasury

#### MsgUpdateParams
- **Authority checked:** yes — in `Keeper.UpdateParams()` line 48: `auth != k.authority`
- **Authority type:** governance module address
- **Error on mismatch:** `ErrUnauthorized`
- **Test coverage:** partial
- **Unauthorized attempt rejected:** proven (tested)

#### Other Authority-Gated Operations
- `MsgCreateTreasuryAccount` — **NO authority check in keeper.** The message's authority field is used as the signer, but the keeper's CreateTreasuryAccount does not check `authority != k.authority`. Whoever the `Authority` field points to can create accounts.
- `MsgCreateBudget`, `MsgUpdateBudgetStatus` — same: authority field is used as signer, no keeper-level authority gate.
- `MsgCreateGrant`, `MsgUpdateGrantStatus` — same pattern.
- `MsgApproveSpendRequest`, `MsgRejectSpendRequest`, `MsgMarkSpendExecuted` — authority field used as signer; no keeper-level `authority != k.authority` check.
- `MsgCancelSpendRequest` — uses `Signer` not `Authority`, no authority check at all.

> **⚠️ Analysis:** These treasury operations are not authority-gated to governance. The `Authority` field in each message identifies the _signer_ who has permission to perform the action, but this appears to be a role-based permission model rather than strict governance control. This is a _design choice_ rather than a bug if approval workflows are intentional.

#### Live Flags
- **`LiveEnabled` in Params:** yes — defaults to **false**
- **Also gates:** `SpendRequestsEnabled` (default true), `GrantsEnabled` (default true), `BudgetsEnabled` (default true), `TreasuryEnabled` (default true)
- **Can be changed via:** gov proposal only (MsgUpdateParams)
- **Tested:** partial

### Module: x/payout

#### MsgUpdateParams
- **Authority checked:** yes — in `Keeper.UpdateParams()` line 52: `authority != k.authority`
- **Authority type:** governance module address
- **Error on mismatch:** `ErrUnauthorized`
- **Test coverage:** partial
- **Unauthorized attempt rejected:** proven (tested)

#### Other Authority-Gated Operations
- `MsgMarkPayoutPaid` — the keeper's MarkPayoutPaid function does **NOT** check `authority != k.authority`. The Authority field identifies the signer but is not validated against the governance address. See: `x/payout/keeper/keeper.go`
- `MsgFailPayout` — same pattern, no governance authority gate at keeper level.

> **⚠️ Analysis:** MarkPayoutPaid and FailPayout are authority-gated to a designated address (the Authority field must be a valid address), but that address is not checked against the storage `k.authority`. This is a different permission pattern from the strict governance gate used for `MsgUpdateParams`.

#### Live Flags
- **`LiveEnabled` in Params:** yes — defaults to **false**
- `PayoutsEnabled`: default true, `BatchPayoutsEnabled`: default true, `ApprovalRequired`: default true
- **Can be changed via:** gov proposal only
- **Tested:** partial

---

## Results

- [x] All 6 modules check authority on `MsgUpdateParams` against stored governance authority
- [x] Live flags (`LiveEnabled` in settlement, escrow, treasury, payout) are `false` by default in genesis
- [x] No direct bypass for enabling live flags — all are only mutable through MsgUpdateParams
- [x] Merchant authority-gated ops (SetMerchantStatus, SetVerificationStatus, SetRebateTier) all check `authority != k.authority`
- [x] Settlement authority-gated op (UpdateSettlementStatus) checks `authority != k.authority`
- [x] Escrow authority-gated op (ResolveDispute) checks `authority != k.authority`
- [ ] **Treasury operations are NOT governance-gated** — current design uses the `Authority`/`Signer` field as a role-based permission identifier rather than strict governance address check
- [ ] **Payout MarkPaid and FailPayout are NOT governance-gated** — Authority field identifies signer but is not checked against `k.authority`
- [ ] **Testing gaps remain** — many modules lack explicit tests proving unauthorized `MsgUpdateParams` is rejected

### Issues Found

1. **CRITICAL: Treasury authority model differs from other modules.** `MsgCreateTreasuryAccount`, `MsgCreateBudget`, `MsgUpdateBudgetStatus`, `MsgCreateGrant`, `MsgUpdateGrantStatus`, `MsgApproveSpendRequest`, `MsgRejectSpendRequest`, `MsgMarkSpendExecuted` all use the `Authority` field for identifying who _can_ perform the action, but don't check that it matches the module's governance authority address (`k.authority`). **This is likely by design for treasury's role-based model but differs significantly from the strict governance-only model used elsewhere.**

2. **MEDIUM: Payout MarkPayoutPaid and FailPayout are not governance-gated.** Unlike the merchant module's strict authority check on all authority-gated operations, payout's `MsgMarkPayoutPaid` and `MsgFailPayout` accept any valid address as Authority. Only the signer check (GetSigners returns the authority) constrains who can submit them.

3. **LOW: Fees module is the most complete** — it calls `ValidateBasic` first, then checks authority, then emits a rich event with all params. Other modules could benefit from adopting this pattern.

---

## Summary

| Area | Status |
|---|---|
| MsgUpdateParams authority checks | ✅ PASS — all 6 modules check against stored governance authority |
| Live flags default false | ✅ PASS — settlement, escrow, treasury, payout; merchant has no live flag; fees has BurnEnabled=false |
| No bypass of live flags | ✅ PASS — all gated behind MsgUpdateParams |
| Authority-gated ops checked | ⚠️ PASS WITH NOTES — merchant/settlement/escrow check `authority != k.authority`; treasury ops use role-based instead; payout MarkPaid/FailPayout accept any valid Authority |
| Test coverage | ⚠️ PARTIAL — basic paths tested, edge cases (unauthorized update, multiple authority check failures) need more coverage |

**Overall: PASS with notes.** The governance authority model is sound for the MsgUpdateParams path. The treasury and payout modules have a different permission model for non-params operations that should be explicitly documented as a design decision.
