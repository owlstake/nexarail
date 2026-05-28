# Phase 10B.0.1 Full-Mode Budget Fix

**Date:** 2026-05-28  
**Scope:** Product-flow rehearsal suite splitting, resume support, and global timeout policy  
**Status:** Complete. Full product-flow suite now completes inside the 2400s cap.

## Phase 10B.0 Baseline

- Plain smoke passed: `scripts/testnet/run-product-flow-rehearsal.sh --smoke`
  - Result: 43 pass / 0 fail
  - Evidence: `rehearsals/validator-agents/product-flows/evidence/20260527T220802Z/`
- Force-clean smoke passed: `scripts/testnet/run-product-flow-rehearsal.sh --smoke --force-clean`
  - Result: 43 pass / 0 fail
  - Evidence: `rehearsals/validator-agents/product-flows/evidence/20260527T220951Z/`
- Full force-clean failed clearly: `scripts/testnet/run-product-flow-rehearsal.sh --full --force-clean`
  - Failed stage: `payout flow`
  - Exit: `143`
  - Cause: 900s global timeout
  - Evidence: `rehearsals/validator-agents/product-flows/evidence/20260527T221138Z/`

## Root Cause

The full suite was still progressing through payout when the 900s global timer fired. This was not a stale-process, port-conflict, descriptor, CheckTx, or panic issue. The failed evidence shows payout mark-paid proposal pass, payout recipient delta, treasury module delta, payout query, and payout list query had completed before the global cap terminated the run.

## Suite Split Design

`scripts/testnet/run-product-flow-rehearsal.sh` now supports:

- `--suite smoke`
- `--suite merchant`
- `--suite settlement`
- `--suite escrow`
- `--suite treasury`
- `--suite payout`
- `--suite safety`
- `--suite all`

Aliases remain:

- `--smoke` maps to `--suite smoke`
- `--full` maps to `--suite all`

`--suite all` runs:

1. Smoke gate
2. Merchant
3. Settlement
4. Escrow
5. Treasury
6. Payout
7. Safety
8. Final live flags

If smoke fails, product suites do not run. If a later suite fails, diagnostics are collected and a rerun command is written to `rerun-command.txt`.

## Resume Behavior

Supported resume stages:

- `preflight`
- `spawn`
- `query-readiness`
- `merchant`
- `settlement-metadata`
- `settlement-live`
- `settlement-treasury`
- `settlement-burn`
- `escrow`
- `treasury`
- `payout`
- `safety`
- `final-live-flags`

Resume mode checks that the existing runtime is reachable before skipping spawn or earlier stages. Resume metadata is written to `resume-metadata.txt`.

## Timeout Defaults

| Suite | Default global timeout |
|---|---:|
| `smoke` | 300s |
| Individual module suite | 600s |
| `all` / `full` | 2400s |

Per-stage caps remain in place. The global timeout still exists; there are no unbounded full-mode runs.

## Suite Summary Artifacts

Every run now writes:

- `stage-durations.tsv`
- `summary.json`
- `summary.txt`

The console summary prints suite name, global timeout, elapsed time, stage durations, slowest stage, and pass/fail count.

## Payout Duration Diagnosis

The Phase 10B.0 full failure shows payout was slow because of normal governance timing and sequential tx/proposal confirmation, not because of unnecessary sleeps or retry loops. The script preserves correctness and uses the larger full-suite global cap rather than weakening per-stage caps.

## Final Results

### Verification Gates

- `go mod tidy`: PASS
- `go mod verify`: PASS
- `go build ./...`: PASS
- `go vet ./...`: PASS
- `go test ./...`: PASS

### Rehearsal Runs

| Command | Result | Elapsed | Slowest stage | Evidence |
|---|---:|---:|---|---|
| `scripts/testnet/run-product-flow-rehearsal.sh --suite smoke --force-clean` | 43 pass / 0 fail | 94s | `clean spawn` 77s | `rehearsals/validator-agents/product-flows/evidence/20260527T224738Z/` |
| `scripts/testnet/run-product-flow-rehearsal.sh --suite payout --no-spawn` | Expected clear fail | 120s cap | `RPC readiness` | `rehearsals/validator-agents/product-flows/evidence/20260527T224932Z/` |
| `scripts/testnet/run-product-flow-rehearsal.sh --suite payout --force-clean --keep-running` | 132 pass / 0 fail | 370s | `payout flow` 139s | `rehearsals/validator-agents/product-flows/evidence/20260527T225147Z/` |
| `scripts/testnet/run-product-flow-rehearsal.sh --suite safety --no-spawn` | 53 pass / 0 fail | 22s | `safety checks` 13s | `rehearsals/validator-agents/product-flows/evidence/20260527T225807Z/` |
| `scripts/testnet/run-product-flow-rehearsal.sh --suite all --force-clean --global-timeout 2400` | 469 pass / 0 fail | 1111s | `treasury flow` 200s | `rehearsals/validator-agents/product-flows/evidence/20260527T225842Z/` |

The requested payout `--no-spawn` run failed because the prior smoke run correctly stopped the local agent runtime by default. That is now documented behavior. The fallback clean-spawn payout run used `--keep-running`, allowing the safety suite to run with `--no-spawn` against an existing runtime.

### Final Live Flags

Final full-suite readback:

- `settlement.live_enabled=false`
- `settlement.treasury_routing_enabled=false`
- `settlement.burn_routing_enabled=false`
- `escrow.live_enabled=false`
- `treasury.live_enabled=false`
- `payout.live_enabled=false`

### Descriptor / CheckTx Status

`descriptor-errors.txt` in the final full-suite evidence contains 0 lines. No runtime `unknownproto`, descriptor, `index out of range`, gzip/invalid-header, `CheckTx`, or panic signature appeared in the final run.

### Safety Wording Status

Safety wording audit passed after review. Remaining matches are negative, qualified, technical, checklist literals, moderation examples, or explicit prohibitions. No positive claim was added that mainnet is live, NXRL can be bought, a token sale exists, investment/return/profit/APY is available, price/listing exists, or external decentralisation has been achieved.

### Manual Cleanup

Manual cleanup is not required. The scripts own force-clean, diagnostics, failure evidence, and final stop/cleanup.
