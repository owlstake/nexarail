# Phase 16D - Local Multi-Run Trend and Limit Profiling Plan

## Objective

Run repeated local five-agent load profiles across increasing bank transaction and REST/RPC query load levels, collect resource metrics, compare trends, define conservative local-only ceilings, and document failure thresholds.

Phase 16D is local profiling only. It does not add product modules, alter economics, change validator economics, enable live flags by default, launch a public testnet, or imply production throughput.

## Goals

- Repeat load tests across defined local load levels.
- Capture transaction inclusion, query success, latency, block progress, peer count, validator set, live flags, REST/RPC health, and log scans per level.
- Capture per-agent process resource metrics during each load window.
- Compare trends across levels in one combined evidence directory.
- Define conservative local five-agent devnet ceilings and stop/failure thresholds.
- Keep evidence reproducible and isolated under `rehearsals/validator-agents/load-trends/evidence/<timestamp>/`.

## Non-Goals

- No product module additions.
- No economics changes.
- No validator economics changes.
- No default live-flag enablement.
- No real funds or live product funds.
- No npm or PyPI publishing.
- No public or external testnet launch.
- No external validator or decentralisation claim.
- No production TPS, public-network performance, token-buyability, market, exchange, fundraising, yield, or financial-upside claim.

## Local-Only Limitation

All results are single-machine local five-agent devnet observations. They are useful for local harness stability, relative trend comparison, and conservative pre-external-readiness thresholds. They are not public network performance results and must not be described as production throughput.

## Load Levels

| Level | Duration | Tx rate target | Query rate target | Concurrency | Purpose |
|---|---:|---:|---:|---:|---|
| L1 baseline | 10 min | 1/s | 5/s | 2 | Repeat Phase 16C standard baseline |
| L2 moderate | 10 min | 2/s | 10/s | 4 | Repeat Phase 16C heavier shape as moderate trend point |
| L3 elevated | 10 min | 4/s | 20/s | 6 | Increase query and tx pressure |
| L4 stress | 10 min | 6/s | 30/s | 8 | Local stress threshold probe |
| L5 exploratory | optional | TBD | TBD | TBD | Only with explicit flag and only if L4 passes cleanly |

The transaction harness is intentionally conservative: workers wait for inclusion before reusing a sender to avoid unsafe sequence races. Observed tx throughput may therefore be lower than the target request rate under higher levels.

## Metrics

Per load level:
- configured duration, tx rate, query rate, and concurrency
- observed duration
- start height, final height, height delta, and average block time
- peer count range
- validator count range
- tx attempted, broadcast success, included code `0`, failed by class
- p50/p95 transaction inclusion latency
- query attempted, success, failed by endpoint and agent
- p50/p95 query latency
- REST/RPC health
- final live flags
- panic/fatal scan count
- CheckTx scan count
- descriptor/unknownproto/gzip scan count
- cleanup status

Resource metrics:
- per-agent PID
- CPU percent where available
- RSS memory
- open files where available
- process uptime
- disk size of each agent data directory
- machine load average
- timestamp

## Success Thresholds

A level passes when:
- five agents remain alive at final health collection
- block height advances
- validator count remains 5
- peer count remains stable and sampled
- tx inclusion is measured
- all tx failures, if any, are classified
- queries complete without failures
- REST/RPC health passes
- final live flags are false
- panic/fatal scan is 0
- unrecovered CheckTx scan is 0
- descriptor/unknownproto/gzip scan is 0
- resource metrics are captured when resource sampling is enabled
- agents stop cleanly unless `--keep-running` is explicitly used

Preferred trend criteria:
- tx inclusion rate: 100%
- query success rate: 100%
- no inter-agent validator-set drift
- no consensus stall

## Failure Thresholds

Classify and stop or downgrade the local ceiling when any of these appear:
- tx inclusion falls below 99%
- repeated tx sequence failures
- mempool or broadcast failures persist beyond isolated transients
- query success falls below 99.5%
- repeated RPC or REST timeouts
- block height does not advance across at least two sample intervals
- validator count drops below 5
- peer count becomes unstable or unavailable
- any agent process exits unexpectedly
- resource pressure coincides with tx/query failures
- panic/fatal, unrecovered CheckTx, descriptor, unknownproto, or gzip scan is nonzero
- final live flags are not false

## Resource Sampling Approach

`scripts/testnet/sample-agent-resources.sh` samples local validator-agent processes without sudo. macOS is the primary target; Linux is best-effort.

It reads PID files from `rehearsals/validator-agents/pids/` where available and falls back to process command matching. It records data into:
- `resources.tsv`
- `resources-summary.json`

When invoked by the load runner, the sampler starts before the load window and stops before runtime cleanup so process resource metrics are captured while agents are alive.

## Evidence Paths

Trend-run evidence root:

```text
rehearsals/validator-agents/load-trends/evidence/<timestamp>/
```

Required combined files:
- `trend-summary.json`
- `trend-summary.md`
- `level-results.tsv`
- `level-evidence-paths.txt`
- `resource-comparison.tsv`
- `failure-thresholds.md`
- `safety-scan.txt`

Each level also writes a nested load-simulation evidence directory containing Phase 16C-format load evidence plus resource files.

## Interpretation Rules

- Use “local five-agent devnet observed throughput” only.
- Do not call results production throughput.
- Do not imply public network performance.
- Include machine and single-machine caveats.
- Treat the conservative local ceiling as the highest cleanly passing level, not as a product promise.
- If L3 or L4 fails, document the first failure threshold honestly and use the previous clean level as the ceiling.
- Governance under load is separate from bank/query throughput and must be separately labeled if run.
