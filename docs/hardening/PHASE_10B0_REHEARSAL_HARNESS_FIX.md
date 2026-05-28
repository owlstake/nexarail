# Phase 10B.0 Rehearsal Harness Fix

**Date:** 2026-05-27  
**Scope:** Product-flow rehearsal harness hardening  
**Decision:** Smoke harness GO. Full product-flow timeout blocker later resolved by Phase 10B.0.1 suite splitting and a 2400s full-suite cap.

## Freeze Symptom

The Phase 10B product-flow rehearsal could appear frozen during local 5-agent runtime setup or long product-flow execution. The old harness redirected key spawn output, allowed some failures to continue as soft state loss, and did not always emit a single actionable failure package.

## Likely Root Causes

- Orphaned validator-agent `nexaraild` processes could survive tmux/PID-file mismatch.
- Agent ports could remain occupied after an interrupted run.
- Spawn could wait without proving each agent process, RPC socket, gRPC socket, height advancement, and validator-set count.
- The product-flow script had no global failure trap and could continue after a failed stage.
- Full mode is longer than the 900s global cap under the current number of sequential governance proposals.

## Script Changes

- `scripts/testnet/run-product-flow-rehearsal.sh`
  - Added `set -Eeuo pipefail`.
  - Added `--smoke`, `--full`, `--force-clean`, `--no-spawn`, `--keep-running`, `--timeout`, and `--evidence-dir`.
  - Added stage logging: `[PHASE 10B] START/OK/FAIL <stage>`.
  - Added global traps for `EXIT`, `ERR`, `INT`, and `TERM`.
  - Added evidence-first setup with `run.log`, snapshots, logs, txs, queries, diagnostics, and final live-flag artifacts.
  - Added result-event accounting so subshell-timed stages cannot hide pass/fail events.
  - Added smoke mode: spawn, readiness, query readback, one bank send, balance query, final live flags, cleanup.

- `scripts/testnet/diagnose-agent-freeze.sh`
  - New non-interactive diagnostics collector.
  - Captures process state, port listeners, tmux state, latest logs, PID files, config snippets, RPC status, validator logs, and descriptor/CheckTx terms.

- `scripts/testnet/spawn-validator-agents.sh`
  - Added `--force-clean`, `--no-tmux`, and `--evidence-dir`.
  - Default stale process/port behavior now fails clearly with diagnostics.
  - `--force-clean` only kills validator-agent runtime or validator-agent port owners.
  - Verifies post-start PID liveness, per-agent RPC readiness, gRPC socket readiness, height advancement, and validator-set count.

- `scripts/testnet/stop-validator-agents.sh`
  - Stops tmux sessions, PID-file processes, and orphaned validator-agent `nexaraild` processes.
  - Avoids unrelated `nexaraild` processes unless `--all-nexaraild` is explicitly passed.
  - Supports `--force` and `--evidence-dir`.

- `scripts/testnet/check-agent-data-clean.sh`
  - Detects data DBs, genesis files, PID files, and logs.
  - Supports `--json`, `--allow-reuse`, and `--evidence-dir`.

## Timeout List

| Stage | Timeout |
|---|---:|
| Preflight | 60s |
| Cleanup | 60s |
| Port check | 30s |
| Clean spawn | 180s |
| RPC readiness | 120s |
| Height readiness | 180s |
| Query readiness | 90s |
| Smoke bank tx | 90s |
| Merchant flow | 180s |
| Settlement metadata flow | 240s |
| Settlement live/routing flows | 300s |
| Escrow flow | 240s |
| Treasury flow | 240s |
| Payout flow | 240s |
| Safety checks | 180s |
| Final live flags | 90s |
| Evidence finalization | 60s |
| Stop/cleanup | 60s |
| Full rehearsal global cap | 900s in Phase 10B.0; replaced by Phase 10B.0.1 defaults |

## Cleanup Behavior

Manual user cleanup is no longer required. The harness owns:

- stale validator-agent process detection;
- safe validator-agent cleanup;
- force-clean of validator-agent-owned ports;
- final stop/cleanup;
- process, port, log, and config diagnostics on failure.

The scripts do not kill unrelated `nexaraild` processes unless explicitly invoked with `--all-nexaraild`.

## Results

| Command | Result | Evidence |
|---|---|---|
| `scripts/testnet/run-product-flow-rehearsal.sh --smoke` | PASS, 43 pass / 0 fail | `rehearsals/validator-agents/product-flows/evidence/20260527T220802Z/` |
| `scripts/testnet/run-product-flow-rehearsal.sh --smoke --force-clean` | PASS, 43 pass / 0 fail | `rehearsals/validator-agents/product-flows/evidence/20260527T220951Z/` |
| `scripts/testnet/run-product-flow-rehearsal.sh --full --force-clean` | FAIL clearly, stage `payout flow`, exit `143` | `rehearsals/validator-agents/product-flows/evidence/20260527T221138Z/` |

## Full Rehearsal Blocker

The full rehearsal did not freeze silently. It hit the 900s global cap during `payout flow` after:

- clean spawn passed;
- RPC readiness passed;
- height readiness passed;
- query readiness passed;
- smoke bank tx passed;
- merchant flow passed;
- settlement metadata passed;
- settlement live passed;
- settlement treasury routing passed;
- settlement burn routing passed;
- escrow passed;
- treasury passed;
- payout enable/create/approve/mark-paid/proposal-pass/readback/deltas passed.

The timeout fired before the remaining payout disable/safety/final-live-flag stages. Best diagnosis: the current 900s global cap is too tight for the full sequential-governance product-flow suite. This is a timeout-budget issue, not a silent freeze.

## Phase 10B.0.1 Follow-Up

Phase 10B.0.1 resolved the timeout-budget blocker without changing product modules, economics, live-flag genesis defaults, or per-stage caps.

- Added `--suite smoke|merchant|settlement|escrow|treasury|payout|safety|all`.
- Added `--resume-from <stage>`.
- Added `--global-timeout <seconds>`.
- Default global caps are now 300s for smoke, 600s for individual module suites, and 2400s for all/full.
- Added `stage-durations.tsv`, `summary.json`, and `summary.txt` for every run.
- Full suite now passes: `469 pass / 0 fail`, elapsed `1111s`, evidence `rehearsals/validator-agents/product-flows/evidence/20260527T225842Z/`.
- Final live flags remain false for settlement, escrow, treasury, and payout controls.

## Descriptor / CheckTx Status

No runtime descriptor, `unknownproto`, `index out of range`, `gzip`, invalid-header, `CheckTx`, or panic evidence remains after filtering diagnostics to runtime logs and tx/query artifacts. Full-run `descriptor-errors.txt` contains 0 matches.

## Verification

- `go mod tidy`: PASS
- `go mod verify`: PASS
- `go build ./...`: PASS
- `go vet ./...`: PASS
- `go test ./...`: PASS

## Safety Wording Audit

Terms audited: `decentralised`, `independent validators`, `external validators`, `mainnet live`, `buy NXRL`, `token sale`, `investment`, `guaranteed`, `profit`, `APY`, `returns`, `price`, `listing`.

Result: pass after review. Remaining matches are negative, qualified, technical, checklist literals, moderation examples, or explicit prohibitions. No positive claim was added that mainnet is live, NXRL can be bought, a token sale exists, investment/return/profit/APY is available, price/listing exists, or external decentralisation has been achieved.

## Manual Cleanup Requirement

Manual user cleanup is not required. If a future run fails, the evidence directory contains the failure stage, exit code, logs, process list, port usage, last validator logs, descriptor scan, and root-cause hypothesis.
