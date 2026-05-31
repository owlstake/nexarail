# NexaRail Audit Package Index

**Document:** docs/audit/AUDIT_PACKAGE_INDEX.md
**Date:** 2026-05-25
**Purpose:** Index for external security auditors

## Repo Overview

| Item | Value |
|---|---|
| Project | NexaRail Network |
| Type | Sovereign Cosmos SDK Layer 1 |
| SDK version | v0.47.17 |
| Consensus | CometBFT v0.37.18 |
| Language | Go 1.22+ |
| Module count | 16 SDK + 6 custom |

## Module List

### Standard Cosmos SDK Modules
auth, bank, staking, slashing, gov, distribution, mint, params, crisis, upgrade, evidence, feegrant, authz, capability, vesting, genutil

### Custom NexaRail Modules

| Module | Path | Purpose | Live Funds? |
|---|---|---|---|
| x/fees | `x/fees/` | Fee split parameters (60/20/20 bps) | Policy only |
| x/merchant | `x/merchant/` | Merchant registration + tiers | N/A |
| x/settlement | `x/settlement/` | Payment settlement + fee routing | Yes — behind 3 flags |
| x/escrow | `x/escrow/` | Escrow custody | Yes — behind 1 flag |
| x/payout | `x/payout/` | Payout execution | Yes — behind 1 flag |
| x/treasury | `x/treasury/` | Treasury accounts + spend execution | Yes — behind 1 flag |

## Live Funds Flags

All default to **false**. See `docs/design/LIVE_FLAGS_MATRIX.md`.

| Module | Flag | Controls |
|---|---|---|
| x/escrow | LiveEnabled | Escrow custody |
| x/treasury | LiveEnabled | Spend execution |
| x/payout | LiveEnabled | Payout execution |
| x/settlement | LiveEnabled | Merchant-net transfer |
| x/settlement | TreasuryRoutingEnabled | Treasury-share routing |
| x/settlement | BurnRoutingEnabled | Burn-share routing + BurnCoins |

## Module Accounts

| Account | Permission | Used By |
|---|---|---|
| nexarail_escrow | nil | x/escrow |
| nexarail_treasury | nil | x/treasury, x/payout, x/settlement |
| nexarail_burner | {authtypes.Burner} | x/settlement (burn) |
| nexarail_fee_router | nil | Unused (deferred) |

All are in `blockedAddrs`. See `app/app.go` line ~220.

## Threat Models

| Document | Scope |
|---|---|
| `docs/security/LIVE_FUNDS_THREAT_MODEL.md` | General live funds (Phase 5B) |
| `docs/security/SETTLEMENT_LIVE_THREAT_MODEL.md` | Settlement merchant-net (Phase 5F.1) |
| `docs/security/SETTLEMENT_TREASURY_FEE_THREAT_MODEL.md` | Settlement treasury routing (Phase 5F.3) |
| `docs/security/SETTLEMENT_BURN_THREAT_MODEL.md` | Settlement burn routing (Phase 5F.5) |
| `docs/security/VALIDATOR_DISTRIBUTION_THREAT_MODEL.md` | Validator distribution (deferred) |
| `docs/security/PHASE_5_AUDIT_PREP.md` | Consolidated audit prep with questions |
| `docs/security/PHASE_3_THREAT_REVIEW.md` | Pre-live-funds state machine audit |

## Invariants

| Document | Scope |
|---|---|
| `docs/design/INVARIANTS.md` | All module invariants |
| Escrow: `ActiveCustodiedEscrowTotals`, `ValidateCustodyInvariant` | `x/escrow/keeper/keeper.go` |
| Treasury: `ActiveExecutedSpendTotals`, `ValidateSpendInvariant` | `x/treasury/keeper/keeper.go` |
| Payout: `ActivePaidPayoutTotals`, `ValidatePayoutFundsInvariant` | `x/payout/keeper/keeper.go` |
| Settlement: `ActiveSettledTotals`, `ValidateSettlementFundsInvariant` | `x/settlement/keeper/keeper.go` |

## Test Commands

```bash
cd ~/workspace/nexarail
go mod tidy && go mod verify
go build ./...
go vet ./...
go test ./...                              # all packages
go test ./x/settlement/keeper/... -v       # settlement-specific
go test ./x/escrow/keeper/... -v           # escrow-specific
go test ./app/... -v -run TestModuleAccount # app integration
```

