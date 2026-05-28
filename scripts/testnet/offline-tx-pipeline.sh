#!/usr/bin/env bash
# NexaRail — Offline Transaction Pipeline
#
# End-to-end offline transaction pipeline supporting multiple broadcast modes.
# Generates, signs, encodes, and broadcasts transactions.
#
# Usage:
#   offline-tx-pipeline.sh <command> [args]
#
# Commands:
#   bank-send <from> <to> <amount>  - Simple bank send
#   gov-proposal <proposal.json>     - Gov v1 proposal (nested Any)
#
# Options (bank-send):
#   --from-key KEY       Signing key name (default: bravo-key)
#   --home PATH          Keyring home (default: rehearsals/validator-agents/bravo)
#   --account-number N   Account number (default: 1)
#   --sequence N         Sequence number (default: 0)
#   --chain-id ID        Chain ID (default: nexarail-agent-testnet-1)
#   --fees AMOUNT        Fees (default: 2000unxrl)
#   --broadcast MODE     Broadcast mode: comet-json, comet-proto, grpc-proto (default: comet-proto)
#   --broadcast-mode ASYNC Broadcast sub-mode: sync, async, block (default: async)
#   --rpc-url URL        CometBFT RPC URL (default: http://127.0.0.1:27667)
#   --grpc-addr ADDR     gRPC address (default: 127.0.0.1:9191)
#   --output-dir PATH    Output directory for artefacts
#
# Broadcast modes:
#   comet-json   - CometBFT RPC with JSON body (amino encoded)
#   comet-proto  - CometBFT RPC with proto-encoded bytes
#   grpc-proto   - gRPC tx service with proto-encoded bytes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
BINARY="$PROJECT_DIR/build/nexaraild"

# Defaults
FROM_KEY="bravo-key"
HOME_DIR="$PROJECT_DIR/rehearsals/validator-agents/bravo"
ACCOUNT_NUMBER=1
SEQUENCE=0
CHAIN_ID="nexarail-agent-testnet-1"
FEES="2000unxrl"
BROADCAST_MODE="comet-proto"
BCAST_SUB_MODE="async"
RPC_URL="http://127.0.0.1:27667"
GRPC_ADDR="127.0.0.1:9191"
OUTPUT_DIR=""
GOV_PROPOSAL=""

usage() {
    cat <<EOF
Usage: $(basename "$0") <command> [options]

Commands:
  bank-send <to_address> <amount>
      Simple bank send transaction.
      Example: $(basename "$0") bank-send nxr1... 1000unxrl

  gov-proposal <proposal.json>
      Submit a gov v1 proposal (nested Any messages).
      Example: $(basename "$0") gov-proposal enable-live.json

Options:
  --from-key KEY         Signing key (default: bravo-key)
  --home PATH            Keyring home (default: rehearsals/validator-agents/bravo)
  --account-number N     Account number (default: 1)
  --sequence N           Sequence number (default: 0)
  --chain-id ID          Chain ID (default: nexarail-agent-testnet-1)
  --fees AMOUNT          Fees (default: 2000unxrl)
  --broadcast MODE       Broadcast: comet-json, comet-proto, grpc-proto
  --broadcast-mode MODE  Sub-mode: sync, async, block
  --rpc-url URL          CometBFT RPC URL
  --grpc-addr ADDR       gRPC address
  --output-dir PATH      Output directory for artefacts
  --help                 Show this help
EOF
    exit 1
}

# Parse command
COMMAND=""
if [[ $# -gt 0 ]]; then
    case "$1" in
        bank-send) COMMAND="bank-send"; shift ;;
        gov-proposal) COMMAND="gov-proposal"; shift ;;
        --help|-h) usage ;;
        *) echo "Unknown command: $1"; usage ;;
    esac
fi

if [ -z "$COMMAND" ]; then
    usage
fi

# Command-specific args
TO_ADDR=""
AMOUNT=""
if [ "$COMMAND" = "bank-send" ]; then
    TO_ADDR="${1:-}"
    AMOUNT="${2:-}"
    shift 2 2>/dev/null || true
    if [ -z "$TO_ADDR" ] || [ -z "$AMOUNT" ]; then
        echo "Error: bank-send requires <to_address> <amount>"
        usage
    fi
elif [ "$COMMAND" = "gov-proposal" ]; then
    GOV_PROPOSAL="${1:-}"
    shift 2>/dev/null || true
    if [ -z "$GOV_PROPOSAL" ] || [ ! -f "$GOV_PROPOSAL" ]; then
        echo "Error: gov-proposal requires a valid proposal JSON file"
        usage
    fi
    FEES="10000unxrl"
