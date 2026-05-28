# Phase 10B.2 REST Readback Parity

**Date:** 2026-05-28  
**Scope:** Product-flow REST/query readback parity audit  
**Boundary:** Documentation/audit only. No product modules, economics, live defaults, or launch claims changed.

## Summary

Phase 10B.1 proved the product flows through CLI transactions, governance proposal evidence, REST readback, gRPC-backed query services, and state/balance assertions. Phase 10B.2 kept that harness intact and audited the REST readback surface against the CLI/gRPC query surface. Phase 10B.3 has since brought REST parity to ~97% coverage (35 of 36 gRPC query methods wired as REST endpoints).

As of Phase 10B.3, REST is at parity with CLI/gRPC for all product readback use cases. The only remaining gap is a `payout/exists` convenience route. This is no longer an operator-surface gap.

## Route Parity (pre-10B.3 baseline)

| Area | REST status | Available REST readback | Missing / partial | Classification |
|---|---|---|---|---|
| Fees params | Available | `/nexarail/fees/v1/params`, `/nexarail/fees/v1/fee_split` | None identified for current product-flow needs | Available |
| Merchant params/list/detail | Available | `/nexarail/merchant/v1/params`, `/nexarail/merchant/v1/merchants`, `/nexarail/merchant/v1/merchant/{owner}` | No dedicated REST status/rebate/verification helper beyond detail object | Available |
| Settlement params/list/detail/by merchant | Partial | `/nexarail/settlement/v1/params`, `/nexarail/settlement/v1/settlements`, `/nexarail/settlement/v1/settlement/{id}`, `/nexarail/settlement/v1/settlements/by-merchant/{owner}` | REST by-payer route not wired in runtime readback | Partial |
| Escrow params/list | Partial | `/nexarail/escrow/v1/params`, `/nexarail/escrow/v1/escrows` | Detail by ID, buyer, seller, merchant, and exists routes are CLI/gRPC-only from the current REST surface | Partial |
| Treasury params/summary/spend detail | Partial | `/nexarail/treasury/v1/params`, `/nexarail/treasury/v1/summary`, `/nexarail/treasury/v1/spend/{id}` | Account, accounts, budget, budgets, grant, grants, and spends list/filter REST routes missing | Partial |
| Payout params/list/detail | Partial | `/nexarail/payout/v1/params`, `/nexarail/payout/v1/payouts`, `/nexarail/payout/v1/payout/{id}` | By merchant, recipient, initiator, batch, batches, and exists routes missing | Partial |
| Tx submission | Intentionally deferred | Generic Cosmos tx service is registered | No custom product REST tx endpoints | Intentionally deferred |

## Phase 10B.3 Resolution

Phase 10B.3 closed every gap identified above except `payout/exists`. The following routes were added in `app/app.go`'s `RegisterRuntimeReadbackRoutes`:

- Escrow: detail by ID, by-buyer, by-seller, by-merchant, exists
- Settlement: by-payer
- Payout: by-merchant, by-recipient, by-initiator, batch-payout detail, batch-payout list
- Treasury: account detail, account list, budget detail, budget list, grant detail, grant list, spend request list

See [`PHASE_10B3_REST_PARITY_PLAN.md`](./PHASE_10B3_REST_PARITY_PLAN.md) for the full parity audit.

## Phase 10B.4 Resolution

Phase 10B.4 closed the remaining REST gap:
- `GET /nexarail/payout/v1/payout/exists/{id}` — added in app.go. Returns `{"exists": true/false}`. Uses `PayoutKeeper.HasPayout()`.

REST parity is now **36 of 36 (100%) gRPC query methods wired as REST endpoints**.

## Operator Implication

REST is now the canonical operator surface for all product readback alongside gRPC. Dashboards and evidence checks can freely use any of the 35 wired REST endpoints.

## Verification Evidence

- Final all-suite evidence: `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/`.
- Full suite result: `487 pass / 0 fail`, elapsed `1102s`.
- REST parity improved from ~55% to ~97% in 10B.3. See [`PHASE_10B3_REST_PARITY_PLAN.md`](./PHASE_10B3_REST_PARITY_PLAN.md) for the endpoint-by-endpoint audit.
