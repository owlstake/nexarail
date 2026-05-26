#!/usr/bin/env bash
# NexaRail Testnet Node Health Check
# Quick health verification for a running node.
set -euo pipefail

NODE="${NEXARAIL_NODE:-http://localhost:26657}"
BINARY="${NEXARAIL_BINARY:-./build/nexaraild}"

echo "=== NexaRail Node Health Check ==="
echo "Node: $NODE"
echo ""

# Check 1: Node status
echo "--- Node Status ---"
STATUS=$(curl -s "$NODE/status" 2>/dev/null || echo '{}')
HEIGHT=$(echo "$STATUS" | jq -r '.result.sync_info.latest_block_height // "unknown"')
CATCHING_UP=$(echo "$STATUS" | jq -r '.result.sync_info.catching_up // "unknown"')
MONIKER=$(echo "$STATUS" | jq -r '.result.node_info.moniker // "unknown"')

echo "  Moniker:     $MONIKER"
echo "  Height:      $HEIGHT"
echo "  Catching up: $CATCHING_UP"

if [ "$CATCHING_UP" = "false" ] && [ "$HEIGHT" != "unknown" ] && [ "$HEIGHT" -gt 0 ]; then
    echo "  ✅ Node is synced and producing blocks"
elif [ "$CATCHING_UP" = "true" ]; then
    echo "  ⚠️  Node is still catching up"
else
    echo "  ❌ Cannot determine node status"
fi

# Check 2: Peer count
echo "--- Peers ---"
PEERS=$(curl -s "$NODE/net_info" 2>/dev/null | jq -r '.result.n_peers // "0"')
echo "  Peers: $PEERS"
if [ "$PEERS" -gt 0 ] 2>/dev/null; then
    echo "  ✅ Connected to peers"
elif [ "$PEERS" -eq 0 ] 2>/dev/null; then
    echo "  ⚠️  No peers connected"
fi

# Check 3: Consensus
echo "--- Consensus ---"
CONSENSUS=$(curl -s "$NODE/dump_consensus_state" 2>/dev/null || echo '{}')
ROUND=$(echo "$CONSENSUS" | jq -r '.result.round_state.round // "unknown"')
echo "  Round: $ROUND"

# Check 4: Binary version
echo "--- Binary ---"
VERSION=$($BINARY version 2>/dev/null || echo "unknown")
echo "  Version: $VERSION"

echo ""
echo "Health check complete."
