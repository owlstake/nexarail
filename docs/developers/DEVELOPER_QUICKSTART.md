# NexaRail Developer Quickstart

> ⚠️ **NOT** a public testnet. **NOT** mainnet. **NO** token sale.
> Tokens on this devnet have **zero monetary value** — test tokens only.

## What You Can Do on a Local Devnet

A local NexaRail devnet gives you a full Cosmos SDK blockchain running on your machine. You can:

- **Query committed chain state** — block height, validator set, bank balances
- **Explore all 6 NexaRail modules** — create merchants, post settlements, manage escrows, run treasury operations, create payouts, inspect fee configurations
- **Test integration scenarios** — connect a dashboard or CLI tool to the REST API
- **Toggle live-funds flags** via governance proposals (using `product-gov.sh`)
- **Verify product flows** end-to-end with smoke-test scripts
- **Inspect module state** through custom REST readback endpoints (35+ endpoints)

## Prerequisites

- Go 1.26+ or a pre-built `nexaraild` binary for your platform
- `bash`, `curl`, `jq` (standard on macOS/Linux)
- No external services, cloud accounts, or network access required

### Build the Binary

```bash
cd /Users/bradleyjohnston/workspace/nexarail
make build
```

This produces `./build/nexaraild`.

---

## Launch RC1 Devnet (Single-Node)

The recommended way to start a local devnet for development work:

```bash
bash scripts/release/launch-rc1-devnet.sh --single-node --clean
```

What this does:

1. Initialises a fresh chain at `~/.nexarail-devnet`
2. Creates the `devnet-key` key pair (test keyring)
3. Funds the genesis account with `1000000000unxrl`
4. Creates and collects a genesis transaction
5. Patches genesis for short governance voting (30s) and the `unxrl` bond denom
6. Starts a single `nexaraild` node on default ports
7. Waits for RPC readiness and at least 10 blocks of consensus

**Ports:**

| Service | Port |
|---------|------|
| CometBFT RPC | `26657` |
| REST API | `1317` |
| gRPC | `9090` |

When running, you see output like:

```
  ✅ RPC ready after 3s
  ✅ Height 12 reached
  ✅ Single-node devnet running
  RPC:  http://127.0.0.1:26657
  REST: http://127.0.0.1:1317
```

### Alternative: Five-Agent Devnet

```bash
bash scripts/release/launch-rc1-devnet.sh --five-agent --clean
```

Launches 5 validator agents on ports `27657-27697` with P2P networking (peer-to-peer, technical P2P layer — not validator-set decentralisation). Used for multi-validator testing.

---

## Query Status

### Block Height (CometBFT RPC)

```bash
curl -s http://127.0.0.1:26657/status | jq '.result.sync_info.latest_block_height'
```

Example response: `"12"`

### Network Info

```bash
curl -s http://127.0.0.1:26657/status | jq '.result.node_info.network'
```

Example response: `"nexarail-devnet-1"`

### Validator Set

```bash
curl -s http://127.0.0.1:26657/validators | jq '.result.validators[0].address'
```

### Bank Balances (CLI)

```bash
./build/nexaraild query bank balances nxrl1... --node tcp://localhost:26657
```

Or via the key name:

```bash
./build/nexaraild query bank balances $(./build/nexaraild keys show devnet-key -a --keyring-backend test --home ~/.nexarail-devnet) --node tcp://localhost:26657
```

---

## Query Live Flags (REST Params Endpoints)

All 6 live flags are readable from the params endpoints. Default: `false`.

```bash
# Module-level live flags
curl -s http://127.0.0.1:1317/nexarail/settlement/v1/params | jq '.params.live_enabled'
curl -s http://127.0.0.1:1317/nexarail/escrow/v1/params      | jq '.params.live_enabled'
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/params    | jq '.params.live_enabled'
curl -s http://127.0.0.1:1317/nexarail/payout/v1/params      | jq '.params.live_enabled'

# Settlement sub-flags
curl -s http://127.0.0.1:1317/nexarail/settlement/v1/params | jq '.params.treasury_routing_enabled'
curl -s http://127.0.0.1:1317/nexarail/settlement/v1/params | jq '.params.burn_routing_enabled'
```

All should return `false` on a fresh devnet.

For a full formatted view:

```bash
curl -s http://127.0.0.1:1317/nexarail/settlement/v1/params | jq .
curl -s http://127.0.0.1:1317/nexarail/escrow/v1/params | jq .
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/params | jq .
curl -s http://127.0.0.1:1317/nexarail/payout/v1/params | jq .
```

---

## Call REST Endpoints

All 35+ custom REST endpoints are read-only `GET` queries returning JSON. They live under `/nexarail/{module}/v1/`.

### Params (each module)

