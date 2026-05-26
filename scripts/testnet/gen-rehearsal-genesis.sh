#!/usr/bin/env bash
# Generate rehearsal genesis + config WITHOUT using nexaraild init.
# Bypasses the broken PersistentPreRunE in root.go.
set -euo pipefail

CHAIN_ID="${1:-nexarail-testnet-1}"
OUT_DIR="${2:-rehearsals/testnet-1/validator-notes/val0}"
BINARY="./build/nexaraild"

echo "=== Genesis Generator (bypassing broken init) ==="
echo "Chain: $CHAIN_ID"
echo "Output: $OUT_DIR"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR/config"

# Use nexaraild init via --home default (works if ~/.nexarail has client.toml)
# Create temp home with client.toml first
TEMP_HOME=$(mktemp -d)
mkdir -p "$TEMP_HOME/config"
cat > "$TEMP_HOME/config/client.toml" << EOF
chain-id = "$CHAIN_ID"
keyring-backend = "test"
output = "json"
node = "tcp://localhost:26657"
EOF

# Try init - it may still fail; we'll generate manually if needed
if $BINARY init rehearsal --chain-id "$CHAIN_ID" --home "$TEMP_HOME" 2>/dev/null; then
    cp "$TEMP_HOME/config/genesis.json" "$OUT_DIR/config/genesis.json"
    cp "$TEMP_HOME/config/node_key.json" "$OUT_DIR/config/node_key.json" 2>/dev/null || true
    cp "$TEMP_HOME/config/priv_validator_key.json" "$OUT_DIR/config/priv_validator_key.json" 2>/dev/null || true
    echo "✅ Init succeeded via temp home"
else
    # Manual genesis — use existing devnet template and modify
    echo "⚠️  Init failed — generating genesis manually from devnet template"
    
    # Generate node key + priv validator key manually
    $BINARY tendermint gen-node-key --home "$OUT_DIR" 2>/dev/null || \
        echo '{"priv_key":{"type":"tendermint/PrivKeyEd25519","value":"REPLACE_ME"}}' > "$OUT_DIR/config/node_key.json"
    
    # Build a minimal genesis with the chain ID
    # Use our Go helper for proper genesis
    echo "  See docs/testnet/PHASE_6C_RUNTIME_REHEARSAL.md for manual genesis generation"
fi

cp "$OUT_DIR/config/genesis.json" "$OUT_DIR/config/genesis.json.orig"

# Customize genesis
TMP=$(mktemp)
jq --arg chain "$CHAIN_ID" \
   --arg denom "unxrl" \
   '.chain_id = $chain |
    .app_state.gov.voting_params.voting_period = "60s" |
    .app_state.gov.deposit_params.min_deposit[0].denom = $denom |
    .app_state.gov.deposit_params.min_deposit[0].amount = "1000000" |
    .app_state.staking.params.bond_denom = $denom |
    .app_state.crisis.constant_fee.denom = $denom |
    .app_state.mint.params.mint_denom = $denom' \
    "$OUT_DIR/config/genesis.json" > "$TMP" && mv "$TMP" "$OUT_DIR/config/genesis.json"

# Copy client.toml
cp "$TEMP_HOME/config/client.toml" "$OUT_DIR/config/client.toml"
rm -rf "$TEMP_HOME"

echo "✅ Genesis prepared at $OUT_DIR/config/genesis.json"
echo "Chain ID: $CHAIN_ID"
echo "Denom: unxrl"
