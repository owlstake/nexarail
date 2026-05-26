#!/usr/bin/env bash
# NexaRail Testnet Gentx Collector
# Core team tool: validates and collects gentx files.
# TESTNET ONLY.
set -euo pipefail

BINARY="${NEXARAIL_BINARY:-./build/nexaraild}"
CHAIN_ID="${CHAIN_ID:-nexarail-testnet-1}"
GENTX_DIR="${1:-gentx-submissions}"
COLLECTED_DIR="gentx-collected"

if [ ! -d "$GENTX_DIR" ]; then
    echo "Gentx directory not found: $GENTX_DIR"
    echo "Usage: $0 <gentx-directory>"
    exit 1
fi

echo "=== NexaRail Gentx Collector ==="
echo "Chain ID: $CHAIN_ID"
echo "Source:   $GENTX_DIR"
echo ""

# Validate each gentx
VALID=0
INVALID=0
mkdir -p "$COLLECTED_DIR"

for f in "$GENTX_DIR"/*.json; do
    [ -f "$f" ] || continue
    echo -n "Validating: $(basename "$f") ... "
    if $BINARY gentx validate --gentx "$f" --chain-id "$CHAIN_ID" 2>/dev/null; then
        echo "✅ Valid"
        cp "$f" "$COLLECTED_DIR/"
        ((VALID++))
    else
        echo "❌ Invalid"
        ((INVALID++))
    fi
done

echo ""
echo "Results: $VALID valid, $INVALID invalid"
echo "Valid gentx files copied to: $COLLECTED_DIR"

if [ "$VALID" -gt 0 ]; then
    echo ""
    echo "To add valid gentx to genesis:"
    echo "  cp $COLLECTED_DIR/*.json ~/.nexarail/config/gentx/"
    echo "  $BINARY collect-gentx"
fi
