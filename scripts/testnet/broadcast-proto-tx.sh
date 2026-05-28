#!/usr/bin/env bash
# NexaRail — Proto Transaction Broadcast Helper
#
# Encodes a signed transaction JSON to proto bytes and broadcasts via
# CometBFT RPC or gRPC tx service.
#
# Usage:
#   broadcast-proto-tx.sh <signed-tx.json> [--mode sync|async|block] [--endpoint comet|grpc] [--rpc-url URL] [--grpc-addr ADDR]
#
# Arguments:
#   signed-tx.json     Path to signed transaction JSON file
#   --mode             Broadcast mode: sync, async, block (default: async)
#   --endpoint         Broadcast endpoint: comet (CometBFT RPC) or grpc (gRPC tx service)
#   --rpc-url          CometBFT RPC URL (default: http://127.0.0.1:27667)
#   --grpc-addr        gRPC address (default: 127.0.0.1:9191)
#   --output           Output path for broadcast response (default: stdout)
#
# Exit codes:
#   0 - Success
#   1 - Usage error
#   2 - Encode failure
#   3 - Broadcast failure
#   4 - gRPC not available

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
BINARY="$PROJECT_DIR/build/nexaraild"

# Defaults
MODE="async"
ENDPOINT="comet"
RPC_URL="http://127.0.0.1:27667"
GRPC_ADDR="127.0.0.1:9191"
OUTPUT=""

usage() {
    cat <<EOF
Usage: $(basename "$0") <signed-tx.json> [options]

Options:
  --mode MODE        Broadcast mode: sync, async, block (default: async)
  --endpoint TYPE    Broadcast endpoint: comet (CometBFT RPC) or grpc (gRPC)
  --rpc-url URL      CometBFT RPC URL (default: http://127.0.0.1:27667)
  --grpc-addr ADDR   gRPC address (default: 127.0.0.1:9191)
  --output PATH      Save broadcast response to file (default: stdout)
  --help             Show this help

Examples:
  $(basename "$0") signed.json
  $(basename "$0") signed.json --mode sync --endpoint grpc
  $(basename "$0") signed.json --mode block --rpc-url http://127.0.0.1:27667
EOF
    exit 1
}

# Parse args
SIGNED_TX=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode) MODE="$2"; shift 2 ;;
        --endpoint) ENDPOINT="$2"; shift 2 ;;
        --rpc-url) RPC_URL="$2"; shift 2 ;;
        --grpc-addr) GRPC_ADDR="$2"; shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        --help|-h) usage ;;
        -* ) echo "Unknown option: $1"; usage ;;
        *) SIGNED_TX="$1"; shift ;;
    esac
done

if [ -z "$SIGNED_TX" ] || [ ! -f "$SIGNED_TX" ]; then
    echo "Error: signed transaction JSON file required"
    usage
fi

if [ ! -f "$BINARY" ]; then
    echo "Error: nexaraild binary not found at $BINARY"
    echo "Run: make build"
    exit 2
fi

# Validate mode
case "$MODE" in
    sync|async|block) ;;
    *) echo "Error: invalid mode '$MODE'. Use sync, async, or block"; exit 1 ;;
esac

# Validate endpoint
case "$ENDPOINT" in
    comet|grpc) ;;
    *) echo "Error: invalid endpoint '$ENDPOINT'. Use comet or grpc"; exit 1 ;;
esac

# ---------------------------------------------------------------------------
# Step 1: Encode to proto bytes
# ---------------------------------------------------------------------------

echo "--- Encoding signed transaction ---" >&2
ENCODED_B64=$("$BINARY" tx encode "$SIGNED_TX" 2>/dev/null | tr -d '\n')

if [ -z "$ENCODED_B64" ]; then
    echo "Error: tx encode produced empty output" >&2
    exit 2
fi

echo "  Encoded: ${#ENCODED_B64} base64 chars" >&2

# ---------------------------------------------------------------------------
# Step 2: Broadcast
# ---------------------------------------------------------------------------

