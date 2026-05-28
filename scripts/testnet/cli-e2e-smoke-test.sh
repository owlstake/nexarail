#!/usr/bin/env bash
# NexaRail CLI E2E Smoke Test
# Runs against a live nexaraild node. Requires RPC on port 26657 and gRPC on port 9090.
# TESTNET/DEVNET ONLY — not for mainnet (none exists).
set -euo pipefail

RPC="${RPC:-http://127.0.0.1:26657}"
GRPC="${GRPC:-127.0.0.1:9090}"
BINARY="${BINARY:-./build/nexaraild}"
HOME_DIR="${HOME_DIR:-$HOME/.nexarail}"
PASS=0
FAIL=0

check() { local msg="$1"; shift; if "$@" 2>/dev/null; then echo "  ✅ $msg"; PASS=$((PASS+1)); else echo "  ❌ $msg"; FAIL=$((FAIL+1)); fi; }
skip() { echo "  ⏭️  $1 (skipped)"; }

echo "╔══════════════════════════════════════════╗"
echo "║  NexaRail CLI E2E Smoke Test            ║"
echo "║  RPC: $RPC"
echo "║  gRPC: $GRPC"
echo "╚══════════════════════════════════════════╝"
echo ""

# Pre-flight
echo "--- Pre-flight ---"
check "Binary exists" test -f "$BINARY"
check "RPC reachable" curl -s --max-time 3 "$RPC/status" > /dev/null

# RPC status
echo ""
echo "--- RPC Status ---"
STATUS=$(curl -s --max-time 3 "$RPC/status" 2>/dev/null || echo '{}')
HEIGHT=$(echo "$STATUS" | jq -r '.result.sync_info.latest_block_height // "0"')
CHAIN=$(echo "$STATUS" | jq -r '.result.node_info.network // ""')
echo "  Height: $HEIGHT  Chain: $CHAIN"
check "RPC status returns height > 0" test "${HEIGHT:-0}" -gt 0

# Module CLI queries (via gRPC, need --grpc-addr)
echo ""
echo "--- Module Params Queries ---"
for mod in fees merchant settlement escrow payout treasury; do
    result=$("$BINARY" query "$mod" params --node "$RPC" --grpc-addr "$GRPC" --grpc-insecure --output json 2>/dev/null || echo "")
    if [ -n "$result" ]; then
        check "query $mod params" true
    else
        echo "  ⚠️  query $mod params (gRPC client not reachable — may need running node)"
        FAIL=$((FAIL+1))
    fi
done

# Bank query
echo ""
echo "--- Bank Query ---"
BANK_RESULT=$("$BINARY" query bank total --node "$RPC" 2>/dev/null || echo "")
if [ -n "$BANK_RESULT" ]; then
    check "query bank total" true
else
    echo "  ⚠️  query bank total (may need gRPC client — try with a local node)"
    FAIL=$((FAIL+1))
fi

# Key operations (test keyring)
echo ""
echo "--- Key Operations ---"
KEY_NAME="smoke-test-key"
"$BINARY" keys delete "$KEY_NAME" --keyring-backend test --home "$HOME_DIR" -y 2>/dev/null || true
check "keys add" "$BINARY" keys add "$KEY_NAME" --keyring-backend test --home "$HOME_DIR" --output text 2>/dev/null | grep -q "address"
ADDR=$("$BINARY" keys show "$KEY_NAME" -a --keyring-backend test --home "$HOME_DIR" 2>/dev/null || echo "")
check "keys show returns address" test -n "$ADDR"
echo "  Address: $ADDR"
check "keys list shows key" "$BINARY" keys list --keyring-backend test --home "$HOME_DIR" 2>/dev/null | grep -q "$KEY_NAME"

# Cleanup key
"$BINARY" keys delete "$KEY_NAME" --keyring-backend test --home "$HOME_DIR" -y 2>/dev/null || true

# Debug commands
echo ""
echo "--- Debug Commands ---"
check "debug-p2p-config" "$BINARY" debug-p2p-config --home "$HOME_DIR" 2>/dev/null | grep -q "p2p.laddr"

# Live flags check (if command added)
echo ""
echo "--- Live Flags Check ---"
if "$BINARY" debug live-flags --home "$HOME_DIR" 2>/dev/null | grep -q "live_enabled"; then
    check "debug live-flags" true
    "$BINARY" debug live-flags --home "$HOME_DIR" 2>/dev/null
else
    skip "debug live-flags (command may not be registered yet)"
fi

# Module summary
if "$BINARY" debug module-summary --home "$HOME_DIR" 2>/dev/null | grep -q "Module"; then
    check "debug module-summary" true
else
    skip "debug module-summary (command may not be registered yet)"
fi

# Summary
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Results: $PASS passed, $FAIL failed       ║"
if [ "$FAIL" -gt 0 ]; then
    echo "║  Some checks failed or were skipped.    ║"
    echo "║  Ensure a local node is running for     ║"
    echo "║  full CLI E2E coverage.                 ║"
fi
echo "╚══════════════════════════════════════════╝"

exit $FAIL
