#!/usr/bin/env bash
set -euo pipefail

# Query escrow module: params, list, detail, filtered lookups, and existence check.

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
echo "  Nexarail Escrow Queries"
echo "  Base URL: $API_BASE_URL"
echo "=============================================="
echo ""

# --- Escrow Params ---
echo "--- 1. Escrow Params ---"
RESP=$(curl -s -o /tmp/nexarail_escrow.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/escrow/v1/params" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_escrow.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not fetch escrow params"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Escrow List ---
echo "--- 2. Escrow List ---"
RESP=$(curl -s -o /tmp/nexarail_escrow.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/escrow/v1/escrows" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_escrow.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not fetch escrow list"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Escrow Detail (non-existent) ---
echo "--- 3. Escrow Detail (ID: non-existent) ---"
RESP=$(curl -s -o /tmp/nexarail_escrow.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/escrow/v1/escrows/99999" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_escrow.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — escrow not found (expected)"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Escrow by Buyer ---
echo "--- 4. Escrow by Buyer (empty → empty array expected) ---"
RESP=$(curl -s -o /tmp/nexarail_escrow.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/escrow/v1/escrows/buyer/nexa1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs3n84y" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_escrow.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not query escrow by buyer"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Escrow by Seller ---
echo "--- 5. Escrow by Seller (empty → empty array expected) ---"
RESP=$(curl -s -o /tmp/nexarail_escrow.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/escrow/v1/escrows/seller/nexa1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs3n84y" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_escrow.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not query escrow by seller"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Escrow by Merchant ---
echo "--- 6. Escrow by Merchant (empty → empty array expected) ---"
RESP=$(curl -s -o /tmp/nexarail_escrow.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/escrow/v1/escrows/merchant/nexa1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs3n84y" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_escrow.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not query escrow by merchant"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Escrow Exists (non-existent) ---
echo "--- 7. Escrow Exists (non-existent → false expected) ---"
RESP=$(curl -s -o /tmp/nexarail_escrow.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/escrow/v1/escrows/exists/99999" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_escrow.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not check escrow existence"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

echo "=============================================="
echo "  Escrow queries complete."
echo "=============================================="

rm -f /tmp/nexarail_escrow.txt
