# Controlled Testnet Status

**Network:** `nexarail-testnet-1`
**Last updated:** 2026-05-29

## Current Status

| Item | Status |
|---|---|
| Controlled external-validator testnet | NOT LAUNCHED |
| Final public genesis | PENDING - waiting for verified external gentxs |
| Internal coordinator candidate | PREPARED - not final public genesis |
| Validator intake registry | OPEN - awaiting submissions |
| Validator gentxs | WAITING |
| Launch time | PENDING |
| Persistent peers | INTERNAL CANDIDATE READY; final public peers waiting for complete external records |
| Seed or bootnode | PENDING |
| External validator evidence | PENDING |
| Phase 17B intake workflow | READY |
| Phase 18A join readiness package | READY |
| Phase 18B intake execution | OPEN - awaiting submissions |
| Final genesis freeze decision | FREEZE_DEFER |
| Local Phase 17A dry-run | PASS |
| Internal coordinator candidate dry-run | PASS |
| Product live flags | FALSE BY DESIGN |
| Mainnet | NO-GO |

## Current Validator Path

Source-build only:

```bash
git clone https://github.com/Bookings-cpu/nexarail.git
cd nexarail
git checkout v0.1.0-rc1-cli-hotfix
make build
```

Prebuilt hotfix binary upload is not the validator path until release asset permissions are resolved and checksums are published through the GitHub release.

## Phase 17B Intake Status

Current coordination workspace:

- intake registry: `coordination/validators/validator-intake.csv`;
- pending gentxs: `coordination/validators/gentxs/`;
- verified gentxs and validation summaries: `coordination/validators/verified/`;
- rejected gentxs and reason files: `coordination/validators/rejected/`;
- peer output: `coordination/validators/peer-info/`.

Current counts:

- validator records submitted: 0;
- gentxs verified: 0;
- gentxs rejected: 0;
- final genesis candidate: not assembled.
- endpoint inventory: header-only template.
- internal coordinator candidate: assembled from local coordinator validators only.
- submission tracker: awaiting validator submissions.
- final genesis freeze decision: `FREEZE_DEFER`.

## Phase 18A Coordinator Candidate

Phase 18A adds an internal coordinator-controlled candidate so launch artifacts can be rehearsed while external validator intake remains open.

- plan: `docs/testnet/PHASE_18A_INTERNAL_COORDINATOR_TESTNET_CANDIDATE.md`;
- join readiness: `docs/testnet/PUBLIC_JOIN_READINESS_CHECKLIST.md`;
- candidate generator: `scripts/testnet/prepare-coordinator-genesis-candidate.sh`;
- monitoring script: `scripts/testnet/monitor-controlled-testnet-readiness.sh`;
- endpoint inventory template: `coordination/validators/endpoint-inventory.csv`;
- launch-window template: `docs/testnet/CONTROLLED_TESTNET_LAUNCH_WINDOW_TEMPLATE.md`;
- public status draft: `docs/testnet/CONTROLLED_TESTNET_STATUS_UPDATE_DRAFT.md`.

The coordinator candidate is marked `INTERNAL COORDINATOR CANDIDATE — NOT FINAL PUBLIC GENESIS`.

## Phase 18B Intake Execution

Phase 18B executes real validator intake and the final public genesis freeze gate.

- execution plan: `docs/testnet/PHASE_18B_EXTERNAL_VALIDATOR_INTAKE_EXECUTION.md`;
- validator tracker: `coordination/validators/submission-tracker.md`;
- validator messages: `docs/testnet/VALIDATOR_INTAKE_MESSAGE_PACK.md`;
- freeze decision: `docs/testnet/FINAL_GENESIS_FREEZE_DECISION.md`.

Current decision: `FREEZE_DEFER` because no external validator gentxs or endpoint records have been submitted.

## Local Dry-Run Evidence

The launch tooling path passed a local five-validator dry-run:

- height verified: 20;
- validator set count: 5;
- genesis SHA256: `5fc2ad8a76cfee850e33ddf8f94f403b101657f27de6f0c8885021e8b2c74d90`;
- product live flags: false;
- `tendermint show-node-id` and `comet show-node-id`: pass.

See `docs/testnet/PHASE_17A_CONTROLLED_TESTNET_DRY_RUN_RESULTS.md`.

The Phase 18A coordinator candidate also passed a local five-validator dry-run from the generated candidate:

- height verified: 20;
- validator set count: 5;
- genesis SHA256: `b02d00bf63386e44cd46b6ac83f26f072da3f389b50838f7c62c72f2639d9648`;
- product live flags: false;
- REST params queryable;
- readiness monitor: pass against five local RPC/API endpoints;
- panic/fatal log scan: pass;
- `tendermint show-node-id` and `comet show-node-id`: pass.

## Status Rules

- Do not describe the controlled testnet as launched until final genesis is published and accepted external validators are running.
- Do not describe external decentralisation as achieved until external validator operation is evidenced.
- Do not describe NXRL as buyable or having monetary value.
- Keep product live-funds flags false unless a separately reviewed governance process changes them.