Expected: 14 packages, ~332 tests, all pass.

## Known Limitations

See `docs/LIMITATIONS.md`.

- Validator distribution deferred (Phase 5F.7 design only)
- Fee router unused
- BeginBlock routing not implemented
- Stablecoin / bridge not built
- Multi-denom settlements not supported
- No external security audit yet
- Testnet only — mainnet not ready

## Deferred Features

See `docs/PHASE_5_LIVE_FUNDS_STATUS.md`.

## High-Risk Files

| File | Risk |
|---|---|
| `x/settlement/keeper/keeper.go:CreateSettlement` | Multi-transfer flow (merchant + treasury + burn) |
| `x/escrow/keeper/keeper.go` | Custody lifecycle, dispute resolution |
| `x/settlement/keeper/keeper.go:BurnCoins` call | Irreversible supply reduction |
| `app/app.go:maccPerms` | Module account permissions |

## Questions for Auditors

1. Are all `bank.SendCoins*` calls gated by correct status checks?
2. Can any live transfer be triggered with `LiveEnabled=false`?
3. Is the transfer-before-state-mutation pattern consistent across all modules?
4. Can `BurnCoins` be called with a non-burner module account?
5. Can governance enable all flags and drain treasury/escrow in one block?
6. Are supply invariants maintained after progressive settlement transfers?
7. Is double-execution prevented for escrow release, treasury spend, and payout pay?
8. Are all module accounts correctly blocked from direct user sends?
9. Can a failed intermediate transfer leave inconsistent state?

---

## Phase 8D Updates (2026-05-26)

### Audit Package Final
- `docs/audit/PHASE_8D_AUDIT_PACKAGE_FINAL.md` — Complete project overview for auditors
- `docs/security/PHASE_8D_SECURITY_REVIEW.md` — 15-category security review
- `docs/security/THREAT_REGISTER.md` — 20-entry threat register with severity/status

### Hardening Docs
- `docs/hardening/PHASE_8A_API_ROUTE_AUDIT.md` — API route audit (Phase 8A)
- `docs/hardening/RUNTIME_CONFIG_HARDENING.md` — Runtime config hardening (Phase 8A)
- `docs/hardening/CLI_E2E_TESTING.md` — CLI test coverage (Phase 8A)
- `docs/hardening/API_SMOKE_TESTING.md` — API test coverage (Phase 8A)
- `docs/hardening/PHASE_8B_TEST_GAP_AUDIT.md` — Test gap audit (Phase 8B)
- `docs/hardening/TEST_COVERAGE_MATRIX.md` — Coverage matrix (Phase 8B)
- `docs/hardening/LIVE_FUNDS_TEST_COVERAGE.md` — Live funds coverage (Phase 8B)
- `docs/hardening/API_CLI_TEST_COVERAGE.md` — API/CLI coverage (Phase 8B)
- `docs/hardening/PHASE_8C_INTEGRATION_TEST_PLAN.md` — Integration plan (Phase 8C)
- `docs/hardening/MULTI_MODULE_FLOW_COVERAGE.md` — Flow coverage (Phase 8C)
- `docs/hardening/RUNTIME_HARNESS_TESTING.md` — Harness approach (Phase 8C)
- `docs/hardening/PERFORMANCE_BASELINES.md` — Benchmarks (Phase 8C)
- `docs/hardening/PHASE_8D_PRE_DEPLOYMENT_REVIEW.md` — Pre-deployment review (Phase 8D)

### Release Docs
- `docs/release/CONTROLLED_TESTNET_RELEASE_CHECKLIST.md` — 49-gate release checklist
- `docs/release/RELEASE_TAGGING_AND_CHECKSUMS.md` — Release procedures
- `docs/release/CHANGE_CONTROL_POLICY.md` — Change control policy

### Phase 9M Docs
- `docs/testnet/PHASE_9M_TX_SERVICE_BROADCAST_ANALYSIS.md` — Tx service endpoint analysis
- `docs/testnet/PHASE_9M_TX_SERVICE_BROADCAST_RESULTS.md` — Phase 9M results
- `docs/testnet/VALIDATOR_AGENT_GOVERNANCE_RESULTS.md` — Governance results summary

