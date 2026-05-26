#!/usr/bin/env bash
# NexaRail Local 3-Validator Rehearsal Orchestrator v3
# Fixed: persistent_peers configured BEFORE start, P2P discovery works.
# TESTNET REHEARSAL ONLY — no mainnet, no public network, tokens have zero value.
set -uo pipefail

CHAIN_ID="nexarail-testnet-1"
DENOM="unxrl"
REHEARSAL_DIR="rehearsals/testnet-1"
BINARY="./build/nexaraild"

CLEAN_MODE=false
[[ "${1:-}" == "--clean" ]] && CLEAN_MODE=true

$CLEAN_MODE && { echo "🧹 Clean mode"; rm -rf "$REHEARSAL_DIR"; }
mkdir -p "$REHEARSAL_DIR"/{genesis,gentxs,validator-notes,logs,checksums}

echo "╔══════════════════════════════════════════╗"
echo "║  NexaRail 3-Validator Rehearsal v3      ║"
echo "║  Chain: $CHAIN_ID                  ║"
echo "╚══════════════════════════════════════════╝"

# Step 1: Build
echo -e "\n--- Step 1: Build ---"
[ -f "$BINARY" ] || make build
echo "  ✅ Binary: $BINARY"

# Step 2: Init 3 validators on unique ports
echo -e "\n--- Step 2: Init validators ---"
HOMES=()
# val0: p2p=26656 rpc=26657 rest=1317 grpc=9090
# val1: p2p=26666 rpc=26667 rest=1318 grpc=9091  
# val2: p2p=26676 rpc=26677 rest=1319 grpc=9092
PORT_CFG=("26656|26657|1317|9090" "26666|26667|1318|9091" "26676|26677|1319|9092")

for i in 0 1 2; do
    home="$REHEARSAL_DIR/validator-notes/val$i"
    HOMES+=("$home")
    rm -rf "$home"
    $BINARY init "val$i" --chain-id "$CHAIN_ID" --home "$home" > /dev/null 2>&1
    IFS='|' read -r p2p rpc rest grpc <<< "${PORT_CFG[$i]}"
    sed -i '' "s|^laddr = \"tcp://.*:26657\"|laddr = \"tcp://0.0.0.0:$rpc\"|" "$home/config/config.toml" 2>/dev/null || sed -i "s|^laddr = \"tcp://.*:26657\"|laddr = \"tcp://0.0.0.0:$rpc\"|" "$home/config/config.toml"
    sed -i '' "s|^laddr = \"tcp://.*:26656\"|laddr = \"tcp://0.0.0.0:$p2p\"|" "$home/config/config.toml" 2>/dev/null || sed -i "s|^laddr = \"tcp://.*:26656\"|laddr = \"tcp://0.0.0.0:$p2p\"|" "$home/config/config.toml"
    echo "  ✅ val$i: home=$home P2P=$p2p RPC=$rpc"
done
TEMPLATE_HOME="${HOMES[0]}"

# Step 3: Keys
echo -e "\n--- Step 3: Keys ---"
ADDRS=()
for home in "${HOMES[@]}"; do
    name=$(basename "$home")
    $BINARY keys add "$name" --keyring-backend test --home "$home" > /dev/null 2>&1 || true
    addr=$($BINARY keys show "$name" -a --keyring-backend test --home "$home" 2>/dev/null)
    ADDRS+=("$addr")
    echo "  ✅ $name: $addr"
done

# Step 4: Genesis
echo -e "\n--- Step 4: Genesis ---"
for addr in "${ADDRS[@]}"; do
    $BINARY add-genesis-account "$addr" "1000000000000$DENOM" --home "$TEMPLATE_HOME" 2>/dev/null || true
done
$BINARY keys add faucet --keyring-backend test --home "$TEMPLATE_HOME" > /dev/null 2>&1 || true
FAUCET=$($BINARY keys show faucet -a --keyring-backend test --home "$TEMPLATE_HOME" 2>/dev/null)
$BINARY add-genesis-account "$FAUCET" "100000000000000$DENOM" --home "$TEMPLATE_HOME" 2>/dev/null || true
TMP=$(mktemp)
jq '.app_state.gov.voting_params.voting_period = "60s" | .app_state.staking.params.bond_denom = "'$DENOM'" | .app_state.crisis.constant_fee.denom = "'$DENOM'" | .app_state.params = {}' "$TEMPLATE_HOME/config/genesis.json" > "$TMP" && mv "$TMP" "$TEMPLATE_HOME/config/genesis.json"
echo "  ✅ Bonds=$DENOM voting=60s"

# Step 5: Gentx
echo -e "\n--- Step 5: Gentx ---"
for i in 0 1 2; do
    home="${HOMES[$i]}"
    [ "$home" != "$TEMPLATE_HOME" ] && cp "$TEMPLATE_HOME/config/genesis.json" "$home/config/genesis.json"
    $BINARY gentx "val$i" "500000000$DENOM" --chain-id "$CHAIN_ID" --moniker "val$i" \
        --commission-rate 0.05 --commission-max-rate 0.20 --commission-max-change-rate 0.01 \
        --min-self-delegation 1 --keyring-backend test --home "$home" > /dev/null 2>&1 && \
        echo "  ✅ val$i gentx" || echo "  ❌ val$i gentx failed"
    mkdir -p "$TEMPLATE_HOME/config/gentx"
    [ "$home" != "$TEMPLATE_HOME" ] && ls "$home/config/gentx/"*.json >/dev/null 2>&1 && cp "$home/config/gentx/"*.json "$TEMPLATE_HOME/config/gentx/"
