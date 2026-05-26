# NexaRail Phase 6K — External Docker Runtime Execution

**Date:** 2026-05-25
**Status:** Package ready — execution pending on Docker-capable machine

## Machine Requirements

| Requirement | Minimum |
|---|---|
| Docker Engine | 24+ with Compose plugin (`docker compose`) |
| OS | macOS 14+ (Apple Silicon) or Ubuntu 22.04+ (amd64/arm64) |
| RAM | 8 GB free |
| Disk | 5 GB free |
| Ports | 26656-26677, 1317-1319, 9090-9092 free |
| Tools | `git`, `make`, `jq`, `python3`, `curl` |

## Docker Version Check

```bash
docker --version        # 24.0+
docker compose version  # v2.20+
```

## Setup Commands

```bash
# 1. Clone
git clone https://github.com/Bookings-cpu/nexarail.git
cd nexarail

# 2. Checkout the target commit
git checkout main   # or specific tag

# 3. Build
make build
# Binary: build/nexaraild

# 4. Verify
go test ./...    # All 14 packages pass

# 5. Prepare Docker genesis
./scripts/testnet/prepare-docker-3-validator-rehearsal.sh
# Expected: gen_txs: 3, genesis validated, p2p-summary.txt created
```

## One-Command Run

```bash
./scripts/testnet/run-docker-3-validator-rehearsal.sh
```

## Expected Output

```
╔══════════════════════════════════════════╗
║  🚀 3 VALIDATORS PRODUCING BLOCKS!     ║
║  Height: 5  Peers: 2                   ║
╚══════════════════════════════════════════╝
```

If the script times out (120s), check logs:
```bash
./scripts/testnet/logs-docker-3-validator-rehearsal.sh
```

## How to Collect Logs

```bash
# Individual validator logs
docker compose -f rehearsals/testnet-1/docker/docker-compose.yml logs val0 > val0.log
docker compose -f rehearsals/testnet-1/docker/docker-compose.yml logs val1 > val1.log
docker compose -f rehearsals/testnet-1/docker/docker-compose.yml logs val2 > val2.log

# Or use the helper
./scripts/testnet/logs-docker-3-validator-rehearsal.sh > rehearsal-logs.txt
```

## How to Stop/Reset

```bash
# Stop (preserves validator data)
./scripts/testnet/stop-docker-3-validator-rehearsal.sh

# Full reset
rm -rf rehearsals/testnet-1/docker/validator-notes/
./scripts/testnet/prepare-docker-3-validator-rehearsal.sh
./scripts/testnet/run-docker-3-validator-rehearsal.sh
```

## What Proof to Capture

Run the evidence collector:
```bash
./scripts/testnet/collect-docker-rehearsal-evidence.sh
```

This produces: `rehearsals/testnet-1/docker/evidence/<timestamp>/`

Required proof:
- [ ] `docker ps` showing 3 running containers
- [ ] val0/val1/val2 status JSON with height > 0
- [ ] Chain ID = `nexarail-testnet-1`
- [ ] Peer count ≥ 2
- [ ] All 6 live flags = false
- [ ] gen_txs = 3 in p2p-summary.txt
- [ ] No panics in validator logs
- [ ] build/vet/test output green

## Troubleshooting

| Symptom | Check |
|---|---|
| Port conflict | `lsof -i :26656-26677` and kill stale processes |
| `docker compose` not found | Use `docker-compose` (v1) or install Compose plugin |
| Containers exit immediately | `docker compose logs val0` |
| Height stays 0, peers=0 | Check persistent_peers in `p2p-summary.txt` — service names must match Docker hostnames |
| "error in app.toml" | Remove app.toml from validator homes; `--minimum-gas-prices` flag is used |
| "gen_txs: 0" | `collect-gentxs` may need `--home` pointing to val0; re-run preparation script |
