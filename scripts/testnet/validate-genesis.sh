#!/usr/bin/env bash
# NexaRail Genesis Validator
# Verifies genesis.json chain ID, checksum, and module state.
set -euo pipefail

BINARY="${NEXARAIL_BINARY:-./build/nexaraild}"
CHAIN_ID="${CHAIN_ID:-nexarail-testnet-1}"
EXPECTED_CHECKSUM="${EXPECTED_CHECKSUM:-}"

echo "=== NexaRail Genesis Validator ==="

# Basic validation
echo "--- Running validate-genesis ---"
$BINARY validate-genesis

# Check chain ID
GENESIS_CHAIN=$($BINARY --home ~/.nexarail 2>/dev/null || echo "")
if grep -q "\"chain_id\":\"$CHAIN_ID\"" ~/.nexarail/config/genesis.json; then
    echo "✅ Chain ID matches: $CHAIN_ID"
else
    echo "❌ Chain ID mismatch in genesis.json"
    grep '"chain_id"' ~/.nexarail/config/genesis.json
    exit 1
fi

# Checksum
ACTUAL_CHECKSUM=$(sha256sum ~/.nexarail/config/genesis.json | awk '{print $1}')
echo "Genesis checksum: $ACTUAL_CHECKSUM"

if [ -n "$EXPECTED_CHECKSUM" ]; then
    if [ "$ACTUAL_CHECKSUM" = "$EXPECTED_CHECKSUM" ]; then
        echo "✅ Checksum matches expected: $EXPECTED_CHECKSUM"
    else
        echo "❌ Checksum mismatch! Expected: $EXPECTED_CHECKSUM"
        exit 1
    fi
else
    echo "⚠️  No expected checksum provided. Verify manually with published value."
fi

echo ""
echo "✅ Genesis validation complete."
