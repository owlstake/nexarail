# NexaRail Devnet Validator Runbook

## Overview

This runbook covers operating a NexaRail devnet validator node. For production deployment, additional hardening is required.

## Prerequisites

- Go 1.22+
- NexaRail binary (`nexaraild`) built from source or downloaded release

## Initial Setup

### 1. Initialize the Node

```bash
nexaraild init <node-moniker> \
  --chain-id nexarail-devnet-1
```

This creates `~/.nexarail/` with:
- `config/config.toml` — CometBFT configuration
- `config/app.toml` — Cosmos SDK application configuration
- `config/genesis.json` — Genesis file (copy from trusted source)
- `config/priv_validator_key.json` — Validator private key
- `data/priv_validator_state.json` — Validator state

### 2. Configure `config/app.toml`

```toml
minimum-gas-prices = "0.025unxrl"

# Enable API server (validator 0 only)
[api]
enable = true
address = "tcp://0.0.0.0:1317"

# Enable gRPC (validator 0 only)
[grpc]
enable = true
address = "0.0.0.0:9090"
```

### 3. Configure `config/config.toml`

```toml
# Allow all IPs (devnet only — restrict in production)
addr_book_strict = false

# Set persistent peers
persistent_peers = "<validator0-node-id>@<validator0-ip>:26656"

# Enable Prometheus for monitoring
prometheus = true
```

### 4. Get the Genesis File

```bash
# Copy from a trusted source
cp /path/to/genesis.json ~/.nexarail/config/genesis.json

# Validate
nexaraild validate-genesis
```

## Running the Node

### Standard Start

```bash
nexaraild start \
  --minimum-gas-prices 0.025unxrl \
  --rpc.laddr tcp://0.0.0.0:26657 \
  --p2p.laddr tcp://0.0.0.0:26656
```

### Start with Custom Home

```bash
nexaraild start --home /path/to/custom/home
```

## Creating a Validator

### 1. Create or Import a Key

```bash
# Create new key
nexaraild keys add <key-name> --keyring-backend test

# Import existing mnemonic
nexaraild keys add <key-name> --recover --keyring-backend test
```

### 2. Create a Self-Delegation Transaction

```bash
nexaraild tx staking create-validator \
  --amount 1000000000unxrl \
  --pubkey $(nexaraild tendermint show-validator) \
  --moniker "<moniker>" \
  --chain-id nexarail-devnet-1 \
  --commission-rate "0.10" \
  --commission-max-rate "0.20" \
  --commission-max-change-rate "0.01" \
  --min-self-delegation "1" \
  --from <key-name> \
  --keyring-backend test \
  --gas auto
```

### 3. Confirm Validator is Active

```bash
nexaraild query staking validators
```

## Common Operations

### Check Node Status

```bash
nexaraild status
# or
curl http://localhost:26657/status
```

### Query Balance

```bash
nexaraild query bank balances <address>
```

### Delegate Tokens

```bash
nexaraild tx staking delegate \
  <validator-address> \
  500000000unxrl \
  --from <delegator> \
  --chain-id nexarail-devnet-1 \
  --gas auto
```

### Submit Governance Proposal

```bash
# Text proposal
nexaraild tx gov submit-proposal \
  --title "Test Proposal" \
  --description "Testing governance" \
  --deposit 1000000000unxrl \
  --type Text \
  --from <key-name> \
  --chain-id nexarail-devnet-1

# Parameter change proposal
nexaraild tx gov submit-proposal param-change \
  <proposal-json-file> \
  --from <key-name> \
  --chain-id nexarail-devnet-1

# Vote
nexaraild tx gov vote <proposal-id> Yes \
  --from <key-name> \
  --chain-id nexarail-devnet-1
```

### View Blocks and Transactions

```bash
# Latest block
nexaraild block

# Block at height
nexaraild block <height>

# Transaction by hash
nexaraild query tx <tx-hash>
```

## Troubleshooting

### Node Won't Start

1. Check logs for errors
2. Verify genesis file: `nexaraild validate-genesis`
3. Clear data: `rm -rf ~/.nexarail/data`
4. Re-initialize with fresh genesis

### Validator Not Signing

1. Check `priv_validator_key.json` exists
2. Verify correct node is in validator set
3. Check peers are connected

### Peers Not Connecting

1. Ensure `persistent_peers` is set correctly
2. Verify both nodes are using the same chain ID
3. Check firewall rules allow port 26656

### "Wrong Block.Header.AppHash" Error

1. The node has processed a different chain state
2. Usually requires a fresh start with `unsafe-reset-all`

## Security Notes (Devnet)

- The devnet uses `keyring-backend test` which stores keys in plaintext
- No TLS configured for RPC/API endpoints
- All validators run on localhost
- Minimum gas prices set to prevent spam

## Reset Devnet

```bash
# Stop all nodes
pkill -f nexaraild

# Reset data
make reset-devnet

# Re-initialize
make init-devnet
make start-devnet
```
