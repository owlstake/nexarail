#!/usr/bin/env bash
# NexaRail — Spawn Autonomous Validator Agents
# Creates and starts 5 local validator agents for nexarail-agent-testnet-1.
# TESTNET/DEVNET ONLY — not for mainnet (none exists).
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
BINARY="$PROJECT_DIR/build/nexaraild"
CHAIN_ID="nexarail-agent-testnet-1"
DENOM="unxrl"
AGENT_DIR="$PROJECT_DIR/rehearsals/validator-agents"
TIMESTAMP="${SPAWN_TIMESTAMP:-$(date -u +%Y%m%dT%H%M%SZ)}"
EVIDENCE_DIR="${EVIDENCE_DIR:-$AGENT_DIR/clean-spawn-governance/evidence/$TIMESTAMP}"
CLEAN_MODE=0
FULL_RESET=0
REUSE_DATA=0
FORCE_CLEAN=0
NO_TMUX=0
AGENT_COUNT=5

usage() {
    cat <<EOF
Usage: scripts/testnet/spawn-validator-agents.sh [--clean|--full-reset|--reuse-data] [--force-clean] [--no-tmux] [--evidence-dir PATH] [--agent-count N]

Modes:
  --clean       Stop old agents, wipe each agent data/ directory, regenerate genesis/gentxs.
  --full-reset  Stop old agents, delete each agent home, regenerate all homes/genesis/gentxs.
  --reuse-data  Explicitly reuse existing data directories. Diagnostic only.
  --force-clean Kill stale validator-agent runtime and validator-agent port owners automatically.
  --no-tmux     Start agents with nohup even when tmux exists.
  --evidence-dir PATH
                Save spawn diagnostics/evidence in PATH.
  --agent-count Number of local agents to start from the alpha..echo set. Default: 5.

Default mode refuses stale data. Use --clean for Phase 9T clean-spawn evidence.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --clean)
            CLEAN_MODE=1
            shift
            ;;
        --full-reset)
            CLEAN_MODE=1
            FULL_RESET=1
            shift
            ;;
        --reuse-data)
            REUSE_DATA=1
            shift
            ;;
        --force-clean)
            FORCE_CLEAN=1
            shift
            ;;
        --no-tmux)
            NO_TMUX=1
            shift
            ;;
        --evidence-dir)
            EVIDENCE_DIR="${2:-}"
            shift 2
            ;;
        --agent-count)
            AGENT_COUNT="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            usage
            exit 1
            ;;
    esac
done

case "$AGENT_COUNT" in
    1|2|3|4|5) ;;
    *)
        echo "Invalid --agent-count: $AGENT_COUNT (expected 1-5)"
        exit 1
        ;;
esac

if [ "$REUSE_DATA" -eq 1 ] && [ "$CLEAN_MODE" -eq 1 ]; then
    echo "Refusing conflicting modes: --reuse-data cannot be combined with --clean/--full-reset"
    exit 1
fi

# Agent definitions: name, moniker, rpc, p2p, api, grpc
AGENTS=(
    "alpha:nxrl-validator-agent-alpha:27657:27656:1417:9190"
    "bravo:nxrl-validator-agent-bravo:27667:27666:1418:9191"
    "charlie:nxrl-validator-agent-charlie:27677:27676:1419:9192"
    "delta:nxrl-validator-agent-delta:27687:27686:1420:9193"
    "echo:nxrl-validator-agent-echo:27697:27696:1421:9194"
)
AGENTS=("${AGENTS[@]:0:$AGENT_COUNT}")

cleanup() {
    echo ""
    echo "⚠️  Script interrupted. Capturing diagnostics and stopping validator-agent runtime."
    "$SCRIPT_DIR/diagnose-agent-freeze.sh" --evidence-dir "$EVIDENCE_DIR" --label spawn-interrupted >/dev/null 2>&1 || true
    "$SCRIPT_DIR/stop-validator-agents.sh" --force --evidence-dir "$EVIDENCE_DIR" >/dev/null 2>&1 || true
}
on_error() {
    local code="$?"
    local line="${1:-unknown}"
    echo "  ❌ spawn-validator-agents.sh failed at line $line exit_code=$code"
    "$SCRIPT_DIR/diagnose-agent-freeze.sh" --evidence-dir "$EVIDENCE_DIR" --label spawn-error-line-$line \
        > "$EVIDENCE_DIR/diagnostics/spawn-error-line-$line.log" 2>&1 || true
    exit "$code"
}
trap 'on_error $LINENO' ERR
trap cleanup INT TERM

