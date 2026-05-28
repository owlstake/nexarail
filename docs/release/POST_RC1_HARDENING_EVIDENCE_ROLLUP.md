# Post-RC1 Hardening Evidence Rollup

## Scope

This rollup summarizes post-RC1 hardening from Phase 14B through Phase 16D.

It is release-evidence documentation only. It does not launch a public testnet, does not change economics, does not enable live flags by default, does not publish SDK packages, and does not imply mainnet readiness or production throughput.

## Summary

Post-RC1 work materially improved the codebase and harnesses:
- product module validation and governance safety were audited
- validation and params-event fixes landed
- state-transition, invariant, bounded fuzz, and runtime invariant tests were added
- five-agent local runtime validation was expanded
- product-flow replay ran across all modules
- governance vote sequence/routing was hardened
- restart recovery, soak, load, and local trend profiling evidence was captured

Remaining release-quality gates:
- canonical one-hour soak rerun with the patched harness
- targeted governance/product-flow replay after the Phase 16A.7 vote reliability fix
- final RC2 readiness script and safety audit

Phase 16E readiness result:
- `scripts/release/check-rc2-readiness.sh`
- PASS=29, FAIL=0, SKIP=0, WARN=2, DEFER=2, BLOCK=0
- recommendation: `RC2_DEFER`

Phase 16E safety audit:
- PASS
- evidence: `rehearsals/rc2-readiness/evidence/phase16e-safety-audit-20260528T235319Z/`

## Phase Table

| Phase | Purpose | Code/docs/scripts changed | Evidence result | Commit hash | Launch impact |
|---|---|---|---|---|---|
| 14B | Product module validation, governance, event, and error audits | Audit docs and module validation review | Audit completed; hardening gaps identified | `096e064` | No launch-status change |
| 14C | Validation and params-event fixes | Product module msg validation and event emissions | Fixes documented and tested | `e2db010`, `302e283` | No launch-status change |
| 14D | State transition and invariant test expansion | Keeper/type tests across modules | Expanded deterministic tests | `3d2064f` | No launch-status change |
| 15A | Bounded fuzz tests and invariant framework | Fuzz/invariant scripts and tests | Fuzz/invariant framework added | `6b51ffd` | No launch-status change |
| 16A | Five-agent multi-node validation | Agent lifecycle harnesses and evidence docs | Five-agent local devnet validation improved | `9749a24` | Local-only evidence |
| 16A.6 | Full product-flow replay | Product-flow harness/evidence docs | 486 PASS / 1 transient vote tx failure; proposal still passed; final live flags false | `14181da` | Needs targeted replay before RC2 tag |
| 16A.7 | Governance vote reliability | Product-flow vote routing and retry logic | Root cause documented; each validator votes through own RPC with retry/sequence refresh | `97ec215` | Improves local governance harness reliability |
| 16B.1 | Restart recovery and short soak | Restart and soak scripts/docs | One-node restart passed; all-node sequential restart passed; short soak passed | `27a221b`, `03eb76f` | Local-only recovery evidence |
| 16B.2 | One-hour soak inspection | Long-soak/restart harness fixes and results doc | Raw one-hour stability passed; canonical summary needs patched rerun | `fb859d9` | Defer gate for RC2 tag |
| 16C | Load simulation and throughput profiling | Load runner, plan/results docs, evidence indexes | Smoke, 10-minute, and heavier local load runs passed; final live flags false; scans clean | `fb859d9` | Local-only load baseline |
| 16D | Local multi-run trend and limit profiling | Trend plan, resource sampler, trend runner, load-runner resource hooks | L1/L2 passed; L3 passed; L4 interrupted by Phase 16E handoff and is non-canonical | Phase 16E commit | Local-only trend baseline |

## Key Evidence

### Product-Flow Replay

Evidence path:

```text
rehearsals/validator-agents/product-flows/evidence/20260528T170347Z/
```

Result:
- 486 PASS / 1 FAIL
- single failure: transient governance vote sequence/routing issue
- proposal still passed
- semantic assertions: 36/36
- governance proposals: 22
- burn supply delta: -2000 unxrl
- final live flags: false

Follow-up:
- Phase 16A.7 fixed vote routing and retry behavior
- targeted replay is still recommended before RC2 tag

### Restart and Soak

Evidence path:

```text
rehearsals/validator-agents/restart-check/evidence/20260528T183537Z/
```

Result:
- one-node restart passed
- all-node sequential restart passed
- all agents alive after restart
- final live flags false

One-hour soak raw evidence:

```text
rehearsals/validator-agents/long-soak/evidence/phase16b2-20260528T190803Z/
```

Result:
- height 164 to 832
- height delta 668
- max inter-agent drift 1 block
- REST health passed
- live flags manually rechecked false
- log scans manually recomputed as clean

Limitation:
- original harness did not write canonical `summary.json`
- tx smoke evidence was non-canonical
- patched-harness rerun remains required before RC2 tag

### Phase 16C Load Simulation

Evidence paths:

```text
rehearsals/validator-agents/load-sim/evidence/phase16c-smoke-20260528T213401Z/
rehearsals/validator-agents/load-sim/evidence/phase16c-10min-stable-20260528T215108Z/
rehearsals/validator-agents/load-sim/evidence/phase16c-heavy-20260528T220345Z/
```

Result:
- smoke: 45/45 tx included, 208/208 queries
- 10-minute: 220/220 tx included, 2330/2330 queries
- heavier: 876/876 tx included, 9020/9020 queries
- p95 tx inclusion roughly 6.2s or lower in passing runs
- p95 local query latency roughly 12ms or lower in passing runs
- peer count stable at 4 per node
- validator count stable at 5
- final live flags false
- panic/CheckTx/descriptor scans clean

Interpretation:
- local five-agent devnet observed throughput only
- not production throughput

### Phase 16D Trend Baseline

Evidence paths:

```text
rehearsals/validator-agents/load-trends/evidence/phase16d-L1L2-20260528T225534Z/
rehearsals/validator-agents/load-trends/evidence/phase16d-L3L4-20260528T231938Z/
```

Result:
- L1: 224/224 tx included, 2600/2600 queries, p95 tx 5576.7ms, p95 query 5ms
- L2: 448/448 tx included, 5030/5030 queries, p95 tx 5559.3ms, p95 query 5ms
- L3: 515/515 tx included, 7300/7300 queries, p95 tx 6876.6ms, p95 query 19ms
- L4: interrupted during Phase 16E handoff; not canonical evidence

Current conservative local ceiling from completed Phase 16D evidence: **L3 completed cleanly**, but **L2 is the conservative recommendation until L4 is rerun or formally failed/passed**.

## What Did Not Change

- No product modules were added.
- No economics changed.
- No validator economics changed.
- No live flags were enabled by default.
- No mainnet was launched.
- No public testnet was launched.
- No external validators were activated.
- No SDK packages were published to npm or PyPI.
- No production throughput claim is made.

## Remaining Limitations

- RC1 binaries do not include all post-RC1 hardening.
- One-hour soak needs a canonical rerun with the patched harness.
- Product-flow/governance path should be replayed after the Phase 16A.7 vote fix.
- External validator rehearsal remains pending.
- All load and trend results are local single-machine five-agent devnet observations.
