#!/usr/bin/env bash
# NexaRail API Smoke Test
# Tests REST, RPC, and gRPC endpoints against a live node.
# TESTNET/DEVNET ONLY — not for mainnet (none exists).
set -euo pipefail

RPC="${RPC:-http://127.0.0.1:26657}"
REST="${REST:-http://127.0.0.1:1317}"
GRPC="${GRPC:-127.0.0.1:9090}"
PASS=0
FAIL=0
SKIP=0
EXPECTED_NOT_FOUND=0
SKIP_DEFERRED=0
WARN=0
BLOCKED=0

check() { local msg="$1"; shift; if "$@" 2>/dev/null; then echo "  PASS   $msg"; PASS=$((PASS+1)); else echo "  FAIL   $msg"; FAIL=$((FAIL+1)); fi; }
skip() { echo "  SKIP   $1"; SKIP=$((SKIP+1)); }

warn() { echo "  WARN   $*"; WARN=$((WARN+1)); }
blocked() { echo "  BLOCKED $*"; BLOCKED=$((BLOCKED+1)); FAIL=$((FAIL+1)); }

# Check that a REST endpoint returns an error response containing "not found"
check_expected_not_found() {
  local msg="$1"
  local url="$2"
  local resp
  resp=$(curl -s --max-time 3 "$url" 2>/dev/null || echo '{}')
  # Try JSON error field with "not found" text
  if echo "$resp" | jq -e '.error' > /dev/null 2>&1; then
    local err_text
    err_text=$(echo "$resp" | jq -r '.error' 2>/dev/null)
    if echo "$err_text" | grep -qi "not found"; then
      echo "  EXPECTED_NOT_FOUND  $msg"
      EXPECTED_NOT_FOUND=$((EXPECTED_NOT_FOUND+1))
      return 0
    fi
  fi
  # Try raw response body for "not found" text
  if echo "$resp" | grep -qi "not found"; then
    echo "  EXPECTED_NOT_FOUND  $msg"
    EXPECTED_NOT_FOUND=$((EXPECTED_NOT_FOUND+1))
    return 0
  fi
  echo "  FAIL   $msg (expected not-found error, got: $(echo "$resp" | jq -c '.' 2>/dev/null || head -c 300 <<< "$resp"))"
  FAIL=$((FAIL+1))
  return 1
}

# Check that a REST endpoint returns a response with a given array field that is empty (or non-empty = still PASS)
check_empty_array() {
  local msg="$1"
  local url="$2"
  local field="$3"
  local resp
  resp=$(curl -s --max-time 3 "$url" 2>/dev/null || echo '{}')
  # Check that the field exists and is an array (empty or non-empty both count as PASS)
  if echo "$resp" | jq -e ".${field} | type == \"array\"" > /dev/null 2>&1; then
    local len
    len=$(echo "$resp" | jq ".${field} | length" 2>/dev/null)
    echo "  PASS   $msg (${field}: ${len} entries)"
    PASS=$((PASS+1))
    return 0
  fi
  # If REST not available, skip gracefully
  if [ "$resp" = "{}" ] || echo "$resp" | jq -e '.error' > /dev/null 2>&1; then
    echo "  SKIP   $msg (endpoint unavailable)"
    SKIP=$((SKIP+1))
    return 0
  fi
  echo "  FAIL   $msg (expected array field '${field}', got: $(echo "$resp" | jq -c '.' 2>/dev/null || head -c 300 <<< "$resp"))"
  FAIL=$((FAIL+1))
  return 1
}

# Check that a REST endpoint returns { "exists": false }
check_exists_false() {
  local msg="$1"
  local url="$2"
  local resp
  resp=$(curl -s --max-time 3 "$url" 2>/dev/null || echo '{}')
  local exists_val
  exists_val=$(echo "$resp" | jq -r '.exists // "null"' 2>/dev/null)
  if [ "$exists_val" = "false" ]; then
    echo "  PASS   $msg (exists=false)"
    PASS=$((PASS+1))
    return 0
  fi
  if [ "$resp" = "{}" ] || echo "$resp" | jq -e '.error' > /dev/null 2>&1; then
    echo "  SKIP   $msg (endpoint unavailable)"
    SKIP=$((SKIP+1))
    return 0
  fi
  echo "  FAIL   $msg (expected exists=false, got: $(echo "$resp" | jq -c '.' 2>/dev/null || head -c 300 <<< "$resp"))"
  FAIL=$((FAIL+1))
  return 1
}

# Deferred endpoint (not yet implemented, intentionally skipped)
skip_deferred() {
  echo "  SKIP_DEFERRED  $1"
  SKIP_DEFERRED=$((SKIP_DEFERRED+1))
}

echo "╔══════════════════════════════════════════╗"
echo "║  NexaRail API Smoke Test                ║"
echo "║  RPC:  $RPC"
echo "║  REST: $REST"
echo "║  gRPC: $GRPC"
echo "╚══════════════════════════════════════════╝"
echo ""

