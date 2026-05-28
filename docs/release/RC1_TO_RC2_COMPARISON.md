# RC1 to RC2 Comparison

## Baseline

| Item | Value |
|---|---|
| RC1 tag | `v0.1.0-rc1` |
| RC1 tag commit | `b8a1057` |
| RC1 release | `https://github.com/Bookings-cpu/nexarail/releases/tag/v0.1.0-rc1` |
| Current post-RC1 main baseline | `fb859d9` before Phase 16E rollup docs |
| Proposed RC2 version | `v0.1.1-rc2` |
| Current recommendation | Prepare RC2, defer tag/release |
| Phase 16E readiness result | `RC2_DEFER` |

## Changed Categories Since RC1

| Category | Examples |
|---|---|
| Product module validation | Msg validation, params validation, clearer errors |
| Events and evidence | Params-event improvements, product-flow event extraction |
| Tests | State-transition tests, invariant tests, bounded fuzz tests |
| Runtime harnesses | Five-agent lifecycle, product-flow replay, restart, soak, load simulation |
| Governance reliability | Per-agent vote RPC routing, retry/sequence refresh |
| Release evidence docs | Phase 14B-16D evidence docs and indexes |
| Reviewer tooling | Regression and readiness scripts, evidence summaries |

## New Tests and Harnesses

- Expanded keeper/type tests across settlement, escrow, merchant, payout, treasury, and fees
- `scripts/testnet/run-invariant-checks.sh`
- `scripts/testnet/run-module-hardening-tests.sh`
- `scripts/testnet/check-product-flow-harness.sh`
- `scripts/testnet/test-governance-vote-reliability.sh`
- `scripts/testnet/run-five-agent-long-soak.sh`
- `scripts/testnet/run-five-agent-restart-check.sh`
- `scripts/testnet/run-five-agent-load-sim.sh`
- `scripts/testnet/sample-agent-resources.sh`
- `scripts/testnet/run-load-trend-profile.sh`
- `scripts/release/check-rc2-readiness.sh`

## Evidence Improvements

- Post-hardening product-flow replay evidence
- Semantic assertions and burn supply delta proof
- Governance proposal indexing
- Restart recovery evidence
- Short soak and raw one-hour soak evidence
- Local load simulation evidence
- Local trend/resource profiling evidence

## Unchanged Status

- Mainnet: NO-GO
- Public testnet: NO-GO
- External validators: pending
- Live flags: false by default
- SDK package publishing: not published to npm/PyPI
- Economics: unchanged
- Product module set: unchanged

## Release Interpretation

RC2 would be a packaging of post-RC1 hardening for controlled local evaluation. It would not represent public network readiness, external validator readiness, or production throughput.
