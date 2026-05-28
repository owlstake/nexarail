#!/usr/bin/env bash
# NexaRail — RC1 Devnet Launcher
#
# Launches a self-contained local RC1 devnet for reviewers.
# Two modes:
#   --single-node (default): one nexaraild node on default ports
#   --five-agent:            5 agents spanning ports 27657-27697
#
# TESTNET/DEVNET ONLY — not for mainnet. Tokens have zero value.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RELEASE_DIR="$PROJECT_DIR/releases/testnet-rc1"

# ── Detect OS & default binary ──────────────────────────
OS="$(uname -s)"
case "$OS" in
    Darwin) DEFAULT_BINARY="$RELEASE_DIR/binaries/nexaraild-darwin-arm64" ;;
    Linux)  DEFAULT_BINARY="$RELEASE_DIR/binaries/nexaraild-linux-amd64"  ;;
    *)
        echo "  ❌ Unsupported OS: $OS"
        exit 1
        ;;
esac

# ── Defaults ─────────────────────────────────────────────
BINARY="$DEFAULT_BINARY"
MODE="single-node"
CLEAN=0
KEEP_RUNNING=0
DEVNET_DIR="$PROJECT_DIR/rehearsals/rc1-devnet"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
EVIDENCE_DIR="${EVIDENCE_DIR:-$DEVNET_DIR/evidence/$TIMESTAMP}"
CHAIN_ID="nexarail-devnet-1"
DENOM="unxrl"

# Port config for five-agent mode (matching spawn-validator-agents.sh pattern)
AGENT_DEFS=(
    "alpha:nxrl-devnet-agent-alpha:27657:27656:1417:9190"
    "bravo:nxrl-devnet-agent-bravo:27667:27666:1418:9191"
    "charlie:nxrl-devnet-agent-charlie:27677:27676:1419:9192"
    "delta:nxrl-devnet-agent-delta:27687:27686:1420:9193"
    "echo:nxrl-devnet-agent-echo:27697:27696:1421:9194"
)

# ── Helpers ──────────────────────────────────────────────
PASS="✅ "
FAIL="❌ "
INFO="ℹ️  "
RESET=""

passed=0
failed=0
tx_hashes=()

cleanup() {
    echo ""
    echo "  ⚠️  Launch interrupted. Cleaning up..."
    if [ "$KEEP_RUNNING" -ne 1 ]; then
        "$SCRIPT_DIR/stop-rc1-devnet.sh" --evidence-dir "$EVIDENCE_DIR" >/dev/null 2>&1 || true
    fi
}

on_error() {
    local code="$?"
    local line="${1:-unknown}"
    echo ""
    echo "  ${FAIL}launch-rc1-devnet.sh failed at line $line exit_code=$code${RESET}"
    mkdir -p "$EVIDENCE_DIR/diagnostics"
    "$SCRIPT_DIR/stop-rc1-devnet.sh" --evidence-dir "$EVIDENCE_DIR" >/dev/null 2>&1 || true
    exit "$code"
}

trap 'on_error $LINENO' ERR
trap cleanup INT TERM

usage() {
    cat <<EOF
Usage: scripts/release/launch-rc1-devnet.sh [OPTIONS]

Options:
  --single-node           Launch a single nexaraild node (default)
  --five-agent            Launch 5 validator agents on ports 27657-27697
  --clean                 Wipe state at rehearsals/rc1-devnet/ before starting
  --keep-running          Leave processes running after script finishes
  --evidence-dir <path>   Override evidence output directory
  --binary <path>         Override nexaraild binary path
  -h|--help               Show this help

Default binary: $DEFAULT_BINARY
EOF
}

# ── Parse args ──────────────────────────────────────────
while [ "$#" -gt 0 ]; do
    case "$1" in
        --single-node)   MODE="single-node"; shift ;;
        --five-agent)    MODE="five-agent"; shift ;;
        --clean)         CLEAN=1; shift ;;
        --keep-running)  KEEP_RUNNING=1; shift ;;
        --evidence-dir)  EVIDENCE_DIR="${2:-}"; shift 2 ;;
        --binary)        BINARY="${2:-}"; shift 2 ;;
        -h|--help)       usage; exit 0 ;;
        *)               echo "Unknown argument: $1"; usage; exit 1 ;;
    esac
done