mkdir -p "$AGENT_DIR/logs" "$AGENT_DIR/genesis" "$AGENT_DIR/evidence" "$AGENT_DIR/pids" "$EVIDENCE_DIR" "$EVIDENCE_DIR/diagnostics"

agent_pids() {
    pgrep -f "nexaraild.*validator-agents" 2>/dev/null || true
}

diagnose_and_fail() {
    local label="$1"
    local message="$2"
    echo "  ❌ $message"
    "$SCRIPT_DIR/diagnose-agent-freeze.sh" --evidence-dir "$EVIDENCE_DIR" --label "$label" \
        > "$EVIDENCE_DIR/diagnostics/${label}.log" 2>&1 || true
    exit 1
}

require_or_stop_old_agents() {
    local pids
    pids="$(agent_pids)"
    if [ -z "$pids" ]; then
        echo "  ✅ No running validator agents detected"
        return 0
    fi

    echo "  ⚠️  Running validator agents detected:"
    echo "$pids" | sed 's/^/    PID: /'
    if [ "$FORCE_CLEAN" -ne 1 ]; then
        diagnose_and_fail "spawn-stale-processes" "Refusing to spawn while stale validator-agent processes are running. Re-run with --force-clean for harness-owned cleanup."
    fi

    echo "  Force-clean enabled; stopping old validator-agent runtime..."
    "$SCRIPT_DIR/stop-validator-agents.sh" --force --evidence-dir "$EVIDENCE_DIR" || true
    sleep 2

    pids="$(agent_pids)"
    if [ -n "$pids" ]; then
        diagnose_and_fail "spawn-stale-processes-after-force-clean" "Validator-agent processes survived force-clean."
    fi
    echo "  ✅ Old validator agents stopped"
}

port_owner_is_validator_agent() {
    local pid="$1"
    ps -p "$pid" -o command= 2>/dev/null | grep -q "$AGENT_DIR"
}

check_or_clean_ports() {
    local used=0 pid port
    : > "$EVIDENCE_DIR/port-check-before.txt"
    for agent_def in "${AGENTS[@]}"; do
        IFS=':' read -r _name _moniker rpc p2p api grpc <<< "$agent_def"
        for port in "$rpc" "$p2p" "$api" "$grpc"; do
            pids="$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)"
            if [ -z "$pids" ]; then
                echo "PASS port $port free" >> "$EVIDENCE_DIR/port-check-before.txt"
                continue
            fi
            used=1
            echo "FAIL port $port in use by $pids" >> "$EVIDENCE_DIR/port-check-before.txt"
            if [ "$FORCE_CLEAN" -eq 1 ]; then
                for pid in $pids; do
                    [ -z "$pid" ] && continue
                    if port_owner_is_validator_agent "$pid"; then
                        echo "  Force-clean: stopping validator-agent port owner PID $pid on port $port"
                        kill "$pid" >/dev/null 2>&1 || true
                    else
                        diagnose_and_fail "spawn-port-${port}-owned-by-non-agent" "Port $port is owned by non-validator-agent PID $pid."
                    fi
                done
            fi
        done
    done
    if [ "$used" -eq 1 ] && [ "$FORCE_CLEAN" -eq 1 ]; then
        sleep 2
        used=0
        : > "$EVIDENCE_DIR/port-check-after-force-clean.txt"
        for agent_def in "${AGENTS[@]}"; do
            IFS=':' read -r _name _moniker rpc p2p api grpc <<< "$agent_def"
            for port in "$rpc" "$p2p" "$api" "$grpc"; do
                if lsof -tiTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
                    echo "FAIL port $port still in use" >> "$EVIDENCE_DIR/port-check-after-force-clean.txt"
                    used=1
                else
                    echo "PASS port $port free" >> "$EVIDENCE_DIR/port-check-after-force-clean.txt"
                fi
            done
        done
    fi
    if [ "$used" -eq 1 ]; then
        diagnose_and_fail "spawn-port-conflict" "Refusing to spawn while validator-agent ports are in use."
    fi
    echo "  ✅ Agent ports free"
}