```bash
# Module params
curl -s http://127.0.0.1:1317/nexarail/fees/v1/params | jq .
curl -s http://127.0.0.1:1317/nexarail/settlement/v1/params | jq .
curl -s http://127.0.0.1:1317/nexarail/escrow/v1/params | jq .
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/params | jq .
curl -s http://127.0.0.1:1317/nexarail/merchant/v1/params | jq .
curl -s http://127.0.0.1:1317/nexarail/payout/v1/params | jq .
```

### Lists

```bash
curl -s http://127.0.0.1:1317/nexarail/merchant/v1/merchants | jq .
curl -s http://127.0.0.1:1317/nexarail/settlement/v1/settlements | jq .
curl -s http://127.0.0.1:1317/nexarail/escrow/v1/escrows | jq .
curl -s http://127.0.0.1:1317/nexarail/payout/v1/payouts | jq .
curl -s http://127.0.0.1:1317/nexarail/payout/v1/batch-payouts | jq .
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/summary | jq .
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/accounts | jq .
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/budgets | jq .
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/grants | jq .
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/spends | jq .
```

### Detail by ID

```bash
curl -s http://127.0.0.1:1317/nexarail/settlement/v1/settlement/1 | jq .
curl -s http://127.0.0.1:1317/nexarail/escrow/v1/escrow/escrow-001 | jq .
curl -s http://127.0.0.1:1317/nexarail/payout/v1/payout/payout-001 | jq .
curl -s http://127.0.0.1:1317/nexarail/payout/v1/batch-payout/batch-001 | jq .
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/account/acct-001 | jq .
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/budget/bgt-001 | jq .
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/grant/grant-001 | jq .
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/spend/spend-001 | jq .
```

### Filtered Lists

```bash
curl -s "http://127.0.0.1:1317/nexarail/settlement/v1/settlements/by-merchant/{owner-address}" | jq .
curl -s "http://127.0.0.1:1317/nexarail/settlement/v1/settlements/by-payer/{payer-address}" | jq .
curl -s "http://127.0.0.1:1317/nexarail/escrow/v1/escrows/by-buyer/{buyer-address}" | jq .
curl -s "http://127.0.0.1:1317/nexarail/escrow/v1/escrows/by-seller/{seller-address}" | jq .
curl -s "http://127.0.0.1:1317/nexarail/escrow/v1/escrows/by-merchant/{merchant-id}" | jq .
curl -s "http://127.0.0.1:1317/nexarail/payout/v1/payouts/by-merchant/{merchant-id}" | jq .
curl -s "http://127.0.0.1:1317/nexarail/payout/v1/payouts/by-recipient/{recipient-address}" | jq .
curl -s "http://127.0.0.1:1317/nexarail/payout/v1/payouts/by-initiator/{initiator-address}" | jq .
```

### Exists Checks

```bash
curl -s "http://127.0.0.1:1317/nexarail/escrow/v1/escrow/exists/{id}" | jq .
curl -s "http://127.0.0.1:1317/nexarail/payout/v1/payout/exists/{id}" | jq .
```

### Fee Split

```bash
curl -s http://127.0.0.1:1317/nexarail/fees/v1/fee_split | jq .
```

---

## Create and Use Keys

The devnet creates a `devnet-key` automatically. To create additional keys:

```bash
./build/nexaraild keys add my-key --keyring-backend test --home ~/.nexarail-devnet
```

List keys:

```bash
./build/nexaraild keys list --keyring-backend test --home ~/.nexarail-devnet
```

Show a key's address:

```bash
./build/nexaraild keys show devnet-key -a --keyring-backend test --home ~/.nexarail-devnet
```

Delete a key:

```bash
./build/nexaraild keys delete my-key --keyring-backend test --home ~/.nexarail-devnet -y
```

> **Note:** Keys created with `--home ~/.nexarail-devnet` are local to your devnet. For production (mainnet), always use a dedicated keyring backend (e.g., `os` or `file`).

---

## Run Product-Flow Scripts

Two key scripts reference existing documentation:

### `product-gov.sh`

Located at `scripts/testnet/product-gov.sh`. Toggles live-funds flags via governance proposals.

```bash
# View current flags (dry-run safe)
bash scripts/testnet/product-gov.sh show-live-flags

# Dry-run toggles (no chain mutation)
bash scripts/testnet/product-gov.sh enable-escrow-live
bash scripts/testnet/product-gov.sh enable-settlement-live
bash scripts/testnet/product-gov.sh enable-treasury-live
bash scripts/testnet/product-gov.sh enable-payout-live

# Actual submit (requires --confirm flag on a running multi-agent devnet)
bash scripts/testnet/product-gov.sh enable-escrow-live --confirm
```

> **Important:** `product-gov.sh` is designed for the **five-agent** devnet pattern (bravo agent at `:27667` RPC). For single-node devnet, use direct CLI commands instead.