done

# Step 6: Collect
echo -e "\n--- Step 6: Collect gentxs ---"
$BINARY collect-gentxs --home "$TEMPLATE_HOME" 2>/dev/null
N=$(python3 -c "import json; g=json.load(open('$TEMPLATE_HOME/config/genesis.json')); print(len(g['app_state']['genutil']['gen_txs']))" 2>/dev/null || echo "0")
echo "  ✅ gen_txs: $N"

# Step 7: Validate + distribute
echo -e "\n--- Step 7: Validate + distribute genesis ---"
$BINARY validate-genesis --home "$TEMPLATE_HOME" 2>&1 | tail -1 || true
sha256sum "$TEMPLATE_HOME/config/genesis.json" | awk '{print $1}' > "$REHEARSAL_DIR/checksums/SHA256SUMS"
for home in "${HOMES[@]}"; do
    [ "$home" != "$TEMPLATE_HOME" ] && cp "$TEMPLATE_HOME/config/genesis.json" "$home/config/genesis.json"
done
echo "  ✅ Genesis distributed"

# Step 8: P2P config — extract node IDs from node_key.json
echo -e "\n--- Step 8: P2P config ---"
get_node_id() {
    python3 -c "
import json, hashlib, base64
with open('$1/config/node_key.json') as f:
    k = json.load(f)
pk = base64.b64decode(k['priv_key']['value'])[32:]
print(hashlib.sha256(pk).hexdigest()[:40])
" 2>/dev/null || echo "UNKNOWN"
}

NODE_IDS=()
P2P_PORTS=(26656 26666 26676)
for i in 0 1 2; do
    NODE_IDS+=("$(get_node_id "${HOMES[$i]}")")
    echo "  val$i node_id: ${NODE_IDS[$i]}  p2p: ${P2P_PORTS[$i]}"
done

# Configure each validator
for i in 0 1 2; do
    home="${HOMES[$i]}"
    peers=""
    for j in 0 1 2; do
        [ "$i" = "$j" ] && continue
        [ -n "$peers" ] && peers+=","
        peers+="${NODE_IDS[$j]}@127.0.0.1:${P2P_PORTS[$j]}"
    done
    
    sed -i '' "s|^persistent_peers = .*|persistent_peers = \"$peers\"|" "$home/config/config.toml" 2>/dev/null || \
    sed -i "s|^persistent_peers = .*|persistent_peers = \"$peers\"|" "$home/config/config.toml"
    sed -i '' 's|^allow_duplicate_ip = .*|allow_duplicate_ip = true|' "$home/config/config.toml" 2>/dev/null || \
    sed -i 's|^allow_duplicate_ip = .*|allow_duplicate_ip = true|' "$home/config/config.toml"
    sed -i '' 's|^addr_book_strict = .*|addr_book_strict = false|' "$home/config/config.toml" 2>/dev/null || \
    sed -i 's|^addr_book_strict = .*|addr_book_strict = false|' "$home/config/config.toml"
    sed -i '' 's|^pex = .*|pex = true|' "$home/config/config.toml" 2>/dev/null || \
    sed -i 's|^pex = .*|pex = true|' "$home/config/config.toml"
    
    echo "  val$i peers: $peers"
done

# Step 9: Start
echo -e "\n--- Step 9: Start ---"
PIDS=()
for i in 0 1 2; do
    home="${HOMES[$i]}"
    IFS='|' read -r p2p rpc rest grpc <<< "${PORT_CFG[$i]}"
    rm -f "$home/config/app.toml"
    $BINARY start --home "$home" --minimum-gas-prices "0$DENOM" > "$REHEARSAL_DIR/logs/val$i.log" 2>&1 &
    pid=$!
    PIDS+=("$pid")
    echo "  ✅ val$i: PID=$pid RPC=http://127.0.0.1:$rpc"
done
printf '%s\n' "${PIDS[@]}" > "$REHEARSAL_DIR/logs/pids.txt"

# Step 10: Wait for blocks
echo -e "\n--- Step 10: Waiting for blocks ---"
IFS='|' read -r p2p rpc rest grpc <<< "${PORT_CFG[0]}"
for t in $(seq 5 5 120); do
    sleep 5
    STATUS=$(curl -s "http://127.0.0.1:$rpc/status" 2>/dev/null || echo '{}')
    HEIGHT=$(echo "$STATUS" | jq -r '.result.sync_info.latest_block_height // "0"')
    NETWORK=$(echo "$STATUS" | jq -r '.result.node_info.network // ""')
    PEERS=$(curl -s "http://127.0.0.1:$rpc/net_info" 2>/dev/null | jq -r '.result.n_peers // "0"')
    echo "  [${t}s] Height=$HEIGHT Peers=$PEERS Network=$NETWORK"
    if [ "${HEIGHT:-0}" -ge 3 ] 2>/dev/null; then
        echo ""
        echo "╔══════════════════════════════════════════╗"
        echo "║  🚀 REHEARSAL SUCCESS!                  ║"
        echo "║  Chain: $NETWORK  Height: $HEIGHT  Peers: $PEERS ║"
        echo "╚══════════════════════════════════════════╝"
        exit 0
    fi
done

echo -e "\n⚠️  Timeout. Logs: $REHEARSAL_DIR/logs/"
exit 1
