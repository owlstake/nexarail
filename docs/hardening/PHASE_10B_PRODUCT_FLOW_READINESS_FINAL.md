# Phase 10B — Product-Flow Readiness Final Report

**Date:** 2026-05-28 (Phase 10B.4 finalisation)
**Scope:** End-to-end product-flow operator surface readiness for NexaRail controlled testnet
**Boundary:** Agent testnet only. No mainnet. No external validators. No live-funds defaults.

## Phase Overview

Phase 10B hardened the product-flow operator surface across four sub-phases:

| Sub-phase | Focus | Result |
|---|---|---|
| 10B.0 | Rehearsal harness fix, timeout map, cleanup behavior | Suite pass with 469 pass / 0 fail |
| 10B.0.1 | Full-mode budget fix, resumable suite design | Full suite: 487 pass / 0 fail, 1102s |
| 10B.1 | Product-flow evidence review | Flow-by-flow proof table complete |
| 10B.2 | REST readback parity audit, governance UX plan, event coverage | Audit complete, gaps identified |
| 10B.3 | REST parity implementation, product-gov.sh, governance templates | REST parity ~97%, 3 medium gaps closed |
| 10B.4 | Payout exists endpoint, REST docs, polish, final report | Low gaps closed, final report |

## Harness Results

### Full Suite (Final)
- **Pass:** 487
- **Fail:** 0
- **Elapsed:** 1102s
- **Evidence:** `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/`

### Targeted Suite Results

| Suite | Pass | Fail | Status |
|---|---|---|---|
| Settlement | 181 | 0 | Complete |
| Escrow | 91 | 0 | Complete |
| Treasury | 155 | 0 | Complete |
| Payout | 133 | 0 | Complete |
| Semantic assertions | 36 | 0 | Complete |

## REST Parity

**35 of 36 gRPC query methods wired as REST endpoints (~97%).**

### New Endpoints (Phase 10B.3 + 10B.4)

| Route | Added In |
|---|---|
| `GET /nexarail/escrow/v1/escrow/{id}` | 10B.3 |
| `GET /nexarail/escrow/v1/escrows/by-buyer/{buyer}` | 10B.3 |
| `GET /nexarail/escrow/v1/escrows/by-seller/{seller}` | 10B.3 |
| `GET /nexarail/escrow/v1/escrows/by-merchant/{merchant}` | 10B.3 |
| `GET /nexarail/escrow/v1/escrow/exists/{id}` | 10B.3 |
| `GET /nexarail/settlement/v1/settlements/by-payer/{payer}` | 10B.3 |
| `GET /nexarail/payout/v1/payouts/by-merchant/{merchant}` | 10B.3 |
| `GET /nexarail/payout/v1/payouts/by-recipient/{recipient}` | 10B.3 |
| `GET /nexarail/payout/v1/payouts/by-initiator/{initiator}` | 10B.3 |
| `GET /nexarail/payout/v1/batch-payout/{id}` | 10B.3 |
| `GET /nexarail/payout/v1/batch-payouts` | 10B.3 |
| `GET /nexarail/treasury/v1/account/{id}` | 10B.3 |
| `GET /nexarail/treasury/v1/accounts` | 10B.3 |
| `GET /nexarail/treasury/v1/budget/{id}` | 10B.3 |
| `GET /nexarail/treasury/v1/budgets` | 10B.3 |
| `GET /nexarail/treasury/v1/grant/{id}` | 10B.3 |
| `GET /nexarail/treasury/v1/grants` | 10B.3 |
| `GET /nexarail/treasury/v1/spends` | 10B.3 |
| `GET /nexarail/payout/v1/payout/exists/{id}` | 10B.4 |

### API Smoke Test

- **Format:** PASS / EXPECTED_NOT_FOUND / FAIL / SKIP_DEFERRED / WARN / BLOCKED
- **Coverage:** All 35 REST endpoints tested
- **Empty state:** Returns empty arrays, not panic
- **Not-found:** Returns structured `{"error":"..."}` JSON

### REST Documentation

- `docs/api/REST_READBACK_ROUTES.md` — Complete route catalogue
- `docs/api/REST_READBACK_LIMITATIONS.md` — Scope and boundary notes

## product-gov Status

**Script:** `scripts/testnet/product-gov.sh` (822 lines)

- 13 commands: enable/disable escrow/settlement/treasury/payout live flags, settlement routing flags, show-live-flags
- Dry-run by default; `--confirm` required for execution
- Governance proposal path only; no authority bypass
- Dependency validation (burn routing → treasury routing → settlement live)
- Writes evidence JSON + flag snapshots
- CLI-native integration: **Deferred** — script covers all use cases

## Governance Evidence Indexing

**Script:** `scripts/testnet/index-governance-product-evidence.sh`

- Evidence classification: `direct_event` / `indirect_proposal_state` / `missing`
- Expected before/after values from proposal labels
- Related product flow tx discovery
- 22 proposals indexed in final run
- All final states: `PROPOSAL_STATUS_PASSED`