wait_for_rpc() {
    local name="$1"
    local rpc="$2"
    local status_file="$EVIDENCE_DIR/${name}-rpc-status.json"
    local h
    for _ in $(seq 1 30); do
        curl -s --max-time 3 "http://127.0.0.1:$rpc/status" > "$status_file" 2> "$status_file.err" || true
        h="$(jq -r '.result.sync_info.latest_block_height // "0"' "$status_file" 2>/dev/null || echo "0")"
        if jq -e '.result.node_info.network' "$status_file" >/dev/null 2>&1; then
            rm -f "$status_file.err"
            echo "  ✅ $name RPC ready (height $h)"
            return 0
        fi
        sleep 2
    done
    echo "  ❌ $name RPC not ready on :$rpc"
    tail -100 "$AGENT_DIR/logs/${name}.log" 2>/dev/null || true
    return 1
}

wait_for_grpc_port() {
    local name="$1"
    local grpc="$2"
    if ! command -v nc >/dev/null 2>&1; then
        echo "  ⚠️  nc unavailable; skipping $name gRPC socket check"
        return 0
    fi
    for _ in $(seq 1 30); do
        if nc -z 127.0.0.1 "$grpc" >/dev/null 2>&1; then
            echo "  ✅ $name gRPC socket ready (:${grpc})"
            return 0
        fi
        sleep 1
    done
    echo "  ❌ $name gRPC socket not ready (:${grpc})"
    return 1
}

echo "╔══════════════════════════════════════════╗"
echo "║  NexaRail — Spawn Validator Agents      ║"
echo "║  Chain: $CHAIN_ID                 ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Step 1: Build
echo "--- Step 1: Build ---"
if [ ! -f "$BINARY" ]; then
    cd "$PROJECT_DIR" && make build
fi
echo "  ✅ Binary: $BINARY"
"$BINARY" version 2>/dev/null || echo "  ⚠️  version command failed (non-fatal)"

# Step 2: Runtime/data hygiene
echo ""
echo "--- Step 2: Runtime/data hygiene ---"
require_or_stop_old_agents
check_or_clean_ports

if [ "$REUSE_DATA" -eq 1 ]; then
    "$SCRIPT_DIR/check-agent-data-clean.sh" --allow-reuse --evidence-dir "$EVIDENCE_DIR"
elif [ "$CLEAN_MODE" -eq 1 ]; then
    "$SCRIPT_DIR/check-agent-data-clean.sh" --clean --evidence-dir "$EVIDENCE_DIR"
else
    "$SCRIPT_DIR/check-agent-data-clean.sh" --evidence-dir "$EVIDENCE_DIR"
fi

printf '%s\n' "$TIMESTAMP" > "$AGENT_DIR/phase9t-latest-evidence-timestamp.txt"
printf '%s\n' "$EVIDENCE_DIR" > "$AGENT_DIR/phase9t-latest-evidence-path.txt"

AGENT_HOMES=()
AGENT_NAMES=()
NODE_IDS=()
ADDRS=()

if [ "$REUSE_DATA" -eq 1 ]; then
    echo "  ⚠️  REUSE DATA: existing data directories retained by explicit request"
    for agent_def in "${AGENTS[@]}"; do
        IFS=':' read -r name moniker rpc p2p api grpc <<< "$agent_def"
        home="$AGENT_DIR/$name"
        if [ ! -f "$home/config/genesis.json" ]; then
            echo "  ❌ --reuse-data requires existing home with config/genesis.json: $home"
            exit 1
        fi
        echo "  ✅ $name existing home retained at $home"
    done
