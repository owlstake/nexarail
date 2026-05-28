#!/usr/bin/env bash
# NexaRail — Query RC1 Devnet
#
# Queries a running RC1 devnet for status, node_info, validator_set,
# bank balances, custom module params, and live flags.
#
# Defaults: single-node at :26657 / :1317. Use --rpc/--rest to change.
# For five-agent: query alpha at --rpc http://127.0.0.1:27657
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RELEASE_DIR="$PROJECT_DIR/releases/testnet-rc1"

OS="$(uname -s)"
case "$OS" in
    Darwin) BINARY="$RELEASE_DIR/binaries/nexaraild-darwin-arm64" ;;
    Linux)  BINARY="$RELEASE_DIR/binaries/nexaraild-linux-amd64"  ;;
    *)      echo "Unsupported OS: $OS"; exit 1 ;;
esac

RPC="http://127.0.0.1:26657"
REST="http://127.0.0.1:1317"
CHAIN_ID="nexarail-devnet-1"
HOME_DIR="$HOME/.nexarail-devnet"

usage() {
    cat <<EOF
Usage: scripts/release/query-rc1-devnet.sh [OPTIONS]

Options:
  --rpc <url>       Override RPC endpoint (default: http://127.0.0.1:26657)
  --rest <url>      Override REST endpoint (default: http://127.0.0.1:1317)
  --binary <path>   Override nexaraild binary path
  --home <path>     Override home directory (default: ~/.nexarail-devnet)
  -h|--help         Show this help
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --rpc)    RPC="${2:-}"; shift 2 ;;
        --rest)   REST="${2:-}"; shift 2 ;;
        --binary) BINARY="${2:-}"; shift 2 ;;
        --home)   HOME_DIR="${2:-}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *)        echo "Unknown: $1"; usage; exit 1 ;;
    esac
done

PASS="✅ "
FAIL="❌ "
INFO="ℹ️  "
RESET=""

passed=0
failed=0

echo "╔══════════════════════════════════════════════╗"
echo "║  NexaRail — RC1 Devnet Query               ║"
echo "║  RPC: $RPC"
echo "║  REST: $REST"
echo "║  Chain: $CHAIN_ID          ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── 1. Status ───────────────────────────────────────────
echo "── [1] Status ─────────────────────────────────────"
STATUS=$(curl -s --max-time 5 "$RPC/status" 2>/dev/null || echo '{"error":"connection failed"}')
echo "$STATUS" | jq '.' 2>/dev/null || echo "  ${FAIL}Failed to query status${RESET}"
if echo "$STATUS" | jq -e '.result.node_info.network' >/dev/null 2>&1; then
    passed=$((passed + 1))
else
    echo "  ${FAIL}Status query returned no network info${RESET}"
    failed=$((failed + 1))
fi
echo ""

# ── 2. Node info ────────────────────────────────────────
echo "── [2] Node Info ─────────────────────────────────"
NODE_INFO=$(curl -s --max-time 5 "$RPC/status" 2>/dev/null | jq '.result.node_info' 2>/dev/null || echo '{}')
echo "$NODE_INFO" | jq '.' 2>/dev/null || echo "  ${FAIL}Failed to get node info${RESET}"
echo ""

# ── 3. Validator set ────────────────────────────────────
echo "── [3] Validator Set ──────────────────────────────"
VAL_SET=$(curl -s --max-time 5 "$RPC/validators" 2>/dev/null || echo '{}')
echo "$VAL_SET" | jq '.' 2>/dev/null || echo "  ${FAIL}Failed to get validator set${RESET}"
VAL_COUNT=$(echo "$VAL_SET" | jq -r '.result.validators | length // 0' 2>/dev/null || echo "0")
echo "  Validator count: $VAL_COUNT"
if [ "$VAL_COUNT" -gt 0 ]; then
    passed=$((passed + 1))
else
    echo "  ${FAIL}No validators found${RESET}"
    failed=$((failed + 1))
fi
echo ""

# ── 4. Bank balances ────────────────────────────────────
echo "── [4] Bank Balances ──────────────────────────────"
if [ -f "$BINARY" ]; then
    KEY_ADDR=$("$BINARY" keys show devnet-key -a --keyring-backend test --home "$HOME_DIR" 2>/dev/null || echo "")
    if [ -n "$KEY_ADDR" ]; then
        echo "  devnet-key address: $KEY_ADDR"
        BAL="$("$BINARY" query bank balances "$KEY_ADDR" --node "$RPC" --output json 2>/dev/null || echo '{}')"
        echo "$BAL" | jq '.' 2>/dev/null || echo "  ${FAIL}Failed to query balance${RESET}"
        passed=$((passed + 1))
    else
        echo "  ${FAIL}devnet-key not found at $HOME_DIR${RESET}"
        echo "  (Running five-agent? Use --home to point to an agent home dir)"
        failed=$((failed + 1))
    fi