BROADCAST_RESULT=""
TX_HASH=""

if [ "$ENDPOINT" = "grpc" ]; then
    # --- gRPC path ---
    if ! command -v grpcurl &>/dev/null; then
        echo "Error: grpcurl not found. Install: brew install grpcurl" >&2
        exit 4
    fi

    # Map mode to gRPC broadcast mode enum
    case "$MODE" in
        sync)  GRPC_MODE="BROADCAST_MODE_SYNC" ;;
        async) GRPC_MODE="BROADCAST_MODE_ASYNC" ;;
        block) GRPC_MODE="BROADCAST_MODE_BLOCK" ;;
    esac

    echo "--- Broadcasting via gRPC ($MODE) ---" >&2

    GRPC_RESPONSE=$(grpcurl -plaintext -max-time 15 \
        -d "{\"tx_bytes\":\"${ENCODED_B64}\",\"mode\":\"${GRPC_MODE}\"}" \
        "$GRPC_ADDR" cosmos.tx.v1beta1.Service/BroadcastTx 2>&1) || {
        echo "Error: gRPC broadcast failed" >&2
        echo "$GRPC_RESPONSE" >&2
        exit 3
    }

    BROADCAST_RESULT="$GRPC_RESPONSE"

    # Extract tx hash from gRPC response (JSON)
    TX_HASH=$(echo "$GRPC_RESPONSE" | python3 -c "
import json,sys
try:
    d = json.load(sys.stdin)
    print(d.get('tx_response',{}).get('txhash','UNKNOWN'))
except:
    print('UNKNOWN')
" 2>/dev/null || echo "UNKNOWN")

else
    # --- CometBFT RPC path ---
    case "$MODE" in
        sync)  RPC_METHOD="broadcast_tx_sync" ;;
        async) RPC_METHOD="broadcast_tx_async" ;;
        block) RPC_METHOD="broadcast_tx_commit" ;;
    esac

    echo "--- Broadcasting via CometBFT RPC ($MODE) ---" >&2

    RPC_RESPONSE=$(curl -s --max-time 15 "$RPC_URL/" \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"method\":\"${RPC_METHOD}\",\"params\":{\"tx\":\"${ENCODED_B64}\"},\"id\":1}" 2>&1)

    if [ -z "$RPC_RESPONSE" ]; then
        echo "Error: CometBFT RPC returned empty response" >&2
        exit 3
    fi

    BROADCAST_RESULT="$RPC_RESPONSE"

    # Extract tx hash
    TX_HASH=$(echo "$RPC_RESPONSE" | python3 -c "
import json,sys
try:
    d = json.load(sys.stdin)
    result = d.get('result', {})
    print(result.get('hash', 'UNKNOWN'))
except:
    print('UNKNOWN')
" 2>/dev/null || echo "UNKNOWN")

    # Check for RPC error
    RPC_ERROR=$(echo "$RPC_RESPONSE" | python3 -c "
import json,sys
try:
    d = json.load(sys.stdin)
    err = d.get('error', {})
    if err:
        print(err.get('message','UNKNOWN'))
    else:
        print('')
except:
    print('')
" 2>/dev/null)

    if [ -n "$RPC_ERROR" ]; then
        echo "Error: RPC error - $RPC_ERROR" >&2
    fi
fi

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

if [ -n "$OUTPUT" ]; then
    echo "$BROADCAST_RESULT" > "$OUTPUT"
    echo "  Response saved to: $OUTPUT" >&2
fi

echo ""
echo "═══════════════════════════════════════"
echo "  Tx Hash: $TX_HASH"
echo "  Mode:    $MODE"
echo "  Endpoint: $ENDPOINT"
echo "═══════════════════════════════════════"

# Output the response to stdout
echo "$BROADCAST_RESULT"

# Exit based on tx hash
if [ "$TX_HASH" = "UNKNOWN" ] || [ -z "$TX_HASH" ]; then
    exit 3
fi

exit 0
