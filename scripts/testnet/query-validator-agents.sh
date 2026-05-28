#!/usr/bin/env bash
# NexaRail — Query Validator Agents
# Captures live readback evidence from all validator agents.
# TESTNET/DEVNET ONLY.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
BINARY="$PROJECT_DIR/build/nexaraild"
AGENT_DIR="$PROJECT_DIR/rehearsals/validator-agents"
TIMESTAMP="${QUERY_TIMESTAMP:-$(date -u +%Y%m%dT%H%M%SZ)}"
EVIDENCE_DIR="${EVIDENCE_DIR:-$AGENT_DIR/query-readback/evidence/$TIMESTAMP}"
mkdir -p "$EVIDENCE_DIR"

AGENTS=(
    "alpha:27657:1417"
    "bravo:27667:1418"
    "charlie:27677:1419"
    "delta:27687:1420"
    "echo:27697:1421"
)
MODULES=(fees merchant settlement escrow payout treasury)
PASS=0
FAIL=0
SKIP=0

pass() { echo "    OK  $1"; PASS=$((PASS+1)); }
fail() { echo "    FAIL $1"; FAIL=$((FAIL+1)); }
skip() { echo "    SKIP $1"; SKIP=$((SKIP+1)); }

json_get() {
    local file="$1"
    local expr="$2"
    jq -r "$expr" "$file" 2>/dev/null || echo ""
}

query_cli() {
    local label="$1"
    local outfile="$2"
    shift 2
    if "$@" > "$outfile" 2> "$outfile.err"; then
        rm -f "$outfile.err"
        pass "$label"
        return 0
    fi
    fail "$label"
    return 1
}

query_rest_params() {
    local label="$1"
    local url="$2"
    local outfile="$3"
    curl -s --max-time 5 "$url" > "$outfile" 2> "$outfile.err" || true
    if jq -e '.params' "$outfile" > /dev/null 2>&1; then
        rm -f "$outfile.err"
        pass "$label"
        return 0
    fi
    fail "$label"
    return 1
}

assert_false() {
    local label="$1"
    local file="$2"
    local expr="$3"
    local val
    val="$(json_get "$file" "$expr")"
    if [ "$val" = "false" ] || [ "$val" = "False" ]; then
        echo "    OK  $label = false"
        PASS=$((PASS+1))
        return 0
    fi
    echo "    FAIL $label = ${val:-missing}"
    FAIL=$((FAIL+1))
    return 1
}

echo "╔══════════════════════════════════════════╗"
echo "║  NexaRail — Query Validator Agents      ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Evidence: $EVIDENCE_DIR"
echo ""

if [ ! -x "$BINARY" ]; then
    echo "❌ Binary not found or not executable: $BINARY"
    exit 1
fi

cat > "$EVIDENCE_DIR/run-context.txt" <<EOF
Timestamp UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Project: $PROJECT_DIR
Agent dir: $AGENT_DIR
Evidence dir: $EVIDENCE_DIR
EOF

