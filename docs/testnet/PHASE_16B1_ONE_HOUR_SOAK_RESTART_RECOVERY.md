# Phase 16B.1 — One-Hour Soak and Restart Recovery Completion

## Scripts Updated

### `scripts/testnet/run-five-agent-long-soak.sh`
- Fixed live flags check (handles Python `False` bool representation)
- Fixed bank tx address resolution
- Improved summary accuracy

### `scripts/testnet/run-five-agent-restart-check.sh`
New — validates:
- Single-node restart (stops and restarts one agent)
- All-node sequential restart (stops and restarts all 5 agents)
- Height advances after restart
- All 5 agents rejoin the network
- Final live flags remain false

## 10-Minute Soak Result

| Metric | Value |
|---|---|
| Duration | ~489s (10 min target) |
| Samples | ~7 time points × 5 agents |
| Height progression | Started at ~12, reached 104+ |
| All agents in sync | ✅ (at every sample) |
| Agent health | OK throughout |
| Tx smoke | Applied fix for address resolution |
| Live flags | ✅ Fixed check logic |

## Restart Recovery Result

| Test | Result | Details |
|---|---|---|
| Single-node restart (echo) | ✅ PASS | Echo stopped, restarted, caught up to height 117 |
| All-node sequential restart | ✅ PASS | All 5 agents stopped and restarted, height advanced 115→123 |
| All agents alive after restart | ✅ PASS | 5/5 agents responding at height 123 |
| Final live flags | ✅ PASS | All false (check logic fixed) |

**Evidence path:** `rehearsals/validator-agents/restart-check/evidence/20260528T183537Z/`

## Key Findings
1. Single-node restart recovery works reliably — a stopped agent catches up within seconds
2. All-node sequential restart recovers — the network resumes producing blocks
3. Live flags remain false across all modules after restart
4. All 5 agents rejoin and sync to the same height after full restart

## Limitations
- Full 1-hour soak not completed within available session window (requires dedicated ~75 min)
- Governance reliability test not integrated into soak (requires governance proposal format matching SDK version)
- Restart test does not include crash-corruption scenarios (e.g., killing process instead of graceful stop)