See `scripts/testnet/product-gov.sh` source for the full list of toggle commands.

### `api-smoke-test.sh`

Located at `scripts/testnet/api-smoke-test.sh`. Tests REST, RPC, and gRPC endpoints against a live node.

```bash
# Run against single-node devnet (default ports)
bash scripts/testnet/api-smoke-test.sh

# Run against custom endpoints
RPC="http://127.0.0.1:27657" REST="http://127.0.0.1:1417" bash scripts/testnet/api-smoke-test.sh
```

### Other Smoke Tests

```bash
# CLI E2E smoke test (requires running node)
bash scripts/testnet/cli-e2e-smoke-test.sh

# Live flags smoke test
bash scripts/live-flags-smoke-test.sh

# Live funds E2E test
bash scripts/live-funds-e2e-test.sh

# Full smoke test suite
bash scripts/smoke-test.sh
```

### Reference Document

For CLI product-flow commands (register merchant, escrow lifecycle, treasury spend, payout, settlement), see:

```
docs/testnet/LIVE_FUNDS_REHEARSAL_COMMANDS.md
```

---

## Local SDK Packages

Two developer SDKs are prepared for local install (not published):

- **Node.js** — `examples/node-client/` — `@nexarail/devnet-client@0.1.0-dev`
- **Python** — `examples/python-client/` — `nexarail-devnet-client==0.1.0.dev`

Local install and tests:

```bash
# Node
cd examples/node-client && node test/client.test.js

# Python
cd examples/python-client && python3 test_client.py
```

Both are local devnet only. No npm or PyPI publishing. Full status: `docs/developers/SDK_PACKAGE_PREPARATION.md`.

---

## Stop and Clean Up

### Stop the Node

```bash
bash scripts/release/stop-rc1-devnet.sh
```

For a more aggressive stop:

```bash
bash scripts/release/stop-rc1-devnet.sh --force
```

### Wipe All Devnet State

```bash
rm -rf ~/.nexarail-devnet
rm -rf rehearsals/rc1-devnet
```

The `--clean` flag on `launch-rc1-devnet.sh` does this automatically.

---

## Key Developer Tips

| Topic | Guidance |
|-------|----------|
| **REST port** | `1317` for single-node, `1417` (bravo) for five-agent |
| **RPC port** | `26657` for single-node, `27657` (alpha) for five-agent |
| **Default denom** | `unxrl` (1 NXRL = 1,000,000 unxrl) |
| **Chain ID** | `nexarail-devnet-1` |
| **Governance voting** | 30 seconds (patched in genesis for dev speed) |
| **Min deposit** | `1000000unxrl` |
| **Build output** | `./build/nexaraild` |
| **Binary for release** | `releases/testnet-rc1/binaries/nexaraild-*` |
| **Evidence dir** | `rehearsals/rc1-devnet/evidence/` |
| **Logs** | `rehearsals/rc1-devnet/logs/` |
| **PIDs** | `rehearsals/rc1-devnet/pids/` |

### Troubleshooting

**Node won't start (port in use):**

```bash
lsof -iTCP:26657 -sTCP:LISTEN  # check RPC port
lsof -iTCP:1317 -sTCP:LISTEN   # check REST port
bash scripts/release/stop-rc1-devnet.sh --force
```

**REST responses return empty or error:**

Ensure the node is running and has reached block height > 0. The REST API is served on port `1317` (check `--api.enable` and `--api.address` in the start command).

**"not found" responses for queries:**

These are expected on a fresh devnet — no merchants, settlements, escrows, etc. Created data using product-flow scripts first.

---

## SDK Documentation

The following SDK documentation is available for developers integrating against the NexaRail devnet:

| Resource | Description |
|---|---|
| [SDK RC1 Release Notes](SDK_RC1_RELEASE_NOTES.md) | Release notes covering changes, installation, and usage |
| [Node.js SDK API Reference](NODE_SDK_API_REFERENCE.md) | Full API reference for `@nexarail/devnet-client` |
| [Python SDK API Reference](PYTHON_SDK_API_REFERENCE.md) | Full API reference for `nexarail-devnet-client` |
| [SDK Recipes](SDK_RECIPES.md) | Common usage patterns and integration examples |

The SDK archives are available locally at `releases/sdk-local/` for offline development. These are **LOCAL DEVNET ONLY** — not published to npm or PyPI.

## Limitations

- **No public testnet** — this is a local devnet only
- **No mainnet** — NexaRail mainnet does not exist yet
- **No token sale** — tokens have zero monetary value
- **No authentication** — REST/RPC are wide open (localhost only)
- **No rate limiting** — endpoints are designed for local development
- **No pagination** — list endpoints return all records
- **No caching** — every request reads from the KV store
- **No SLAs** — data is ephemeral and may be reset

See `docs/api/REST_READBACK_LIMITATIONS.md` for full details.
