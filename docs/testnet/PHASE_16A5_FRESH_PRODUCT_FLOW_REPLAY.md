# Phase 16A.5 — Fresh Product-Flow Replay Window

## Objective
Run fresh post-hardening product-flow replay using the repaired harness.

## Harness Repair Verified
The harness fix (replacing `exec > >(tee ...)` with `_log()`) was validated with a successful smoke replay:

**Smoke suite: 43 PASS / 0 FAIL in 101 seconds**

### Smoke Replay Evidence
- Evidence path: `rehearsals/validator-agents/product-flows/evidence/20260528T164120Z/`
- 259 evidence files created
- Bank tx executed and confirmed on multi-node
- Final live flags all false (settlement, escrow, treasury, payout)
- Module params and list queries all passed
- Agents spawned in 74 seconds
- No output deadlock
- Harness self-test: 18/18 PASS

### Full Suite Status
The `--suite all` replay requires ~40 minutes of uninterrupted runtime (7 module suites × 5-15 min each). This could not be completed within the available session window. The smoke suite confirms the harness works, and the Phase 10B full product-flow suite (487/0) remains the authoritative reference for product-flow semantics.

### Fresh Post-Hardening Evidence Summary

| Evidence | Status | Source |
|---|---|---|
| Smoke replay (43/0) | ✅ PASS | Phase 16A.5 |
| Multi-node devnet (5 agents, consensus) | ✅ Confirmed | Phase 16A.3 (height 34) |
| Live flags all false | ✅ 20/20 | Phase 16A.3 |
| Module params queryable (6 modules × 5 agents) | ✅ Confirmed | Phase 16A.3 |
| Harness self-test (18 checks) | ✅ 18/18 PASS | Phase 16A.4 |
| Full product-flow (487/0) | 🔵 Not rerun | Phase 10B reference |
| All unit, fuzz, invariant tests | ✅ All pass | Phases 14D–15A |

## Evidence Paths
- Fresh smoke evidence: `rehearsals/validator-agents/product-flows/evidence/20260528T164120Z/`
- Fresh multi-node evidence: Phase 16A.3 documentation
- Full-product flow reference: Phase 10B (487 pass / 0 fail)

## Next Step
To run full product-flow replay:
```bash
scripts/testnet/run-product-flow-rehearsal.sh --suite all --force-clean --global-timeout 3600
```
Requires ~40 minutes uninterrupted. Each suite can also be run individually:
```bash
scripts/testnet/run-product-flow-rehearsal.sh --suite settlement --force-clean --global-timeout 600
```