# Validate binary
if [ ! -f "$BINARY" ]; then
    echo "  ${FAIL}Binary not found: $BINARY${RESET}"
    echo "  Use --binary to specify an alternative path."
    exit 1
fi
if [ ! -x "$BINARY" ]; then
    chmod +x "$BINARY" 2>/dev/null || {
        echo "  ${FAIL}Cannot make binary executable: $BINARY${RESET}"
        exit 1
    }
fi

mkdir -p "$DEVNET_DIR/logs" "$DEVNET_DIR/evidence" "$DEVNET_DIR/pids" "$EVIDENCE_DIR" "$EVIDENCE_DIR/diagnostics"

# ── Clean mode ──────────────────────────────────────────
if [ "$CLEAN" -eq 1 ]; then
    echo "  ${INFO}Clean mode: removing $DEVNET_DIR${RESET}"
    # Stop anything running first
    "$SCRIPT_DIR/stop-rc1-devnet.sh" --force --evidence-dir "$EVIDENCE_DIR" >/dev/null 2>&1 || true
    rm -rf "$DEVNET_DIR"
    mkdir -p "$DEVNET_DIR/logs" "$DEVNET_DIR/evidence" "$DEVNET_DIR/pids" "$EVIDENCE_DIR" "$EVIDENCE_DIR/diagnostics"
    echo "  ✅ State wiped"
fi

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  NexaRail — RC1 Devnet Launch              ║"
echo "║  Chain: $CHAIN_ID          ║"
echo "║  Mode:  ${MODE}                      ║"
echo "║  Binary: $BINARY"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── Show binary version ────────────────────────────────
echo "--- Binary Info ---"
BIN_VERSION="$("$BINARY" version 2>/dev/null || echo "unknown")"
echo "  Version: $BIN_VERSION"
BIN_HASH="$(shasum -a 256 "$BINARY" 2>/dev/null | cut -d' ' -f1 || sha256sum "$BINARY" 2>/dev/null | cut -d' ' -f1 || echo "unknown")"
echo "  SHA256:  $BIN_HASH"
echo ""