### Phase 9U Docs
- `docs/testnet/PHASE_9U_LONG_SOAK_PLAN.md` — Long soak and restart test plan
- `docs/testnet/PHASE_9U_LONG_SOAK_RESULTS.md` — 60-minute clean-spawn soak results and reuse-data restart classification
- `docs/testnet/AGENT_TESTNET_DATA_POLICY.md` — Local agent data wipe/reuse policy

### Phase 9V Docs
- `docs/testnet/PHASE_9V_RESTART_INVESTIGATION_PLAN.md` — Restart failure hypotheses, matrix, and risk classification
- `docs/testnet/PHASE_9V_RESTART_PANIC_ANALYSIS.md` — Phase 9U proposal panic analysis and diagnosis
- `docs/testnet/PHASE_9V_RESTART_RESULTS.md` — Restart matrix, root cause, fix, and evidence summary

### Phase 9W Docs
- `docs/testnet/PHASE_9W_AGENT_RUNTIME_READINESS_REPORT.md` — Consolidated agent-testnet runtime readiness report covering block production, readback, tx inclusion, governance, long soak, and restart recovery
- `docs/testnet/AGENT_TESTNET_EVIDENCE_INDEX.md` — Index of Phase 9T, 9U, and 9V evidence paths, tx hashes, proposal IDs, vote tx hashes, genesis checksums, and final live flags
- `docs/testnet/AGENT_TESTNET_LIMITATIONS.md` — Boundary document clarifying that local agent validators are not external validators and do not prove external decentralisation
- `docs/testnet/CONTROLLED_TESTNET_NEXT_STEPS.md` — External validator cohort, multi-machine/Linux rehearsal, final genesis, release/checksum, endpoint, communications, audit, and legal next steps

### Scripts (Phase 9M additions)
- `scripts/testnet/broadcast-proto-tx.sh` — Proto tx broadcast helper (comet/grpc)
- `scripts/testnet/offline-tx-pipeline.sh` — Full offline tx pipeline (3 broadcast modes)
- `scripts/testnet/validator-agent-governance-test.sh` — Updated gov test (proto broadcast)

### Scripts (Phase 9U updates)
- `scripts/testnet/run-agent-soak-test.sh` — Long-soak status, resource, and periodic readback collector
- `scripts/testnet/agent-soak-summary.sh` — Long-soak evidence summariser

### Scripts (Phase 9V updates)
- `scripts/testnet/restart-agent-matrix.sh` — Restart matrix covering single, 3-agent, 5-agent, post-soak, one-node, all-node, sequential, and direct restart paths
- `scripts/testnet/spawn-validator-agents.sh` — Added `--agent-count` for controlled restart matrix cases
- `scripts/testnet/stop-validator-agents.sh` — No-op stop now succeeds when no agents are running

### Phase 10B Product-Flow Harness Hardening
- `docs/hardening/PHASE_10B0_REHEARSAL_HARNESS_FIX.md` — Product-flow rehearsal harness hardening report, timeout map, cleanup behavior, smoke results, full-mode blocker, and evidence paths
- `docs/hardening/PHASE_10B01_FULL_MODE_BUDGET_FIX.md` — Full-mode budget fix, resumable suite design, timeout policy, and final full-suite evidence
- `docs/hardening/PHASE_10B1_PRODUCT_FLOW_EVIDENCE_REVIEW.md` — Flow-by-flow proof table for the successful full local product-flow rehearsal
- `docs/hardening/PHASE_10B2_REST_READBACK_PARITY.md` — REST readback parity audit for product-flow operator surfaces
- `docs/hardening/PHASE_10B2_GOVERNANCE_UX_PLAN.md` — Governance-controlled product action operator UX plan
- `docs/hardening/PRODUCT_FLOW_EVENT_COVERAGE.md` — Product event coverage and governance-execution event gap review
- `docs/hardening/PRODUCT_FLOW_CLI_API_USABILITY.md` — CLI, REST, gRPC, and script-only operator surface review
- `docs/hardening/PRODUCT_FLOW_GAPS.md` — Product-flow gap register; 900s timeout blocker, burn supply-delta gap, JSON query semantics gap, and event-summary gap closed
- `docs/testnet/PRODUCT_FLOW_EVIDENCE_INDEX.md` — Index of Phase 10B product-flow evidence artifacts
- `scripts/testnet/run-product-flow-rehearsal.sh` — Added smoke/full modes, force-clean/no-spawn/keep-running options, `--suite`, `--resume-from`, `--global-timeout`, evidence-first logging, traps, stage timeouts, result-event accounting, stage durations, summary JSON, and final diagnostics
- `scripts/testnet/diagnose-agent-freeze.sh` — New non-interactive freeze diagnostic collector
- `scripts/testnet/spawn-validator-agents.sh` — Added force-clean, no-tmux, evidence-dir, stale process/port checks, RPC/gRPC readiness, height advancement, and validator-set checks
- `scripts/testnet/stop-validator-agents.sh` — Hardened validator-agent-only cleanup with force/evidence support
- `scripts/testnet/check-agent-data-clean.sh` — Expanded stale data guard with JSON/evidence output
- `scripts/testnet/extract-product-flow-events.sh` — Extracts grouped product, bank, burn, governance, and live-flag event summaries from evidence directories
- `scripts/testnet/index-governance-product-evidence.sh` — Indexes proposal IDs, submit txs, votes, final proposal states, expected effects, and readback proof
- `scripts/testnet/check-burn-supply-delta.sh` — Checks burn-routing supply delta, burner module balance, payer balance, and settlement burn-share evidence

