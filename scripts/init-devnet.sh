#!/usr/bin/env bash
# ------------------------------------------------------------------
# NexaRail Devnet Initialisation Script
# Creates a local multi-validator devnet with genesis NXRL allocations.
# ------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
BINARY="$BUILD_DIR/nexaraild"

CHAIN_ID="nexarail-devnet-1"
HOME_DIR="$HOME/.nexarail"

# --- Configuration ---
NUM_VALIDATORS=${1:-3}               # Number of validators (default: 3)
VALIDATOR_COINS=${2:-"100000000000unxrl"}  # Each validator gets this many uxr
DELEGATION_AMOUNT="100000000000unxrl"     # Self-delegation for each validator
STAKING_AMOUNT="100000000000unxrl"        # Amount to bond
GOV_PROPOSAL_DEPOSIT="1000000000unxrl"    # Min deposit for governance

# Additional genesis accounts (address:coins)
EXTRA_ACCOUNTS=(
  "user:50000000000unxrl"
  "treasury:1000000000000unxrl"
  "merchant:10000000000unxrl"
)

echo "========================================"
echo " NexaRail Devnet Initialisation"
echo " Chain ID:  $CHAIN_ID"
echo " Validators: $NUM_VALIDATORS"
echo "========================================"

# Clean existing home directory
rm -rf "$HOME_DIR"*

# Initialise validator directories
for i in $(seq 0 $((NUM_VALIDATORS - 1))); do
  VAL_HOME="${HOME_DIR}/validator${i}"
  MONIKER="nexarail-validator-${i}"

  echo "[init] Validator $i: $MONIKER"

  "$BINARY" init "$MONIKER" \
    --chain-id "$CHAIN_ID" \
    --home "$VAL_HOME"

  # Update validator config for local devnet
  APP_CFG="$VAL_HOME/config/app.toml"
  if [[ -f "$APP_CFG" ]]; then
    # Set min gas price
    sed -i '' 's/minimum-gas-prices = ".*"/minimum-gas-prices = "0.025unxrl"/' "$APP_CFG"
  fi

  # Update CometBFT config for local devnet
  CMT_CFG="$VAL_HOME/config/config.toml"
  if [[ -f "$CMT_CFG" ]]; then
    # Allow all IPs for testing
    sed -i '' 's/addr_book_strict = .*/addr_book_strict = false/' "$CMT_CFG"
    # Peers will be set later
    sed -i '' 's/persistent_peers = .*/persistent_peers = ""/' "$CMT_CFG"
    # Enable Prometheus
    sed -i '' 's/prometheus = .*/prometheus = true/' "$CMT_CFG"
  fi
done

# Create validator keys and accounts
for i in $(seq 0 $((NUM_VALIDATORS - 1))); do
  VAL_HOME="${HOME_DIR}/validator${i}"

  echo "[keys] Creating key for validator $i"

  echo "y" | "$BINARY" keys add "validator${i}" \
    --keyring-backend test \
    --home "$VAL_HOME" \
    --output json > "${HOME_DIR}/validator${i}-key.json" 2>/dev/null
done

# Collect validator addresses
VALIDATOR_ADDRESSES=()
for i in $(seq 0 $((NUM_VALIDATORS - 1))); do
  ADDR=$(jq -r '.address' "${HOME_DIR}/validator${i}-key.json")
  VALIDATOR_ADDRESSES+=("$ADDR")
done

# Add genesis accounts for validators
echo "[genesis] Adding validator accounts..."
for i in $(seq 0 $((NUM_VALIDATORS - 1))); do
  "$BINARY" add-genesis-account "${VALIDATOR_ADDRESSES[$i]}" "$VALIDATOR_COINS" \
    --keyring-backend test \
    --home "${HOME_DIR}/validator0"   # Use validator0 home for genesis state
done

# Add extra genesis accounts
echo "[genesis] Adding additional accounts..."
for entry in "${EXTRA_ACCOUNTS[@]}"; do
  NAME="${entry%%:*}"
  COINS="${entry#*:}"

  # Create key if it doesn't exist
  echo "y" | "$BINARY" keys add "$NAME" \
    --keyring-backend test \
    --home "${HOME_DIR}/validator0" \
    --output json > "${HOME_DIR}/${NAME}-key.json" 2>/dev/null || true

  ADDR=$(jq -r '.address' "${HOME_DIR}/${NAME}-key.json")
  "$BINARY" add-genesis-account "$ADDR" "$COINS" \
    --keyring-backend test \
    --home "${HOME_DIR}/validator0"
done

# Create gentx for each validator
echo "[genesis] Creating gentx transactions..."
for i in $(seq 0 $((NUM_VALIDATORS - 1))); do
  VAL_HOME="${HOME_DIR}/validator${i}"

  # Copy genesis from validator0 to all validators
  cp "${HOME_DIR}/validator0/config/genesis.json" "$VAL_HOME/config/genesis.json"

  "$BINARY" gentx "validator${i}" "$STAKING_AMOUNT" \
    --keyring-backend test \
    --chain-id "$CHAIN_ID" \
    --home "$VAL_HOME" \
    --moniker "nexarail-validator-${i}" \
    --commission-rate "0.10" \
    --commission-max-rate "0.20" \
    --commission-max-change-rate "0.01" \
    --min-self-delegation "1"
done

# Collect gentx into validator0
echo "[genesis] Collecting gentx..."
GENTX_DIR="${HOME_DIR}/validator0/config/gentx"
mkdir -p "$GENTX_DIR"

for i in $(seq 0 $((NUM_VALIDATORS - 1))); do
  cp "${HOME_DIR}/validator${i}/config/gentx/"*.json "$GENTX_DIR/"
done

"$BINARY" collect-gentxs \
  --home "${HOME_DIR}/validator0" \
  --gentx-dir "$GENTX_DIR"

# Validate genesis
echo "[genesis] Validating genesis..."
"$BINARY" validate-genesis \
  --home "${HOME_DIR}/validator0"

# Distribute final genesis to all validators
echo "[genesis] Distributing genesis to all validators..."
for i in $(seq 1 $((NUM_VALIDATORS - 1))); do
  mkdir -p "${HOME_DIR}/validator${i}/config"
  cp "${HOME_DIR}/validator0/config/genesis.json" "${HOME_DIR}/validator${i}/config/genesis.json"
done

echo ""
echo "========================================"
echo " Devnet initialised successfully!"
echo " Validators: $NUM_VALIDATORS"
echo " Genesis file: ${HOME_DIR}/validator0/config/genesis.json"
echo ""
echo " To start the devnet, run:"
echo "   make start-devnet"
echo " Or:"
echo "   bash scripts/start-devnet.sh"
echo "========================================"

# Print summary
echo ""
echo "--- Account Summary ---"
echo "Validator Addresses:"
for i in $(seq 0 $((NUM_VALIDATORS - 1))); do
  echo "  validator${i}: ${VALIDATOR_ADDRESSES[$i]}"
done

for entry in "${EXTRA_ACCOUNTS[@]}"; do
  NAME="${entry%%:*}"
  COINS="${entry#*:}"
  ADDR=$(jq -r '.address' "${HOME_DIR}/${NAME}-key.json" 2>/dev/null || echo "unknown")
  echo "  ${NAME}: ${ADDR} (${COINS})"
done

# Show validator node info
echo ""
echo "--- Node IDs ---"
for i in $(seq 0 $((NUM_VALIDATORS - 1))); do
  NODE_ID=$("$BINARY" tendermint show-node-id --home "${HOME_DIR}/validator${i}" 2>/dev/null || echo "N/A")
  echo "  validator${i}: $NODE_ID"
done
