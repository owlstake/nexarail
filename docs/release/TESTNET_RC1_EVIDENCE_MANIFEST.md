# NexaRail Controlled Testnet RC1 — Evidence Manifest

This document indexes all validation evidence supporting the Controlled Testnet RC1 release. Each entry includes a description, the canonical file path, and verification status.

---

## Evidence Items

### 1. Phase 9T Clean-Spawn Governance Evidence

| Field | Value |
|---|---|
| **Description** | Evidence from the Phase 9T rehearsal demonstrating clean-spawn governance operations. Validates that governance proposals can be created, voted on, and executed in a freshly spawned validator-agent environment. |
| **Path** | `rehearsals/validator-agents/clean-spawn-governance/` |
| **Verification Status** | ✅ Verified — Clean-spawn governance flow validated |

---

### 2. Phase 9U Long Soak Evidence

| Field | Value |
|---|---|
| **Description** | Evidence from the Phase 9U long-duration soak test. Validates that the validator-agent infrastructure remains stable over extended operational periods without degradation, memory leak, or state inconsistency. |
| **Path** | `rehearsals/validator-agents/long-soak/` |
| **Verification Status** | ✅ Verified — Long-duration stability confirmed |

---

### 3. Phase 9V Restart Evidence

| Field | Value |
|---|---|
| **Description** | Evidence from the Phase 9V restart investigation. Validates that validator-agent processes can be cleanly restarted without data loss, state corruption, or consensus disruption. |
| **Path** | `rehearsals/validator-agents/restart-investigation/` |
| **Verification Status** | ✅ Verified — Restart safety confirmed |

---

### 4. Phase 9W Agent Runtime Readiness

| Field | Value |
|---|---|
| **Description** | Formal readiness report assessing the validator-agent runtime for testnet deployment. Covers agent lifecycle, error handling, logging, and operational readiness criteria. |
| **Path** | `docs/testnet/PHASE_9W_AGENT_RUNTIME_READINESS_REPORT.md` |
| **Verification Status** | ✅ Verified — Agent runtime deemed ready for controlled testnet |

---

### 5. Phase 10B Full Product-Flow Evidence

| Field | Value |
|---|---|
| **Description** | Comprehensive evidence directory from the Phase 10B product-flow validation campaign. Contains test run artifacts, logs, and result summaries for all product-flow scenarios (settlement, escrow, treasury, payout). |
| **Path** | `rehearsals/validator-agents/product-flows/evidence/` |
| **Verification Status** | ✅ Verified — 487/487 product-flow tests passed |

---

### 6. Phase 10B.2 Product-Flow Evidence (2026-05-28)

| Field | Value |
|---|---|
| **Description** | Targeted evidence subdirectory from the Phase 10B.2 iteration, timestamped 2026-05-28T00:39:25Z. Represents the final run confirming all product flows before RC1 freeze. |
| **Path** | `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/` |
| **Verification Status** | ✅ Verified — Final iteration passed, no regressions |

---

### 7. Phase 10B.4 Final Product-Flow Readiness Report

| Field | Value |
|---|---|
| **Description** | The conclusive readiness report for Phase 10B product-flow validation. Documents the methodology, coverage, results (487/487 pass), and sign-off for RC1 release qualification. |
| **Path** | `docs/hardening/PHASE_10B_PRODUCT_FLOW_READINESS_FINAL.md` |
| **Verification Status** | ✅ Verified — All product flows certified ready |

---

### 8. REST API Documentation

| Field | Value |
|---|---|
| **Description** | API documentation covering the 36 REST readback endpoints operational in this release, along with documented limitations of the readback-only architecture. |
| **Path** | `docs/api/REST_READBACK_ROUTES.md`, `docs/api/REST_READBACK_LIMITATIONS.md` |
| **Verification Status** | ✅ Verified — 36/36 endpoints documented, limitations noted |

---

### 9. Predeployment Check Outputs

| Field | Value |
|---|---|
| **Description** | Output from the automated predeployment checklist script. Validates binary integrity, chain configuration, genesis parameters, and environment readiness prior to node launch. |
| **Path** | `scripts/testnet/predeployment-check.sh` |
| **Verification Status** | ✅ Verified — 23/23 checks passed |

---

### 10. Live Flags — All False

| Field | Value |
|---|---|
| **Description** | Confirmation that all live-network genesis flags are set to `false` by default. This is documented across all Phase 10B reports and verified prior to RC1 tagging. No deployment will interact with real economic value. |
| **Path** | Documented in all Phase 10B reports (see items 5–7 above) |
| **Verification Status** | ✅ Verified — All live flags default `false` |

---

### 11. Governance Templates (12 Valid)

| Field | Value |
|---|---|
| **Description** | Twelve validated governance templates covering proposal types required for product governance on the NexaRail network. Includes parameter-change, software-upgrade, and product-configuration templates with correct formatting and metadata. |
| **Path** | `rehearsals/validator-agents/governance/templates/` |
| **Verification Status** | ✅ Verified — 12 templates valid and ready for use |

---

### 12. Safety Wording Audit

| Field | Value |
|---|---|
| **Description** | Audit of all user-facing messaging, CLI descriptions, and documentation for safe, clear language that does not imply mainnet readiness, token value, or financial guarantees. |
| **Path** | `docs/hardening/PHASE_10B3_SAFETY_WORDING_AUDIT.md` |
| **Verification Status** | ✅ PASS — All wording deemed compliant and safe |

---

## Summary

| # | Item | Status |
|---|---|---|
| 1 | Phase 9T Clean-Spawn Governance | ✅ Verified |
| 2 | Phase 9U Long Soak | ✅ Verified |
| 3 | Phase 9V Restart | ✅ Verified |
| 4 | Phase 9W Agent Runtime Readiness | ✅ Verified |
| 5 | Phase 10B Full Product-Flow Evidence | ✅ Verified (487/487) |
| 6 | Phase 10B.2 Evidence (2026-05-28) | ✅ Verified |
| 7 | Phase 10B.4 Final Report | ✅ Verified |
| 8 | REST API Documentation | ✅ Verified (36/36) |
| 9 | Predeployment Check Outputs | ✅ Verified (23/23) |
| 10 | Live Flags All False | ✅ Verified |
| 11 | Governance Templates | ✅ Verified (12 valid) |
| 12 | Safety Wording Audit | ✅ PASS |

---

*End of evidence manifest.*
