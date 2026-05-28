#!/usr/bin/env bash
# NexaRail multi-machine rehearsal evidence collector.
# TESTNET ONLY. Collects local node evidence without changing chain state.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
TIMESTAMP="${EVIDENCE_TIMESTAMP:-$(date -u +%Y%m%dT%H%M%SZ)}"
NODE_NAME="${NODE_NAME:-$(hostname -s 2>/dev/null || echo validator)}"
EVIDENCE_DIR="${EVIDENCE_DIR:-$PROJECT_DIR/rehearsals/testnet-1/multi-machine/evidence/$TIMESTAMP/$NODE_NAME}"
BINARY="${NEXARAIL_BINARY:-$PROJECT_DIR/build/nexaraild}"
HOME_DIR="${NEXARAIL_HOME:-$HOME/.nexarail}"
RPC_URL="${RPC_URL:-http://127.0.0.1:26657}"
API_URL="${API_URL:-http://127.0.0.1:1317}"
SERVICE_NAME="${NEXARAIL_SERVICE:-nexaraild}"
LOG_FILE="${NEXARAIL_LOG_FILE:-}"
mkdir -p "$EVIDENCE_DIR"

echo "=== NexaRail multi-machine evidence collector ==="
echo "Node:     $NODE_NAME"
echo "Evidence: $EVIDENCE_DIR"
echo "RPC:      $RPC_URL"
echo "API:      $API_URL"
echo ""

capture() {
    local label="$1"
    local outfile="$2"
    shift 2
    echo "--- $label ---"
    if "$@" > "$outfile" 2> "$outfile.err"; then
        rm -f "$outfile.err"
    else
        echo "collection failed: $label" >> "$outfile"
    fi
}

fetch_json() {
    local label="$1"
    local url="$2"
    local outfile="$3"
    echo "--- $label ---"
    if curl -fsS --max-time 10 "$url" > "$outfile.raw" 2> "$outfile.err"; then
        if command -v jq >/dev/null 2>&1; then
            jq '.' "$outfile.raw" > "$outfile" 2>/dev/null || cp "$outfile.raw" "$outfile"
        else
            cp "$outfile.raw" "$outfile"
        fi
        rm -f "$outfile.raw" "$outfile.err"
    else
        printf '{"error":"unreachable","url":"%s"}\n' "$url" > "$outfile"
    fi
}

