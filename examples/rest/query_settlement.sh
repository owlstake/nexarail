#!/usr/bin/env bash
set -euo pipefail

# Query settlement module: params, list, detail, and filtered lookups.

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
echo "  Nexarail Settlement Queries"
echo "  Base URL: $API_BASE_URL"
echo "=============================================="
echo ""

# --- Settlement Params ---
echo "--- 1. Settlement Params ---"
RESP=$(curl -s -o /tmp/nexarail_settlement.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/settlement/v1/params" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_settlement.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not fetch settlement params"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Settlement List ---
echo "--- 2. Settlement List ---"
RESP=$(curl -s -o /tmp/nexarail_settlement.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/settlement/v1/settlements" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_settlement.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not fetch settlement list"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Settlement Detail (non-existent) ---
echo "--- 3. Settlement Detail (ID: non-existent) ---"
RESP=$(curl -s -o /tmp/nexarail_settlement.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/settlement/v1/settlements/99999" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_settlement.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — settlement not found (expected)"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Settlements by Merchant ---
echo "--- 4. Settlements by Merchant (empty → empty array expected) ---"
RESP=$(curl -s -o /tmp/nexarail_settlement.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/settlement/v1/settlements/merchant/nexa1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs3n84y" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_settlement.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not query settlements by merchant"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Settlements by Payer ---
echo "--- 5. Settlements by Payer (empty → empty array expected) ---"
RESP=$(curl -s -o /tmp/nexarail_settlement.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/settlement/v1/settlements/payer/nexa1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs3n84y" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_settlement.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not query settlements by payer"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

echo "=============================================="
echo "  Settlement queries complete."
echo "=============================================="

rm -f /tmp/nexarail_settlement.txt
