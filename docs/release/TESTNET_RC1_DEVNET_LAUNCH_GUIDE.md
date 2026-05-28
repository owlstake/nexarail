# NexaRail Testnet RC1 — Devnet Launch Guide

**Self-contained local devnet for reviewers and internal development.**

⚠️ **SAFETY DISCLAIMER — READ FIRST**

This document describes how to launch a **local devnet** using the NexaRail Testnet RC1 binaries. This is **NOT** a public testnet. This is **NOT** a mainnet. No token sale has occurred. All tokens minted in this devnet carry **zero economic value**. The network runs with all live-flag parameters set to `false` — no real funds, transfers, or economic operation is possible. See `TESTNET_RC1_KNOWN_LIMITATIONS.md` for full details.

---

## Table of Contents

- [1. Supported Environments](#1-supported-environments)
- [2. Prerequisites](#2-prerequisites)
- [3. Mode Overview](#3-mode-overview)
- [4. Single-Node Mode (Quick Dev/Eval)](#4-single-node-mode-quick-deveval)
- [5. Five-Agent Mode (Multi-Validator)](#5-five-agent-mode-multi-validator)
- [6. Common Commands](#6-common-commands)
- [7. Limitations](#7-limitations)
- [8. Evidence Reference](#8-evidence-reference)

---

## 1. Supported Environments

| Platform | Architecture | Status |
|---|---|---|
| macOS | ARM64 (Apple Silicon) | ✅ Supported — binary: `nexaraild-darwin-arm64` |
| Linux | AMD64 (x86_64) | ✅ Supported — binary: `nexaraild-linux-amd64` |

Other platforms are not tested. The devnet is designed to run on a single machine — no multi-machine distribution is required.

---

## 2. Prerequisites

### Option A: Use the Pre-Built RC1 Binary (Recommended)

Download the correct binary for your platform from the release artifacts:

| Platform | Binary Name | SHA-256 |
|---|---|---|
| macOS ARM64 | `nexaraild-darwin-arm64` | `56f83f3068bb3d9cfe6854656e1f6b819c35cc138b96a5ebe757769a466bdc6a` |
| Linux AMD64 | `nexaraild-linux-amd64` | `25efa8d47f9d141669f4fcc5a6026ec12102f61ee026a3a52b3c0a44984b8c6f` |

**Verify checksum (macOS):**

```bash
shasum -a 256 nexaraild-darwin-arm64
# Expected: 56f83f3068bb3d9cfe6854656e1f6b819c35cc138b96a5ebe757769a466bdc6a
```

**Verify checksum (Linux):**

```bash
sha256sum nexaraild-linux-amd64
# Expected: 25efa8d47f9d141669f4fcc5a6026ec12102f61ee026a3a52b3c0a44984b8c6f
```

**Make executable:**

```bash
chmod +x nexaraild-*
```

**Optional: symlink to `nexaraild` for convenience:**

```bash
ln -sf nexaraild-darwin-arm64 nexaraild   # macOS
ln -sf nexaraild-linux-amd64  nexaraild   # Linux
```

### Option B: Build from Source

Requires [Go 1.26+](https://go.dev/dl/).

```bash
cd /path/to/nexarail
make build
# Binary is produced at: ./build/nexaraild
```

Additional CLI dependencies used in this guide:
- `curl` — for HTTP/rpc queries
- `jq` — for JSON parsing and pretty-printing

---

## 3. Mode Overview

The devnet supports two launch modes, each serving a different purpose.

| Feature | Single-Node | Five-Agent |
|---|---|---|
| **Validators** | 1 | 5 |
| **Consensus** | None (no peers needed) | Yes (5 validators, full PBFT) |
| **Tx-Processing** | ✅ Full | ✅ Full |
| **Product-Flow Testing** | ✅ Quick smoke-test | ✅ Full rehearsal (487/487 pass) |
| **Governance Testing** | ❌ (no quorum) | ✅ (voting/quorum possible) |
| **Use Case** | Code eval, quick dev iteration | Topology rehearsal, agent testing |

**Reference:** Five-agent product-flow evidence: 487/487 tests pass. See `TESTNET_RC1_EVIDENCE_MANIFEST.md` item 5.

---

## 4. Single-Node Mode (Quick Dev/Eval)

### 4.1 Ports Used

| Service | Port |
|---|---|
| RPC | 26657 |
| REST/API | 1317 |
| gRPC | 9090 |
| P2P | 26656 |

### 4.2 Initialize

```bash
# Set binary convenience variable
export NEXARAILD=./nexaraild   # or ./build/nexaraild

# Create home directory
$NEXARAILD init devnet-single \
  --chain-id nexarail-devnet-1 \
  --home ~/.nexarail-devnet-single

# Add a test key
echo "y" | $NEXARAILD keys add devnet-key \
  --keyring-backend test \
  --home ~/.nexarail-devnet-single \
  --output json > ~/.nexarail-devnet-single/key.json

# Fund the key
$NEXARAILD add-genesis-account \
  $(jq -r '.address' ~/.nexarail-devnet-single/key.json) \
  1000000000000unxrl \
  --keyring-backend test \
  --home ~/.nexarail-devnet-single

# Create gentx
$NEXARAILD gentx devnet-key 500000000000unxrl \
  --keyring-backend test \
  --chain-id nexarail-devnet-1 \
  --home ~/.nexarail-devnet-single \
  --commission-rate 0.05 \
  --commission-max-rate 0.20 \
  --commission-max-change-rate 0.01 \
  --min-self-delegation 1

# Collect gentxs and finalize genesis
$NEXARAILD collect-gentxs --home ~/.nexarail-devnet-single
$NEXARAILD validate-genesis --home ~/.nexarail-devnet-single
```

### 4.3 Fix Genesis Parameters

```bash
# Set bond denom, voting period, etc. for devnet
cd ~/.nexarail-devnet-single
jq --arg denom "unxrl" '
  .app_state.staking.params.bond_denom = $denom |
  .app_state.gov.params.voting_period = "30s" |
  .app_state.gov.params.min_deposit[0].denom = "unxrl" |
  .app_state.gov.params.min_deposit[0].amount = "1000000" |
  .app_state.crisis.constant_fee.denom = $denom
' config/genesis.json > config/genesis_fixed.json && \
mv config/genesis_fixed.json config/genesis.json
```

### 4.4 Launch

```bash
$NEXARAILD start \
  --home ~/.nexarail-devnet-single \
  --rpc.laddr tcp://127.0.0.1:26657 \
  --api.address tcp://127.0.0.1:1317 \
  --grpc.address 127.0.0.1:9090 \
  --minimum-gas-prices 0.025unxrl \
  --log_format json
```

### 4.5 Wait for Blocks

In a second terminal (or after backgrounding with `&` / `nohup`), wait until height > 10:

```bash
# Wait loop — runs until height >= 10
for i in $(seq 1 30); do
  H=$(curl -s http://127.0.0.1:26657/status | jq -r '.result.sync_info.latest_block_height // "0"')
  echo "[${i}s] Height=$H"
  [ "${H:-0}" -ge 10 ] 2>/dev/null && echo "✅ Height >= 10 reached" && break
  sleep 2
done
```

### 4.6 Query Status

```bash
# Node info
curl -s http://127.0.0.1:26657/status | jq '.result.node_info'
```

**Expected output (abbreviated):**

```json
{
  "protocol_version": {
    "p2p": "8",
    "block": "11",
    "app": "0"
  },
  "network": "nexarail-devnet-1",
  "version": "...",
  "moniker": "devnet-single"
}
```

```bash
# Block height
curl -s http://127.0.0.1:26657/status | jq '.result.sync_info.latest_block_height'
```

**Expected:** An integer >= 10, incrementing.

```bash
# Validator set
curl -s http://127.0.0.1:26657/validators | jq '.result.total'
```

**Expected:** `1` (single validator).

### 4.7 Query Params

```bash
$NEXARAILD query staking params \
  --node tcp://localhost:26657 \
  --chain-id nexarail-devnet-1 \
  --output json | jq '.bond_denom'
```

**Expected:** `"unxrl"`

```bash
$NEXARAILD query slashing params \
  --node tcp://localhost:26657 \
  --chain-id nexarail-devnet-1 \
  --output json | jq '.signed_blocks_window'
```

**Expected:** `"100"` (default Cosmos value).

```bash
$NEXARAILD query distribution params \
  --node tcp://localhost:26657 \
  --chain-id nexarail-devnet-1 \
  --output json
```

**Expected:** A JSON object with distribution parameters, `community_tax` = `"0.020000000000000000"`.

### 4.8 Check Live Flags (All Must Be `false`)

```bash
# Settlement module
$NEXARAILD query settlement params \
  --node tcp://localhost:26657 \
  --chain-id nexarail-devnet-1 \
  --output json | jq '.params'

# Escrow module
$NEXARAILD query escrow params \
  --node tcp://localhost:26657 \
  --chain-id nexarail-devnet-1 \
  --output json | jq '.params'

# Treasury module
$NEXARAILD query treasury params \
  --node tcp://localhost:26657 \
  --chain-id nexarail-devnet-1 \
  --output json | jq '.params'

# Payout module
$NEXARAILD query payout params \
  --node tcp://localhost:26657 \
  --chain-id nexarail-devnet-1 \
  --output json | jq '.params'
```

**Expected for all modules:** `"live_enabled": false`. For `settlement` specifically: `"treasury_routing_enabled": false`, `"burn_routing_enabled": false`.

### 4.9 Stop

```bash
# If running in foreground: Ctrl+C
# If backgrounded:
pkill -f "nexaraild.*devnet-single" || true
```

### 4.10 Clean Up

```bash
rm -rf ~/.nexarail-devnet-single
```

---

## 5. Five-Agent Mode (Multi-Validator)

This mode creates 5 validator agents (`alpha`, `bravo`, `charlie`, `delta`, `echo`) with full peer-to-peer consensus, suitable for topology rehearsals and product-flow validation.

### 5.1 Ports Used

| Agent | RPC | P2P | REST/API | gRPC |
|---|---|---|---|---|
| **alpha** | 27657 | 27656 | 1417 | 9190 |
| **bravo** | 27667 | 27666 | 1418 | 9191 |
| **charlie** | 27677 | 27676 | 1419 | 9192 |
| **delta** | 27687 | 27686 | 1420 | 9193 |
| **echo** | 27697 | 27696 | 1421 | 9194 |

### 5.2 Prerequisites

In addition to the binary (see [Section 2](#2-prerequisites)), ensure:

```bash
# Check tmux (recommended for multi-agent management)
command -v tmux && echo "tmux available"

# Check nc (for gRPC socket checks)
command -v nc && echo "nc available"
```

If `tmux` is unavailable, the spawn script falls back to `nohup`.

### 5.3 Launch Using Spawn Script

From the NexaRail repository root, run the spawn-validator-agents script:

```bash
cd /path/to/nexarail

# Ensure binary is built or symlinked to ./build/nexaraild
# (the script expects the binary at ./build/nexaraild)
cp /path/to/nexaraild-darwin-arm64 ./build/nexaraild   # or make build

# Spawn 5 agents with clean genesis
bash scripts/testnet/spawn-validator-agents.sh \
  --clean \
  --agent-count 5
```

**What happens:**
1. Stops any existing validator-agent processes (errors if stale without `--force-clean`)
2. Wipes agent home directories
3. Creates 5 agent homes with unique keys, gentxs, and peer configurations
4. Fixes genesis parameters (voting period 30s, bond denom `unxrl`, etc.)
5. Distributes genesis to all agents
6. Starts each agent in its own `tmux` session (or `nohup` if tmux unavailable)
7. Waits for all RPC endpoints to become ready
8. Waits for block height >= 10 and all 5 peers connected
9. Confirms validator set count = 5

### 5.4 Manual Five-Agent Launch (Alternative)

If you prefer to manage agents manually without the spawn script:

**Step 1 — Define agent configurations:**

```bash
export NEXARAILD=./build/nexaraild
export AGENT_DIR=~/.nexarail-agents
export CHAIN_ID=nexarail-devnet-1

# Initialize 5 agents
for i in 0 1 2 3 4; do
  AGENT_HOME="$AGENT_DIR/agent$i"
  $NEXARAILD init "agent-$i" --chain-id "$CHAIN_ID" --home "$AGENT_HOME" --overwrite
done
```

**Step 2 — Create keys and fund accounts:**

```bash
for i in 0 1 2 3 4; do
  AGENT_HOME="$AGENT_DIR/agent$i"
  echo "y" | $NEXARAILD keys add "agent${i}-key" \
    --keyring-backend test --home "$AGENT_HOME" > "$AGENT_HOME/key.json" 2>/dev/null
done

# Use agent0 as genesis template
for i in 0 1 2 3 4; do
  ADDR=$(jq -r '.address' "$AGENT_DIR/agent$i/key.json")
  $NEXARAILD add-genesis-account "$ADDR" 1000000000000unxrl \
    --home "$AGENT_DIR/agent0"
done
```

**Step 3 — Fix genesis (see [Section 4.3](#43-fix-genesis-parameters) for commands).**

**Step 4 — Create gentxs:**

```bash
for i in 0 1 2 3 4; do
  AGENT_HOME="$AGENT_DIR/agent$i"
  cp "$AGENT_DIR/agent0/config/genesis.json" "$AGENT_HOME/config/genesis.json"
  $NEXARAILD gentx "agent${i}-key" 500000000000unxrl \
    --keyring-backend test --chain-id "$CHAIN_ID" \
    --home "$AGENT_HOME" --moniker "agent-$i" \
    --commission-rate 0.05 --commission-max-rate 0.20 \
    --commission-max-change-rate 0.01 --min-self-delegation 1
done

# Collect gentxs into agent0
mkdir -p "$AGENT_DIR/agent0/config/gentx"
for i in 0 1 2 3 4; do
  cp "$AGENT_DIR/agent$i/config/gentx/"*.json "$AGENT_DIR/agent0/config/gentx/"
done
$NEXARAILD collect-gentxs --home "$AGENT_DIR/agent0" --gentx-dir "$AGENT_DIR/agent0/config/gentx"

# Distribute genesis
for i in 1 2 3 4; do
  mkdir -p "$AGENT_DIR/agent$i/config"
  cp "$AGENT_DIR/agent0/config/genesis.json" "$AGENT_DIR/agent$i/config/genesis.json"
done
```

**Step 5 — Start agents on designated ports:**

```bash
# Start agent0 (alpha) — full endpoints
$NEXARAILD start \
  --home "$AGENT_DIR/agent0" \
  --rpc.laddr tcp://127.0.0.1:27657 \
  --p2p.laddr tcp://127.0.0.1:27656 \
  --api.address tcp://127.0.0.1:1417 \
  --grpc.address 127.0.0.1:9190 \
  --minimum-gas-prices 0.025unxrl &
sleep 2

# Get agent0 node ID for peer configuration
AGENT0_NODE_ID=$($NEXARAILD tendermint show-node-id --home "$AGENT_DIR/agent0")

# Start remaining agents as peers of agent0
for i in 1 2 3 4; do
  RPC_PORT=$((27657 + i * 10))
  P2P_PORT=$((27656 + i * 10))
  API_PORT=$((1417 + i))
  GRPC_PORT=$((9190 + i))
  
  $NEXARAILD start \
    --home "$AGENT_DIR/agent$i" \
    --rpc.laddr tcp://127.0.0.1:$RPC_PORT \
    --p2p.laddr tcp://127.0.0.1:$P2P_PORT \
    --p2p.persistent_peers "tcp://${AGENT0_NODE_ID}@127.0.0.1:27656" \
    --minimum-gas-prices 0.025unxrl &
  sleep 2
done
```

### 5.5 Wait for Blocks

```bash
# Use alpha's RPC port (27657)
for i in $(seq 1 60); do
  STATUS=$(curl -s --max-time 3 http://127.0.0.1:27657/status 2>/dev/null)
  H=$(echo "$STATUS" | jq -r '.result.sync_info.latest_block_height // "0"')
  P=$(curl -s --max-time 3 http://127.0.0.1:27657/net_info | jq -r '.result.n_peers // "0"')
  echo "[${i}s] Height=$H Peers=$P"
  if [ "${H:-0}" -ge 10 ] 2>/dev/null && [ "${P:-0}" -ge 4 ] 2>/dev/null; then
    echo "✅ Height >= 10 and 4+ peers connected"
    break
  fi
  sleep 2
done
```

**Expected:** Height increases to >= 10, and peer count reaches 4 (all 5 validators connected to each other).

### 5.6 Query Status (via Alpha Agent)

```bash
# Network info
curl -s http://127.0.0.1:27657/status | jq '.result.node_info.network'
```

**Expected:** `"nexarail-devnet-1"` (or `"nexarail-agent-testnet-1"` if using spawn-validator-agents.sh).

```bash
# Block height
curl -s http://127.0.0.1:27657/status | jq '.result.sync_info.latest_block_height'
```

**Expected:** Integer >= 10.

```bash
# Validator set
curl -s http://127.0.0.1:27657/validators | jq '.result.total'
```

**Expected:** `5` (all five agents are bonded validators).

```bash
# Net info — connected peers
curl -s http://127.0.0.1:27657/net_info | jq '.result.n_peers'
```

**Expected:** `4` (each validator connected to the other 4).

### 5.7 Query Params (via Alpha Agent)

```bash
# Staking params
$NEXARAILD query staking params \
  --node tcp://localhost:27657 \
  --chain-id "$CHAIN_ID" \
  --output json | jq '.bond_denom'
```

**Expected:** `"unxrl"`

```bash
# Governance params
$NEXARAILD query gov params \
  --node tcp://localhost:27657 \
  --chain-id "$CHAIN_ID" \
  --output json | jq '.voting_params.voting_period'
```

**Expected:** `"30s"` (devnet-configured).

### 5.8 Check Live Flags (All Must Be `false`)

```bash
for mod in settlement escrow treasury payout; do
  echo "=== $mod ==="
  $NEXARAILD query "$mod" params \
    --node tcp://localhost:27657 \
    --chain-id "$CHAIN_ID" \
    --output json | jq '.params' 2>/dev/null || echo "❌ query failed for $mod"
done
```

**Expected for all modules:** `"live_enabled": false`. For `settlement` additionally: `"treasury_routing_enabled": false`, `"burn_routing_enabled": false`.

### 5.9 Stop Agents

```bash
# Using the stop script:
bash scripts/testnet/stop-validator-agents.sh --force

# Or manually:
for pid in $(pgrep -f "nexaraild.*agent"); do
  kill "$pid" 2>/dev/null && echo "Killed PID $pid"
done
```

### 5.10 Clean Up

```bash
# Using the spawn script's --clean mode re-runs cleanup
# Or manually:
rm -rf ~/.nexarail-agents

# If using the spawn script's default home:
rm -rf rehearsals/validator-agents
```

---

## 6. Common Commands

### Verify Binary Version

```bash
./nexaraild version
```

**Expected:** A version string (e.g., containing commit hash `01f5f2a`).

### Query Bank Balance

```bash
$NEXARAILD query bank balances \
  $(jq -r '.address' ~/.nexarail-devnet-single/key.json) \
  --node tcp://localhost:26657 \
  --chain-id nexarail-devnet-1 \
  --output json
```

### Send a Test Transaction

```bash
# Single-node mode
$NEXARAILD tx bank send devnet-key \
  <recipient-address> \
  1000unxrl \
  --keyring-backend test \
  --chain-id nexarail-devnet-1 \
  --node tcp://localhost:26657 \
  --fees 500unxrl \
  --gas auto \
  --gas-adjustment 1.5 \
  --output json
```

### Query Transaction

```bash
$NEXARAILD query tx <tx-hash> \
  --node tcp://localhost:26657 \
  --chain-id nexarail-devnet-1 \
  --output json
```

---

## 7. Limitations

| Limitation | Detail |
|---|---|
| **Devnet only** | This is a self-contained local devnet for review and internal development. No external validators can join. |
| **Not a public testnet** | No faucet, no public seed nodes, no validator onboarding. |
| **Not mainnet** | No mainnet infrastructure, incentives, or guarantees are implied. |
| **No token value** | All `unxrl` tokens minted in this devnet carry zero economic value. No token sale has occurred. |
| **Unsafe for consensus testing** | Single-node mode has no peers. Five-agent mode runs on a single machine with loopback networking. Consensus edge cases (partitions, byzantine behaviour) are not testable in this configuration. |
| **No genesis finality** | Genesis can be regenerated at any time. There is no commitment to a canonical genesis. |
| **Live flags disabled** | All `live_enabled`, `treasury_routing_enabled`, and `burn_routing_enabled` parameters default to `false`. No real fund movement is possible. |
| **REST readback only** | REST endpoints are query-only (36/36 readback endpoints operational). Transaction broadcast uses the generic Cosmos `/cosmos/tx/v1beta1/txs` endpoint. |
| **No external security audit** | The codebase has undergone internal review and automated testing only. |

See `TESTNET_RC1_KNOWN_LIMITATIONS.md` for the complete list.

---

## 8. Evidence Reference

| Evidence Item | Path | Status |
|---|---|---|
| Five-agent product-flow validation (487/487 pass) | `rehearsals/validator-agents/product-flows/evidence/` | ✅ Verified |
| Clean-spawn governance | `rehearsals/validator-agents/clean-spawn-governance/` | ✅ Verified |
| Long soak (>24h) | `rehearsals/validator-agents/long-soak/` | ✅ Verified |
| Agent restart safety | `rehearsals/validator-agents/restart-investigation/` | ✅ Verified |
| REST readback parity | `docs/api/REST_READBACK_ROUTES.md` | ✅ 36/36 operational |
| Live flags (all false) | Documented in all Phase 10B reports | ✅ Confirmed |

---

*End of devnet launch guide.*
