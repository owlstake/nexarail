# Product Flow CLI/API Usability Review

**Date:** 2026-05-28  
**Scope:** Phase 10B product-flow operator surface review  
**Evidence root:** `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/`

## Summary

The product flows can be operated through the CLI plus governance proposal JSON. Readback is available through CLI, gRPC query services, and a partial REST readback surface. Phase 10B.2 improved evidence-grade event/reporting output, semantic assertions, and treasury funding prerequisite checks. The main remaining usability weakness is operator ergonomics around authority/governance actions and REST route completeness.

## CLI Surface

| Module | Tx commands present | Query commands present | Usability status |
|---|---|---|---|
| `merchant` | `register`, `update` | `params`, `merchant`, `merchants` | Good for owner operations; authority actions like status/verification/rebate require governance JSON |
| `settlement` | `create`, `update-status`, `update-params` | `params`, `settlement`, `list`, `by-merchant`, `by-payer` | Good for create/query; authority actions require governance |
| `escrow` | `create`, `release`, `refund`, `dispute`, `resolve-dispute`, `cancel`, `update-params` | `params`, `escrow`, `list`, `by-buyer`, `by-seller`, `by-merchant`, `exists` | Good direct surface; dispute/resolve not rehearsed in 10B full suite |
| `treasury` | `create-account`, `create-budget`, `create-grant`, `create-spend`, `approve-spend`, `reject-spend`, `mark-spend-executed`, `cancel-spend`, `update-*`, `update-params` | `params`, `account`, `accounts`, `budget`, `budgets`, `grant`, `grants`, `spend`, `spends`, `summary` | Broad CLI surface; authority actions still need governance in realistic operation |
| `payout` | `create`, `create-batch`, `approve`, `mark-paid`, `cancel`, `fail`, `update-params` | `params`, `payout`, `list`, `by-merchant`, `by-recipient`, `by-initiator`, `batch`, `batches`, `exists` | Good direct surface for create/approve; mark-paid/fail/params are authority actions |

## Flow Operability

| Flow | CLI-only direct user path | Governance/script dependency | REST/API readback used in evidence | Notes |
|---|---|---|---|---|
| Merchant onboarding | Yes for register/update | Status changes require governance proposal JSON | Merchant by owner, merchant list, params | Need operator guide for merchant status governance actions |
| Settlement metadata | Yes | None for metadata-only create | Settlement list, settlement by ID, by merchant, params | Good |
| Settlement live | Create is CLI; live flag requires governance | Live flag enable/disable via governance | Settlement by ID/list, params | Good proof, governance UX heavy |
| Settlement treasury routing | Create is CLI; routing flag requires governance | Treasury routing flag enable/disable via governance | Settlement by ID/list, params | REST readback proves state; no dedicated route for by-payer in REST runtime readback |
| Settlement burn routing | Create is CLI; burn flag requires governance | Burn routing flag enable/disable via governance | Settlement by ID/list, params | Burn supply delta evidence should improve |
| Escrow | Yes for create/release/refund/cancel | Live flag requires governance | Escrow list, params | REST lacks detail/filter routes currently exposed by CLI/gRPC |
| Treasury | Spend request CLI; account/budget/approval/execution are authority/governance in this proof | Most treasury product actions require governance proposal JSON | Treasury summary, params, spend query via CLI/gRPC-style query | REST readback is too narrow for full treasury ops |
| Payout | Create/approve CLI; mark-paid/fail/params authority | Mark-paid and live flag require governance | Payout by ID/list, params | Good state proof; authority workflow needs helper docs |
| Safety/final flags | CLI txs for rejection checks; governance for restore false | Restore false via governance | Params/live flag readback | Good |

## REST/API Coverage

Runtime readback routes observed or registered:

| Area | REST routes covered |
|---|---|
| Fees | `/nexarail/fees/v1/params` |
| Merchant | `/nexarail/merchant/v1/params`, `/nexarail/merchant/v1/merchants`, `/nexarail/merchant/v1/merchant/{owner}` |
| Settlement | `/nexarail/settlement/v1/params`, `/nexarail/settlement/v1/settlements`, `/nexarail/settlement/v1/settlement/{id}`, `/nexarail/settlement/v1/settlements/by-merchant/{owner}` |
| Escrow | `/nexarail/escrow/v1/params`, `/nexarail/escrow/v1/escrows` |
| Treasury | `/nexarail/treasury/v1/params`, `/nexarail/treasury/v1/summary` |
| Payout | `/nexarail/payout/v1/params`, `/nexarail/payout/v1/payouts`, `/nexarail/payout/v1/payout/{id}` |

REST/API gaps:

- No REST detail/filter readback for escrow by ID, buyer, seller, merchant, or exists.
- No REST detail/list routes for treasury accounts, budgets, grants, or spend requests beyond summary.
- No REST payout filter routes by merchant, recipient, initiator, batch, batches, or exists.
- No settlement REST route for by-payer in the runtime readback surface.
- No custom REST transaction endpoints; transaction submission remains CLI/gRPC/generic tx service territory.

## gRPC Coverage

The module query and msg services are registered for merchant, settlement, escrow, treasury, and payout. gRPC is a viable API surface for query and message construction/broadcast paths, but Phase 10B evidence primarily exercised CLI tx submission and REST readback. The previous broadcast-harness work should remain the reference for raw tx/gRPC behavior.

## Script-Only Workarounds

The product-flow harness currently handles several operations better than a human operator would from raw CLI:

- building governance proposal JSON for authority-only messages;
- signing and broadcasting gov proposal txs;
- collecting validator votes;
- waiting for proposal pass;
- reading back state and live flags;
- calculating balance deltas;
- restoring all live flags false.

These are acceptable for local rehearsal, but before broader controlled use they should be converted into operator-grade runbooks or focused helper commands. Phase 10B.2 documents that future direction in `docs/hardening/PHASE_10B2_GOVERNANCE_UX_PLAN.md`.

## Phase 10B.2 Operator Evidence

| Artifact | Status | Purpose |
|---|---|---|
| `semantic-assertions.json` / `.md` | Available | Captures expected state, balance, custody, funds-executed, funds-paid, and final live-flag assertions |
| `event-summary.json` / `.md` | Available | Groups merchant, settlement, escrow, treasury, payout, bank, burn, governance, and live-flag events |
| `governance-product-evidence.json` / `.md` | Available | Connects proposal IDs, submit txs, vote txs, final proposal state, expected state changes, and readback proof |
| `burn-supply-delta.json` / `.md` | Available | Proves burn share and total-supply delta for burn-routing settlement |
| Treasury prerequisite evidence | Available | Captures treasury module balances before treasury and payout suites |

The REST parity audit is documented separately in `docs/hardening/PHASE_10B2_REST_READBACK_PARITY.md`. No broad REST rewrite was performed in Phase 10B.2.

## Phase 10B.3 Update

Phase 10B.3 implemented recommendation 2 (REST readback parity) and recommendation 1 (governance helper):

- **REST readback parity:** 16 new endpoints added; 35 of 36 gRPC query methods now wired. See `docs/hardening/PHASE_10B3_REST_PARITY_PLAN.md`.
- **product-gov.sh:** Safe governance wrapper created at `scripts/testnet/product-gov.sh` with dry-run, dependency validation, evidence output, and proposal-path-only execution.
- **Governance templates:** 12 JSON templates created at `rehearsals/validator-agents/governance/templates/`.

### Remaining Recommendations

1. Add an operator runbook for governance-controlled product actions (partially covered by `product-gov.sh`).
2. Keep generated event summaries and governance evidence indexes in every product-flow run.
3. Keep semantic query assertions in the harness so syntactic JSON success is not treated as product success.
4. Keep live-flag defaults false and keep product actions governance-controlled.