### Phase 10B.3 — REST Parity and Governance UX Hardening
- `docs/hardening/PHASE_10B3_REST_PARITY_PLAN.md` — REST endpoint-by-endpoint parity audit (post-10B.3: 35/36 wired)
- `docs/hardening/PHASE_10B3_OPERATOR_SURFACE_RESULTS.md` — Operator surface hardening results
- `docs/hardening/PHASE_10B3_SAFETY_WORDING_AUDIT.md` — Safety wording audit (PASS)
- `scripts/testnet/product-gov.sh` — Safe governance helper script (822 lines)
- `scripts/testnet/api-smoke-test.sh` — Updated with PASS/EXPECTED_NOT_FOUND/FAIL/SKIP_DEFERRED classification and 18 new endpoint tests
- `scripts/testnet/index-governance-product-evidence.sh` — Improved with evidence classification
- `rehearsals/validator-agents/governance/templates/` — 12 JSON proposal templates
- `scripts/testnet/run-product-flow-rehearsal.sh` — Updated with governance evidence integration

### Phase 10B.4 — Product-Flow Operator Surface Finalisation
- `docs/hardening/PHASE_10B_PRODUCT_FLOW_READINESS_FINAL.md` — Complete product-flow readiness report
- `docs/api/REST_READBACK_ROUTES.md` — REST route catalogue (all 36 endpoints)
- `docs/api/REST_READBACK_LIMITATIONS.md` — REST scope and limitations
- `scripts/testnet/api-smoke-test.sh` — Updated with payout exists endpoint and consistent labels
- `scripts/testnet/product-gov.sh` — Updated with improved error messages
- `scripts/testnet/run-product-flow-rehearsal.sh` — Updated with improved stage error messages and rerun guidance

### Phase 16C — Local Five-Agent Load Simulation
- `docs/testnet/PHASE_16C_LOAD_SIMULATION_PLAN.md` — Local bank tx/query load plan, success criteria, metrics, and safety constraints
- `docs/testnet/PHASE_16C_LOAD_SIMULATION_RESULTS.md` — Smoke, 10-minute, and heavier local load results with evidence paths
- `scripts/testnet/run-five-agent-load-sim.sh` — Controlled five-agent local load runner with tx/query metrics, health checks, live-flag readback, log scans, and cleanup

### Phase 16D/16E — Trend Profiling and RC2 Evidence Rollup
- `docs/testnet/PHASE_16D_TREND_LIMIT_PROFILING_PLAN.md` — Local trend/load-level plan and interpretation rules
- `scripts/testnet/sample-agent-resources.sh` — Local per-agent process/resource sampler
- `scripts/testnet/run-load-trend-profile.sh` — Sequential local load-level trend runner
- `docs/release/RC2_DECISION_CRITERIA.md` — RC2 evidence criteria and decision options
- `docs/release/POST_RC1_HARDENING_EVIDENCE_ROLLUP.md` — Phase 14B through 16D evidence summary
- `docs/release/RC2_RECOMMENDATION.md` — RC2 preparation/defer recommendation
- `docs/release/RC2_RELEASE_CHECKLIST.md` — RC2 release checklist
- `docs/release/GITHUB_RELEASE_V0.1.1_RC2_DRAFT.md` — Draft RC2 release notes
- `docs/release/RC1_TO_RC2_COMPARISON.md` — RC1-to-RC2 comparison
- `scripts/release/check-rc2-readiness.sh` — Local RC2 readiness checker