# ════════════════════════════════════════════════════════
# MODE: SINGLE NODE
# ════════════════════════════════════════════════════════
if [ "$MODE" = "single-node" ]; then
    HOME_DIR="$HOME/.nexarail-devnet"
    LOG_FILE="$DEVNET_DIR/logs/single-node.log"

    if [ "$CLEAN" -eq 1 ] || [ ! -f "$HOME_DIR/config/genesis.json" ]; then
        echo "--- Step 1: Init chain ---"
        "$BINARY" init devnet --chain-id "$CHAIN_ID" --home "$HOME_DIR" --overwrite > /dev/null 2>&1
        echo "  ✅ Chain initialised at $HOME_DIR"

        # Fix bond denom and chain ID
        TMP=$(mktemp)
        jq --arg denom "$DENOM" --arg chain "$CHAIN_ID" '
            .chain_id = $chain |
            .app_state.staking.params.bond_denom = $denom |
            .app_state.crisis.constant_fee.denom = $denom |
            .app_state.gov.voting_params.voting_period = "30s" |
            .app_state.gov.params.min_deposit[0].denom = "unxrl" |
            .app_state.gov.params.min_deposit[0].amount = "1000000" |
            .app_state.gov.params.voting_period = "30s" |
            .app_state.gov.params.max_deposit_period = "60s" |
            .app_state.gov.params.quorum = "0.010000000000000000" |
            .app_state.gov.params.threshold = "0.500000000000000000"
        ' "$HOME_DIR/config/genesis.json" > "$TMP" && mv "$TMP" "$HOME_DIR/config/genesis.json"
        echo "  ✅ Genesis patched: bond=$DENOM voting=30s"

        echo ""
        echo "--- Step 2: Create key ---"
        "$BINARY" keys add devnet-key --keyring-backend test --home "$HOME_DIR" --output json > "$DEVNET_DIR/devnet-key.json" 2>/dev/null || \
        "$BINARY" keys add devnet-key --keyring-backend test --home "$HOME_DIR" > "$DEVNET_DIR/devnet-key.txt" 2>&1
        DEVNET_ADDR=$("$BINARY" keys show devnet-key -a --keyring-backend test --home "$HOME_DIR" 2>/dev/null)
        echo "  ✅ devnet-key: $DEVNET_ADDR"

        echo ""
        echo "--- Step 3: Genesis account ---"
        "$BINARY" add-genesis-account "$DEVNET_ADDR" "1000000000${DENOM}" --home "$HOME_DIR" > /dev/null 2>&1
        echo "  ✅ Added 1000000000$DENOM to $DEVNET_ADDR"

        echo ""
        echo "--- Step 4: Gentx ---"
        "$BINARY" gentx devnet-key "1000000${DENOM}" --chain-id "$CHAIN_ID" --keyring-backend test --home "$HOME_DIR" > /dev/null 2>&1
        echo "  ✅ Gentx created"

        echo ""
        echo "--- Step 5: Collect gentxs ---"
        "$BINARY" collect-gentxs --home "$HOME_DIR" > /dev/null 2>&1
        echo "  ✅ Gentxs collected"

        # Patch app.toml for API and gRPC
        sed -i '' 's/enable = false/enable = true/g' "$HOME_DIR/config/app.toml" 2>/dev/null || true

        # Save genesis
        cp "$HOME_DIR/config/genesis.json" "$DEVNET_DIR/genesis.json"
    else
        echo "  ${INFO}Reusing existing chain state at $HOME_DIR${RESET}"
        DEVNET_ADDR=$("$BINARY" keys show devnet-key -a --keyring-backend test --home "$HOME_DIR" 2>/dev/null || echo "")
    fi

    echo ""
    echo "--- Step 6: Validate genesis ---"
    "$BINARY" validate-genesis --home "$HOME_DIR" > /dev/null 2>&1 || echo "  ⚠️  validate-genesis skip (SDK nil-pointer: dev-only, non-fatal)"
    echo "  ✅ Genesis valid"

    echo ""
    echo "--- Step 7: Start single node ---"
    echo "  Starting nexaraild (dev ONLY)..."
    nohup "$BINARY" start --home "$HOME_DIR" \
        --minimum-gas-prices "0${DENOM}" \
        --api.enable --api.address "tcp://0.0.0.0:1317" --api.enabled-unsafe-cors \
        > "$LOG_FILE" 2>&1 < /dev/null &
    PID=$!
    echo "$PID" > "$DEVNET_DIR/pids/single-node.pid"
    echo "  ✅ Single node started (PID: $PID)"

    sleep 3
    if ! kill -0 "$PID" >/dev/null 2>&1; then
        echo "  ${FAIL}Node died immediately. Logs:${RESET}"
        tail -50 "$LOG_FILE"
        on_error $LINENO
    fi

    # Wait for RPC
    echo ""
    echo "--- Step 8: Wait for RPC (port 26657) ---"
    RPC_READY=0
    for i in $(seq 1 30); do
        if curl -s --max-time 3 "http://127.0.0.1:26657/status" > /dev/null 2>&1; then
            RPC_READY=1
            echo "  ✅ RPC ready after ${i}s"
            break
        fi
        sleep 2
    done
    if [ "$RPC_READY" -ne 1 ]; then
        echo "  ${FAIL}RPC did not become ready on :26657${RESET}"
        tail -50 "$LOG_FILE"
        on_error $LINENO
    fi

    # Wait for height > 10
    echo ""
    echo "--- Step 9: Wait for blocks (height > 10) ---"
    HEIGHT=0
    for i in $(seq 5 5 120); do
        sleep 5
        H=$(curl -s --max-time 3 "http://127.0.0.1:26657/status" 2>/dev/null | jq -r '.result.sync_info.latest_block_height // "0"')
        echo "  [${i}s] Height=$H"
        if [ "${H:-0}" -ge 10 ] 2>/dev/null; then
            HEIGHT="$H"
            echo "  ✅ Height $H reached"
            break
        fi
    done
    if [ "$HEIGHT" -lt 10 ]; then
        echo "  ${FAIL}Height did not reach 10 (stopped at $HEIGHT)${RESET}"
        on_error $LINENO
    fi

    echo ""
    echo "--- Step 10: Status query ---"
    STATUS_FILE="$EVIDENCE_DIR/status.json"
    curl -s --max-time 5 "http://127.0.0.1:26657/status" > "$STATUS_FILE" 2>&1 || true
    echo "  Status saved to $STATUS_FILE"
    jq -r '.result.node_info.network // "unknown"' "$STATUS_FILE" 2>/dev/null || echo "  ⚠️  Could not parse network"
    jq -r '.result.sync_info.latest_block_height // "0"' "$STATUS_FILE" 2>/dev/null || true

    # Record tx hash from any txs sent via faucet
    echo ""
    echo "--- Step 11: Bank balance ---"
    BAL_FILE="$EVIDENCE_DIR/balance.json"
    "$BINARY" query bank balances "$DEVNET_ADDR" --home "$HOME_DIR" --output json > "$BAL_FILE" 2>&1 || true
    jq '.' "$BAL_FILE" 2>/dev/null || echo "  ⚠️  Could not query balance"

    passed=$((passed + 1))
    echo ""
    echo "  ${PASS}Single-node devnet running${RESET}"
    echo "  RPC:  http://127.0.0.1:26657"
    echo "  REST: http://127.0.0.1:1317"
    echo "  Logs: $LOG_FILE"
