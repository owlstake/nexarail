# Product Flow Gaps

**Date:** 2026-05-28  
**Scope:** Phase 10B.2 product-flow operator-surface gap analysis  
**Evidence reviewed:** `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/`  
**Status:** Full local product-flow suite passed with strengthened evidence; operator/API gaps remain.

## Gap Counts

| Severity | Count | Meaning |
|---|---:|---|
| High | 0 | No product-flow semantic gap currently blocks local agent-testnet rehearsal use |
| Medium | 3 | Confusing, incomplete, or operationally risky before broader controlled use |
| Low | 4 | Documentation, naming, ergonomics, or reporting polish |

## High Severity

None found in the reviewed evidence.

## Medium Severity

### PF-10B1-M01 — Governance-Executed Product Events Are Not Directly Indexed

- **Category:** Event gaps; governance UX gaps; evidence/reporting gaps
- **Evidence:** Governance-wrapped actions in `merchant/set-inactive/`, `treasury/approve-execute-spend/`, `payout/mark-paid/`, and `gov/*` prove submit/vote/final status plus state readback. Phase 10B.2 now generates `governance-product-evidence.json` and `event-summary.json`, but submit tx events are still primarily `submit_proposal`, `proposal_deposit`, and generic tx events.
- **Impact:** Indexers/operators cannot easily consume a single product-specific event stream for authority actions such as `payout_paid`, treasury spend execution, merchant status changes, or live-flag changes.
- **Recommendation:** Add protocol/module event emission or indexer rules for proposal execution effects if operator dashboards need first-class product-event streams.

### PF-10B1-M02 — REST Readback Surface Is Partial

- **Category:** REST/API gaps; query output gaps
- **Evidence:** Phase 10B readback successfully used REST for params/list plus selected detail routes, but runtime REST routes do not yet mirror all CLI/gRPC query commands. Missing areas include escrow detail/filter routes, treasury account/budget/grant/spend routes, payout filter/batch/exists routes, and settlement by-payer.
- **Impact:** Operators can use CLI/gRPC for these queries, but REST-only dashboards and monitoring cannot yet cover the full product surface.
- **Recommendation:** Expand REST readback routes to match the CLI/gRPC query surface before public dashboard or operator API claims.

### PF-10B1-M03 — Authority/Governance UX Is Script-Heavy

- **Category:** CLI gaps; governance UX gaps; docs gaps
- **Evidence:** Live-flag changes, merchant status changes, treasury account/budget creation, treasury spend execution, and payout mark-paid were driven through proposal JSON and harness wrappers.
- **Impact:** The protocol path is correct, but a human operator would need careful scripts or runbooks to avoid malformed proposals.
- **Recommendation:** Add an operator-grade governance runbook and/or helper commands for common product governance actions.

## Low Severity

### PF-10B1-L01 — Numeric Status Codes Need Human Labels In Evidence

- **Category:** Query output gaps; docs gaps
- **Evidence:** Query JSON uses numeric statuses such as merchant `status=0`, payout `status=3`, spend `status=4`, escrow statuses `3/4/6`.
- **Impact:** Engineers can map them, but evidence reviews are slower and less legible.
- **Recommendation:** Add a status-code legend to evidence docs or emit derived labels in harness summaries.

### PF-10B1-L02 — Rejected Tx Errors Are Sometimes Generic

- **Category:** Error-message gaps
- **Evidence:** Double treasury execute and double payout mark-paid produce generic `unauthorized`; unauthorized settlement params is clearer and names expected authority.
- **Impact:** Correct rejection is proven, but operator debugging is weaker.
- **Recommendation:** Improve error strings where possible without weakening authorization semantics.

### PF-10B1-L04 — Dispute/Resolve Escrow Path Not In Full Product Suite

- **Category:** State-transition gaps
- **Evidence:** CLI supports `escrow dispute` and `escrow resolve-dispute`; Phase 10B full suite covers create, release, refund, cancel, and double-release rejection only.
- **Impact:** Core escrow custody paths are proven, but dispute lifecycle remains outside this product-flow proof.
- **Recommendation:** Add a targeted escrow dispute suite if dispute operations are in scope for the next controlled product proof.

### PF-10B1-L05 — REST Routes Live In Both Module And App-Level Readback Wiring

- **Category:** REST/API gaps; docs gaps
- **Evidence:** Module `RegisterGRPCGatewayRoutes` registers basic routes, while app-level runtime readback adds selected detail routes.
- **Impact:** The split is workable but easy to forget when extending REST coverage.
- **Recommendation:** Consolidate route documentation and add route-level tests for all intended public readback endpoints.

## Closed / Not Reproduced

### PF-10B1-M04 — Burn Routing Lacks Explicit Supply Delta Evidence

- **Original gap:** Burn-routing proof had tx event + settlement state but no explicit total-supply delta.
- **Fix:** Phase 10B.2 added `scripts/testnet/check-burn-supply-delta.sh` and harness assertions.
- **Verification:** `burn-supply-delta.json` in `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/` reports status `pass`, burn share `2000`, total supply delta `-2000`, and burner module balance delta `0`.

### PF-10B1-M05 — Query Evidence Can Treat JSON Error Bodies As Passes