### Phase 17A — Controlled External-Validator Testnet Launch Candidate
- `docs/testnet/PHASE_17A_CONTROLLED_TESTNET_LAUNCH_PLAN.md` — Launch objective, chain ID, source-build path, gentx collection, genesis assembly, persistent peers, timeline, coordinator/validator duties, rollback, and safety boundary
- `docs/testnet/VALIDATOR_INTAKE_TEMPLATE.md` — Validator intake fields and testnet-only acknowledgement
- `docs/testnet/CONTROLLED_TESTNET_COORDINATOR_CHECKLIST.md` — Intake, gentx validation, genesis, peer, launch-window, rollback, and evidence checklist
- `docs/testnet/CONTROLLED_TESTNET_RUNBOOK.md` — Validator build, init, genesis, peers, start, status, signing, and safe-log runbook
- `docs/testnet/CONTROLLED_TESTNET_STATUS.md` — Current status: not launched, genesis pending, gentxs pending, live flags false by design
- `docs/testnet/PHASE_17A_CONTROLLED_TESTNET_DRY_RUN_RESULTS.md` — Local five-validator dry-run result and checksum
- `docs/testnet/PHASE_17B_VALIDATOR_INTAKE_AND_GENESIS_CANDIDATE.md` — External-validator intake and final genesis candidate status
- `docs/testnet/VALIDATOR_SUBMISSION_CHECKLIST.md` — Submission checklist for accepted validators
- `docs/testnet/VALIDATOR_COORDINATION_MESSAGES.md` — Safe coordinator message templates
- `scripts/testnet/verify-controlled-testnet-gentx.sh` — Controlled gentx verifier
- `scripts/testnet/assemble-controlled-testnet-genesis.sh` — Controlled genesis assembly and checksum/manifest writer
- `scripts/testnet/generate-persistent-peers.sh` — Validator intake to persistent-peers generator
- `scripts/testnet/run-controlled-testnet-dry-run.sh` — Local five-validator launch-path rehearsal
- `scripts/testnet/validate-validator-intake.sh` — Intake registry, gentx hash, field, and gentx verifier workflow

### Phase 18A — Internal Coordinator Testnet Candidate And Public Join Readiness
- `docs/testnet/PHASE_18A_INTERNAL_COORDINATOR_TESTNET_CANDIDATE.md` — Internal coordinator candidate purpose, process, gates, and safety boundary
- `docs/testnet/PUBLIC_JOIN_READINESS_CHECKLIST.md` — Source build, CLI, gentx, intake, verifier, genesis, peer, runbook, support, and pending final-launch checklist
- `docs/testnet/CONTROLLED_TESTNET_LAUNCH_WINDOW_TEMPLATE.md` — Planned UTC window, checksum, peers, seed nodes, first-block, first-100-block, first-hour, rollback, and channel placeholders
- `docs/testnet/CONTROLLED_TESTNET_STATUS_UPDATE_DRAFT.md` — Public-safe status wording draft for preparation-only updates
- `coordination/validators/endpoint-inventory.csv` — Header-only endpoint inventory template
- `scripts/testnet/prepare-coordinator-genesis-candidate.sh` — Internal coordinator-only genesis candidate generator
- `scripts/testnet/monitor-controlled-testnet-readiness.sh` — RPC/API launch-readiness monitor for future controlled launch windows

### Phase 18B — External Validator Intake Execution And Genesis Freeze Gate
- `docs/testnet/PHASE_18B_EXTERNAL_VALIDATOR_INTAKE_EXECUTION.md` — Intake execution objective, fields, gentx handling, endpoint process, acceptance/rejection rules, and freeze criteria
- `docs/testnet/PHASE_18B_VALIDATOR_INTAKE_AND_GENESIS_CANDIDATE.md` — Compatibility status document for Phase 18B intake and freeze-gate state
- `docs/testnet/VALIDATOR_INTAKE_MESSAGE_PACK.md` — Copy-paste validator coordination messages with safety wording
- `docs/testnet/FINAL_GENESIS_FREEZE_DECISION.md` — Current freeze decision, counts, reasons, and next required action
- `coordination/validators/submission-tracker.md` — Submission tracker with NodeSync accepted and DNS peer confirmed
- `coordination/validators/endpoint-inventory.csv` — Endpoint inventory with NodeSync P2P-only DNS metadata

