#!/usr/bin/env bash
# NexaRail Docker Rehearsal — QUERY
# Queries all 3 validators and 6 custom module params.
set -euo pipefail
RPC=(http://127.0.0.1:26657 http://127.0.0.1:26667 http://127.0.0.1:26677)
CHAIN="nexarail-testnet-1"

echo "=== NexaRail Docker Rehearsal Query ==="
for i in 0 1 2; do
    rpc="${RPC[$i]}"
    S=$(curl -s "$rpc/status" 2>/dev/null || echo '{}')
    H=$(echo "$S" | jq -r '.result.sync_info.latest_block_height // "0"')
    N=$(echo "$S" | jq -r '.result.node_info.network // ""')
    C=$(echo "$S" | jq -r '.result.sync_info.catching_up // "true"')
    P=$(curl -s "$rpc/net_info" 2>/dev/null | jq -r '.result.n_peers // "0"')
    echo "val$i: height=$H chain=$N catching_up=$C peers=$P"
done

echo ""
echo "--- Module Params (via val0 REST :1317) ---"
REST=http://127.0.0.1:1317

query() {
    local mod="$1" path="$2" field="$3"
    local v=$(curl -s "$REST/$path" 2>/dev/null | jq -r "$field // \"N/A\"")
    printf "  %-20s %s\n" "$mod:" "$v"
}

query "fees"          "cosmos/fees/v1/params"         '.params.validator_share_bps' 2>/dev/null
query "merchant"      "cosmos/merchant/v1/params"     '.params.enabled' 2>/dev/null

echo "  settlement:"
curl -s "$REST/cosmos/settlement/v1/params" 2>/dev/null | jq '{live: .params.live_enabled, treasury: .params.treasury_routing_enabled, burn: .params.burn_routing_enabled, fee_rate: .params.fee_rate_bps}' 2>/dev/null

echo "  escrow:"
curl -s "$REST/cosmos/escrow/v1/params" 2>/dev/null | jq '{live: .params.live_enabled}' 2>/dev/null

echo "  treasury:"
curl -s "$REST/cosmos/treasury/v1/params" 2>/dev/null | jq '{live: .params.live_enabled}' 2>/dev/null

echo "  payout:"
curl -s "$REST/cosmos/payout/v1/params" 2>/dev/null | jq '{live: .params.live_enabled}' 2>/dev/null

echo ""
echo "All 6 live flags should show false (default)."
