# Phase 16B.2 — One-Hour Five-Agent Soak Results

## Verdict

Network stability: PASS.

Harness completeness: PARTIAL. The one-hour run produced valid height, REST, live-flag, and log-scan evidence, but the original harness did not produce a clean final `summary.json` because the no-match log scan tripped `set -e -o pipefail`. Bank tx smoke files were also empty because the harness used the removed `tx bank send` command and tried to resolve the recipient key from the wrong agent home.

Full Phase 16B.2 closure requires one rerun with the patched harness.

## Raw Evidence

- Evidence path: `rehearsals/validator-agents/long-soak/evidence/phase16b2-20260528T190803Z/`
- Sample file: `samples.tsv`
- REST health: `rest-health.json`
- REST module snapshots: `rest/*.json`
- Log scan: `panic-scan.txt`
- TX smoke attempts: `tx/*.json`

## One-Hour Soak Metrics

| Metric | Result |
|---|---:|
| Sample rows | 300 |
| Sample points | 60 |
| Agents | 5 |
| Start time UTC | 19:08:03 |
| End time UTC | 20:07:50 |
| Observed sample duration | 3,587s |
| Start height | 164 |
| End height | 832 |
| Height delta | 668 blocks |
| Max inter-agent height drift | 1 block |
| Sample points with >1 block drift | 0 |

## Final State Checks

REST health returned HTTP 200 for all five agents across:
- settlement
- escrow
- payout
- treasury

Live flags were manually rechecked after the run across all five agents and all four modules. All returned `false`.

Log scan counts were manually recomputed from the raw evidence:
- `panic`: 0
- `fatal`: 0
- `CheckTx`: 0
- `descriptor`: 0
- `gzip invalid`: 0
- `index out of range`: 0
- `version does not exist`: 0

## Harness Fixes Applied After Inspection

Updated `scripts/testnet/run-five-agent-long-soak.sh`:
- sample rows now include real peer count and `catching_up`, matching the TSV header
- tx smoke now uses `nexaraild tx send`, not the invalid `tx bank send`
- tx smoke resolves the `bravo-key` recipient from the bravo agent home
- tx stderr is retained beside the tx JSON evidence
- zero-match log scans no longer abort before summary writing

Updated `scripts/testnet/run-five-agent-restart-check.sh`:
- fixed the live-flag pass/fail branch so a passing live-flag check does not also increment `FAIL`

## Patch Validation

Short patched-harness smoke:
- Command: `scripts/testnet/run-five-agent-long-soak.sh --duration 3 --sample-interval 1 --tx-interval 1 --keep-running --evidence-dir rehearsals/validator-agents/long-soak/evidence/patch-smoke-20260528T2043Z`
- Result: PASS 3, FAIL 0, SKIP 0
- Bank tx hash: `CEE308753A026D036BBED654FC7879763D4A978A7D51F11D66D3E0CDEF5C0E5C`
- Log scan wrote all zero counts and `summary.json` successfully

## Remaining Gap

Phase 16B.2 should be rerun for the full hour with the patched harness to produce a clean canonical `summary.json` and valid periodic tx smoke evidence. Until that rerun, the five-agent network stability result is strong, but tx-load and final harness accounting remain non-canonical.

No public testnet, mainnet, token-buyability, or live-value claim is implied by this result.
