#!/usr/bin/env bash
set -euo pipefail

# Query treasury module: params, summary, and all sub-resources.

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
echo "  Nexarail Treasury Queries"
echo "  Base URL: $API_BASE_URL"
echo "=============================================="
echo ""

# --- Treasury Params ---
echo "--- 1. Treasury Params ---"
RESP=$(curl -s -o /tmp/nexarail_treasury.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/treasury/v1/params" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_treasury.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not fetch treasury params"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Treasury Summary ---
echo "--- 2. Treasury Summary ---"
RESP=$(curl -s -o /tmp/nexarail_treasury.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/treasury/v1/summary" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_treasury.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not fetch treasury summary"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Treasury Account Detail (non-existent) ---
echo "--- 3. Treasury Account Detail (non-existent address) ---"
RESP=$(curl -s -o /tmp/nexarail_treasury.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/treasury/v1/accounts/nexa1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs3n84y" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_treasury.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — account not found (expected)"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Treasury Accounts ---
echo "--- 4. Treasury Accounts List ---"
RESP=$(curl -s -o /tmp/nexarail_treasury.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/treasury/v1/accounts" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_treasury.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not fetch treasury accounts"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Treasury Budget Detail (non-existent) ---
echo "--- 5. Treasury Budget Detail (non-existent ID) ---"
RESP=$(curl -s -o /tmp/nexarail_treasury.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/treasury/v1/budgets/99999" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_treasury.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — budget not found (expected)"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Treasury Budgets ---
echo "--- 6. Treasury Budgets List ---"
RESP=$(curl -s -o /tmp/nexarail_treasury.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/treasury/v1/budgets" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_treasury.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not fetch treasury budgets"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Treasury Grant Detail (non-existent) ---
echo "--- 7. Treasury Grant Detail (non-existent ID) ---"
RESP=$(curl -s -o /tmp/nexarail_treasury.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/treasury/v1/grants/99999" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_treasury.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — grant not found (expected)"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Treasury Grants ---
echo "--- 8. Treasury Grants List ---"
RESP=$(curl -s -o /tmp/nexarail_treasury.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/treasury/v1/grants" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_treasury.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not fetch treasury grants"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Treasury Spend Detail (non-existent) ---
echo "--- 9. Treasury Spend Detail (non-existent ID) ---"
RESP=$(curl -s -o /tmp/nexarail_treasury.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/treasury/v1/spends/99999" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_treasury.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — spend not found (expected)"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

# --- Treasury Spends ---
echo "--- 10. Treasury Spends List ---"
RESP=$(curl -s -o /tmp/nexarail_treasury.txt -w "%{http_code}" "${API_BASE_URL}/nexarail/treasury/v1/spends" 2>/dev/null || echo "000")
BODY=$(cat /tmp/nexarail_treasury.txt 2>/dev/null || true)
if [ "$RESP" = "200" ]; then
  _fmt "$BODY"
else
  echo "  HTTP $RESP — could not fetch treasury spends"
  echo "  Body: $(echo "$BODY" | head -c 300)"
fi
echo ""

echo "=============================================="
echo "  Treasury queries complete."
echo "=============================================="

rm -f /tmp/nexarail_treasury.txt