fi

# Parse remaining options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --from-key) FROM_KEY="$2"; shift 2 ;;
        --home) HOME_DIR="$2"; shift 2 ;;
        --account-number) ACCOUNT_NUMBER="$2"; shift 2 ;;
        --sequence) SEQUENCE="$2"; shift 2 ;;
        --chain-id) CHAIN_ID="$2"; shift 2 ;;
        --fees) FEES="$2"; shift 2 ;;
        --broadcast) BROADCAST_MODE="$2"; shift 2 ;;
        --broadcast-mode) BCAST_SUB_MODE="$2"; shift 2 ;;
        --rpc-url) RPC_URL="$2"; shift 2 ;;
        --grpc-addr) GRPC_ADDR="$2"; shift 2 ;;
        --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
        --help|-h) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

# Validate broadcast mode
case "$BROADCAST_MODE" in
    comet-json|comet-proto|grpc-proto) ;;
    *) echo "Error: invalid broadcast mode '$BROADCAST_MODE'"; exit 1 ;;
esac

# Set up output directory
if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR="$PROJECT_DIR/rehearsals/validator-agents/tx-service/evidence/$(date +%Y%m%d_%H%M%S)"
fi
mkdir -p "$OUTPUT_DIR"

if [ ! -f "$BINARY" ]; then
    echo "Error: nexaraild binary not found at $BINARY"
    exit 2
fi

echo "╔══════════════════════════════════════════════╗"
echo "║  NexaRail — Offline Transaction Pipeline    ║"
echo "║  Command: $COMMAND"
echo "║  Broadcast: $BROADCAST_MODE ($BCAST_SUB_MODE)"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "Output dir: $OUTPUT_DIR"
echo ""

# ---------------------------------------------------------------------------
# Step 1: Generate unsigned transaction
# ---------------------------------------------------------------------------

echo "--- Step 1: Generate unsigned transaction ---"

UNSIGNED="$OUTPUT_DIR/unsigned.json"

if [ "$COMMAND" = "bank-send" ]; then
    "$BINARY" tx send "$FROM_KEY" "$TO_ADDR" "$AMOUNT" \
        --from "$FROM_KEY" --keyring-backend test --home "$HOME_DIR" \
        --chain-id "$CHAIN_ID" --node tcp://127.0.0.1:27667 \
        --generate-only --fees "$FEES" \
        > "$UNSIGNED" 2>&1
else
    "$BINARY" tx gov submit-proposal "$GOV_PROPOSAL" \
        --from "$FROM_KEY" --keyring-backend test --home "$HOME_DIR" \
        --chain-id "$CHAIN_ID" --node tcp://127.0.0.1:27667 \
        --generate-only --fees "$FEES" \
        > "$UNSIGNED" 2>&1
fi

UNSIGNED_LEN=$(wc -c < "$UNSIGNED" | tr -d ' ')
echo "  Generated: $UNSIGNED_LEN bytes → $UNSIGNED"

# ---------------------------------------------------------------------------
# Step 2: Sign offline
# ---------------------------------------------------------------------------

echo "--- Step 2: Sign offline ---"

SIGNED="$OUTPUT_DIR/signed.json"

"$BINARY" tx sign "$UNSIGNED" \
    --offline --account-number "$ACCOUNT_NUMBER" --sequence "$SEQUENCE" \
    --from "$FROM_KEY" --keyring-backend test --home "$HOME_DIR" \
    --chain-id "$CHAIN_ID" \
    > "$SIGNED" 2>&1

SIGNED_LEN=$(wc -c < "$SIGNED" | tr -d ' ')
echo "  Signed: $SIGNED_LEN bytes → $SIGNED"

# ---------------------------------------------------------------------------
# Step 3: Encode to proto
# ---------------------------------------------------------------------------

echo "--- Step 3: Encode to proto bytes ---"

ENCODED="$OUTPUT_DIR/signed.b64"

"$BINARY" tx encode "$SIGNED" > "$ENCODED" 2>&1

