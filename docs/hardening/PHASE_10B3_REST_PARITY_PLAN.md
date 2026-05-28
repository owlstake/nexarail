# Phase 10B.3 — REST Parity Plan

**Date:** 2026-05-28  
**Scope:** Audit every REST endpoint in the NexaRail chain, classifying by operational status.  
**Boundary:** Documentation/audit only. No product modules, economics, live defaults, or launch claims changed.

## Classification Categories

| Status | Meaning |
|---|---|
| **working** | Fully wired with keeper-dispatch, no panics, structured error JSON responses |
| **partial** | Wired but missing some filter/param query variants |
| **missing** | Keeper/gRPC query exists but no REST wrapper registered |
| **intentionally deferred** | Tx/broadcast endpoints not added in 10B.3 (generic Cosmos tx service covers this) |

## Registration Architecture

REST routes are registered from two locations in the `RegisterAPIRoutes` call chain:

1. **`RegisterRuntimeReadbackRoutes`** (`app/app.go`) — direct keeper calls with proper error handling, path-param parsing, and structured JSON errors.
2. **`ModuleBasics.RegisterGRPCGatewayRoutes`** (per-module `module.go`) — gRPC gateway client calls via `common.RegisterQueryRoute` / `common.RegisterQueryRouteWithParam`.

Phase 10B.3 added 16 new endpoints via `RegisterRuntimeReadbackRoutes` in `app/app.go`, plus ported several pre-existing routes to the same pattern. The table below reflects the current (post-10B.3) state of the codebase.

## Full REST Endpoint Audit

### Fees

| Endpoint | Status | Notes |
|---|---|---|
| `GET /nexarail/fees/v1/params` | working | app.go direct keeper; module-level gRPC gateway also registered |
| `GET /nexarail/fees/v1/fee_split` | working | Module-level gRPC gateway only; keeper client via gRPC |

**Area summary:** Complete. Both query endpoints wired.

### Merchant

| Endpoint | Status | Notes |
|---|---|---|
| `GET /nexarail/merchant/v1/params` | working | app.go direct keeper; module-level gRPC gateway also registered |
| `GET /nexarail/merchant/v1/merchants` | working | app.go direct keeper; module-level gRPC gateway also registered |
| `GET /nexarail/merchant/v1/merchant/{owner}` | **working** | Added pre-10B.3 in app.go; uses `GetMerchant` keeper, validates AccAddress |
| `GET /nexarail/merchant/v1/merchant/exists/{owner}` | missing | gRPC `Merchant` query exists but no dedicated exists endpoint; detail query serves same purpose (404 = not found) |

**Area summary:** Near-complete. Only a "merchant exists" convenience endpoint is absent; detail-by-owner covers the use case via 404 response.

### Settlement

| Endpoint | Status | Notes |
|---|---|---|
| `GET /nexarail/settlement/v1/params` | working | app.go direct keeper; module-level gRPC gateway also registered |
| `GET /nexarail/settlement/v1/settlements` | working | app.go direct keeper; module-level gRPC gateway also registered |
| `GET /nexarail/settlement/v1/settlement/{id}` | **working** | Added pre-10B.3 in app.go; uint64 id parsing with validation |
| `GET /nexarail/settlement/v1/settlements/by-merchant/{owner}` | **working** | Added pre-10B.3 in app.go; uses `GetSettlementsByMerchant` keeper |
| `GET /nexarail/settlement/v1/settlements/by-payer/{payer}` | **working** | Added in 10B.3; uses `GetSettlementsByPayer` keeper |

**Area summary:** Complete in 10B.3. All five settlement gRPC query methods now have REST wrappers.

### Escrow

| Endpoint | Status | Notes |
|---|---|---|
| `GET /nexarail/escrow/v1/params` | working | app.go direct keeper; module-level gRPC gateway also registered |
| `GET /nexarail/escrow/v1/escrows` | working | app.go direct keeper; module-level gRPC gateway also registered |
| `GET /nexarail/escrow/v1/escrow/{id}` | **working** | Added in 10B.3; validates non-empty id, returns structured 404 on not-found |
| `GET /nexarail/escrow/v1/escrows/by-buyer/{buyer}` | **working** | Added in 10B.3; validates non-empty buyer address |
| `GET /nexarail/escrow/v1/escrows/by-seller/{seller}` | **working** | Added in 10B.3; validates non-empty seller address |
| `GET /nexarail/escrow/v1/escrows/by-merchant/{merchant}` | **working** | Added in 10B.3; validates non-empty merchant id |
| `GET /nexarail/escrow/v1/escrow/exists/{id}` | **working** | Added in 10B.3; validates non-empty id, returns `{"exists": bool}` |

**Area summary:** Complete in 10B.3. All seven escrow gRPC query methods now have REST wrappers.

### Payout