## Governance Templates

**Directory:** `rehearsals/validator-agents/governance/templates/`

- 12 JSON proposal templates for all product-flow governance actions
- All valid JSON, agent-testnet only, live flags default false

## Burn Supply Proof

- Total supply delta: **-2000 unxrl**
- Burn share: **2000 unxrl**
- Burner module delta: **0** (proving burn is from settlement routing, not module self-deal)

## Semantic Assertions

- **36 pass / 0 fail**
- Covers: expected state, balance, custody, funds-executed, funds-paid, and final live-flag assertions

## Verification

| Check | Result |
|---|---|
| `go mod tidy` | Pass |
| `go mod verify` | Pass |
| `go build ./...` | Pass |
| `go vet ./...` | Pass |
| `go test ./...` | All pass |
| `predeployment-check.sh` | 23/23 pass |
| Safety wording audit | PASS |

## Safety Wording Audit

**PASS** — All checked terms (decentralised, external validators, mainnet live, buy NXRL, token sale, investment, etc.) are negative, qualified, technical, or explicit prohibitions. No promotional/financial claims.

## Final Live Flags

All false (unchanged from genesis defaults):

```
settlement.live_enabled=false
settlement.treasury_routing_enabled=false
settlement.burn_routing_enabled=false
escrow.live_enabled=false
treasury.live_enabled=false
payout.live_enabled=false
```

## Deferred Items

| Item | Reason |
|---|---|
| Escrow dispute suite coverage | Dispute flow exists in keeper. Adding harness suite would require new proposal patterns and could destabilise full suite. No protocol dependency. |
| CLI-native product-gov commands | `product-gov.sh` covers all safe use cases. CLI commands would be UX polish only. |
| REST handler Go unit tests | Script-level smoke tests cover all endpoints. Package not yet extracted for unit test isolation. |
| External validator onboarding | Next phase. Not a product-flow gap. |

## GO/NO-GO Status

| Target | Status | Required For GO |
|---|---|---|
| Agent testnet runtime | **GO** | ✓ Product flows proven (487/0) |
| | | ✓ REST parity (35/36) |
| | | ✓ Governance UX helpers |
| | | ✓ Evidence indexing |
| | | ✓ Safety audit clean |
| | | ✓ Live flags all false |
| Public/external controlled testnet | **NO-GO** | ✗ External validators needed |
| | | ✗ Gentx collection needed |
| | | ✗ Final genesis needed |
| Mainnet | **NO-GO** | ✗ Not before controlled testnet |

## Evidence Paths

### Core Evidence
- `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/` — Full suite evidence
- `rehearsals/validator-agents/product-flows/evidence/` — All product-flow sub-suite evidence

### Documentation
- `docs/hardening/PHASE_10B0_REHEARSAL_HARNESS_FIX.md` — Harness fix report
- `docs/hardening/PHASE_10B01_FULL_MODE_BUDGET_FIX.md` — Budget fix report
- `docs/hardening/PHASE_10B1_PRODUCT_FLOW_EVIDENCE_REVIEW.md` — Evidence review
- `docs/hardening/PHASE_10B2_REST_READBACK_PARITY.md` — REST parity audit
- `docs/hardening/PHASE_10B2_GOVERNANCE_UX_PLAN.md` — Governance UX plan
- `docs/hardening/PHASE_10B3_REST_PARITY_PLAN.md` — REST parity implementation plan
- `docs/hardening/PHASE_10B3_OPERATOR_SURFACE_RESULTS.md` — 10B.3 results
- `docs/hardening/PHASE_10B3_SAFETY_WORDING_AUDIT.md` — Safety audit
- `docs/hardening/PHASE_10B_PRODUCT_FLOW_READINESS_FINAL.md` — This report
- `docs/hardening/PRODUCT_FLOW_GAPS.md` — Gap register
- `docs/hardening/PRODUCT_FLOW_EVENT_COVERAGE.md` — Event coverage
- `docs/hardening/PRODUCT_FLOW_CLI_API_USABILITY.md` — Usability review
- `docs/api/REST_READBACK_ROUTES.md` — REST route catalogue
- `docs/api/REST_READBACK_LIMITATIONS.md` — REST limitations
- `docs/testnet/PRODUCT_FLOW_EVIDENCE_INDEX.md` — Evidence index
- `docs/testnet/LAUNCH_GO_NO_GO_REVIEW.md` — Go/no-go review

### Scripts
- `scripts/testnet/run-product-flow-rehearsal.sh` — Harness
- `scripts/testnet/api-smoke-test.sh` — API smoke test
- `scripts/testnet/product-gov.sh` — Governance helper
- `scripts/testnet/index-governance-product-evidence.sh` — Evidence indexer
- `scripts/testnet/check-burn-supply-delta.sh` — Burn delta check
- `scripts/testnet/extract-product-flow-events.sh` — Event extraction
- `rehearsals/validator-agents/governance/templates/` — Governance templates