ENCODED_B64=$(cat "$ENCODED" | tr -d '\n')
ENCODED_LEN=${#ENCODED_B64}
echo "  Encoded: $ENCODED_LEN base64 chars → $ENCODED"

# Also generate hex version for CometBFT hex param
echo "$ENCODED_B64" | base64 -d 2>/dev/null | xxd -p | tr -d '\n' > "$OUTPUT_DIR/signed.hex"
echo "  Hex: $(wc -c < "$OUTPUT_DIR/signed.hex" | tr -d ' ') chars → $OUTPUT_DIR/signed.hex"

# ---------------------------------------------------------------------------
# Step 4: Broadcast
# ---------------------------------------------------------------------------

echo "--- Step 4: Broadcast ($BROADCAST_MODE) ---"

BROADCAST_RESULT="$OUTPUT_DIR/broadcast-result.json"
TX_HASH=""

case "$BROADCAST_MODE" in
    comet-json)
        # Use nexaraild tx broadcast (amino/JSON codec)
        echo "  Warning: comet-json mode may fail for nested Any messages" >&2
        "$BINARY" tx broadcast "$SIGNED" \
            --node "$RPC_URL" --chain-id "$CHAIN_ID" \
            --from "$FROM_KEY" --keyring-backend test --home "$HOME_DIR" \
            > "$BROADCAST_RESULT" 2>&1 || true
        
        TX_HASH=$(grep -o 'txhash: .*' "$BROADCAST_RESULT" 2>/dev/null | awk '{print $2}' || echo "UNKNOWN")
        ;;

    comet-proto)
        # Use CometBFT RPC with proto-encoded base64 bytes
        case "$BCAST_SUB_MODE" in
            sync)  RPC_METHOD="broadcast_tx_sync" ;;
            async) RPC_METHOD="broadcast_tx_async" ;;
            block) RPC_METHOD="broadcast_tx_commit" ;;
        esac

        curl -s --max-time 15 "$RPC_URL/" \
            -H "Content-Type: application/json" \
            -d "{\"jsonrpc\":\"2.0\",\"method\":\"${RPC_METHOD}\",\"params\":{\"tx\":\"${ENCODED_B64}\"},\"id\":1}" \
            > "$BROADCAST_RESULT" 2>&1

        TX_HASH=$(python3 -c "
import json,sys
try:
    d = json.load(sys.stdin)
    print(d.get('result',{}).get('hash','UNKNOWN'))
except:
    print('UNKNOWN')
" < "$BROADCAST_RESULT" 2>/dev/null)
        ;;

    grpc-proto)
        # Use gRPC tx service
        if ! command -v grpcurl &>/dev/null; then
            echo "  Error: grpcurl not available. Install: brew install grpcurl"
            exit 4
        fi

        case "$BCAST_SUB_MODE" in
            sync)  GRPC_MODE="BROADCAST_MODE_SYNC" ;;
            async) GRPC_MODE="BROADCAST_MODE_ASYNC" ;;
            block) GRPC_MODE="BROADCAST_MODE_BLOCK" ;;
        esac

        grpcurl -plaintext -max-time 15 \
            -d "{\"tx_bytes\":\"${ENCODED_B64}\",\"mode\":\"${GRPC_MODE}\"}" \
            "$GRPC_ADDR" cosmos.tx.v1beta1.Service/BroadcastTx \
            > "$BROADCAST_RESULT" 2>&1 || true

        TX_HASH=$(python3 -c "
import json,sys
try:
    d = json.load(sys.stdin)
    print(d.get('tx_response',{}).get('txhash','UNKNOWN'))
except:
    print('UNKNOWN')
" < "$BROADCAST_RESULT" 2>/dev/null)
        ;;
esac

echo "  Result: $BROADCAST_RESULT"
echo "  Tx Hash: $TX_HASH"

# ---------------------------------------------------------------------------
# Step 5: Summary
# ---------------------------------------------------------------------------

echo ""
echo "╔══════════════════════════════════════════════╗"
printf "║  Tx Hash: %-34s ║\n" "${TX_HASH:0:34}"
printf "║  Command: %-34s ║\n" "$COMMAND"
printf "║  Broadcast: %-31s ║\n" "$BROADCAST_MODE/$BCAST_SUB_MODE"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "Artefacts saved to: $OUTPUT_DIR"
echo "  unsigned.json     - Unsigned transaction"
echo "  signed.json       - Signed transaction"
echo "  signed.b64        - Proto-encoded base64"
echo "  signed.hex        - Proto-encoded hex"
echo "  broadcast-result.json - Broadcast response"

if [ "$TX_HASH" = "UNKNOWN" ] || [ -z "$TX_HASH" ]; then
    exit 3
fi

exit 0