else
    echo "  ${FAIL}Binary not found: $BINARY${RESET}"
    failed=$((failed + 1))
fi
echo ""

# ── 5. Custom module params via REST ────────────────────
echo "── [5] Custom Module Params (REST) ────────────────"
REST_ENDPOINTS=(
    "/cosmos/staking/v1beta1/params"
    "/cosmos/slashing/v1beta1/params"
    "/cosmos/gov/v1beta1/params"
    "/cosmos/mint/v1beta1/params"
    "/cosmos/distribution/v1beta1/params"
    "/cosmos/bank/v1beta1/params"
)

for ep in "${REST_ENDPOINTS[@]}"; do
    RESULT=$(curl -s --max-time 5 "$REST$ep" 2>/dev/null || echo '{"error":"connection failed"}')
    echo "  [$ep]"
    echo "$RESULT" | jq '.' 2>/dev/null || echo "    (no response)"
    echo ""
done
passed=$((passed + 1))

# ── 6. Live flags via REST (app version endpoint) ───────
echo "── [6] Live Flags ──────────────────────────────────"
# Try various endpoints that might expose module flags/params
LIVE_FLAGS_RESULT=$(curl -s --max-time 5 "$REST/cosmos/base/tendermint/v1beta1/node_info" 2>/dev/null || echo '{}')
echo "$LIVE_FLAGS_RESULT" | jq '.' 2>/dev/null || echo "  (no response)"
echo ""

# Try to get AppVersion / node config details
APP_VERSION=$(curl -s --max-time 5 "$REST/cosmos/base/tendermint/v1beta1/node_info" 2>/dev/null | jq '.application_version // empty' 2>/dev/null || echo "")
if [ -n "$APP_VERSION" ]; then
    echo "$APP_VERSION" | jq '.' 2>/dev/null
else
    echo "  (no application version info available via REST)"
fi
echo ""

# ── 7. Governance proposals ─────────────────────────────
echo "── [7] Governance Proposals ────────────────────────"
PROPOSALS=$(curl -s --max-time 5 "$REST/cosmos/gov/v1beta1/proposals" 2>/dev/null || echo '{}')
echo "$PROPOSALS" | jq '.' 2>/dev/null || echo "  (no proposals)"
echo ""

# ── 8. Consensus params ────────────────────────────────
echo "── [8] Consensus Params ────────────────────────────"
CONSENSUS=$(curl -s --max-time 5 "$REST/cosmos/base/tendermint/v1beta1/consensus_params" 2>/dev/null || echo '{}')
echo "$CONSENSUS" | jq '.' 2>/dev/null || echo "  (no response)"
echo ""

# ── 9. Supply ──────────────────────────────────────────
echo "── [9] Total Supply ────────────────────────────────"
SUPPLY=$(curl -s --max-time 5 "$REST/cosmos/bank/v1beta1/supply" 2>/dev/null || echo '{}')
echo "$SUPPLY" | jq '.supply // []' 2>/dev/null || echo "  (no response)"
echo ""

# ── 10. NexaRail custom module queries (if available) ──
echo "── [10] Custom NexaRail Modules (attempted) ─────────"
CUSTOM_ENDPOINTS=(
    "/nexarail/params"
    "/nexarail"
)
for ep in "${CUSTOM_ENDPOINTS[@]}"; do
    RESULT=$(curl -s --max-time 5 "$REST$ep" 2>/dev/null || echo '{"error":"not found"}')
    echo "  [$ep]"
    echo "$RESULT" | jq '.' 2>/dev/null || echo "    (no response or endpoint does not exist)"
    echo ""
done

# ── Summary ─────────────────────────────────────────────
echo "══════════════════════════════════════════════════════"
echo "  Query Complete"
echo "  Passed: $passed    Failed: $failed"
echo "══════════════════════════════════════════════════════"
echo ""

if [ "$failed" -gt 0 ]; then
    echo "${FAIL}RC1 devnet query completed with $failed failure(s).${RESET}"
else
    echo "${PASS}RC1 devnet query PASSED.${RESET}"
fi

exit "$failed"