### Phase 18C — Coordinator Launch Operations And Incident Response
- `docs/testnet/CONTROLLED_TESTNET_INCIDENT_RESPONSE.md` — Severity, roles, halt/rollback criteria, validator comms, evidence, log preservation, and common incident handling
- `docs/testnet/CONTROLLED_TESTNET_LAUNCH_DAY_COMMANDS.md` — Coordinator command sheet for binary, genesis, peers, RPC/API, live flags, monitor, evidence, and safety checks
- `docs/testnet/GENESIS_PUBLICATION_CHECKLIST.md` — Final genesis publication gate checklist
- `docs/testnet/VALIDATOR_SUPPORT_TRIAGE_TEMPLATE.md` — Support issue capture template for validators
- `docs/testnet/CONTROLLED_TESTNET_LAUNCH_READINESS_DASHBOARD.md` — Manual readiness dashboard for intake, genesis, peers, endpoints, monitor, rollback, support, and safety status
- `scripts/testnet/collect-launch-hour-evidence.sh` — Launch-hour RPC/API, peer, validator, live-flag, and evidence summarizer

### Phase 17C — First External Gentx Verification
- `docs/testnet/PHASE_17C_FIRST_EXTERNAL_GENTX_VERIFICATION.md` — NodeSync gentx SHA256 match, verifier result, acceptance status, confirmed DNS peer, genesis decision, launch status, and next action
- `docs/testnet/PHASE_17C1_NODESYNC_SUBMISSION_RECHECK.md` — Local evidence recheck for repo, downloads, attachment-like files, SHA256, validation, peer generation, and resend decision
- `coordination/validators/submission-tracker.md` — Tracks NodeSync as accepted with DNS peer confirmed
- `coordination/validators/endpoint-inventory.csv` — Records NodeSync P2P-only DNS endpoint metadata
- `coordination/validators/gentxs/gentx-2bb62d82b4dbf820fdafd843816f1e72a84ffa8f.json` — Original NodeSync gentx saved under canonical filename
- `coordination/validators/verified/gentx-2bb62d82b4dbf820fdafd843816f1e72a84ffa8f.json` — Accepted NodeSync gentx copied after SHA256 and verifier pass
- `docs/testnet/EXTERNAL_VALIDATOR_ACTION_PACK.md` — Includes required local `add-genesis-account` step before gentx generation
- `docs/testnet/VALIDATOR_SUBMISSION_CHECKLIST.md` — Includes required local `add-genesis-account` check before gentx submission

### Phase 17D — External Validator Genesis Candidate Freeze Review
- `docs/testnet/PHASE_17D_EXTERNAL_VALIDATOR_GENESIS_CANDIDATE.md` — Candidate composition, NodeSync in-genesis verification, peers, DNS/TCP check, dry-run result, freeze decision, and launch status
- `releases/testnet-genesis/nexarail-testnet-1-candidate/genesis.json` — Review-only controlled testnet genesis candidate; not final public genesis
- `releases/testnet-genesis/nexarail-testnet-1-candidate/manifest.json` — Candidate manifest with validator counts, SHA256, safety marker, and freeze decision
- `releases/testnet-genesis/nexarail-testnet-1-candidate/CANDIDATE_NOTICE.md` — Notice marking the candidate as not final public genesis
- `scripts/testnet/run-controlled-testnet-dry-run.sh` — Added configurable source genesis, source homes, expected validator count, and min-height flags

### Phase 17E — NodeSync P2P Reachability And Freeze Gate
- `docs/testnet/PHASE_17E_NODESYNC_P2P_REACHABILITY_AND_FREEZE_GATE.md` — DNS, TTL, TCP reachability, candidate integrity checks, freeze decision, and required validator action
- `coordination/validators/endpoint-inventory.csv` — Marks NodeSync P2P endpoint `NOT_REACHABLE` until TCP 26656 accepts inbound connections

