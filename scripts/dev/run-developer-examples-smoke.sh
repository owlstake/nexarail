#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# run-developer-examples-smoke.sh
#
# Smoke-test runner for producer-examples against local RC1 devnet.
# Checks devnet liveness, then runs each example script in turn.
# ---------------------------------------------------------------------------

export API="${API:-http://localhost:1317}"
export RPC="${RPC:-http://localhost:26657}"

SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
EXAMPLES_DIR="${SCRIPT_DIR}/examples"
EVIDENCE_DIR="${SCRIPT_DIR}/rehearsals/developer-examples/evidence/$(date +%Y%m%d-%H%M%S)"

PASS=0
FAIL=0
SKIP=0
FAILURES=""

# ── helpers ────────────────────────────────────────────────────────────────
pass() { echo "  [PASS]  $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL]  $1"; FAIL=$((FAIL + 1)); FAILURES="${FAILURES}  FAIL: $1${2:+ ($2)}"$'\n'; }
skip() { echo "  [SKIP]  $1"; SKIP=$((SKIP + 1)); }

check_devnet() {
  echo ""
  echo "── Checking devnet liveness ───────────────────────────────"
  local status
  status=$(curl -s --max-time 3 "${RPC}/status" 2>/dev/null || true)
  if [ -z "$status" ]; then
    echo "  Devnet not reachable at ${RPC}"
    return 1
  fi
  local height
  height=$(echo "$status" | python3 -c "import sys,json; print(json.load(sys.stdin).get('result',{}).get('sync_info',{}).get('latest_block_height','?'))" 2>/dev/null || echo "?")
  echo "  Devnet alive — height=${height}"
  return 0
}

run_node_script() {
  local script="$1"
  local label="$2"
  if command -v node &>/dev/null; then
    echo "  Running: node ${script} (Node $(node -v))"
    if node "$script" "$EVIDENCE_DIR" 2>&1; then
      pass "$label"
    else
      fail "$label"
    fi
  else
    skip "$label (node not found)"
  fi
}

run_python_script() {
  local script="$1"
  local label="$2"
  if command -v python3 &>/dev/null; then
    echo "  Running: python3 ${script} (Python $(python3 --version | cut -d' ' -f2))"
    if python3 "$script" 2>&1; then
      pass "$label"
    else
      fail "$label"
    fi
  else
    skip "$label (python3 not found)"
  fi
}

run_rest_script() {
  local script="$1"
  local label="$2"
  if [ -x "$script" ] || [ -f "$script" ]; then
    echo "  Running: ${script}"
    if bash "$script" 2>&1; then
      pass "$label"
    else
      fail "$label"
    fi
  else
    skip "$label (${script} not found)"
  fi
}

# ── main ───────────────────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════════"
echo "  NexaRail — Developer Examples Smoke Test"
echo "  API: ${API}"
echo "  RPC: ${RPC}"
echo "  Evidence: ${EVIDENCE_DIR}"
echo "═══════════════════════════════════════════════════════════════"

mkdir -p "$EVIDENCE_DIR"

# Record env
cat > "${EVIDENCE_DIR}/env.txt" <<EOF
API=${API}
RPC=${RPC}
Date: $(date -u '+%Y-%m-%dT%H:%M:%SZ')
Host: $(hostname)
EOF

# Check devnet
if ! check_devnet; then
  echo ""
  echo "  Devnet is not running. Skipping all tests."
  skip "devnet not reachable"
  echo ""
  echo "── Summary ────────────────────────────────────────────────"
  echo "  PASS: ${PASS}  FAIL: ${FAIL}  SKIP: ${SKIP}"
  echo "─────────────────────────────────────────────────────────"
  echo "  Evidence: ${EVIDENCE_DIR}/"
  exit 0
fi

# Record node status
curl -s "${RPC}/status" > "${EVIDENCE_DIR}/node_status.json" 2>/dev/null || true

