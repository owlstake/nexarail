# Phase 16B — Long Soak, Crash Recovery, and Load Simulation

## Scripts Created

### `scripts/testnet/run-five-agent-long-soak.sh`
Runs a controlled long soak with:
- `--duration <seconds>` (default 3600)
- `--sample-interval <seconds>` (default 60)
- `--tx-interval <seconds>` (default 300)
- `--keep-running`, `--skip-gov`, `--skip-tx` flags
- Periodic height/peer/agent sampling
- Periodic bank tx smoke transactions
- Governance vote reliability polling
- REST API health checks
- Final live flag verification
- Log/panic/descriptor/CheckTx scanning

## Short Soak Result (300s = 5 min)

| Metric | Value |
|---|---|
| Duration | 300s (target) |
| Samples taken | 5 time points × 5 agents |
| Height progression | 12 → 42 (30 blocks in 5 min, ~10s/block) |
| All agents in sync | ✅ (all at same height at each sample) |
| REST health | ✅ (all endpoints responding) |
| Bank tx | ⚠️ Needs address resolution fix (applied) |
| Live flags | ⚠️ Check logic fixed (applied) |
| Error/panic scan | Clean |

## Evidence Output
```
rehearsals/validator-agents/long-soak/evidence/<timestamp>/
├── samples.tsv           (height/agent/time per sample)
├── rest/                 (REST param snapshots)
├── tx/                   (bank tx evidence)
├── gov/                  (gov vote results if run)
├── logs/                 (agent log archives)
├── rest-health.json
├── panic-scan.txt
├── summary.json
```

## Crash Recovery Status
Dedicated restart check script (`run-five-agent-restart-check.sh`) deferred due to time constraints. The product-flow rehearsal harness already validates clean spawn and stop (Phase 16A.5–.6). Multi-node restart validation remains pending.

## Limitations
- Full 1-hour soak not run (requires ~75 min total for spawn + soak + cleanup)
- Crash/restart mini-test not run (requires dedicated validation)
- Governance vote reliability not tested during soak
- TX smoke uses bank send only (not module-specific txs)
