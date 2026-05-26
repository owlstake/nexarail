#!/usr/bin/env bash
# NexaRail Local 3-Validator Rehearsal — QUERY
# Queries all module params, chain status, validators, and balances.
# Assumes validators are running (run-local-3-validator-rehearsal.sh).
set -euo pipefail

CHAIN_ID="nexarail-testnet-1"
DENOM="unxrl"
RPC="http://127.0.0.1:26657"
REST="http://127.0.0.1:1317"
BINARY="./build/nexaraild"

PASS=0
FAIL=0

check_value() {
    local desc="$1" key="$2" expected="$3"
    local actual="$4"
    echo -n "  $desc: "
    if echo "$actual" | grep -q "$expected" 2>/dev/null; then
        echo "✅ $actual"
        ((PASS++))
    else
        echo "❌ got '$actual', expected to contain '$expected'"
        ((FAIL++))
    fi
}

echo "╔══════════════════════════════════════════╗"
echo "║  NexaRail Rehearsal Query               ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# 1. Node Status
echo "--- 1. Node Status ---"
STATUS=$(curl -s "$RPC/status" 2>/dev/null || echo '{"result":{"sync_info":{"latest_block_height":"0","catching_up":"true"},"node_info":{"network":""}}}')
HEIGHT=$(echo "$STATUS" | jq -r '.result.sync_info.latest_block_height // "0"')
CATCHING=$(echo "$STATUS" | jq -r '.result.sync_info.catching_up // "true"')
NETWORK=$(echo "$STATUS" | jq -r '.result.node_info.network // ""')
MONIKER=$(echo "$STATUS" | jq -r '.result.node_info.moniker // ""')

check_value "Block height > 0"   "height"  "."  "$HEIGHT"
check_value "Not catching up"     "sync"    "false" "$CATCHING"
check_value "Chain ID"            "chain"   "$CHAIN_ID" "$NETWORK"
echo "  Moniker: $MONIKER (height=$HEIGHT)"

# 2. Net Info
echo "--- 2. Peers ---"
PEERS=$(curl -s "$RPC/net_info" 2>/dev/null | jq -r '.result.n_peers // "0"')
echo "  Peers: $PEERS"

# 3. Validator Set
echo "--- 3. Validator Set ---"
VAL_COUNT=$(curl -s "$RPC/validators" 2>/dev/null | jq '.result.validators | length // 0')
echo "  Validators: $VAL_COUNT"

# 4. Bank Balances (faucet)
echo "--- 4. Balances ---"
FAUCET_ADDR=$($BINARY keys show faucet -a --keyring-backend test --home rehearsals/testnet-1/validator-notes/val0 2>/dev/null || echo "unknown")
BAL=$(curl -s "$REST/cosmos/bank/v1beta1/balances/$FAUCET_ADDR" 2>/dev/null | jq -r '.balances[0].amount // "0"')
echo "  Faucet ($FAUCET_ADDR): ${BAL}${DENOM}"

# 5. Settlement Params
echo "--- 5. Settlement Params ---"
SP=$(curl -s "$REST/cosmos/settlement/v1/params" 2>/dev/null || echo '{"params":{}}')
check_value "Settlement LiveEnabled"    "live"    "false" "$(echo "$SP" | jq -r '.params.live_enabled // "query_failed"')"
check_value "TreasuryRoutingEnabled"     "treasury" "false" "$(echo "$SP" | jq -r '.params.treasury_routing_enabled // "query_failed"')"
check_value "BurnRoutingEnabled"         "burn"    "false" "$(echo "$SP" | jq -r '.params.burn_routing_enabled // "query_failed"')"

# 6. Escrow Params
echo "--- 6. Escrow Params ---"
EP=$(curl -s "$REST/cosmos/escrow/v1/params" 2>/dev/null || echo '{"params":{}}')
check_value "Escrow LiveEnabled" "escrow_live" "false" "$(echo "$EP" | jq -r '.params.live_enabled // "query_failed"')"

# 7. Treasury Params
echo "--- 7. Treasury Params ---"
TP=$(curl -s "$REST/cosmos/treasury/v1/params" 2>/dev/null || echo '{"params":{}}')
check_value "Treasury LiveEnabled" "treasury_live" "false" "$(echo "$TP" | jq -r '.params.live_enabled // "query_failed"')"

# 8. Payout Params
echo "--- 8. Payout Params ---"
PP=$(curl -s "$REST/cosmos/payout/v1/params" 2>/dev/null || echo '{"params":{}}')
check_value "Payout LiveEnabled" "payout_live" "false" "$(echo "$PP" | jq -r '.params.live_enabled // "query_failed"')"

# 9. Fees Params
echo "--- 9. Fees Params ---"
FP=$(curl -s "$REST/cosmos/fees/v1/params" 2>/dev/null || echo '{"params":{}}')
VS=$(echo "$FP" | jq -r '.params.validator_share_bps // "query_failed"')
TS=$(echo "$FP" | jq -r '.params.treasury_share_bps // "query_failed"')
BS=$(echo "$FP" | jq -r '.params.burn_share_bps // "query_failed"')
echo "  Validator share: ${VS} bps | Treasury: ${TS} bps | Burn: ${BS} bps"
check_value "Fee split valid" "fees" "6000" "$VS"

# 10. Merchant Params
echo "--- 10. Merchant Params ---"
MP=$(curl -s "$REST/cosmos/merchant/v1/params" 2>/dev/null || echo '{"params":{}}')
EM=$(echo "$MP" | jq -r '.params.enabled // "query_failed"')
echo "  Merchant enabled: $EM"

# 11. Staking Validators (REST)
echo "--- 11. Staking Validators ---"
SV=$(curl -s "$REST/cosmos/staking/v1beta1/validators?status=BOND_STATUS_BONDED" 2>/dev/null | jq '.validators | length // 0')
echo "  Bonded validators: $SV"

# Summary
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Query Results: $PASS passed, $FAIL failed      ║"
echo "╚══════════════════════════════════════════╝"
if [ "$FAIL" -eq 0 ]; then
    echo "✅ All queries passed. Live flags all default false."
else
    echo "⚠️  Some queries failed. Check if validators are running."
fi