sha256_file() {
    if [ ! -f "$1" ]; then
        echo "missing"
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

params_endpoint() {
    local module="$1"
    local outfile="$2"
    if curl -fsS --max-time 10 "$API_URL/nexarail/$module/v1/params" > "$outfile.raw" 2> "$outfile.err"; then
        :
    elif curl -fsS --max-time 10 "$API_URL/cosmos/$module/v1/params" > "$outfile.raw" 2> "$outfile.err"; then
        :
    else
        printf '{"error":"params unreachable","module":"%s"}\n' "$module" > "$outfile"
        return 0
    fi

    if command -v jq >/dev/null 2>&1; then
        jq '.' "$outfile.raw" > "$outfile" 2>/dev/null || cp "$outfile.raw" "$outfile"
    else
        cp "$outfile.raw" "$outfile"
    fi
    rm -f "$outfile.raw" "$outfile.err"
}

cat > "$EVIDENCE_DIR/run-context.txt" <<EOF
Timestamp UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Node name: $NODE_NAME
Project: $PROJECT_DIR
Binary: $BINARY
Home: $HOME_DIR
RPC: $RPC_URL
API: $API_URL
Evidence: $EVIDENCE_DIR
EOF

capture "uname" "$EVIDENCE_DIR/uname.txt" uname -a
if [ -f /etc/os-release ]; then cp /etc/os-release "$EVIDENCE_DIR/os-release.txt"; fi
capture "disk" "$EVIDENCE_DIR/disk.txt" df -h
capture "memory" "$EVIDENCE_DIR/memory.txt" sh -c 'free -h 2>/dev/null || vm_stat 2>/dev/null || true'
capture "time sync" "$EVIDENCE_DIR/timedatectl.txt" sh -c 'timedatectl status 2>/dev/null || date -u'
capture "processes" "$EVIDENCE_DIR/processes.txt" sh -c 'ps aux | grep "[n]exaraild" || true'

if [ -x "$BINARY" ]; then
    capture "binary version" "$EVIDENCE_DIR/nexaraild-version.txt" "$BINARY" version
    capture "node id" "$EVIDENCE_DIR/node-id.txt" "$BINARY" tendermint show-node-id --home "$HOME_DIR"
    capture "validator pubkey" "$EVIDENCE_DIR/validator-pubkey.json" "$BINARY" tendermint show-validator --home "$HOME_DIR"
else
    echo "binary not found or not executable: $BINARY" > "$EVIDENCE_DIR/nexaraild-version.txt"
fi

go version > "$EVIDENCE_DIR/go-version.txt" 2>/dev/null || echo "go not found" > "$EVIDENCE_DIR/go-version.txt"
git -C "$PROJECT_DIR" rev-parse HEAD > "$EVIDENCE_DIR/git-commit.txt" 2>/dev/null || echo "unknown" > "$EVIDENCE_DIR/git-commit.txt"
sha256_file "$HOME_DIR/config/genesis.json" > "$EVIDENCE_DIR/genesis-sha256.txt"

fetch_json "status" "$RPC_URL/status" "$EVIDENCE_DIR/status.json"
fetch_json "net info" "$RPC_URL/net_info" "$EVIDENCE_DIR/net_info.json"
fetch_json "validators" "$RPC_URL/validators" "$EVIDENCE_DIR/validators.json"

for module in fees merchant settlement escrow payout treasury; do
    params_endpoint "$module" "$EVIDENCE_DIR/${module}-params.json"
done

LIVE_FILE="$EVIDENCE_DIR/live-flags.txt"
: > "$LIVE_FILE"
if command -v jq >/dev/null 2>&1; then
    {
        printf 'settlement.live_enabled=%s\n' "$(jq -r '.params.live_enabled // "missing"' "$EVIDENCE_DIR/settlement-params.json" 2>/dev/null)"
        printf 'settlement.treasury_routing_enabled=%s\n' "$(jq -r '.params.treasury_routing_enabled // "missing"' "$EVIDENCE_DIR/settlement-params.json" 2>/dev/null)"
        printf 'settlement.burn_routing_enabled=%s\n' "$(jq -r '.params.burn_routing_enabled // "missing"' "$EVIDENCE_DIR/settlement-params.json" 2>/dev/null)"
        printf 'escrow.live_enabled=%s\n' "$(jq -r '.params.live_enabled // "missing"' "$EVIDENCE_DIR/escrow-params.json" 2>/dev/null)"
        printf 'payout.live_enabled=%s\n' "$(jq -r '.params.live_enabled // "missing"' "$EVIDENCE_DIR/payout-params.json" 2>/dev/null)"
        printf 'treasury.live_enabled=%s\n' "$(jq -r '.params.live_enabled // "missing"' "$EVIDENCE_DIR/treasury-params.json" 2>/dev/null)"
    } > "$LIVE_FILE"
else
    echo "jq missing; inspect module param JSON files manually" > "$LIVE_FILE"
fi

if command -v journalctl >/dev/null 2>&1; then
    journalctl -u "$SERVICE_NAME" -n 500 --no-pager > "$EVIDENCE_DIR/journalctl-${SERVICE_NAME}.log" 2>/dev/null || true
fi
if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
    tail -n 500 "$LOG_FILE" > "$EVIDENCE_DIR/node-tail.log" 2>/dev/null || true
fi
if [ -d "$HOME_DIR" ]; then
    find "$HOME_DIR" -maxdepth 3 \( -name "*.log" -o -name "config.toml" -o -name "app.toml" \) -print > "$EVIDENCE_DIR/home-files-index.txt" 2>/dev/null || true
fi

HEIGHT="unknown"
CHAIN="unknown"
PEERS="unknown"
VALS="unknown"
if command -v jq >/dev/null 2>&1; then
    HEIGHT="$(jq -r '.result.sync_info.latest_block_height // "unknown"' "$EVIDENCE_DIR/status.json" 2>/dev/null)"
    CHAIN="$(jq -r '.result.node_info.network // "unknown"' "$EVIDENCE_DIR/status.json" 2>/dev/null)"
    PEERS="$(jq -r '.result.n_peers // "unknown"' "$EVIDENCE_DIR/net_info.json" 2>/dev/null)"
    VALS="$(jq -r '.result.validators | length // "unknown"' "$EVIDENCE_DIR/validators.json" 2>/dev/null)"
fi

cat > "$EVIDENCE_DIR/SUMMARY.txt" <<EOF
NexaRail multi-machine node evidence
====================================
Timestamp UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Node: $NODE_NAME
Chain: $CHAIN
Height: $HEIGHT
Peers: $PEERS
Validators returned: $VALS
Genesis SHA256: $(cat "$EVIDENCE_DIR/genesis-sha256.txt")
Live flags:
$(cat "$LIVE_FILE")
EOF

echo ""
echo "Evidence collected at: $EVIDENCE_DIR"
cat "$EVIDENCE_DIR/SUMMARY.txt"
