# Phase 14C — Validation and Event Coverage Fixes

## Scope
Fixed the concrete gaps identified in the Phase 14B audit across all 6 product modules. No economics changed. No live flags enabled. No product modules added.

## Finding 1: Payout MsgUpdateParams — Missing Params.Validate()

**Before:** `MsgUpdateParams.ValidateBasic()` only checked the authority address.

**After:** Added `m.Params.Validate()` call. Invalid params are now rejected at message level.

**File:** `x/payout/types/msg.go`

**Status:** ✅ Fixed

## Finding 2: Merchant MsgUpdateMerchant — Missing Field Length Checks

**Before:** Only validated owner address.

**After:** Added maximum length checks:
- Name: max 64 characters
- Description: max 256 characters
- Website: max 512 characters

**File:** `x/merchant/types/msg.go`

**Status:** ✅ Fixed

## Finding 3: Treasury ValidateBasic — Address-Only Stubs

**Before:** Three treasury ValidateBasic methods checked only the authority/requester address with no field validation.

**After:** Each now validates IDs, amounts, and addresses:
- `MsgCreateBudget`: validates budget_id, account_id non-empty, total_amount valid/non-negative
- `MsgCreateGrant`: validates grant_id, budget_id non-empty, recipient_address format, amount valid/non-negative
- `MsgCreateSpendRequest`: validates spend_id, account_id non-empty, recipient_address format, amount valid/non-negative, purpose max 512 chars

**Files:** `x/treasury/types/msg.go`

**Status:** ✅ Fixed

## Finding 4: Escrow MsgCreateEscrow — Missing Field Validation

**Before:** Validated buyer/seller addresses, buyer!=seller, amount non-zero/positive.

**After:** Added:
- merchant_id required
- escrow_id required
- asset denom required
- payment reference max 120 characters
- Amount check uses `IsValid()` before IsZero/IsNegative

**File:** `x/escrow/types/msg.go`

**Status:** ✅ Fixed

## Finding 5–6: Missing Params-Update Events

**Before:** 3 declared events never emitted (escrow, treasury, payout params_updated). Merchant and settlement had no event constants.

**After:** All 5 modules now emit params-update events via `msg_server.UpdateParams()`:
- Payout: `payout_params_updated` with authority + live_enabled attributes
- Treasury: `treasury_params_updated` with authority attribute
- Escrow: `escrow_params_updated` with authority + live_enabled attributes
- Merchant: `merchant_params_updated` with authority attribute (merchant has no live flag)
- Settlement: `settlement_params_updated` with authority + live_enabled attributes

Event constants added for merchant and settlement modules.

**Files:** All 5 `msg_server.go` files, `x/merchant/types/events.go`, `x/settlement/types/events.go`

**Status:** ✅ Fixed

## Items Intentionally Deferred
- Full product-flow rehearsal not rerun (existing 487/0 evidence still valid; no semantics changed)
- Remaining treasury ValidateBasic methods (ApproveSpend, RejectSpend, MarkSpendExecuted, CancelSpend, CreateTreasuryAccount, UpdateBudgetStatus, UpdateGrantStatus) still have address-only validation — these are authority-only operations with keeper-level validation already in place
- Fuzz tests not run (no fuzz functions defined yet)

## No Economics or Live-Default Changes
- All `live_enabled` fields remain `false` by default
- No economic parameters changed
- No new product modules added
- No new authorization paths created

## Verification
- `go build ./...`: ✅ PASS
- `go vet ./...`: ✅ PASS
- `go test ./...`: ✅ All pass
- `predeployment-check.sh`: ✅ 23/23 PASS
- `verify-testnet-rc1.sh`: ✅ 37/37 PASS
- `run-nexarail-regression-matrix.sh --fast`: ✅ **9/9 PASS**
