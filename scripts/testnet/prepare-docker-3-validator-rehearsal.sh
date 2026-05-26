#!/usr/bin/env bash
# NexaRail Docker 3-Validator Rehearsal Genesis Preparation
# Creates all necessary config files for Docker Compose launch.
# Uses service-name P2P addresses (val0/val1/val2) instead of 127.0.0.1.
# TESTNET REHEARSAL ONLY.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
DOCKER_DIR="$PROJECT_DIR/rehearsals/testnet-1/docker"
BINARY="$PROJECT_DIR/build/nexaraild"
CHAIN_ID="nexarail-testnet-1"
DENOM="unxrl"

echo "╔══════════════════════════════════════════╗"
echo "║  NexaRail Docker Genesis Preparation    ║"
echo "║  Chain: $CHAIN_ID                  ║"
echo "╚══════════════════════════════════════════╝"

# Build if needed
[ -f "$BINARY" ] || (cd "$PROJECT_DIR" && make build)

# Clean + init
rm -rf "$DOCKER_DIR/validator-notes"
VALIDATOR_HOMES=()
for name in val0 val1 val2; do
    home="$DOCKER_DIR/validator-notes/$name"
    VALIDATOR_HOMES+=("$home")
    mkdir -p "$home"
    $BINARY init "$name" --chain-id "$CHAIN_ID" --home "$home" > /dev/null 2>&1
    echo "  ✅ $name initialised"
done
TEMPLATE_HOME="${VALIDATOR_HOMES[0]}"

# Keys
echo -e "\n--- Keys ---"
ADDRS=()
for home in "${VALIDATOR_HOMES[@]}"; do
    name=$(basename "$home")
    $BINARY keys add "$name" --keyring-backend test --home "$home" > /dev/null 2>&1 || true
    addr=$($BINARY keys show "$name" -a --keyring-backend test --home "$home" 2>/dev/null)
    ADDRS+=("$addr")
    echo "  ✅ $name: $addr"
done

# Genesis accounts
echo -e "\n--- Genesis accounts ---"
for addr in "${ADDRS[@]}"; do
    $BINARY add-genesis-account "$addr" "1000000000000$DENOM" --home "$TEMPLATE_HOME" 2>/dev/null || true
done
echo "  ✅ Accounts added"

# Fix genesis: bond denom, voting period, params
TMP=$(mktemp)
jq '.app_state.staking.params.bond_denom = "'$DENOM'" |
    .app_state.gov.voting_params.voting_period = "60s" |
    .app_state.crisis.constant_fee.denom = "'$DENOM'" |
    .app_state.params = {}' \
    "$TEMPLATE_HOME/config/genesis.json" > "$TMP" && mv "$TMP" "$TEMPLATE_HOME/config/genesis.json"
echo "  ✅ Bond=$DENOM voting=60s"

# Enable REST API and gRPC in app.toml (disabled by default in SDK template)
for home in "${VALIDATOR_HOMES[@]}"; do
    AT="$home/config/app.toml"
    if [ -f "$AT" ]; then
        sed -i '' 's|^enable = false|enable = true|' "$AT" 2>/dev/null || sed -i 's|^enable = false|enable = true|' "$AT"
        sed -i '' 's|^address = "tcp://localhost:1317"|address = "tcp://0.0.0.0:1317"|' "$AT" 2>/dev/null || sed -i 's|^address = "tcp://localhost:1317"|address = "tcp://0.0.0.0:1317"|' "$AT"
        sed -i '' 's|^address = "tcp://localhost:1317"|address = "tcp://0.0.0.0:1317"|' "$AT" 2>/dev/null || sed -i 's|^address = "tcp://localhost:1317"|address = "tcp://0.0.0.0:1317"|' "$AT"
        sed -i '' 's|^address = "0.0.0.0:9090"|address = "0.0.0.0:9090"|' "$AT" 2>/dev/null || sed -i 's|^address = "0.0.0.0:9090"|address = "0.0.0.0:9090"|' "$AT"
        # Ensure gRPC is enabled
        sed -i '' 's|^enable = false|enable = true|' "$AT" 2>/dev/null || sed -i 's|^enable = false|enable = true|' "$AT"
        echo "  ✅ $(basename $home) app.toml: API enabled"
    fi
done

# Gentx
echo -e "\n--- Gentx ---"
for home in "${VALIDATOR_HOMES[@]}"; do
    name=$(basename "$home")
    [ "$home" != "$TEMPLATE_HOME" ] && cp "$TEMPLATE_HOME/config/genesis.json" "$home/config/genesis.json"
    $BINARY gentx "$name" "500000000$DENOM" --chain-id "$CHAIN_ID" --moniker "$name" \
        --commission-rate 0.05 --commission-max-rate 0.20 --commission-max-change-rate 0.01 \
        --min-self-delegation 1 --keyring-backend test --home "$home" > /dev/null 2>&1 && \
        echo "  ✅ $name gentx" || echo "  ❌ $name gentx FAILED"
    mkdir -p "$TEMPLATE_HOME/config/gentx"
    [ "$home" != "$TEMPLATE_HOME" ] && ls "$home/config/gentx/"*.json >/dev/null 2>&1 && \
        cp "$home/config/gentx/"*.json "$TEMPLATE_HOME/config/gentx/"
done