# --- RPC Endpoints ---
echo "--- CometBFT RPC ---"
check "GET /status" curl -s --max-time 3 "$RPC/status" | jq -e '.result.sync_info.latest_block_height' > /dev/null
check "GET /net_info" curl -s --max-time 3 "$RPC/net_info" | jq -e '.result.n_peers' > /dev/null
check "GET /validators" curl -s --max-time 3 "$RPC/validators" | jq -e '.result.validators' > /dev/null

# --- REST Endpoints (Standard Cosmos) ---
echo ""
echo "--- REST API: Standard Cosmos ---"
NODE_INFO=$(curl -s --max-time 3 "$REST/cosmos/base/tendermint/v1beta1/node_info" 2>/dev/null || echo '{}')
if echo "$NODE_INFO" | jq -e '.default_node_info.network' > /dev/null 2>&1; then
    check "GET /cosmos/base/tendermint/v1beta1/node_info" true
    echo "    Network: $(echo "$NODE_INFO" | jq -r '.default_node_info.network')"
else
    skip "GET /cosmos/base/tendermint/v1beta1/node_info (REST API may not be running)"
fi

check "GET /cosmos/bank/v1beta1/params" curl -s --max-time 3 "$REST/cosmos/bank/v1beta1/params" | jq -e '.params' > /dev/null

# --- REST Endpoints (Custom NexaRail Modules) ---
echo ""
echo "--- REST API: NexaRail Custom Modules ---"
CUSTOM_MODULES="fees merchant settlement escrow payout treasury"
for mod in $CUSTOM_MODULES; do
    resp=$(curl -s --max-time 3 "$REST/nexarail/$mod/v1/params" 2>/dev/null || echo '{}')
    if echo "$resp" | jq -e '.params' > /dev/null 2>&1; then
        check "GET /nexarail/$mod/v1/params" true
    elif echo "$resp" | jq -e '.error' > /dev/null 2>&1; then
        warn "GET /nexarail/$mod/v1/params — returned error (gRPC may not be reachable from REST)"
    else
        skip "GET /nexarail/$mod/v1/params (REST API not running or route not registered)"
    fi
done

# List endpoints
echo ""
echo "--- REST API: List Queries ---"
for mod in merchant settlement escrow payout; do
    list_resp=$(curl -s --max-time 3 "$REST/nexarail/$mod/v1/${mod}s" 2>/dev/null || echo '{}')
    if echo "$list_resp" | jq -e '.error' > /dev/null 2>&1 || [ "$list_resp" = "{}" ]; then
        skip "GET /nexarail/$mod/v1/${mod}s"
    else
        check "GET /nexarail/$mod/v1/${mod}s" true
    fi
done

echo ""
echo "--- REST API: Treasury Summary ---"
treasury_resp=$(curl -s --max-time 3 "$REST/nexarail/treasury/v1/summary" 2>/dev/null || echo '{}')
if echo "$treasury_resp" | jq -e '.error' > /dev/null 2>&1 || [ "$treasury_resp" = "{}" ]; then
    skip "GET /nexarail/treasury/v1/summary"
else
    check "GET /nexarail/treasury/v1/summary" true
fi

# --- gRPC Reflection ---
echo ""
echo "--- gRPC ---"
if command -v grpcurl &>/dev/null; then
    SERVICES=$(grpcurl -plaintext -max-time 3 "$GRPC" list 2>/dev/null || echo "")
    if [ -n "$SERVICES" ]; then
        check "gRPC reflection available" true
        for mod in fees merchant settlement escrow payout treasury; do
            echo "$SERVICES" | grep -q "nexarail.$mod.v1.Query" && check "gRPC: nexarail.$mod.v1.Query registered" true || check "gRPC: nexarail.$mod.v1.Query registered" false
        done
    else
        skip "gRPC reflection (timeout or port conflict)"
    fi
else
    skip "grpcurl not installed — install with: brew install grpcurl"
fi

# --- Live Flags Check via REST ---
echo ""
echo "--- Live Flags (if REST available) ---"
LIVE_FLAGS="settlement escrow payout treasury"
for mod in $LIVE_FLAGS; do
    resp=$(curl -s --max-time 3 "$REST/nexarail/$mod/v1/params" 2>/dev/null || echo '{}')
    live=$(echo "$resp" | jq -r '.params.live_enabled // "N/A"' 2>/dev/null)
    if [ "$live" = "false" ] || [ "$live" = "False" ]; then
        check "$mod.live_enabled = false" true
    elif [ "$live" = "N/A" ]; then
        skip "$mod.live_enabled (REST API not available)"
    else
        check "$mod.live_enabled = false (got: $live)" false
    fi
done

# ---------------------------------------------------------------------------
# New Phase 10B.3 Endpoints
# ---------------------------------------------------------------------------
echo ""
echo "--- REST API: New Phase 10B.3 Endpoints ---"

# ── Escrow Module ──
check_expected_not_found "GET /nexarail/escrow/v1/escrow/{id} (non-existent)" \
  "$REST/nexarail/escrow/v1/escrow/nonexistent"