- **Original gap:** REST query helpers could treat syntactically valid error JSON as a successful query.
- **Fix:** Phase 10B.2 tightened query/readback semantics and added `semantic-assertions.json`.
- **Verification:** `semantic-assertions.json` in `20260528T003925Z` reports `36 pass / 0 fail`.

### PF-10B1-M06 — Product Flow Relies On Treasury Funding Prerequisites

- **Original gap:** Treasury and payout suites consumed treasury module funds without a standalone prerequisite check.
- **Fix:** Phase 10B.2 added treasury funding prerequisite checks and balance evidence before treasury and payout suites.
- **Verification:** Full-suite semantic assertions include `treasury funding prerequisite` and `payout treasury funding prerequisite` as passing checks.

### PF-10B1-L03 — Event Summary Requires Manual jq Review

- **Original gap:** Product events required manual JSON review.
- **Fix:** Phase 10B.2 added `scripts/testnet/extract-product-flow-events.sh`.
- **Verification:** `event-summary.json` and `event-summary.md` are generated automatically in the final evidence directory.

### PF-10B0-001 — Full Suite Exceeds 900s Global Cap

- **Original command:** `scripts/testnet/run-product-flow-rehearsal.sh --full --force-clean`
- **Original result:** Failed clearly at stage `payout flow`, exit `143`.
- **Original evidence:** `rehearsals/validator-agents/product-flows/evidence/20260527T221138Z/`
- **Fix:** Phase 10B.0.1 added resumable suite selection, resume support, stage duration summaries, and a 2400s full-suite global cap while preserving per-stage caps.
- **Verification:** `scripts/testnet/run-product-flow-rehearsal.sh --suite all --force-clean --global-timeout 2400` passed with `469 pass / 0 fail`, elapsed `1111s`.
- **Evidence:** `rehearsals/validator-agents/product-flows/evidence/20260527T225842Z/`

### Descriptor / CheckTx Panic

- **Status:** Not reproduced in Phase 10B.0 smoke/full attempts, the Phase 10B.0.1 full-suite pass, or the Phase 10B.2 full-suite pass.
- **Evidence:** `descriptor-errors.txt` in `20260528T003925Z` contains 0 runtime matches after filtering to runtime logs and tx/query artifacts.
- **Notes:** The harness captures `unknownproto`, `Descriptor`, `index out of range`, `gzip`, `invalid header`, `CheckTx`, and `panic` matches automatically on failure.

### Silent Freeze

- **Status:** Closed for harness behavior.
- **Evidence:** Failed full run emitted exact stage, exit code, run log, process list, port usage, validator logs, diagnostics, and root-cause hypothesis. Final 2400s full suite passed.
- **Manual cleanup:** Not required.

## Phase 10B.3 Resolution

Phase 10B.3 closed 3 medium gaps:

| Gap | Resolution | Evidence |
|---|---|---|
| REST parity (medium) | 16 new REST endpoints added; 35/36 gRPC query methods now wired | `docs/hardening/PHASE_10B3_REST_PARITY_PLAN.md` |
| Governance UX (medium) | `product-gov.sh` script + 12 governance templates created | `scripts/testnet/product-gov.sh`, `rehearsals/validator-agents/governance/templates/` |
| Gov-executed event indexing (medium) | Evidence classification, before/after values, related tx discovery | `scripts/testnet/index-governance-product-evidence.sh` |

### Remaining Gaps After 10B.3

- **Low:** Payout exists convenience REST endpoint (single route)
- **Low:** CLI-native product-gov commands (deferred to future phase)
- **Low:** REST handler Go unit tests (script-level smoke tests added)

## Phase 10B.4 Resolution

Phase 10B.4 closed remaining low gaps:

| Gap | Resolution | Evidence |
|---|---|---|
| Payout exists REST endpoint (low) | Added `GET /nexarail/payout/v1/payout/exists/{id}` in app.go | `app/app.go` |
| Status labels polish (low) | Smoke test and scripts updated with consistent PASS/FAIL/EXPECTED_NOT_FOUND/SKIP_DEFERRED/WARN/BLOCKED | `scripts/testnet/api-smoke-test.sh` |
| Rejection-message clarity (low) | Error messages improved: what failed, why, where evidence, rerun command | `product-gov.sh`, `run-product-flow-rehearsal.sh`, `api-smoke-test.sh`, `diagnose-agent-freeze.sh` |
| REST route documentation split (low) | `docs/api/REST_READBACK_ROUTES.md` + `docs/api/REST_READBACK_LIMITATIONS.md` created | `docs/api/` |

### Deferred Items

| Item | Reason | Future Phase |
|---|---|---|
| Escrow dispute suite | Dispute flow exists in keeper (BuyerWins/SellerWins/Settled/Rejected). Adding suite would require new proposal patterns and risk destabilising the passing full suite. No protocol functionality depends on harness coverage. | Future hardening |
| CLI-native product-gov commands | `product-gov.sh` already provides safe operator wrapper. Native CLI commands would be UX polish only; no protocol functionality depends on them. | Future polish |
| REST handler Go unit tests | Script-level smoke tests cover all endpoints. Go unit tests would duplicate coverage. | If/when REST handler package extracted |

### Final Gap Statement (End of Phase 10B)

The product-flow operator surface is complete. All medium gaps closed. The remaining items are either convenience features or explicitly deferred with documented scope. No product-flow operational gap remains.
