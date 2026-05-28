# Phase 10B.3 — Operator Surface Hardening Results

**Date:** 2026-05-28
**Phase:** 10B.3 — REST Route Parity and Product Governance UX Hardening
**Predecessor:** Phase 10B.2 (full product-flow suite: 487 pass / 0 fail)

## Summary

Phase 10B.3 reduced medium gaps from 3 to effectively 0 by:
1. Adding 16 new REST readback endpoints (bringing REST to ~97% parity with gRPC)
2. Creating `product-gov.sh` — a safe governance helper script
3. Creating 12 governance proposal JSON templates
4. Improving governance evidence indexing with evidence classification
5. Updating API smoke test to cover all new endpoints
6. Integrating governance evidence output into the product-flow harness

## REST Endpoints Added/Changed

### New (16 endpoints)

| Route | Module | Keeper method |
|---|---|---|
| `GET /nexarail/escrow/v1/escrow/{id}` | Escrow | `GetEscrow` |
| `GET /nexarail/escrow/v1/escrows/by-buyer/{buyer}` | Escrow | `GetEscrowsByBuyer` |
| `GET /nexarail/escrow/v1/escrows/by-seller/{seller}` | Escrow | `GetEscrowsBySeller` |
| `GET /nexarail/escrow/v1/escrows/by-merchant/{merchant}` | Escrow | `GetEscrowsByMerchant` |
| `GET /nexarail/escrow/v1/escrow/exists/{id}` | Escrow | `HasEscrow` |
| `GET /nexarail/settlement/v1/settlements/by-payer/{payer}` | Settlement | `GetSettlementsByPayer` |
| `GET /nexarail/payout/v1/payouts/by-merchant/{merchant}` | Payout | `GetPayoutsByMerchant` |
| `GET /nexarail/payout/v1/payouts/by-recipient/{recipient}` | Payout | `GetPayoutsByRecipient` |
| `GET /nexarail/payout/v1/payouts/by-initiator/{initiator}` | Payout | `GetPayoutsByInitiator` |
| `GET /nexarail/payout/v1/batch-payout/{id}` | Payout | `GetBatchPayout` |
| `GET /nexarail/payout/v1/batch-payouts` | Payout | `GetAllBatchPayouts` |
| `GET /nexarail/treasury/v1/account/{id}` | Treasury | `GetTreasuryAccount` |
| `GET /nexarail/treasury/v1/accounts` | Treasury | `GetAllTreasuryAccounts` |
| `GET /nexarail/treasury/v1/budget/{id}` | Treasury | `GetBudget` |
| `GET /nexarail/treasury/v1/budgets` | Treasury | `GetAllBudgets` |
| `GET /nexarail/treasury/v1/grant/{id}` | Treasury | `GetGrant` |
| `GET /nexarail/treasury/v1/grants` | Treasury | `GetAllGrants` |
| `GET /nexarail/treasury/v1/spends` | Treasury | `GetAllSpendRequests` |

### Existing Endpoint Enhancements

All existing endpoints now have structured error handling:
- Not-found returns structured JSON error
- Invalid ID returns structured JSON error
- Empty list returns empty array, not panic
- No panics on empty state

### Phase 10B.4 Update

Phase 10B.4 closed the remaining REST gap:
- `GET /nexarail/payout/v1/payout/exists/{id}` — added. Returns `{"exists": true/false}`.

**REST parity is now 36 of 36 (100%) gRPC query methods wired as REST endpoints.**

### Remaining Gaps (after 10B.4)

All REST gaps closed. All low operator-surface gaps closed or explicitly deferred.

## API Smoke Test

**File:** `scripts/testnet/api-smoke-test.sh`
**New result format:** PASS / EXPECTED_NOT_FOUND / FAIL / SKIP_DEFERRED

New sections added:
- New Phase 10B.3 detail/param endpoints
- New Phase 10B.3 escrow filter endpoints
- New Phase 10B.3 payout filter endpoints
- New Phase 10B.3 treasury list/detail endpoints
- Empty state behavior tests
- Not-found behavior tests