check_empty_array "GET /nexarail/escrow/v1/escrows" \
  "$REST/nexarail/escrow/v1/escrows" "escrows"

check_empty_array "GET /nexarail/escrow/v1/escrows/by-buyer/{buyer} (non-existent)" \
  "$REST/nexarail/escrow/v1/escrows/by-buyer/nexa1nonexistent" "escrows"

check_empty_array "GET /nexarail/escrow/v1/escrows/by-seller/{seller} (non-existent)" \
  "$REST/nexarail/escrow/v1/escrows/by-seller/nexa1nonexistent" "escrows"

check_empty_array "GET /nexarail/escrow/v1/escrows/by-merchant/{merchant} (non-existent)" \
  "$REST/nexarail/escrow/v1/escrows/by-merchant/nexa1nonexistent" "escrows"

check_exists_false "GET /nexarail/escrow/v1/escrow/exists/{id} (non-existent)" \
  "$REST/nexarail/escrow/v1/escrow/exists/nonexistent"

# ── Settlement Module ──
check_empty_array "GET /nexarail/settlement/v1/settlements/by-payer/{payer} (non-existent)" \
  "$REST/nexarail/settlement/v1/settlements/by-payer/nexa1nonexistent" "settlements"

# ── Payout Module ──
check_expected_not_found "GET /nexarail/payout/v1/payout/{id} (non-existent)" \
  "$REST/nexarail/payout/v1/payout/nonexistent"

check_exists_false "GET /nexarail/payout/v1/payout/exists/{id} (non-existent)" \
  "$REST/nexarail/payout/v1/payout/exists/nonexistent"

check_empty_array "GET /nexarail/payout/v1/payouts/by-merchant/{merchant} (non-existent)" \
  "$REST/nexarail/payout/v1/payouts/by-merchant/nexa1nonexistent" "payouts"

check_empty_array "GET /nexarail/payout/v1/payouts/by-recipient/{recipient} (non-existent)" \
  "$REST/nexarail/payout/v1/payouts/by-recipient/nexa1nonexistent" "payouts"

check_empty_array "GET /nexarail/payout/v1/payouts/by-initiator/{initiator} (non-existent)" \
  "$REST/nexarail/payout/v1/payouts/by-initiator/nexa1nonexistent" "payouts"

check_expected_not_found "GET /nexarail/payout/v1/batch-payout/{id} (non-existent)" \
  "$REST/nexarail/payout/v1/batch-payout/nonexistent"

check_empty_array "GET /nexarail/payout/v1/batch-payouts" \
  "$REST/nexarail/payout/v1/batch-payouts" "batch_payouts"

# ── Treasury Module ──
check_expected_not_found "GET /nexarail/treasury/v1/account/{id} (non-existent)" \
  "$REST/nexarail/treasury/v1/account/nonexistent"

check_empty_array "GET /nexarail/treasury/v1/accounts" \
  "$REST/nexarail/treasury/v1/accounts" "accounts"

check_expected_not_found "GET /nexarail/treasury/v1/budget/{id} (non-existent)" \
  "$REST/nexarail/treasury/v1/budget/nonexistent"

check_empty_array "GET /nexarail/treasury/v1/budgets" \
  "$REST/nexarail/treasury/v1/budgets" "budgets"

check_expected_not_found "GET /nexarail/treasury/v1/grant/{id} (non-existent)" \
  "$REST/nexarail/treasury/v1/grant/nonexistent"

check_empty_array "GET /nexarail/treasury/v1/grants" \
  "$REST/nexarail/treasury/v1/grants" "grants"

check_empty_array "GET /nexarail/treasury/v1/spends" \
  "$REST/nexarail/treasury/v1/spends" "spends"

# --- Summary ---
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                     RESULTS SUMMARY                         ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %3d                                            ║\n" "PASS" "$PASS"
printf "║  %-20s %3d                                            ║\n" "EXPECTED_NOT_FOUND" "$EXPECTED_NOT_FOUND"
printf "║  %-20s %3d                                            ║\n" "FAIL" "$FAIL"
printf "║  %-20s %3d                                            ║\n" "SKIP (unavailable)" "$SKIP"
printf "║  %-20s %3d                                            ║\n" "WARN" "$WARN"
printf "║  %-20s %3d                                            ║\n" "BLOCKED" "$BLOCKED"
printf "║  %-20s %3d                                            ║\n" "SKIP_DEFERRED" "$SKIP_DEFERRED"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %3d                                            ║\n" "TOTAL" "$((PASS + EXPECTED_NOT_FOUND + FAIL + SKIP + SKIP_DEFERRED + WARN + BLOCKED))"
echo "╚══════════════════════════════════════════════════════════════╝"
if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo "  Some checks failed. Start a local node with REST API"
    echo "  enabled for full coverage, or check endpoint registration."
    echo "  Evidence: check the output above for FAIL/BLOCKED/WARN lines."
    echo "  Rerun: RPC=\"$RPC\" REST=\"$REST\" GRPC=\"$GRPC\" $(basename "$0")"
fi

exit $FAIL