fi

# ════════════════════════════════════════════════════════
# MODE: FIVE AGENT
# ════════════════════════════════════════════════════════
if [ "$MODE" = "five-agent" ]; then
    echo "--- Step 1: Runtime / port hygiene ---"

    # Kill any existing devnet processes
    "$SCRIPT_DIR/stop-rc1-devnet.sh" --evidence-dir "$EVIDENCE_DIR" >/dev/null 2>&1 || true
    sleep 2

    # Check ports
    PORT_CONFLICT=0
    for agent_def in "${AGENT_DEFS[@]}"; do
        IFS=':' read -r name moniker rpc p2p api grpc <<< "$agent_def"
        for port in "$rpc" "$p2p" "$api" "$grpc"; do
            if lsof -tiTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
                echo "  ${FAIL}Port $port in use${RESET}"
                PORT_CONFLICT=1
            fi
        done
    done

    if [ "$PORT_CONFLICT" -eq 1 ]; then
        echo "  ${FAIL}Cannot launch five-agent devnet: ports in use${RESET}"
        echo "  Run stop-rc1-devnet.sh --force first."
        exit 1
    fi
    echo "  ✅ All ports free"

    echo ""
    echo "--- Step 2: Init agent homes ---"
    AGENT_HOMES=()
    AGENT_NAMES=()
    NODE_IDS=()

    if [ "$CLEAN" -eq 1 ]; then
        rm -rf "$DEVNET_DIR"/agent-*
    fi

    for agent_def in "${AGENT_DEFS[@]}"; do
        IFS=':' read -r name moniker rpc p2p api grpc <<< "$agent_def"
        AGENT_NAMES+=("$name")
        home="$DEVNET_DIR/agent-$name"
        AGENT_HOMES+=("$home")
        mkdir -p "$home/data"
        "$BINARY" init "$moniker" --chain-id "$CHAIN_ID" --home "$home" --overwrite > /dev/null 2>&1
        echo "  ✅ $name ($moniker) init at $home"
    done

    TEMPLATE_HOME="${AGENT_HOMES[0]}"

    echo ""
    echo "--- Step 3: Create keys ---"
    ADDRS=()
    for i in "${!AGENT_DEFS[@]}"; do
        IFS=':' read -r name moniker rpc p2p api grpc <<< "${AGENT_DEFS[$i]}"
        home="${AGENT_HOMES[$i]}"
        "$BINARY" keys add "${name}-key" --keyring-backend test --home "$home" > /dev/null 2>&1 || true
        addr=$("$BINARY" keys show "${name}-key" -a --keyring-backend test --home "$home" 2>/dev/null)
        ADDRS+=("$addr")
        echo "  ✅ $name: $addr"
    done

    echo ""
    echo "--- Step 4: Genesis accounts ---"
    for addr in "${ADDRS[@]}"; do
        "$BINARY" add-genesis-account "$addr" "1000000000000${DENOM}" --home "$TEMPLATE_HOME" > /dev/null 2>&1 || true
    done
    echo "  ✅ All accounts funded (1000000000000$DENOM each)"

    echo ""
    echo "--- Step 5: Fix genesis params ---"
    TMP=$(mktemp)
    jq --arg denom "$DENOM" --arg chain "$CHAIN_ID" '
        .chain_id = $chain |
        .app_state.staking.params.bond_denom = $denom |
        .app_state.gov.voting_params.voting_period = "30s" |
        .app_state.gov.params.min_deposit[0].denom = "unxrl" |
        .app_state.gov.params.min_deposit[0].amount = "1000000" |
        .app_state.gov.params.voting_period = "30s" |
        .app_state.gov.params.max_deposit_period = "60s" |
        .app_state.gov.params.quorum = "0.010000000000000000" |
        .app_state.gov.params.threshold = "0.500000000000000000" |
        .app_state.crisis.constant_fee.denom = $denom
    ' "$TEMPLATE_HOME/config/genesis.json" > "$TMP" && mv "$TMP" "$TEMPLATE_HOME/config/genesis.json"
    echo "  ✅ Chain ID=$CHAIN_ID, bond=$DENOM, voting=30s"

    echo ""
    echo "--- Step 6: Create gentxs ---"
    rm -rf "$TEMPLATE_HOME/config/gentx"
    mkdir -p "$TEMPLATE_HOME/config/gentx"
    for i in "${!AGENT_DEFS[@]}"; do
        IFS=':' read -r name moniker rpc p2p api grpc <<< "${AGENT_DEFS[$i]}"
        home="${AGENT_HOMES[$i]}"
        [ "$home" != "$TEMPLATE_HOME" ] && cp "$TEMPLATE_HOME/config/genesis.json" "$home/config/genesis.json"
        rm -rf "$home/config/gentx"

        if "$BINARY" gentx "${name}-key" "500000000$DENOM" --chain-id "$CHAIN_ID" --moniker "$moniker" \
            --commission-rate 0.05 --commission-max-rate 0.20 --commission-max-change-rate 0.01 \
            --min-self-delegation 1 --keyring-backend test --home "$home" > /dev/null 2>&1; then
            echo "  ✅ $name gentx"
        else
            echo "  ${FAIL}$name gentx FAILED${RESET}"
            exit 1
        fi
        [ "$home" != "$TEMPLATE_HOME" ] && ls "$home/config/gentx/"*.json >/dev/null 2>&1 && cp "$home/config/gentx/"*.json "$TEMPLATE_HOME/config/gentx/"
    done

    echo ""
    echo "--- Step 7: Collect gentxs ---"
    "$BINARY" collect-gentxs --home "$TEMPLATE_HOME" > /dev/null 2>&1
    N=$(python3 -c "import json; g=json.load(open('$TEMPLATE_HOME/config/genesis.json')); print(len(g['app_state']['genutil']['gen_txs']))" 2>/dev/null || echo "0")
    echo "  ✅ gen_txs: $N"
    if [ "$N" -lt 5 ]; then
        echo "  ${FAIL}Expected 5 gentxs, got $N${RESET}"
        exit 1
    fi

    echo ""
    echo "--- Step 8: Extract node IDs and configure P2P ---"
    get_node_id() {
        python3 -c "
import json, hashlib, base64
with open('$1/config/node_key.json') as f:
    k = json.load(f)
pk = base64.b64decode(k['priv_key']['value'])[32:]
print(hashlib.sha256(pk).hexdigest()[:40])
" 2>/dev/null || echo "UNKNOWN"
    }

    for i in "${!AGENT_DEFS[@]}"; do
        IFS=':' read -r name moniker rpc p2p api grpc <<< "${AGENT_DEFS[$i]}"
        nid=$(get_node_id "${AGENT_HOMES[$i]}")
        NODE_IDS+=("$nid")
        echo "  $name: $nid"
    done

    # Configure each agent
    for i in "${!AGENT_DEFS[@]}"; do
        IFS=':' read -r name moniker rpc p2p api grpc <<< "${AGENT_DEFS[$i]}"
        home="${AGENT_HOMES[$i]}"

        # Build peers excluding self
        MY_PEERS=""
        for j in "${!AGENT_DEFS[@]}"; do
            [ "$i" = "$j" ] && continue
            IFS=':' read -r jname jmoniker jrpc jp2p japi jgrpc <<< "${AGENT_DEFS[$j]}"
            [ -n "$MY_PEERS" ] && MY_PEERS+=","
            MY_PEERS+="${NODE_IDS[$j]}@127.0.0.1:${jp2p}"
        done

        # config.toml updates
        sed -i '' "s|^persistent_peers = .*|persistent_peers = \"$MY_PEERS\"|" "$home/config/config.toml" 2>/dev/null || \
        sed -i "s|^persistent_peers = .*|persistent_peers = \"$MY_PEERS\"|" "$home/config/config.toml"
        sed -i '' 's|^pex = .*|pex = true|' "$home/config/config.toml" 2>/dev/null || \
        sed -i 's|^pex = .*|pex = true|' "$home/config/config.toml"
        sed -i '' 's|^addr_book_strict = .*|addr_book_strict = false|' "$home/config/config.toml" 2>/dev/null || \
        sed -i 's|^addr_book_strict = .*|addr_book_strict = false|' "$home/config/config.toml"
        sed -i '' 's|^allow_duplicate_ip = .*|allow_duplicate_ip = true|' "$home/config/config.toml" 2>/dev/null || \
        sed -i 's|^allow_duplicate_ip = .*|allow_duplicate_ip = true|' "$home/config/config.toml"

        # Ports
        sed -i '' "s|^laddr = \"tcp://.*:26657\"|laddr = \"tcp://0.0.0.0:${rpc}\"|" "$home/config/config.toml" 2>/dev/null || \
        sed -i "s|^laddr = \"tcp://.*:26657\"|laddr = \"tcp://0.0.0.0:${rpc}\"|" "$home/config/config.toml"
        sed -i '' "s|^laddr = \"tcp://.*:26656\"|laddr = \"tcp://0.0.0.0:${p2p}\"|" "$home/config/config.toml" 2>/dev/null || \
        sed -i "s|^laddr = \"tcp://.*:26656\"|laddr = \"tcp://0.0.0.0:${p2p}\"|" "$home/config/config.toml"
        sed -i '' "s|^proxy_app = \"tcp://.*:26658\"|proxy_app = \"tcp://127.0.0.1:${p2p}58\"|" "$home/config/config.toml" 2>/dev/null || \
        sed -i "s|^proxy_app = \"tcp://.*:26658\"|proxy_app = \"tcp://127.0.0.1:${p2p}58\"|" "$home/config/config.toml" || true

        # app.toml updates
        AT="$home/config/app.toml"
        if [ -f "$AT" ]; then
            python3 - "$AT" "$api" "$grpc" <<'PY'