else
    echo "  CLEAN SPAWN: data directories wiped"
    for agent_def in "${AGENTS[@]}"; do
        IFS=':' read -r name moniker rpc p2p api grpc <<< "$agent_def"
        home="$AGENT_DIR/$name"
        if [ "$FULL_RESET" -eq 1 ]; then
            rm -rf "$home"
        else
            rm -rf "$home/data" "$home/config" "$home/.nexarail"
        fi
    done
    rm -f "$AGENT_DIR"/pids/*.pid 2>/dev/null || true
    rm -f "$AGENT_DIR"/logs/*.log 2>/dev/null || true
fi

echo ""
echo "--- Step 3: Create agent homes ---"
for agent_def in "${AGENTS[@]}"; do
    IFS=':' read -r name moniker rpc p2p api grpc <<< "$agent_def"
    AGENT_NAMES+=("$name")
    home="$AGENT_DIR/$name"
    AGENT_HOMES+=("$home")

    if [ "$REUSE_DATA" -eq 0 ]; then
        mkdir -p "$home/data"
        "$BINARY" init "$moniker" --chain-id "$CHAIN_ID" --home "$home" --overwrite > /dev/null 2>&1
        echo "  ✅ $name ($moniker) initialised at $home"
    fi
done

# Use first agent as genesis template
TEMPLATE_HOME="${AGENT_HOMES[0]}"

# Step 4: Keys
echo ""
echo "--- Step 4: Create keys ---"
for i in "${!AGENTS[@]}"; do
    IFS=':' read -r name moniker rpc p2p api grpc <<< "${AGENTS[$i]}"
    home="${AGENT_HOMES[$i]}"
    
    "$BINARY" keys add "${name}-key" --keyring-backend test --home "$home" > /dev/null 2>&1 || true
    addr=$("$BINARY" keys show "${name}-key" -a --keyring-backend test --home "$home" 2>/dev/null)
    ADDRS+=("$addr")
    echo "  ✅ $name: $addr"
done

# Step 5: Genesis accounts
echo ""
echo "--- Step 5: Genesis accounts ---"
if [ "$REUSE_DATA" -eq 0 ]; then
    for addr in "${ADDRS[@]}"; do
        "$BINARY" add-genesis-account "$addr" "1000000000000$DENOM" --home "$TEMPLATE_HOME" 2>/dev/null
    done
    echo "  ✅ All accounts added (1,000,000,000,000 unxrl each)"
else
    echo "  ⚠️  Skipped: reusing existing genesis"
fi

# Step 6: Fix genesis params
echo ""
echo "--- Step 6: Fix genesis ---"
if [ "$REUSE_DATA" -eq 0 ]; then
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
    echo "  ✅ Chain ID=$CHAIN_ID, voting=30s, bond=$DENOM"
else
    echo "  ⚠️  Skipped: reusing existing genesis"
fi

# Step 7: Gentx
echo ""
echo "--- Step 7: Create gentxs ---"
if [ "$REUSE_DATA" -eq 0 ]; then
    rm -rf "$TEMPLATE_HOME/config/gentx"
    mkdir -p "$TEMPLATE_HOME/config/gentx"
    for i in "${!AGENTS[@]}"; do
        IFS=':' read -r name moniker rpc p2p api grpc <<< "${AGENTS[$i]}"
        home="${AGENT_HOMES[$i]}"

        [ "$home" != "$TEMPLATE_HOME" ] && cp "$TEMPLATE_HOME/config/genesis.json" "$home/config/genesis.json"
        rm -rf "$home/config/gentx"

        if "$BINARY" gentx "${name}-key" "500000000$DENOM" --chain-id "$CHAIN_ID" --moniker "$moniker" \
            --commission-rate 0.05 --commission-max-rate 0.20 --commission-max-change-rate 0.01 \
            --min-self-delegation 1 --keyring-backend test --home "$home" > /dev/null 2>&1; then
            echo "  ✅ $name gentx created"
        else
            echo "  ❌ $name gentx FAILED"
            exit 1
        fi

        [ "$home" != "$TEMPLATE_HOME" ] && cp "$home/config/gentx/"*.json "$TEMPLATE_HOME/config/gentx/"
    done
else
    echo "  ⚠️  Skipped: reusing existing gentxs/genesis"
fi

# Step 8: Collect gentxs
echo ""
echo "--- Step 8: Collect gentxs ---"
if [ "$REUSE_DATA" -eq 0 ]; then
    "$BINARY" collect-gentxs --home "$TEMPLATE_HOME" 2>/dev/null
fi
N=$(python3 -c "import json; g=json.load(open('$TEMPLATE_HOME/config/genesis.json')); print(len(g['app_state']['genutil']['gen_txs']))" 2>/dev/null || echo "0")
echo "  ✅ gen_txs: $N"
[ "$N" != "${#AGENTS[@]}" ] && echo "  ❌ Expected ${#AGENTS[@]} gentxs, got $N" && exit 1

# Step 9: Node IDs and peer config
echo ""
echo "--- Step 9: Configure P2P ---"
get_node_id() {
    python3 -c "
import json, hashlib, base64
with open('$1/config/node_key.json') as f:
    k = json.load(f)
pk = base64.b64decode(k['priv_key']['value'])[32:]
print(hashlib.sha256(pk).hexdigest()[:40])
" 2>/dev/null || echo "UNKNOWN"
}

for i in "${!AGENTS[@]}"; do
    IFS=':' read -r name moniker rpc p2p api grpc <<< "${AGENTS[$i]}"
    nid=$(get_node_id "${AGENT_HOMES[$i]}")
    NODE_IDS+=("$nid")
    echo "  $name: $nid"
done

# Build peer list
PEER_LIST=""
for i in "${!AGENTS[@]}"; do
    IFS=':' read -r name moniker rpc p2p api grpc <<< "${AGENTS[$i]}"
    [ -n "$PEER_LIST" ] && PEER_LIST+=","
    PEER_LIST+="${NODE_IDS[$i]}@127.0.0.1:${p2p}"
done

for i in "${!AGENTS[@]}"; do
    IFS=':' read -r name moniker rpc p2p api grpc <<< "${AGENTS[$i]}"
    home="${AGENT_HOMES[$i]}"
    
    # Build peers excluding self
    MY_PEERS=""
    for j in "${!AGENTS[@]}"; do
        [ "$i" = "$j" ] && continue
        IFS=':' read -r jname jmoniker jrpc jp2p japi jgrpc <<< "${AGENTS[$j]}"
        [ -n "$MY_PEERS" ] && MY_PEERS+=","
        MY_PEERS+="${NODE_IDS[$j]}@127.0.0.1:${jp2p}"
    done
    
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

    # Enable API and gRPC in app.toml
    AT="$home/config/app.toml"
    if [ -f "$AT" ]; then
        sed -i '' 's|^enable = false|enable = true|' "$AT" 2>/dev/null || sed -i 's|^enable = false|enable = true|' "$AT"
        sed -i '' "s|^address = \"tcp://localhost:1317\"|address = \"tcp://0.0.0.0:${api}\"|" "$AT" 2>/dev/null || \
        sed -i "s|^address = \"tcp://localhost:1317\"|address = \"tcp://0.0.0.0:${api}\"|" "$AT"
        # Fix gRPC address — handle localhost:9090 and 0.0.0.0:9090 template defaults
        if grep -q 'address = "localhost:9090"' "$AT" 2>/dev/null; then
            sed -i '' "s|address = \"localhost:9090\"|address = \"0.0.0.0:${grpc}\"|" "$AT" 2>/dev/null || \
            sed -i "s|address = \"localhost:9090\"|address = \"0.0.0.0:${grpc}\"|" "$AT"
        fi
        if grep -q 'address = "0.0.0.0:9090"' "$AT" 2>/dev/null; then
            sed -i '' "s|address = \"0.0.0.0:9090\"|address = \"0.0.0.0:${grpc}\"|" "$AT" 2>/dev/null || \
            sed -i "s|address = \"0.0.0.0:9090\"|address = \"0.0.0.0:${grpc}\"|" "$AT"
        fi
        # Fix gRPC-web address
        if grep -q 'address = "localhost:9091"' "$AT" 2>/dev/null; then
            sed -i '' "s|address = \"localhost:9091\"|address = \"0.0.0.0:$((grpc+1))\"|" "$AT" 2>/dev/null || \
            sed -i "s|address = \"localhost:9091\"|address = \"0.0.0.0:$((grpc+1))\"|" "$AT"
        fi
        # Phase 9H: Disable pruning for governance testing
        sed -i '' 's|^pruning = .*|pruning = "nothing"|' "$AT" 2>/dev/null || sed -i 's|^pruning = .*|pruning = "nothing"|' "$AT"
        # Keep only API/gRPC enabled. Rosetta and gRPC-web trigger query noise during local rehearsal.
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
        elif line.startswith("pruning = "):
            line = 'pruning = "nothing"\n'
        out.append(line)
with open(path, "w") as f:
    f.writelines(out)
PY
    fi
    echo "  ✅ $name configured (RPC:$rpc P2P:$p2p API:$api gRPC:$grpc)"
done

# Step 10: Distribute genesis
echo ""
echo "--- Step 10: Distribute genesis ---"
if [ "$REUSE_DATA" -eq 0 ]; then
    for home in "${AGENT_HOMES[@]}"; do
        [[ "$home" != "$TEMPLATE_HOME" ]] && cp "$TEMPLATE_HOME/config/genesis.json" "$home/config/genesis.json"
    done
fi

# Save genesis
cp "$TEMPLATE_HOME/config/genesis.json" "$AGENT_DIR/genesis/genesis.json"
sha256sum "$AGENT_DIR/genesis/genesis.json" | awk '{print $1}' > "$AGENT_DIR/genesis/genesis-checksum.txt"
echo "  ✅ Genesis distributed, checksum: $(cat $AGENT_DIR/genesis/genesis-checksum.txt)"

cat > "$AGENT_DIR/clean-spawn-proof.txt" << EOF
Clean spawn proof
Timestamp UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Mode: $([ "$REUSE_DATA" -eq 1 ] && echo "reuse-data" || { [ "$FULL_RESET" -eq 1 ] && echo "full-reset" || echo "clean"; })
Policy: stale data refused unless --clean/--full-reset wipes it or --reuse-data explicitly keeps it.
Data policy: $([ "$REUSE_DATA" -eq 1 ] && echo "existing data directories explicitly retained" || echo "data directories wiped for clean spawn")
Genesis checksum: $(cat "$AGENT_DIR/genesis/genesis-checksum.txt")
Agent count: ${#AGENTS[@]}
gen_txs: $N
Evidence: $EVIDENCE_DIR
EOF
cp "$AGENT_DIR/clean-spawn-proof.txt" "$EVIDENCE_DIR/clean-spawn-proof.txt"
cp "$AGENT_DIR/genesis/genesis-checksum.txt" "$EVIDENCE_DIR/genesis-checksum.txt"

# Step 11: Start all agents
echo ""
echo "--- Step 11: Start agents ---"
for i in "${!AGENTS[@]}"; do
    IFS=':' read -r name moniker rpc p2p api grpc <<< "${AGENTS[$i]}"
    home="${AGENT_HOMES[$i]}"
    log="$AGENT_DIR/logs/${name}.log"
    session="nexarail-agent-${name}"

    if [ "$NO_TMUX" -eq 0 ] && command -v tmux >/dev/null 2>&1; then
        tmux kill-session -t "$session" >/dev/null 2>&1 || true
        tmux new-session -d -s "$session" \
            "exec \"$BINARY\" start --home \"$home\" --minimum-gas-prices \"0$DENOM\" --api.enable --api.address \"tcp://0.0.0.0:${api}\" --api.enabled-unsafe-cors --grpc.enable --grpc.address \"0.0.0.0:${grpc}\" > \"$log\" 2>&1"
        PID=$(tmux display-message -p -t "$session" "#{pane_pid}")
    else
        nohup "$BINARY" start --home "$home" --minimum-gas-prices "0$DENOM" \
            --api.enable --api.address "tcp://0.0.0.0:${api}" --api.enabled-unsafe-cors \
            --grpc.enable --grpc.address "0.0.0.0:${grpc}" \
            > "$log" 2>&1 < /dev/null &
        PID=$!
    fi
    echo $PID > "$AGENT_DIR/pids/${name}.pid"
    echo "  ✅ $name started (PID: $PID)"
    sleep 3
    if ! kill -0 "$PID" >/dev/null 2>&1; then
        echo "  ❌ $name died immediately after start"
        tail -100 "$log" 2>/dev/null || true
        diagnose_and_fail "spawn-${name}-died" "$name died immediately after start."
    fi
done

echo ""
echo "--- Step 11B: Verify agent sockets ---"
for agent_def in "${AGENTS[@]}"; do
    IFS=':' read -r name moniker rpc p2p api grpc <<< "$agent_def"
    wait_for_rpc "$name" "$rpc" || diagnose_and_fail "spawn-${name}-rpc-not-ready" "$name RPC did not become ready."
    wait_for_grpc_port "$name" "$grpc" || diagnose_and_fail "spawn-${name}-grpc-not-ready" "$name gRPC did not become ready."
done

# Step 12: Wait for blocks
echo ""
echo "--- Step 12: Wait for blocks ---"
ALPHA_RPC=27657
MIN_PEERS=$((AGENT_COUNT - 1))
READY=0
FIRST_HEIGHT=""
for i in $(seq 5 5 180); do
    sleep 5
    H=$(curl -s --max-time 3 "http://127.0.0.1:$ALPHA_RPC/status" 2>/dev/null | jq -r '.result.sync_info.latest_block_height // "0"')
    P=$(curl -s --max-time 3 "http://127.0.0.1:$ALPHA_RPC/net_info" 2>/dev/null | jq -r '.result.n_peers // "0"')
    [ -z "$FIRST_HEIGHT" ] && FIRST_HEIGHT="${H:-0}"
    echo "  [${i}s] Height=$H Peers=$P"
    if [ "${H:-0}" -ge 10 ] 2>/dev/null && [ "${P:-0}" -ge "$MIN_PEERS" ] 2>/dev/null; then
        READY=1
        break
    fi
done
if [ "$READY" -ne 1 ]; then
    diagnose_and_fail "spawn-block-readiness" "Agents did not reach height >=10 and peer count >=$MIN_PEERS before timeout."
fi

NEXT_HEIGHT="${H:-0}"
ADVANCED=0
for _ in $(seq 1 12); do
    sleep 5
    NEXT_HEIGHT=$(curl -s --max-time 3 "http://127.0.0.1:$ALPHA_RPC/status" 2>/dev/null | jq -r '.result.sync_info.latest_block_height // "0"')
    if [ "${NEXT_HEIGHT:-0}" -gt "${H:-0}" ] 2>/dev/null; then
        ADVANCED=1
        break
    fi
done
if [ "$ADVANCED" -ne 1 ]; then
    diagnose_and_fail "spawn-height-not-advancing" "Block height did not advance after readiness within 60s (height $H -> $NEXT_HEIGHT)."
fi

VAL_COUNT=$(curl -s --max-time 3 "http://127.0.0.1:$ALPHA_RPC/validators" 2>/dev/null | jq -r '.result.validators | length // 0')
if [ "$VAL_COUNT" != "$AGENT_COUNT" ]; then
    diagnose_and_fail "spawn-validator-set-count" "Validator set count $VAL_COUNT does not match agent count $AGENT_COUNT."
fi

echo ""
echo "  🚀 All agent validators producing blocks (height $H -> $NEXT_HEIGHT, validators=$VAL_COUNT)"

# Step 13: Write endpoints
echo ""
echo "--- Step 13: Write endpoints and summary ---"
cat > "$AGENT_DIR/endpoints.md" << EOF
# Validator Agent Endpoints — nexarail-agent-testnet-1

| Agent | Moniker | RPC | P2P | API | gRPC |
|---|---|---|---|---|---|
EOF
for agent_def in "${AGENTS[@]}"; do
    IFS=':' read -r name moniker rpc p2p api grpc <<< "$agent_def"
    echo "| $name | $moniker | $rpc | $p2p | $api | $grpc |" >> "$AGENT_DIR/endpoints.md"
done

# Write summary
cat > "$AGENT_DIR/summary.md" << EOF
# Validator Agent Summary — nexarail-agent-testnet-1

- Chain ID: $CHAIN_ID
- Denom: $DENOM
- Agent count: ${#AGENTS[@]}
- gen_txs: $N
- Genesis checksum: $(cat $AGENT_DIR/genesis/genesis-checksum.txt)
- Peer list: $PEER_LIST

## Agent Status
| Agent | Moniker | RPC Port | Status |
|---|---|---|---|
EOF
for agent_def in "${AGENTS[@]}"; do
    IFS=':' read -r name moniker rpc p2p api grpc <<< "$agent_def"
    echo "| $name | $moniker | $rpc | Running |" >> "$AGENT_DIR/summary.md"
done

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  ✅ VALIDATOR AGENTS SPAWNED           ║"
echo "║  Chain: $CHAIN_ID                 ║"
echo "║  Agents: ${#AGENTS[@]}  gen_txs: $N               ║"
echo "║  Query: scripts/testnet/query-validator-agents.sh ║"
echo "║  Stop:  scripts/testnet/stop-validator-agents.sh  ║"
echo "╚══════════════════════════════════════════╝"
