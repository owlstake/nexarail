# Runtime Config Hardening — NexaRail

**Date:** 2026-05-26
**Phase:** 8A

---

## Recommended Configurations

### Devnet (Local Development)

```toml
# app.toml
[api]
enable = true
address = "tcp://0.0.0.0:1317"

[grpc]
enable = true
address = "0.0.0.0:9090"

[grpc-web]
enable = false

[state-sync]
snapshot-interval = 0
snapshot-keep-recent = 2

[rosetta]
enable = false

[telemetry]
enabled = false

minimum-gas-prices = "0unxrl"
pruning = "nothing"
halt-height = 0
halt-time = 0
min-retain-blocks = 0
inter-block-cache = true
index-events = []
iavl-cache-size = 781250
iavl-disable-fastnode = false

# config.toml
[rpc]
laddr = "tcp://0.0.0.0:26657"
cors_allowed_origins = ["*"]
unsafe = false
max_open_connections = 900

[p2p]
laddr = "tcp://0.0.0.0:26656"
pex = true
addr_book_strict = false
allow_duplicate_ip = true
persistent_peers = "<node-id>@<ip>:26656"

[mempool]
size = 5000
max_txs_bytes = 1073741824
max_tx_bytes = 1048576

[consensus]
timeout_commit = "5s"
timeout_propose = "3s"
```

### Controlled Testnet

```toml
# app.toml
[api]
enable = true
address = "tcp://0.0.0.0:1317"

[grpc]
enable = true
address = "0.0.0.0:9090"

[state-sync]
snapshot-interval = 1000
snapshot-keep-recent = 2

[rosetta]
enable = false  # Rosetta not functional for custom modules

[telemetry]
enabled = true
prometheus-retention-time = 60

minimum-gas-prices = "0.025unxrl"
pruning = "default"
pruning-keep-recent = "2"
pruning-interval = "10"

# config.toml
[rpc]
laddr = "tcp://0.0.0.0:26657"
unsafe = false

[p2p]
laddr = "tcp://0.0.0.0:26656"
pex = true
addr_book_strict = false
allow_duplicate_ip = false  # stricter in testnet
persistent_peers = "<node-id>@<ip>:26656"
max_num_inbound_peers = 40
max_num_outbound_peers = 10

[tx-index]
indexer = "kv"

[mempool]
size = 5000

[consensus]
timeout_commit = "5s"
```

---

## Unsafe Options (Do Not Use in Production)

| Option | Risk |
|---|---|
| `addr_book_strict = false` | Allows non-routable IPs — use only in devnet/testnet |
| `allow_duplicate_ip = true` | Allows multiple peers from same IP — testing only |
| `rpc.unsafe = true` | Exposes unsafe RPC methods |
| `cors_allowed_origins = ["*"]` | Allows any origin for CORS — testing only |
| `pruning = "nothing"` | Disk usage grows unbounded — never in production |
| `minimum-gas-prices = "0unxrl"` | Zero gas price — spam risk, testing only |
| `api.address = "tcp://0.0.0.0:1317"` | Exposes API to all interfaces — use firewall |
| `rpc.laddr = "tcp://0.0.0.0:26657"` | Exposes RPC to all interfaces — use firewall |

---

## Production Warnings

### Do NOT use in production or with real value:
- `allow_duplicate_ip = true`
- `minimum-gas-prices = "0unxrl"`
- `pruning = "nothing"`
- `cors_allowed_origins = ["*"]`
- `rpc.unsafe = true`
- `[rosetta] enable = true` (not functional for NexaRail custom modules)

### Always configure in production:
- `addr_book_strict = true`
- `allow_duplicate_ip = false`
- `minimum-gas-prices` set to a non-zero value
- `pruning = "default"` or `"custom"`
- Firewall rules restricting ports 26657, 1317, 9090
- Telemetry for monitoring

---

## Module Account Configuration

The following module accounts are created at genesis:

| Account | Purpose | Permissions |
|---|---|---|
| `nexarail_escrow` | Escrow custody pool | None (manual transfer) |
| `nexarail_treasury` | Treasury fund pool | None (manual transfer) |
| `nexarail_fee_router` | Fee routing intermediary | None |
| `nexarail_burner` | Burn routing destination | Burner |

All live fund routing is disabled by default. These accounts receive no funds until governance enables routing.

---

## API Defaults

| Service | Port | Default Status | Phase 6J.2 Fix |
|---|---|---|---|
| RPC | 26657 | ✅ Enabled | — |
| REST API | 1317 | ❌ Disabled by default | Fixed — `app.toml` patched in prepare script |
| gRPC | 9090 | ✅ Enabled | — |
| P2P | 26656 | ✅ Enabled | — |

---

## Diagnostic Commands

```
nexaraild debug-p2p-config       # Print loaded P2P/RPC config
nexaraild debug-live-flags       # Print all 6 live flags from genesis
nexaraild debug-module-summary   # Print module summary and warnings
```

---

## Config Generation

The `prepare-docker-3-validator-rehearsal.sh` script automatically:
- Enables `[api] enable = true`
- Sets `address = "tcp://0.0.0.0:1317"` for API
- Sets appropriate P2P config for Docker testnet
