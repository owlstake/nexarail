# Phase 16C — Load Simulation and Throughput Profiling Plan

## Objective

Measure local five-agent devnet behavior under controlled transaction and query load without changing product semantics, economics, live defaults, validator economics, launch status, or release distribution.

Phase 16B.2.1 is treated as the stability baseline before load work. Phase 16C only adds a local load harness and evidence; it does not launch a public testnet and does not imply mainnet readiness.

## Goals

- Run conservative local bank transaction load across the five validator agents.
- Run concurrent read/query load across RPC and REST endpoints.
- Measure block height progression, validator set size, peer counts, transaction inclusion, query latency, REST/RPC health, and final live flags.
- Classify transaction failures instead of hiding them.
- Produce repeatable evidence in `rehearsals/validator-agents/load-sim/evidence/<timestamp>/`.
- Stop local agents cleanly after evidence capture unless `--keep-running` is explicitly used.

## Non-Goals

- No product module additions.
- No economics changes.
- No validator economics changes.
- No default live-flag enablement.
- No real funds.
- No SDK publishing to npm or PyPI.
- No public/external testnet launch.
- No external validator or decentralisation claim.
- No mainnet, token-buyability, market, exchange, fundraising, yield, or financial-upside claim.

## Load Types

### Bank Transaction Load

The load runner sends small `unxrl` bank transfers between local genesis-funded validator-agent accounts. Transaction workers rotate across existing local agent keys and wait for inclusion before reusing a sender, avoiding sequence races by design.

Default load is conservative:
- duration: 600 seconds
- tx rate target: 1 transaction per second
- query rate target: 5 queries per second
- concurrency: 2
- sample interval: 30 seconds

### Query Load

The query load repeatedly hits all five agents across:
- RPC `/status`
- RPC `/net_info`
- RPC `/validators`
- REST bank balances
- REST fees params
- REST merchant params and merchant list
- REST settlement params and settlement list
- REST escrow params and escrow list
- REST payout params and payout list
- REST treasury params and summary

## Success Criteria

- Five agents remain alive.
- Block height advances during the run.
- Validator set remains 5.
- Peer count remains stable.
- Transaction inclusion rate is measured.
- Failed transactions are classified.
- REST/RPC health is measured.
- Final live flags are false.
- No panics.
- No descriptor, unknown proto, or gzip errors.
- No unrecovered CheckTx failures.
- Agents stop cleanly during cleanup unless `--keep-running` is set.

## Metrics Collected

Required evidence files:
- `summary.json`
- `summary.md`
- `samples.tsv`
- `tx-results.jsonl`
- `tx-summary.json`
- `query-results.jsonl`
- `query-summary.json`
- `rpc-health.json`
- `rest-health.json`
- `live-flags-final.json`
- `panic-scan.txt`
- `checktx-scan.txt`
- `descriptor-scan.txt`
- `logs/`

Metric categories:
- duration
- start height
- final height
- height delta
- average block time
- transaction attempts
- transaction broadcast success
- transaction inclusion code `0`
- transaction failures by class
- p50/p95 transaction inclusion latency
- query attempts
- query success
- query failures by endpoint and agent
- p50/p95 query latency
- peer count range
- validator count
- final live flags

## Expected Runtime

- Smoke mode: 120 seconds plus spawn and cleanup time.
- Standard 10-minute run: 600 seconds plus spawn and cleanup time.
- Optional heavier run: 1,200 seconds plus spawn and cleanup time, attempted only if the 10-minute run passes.

## Evidence Paths

Default evidence root:

```text
rehearsals/validator-agents/load-sim/evidence/<timestamp>/
```

Spawn, stop, and cleanup diagnostics are written under the same evidence directory where available.

## Known Limitations

- This is local five-agent evidence only.
- Query concurrency runs on a single machine and is not a substitute for geographically distributed validator load.
- Bank transaction throughput is intentionally conservative because workers wait for inclusion before reusing a sender.
- The harness measures local RPC/REST behavior, not internet-facing endpoint behavior.
- Optional governance reliability under load may be skipped if it would materially extend runtime or destabilise the controlled load window.
