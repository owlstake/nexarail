#!/usr/bin/env bash
set -euo pipefail

# Query merchant module: params, list, and detail.

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
echo "  Nexarail Merchant Queries"
echo "  Base URL: $API_BASE_URL"
echo "=============================================="
echo ""

# --- Merchant Params ---
echo "--- 1. Merchant Params ---"
RESP=$(curl -s -o /tmp/nexarail_merchant.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/merchant/v1/params" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_merchant.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not fetch merchant params"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Merchant List ---
echo "--- 2. Merchant List ---"
RESP=$(curl -s -o /tmp/nexarail_merchant.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/merchant/v1/merchants" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_merchant.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not fetch merchant list"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Merchant Detail ---
echo "--- 3. Merchant Detail (by address — replace with real address if known) ---"
# Use a placeholder address; on an unseeded devnet this will return not-found.
MERCHANT_ADDR="${MERCHANT_ADDR:-nexa1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs3n84y}"
RESP=$(curl -s -o /tmp/nexarail_merchant.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/merchant/v1/merchants/${MERCHANT_ADDR}" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_merchant.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — merchant not found or query failed"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

echo "=============================================="
echo "  Merchant queries complete."
echo "=============================================="

rm -f /tmp/nexarail_merchant.txt
