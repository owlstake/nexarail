#!/usr/bin/env bash
set -euo pipefail

# Query payout module: params, list, detail, filtered lookups, existence check, batch operations.

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
echo "  Nexarail Payout Queries"
echo "  Base URL: $API_BASE_URL"
echo "=============================================="
echo ""

# --- Payout Params ---
echo "--- 1. Payout Params ---"
RESP=$(curl -s -o /tmp/nexarail_payout.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/payout/v1/params" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_payout.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not fetch payout params"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Payout List ---
echo "--- 2. Payout List ---"
RESP=$(curl -s -o /tmp/nexarail_payout.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/payout/v1/payouts" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_payout.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not fetch payout list"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Payout Detail (non-existent) ---
echo "--- 3. Payout Detail (ID: non-existent) ---"
RESP=$(curl -s -o /tmp/nexarail_payout.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/payout/v1/payouts/99999" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_payout.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — payout not found (expected)"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Payout by Merchant ---
echo "--- 4. Payout by Merchant (empty → empty array expected) ---"
RESP=$(curl -s -o /tmp/nexarail_payout.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/payout/v1/payouts/merchant/nexa1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs3n84y" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_payout.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not query payout by merchant"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Payout by Recipient ---
echo "--- 5. Payout by Recipient (empty → empty array expected) ---"
RESP=$(curl -s -o /tmp/nexarail_payout.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/payout/v1/payouts/recipient/nexa1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs3n84y" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_payout.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not query payout by recipient"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Payout by Initiator ---
echo "--- 6. Payout by Initiator (empty → empty array expected) ---"
RESP=$(curl -s -o /tmp/nexarail_payout.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/payout/v1/payouts/initiator/nexa1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs3n84y" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_payout.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not query payout by initiator"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Payout Exists (non-existent) ---
echo "--- 7. Payout Exists (non-existent → false expected) ---"
RESP=$(curl -s -o /tmp/nexarail_payout.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/payout/v1/payouts/exists/99999" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_payout.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not check payout existence"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Batch Payout Detail (non-existent) ---
echo "--- 8. Batch Payout Detail (non-existent ID) ---"
RESP=$(curl -s -o /tmp/nexarail_payout.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/payout/v1/batch_payouts/99999" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_payout.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — batch payout not found (expected)"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Batch Payouts ---
echo "--- 9. Batch Payouts List ---"
RESP=$(curl -s -o /tmp/nexarail_payout.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/payout/v1/batch_payouts" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_payout.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not fetch batch payouts"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

echo "=============================================="
echo "  Payout queries complete."
echo "=============================================="

rm -f /tmp/nexarail_payout.txt
