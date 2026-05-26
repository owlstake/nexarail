#!/usr/bin/env bash
# NexaRail Testnet Validator Initialiser
# TESTNET ONLY — do not run against mainnet.
# Prepares a fresh node for nexarail-testnet-1.
set -euo pipefail

BINARY="${NEXARAIL_BINARY:-./build/nexaraild}"
CHAIN_ID="${NEXARAIL_CHAIN_ID:-nexarail-testnet-1}"
MONIKER="${NEXARAIL_MONIKER:-nexarail-validator}"
GENESIS_URL="${GENESIS_URL:-}"
KEYRING="${NEXARAIL_KEYRING:-file}"

echo "=== NexaRail Testnet Validator Init ==="
echo "Chain ID: $CHAIN_ID"
echo "Moniker:  $MONIKER"
echo ""

if [ ! -f "$BINARY" ]; then
    echo "Binary not found: $BINARY"
    echo "Build with: make build"
    exit 1
fi

# Initialise node
echo "--- Initialising node ---"
$BINARY init "$MONIKER" --chain-id "$CHAIN_ID"

# Download genesis
if [ -n "$GENESIS_URL" ]; then
    echo "--- Downloading genesis from $GENESIS_URL ---"
    curl -sSL "$GENESIS_URL" -o ~/.nexarail/config/genesis.json
else
    echo "⚠️  No GENESIS_URL set. Place genesis.json at ~/.nexarail/config/genesis.json manually."
fi

# Verify genesis
echo "--- Validating genesis ---"
$BINARY validate-genesis

echo ""
echo "✅ Validator node initialised."
echo ""
echo "Next steps:"
echo "  1. Create a key:  $BINARY keys add <keyname> --keyring-backend $KEYRING"
echo "  2. Get tokens:    Use testnet faucet (see docs/testnet/FAUCET_PLAN.md)"
echo "  3. Create validator: See docs/testnet/VALIDATOR_ONBOARDING.md"
echo "  4. Start node:    $BINARY start"