for agent_def in "${AGENTS[@]}"; do
    IFS=':' read -r name rpc api <<< "$agent_def"
    home="$AGENT_DIR/$name"
    node="tcp://127.0.0.1:$rpc"

    echo "═══ Agent: $name (RPC :$rpc API :$api) ═══"

    STATUS_FILE="$EVIDENCE_DIR/${name}-status.json"
    if ! curl -s --max-time 5 "http://127.0.0.1:$rpc/status" > "$STATUS_FILE" 2> "$STATUS_FILE.err"; then
        fail "$name latest height query"
        echo ""
        continue
    fi
    rm -f "$STATUS_FILE.err"
    H="$(json_get "$STATUS_FILE" '.result.sync_info.latest_block_height // "0"')"
    C="$(json_get "$STATUS_FILE" '.result.node_info.network // ""')"
    CU="$(json_get "$STATUS_FILE" '.result.sync_info.catching_up // "true"')"
    echo "$H" > "$EVIDENCE_DIR/${name}-latest-height.txt"
    if [ "${H:-0}" -gt 0 ] 2>/dev/null; then
        pass "$name latest height query height=$H chain=$C catching_up=$CU"
    else
        fail "$name latest height query height=$H"
    fi

    NET_FILE="$EVIDENCE_DIR/${name}-net_info.json"
    curl -s --max-time 5 "http://127.0.0.1:$rpc/net_info" > "$NET_FILE" 2> "$NET_FILE.err" || true
    P="$(json_get "$NET_FILE" '.result.n_peers // "0"')"
    echo "    peers=$P"

    VAL_FILE="$EVIDENCE_DIR/${name}-validators.json"
    curl -s --max-time 5 "http://127.0.0.1:$rpc/validators" > "$VAL_FILE" 2> "$VAL_FILE.err" || true
    VC="$(json_get "$VAL_FILE" '.result.validators | length // 0')"
    if [ "$VC" = "5" ]; then
        pass "$name validator set count = 5"
    else
        fail "$name validator set count = ${VC:-missing}"
    fi

    ADDR_FILE="$EVIDENCE_DIR/${name}-address.txt"
    if "$BINARY" keys show "${name}-key" -a --keyring-backend test --home "$home" > "$ADDR_FILE" 2> "$ADDR_FILE.err"; then
        rm -f "$ADDR_FILE.err"
        addr="$(cat "$ADDR_FILE")"
        pass "$name key address resolved"
    else
        fail "$name key address resolved"
        echo ""
        continue
    fi

    echo "  --- SDK queries ---"
    query_cli "$name bank balances query" "$EVIDENCE_DIR/${name}-bank-balances.json" \
        "$BINARY" query bank balances "$addr" --node "$node" --output json || true

    if "$BINARY" query auth account "$addr" --node "$node" --output json > "$EVIDENCE_DIR/${name}-auth-account.json" 2> "$EVIDENCE_DIR/${name}-auth-account.json.err"; then
        rm -f "$EVIDENCE_DIR/${name}-auth-account.json.err"
        pass "$name auth account query"
    else
        skip "$name auth account query unsupported/unavailable"
    fi

    echo "  --- Custom module params ---"
    for mod in "${MODULES[@]}"; do
        query_rest_params "$name $mod params query" \
            "http://127.0.0.1:$api/nexarail/$mod/v1/params" \
            "$EVIDENCE_DIR/${name}-${mod}-params.json" || true
    done

    echo "  --- Live flags ---"
    LIVE_FILE="$EVIDENCE_DIR/${name}-live-flags.txt"
    : > "$LIVE_FILE"
    settlement_file="$EVIDENCE_DIR/${name}-settlement-params.json"
    escrow_file="$EVIDENCE_DIR/${name}-escrow-params.json"
    payout_file="$EVIDENCE_DIR/${name}-payout-params.json"
    treasury_file="$EVIDENCE_DIR/${name}-treasury-params.json"

    for item in \
        "settlement.live_enabled:$settlement_file:.params.live_enabled" \
        "settlement.treasury_routing_enabled:$settlement_file:.params.treasury_routing_enabled" \
        "settlement.burn_routing_enabled:$settlement_file:.params.burn_routing_enabled" \
        "escrow.live_enabled:$escrow_file:.params.live_enabled" \
        "payout.live_enabled:$payout_file:.params.live_enabled" \
        "treasury.live_enabled:$treasury_file:.params.live_enabled"; do
        IFS=':' read -r label file expr <<< "$item"
        val="$(json_get "$file" "$expr")"
        echo "$label=$val" >> "$LIVE_FILE"
        assert_false "$name $label" "$file" "$expr" || true
    done

    echo ""
done

cat > "$EVIDENCE_DIR/summary.txt" <<EOF
NexaRail validator agent query readback summary
Timestamp UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Evidence: $EVIDENCE_DIR
PASS: $PASS
FAIL: $FAIL
SKIP: $SKIP
EOF

echo "╔══════════════════════════════════════════╗"
echo "║  Query Complete                         ║"
echo "║  Evidence: $EVIDENCE_DIR"
printf "║  PASS: %-3d FAIL: %-3d SKIP: %-3d        ║\n" "$PASS" "$FAIL" "$SKIP"
echo "╚══════════════════════════════════════════╝"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