| Endpoint | Status | Notes |
|---|---|---|
| `GET /nexarail/payout/v1/params` | working | app.go direct keeper; module-level gRPC gateway also registered |
| `GET /nexarail/payout/v1/payouts` | working | app.go direct keeper; module-level gRPC gateway also registered |
| `GET /nexarail/payout/v1/payout/{id}` | **working** | Added pre-10B.3; uses `GetPayout` keeper with structured 404 |
| `GET /nexarail/payout/v1/payouts/by-merchant/{merchant}` | **working** | Added in 10B.3; uses `GetPayoutsByMerchant` keeper |
| `GET /nexarail/payout/v1/payouts/by-recipient/{recipient}` | **working** | Added in 10B.3; uses `GetPayoutsByRecipient` keeper |
| `GET /nexarail/payout/v1/payouts/by-initiator/{initiator}` | **working** | Added in 10B.3; uses `GetPayoutsByInitiator` keeper |
| `GET /nexarail/payout/v1/batch-payout/{id}` | **working** | Added in 10B.3; uses `GetBatchPayout` keeper with structured 404 |
| `GET /nexarail/payout/v1/batch-payouts` | **working** | Added in 10B.3; uses `GetAllBatchPayouts` keeper |
| `GET /nexarail/payout/v1/payout/exists/{id}` | **missing** | gRPC `PayoutExists` query exists in keeper; no REST wrapper registered |

**Area summary:** Complete in 10B.3 except for `payout/exists/{id}`. The `payout/{id}` detail route covers the same ground via 404, so this is a minor gap.

### Treasury

| Endpoint | Status | Notes |
|---|---|---|
| `GET /nexarail/treasury/v1/params` | working | app.go direct keeper; module-level gRPC gateway also registered |
| `GET /nexarail/treasury/v1/summary` | working | app.go direct keeper; module-level gRPC gateway also registered |
| `GET /nexarail/treasury/v1/spend/{id}` | **working** | Added pre-10B.3; uses `GetSpendRequest` keeper with structured 404 |
| `GET /nexarail/treasury/v1/spends` | **working** | Added in 10B.3; uses `GetAllSpendRequests` keeper |
| `GET /nexarail/treasury/v1/account/{id}` | **working** | Added in 10B.3; uses `GetTreasuryAccount` keeper with structured 404 |
| `GET /nexarail/treasury/v1/accounts` | **working** | Added in 10B.3; uses `GetAllTreasuryAccounts` keeper |
| `GET /nexarail/treasury/v1/budget/{id}` | **working** | Added in 10B.3; uses `GetBudget` keeper with structured 404 |
| `GET /nexarail/treasury/v1/budgets` | **working** | Added in 10B.3; uses `GetAllBudgets` keeper |
| `GET /nexarail/treasury/v1/grant/{id}` | **working** | Added in 10B.3; uses `GetGrant` keeper with structured 404 |
| `GET /nexarail/treasury/v1/grants` | **working** | Added in 10B.3; uses `GetAllGrants` keeper |

**Area summary:** Complete in 10B.3. All ten treasury gRPC query methods now have REST wrappers.

### Tx Submission

| Endpoint | Status | Notes |
|---|---|---|
| Any custom product-level tx POST endpoint | **intentionally deferred** | Generic Cosmos `RegisterTxService` handles tx broadcast. Custom product tx endpoints (escrow create, payout submit, etc.) are deferred to a future phase — they add no consensus value and are correctly exposed only via CLI/msg-server. |

**Area summary:** Correctly deferred. Generic tx service is sufficient for operator needs.

## Duplicate Registration Risk

Routes registered in both `RegisterRuntimeReadbackRoutes` AND `ModuleBasics.RegisterGRPCGatewayRoutes` with the same path pattern may cause a `runtime.MustPattern` panic on gateway startup due to pattern conflict. The affected routes are:

- `/nexarail/fees/v1/params`
- `/nexarail/merchant/v1/params`
- `/nexarail/merchant/v1/merchants`
- `/nexarail/settlement/v1/params`
- `/nexarail/settlement/v1/settlements`
- `/nexarail/escrow/v1/params`
- `/nexarail/escrow/v1/escrows`
- `/nexarail/payout/v1/params`
- `/nexarail/payout/v1/payouts`
- `/nexarail/treasury/v1/params`
- `/nexarail/treasury/v1/summary`

**Recommendation:** Either deduplicate (move all routes to app.go, remove module-level duplicates) or verify at startup that duplicate pattern registration is harmless in the current `grpc-gateway` runtime version. If the mux silently overwrites, the keeper-direct routes win (preferred — they have better error messages).

## Summary

| Area | Total gRPC Queries | REST Wired | Missing | Deferred |
|---|---|---|---|---|
| Fees | 2 | 2 | 0 | 0 |
| Merchant | 3 | 3 | 0 | 0 |
| Settlement | 5 | 5 | 0 | 0 |
| Escrow | 7 | 7 | 0 | 0 |
| Payout | 9 | 8 | 1 (`exists`) | 0 |
| Treasury | 10 | 10 | 0 | 0 |
| Tx | n/a | 0 | 0 | all custom tx endpoints |
| **Total** | **36** | **35** | **1** | **(all tx)** |

## Remaining Gap

1. **`GET /nexarail/payout/v1/payout/exists/{id}`** — the only gRPC query method without a REST wrapper. All other payout queries (detail, list, by-merchant, by-recipient, by-initiator, batch-detail, batch-list) are wired. Adding this route is a trivial one-line registration in `RegisterRuntimeReadbackRoutes`.

2. **Duplicate pattern risk** — 11 routes registered from two locations; TBD whether gRPC-gateway runtime tolerates this at startup.

3. **No remaining keeper query without REST** — Every gRPC `QueryServer` method in every module now has a corresponding REST endpoint, except `PayoutExists`.
