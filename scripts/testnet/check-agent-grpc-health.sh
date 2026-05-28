#!/usr/bin/env bash
# NexaRail — gRPC Health Check for Validator Agents
#
# Checks that gRPC is enabled and the tx service is reachable on each agent.
# TESTNET ONLY.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

GRPC_PORTS=(9190 9191 9192 9193 9194)
AGENT_NAMES=(alpha bravo charlie delta echo)
PASS=0
FAIL=0

echo "╔══════════════════════════════════════════════╗"
echo "║  NexaRail — Agent gRPC Health Check         ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

if ! command -v grpcurl &>/dev/null; then
    echo "❌ grpcurl not installed. Install: brew install grpcurl"
    exit 1
fi

for i in "${!GRPC_PORTS[@]}"; do
    port="${GRPC_PORTS[$i]}"
    name="${AGENT_NAMES[$i]}"
    
    echo "--- $name (port $port) ---"
    
    # Check port open
    if lsof -iTCP:$port -sTCP:LISTEN -P -n 2>/dev/null | grep -q LISTEN; then
        echo "  ✅ Port open"
    else
        echo "  ❌ Port NOT listening"
        FAIL=$((FAIL+1))
        continue
    fi
    
    # Check reflection
    SERVICES=$(grpcurl -plaintext -max-time 3 "127.0.0.1:$port" list 2>&1)
    if echo "$SERVICES" | grep -q "cosmos.tx.v1beta1.Service"; then
        echo "  ✅ gRPC reflection: cosmos.tx.v1beta1.Service found"
        PASS=$((PASS+1))
    else
        echo "  ⚠️  gRPC reflection: services found but cosmos.tx.v1beta1.Service may be missing"
        echo "     First 5: $(echo "$SERVICES" | head -3 | tr '\n' ' ')"
    fi
    
    # Check BroadcastTx
    TX_CHECK=$(grpcurl -plaintext -max-time 3 "127.0.0.1:$port" describe cosmos.tx.v1beta1.Service 2>&1)
    if echo "$TX_CHECK" | grep -q "BroadcastTx"; then
        echo "  ✅ BroadcastTx available"
    else
        echo "  ⚠️  BroadcastTx not available: $TX_CHECK"
    fi
    
    # Check query services
    if echo "$SERVICES" | grep -q "nexarail.escrow.v1.Query"; then
        echo "  ✅ nexarail.escrow.v1.Query available"
    fi
    if echo "$SERVICES" | grep -q "cosmos.gov.v1.Query"; then
        echo "  ✅ cosmos.gov.v1.Query available"
    fi
    
    echo ""
done

echo "══════════════════════════════════════════════"
echo "  gRPC Health: $PASS/$((PASS+FAIL)) agents OK"
echo "══════════════════════════════════════════════"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