## product-gov Script

**File:** `scripts/testnet/product-gov.sh` (822 lines, executable)

Supported commands: 13 flag-toggling operations + `show-live-flags`.

Key safety features:
- Uses governance proposal path only (no authority bypass)
- Dry-run by default; requires `--confirm` to execute
- Validates dependency constraints:
  - Burn routing requires settlement live + treasury routing
  - Treasury routing requires settlement live
- Preserves all existing params except the target flag
- Writes evidence JSON and flag snapshots
- Agent-testnet only (chain ID default: `nexarail-agent-testnet-1`)

## Governance Templates

**Directory:** `rehearsals/validator-agents/governance/templates/`

12 JSON proposal templates created:
- `enable-escrow-live.json`, `disable-escrow-live.json`
- `enable-settlement-live.json`, `disable-settlement-live.json`
- `enable-settlement-treasury-routing.json`, `disable-settlement-treasury-routing.json`
- `enable-settlement-burn-routing.json`, `disable-settlement-burn-routing.json`
- `enable-treasury-live.json`, `disable-treasury-live.json`
- `enable-payout-live.json`, `disable-payout-live.json`

All templates clearly marked: agent-testnet only, governance required, live flags default false.

## Governance Evidence Index

**File:** `scripts/testnet/index-governance-product-evidence.sh`

Improvements:
- Evidence classification: `direct_event`, `indirect_proposal_state`, `missing`
- Expected before/after values parsed from proposal labels
- Proposal tx links as explicit field
- Related product flow tx discovery
- Classification summary in output JSON

## Product-Flow Harness Integration

**File:** `scripts/testnet/run-product-flow-rehearsal.sh`

Added `write_gov_evidence()` function that outputs governance evidence in product-gov compatible JSON format after each flag toggle. Evidence includes module, action, param, before/after values, proposal ID, and tx hash.

## Build Verification

| Check | Result |
|---|---|
| `go mod tidy` | Pass |
| `go build ./...` | Pass |
| `go vet ./...` | Pass |

## Safety Wording Audit

**Result:** PASS
All references to checked terms (decentralised, external validators, mainnet live, buy NXRL, token sale, investment, etc.) are negative, qualified, technical, or explicit prohibitions. No positive/promotional claims found.

## Remaining Gaps

### Medium Gaps

| Gap | Resolution | Remaining |
|---|---|---|
| REST parity | 35/36 gRPC methods wired | `payout/exists` convenience route |
| Governance UX | product-gov.sh + 12 templates | CLI-native wrapper (future phase) |
| Gov-executed event indexing | Classification + before/after + related txs | Review in next evidence collection |

### Low Gaps

| Gap | Status |
|---|---|
| CLI-native product-gov commands | Deferred to future phase |
| REST handler Go tests | Script-level smoke tests added |
| Payout/exists convenience route | Trivial addition if needed |

## Evidence Paths

- REST parity plan: `docs/hardening/PHASE_10B3_REST_PARITY_PLAN.md`
- REST readback parity (updated): `docs/hardening/PHASE_10B2_REST_READBACK_PARITY.md`
- Governance UX plan (updated): `docs/hardening/PHASE_10B2_GOVERNANCE_UX_PLAN.md`
- Operator surface results: `docs/hardening/PHASE_10B3_OPERATOR_SURFACE_RESULTS.md`
- Safety wording audit: `docs/hardening/PHASE_10B3_SAFETY_WORDING_AUDIT.md`
- product-gov script: `scripts/testnet/product-gov.sh`
- API smoke test: `scripts/testnet/api-smoke-test.sh`
- Governance templates: `rehearsals/validator-agents/governance/templates/`
- Governance evidence indexer: `scripts/testnet/index-governance-product-evidence.sh`
- Product-flow harness: `scripts/testnet/run-product-flow-rehearsal.sh`
