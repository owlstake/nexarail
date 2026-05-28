# Phase 16C - Load Simulation and Throughput Profiling Results

## Verdict

Phase 16C passed for controlled local five-agent load simulation.

The tested network stayed local-only, five-agent only, and devnet-only. No product modules, economics, validator economics, live defaults, release distribution, or public launch status were changed.

## Commands Run

Smoke:

```bash
scripts/testnet/run-five-agent-load-sim.sh --duration 120 --tx-rate 1 --query-rate 2 --sample-interval 30 --evidence-dir rehearsals/validator-agents/load-sim/evidence/phase16c-smoke-20260528T213401Z
```

Standard 10-minute run:

```bash
scripts/testnet/run-five-agent-load-sim.sh --duration 600 --tx-rate 1 --query-rate 5 --concurrency 2 --sample-interval 30 --evidence-dir rehearsals/validator-agents/load-sim/evidence/phase16c-10min-stable-20260528T215108Z
```

Optional heavier run:

```bash
scripts/testnet/run-five-agent-load-sim.sh --duration 1200 --tx-rate 2 --query-rate 10 --concurrency 4 --sample-interval 30 --evidence-dir rehearsals/validator-agents/load-sim/evidence/phase16c-heavy-20260528T220345Z
```

Discarded run:

```text
rehearsals/validator-agents/load-sim/evidence/phase16c-10min-20260528T213839Z/
```

That run is not counted as evidence because the script was edited while the bash process was still reading it, causing a final-collection parse error. The runtime was cleaned and the 10-minute profile was rerun from a stable script.

## Evidence Paths

| Run | Evidence path |
|---|---|
| Smoke | `rehearsals/validator-agents/load-sim/evidence/phase16c-smoke-20260528T213401Z/` |
| 10-minute | `rehearsals/validator-agents/load-sim/evidence/phase16c-10min-stable-20260528T215108Z/` |
| Heavier | `rehearsals/validator-agents/load-sim/evidence/phase16c-heavy-20260528T220345Z/` |

Each passing run wrote:
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

## Load Metrics

| Metric | Smoke | 10-minute | Heavier |
|---|---:|---:|---:|
| Configured duration | 120s | 600s | 1200s |
| Observed sample duration | 123s | 615s | 1229s |
| Start height | 11 | 11 | 11 |
| Final height | 34 | 124 | 237 |
| Height delta | 23 | 113 | 226 |
| Average block time | 5.35s | 5.44s | 5.44s |
| Peer count range | 4-4 | 4-4 | 4-4 |
| Validator count range | 5-5 | 5-5 | 5-5 |
| Tx attempted | 45 | 220 | 876 |
| Tx broadcast success | 45 | 220 | 876 |
| Tx included code 0 | 45 | 220 | 876 |
| Tx failed by class | none | none | none |
| Tx inclusion latency p50 | 5394ms | 5390ms | 5319ms |
| Tx inclusion latency p95 | 5944ms | 6052ms | 6153ms |
| Queries attempted | 208 | 2330 | 9020 |
| Queries successful | 208 | 2330 | 9020 |
| Query failures | 0 | 0 | 0 |
| Query latency p50 | 2ms | 1ms | 1ms |
| Query latency p95 | 10ms | 10ms | 12ms |
| Final live flags false | true | true | true |
| Phase pass | true | true | true |

## REST/RPC Health

Final RPC health for the 10-minute run:
- all five agents alive
- final health height: 125 on each agent
- `catching_up=false` on each agent
- peer count: 4 on each agent
- validator count: 5 on each agent

Final RPC health for the heavier run:
- all five agents alive
- final health height: 237 on each agent
- `catching_up=false` on each agent
- peer count: 4 on each agent
- validator count: 5 on each agent

REST health passed for all 30 final REST checks in the heavier run: settlement, escrow, payout, treasury, merchant, and fees params across all five agents.

## Log Scans

All passing Phase 16C runs produced:
- panic/fatal scan: 0
- CheckTx scan: 0
- descriptor/unknownproto/gzip scan: 0

No unrecovered CheckTx failures were observed in `tx-results.jsonl`.

## Governance Reliability

Governance reliability during load was skipped deliberately.

Reason: Phase 16C was scoped to bank tx throughput and REST/RPC read load. Keeping proposal/vote timing out of the load window preserved a clean throughput baseline. Existing Phase 16A.7 vote reliability hardening remains the governance baseline.

## Cleanup

Each passing run stopped and cleaned local validator-agent runtime:
- stop rc: 0
- clean rc: 0
- remaining agent processes: 0
- occupied test ports: 0

## Harness Notes

Two harness issues were fixed before accepting the canonical 10-minute evidence:
- transaction inclusion now uses CometBFT RPC `/tx?hash=...` because this binary does not expose `query tx`
- `catching_up=false` is now preserved in samples and RPC health instead of being replaced by a fallback value

## Limitations

- Local single-machine five-agent evidence only.
- Bank send load only; product-flow semantics were not changed or exercised as load traffic.
- No external validators were activated.
- No public testnet was launched.
- No live-value or token-buyability claim is implied.
- Query latency reflects local loopback REST/RPC access, not internet-facing endpoint behavior.

## Verification

| Command | Result |
|---|---|
| `bash -n scripts/testnet/run-five-agent-load-sim.sh scripts/testnet/run-five-agent-long-soak.sh scripts/testnet/run-five-agent-restart-check.sh` | PASS |
| `bash -n scripts/dev/run-nexarail-regression-matrix.sh` | PASS |
| `go mod tidy` | PASS |
| `go mod verify` | PASS, all modules verified |
| `go build ./...` | PASS |
| `go vet ./...` | PASS |
| `go test ./...` | PASS |
| `scripts/testnet/predeployment-check.sh` | PASS, 23 passed / 0 failed |
| `scripts/dev/run-nexarail-regression-matrix.sh --fast` | PASS, 9 passed / 0 failed / 0 skipped |
| `scripts/release/verify-testnet-rc1.sh` | PASS, 37 passed / 0 failed |
| `scripts/testnet/check-product-flow-harness.sh` | PASS, 18 passed / 0 failed |
| `scripts/testnet/stop-validator-agents.sh` | PASS, no running validator-agent processes |
| `scripts/testnet/clean-validator-agent-runtime.sh` | PASS, final agent processes 0 and all agent ports free |

Fast regression matrix evidence:

```text
rehearsals/regression-matrix/evidence/20260528T223514Z/
```

## Safety Wording Audit

Evidence:

```text
rehearsals/validator-agents/load-sim/evidence/phase16c-safety-audit-20260528T222937Z/
```

Result: PASS.

Global audit scope covered `README.md`, `docs`, `scripts`, and `examples`, excluding generated portal assets. Raw matches were classified as pre-existing safety disclaimers, legal warnings, API return descriptions, scanner patterns, moderation examples, or technical gas-price/minimum-gas-prices usage.

Changed-file audit after cleanup found only allowed classes:
- `docs/audit/AUDIT_PACKAGE_INDEX.md`: limitation text saying local agents do not prove external decentralisation
- this results document: audit-summary references to the same limitation and technical gas-price classification
- `scripts/testnet/run-five-agent-restart-check.sh`: technical `--minimum-gas-prices` flags

No positive launch, token-buyability, public sale, financial-upside, package-publishing, external-validator, or secret-handling claim was introduced by Phase 16C.