### Phase 17F — Coordinator Launch Rehearsal With External Candidate Genesis
- `docs/testnet/PHASE_17F_COORDINATOR_LAUNCH_REHEARSAL.md` — Coordinator launch rehearsal using the six-validator external candidate genesis, five local coordinator signers, evidence capture, readiness monitoring, limitations, freeze decision, and launch status
- `coordination/validators/nodesync-reachability.md` — NodeSync DNS/TCP reachability tracker with latest `NOT_REACHABLE` result and next recheck command
- `scripts/testnet/run-controlled-testnet-dry-run.sh` — Height wait budget now derives from the parsed minimum height for higher-height coordinator rehearsals
- `rehearsals/controlled-testnet/dry-run/evidence/20260530T012624Z-phase17f-live/` — Local coordinator rehearsal evidence path; not launch evidence
- `rehearsals/controlled-testnet/launch-hour/evidence/20260530T013213Z/` — Local launch-hour evidence rehearsal path; records expected validator-count failure from non-simulated NodeSync signer; not launch evidence

### Phase 17E.1 — Candidate Genesis Denom Audit And P2P Preconditions
- `docs/testnet/PHASE_17E1_GENESIS_DENOM_AUDIT_AND_P2P_PRECONDITIONS.md` — NodeSync clarification, denom audit method/result, real CometBFT P2P readiness preconditions, freeze decision
- `scripts/testnet/check-genesis-denoms.sh` — Genesis denom auditor (staking/bond/mint/gov/crisis/bank/gentx/distribution; suspicious denom scan; JSON report)
- `coordination/audits/phase17e1-denom-audit.json` — Machine-readable denom audit report for the candidate (Result: PASS)

### Phase 17H — Final Genesis Freeze Gate Automation And Launch Packet
- `scripts/testnet/check-final-genesis-freeze-gate.sh` — Single authoritative freeze gate emitting `FREEZE_GO` / `FREEZE_DEFER` / `FREEZE_BLOCKED`; checks genesis file, SHA256, `validate-genesis`, denom audit, live flags, NodeSync gentx + in-genesis + persistent peer, host resolution, TCP 26656 state, optional CometBFT `/net_info` handshake, secret material, final folder, docs, sign-off
- `docs/testnet/CONTROLLED_TESTNET_LAUNCH_SIGNOFF.md` — Sign-off doc read by the freeze gate (`APPROVED_FOR_GENESIS_PUBLICATION` after Phase 17I.0)
- `docs/testnet/CONTROLLED_TESTNET_FINAL_LAUNCH_PACKET_DRAFT.md` — Final launch packet draft (DRAFT — NOT FINAL — DO NOT START UNTIL SIGNOFF)
- `docs/testnet/NODESYNC_LAUNCH_WINDOW_INSTRUCTIONS.md` — Operator-facing launch-window instructions (DRAFT)
- `rehearsals/controlled-testnet/freeze-gate/evidence/20260530T090422Z/` — First freeze-gate evidence (`FREEZE_DEFER`, 12 pass / 0 fail / 2 defer)

### Phase 17I.0 — Final Controlled-Testnet Genesis Publication And Validator Link Pack
- `releases/testnet-genesis/nexarail-testnet-1/genesis.json` — Final controlled-testnet genesis (sha256 `4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095`)
- `releases/testnet-genesis/nexarail-testnet-1/SHA256SUMS` — Checksum manifest
- `releases/testnet-genesis/nexarail-testnet-1/manifest.json` — Provenance + safety metadata
- `releases/testnet-genesis/nexarail-testnet-1/persistent-peers.txt` — NodeSync persistent peer
- `releases/testnet-genesis/nexarail-testnet-1/README.md` / `FINAL_NOTICE.md` — Safety notice (not mainnet, no token sale, no monetary value, live-funds flags false)
- `docs/testnet/PHASE_17I0_FINAL_GENESIS_PUBLICATION.md` — Publication record with raw GitHub download links and next required step

### Scripts (existing)
- `scripts/testnet/verify-submitted-gentx.sh` — Gentx validation
- `scripts/testnet/assemble-testnet-genesis.sh` — Genesis assembly
- `scripts/testnet/check-final-genesis.sh` — Genesis integrity
- `scripts/testnet/cli-e2e-smoke-test.sh` — CLI smoke test
- `scripts/testnet/api-smoke-test.sh` — API smoke test (updated 10B.3)
- `scripts/testnet/run-hardening-suite.sh` — Full hardening suite
- `scripts/testnet/test-coverage-summary.sh` — Coverage reporting
- `scripts/testnet/predeployment-check.sh` — Pre-deployment check