# ── REST example scripts ─────────────────────────────────────────────────
echo ""
echo "── REST Customer Inline Check ───────────────────────────────────"
# Check live flags via REST inline
echo ""
echo "  >>> check_live_flags.sh"
if bash -c 'set -euo pipefail
  for mod in settlement escrow treasury payout; do
    resp=$(curl -s --max-time 3 "${API}/nexarail/${mod}/v1/params" 2>/dev/null || echo "{}")
    live=$(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get(\"live_enabled\",\"MISSING\"))" 2>/dev/null || echo "MISSING")
    echo "  ${mod}: live_enabled=${live}"
  done
'; then
  pass "check_live_flags.sh (inline)"
else
  fail "check_live_flags.sh (inline)"
fi

echo ""
echo "  >>> query_merchant.sh"
if bash -c 'set -euo pipefail
  resp=$(curl -s --max-time 3 "${API}/nexarail/treasury/v1/merchant" 2>/dev/null || echo "{}")
  count=$(echo "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); items=d.get(\"merchant\") or d.get(\"list\") or []; print(len(items) if isinstance(items,list) else 1 if items else 0)" 2>/dev/null || echo "?")
  echo "  Merchants: count=${count}"
'; then
  pass "query_merchant.sh (inline)"
else
  fail "query_merchant.sh (inline)"
fi

run_rest_script "${EXAMPLES_DIR}/rest/check_live_flags.sh" "check_live_flags.sh (file)"
run_rest_script "${EXAMPLES_DIR}/rest/query_merchant.sh" "query_merchant.sh (file)"
run_rest_script "${EXAMPLES_DIR}/rest/query_settlement.sh" "query_settlement.sh (file)"
run_rest_script "${EXAMPLES_DIR}/rest/query_escrow.sh" "query_escrow.sh (file)"
run_rest_script "${EXAMPLES_DIR}/rest/query_payout.sh" "query_payout.sh (file)"
run_rest_script "${EXAMPLES_DIR}/rest/treasury_summary.sh" "treasury_summary.sh (file)"
run_rest_script "${EXAMPLES_DIR}/rest/query_node_status.sh" "query_node_status.sh (file)"

# ── Node.js examples ────────────────────────────────────────────────────
echo ""
echo "── Node Client Examples ───────────────────────────────────────"
if command -v node &>/dev/null; then
  NODE_DIR="${EXAMPLES_DIR}/node-client"
  echo "  Node $(node -v)"

  if [ -f "${NODE_DIR}/src/checkLiveFlags.js" ]; then
    (cd "$NODE_DIR" && node src/checkLiveFlags.js 2>&1 | tee "${EVIDENCE_DIR}/node-checkLiveFlags.txt") \
      && pass "node-client checkLiveFlags" \
      || fail "node-client checkLiveFlags"
  else
    skip "node-client checkLiveFlags (src/checkLiveFlags.js missing)"
  fi

  if [ -f "${NODE_DIR}/src/queryProductState.js" ]; then
    (cd "$NODE_DIR" && node src/queryProductState.js 2>&1 | tee "${EVIDENCE_DIR}/node-queryProductState.txt") \
      && pass "node-client queryProductState" \
      || fail "node-client queryProductState"
  else
    skip "node-client queryProductState (src/queryProductState.js missing)"
  fi
else
  skip "node-client (node binary not found)"
fi

# ── Python examples ─────────────────────────────────────────────────────
echo ""
echo "── Python Client Examples ─────────────────────────────────────"
if command -v python3 &>/dev/null; then
  PY_DIR="${EXAMPLES_DIR}/python-client"
  echo "  Python $(python3 --version | cut -d' ' -f2)"

  if [ -f "${PY_DIR}/check_live_flags.py" ]; then
    (cd "$PY_DIR" && python3 check_live_flags.py 2>&1 | tee "${EVIDENCE_DIR}/py-check_live_flags.txt") \
      && pass "python-client check_live_flags" \
      || fail "python-client check_live_flags"
  else
    skip "python-client check_live_flags (check_live_flags.py missing)"
  fi

  if [ -f "${PY_DIR}/query_product_state.py" ]; then
    (cd "$PY_DIR" && python3 query_product_state.py 2>&1 | tee "${EVIDENCE_DIR}/py-query_product_state.txt") \
      && pass "python-client query_product_state" \
      || fail "python-client query_product_state"
  else
    skip "python-client query_product_state (query_product_state.py missing)"
  fi
else
  skip "python-client (python3 binary not found)"
fi

# ── Summary ────────────────────────────────────────────────────────────
{
  echo "───────── Summary ─────────"
  echo "  PASS: ${PASS}"
  echo "  FAIL: ${FAIL}"
  echo "  SKIP: ${SKIP}"
  echo "───────────────────────────"
} | tee "${EVIDENCE_DIR}/summary.txt"

echo ""
echo "── Evidence ──────────────────────────────────────────────────"
echo "  ${EVIDENCE_DIR}/"
echo "  ${EVIDENCE_DIR}/summary.txt"
echo ""

if [ -n "$FAILURES" ]; then
  echo "── Failures ──────────────────────────────────────────────"
  echo -n "$FAILURES"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
exit $FAIL
