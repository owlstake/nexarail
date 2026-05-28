# Product Flow Evidence Index

**Date:** 2026-05-28  
**Scope:** Phase 10B product-flow rehearsal evidence  
**Primary evidence root:** `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/`  
**Result:** `487 pass / 0 fail`, elapsed `1102s`

## Top-Level Files

| Artifact | Path |
|---|---|
| Run log | `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/run.log` |
| Summary JSON | `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/summary.json` |
| Summary text | `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/summary.txt` |
| Stage durations | `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/stage-durations.tsv` |
| Final live flags | `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/final-live-flags.json` |
| Descriptor scan | `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/descriptor-errors.txt` |
| Semantic assertions | `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/semantic-assertions.json`, `.md` |
| Event summary | `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/event-summary.json`, `.md` |
| Governance evidence index | `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/governance-product-evidence.json`, `.md` |
| Burn supply delta | `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/burn-supply-delta.json`, `.md` |
| Environment | `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/env.txt` |
| Address map | `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/address-map.txt` |
| Genesis checksum | `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/genesis-checksum.txt` |
| Clean spawn proof | `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/clean-spawn-proof.txt` |

## Runtime Logs And Diagnostics

| Artifact | Path |
|---|---|
| Validator logs | `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/logs/` |
| Final stop diagnostics | `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/diagnostics/stop-after/` |
| Process snapshots | `ps-before.txt`, `ps-after.txt`, `pgrep-before.txt`, `pgrep-after.txt` |
| Port snapshots | `lsof-before.txt`, `lsof-after.txt`, `port-check-before.txt`, `port-check-after.txt` |

## Flow Evidence

| Flow | Primary evidence directory | Important artifacts |
|---|---|---|
| Smoke bank tx | `txs/smoke-bank-send/` | `txhash.txt`, `included-tx.json`, `queries/smoke-charlie-balance.json` |
| Merchant onboarding | `merchant/` | `register/`, `update/`, `query-merchant.json`, `query-merchants.json`, `set-inactive/`, `set-active/`, rejection artifacts |
| Settlement metadata | `settlement/metadata/` | `create/`, `settlement-1.json`, `settlements.json`, `by-merchant.json`, balance deltas |
| Settlement live | `settlement/live/` | `create/`, `settlement-2.json`, balance deltas, live enable/disable gov artifacts |
| Settlement treasury routing | `settlement/treasury-routing/` | `create/`, `settlement-3.json`, merchant and treasury deltas, routing gov artifacts |
| Settlement burn routing | `settlement/burn-routing/` | `create/`, `settlement-4.json`, merchant and treasury deltas, supply/burner deltas, burn event in included tx |
| Escrow | `escrow/` | `create-release/`, `release/`, `create-refund/`, `refund/`, `create-cancel/`, `cancel/`, `escrows.json`, balance deltas |
| Treasury | `treasury/` | `create-account/`, `create-budget/`, `create-spend/`, `approve-execute-spend/`, `spend-query.json`, `treasury-summary.json`, balance deltas |
| Payout | `payout/` | `fund-recipient/`, `register-recipient-merchant/`, `create/`, `approve/`, `mark-paid/`, `payout-query.json`, `payouts.json`, balance deltas |
| Safety | `safety/` | `unauthorized-settlement-params/`, `failed-transfer-payout/`, `module-state/`, `pre-final-flags/` |
| Final state | `final-state/` | `live-flags.txt`, module params, final module state snapshots |

## Phase 10B.2 Targeted Suite Evidence

| Suite | Evidence root | Result |
|---|---|---|
| Settlement | `rehearsals/validator-agents/product-flows/evidence/20260528T000636Z/` | `181 pass / 0 fail`, elapsed `398s` |
| Escrow | `rehearsals/validator-agents/product-flows/evidence/20260528T002058Z/` | `91 pass / 0 fail`, elapsed `261s` |
| Treasury | `rehearsals/validator-agents/product-flows/evidence/20260528T002534Z/` | `155 pass / 0 fail`, elapsed `426s` |
| Payout | `rehearsals/validator-agents/product-flows/evidence/20260528T003258Z/` | `133 pass / 0 fail`, elapsed `370s` |

## Governance Evidence

Governance proposal artifacts live under `gov/` and selected module directories. Each proposal directory contains:

- `proposal-id.txt`
- `proposal-status-latest.txt`
- `proposal-final-status.json`
- `submit-tx.json`
- `txhash.txt`
- `vote-tx-hashes.txt`
- signed/unsigned proposal artifacts

Proposal IDs used in the full suite:

| Area | Proposal IDs |
|---|---|
| Merchant status | `1`, `2` |
| Settlement live/routing | `3`, `4`, `5`, `6`, `7`, `8` |
| Escrow live | `9`, `10` |
| Treasury live/account/budget/spend | `11`, `12`, `13`, `14`, `15` |
| Payout live/paid | `16`, `17`, `18` |
| Final restore false | `19`, `20`, `21`, `22` |

## Final Live Flags

`final-live-flags.json` readback:

- `settlement.live_enabled=false`
- `settlement.treasury_routing_enabled=false`
- `settlement.burn_routing_enabled=false`
- `escrow.live_enabled=false`
- `treasury.live_enabled=false`
- `payout.live_enabled=false`

## Related Review Documents

- `docs/hardening/PHASE_10B1_PRODUCT_FLOW_EVIDENCE_REVIEW.md`
- `docs/hardening/PHASE_10B2_REST_READBACK_PARITY.md`
- `docs/hardening/PHASE_10B2_GOVERNANCE_UX_PLAN.md`
- `docs/hardening/PHASE_10B3_REST_PARITY_PLAN.md`
- `docs/hardening/PHASE_10B3_OPERATOR_SURFACE_RESULTS.md`
- `docs/hardening/PHASE_10B3_SAFETY_WORDING_AUDIT.md`
- `docs/hardening/PRODUCT_FLOW_GAPS.md`
- `docs/hardening/PRODUCT_FLOW_EVENT_COVERAGE.md`
- `docs/hardening/PRODUCT_FLOW_CLI_API_USABILITY.md`
- `docs/hardening/PHASE_10B01_FULL_MODE_BUDGET_FIX.md`

## Phase 10B.3 Update

Phase 10B.3 added:
- REST parity improved to ~97% (16 new endpoints, 35/36 gRPC methods wired)
- `scripts/testnet/product-gov.sh` — safe governance helper
- `scripts/testnet/index-governance-product-evidence.sh` — improved with evidence classification, before/after values
- `rehearsals/validator-agents/governance/templates/` — 12 governance JSON templates

## Boundary

This index covers local 5-agent product-flow rehearsal evidence. It does not index external validator evidence because external validators and external gentxs remain pending.
