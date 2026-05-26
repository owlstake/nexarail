#!/usr/bin/env bash
# NexaRail Testnet — Genesis Assembly Script
# Assembles the final genesis from verified gentxs.
# Usage: ./scripts/testnet/assemble-testnet-genesis.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
BINARY="$PROJECT_DIR/build/nexaraild"
CHAIN_ID="nexarail-testnet-1"
DENOM="unxrl"
GENTX_DIR="$PROJECT_DIR/rehearsals/testnet-1/gentx-collection/final"
GENESIS_DIR="$PROJECT_DIR/rehearsals/testnet-1/genesis"
TEMP_HOME="$(mktemp -d)"

cleanup() { rm -rf "$TEMP_HOME"; }
trap cleanup EXIT

echo "╔══════════════════════════════════════════╗"
echo "║  NexaRail Testnet Genesis Assembly      ║"
echo "║  Chain: $CHAIN_ID                    ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Preconditions
if [ ! -f "$BINARY" ]; then
    echo "❌ Binary not found: $BINARY"
    echo "   Run: make build"
    exit 1
fi

if [ ! -d "$GENTX_DIR" ]; then
    echo "❌ Gentx directory not found: $GENTX_DIR"
    echo "   Place verified gentxs in: $GENTX_DIR"
    exit 1
fi

GENTX_COUNT=$(ls -1 "$GENTX_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
if [ "$GENTX_COUNT" -eq 0 ]; then
    echo "❌ No gentx files found in $GENTX_DIR"
    exit 1
fi
echo "Found $GENTX_COUNT gentx file(s)"

# Step 1: Init base genesis
echo ""
echo "--- Step 1: Initialise base genesis ---"
"$BINARY" init coordinator --chain-id "$CHAIN_ID" --home "$TEMP_HOME" > /dev/null 2>&1
echo "  ✅ Base genesis initialised"

# Step 2: Copy gentxs
echo ""
echo "--- Step 2: Copy gentxs ---"
mkdir -p "$TEMP_HOME/config/gentx"
cp "$GENTX_DIR"/*.json "$TEMP_HOME/config/gentx/"
echo "  ✅ $GENTX_COUNT gentx(s) copied"

# Step 3: Collect gentxs
echo ""
echo "--- Step 3: Collect gentxs ---"
"$BINARY" collect-gentxs --home "$TEMP_HOME" 2>/dev/null
COLLECTED=$(python3 -c "
import json
g = json.load(open('$TEMP_HOME/config/genesis.json'))
print(len(g['app_state']['genutil']['gen_txs']))
" 2>/dev/null || echo "0")
echo "  ✅ gen_txs collected: $COLLECTED"

if [ "$COLLECTED" != "$GENTX_COUNT" ]; then
    echo "  ❌ Mismatch: $COLLECTED collected vs $GENTX_COUNT expected"
    exit 1
fi

# Step 4: Set parameters
echo ""
echo "--- Step 4: Set parameters ---"
TMP=$(mktemp)
jq --arg d "$DENOM" '
    .app_state.staking.params.bond_denom = $d |
    .app_state.gov.voting_params.voting_period = "60s" |
    .app_state.crisis.constant_fee.denom = $d
' "$TEMP_HOME/config/genesis.json" > "$TMP" && mv "$TMP" "$TEMP_HOME/config/genesis.json"
echo "  ✅ Bond denom=$DENOM, voting=60s, crisis denom=$DENOM"

# Step 5: Validate
echo ""
echo "--- Step 5: Validate genesis ---"
if "$BINARY" validate-genesis --home "$TEMP_HOME" 2>&1; then
    echo "  ✅ Genesis validation passed"
else
    echo "  ❌ Genesis validation failed"
    exit 1
fi

# Step 6: Write final genesis
echo ""
echo "--- Step 6: Write final genesis ---"
mkdir -p "$GENESIS_DIR"
cp "$TEMP_HOME/config/genesis.json" "$GENESIS_DIR/genesis.json"
echo "  ✅ Genesis written to: $GENESIS_DIR/genesis.json"

# Step 7: Generate checksum
echo ""
echo "--- Step 7: Generate checksum ---"
CHECKSUM=$(sha256sum "$GENESIS_DIR/genesis.json" | awk '{print $1}')
echo "$CHECKSUM  genesis.json" > "$GENESIS_DIR/genesis-checksum.txt"
echo "  ✅ Checksum: $CHECKSUM"
echo "  ✅ Written to: $GENESIS_DIR/genesis-checksum.txt"

# Step 8: Verify live flags
echo ""
echo "--- Step 8: Verify live flags ---"
check_flag() {
    local mod="$1" flag="$2"
    local val=$(python3 -c "
import json
g = json.load(open('$GENESIS_DIR/genesis.json'))
v = g['app_state'].get('$mod',{}).get('params',{}).get('$flag',None)
print(v)
" 2>/dev/null || echo "ERROR")
    if [ "$val" = "False" ] || [ "$val" = "false" ]; then
        echo "  ✅ $mod.$flag = false"
    else
        echo "  ❌ $mod.$flag = $val (expected false)"
    fi
}

check_flag "settlement" "live_enabled"
check_flag "settlement" "treasury_routing_enabled"
check_flag "settlement" "burn_routing_enabled"
check_flag "escrow" "live_enabled"
check_flag "treasury" "live_enabled"
check_flag "payout" "live_enabled"

# Step 9: Summary
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  ✅ GENESIS ASSEMBLY COMPLETE           ║"
echo "╠══════════════════════════════════════════╣"
echo "║  Chain ID:    $CHAIN_ID"
printf "║  Validators:  %-27s ║\n" "$COLLECTED"
echo "║  Checksum:    $CHECKSUM"
echo "║  Genesis:     rehearsals/testnet-1/genesis/genesis.json"
echo "╚══════════════════════════════════════════╝"
