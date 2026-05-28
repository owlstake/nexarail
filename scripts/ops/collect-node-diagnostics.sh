#!/usr/bin/env bash
# NexaRail — Collect Node Diagnostics
# Gathers logs, status, and state info from a running or recently crashed node.
# TESTNET/DEVNET ONLY.
set -euo pipefail

NODE="${1:-http://127.0.0.1:26657}"
OUTDIR="${2:-./diagnostics-$(date -u +%Y%m%dT%H%M%SZ)}"

mkdir -p "$OUTDIR"

echo "=== NexaRail Node Diagnostics ==="
echo "Node: $NODE"
echo "Output: $OUTDIR"
echo ""

# Status
echo "--- Collecting status ---"
curl -s --max-time 5 "$NODE/status" 2>/dev/null > "$OUTDIR/status.json" || echo '{"error":"RPC unreachable"}' > "$OUTDIR/status.json"
HEIGHT=$(jq -r '.result.sync_info.latest_block_height // "0"' "$OUTDIR/status.json")
CHAIN=$(jq -r '.result.node_info.network // "unknown"' "$OUTDIR/status.json")
echo "  Height: $HEIGHT  Chain: $CHAIN"

# Net info
curl -s --max-time 5 "$NODE/net_info" 2>/dev/null > "$OUTDIR/net_info.json" || echo '{}' > "$OUTDIR/net_info.json"
PEERS=$(jq -r '.result.n_peers // "0"' "$OUTDIR/net_info.json")
echo "  Peers: $PEERS"

# Validators
curl -s --max-time 5 "$NODE/validators" 2>/dev/null > "$OUTDIR/validators.json" || echo '{}' > "$OUTDIR/validators.json"

# Consensus state
curl -s --max-time 5 "$NODE/dump_consensus_state" 2>/dev/null > "$OUTDIR/consensus_state.json" || echo '{}' > "$OUTDIR/consensus_state.json"

# Genesis
if [ -f "$HOME/.nexarail/config/genesis.json" ]; then
    cp "$HOME/.nexarail/config/genesis.json" "$OUTDIR/genesis.json"
    echo "  Genesis copied"
fi

# Binary version
if command -v nexaraild &>/dev/null; then
    nexaraild version > "$OUTDIR/version.txt" 2>/dev/null || echo "unknown" > "$OUTDIR/version.txt"
    echo "  Version: $(cat "$OUTDIR/version.txt")"
fi

# Config
if [ -f "$HOME/.nexarail/config/config.toml" ]; then
    cp "$HOME/.nexarail/config/config.toml" "$OUTDIR/config.toml"
    echo "  Config copied"
fi

echo ""
echo "Diagnostics saved to: $OUTDIR"
ls -la "$OUTDIR/"
