# NexaRail Phase 6C — Runtime Rehearsal

**Document:** docs/testnet/PHASE_6C_RUNTIME_REHEARSAL.md
**Date:** 2026-05-25
**Status:** Scripts complete — execution blocked by `nexaraild init` CLI bug

## Environment Required

- **OS:** macOS 14+ (Apple Silicon) or Ubuntu 22.04+
- **Go:** 1.22+
- **Tools:** `jq`, `curl`
- **Ports:** 26656-26677 (P2P), 26657-26677 (RPC), 1317-1319 (REST), 9090-9092 (gRPC)

## Commands to Run

```bash
cd ~/workspace/nexarail

# 1. Build
make build

# 2. Stop any existing validators
pkill -f "nexaraild start" || true

# 3. Launch rehearsal (requires --clean first time)
./scripts/testnet/run-local-3-validator-rehearsal.sh --clean

# 4. Wait for block height > 5 (script waits up to 60s)

# 5. Query
./scripts/testnet/query-local-3-validator-rehearsal.sh

# 6. Governance toggle
./scripts/testnet/rehearsal-governance-toggle.sh

# 7. Stop
./scripts/testnet/stop-local-3-validator-rehearsal.sh
```

## Expected Output

- 3 validators start and connect
- Chain ID: `nexarail-testnet-1`
- Blocks produced (height > 5 within 60s)
- All module params queryable via REST
- All 6 live flags default false
- Governance toggle succeeds (enable → query → disable)

## Port Map

| Validator | P2P | RPC | REST | gRPC |
|---|---|---|---|---|
| val0 | 26656 | 26657 | 1317 | 9090 |
| val1 | 26666 | 26667 | 1318 | 9091 |
| val2 | 26676 | 26677 | 1319 | 9092 |

## Validator Homes

| Validator | Home Directory |
|---|---|
| val0 | `rehearsals/testnet-1/validator-notes/val0/` |
| val1 | `rehearsals/testnet-1/validator-notes/val1/` |
| val2 | `rehearsals/testnet-1/validator-notes/val2/` |

## Log Locations

| Log | Path |
|---|---|
| val0 | `rehearsals/testnet-1/logs/val0.log` |
| val1 | `rehearsals/testnet-1/logs/val1.log` |
| val2 | `rehearsals/testnet-1/logs/val2.log` |
| PIDs | `rehearsals/testnet-1/logs/pids.txt` |

## How to Stop/Reset

```bash
# Stop
./scripts/testnet/stop-local-3-validator-rehearsal.sh

# Reset (clean start)
./scripts/testnet/stop-local-3-validator-rehearsal.sh
./scripts/testnet/run-local-3-validator-rehearsal.sh --clean
```

## Troubleshooting

### "client context not set" on init

**Root cause:** `cmd/nexaraild/cmd/root.go` `PersistentPreRunE` requires a valid `client.toml` before any command can run, including `init`. Since `init` creates the home directory, this is a circular dependency.

**Fix:** The `PersistentPreRunE` must handle missing `client.toml` gracefully. See the fix applied in this commit (made `config.ReadFromClientConfig` failure non-fatal).

**If init still fails:** The Go-generated genesis approach may be needed. Run:
```bash
# Use the manual init helper
./scripts/testnet/gen-rehearsal-genesis.sh nexarail-testnet-1 rehearsals/testnet-1/validator-notes/val0
```

### Port conflicts

```bash
lsof -i :26656-26677  # Check P2P ports
lsof -i :1317-1319    # Check REST ports
pkill -f nexaraild    # Kill existing processes
```

### Validators not connecting

Check persistent peers in `config.toml`. All validators on localhost need `allow_duplicate_ip = true`.

### Blocks not produced

```bash
tail -50 rehearsals/testnet-1/logs/val0.log | grep -i "error\|panic\|timeout"
```