# Collect
echo -e "\n--- Collect gentxs ---"
$BINARY collect-gentxs --home "$TEMPLATE_HOME" 2>/dev/null
N=$(python3 -c "import json; g=json.load(open('$TEMPLATE_HOME/config/genesis.json')); print(len(g['app_state']['genutil']['gen_txs']))" 2>/dev/null || echo "0")
echo "  ✅ gen_txs: $N"
[ "$N" != "3" ] && echo "  ❌ Expected 3 gentxs"

# Node IDs
echo -e "\n--- Node IDs ---"
get_id() {
    python3 -c "
import json, hashlib, base64
with open('$1/config/node_key.json') as f:
    k = json.load(f)
pk = base64.b64decode(k['priv_key']['value'])[32:]
print(hashlib.sha256(pk).hexdigest()[:40])
" 2>/dev/null || echo "UNKNOWN"
}

NODE_IDS=()
for home in "${VALIDATOR_HOMES[@]}"; do
    nid=$(get_id "$home")
    NODE_IDS+=("$nid")
    echo "  $(basename "$home"): $nid"
done

# Configure P2P — each validator gets only the OTHER two as peers
for i in "${!VALIDATOR_HOMES[@]}"; do
    home="${VALIDATOR_HOMES[$i]}"
    name=$(basename "$home")
    
    # Build peers excluding self
    PEERS=""
    for j in "${!NODE_IDS[@]}"; do
        [ "$i" = "$j" ] && continue
        [ -n "$PEERS" ] && PEERS+=","
        case $j in
            0) PEERS+="${NODE_IDS[$j]}@val0:26656" ;;
            1) PEERS+="${NODE_IDS[$j]}@val1:26656" ;;
            2) PEERS+="${NODE_IDS[$j]}@val2:26656" ;;
        esac
    done
    echo "  $name peers: $PEERS"
    sed -i '' "s|^persistent_peers = .*|persistent_peers = \"$PEERS\"|" "$home/config/config.toml" 2>/dev/null || \
    sed -i "s|^persistent_peers = .*|persistent_peers = \"$PEERS\"|" "$home/config/config.toml"
    sed -i '' 's|^pex = .*|pex = true|' "$home/config/config.toml" 2>/dev/null || \
    sed -i 's|^pex = .*|pex = true|' "$home/config/config.toml"
    sed -i '' 's|^addr_book_strict = .*|addr_book_strict = false|' "$home/config/config.toml" 2>/dev/null || \
    sed -i 's|^addr_book_strict = .*|addr_book_strict = false|' "$home/config/config.toml"
    sed -i '' 's|^allow_duplicate_ip = .*|allow_duplicate_ip = true|' "$home/config/config.toml" 2>/dev/null || \
    sed -i 's|^allow_duplicate_ip = .*|allow_duplicate_ip = true|' "$home/config/config.toml"
    # P2P listen on all interfaces inside container
    sed -i '' 's|^laddr = "tcp://.*:26656"|laddr = "tcp://0.0.0.0:26656"|' "$home/config/config.toml" 2>/dev/null || \
    sed -i 's|^laddr = "tcp://.*:26656"|laddr = "tcp://0.0.0.0:26656"|' "$home/config/config.toml"
    sed -i '' 's|^laddr = "tcp://.*:26657"|laddr = "tcp://0.0.0.0:26657"|' "$home/config/config.toml" 2>/dev/null || \
    sed -i 's|^laddr = "tcp://.*:26657"|laddr = "tcp://0.0.0.0:26657"|' "$home/config/config.toml"
    echo "  ✅ $name configured"
done

# Distribute genesis
for home in "${VALIDATOR_HOMES[@]}"; do
    cp "$TEMPLATE_HOME/config/genesis.json" "$home/config/genesis.json" 2>/dev/null || true
done

# Validate
echo -e "\n--- Validate ---"
for home in "${VALIDATOR_HOMES[@]}"; do
    echo -n "  $(basename "$home"): "
    $BINARY validate-genesis --home "$home" 2>&1 | tail -1 || echo "(warning non-fatal)"
done

# Checksum
sha256sum "$TEMPLATE_HOME/config/genesis.json" | awk '{print $1}' > "$DOCKER_DIR/genesis-checksum.txt"

# P2P summary
cat > "$DOCKER_DIR/p2p-summary.txt" << EOF
Chain ID: $CHAIN_ID
Genesis checksum: $(cat $DOCKER_DIR/genesis-checksum.txt)
gen_txs: $N

Node IDs:
  val0: ${NODE_IDS[0]}
  val1: ${NODE_IDS[1]}
  val2: ${NODE_IDS[2]}

Persistent peers: $PEERS

Ports (host → container):
  val0 RPC: 26657 → 26657, REST: 1317, gRPC: 9090
  val1 RPC: 26667 → 26657, REST: 1318, gRPC: 9091
  val2 RPC: 26677 → 26657, REST: 1319, gRPC: 9092

Start:  ./scripts/testnet/run-docker-3-validator-rehearsal.sh
Query:  ./scripts/testnet/query-docker-3-validator-rehearsal.sh
Stop:   ./scripts/testnet/stop-docker-3-validator-rehearsal.sh
Logs:   ./scripts/testnet/logs-docker-3-validator-rehearsal.sh
EOF

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  ✅ Docker genesis prepared!            ║"
echo "║  gen_txs: $N                              ║"
echo "║  Run: scripts/testnet/run-docker-3-validator-rehearsal.sh ║"
echo "╚══════════════════════════════════════════╝"
