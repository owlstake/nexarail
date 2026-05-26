# NexaRail Docker 3-Validator Rehearsal

**TESTNET REHEARSAL ONLY — zero-value tokens, local Docker.**

## Prerequisites

- Docker Engine 24+ with Compose plugin
- `jq` for query scripts
- `python3` for node ID extraction

## Quick Start

```bash
cd ~/workspace/nexarail

# 1. Build binary
make build

# 2. Prepare genesis + config (uses service-name P2P addresses)
./scripts/testnet/prepare-docker-3-validator-rehearsal.sh

# 3. Launch
./scripts/testnet/run-docker-3-validator-rehearsal.sh

# 4. Query
./scripts/testnet/query-docker-3-validator-rehearsal.sh

# 5. Stop
./scripts/testnet/stop-docker-3-validator-rehearsal.sh

# 6. View logs
./scripts/testnet/logs-docker-3-validator-rehearsal.sh
```

## Architecture

```
              Docker bridge: nexarail-testnet
    ┌─────────────────────────────────────────────┐
    │                                             │
    │  val0 (hostname: val0)                     │
    │    P2P: val0:26656  RPC: host:26657        │
    │                                             │
    │  val1 (hostname: val1)                     │
    │    P2P: val1:26656  RPC: host:26667        │
    │                                             │
    │  val2 (hostname: val2)                     │
    │    P2P: val2:26656  RPC: host:26677        │
    │                                             │
    └─────────────────────────────────────────────┘

    Persistent peers: <id0>@val0:26656,<id1>@val1:26656,<id2>@val2:26656
```

## Ports

| Validator | RPC | REST | gRPC |
|---|---|---|---|
| val0 | 26657 | 1317 | 9090 |
| val1 | 26667 | 1318 | 9091 |
| val2 | 26677 | 1319 | 9092 |

## Key Design Decision

Uses Docker **service-name hostnames** (`val0`, `val1`, `val2`) for P2P peer addresses instead of `127.0.0.1`. This resolves the CometBFT localhost P2P parsing issue documented in Phase 6H/6I.

## Cleanup

```bash
# Stop and remove containers, preserve validator data
./scripts/testnet/stop-docker-3-validator-rehearsal.sh

# Full cleanup including validator data
rm -rf rehearsals/testnet-1/docker/validator-notes/
```
