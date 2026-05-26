#!/usr/bin/env bash
# NexaRail Testnet Rehearsal Health Check
# Validates a running nexarail-testnet-1 rehearsal instance.
# LOCAL REHEARSAL ONLY.
set -euo pipefail

BINARY="${NEXARAIL_BINARY:-./build/nexaraild}"
CHAIN_ID="nexarail-testnet-1"
NODE="${NEXARAIL_NODE:-http://localhost:26657}"
REST="${NEXARAIL_REST:-http://localhost:1317}"

PASS=0
FAIL=0

check() {
    local desc="$1"
    shift
    echo -n "  $desc ... "
    if "$@" 2>/dev/null; then
        echo "✅"
        ((PASS++))
    else
        echo "❌"
        ((FAIL++))
    fi
}

echo "=== NexaRail Testnet Rehearsal Health Check ==="
echo "Chain ID: $CHAIN_ID"
echo "Node:     $NODE"
echo ""

# 1. Binary exists
echo "--- Binary ---"
check "Binary exists" test -f "$BINARY"
VERSION=$($BINARY version 2>/dev/null || echo "unknown")
echo "  Version: $VERSION"

# 2. Node status
echo "--- Node Status ---"
STATUS=$(curl -s "$NODE/status" 2>/dev/null || echo '{}')
HEIGHT=$(echo "$STATUS" | jq -r '.result.sync_info.latest_block_height // "0"')
CATCHING_UP=$(echo "$STATUS" | jq -r '.result.sync_info.catching_up // "true"')
NETWORK=$(echo "$STATUS" | jq -r '.result.node_info.network // ""')

check "RPC reachable" test "$HEIGHT" != "0"
check "Chain ID matches ($CHAIN_ID)" test "$NETWORK" = "$CHAIN_ID"
check "Not catching up" test "$CATCHING_UP" = "false"

echo "  Block height: $HEIGHT"
echo "  Network:      $NETWORK"

# 3. Validator count
echo "--- Validators ---"
VAL_COUNT=$(curl -s "$REST/cosmos/staking/v1beta1/validators?status=BOND_STATUS_BONDED" 2>/dev/null | jq '.validators | length // 0')
check "At least 1 bonded validator" test "${VAL_COUNT:-0}" -ge 1
echo "  Bonded validators: ${VAL_COUNT:-unknown}"

# 4. Module params — live flags default false
echo "--- Live Flags (all should be false) ---"

# Settlement
SETTLE_PARAMS=$(curl -s "$NODE/abci_query?path=\"/custom/settlement/params\"" 2>/dev/null || echo '{}')
check "Settlement params queryable" test "$SETTLE_PARAMS" != "{}"

# Escrow
ESCROW_PARAMS=$(curl -s "$NODE/abci_query?path=\"/custom/escrow/params\"" 2>/dev/null || echo '{}')
check "Escrow params queryable" test "$ESCROW_PARAMS" != "{}"

# Treasury
TREASURY_PARAMS=$(curl -s "$NODE/abci_query?path=\"/custom/treasury/params\"" 2>/dev/null || echo '{}')
check "Treasury params queryable" test "$TREASURY_PARAMS" != "{}"

# Payout
PAYOUT_PARAMS=$(curl -s "$NODE/abci_query?path=\"/custom/payout/params\"" 2>/dev/null || echo '{}')
check "Payout params queryable" test "$PAYOUT_PARAMS" != "{}"

# Fees
FEES_PARAMS=$(curl -s "$NODE/abci_query?path=\"/custom/fees/params\"" 2>/dev/null || echo '{}')
check "Fees params queryable" test "$FEES_PARAMS" != "{}"

# Merchant
MERCH_PARAMS=$(curl -s "$NODE/abci_query?path=\"/custom/merchant/params\"" 2>/dev/null || echo '{}')
check "Merchant params queryable" test "$MERCH_PARAMS" != "{}"

# 5. Source-level flag defaults check (always passes if code unchanged)
echo "--- Source-Level Flag Defaults ---"
for flag in "LiveEnabled.*false" "TreasuryRoutingEnabled.*false" "BurnRoutingEnabled.*false"; do
    check "Default $flag in settlement params" grep -q "$flag" x/settlement/types/params.go
done
check "Default LiveEnabled=false in escrow" grep -q "LiveEnabled.*false" x/escrow/types/params.go
check "Default LiveEnabled=false in treasury" grep -q "LiveEnabled.*false" x/treasury/types/params.go
check "Default LiveEnabled=false in payout" grep -q "LiveEnabled.*false" x/payout/types/params.go

# 6. Module accounts
echo "--- Module Accounts ---"
check "nexarail_escrow registered" grep -q "NexaRailEscrowModuleAccount" app/app.go
check "nexarail_treasury registered" grep -q "NexaRailTreasuryModuleAccount" app/app.go
check "nexarail_burner registered" grep -q "NexaRailBurnerModuleAccount" app/app.go
check "nexarail_burner has Burner permission" grep -A20 "maccPerms := map" app/app.go | grep -q "NexaRailBurnerModuleAccount.*Burner"

# Summary
echo ""
echo "=== Health Check Complete ==="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "  Verdict: ✅ All checks passed"
else
    echo "  Verdict: ❌ $FAIL check(s) failed"
fi
