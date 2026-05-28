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

### Scripts (existing)
- `scripts/testnet/verify-submitted-gentx.sh` — Gentx validation
- `scripts/testnet/assemble-testnet-genesis.sh` — Genesis assembly
- `scripts/testnet/check-final-genesis.sh` — Genesis integrity
- `scripts/testnet/cli-e2e-smoke-test.sh` — CLI smoke test
- `scripts/testnet/api-smoke-test.sh` — API smoke test (updated 10B.3)
- `scripts/testnet/run-hardening-suite.sh` — Full hardening suite
- `scripts/testnet/test-coverage-summary.sh` — Coverage reporting
- `scripts/testnet/predeployment-check.sh` — Pre-deployment check
