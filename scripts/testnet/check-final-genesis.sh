#!/usr/bin/env bash
# NexaRail Testnet — Final Genesis Integrity Check
# Verifies the assembled genesis meets all requirements.
# Usage: ./scripts/testnet/check-final-genesis.sh [genesis.json]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
GENESIS="${1:-$PROJECT_DIR/rehearsals/testnet-1/genesis/genesis.json}"
CHAIN_ID="nexarail-testnet-1"
DENOM="unxrl"
EXPECTED_GENTX="${2:-}"

PASS=0
FAIL=0

check() { local msg="$1"; shift; if "$@"; then echo "  ✅ $msg"; PASS=$((PASS+1)); else echo "  ❌ $msg"; FAIL=$((FAIL+1)); fi; }

echo "╔══════════════════════════════════════════╗"
echo "║  NexaRail Genesis Integrity Check       ║"
echo "╚══════════════════════════════════════════╝"
echo ""

if [ ! -f "$GENESIS" ]; then
    echo "❌ Genesis file not found: $GENESIS"
    exit 1
fi
echo "Genesis: $GENESIS"
echo ""

# 1. JSON validity
echo "--- Basic Integrity ---"
check "JSON valid" python3 -c "import json; json.load(open('$GENESIS'))" 2>/dev/null

# 2. Chain ID
echo ""
echo "--- Chain Configuration ---"
ACTUAL_CHAIN=$(python3 -c "import json; print(json.load(open('$GENESIS')).get('chain_id',''))" 2>/dev/null || echo "")
[ "$ACTUAL_CHAIN" = "$CHAIN_ID" ] && check "Chain ID = $CHAIN_ID" true || check "Chain ID = $CHAIN_ID (got: $ACTUAL_CHAIN)" false

# 3. Denom
BOND_DENOM=$(python3 -c "import json; print(json.load(open('$GENESIS'))['app_state']['staking']['params'].get('bond_denom',''))" 2>/dev/null || echo "")
[ "$BOND_DENOM" = "$DENOM" ] && check "Bond denom = $DENOM" true || check "Bond denom = $DENOM (got: $BOND_DENOM)" false

# 4. Voting period
VOTING=$(python3 -c "import json; print(json.load(open('$GENESIS'))['app_state']['gov']['voting_params'].get('voting_period',''))" 2>/dev/null || echo "")
[ "$VOTING" = "60s" ] && check "Voting period = 60s" true || check "Voting period = 60s (got: $VOTING)" false

# 5. Crisis denom
CRISIS_DENOM=$(python3 -c "import json; print(json.load(open('$GENESIS'))['app_state']['crisis']['constant_fee'].get('denom',''))" 2>/dev/null || echo "")
[ "$CRISIS_DENOM" = "$DENOM" ] && check "Crisis denom = $DENOM" true || check "Crisis denom = $DENOM (got: $CRISIS_DENOM)" false

# 6. gen_txs count
echo ""
echo "--- Validator Set ---"
GEN_TX_COUNT=$(python3 -c "import json; print(len(json.load(open('$GENESIS'))['app_state']['genutil']['gen_txs']))" 2>/dev/null || echo "0")
echo "  gen_txs count: $GEN_TX_COUNT"

if [ -n "$EXPECTED_GENTX" ] && [ "$EXPECTED_GENTX" -gt 0 ] 2>/dev/null; then
    [ "$GEN_TX_COUNT" = "$EXPECTED_GENTX" ] && check "gen_txs = $EXPECTED_GENTX (expected)" true || check "gen_txs = $EXPECTED_GENTX (got: $GEN_TX_COUNT)" false
else
    [ "$GEN_TX_COUNT" -ge 3 ] 2>/dev/null && check "gen_txs ≥ 3 (minimum)" true || check "gen_txs ≥ 3 (got: $GEN_TX_COUNT)" false
fi

# 7. Custom modules present
echo ""
echo "--- Custom Modules ---"
for mod in fees merchant settlement escrow treasury payout; do
    EXISTS=$(python3 -c "import json; g=json.load(open('$GENESIS')); print('yes' if '$mod' in g.get('app_state',{}) else 'no')" 2>/dev/null || echo "no")
    [ "$EXISTS" = "yes" ] && check "Module '$mod' present" true || check "Module '$mod' present" false
done

# 8. Live flags
echo ""
echo "--- Live Flags (must all be false) ---"
check_flag() {
    local mod="$1" flag="$2" label="$3"
    local val=$(python3 -c "
import json
g = json.load(open('$GENESIS'))
v = g['app_state'].get('$mod',{}).get('params',{}).get('$flag',None)
print(v)
" 2>/dev/null || echo "ERROR")
    if [ "$val" = "False" ] || [ "$val" = "false" ]; then
        check "$label = false" true
    else
        check "$label = false (got: $val)" false
    fi
}

check_flag "settlement" "live_enabled" "settlement.live_enabled"
check_flag "settlement" "treasury_routing_enabled" "settlement.treasury_routing_enabled"
check_flag "settlement" "burn_routing_enabled" "settlement.burn_routing_enabled"
check_flag "escrow" "live_enabled" "escrow.live_enabled"
check_flag "treasury" "live_enabled" "treasury.live_enabled"
check_flag "payout" "live_enabled" "payout.live_enabled"

# 9. Genesis checksum
echo ""
echo "--- Checksum ---"
CHECKSUM=$(sha256sum "$GENESIS" | awk '{print $1}')
CHECKSUM_FILE="$(dirname "$GENESIS")/genesis-checksum.txt"
if [ -f "$CHECKSUM_FILE" ]; then
    STORED=$(awk '{print $1}' "$CHECKSUM_FILE" 2>/dev/null || echo "")
    [ "$CHECKSUM" = "$STORED" ] && check "Checksum matches stored value" true || check "Checksum matches stored value" false
else
    echo "  ⚠️  No stored checksum file at $CHECKSUM_FILE"
fi
echo "  Current checksum: $CHECKSUM"

# 10. Summary
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Results: $PASS passed, $FAIL failed        ║"
if [ "$FAIL" -gt 0 ]; then
    echo "║  Verdict: ❌ FAILED                     ║"
else
    echo "║  Verdict: ✅ GENESIS VALID              ║"
fi
echo "╚══════════════════════════════════════════╝"

exit $FAIL
