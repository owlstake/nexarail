#!/usr/bin/env bash
set -euo pipefail

# Check live-enabled flags across all Nexarail modules.
# All should read "false" on a fresh RC1 devnet.

API_BASE_URL="${API_BASE_URL:-http://localhost:1317}"

if command -v jq &>/dev/null; then
  JQ="jq"
else
  JQ=""
fi

_fmt() {
  if [ -n "$JQ" ]; then
    echo "$1" | jq .
  else
    echo "$1"
  fi
}

echo "=============================================="
echo "  Nexarail Live Flags Check"
echo "  Base URL: $API_BASE_URL"
echo "=============================================="
echo ""

# --- Settlement ---
echo "--- Module: settlement ---"
RESP=$(curl -s -o /tmp/nexarail_flags.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/settlement/v1/params" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_flags.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  LIVE=$(echo "$BODY" | (jq -r '.params."live_enabled" | . ' 2>/dev/null || echo "PARSE_ERROR"))
  TREASURY=$(echo "$BODY" | (jq -r '.params."treasury_routing_enabled" | . ' 2>/dev/null || echo "PARSE_ERROR"))
  BURN=$(echo "$BODY" | (jq -r '.params."burn_routing_enabled" | . ' 2>/dev/null || echo "PARSE_ERROR"))
  echo "  live_enabled:             $LIVE"
  echo "  treasury_routing_enabled: $TREASURY"
  echo "  burn_routing_enabled:     $BURN"
else
  echo "  HTTP $RESP — could not fetch settlement params"
  echo "  Body: $(echo "$BODY" | head -c 200)"
fi
echo ""

# --- Escrow ---
echo "--- Module: escrow ---"
RESP=$(curl -s -o /tmp/nexarail_flags.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/escrow/v1/params" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_flags.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  LIVE=$(echo "$BODY" | (jq -r '.params."live_enabled" | . ' 2>/dev/null || echo "PARSE_ERROR"))
  echo "  live_enabled: $LIVE"
else
  echo "  HTTP $RESP — could not fetch escrow params"
  echo "  Body: $(echo "$BODY" | head -c 200)"
fi
echo ""

# --- Treasury ---
echo "--- Module: treasury ---"
RESP=$(curl -s -o /tmp/nexarail_flags.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/treasury/v1/params" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_flags.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  LIVE=$(echo "$BODY" | (jq -r '.params."live_enabled" | . ' 2>/dev/null || echo "PARSE_ERROR"))
  echo "  live_enabled: $LIVE"
else
  echo "  HTTP $RESP — could not fetch treasury params"
  echo "  Body: $(echo "$BODY" | head -c 200)"
fi
echo ""

# --- Payout ---
echo "--- Module: payout ---"
RESP=$(curl -s -o /tmp/nexarail_flags.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/payout/v1/params" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_flags.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  LIVE=$(echo "$BODY" | (jq -r '.params."live_enabled" | . ' 2>/dev/null || echo "PARSE_ERROR"))
  echo "  live_enabled: $LIVE"
else
  echo "  HTTP $RESP — could not fetch payout params"
  echo "  Body: $(echo "$BODY" | head -c 200)"
fi
echo ""

echo "=============================================="
echo "  Check complete."
echo "=============================================="

rm -f /tmp/nexarail_flags.txt
