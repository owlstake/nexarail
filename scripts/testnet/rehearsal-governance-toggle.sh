#!/usr/bin/env bash
# NexaRail Rehearsal Governance Toggle
# Demonstrates enabling and disabling escrow LiveEnabled via governance.
# TESTNET REHEARSAL ONLY — local, zero-value tokens.
set -euo pipefail

CHAIN_ID="nexarail-testnet-1"
BINARY="./build/nexaraild"
HOME0="rehearsals/testnet-1/validator-notes/val0"
HOME1="rehearsals/testnet-1/validator-notes/val1"
HOME2="rehearsals/testnet-1/validator-notes/val2"
KEYRING="test"
RPC="http://127.0.0.1:26657"
GAS="--gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl"

echo "╔══════════════════════════════════════════╗"
echo "║  NexaRail Governance Toggle Rehearsal   ║"
echo "║  Enable → test → disable escrow Live    ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Helper: get escrow params
get_flag() {
    curl -s "http://localhost:1317/cosmos/escrow/v1/params" 2>/dev/null | jq -r '.params.live_enabled // "query_failed"'
}

# Helper: authority address (governance module)
AUTH=$($BINARY keys show gov --keyring-backend test --home "$HOME0" -a 2>/dev/null || echo "")
if [ -z "$AUTH" ]; then
    # Use val0 as authority for rehearsal simplicity
    AUTH=$($BINARY keys show val0 -a --keyring-backend test --home "$HOME0")
fi

echo "Current escrow LiveEnabled: $(get_flag)"

# Step 1: Enable escrow LiveEnabled
echo ""
echo "--- Step 1: Enable escrow LiveEnabled ---"
$BINARY tx escrow update-params --live-enabled true \
    --from val0 --chain-id "$CHAIN_ID" --keyring-backend "$KEYRING" \
    --home "$HOME0" $GAS -y 2>&1 | tail -3
sleep 3

FLAG=$(get_flag)
echo "Escrow LiveEnabled after enable: $FLAG"
if [ "$FLAG" = "true" ]; then
    echo "  ✅ Enable succeeded"
else
    echo "  ⚠️  Flag may not have changed yet. Run: nexaraild query escrow params"
fi

# Step 2: Test with metadata mode (flag=true but try a settlement to verify)
echo ""
echo "--- Step 2: Verify flag is true ---"
sleep 3
FLAG=$(get_flag)
echo "  Final check: LiveEnabled=$FLAG"

# Step 3: Disable escrow LiveEnabled
echo ""
echo "--- Step 3: Disable escrow LiveEnabled ---"
$BINARY tx escrow update-params --live-enabled false \
    --from val0 --chain-id "$CHAIN_ID" --keyring-backend "$KEYRING" \
    --home "$HOME0" $GAS -y 2>&1 | tail -3
sleep 3

FLAG=$(get_flag)
echo "Escrow LiveEnabled after disable: $FLAG"
if [ "$FLAG" = "false" ]; then
    echo "  ✅ Disable succeeded"
else
    echo "  ⚠️  Flag may still be true. Wait longer or query manually."
fi

echo ""
echo "=== Governance Toggle Rehearsal Complete ==="
echo "LiveEnabled returned to: $(get_flag)"