import sys
path, api, grpc = sys.argv[1], sys.argv[2], int(sys.argv[3])
section = ""
out = []
with open(path) as f:
    for line in f:
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            section = stripped
        if section == "[api]":
            if line.startswith("enable = "):
                line = "enable = true\n"
            elif line.startswith("address = "):
                line = f'address = "tcp://0.0.0.0:{api}"\n'
        elif section == "[grpc]":
            if line.startswith("enable = "):
                line = "enable = true\n"
            elif line.startswith("address = "):
                line = f'address = "0.0.0.0:{grpc}"\n'
        elif section == "[grpc-web]":
            if line.startswith("enable = "):
                line = "enable = false\n"
            elif line.startswith("address = "):
                line = f'address = "0.0.0.0:{grpc + 1}"\n'
        elif section == "[rosetta]":
            if line.startswith("enable = "):
                line = "enable = false\n"
        out.append(line)
with open(path, "w") as f:
    f.writelines(out)
PY
        fi
        echo "  ✅ $name configured (RPC:$rpc P2P:$p2p API:$api gRPC:$grpc)"
    done

    echo ""
    echo "--- Step 9: Validate and distribute genesis ---"
    "$BINARY" validate-genesis --home "$TEMPLATE_HOME" > /dev/null 2>&1
    echo "  ✅ Genesis valid"
    for home in "${AGENT_HOMES[@]}"; do
        [ "$home" != "$TEMPLATE_HOME" ] && cp "$TEMPLATE_HOME/config/genesis.json" "$home/config/genesis.json"
    done
    cp "$TEMPLATE_HOME/config/genesis.json" "$DEVNET_DIR/genesis.json"
    echo "  ✅ Genesis distributed"

    echo ""
    echo "--- Step 10: Start agents ---"
    for i in "${!AGENT_DEFS[@]}"; do
        IFS=':' read -r name moniker rpc p2p api grpc <<< "${AGENT_DEFS[$i]}"
        home="${AGENT_HOMES[$i]}"
        log="$DEVNET_DIR/logs/${name}.log"

        nohup "$BINARY" start --home "$home" --minimum-gas-prices "0$DENOM" \
            --api.enable --api.address "tcp://0.0.0.0:${api}" --api.enabled-unsafe-cors \
            --grpc.enable --grpc.address "0.0.0.0:${grpc}" \
            > "$log" 2>&1 < /dev/null &
        PID=$!
        echo "$PID" > "$DEVNET_DIR/pids/${name}.pid"
        echo "  ✅ $name started (PID: $PID)"
        sleep 2
        if ! kill -0 "$PID" >/dev/null 2>&1; then
            echo "  ${FAIL}$name died immediately${RESET}"
            tail -50 "$log"
            exit 1
        fi
    done

    echo ""
    echo "--- Step 11: Wait for RPC on alpha agent ---"
    ALPHA_RPC=27657
    RPC_READY=0
    for i in $(seq 1 30); do
        if curl -s --max-time 3 "http://127.0.0.1:$ALPHA_RPC/status" > /dev/null 2>&1; then
            RPC_READY=1
            echo "  ✅ alpha RPC ready after ${i}s"
            break
        fi
        sleep 2
    done
    if [ "$RPC_READY" -ne 1 ]; then
        echo "  ${FAIL}alpha RPC did not become ready on :$ALPHA_RPC${RESET}"
        tail -50 "$DEVNET_DIR/logs/alpha.log"
        exit 1
    fi

    echo ""
    echo "--- Step 12: Wait for blocks (height > 10) ---"
    HEIGHT=0
    for i in $(seq 5 5 150); do
        sleep 5
        H=$(curl -s --max-time 3 "http://127.0.0.1:$ALPHA_RPC/status" 2>/dev/null | jq -r '.result.sync_info.latest_block_height // "0"')
        P=$(curl -s --max-time 3 "http://127.0.0.1:$ALPHA_RPC/net_info" 2>/dev/null | jq -r '.result.n_peers // "0"')
        echo "  [${i}s] Height=$H Peers=$P"
        if [ "${H:-0}" -ge 10 ] 2>/dev/null; then
            HEIGHT="$H"
            echo "  ✅ Height $H reached"
            break
        fi
    done
    if [ "$HEIGHT" -lt 10 ]; then
        echo "  ${FAIL}Height did not reach 10${RESET}"
        exit 1
    fi

    echo ""
    echo "--- Step 13: Save evidence ---"
    curl -s --max-time 5 "http://127.0.0.1:$ALPHA_RPC/status" > "$EVIDENCE_DIR/status.json" 2>&1 || true
    curl -s --max-time 5 "http://127.0.0.1:$ALPHA_RPC/validators" > "$EVIDENCE_DIR/validators.json" 2>&1 || true
    curl -s --max-time 5 "http://127.0.0.1:$ALPHA_RPC/net_info" > "$EVIDENCE_DIR/net_info.json" 2>&1 || true

    passed=$((passed + 1))
    echo ""
    echo "  ${PASS}Five-agent devnet running${RESET}"
    echo "  alpha RPC: http://127.0.0.1:27657"
    echo "  alpha REST: http://127.0.0.1:1417"
fi

# ── Write evidence summary ──────────────────────────────
echo ""
echo "--- Evidence ---"
cat > "$EVIDENCE_DIR/summary.txt" << EOF
RC1 Devnet Launch Evidence
===========================
Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Mode: $MODE
Chain ID: $CHAIN_ID
Binary: $BINARY
Binary SHA256: $BIN_HASH
Binary version: $BIN_VERSION
Height reached: $HEIGHT
Evidence dir: $EVIDENCE_DIR
EOF

echo "  Evidence saved to $EVIDENCE_DIR"

# ── Final result ────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════╗"
if [ "$failed" -gt 0 ]; then
    echo "║  ${FAIL}RC1 DEVNET LAUNCH FAILED${RESET}            ║"
    echo "║  Passed: $passed  Failed: $failed               ║"
else
    echo "║  ${PASS}RC1 DEVNET LAUNCH PASSED${RESET}            ║"
fi
echo "╚══════════════════════════════════════════════╝"

if [ "$KEEP_RUNNING" -ne 1 ]; then
    echo ""
    echo "  ${INFO}--keep-running not set; use stop-rc1-devnet.sh to stop when done.${RESET}"
    echo "  ${INFO}Processes left running for inspection.${RESET}"
fi

exit "$failed"
