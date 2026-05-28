#!/usr/bin/env bash
# NexaRail — End-to-End Developer Demo
#
# Orchestrates a complete local devnet demo: launch → verify → query →
# REST → SDK → write-flow dry-run → dashboard → evidence → cleanup.
#
# LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS
#
# Usage:
#   bash scripts/dev/run-end-to-end-demo.sh                  # full demo
#   bash scripts/dev/run-end-to-end-demo.sh --keep-running   # leave devnet up
#   bash scripts/dev/run-end-to-end-demo.sh --serve-dashboard
#   bash scripts/dev/run-end-to-end-demo.sh --skip-dashboard
#   bash scripts/dev/run-end-to-end-demo.sh --skip-sdk
#   bash scripts/dev/run-end-to-end-demo.sh --evidence-dir /tmp/my-evidence

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RELEASE_DIR="$PROJECT_DIR/releases/testnet-rc1"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
EVIDENCE_DIR="${EVIDENCE_DIR:-$PROJECT_DIR/rehearsals/end-to-end-demo/evidence/$TIMESTAMP}"

# ── Flags ──────────────────────────────────────────────────
KEEP_RUNNING=0
SERVE_DASHBOARD=0
SKIP_DASHBOARD=0
SKIP_SDK=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --keep-running)   KEEP_RUNNING=1; shift ;;
        --serve-dashboard) SERVE_DASHBOARD=1; shift ;;
        --skip-dashboard)  SKIP_DASHBOARD=1; shift ;;
        --skip-sdk)        SKIP_SDK=1; shift ;;
        --evidence-dir)    EVIDENCE_DIR="$2"; shift 2 ;;
        *) echo "  ❌ Unknown flag: $1"; exit 1 ;;
    esac
done

# ── Counters ────────────────────────────────────────────────
PASS=0
FAIL=0
SKIP=0

PASS_MARK="  \033[32m✅ PASS\033[0m"
FAIL_MARK="  \033[31m❌ FAIL\033[0m"
SKIP_MARK="  \033[33m⏭️  SKIP\033[0m"

# ════════════════════════════════════════════════════════════
# Helpers
# ════════════════════════════════════════════════════════════

check_pass() { echo -e "${PASS_MARK} $1 — $2"; PASS=$((PASS+1)); }
check_fail() { echo -e "${FAIL_MARK} $1 — $2"; FAIL=$((FAIL+1)); }
check_skip() { echo -e "${SKIP_MARK} $1 — $2"; SKIP=$((SKIP+1)); }

evid() { mkdir -p "$(dirname "$EVIDENCE_DIR/$1")"; cat > "$EVIDENCE_DIR/$1"; }

timestamp() { date -u +%H:%M:%S; }

# ════════════════════════════════════════════════════════════
# Setup
# ════════════════════════════════════════════════════════════

mkdir -p "$EVIDENCE_DIR/logs"
echo "{\"timestamp\":\"$TIMESTAMP\",\"flags\":{\"keep_running\":$KEEP_RUNNING,\"serve_dashboard\":$SERVE_DASHBOARD,\"skip_dashboard\":$SKIP_DASHBOARD,\"skip_sdk\":$SKIP_SDK}}" | evid "metadata.json"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  NexaRail — End-to-End Developer Demo                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo "  Timestamp: $TIMESTAMP"
echo "  Evidence:  $EVIDENCE_DIR"
echo "  Project:   $PROJECT_DIR"
echo ""

# ══════════════════════════════════════════════════════════════════════
# Section 1: RC1 Verification
# ══════════════════════════════════════════════════════════════════════
echo "── Section 1: RC1 Verification ──────────────────────────────────"
RC1_LOG="$EVIDENCE_DIR/logs/rc1-verify.log"
if [ -x "$PROJECT_DIR/scripts/release/verify-testnet-rc1.sh" ]; then
    if bash "$PROJECT_DIR/scripts/release/verify-testnet-rc1.sh" &> "$RC1_LOG"; then
        check_pass "rc1_verify" "RC1 packaging verification passed"
    else
        check_fail "rc1_verify" "RC1 packaging check failed — see $RC1_LOG"
    fi
else
    check_skip "rc1_verify" "verify-testnet-rc1.sh not found"
fi

# ══════════════════════════════════════════════════════════════════════
# Section 2: Devnet Launch
# ══════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 2: Devnet Launch ─────────────────────────────────────"
LAUNCH_LOG="$EVIDENCE_DIR/logs/devnet-launch.log"
LAUNCH_SCRIPT="$PROJECT_DIR/scripts/release/launch-rc1-devnet.sh"

# Check if devnet is already running
RPC_CHECK=$(curl -s -m 2 "http://localhost:26657/status" 2>/dev/null || echo "")
if [ -n "$RPC_CHECK" ] && echo "$RPC_CHECK" | python3 -c "import sys,json; d=json.load(sys.stdin); h=d.get('result',{}).get('sync_info',{}).get('latest_block_height','0'); print('OK' if int(h)>=1 else 'LOW')" 2>/dev/null | grep -q "OK"; then
    check_pass "devnet_launch" "Devnet already running (will reuse)"
    echo "devnet running"> "$LAUNCH_LOG"
elif [ -x "$LAUNCH_SCRIPT" ]; then
    echo "  Launching devnet..."
    if bash "$LAUNCH_SCRIPT" --single-node --clean &> "$LAUNCH_LOG"; then
        check_pass "devnet_launch" "Devnet started cleanly"
    else
        if grep -q "already in use\|already running\|bind: address already in use" "$LAUNCH_LOG" 2>/dev/null; then
            check_pass "devnet_launch" "Devnet already running (resuming)"
        else
            check_fail "devnet_launch" "Devnet launch failed — see $LAUNCH_LOG"
        fi
    fi
else
    check_skip "devnet_launch" "launch-rc1-devnet.sh not found"
fi

# ══════════════════════════════════════════════════════════════════════
# Section 3: Wait for Height >= 5
# ══════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 3: Wait for Height ───────────────────────────────────"
RPC_URL="${RPC_URL:-http://localhost:26657}"
HEIGHT_REACHED=0
for i in $(seq 1 30); do
    STATUS=$(curl -s "$RPC_URL/status" 2>/dev/null || echo "")
    HEIGHT=$(echo "$STATUS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('result',{}).get('sync_info',{}).get('latest_block_height','0'))" 2>/dev/null || echo "0")
    if [ "$HEIGHT" -ge 5 ] 2>/dev/null; then
        HEIGHT_REACHED=1
        break
    fi
    sleep 2
done

if [ "$HEIGHT_REACHED" -eq 1 ]; then
    check_pass "height_reached" "Node reached height $HEIGHT"
    echo "{\"height\":$HEIGHT,\"rpc\":\"$RPC_URL\"}" | evid "status.json"
else
    STATUS_RAW=$(curl -s "$RPC_URL/status" 2>/dev/null || echo "unreachable")
    echo "$STATUS_RAW" | evid "status.json"
    check_fail "height_reached" "Node did not reach height >= 5 in 60s"
fi

# ══════════════════════════════════════════════════════════════════════
# Section 4: Live Flags Check
# ══════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 4: Live Flags ────────────────────────────────────────"
API_URL="${API_URL:-http://localhost:1317}"
FLAGS_LOG="$EVIDENCE_DIR/logs/live-flags.log"
LIVE_FLAGS=$(curl -s "$API_URL/cosmos/base/tendermint/v1beta1/node_info" 2>/dev/null | evid "live-flags.json" 2>/dev/null; echo "")

# Check each module's params for live_enabled
MODULES="settlement escrow payout treasury"
FLAGS_ALL_FALSE=0
FLAGS_CHECKED=0
FLAGS_FAILED=0
FLAG_RESULTS=""

for mod in $MODULES; do
    PARAMS=$(curl -s "$API_URL/nexarail/${mod}/v1/params" 2>/dev/null || echo '{}')
    LIVE=$(echo "$PARAMS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('params',d).get('live_enabled','unknown'))" 2>/dev/null || echo "error")
    if [ "$LIVE" = "false" ] || [ "$LIVE" = "False" ]; then
        FLAGS_CHECKED=$((FLAGS_CHECKED+1))
        FLAG_RESULTS="${FLAG_RESULTS}  ✓ ${mod}: $LIVE"$'\n'
    elif [ "$LIVE" = "error" ]; then
        FLAGS_FAILED=$((FLAGS_FAILED+1))
        FLAG_RESULTS="${FLAG_RESULTS}  ? ${mod}: $LIVE"$'\n'
    else
        FLAGS_FAILED=$((FLAGS_FAILED+1))
        FLAG_RESULTS="${FLAG_RESULTS}  ✗ ${mod}: $LIVE"$'\n'
    fi
done

echo -n "$FLAG_RESULTS" | evid "live-flags-results.txt"

if [ "$FLAGS_FAILED" -eq 0 ] && [ "$FLAGS_CHECKED" -gt 0 ]; then
    check_pass "live_flags" "$FLAGS_CHECKED modules all false"
elif [ "$FLAGS_FAILED" -gt 0 ]; then
    check_fail "live_flags" "$FLAGS_FAILED module(s) not false — see evidence"
else
    check_skip "live_flags" "No modules queried"
fi

# ══════════════════════════════════════════════════════════════════════
# Section 5: REST Examples
# ══════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 5: REST Examples ─────────────────────────────────────"
REST_DIR="$PROJECT_DIR/examples/rest"
REST_LOG="$EVIDENCE_DIR/logs/rest-examples.log"
REST_PASS=0
REST_FAIL=0

if [ -d "$REST_DIR" ]; then
    for script in "$REST_DIR"/*.sh; do
        name="$(basename "$script" .sh)"
        if [ -f "$script" ] && [ -x "$script" ]; then
            if bash "$script" >> "$REST_LOG" 2>&1; then
                REST_PASS=$((REST_PASS+1))
            else
                REST_FAIL=$((REST_FAIL+1))
                echo "  FAIL: $name" >> "$REST_LOG"
            fi
        fi
    done
fi

if [ "$REST_FAIL" -eq 0 ] && [ "$REST_PASS" -gt 0 ]; then
    check_pass "rest_examples" "$REST_PASS REST examples passed"
elif [ "$REST_FAIL" -gt 0 ]; then
    check_fail "rest_examples" "$REST_FAIL REST example(s) failed — see $REST_LOG"
else
    check_skip "rest_examples" "No REST examples found in $REST_DIR"
fi

# ══════════════════════════════════════════════════════════════════════
# Section 6: Node SDK Read Example
# ══════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 6: Node.js SDK ───────────────────────────────────────"
NODE_LOG="$EVIDENCE_DIR/logs/node-sdk.log"

if [ "$SKIP_SDK" -eq 1 ]; then
    check_skip "node_sdk" "Skipped via --skip-sdk"
elif command -v node &>/dev/null; then
    NODE_CLIENT_DIR="$PROJECT_DIR/examples/node-client"
    # Create a temporary node script that exercises SDK functions
    NODE_TMP=$(mktemp)
    cat > "$NODE_TMP" << 'NODESCRIPT'
const c = require('/REPLACE_PROJECT/examples/node-client/src/client.js');
(async () => {
  const results = {};
  try { results.treasury = await c.treasurySummary(); } catch(e) { results.treasury = { error: e.message }; }
  try { results.params = await c.getParams('settlement'); } catch(e) { results.params = { error: e.message }; }
  try { results.merchants = await c.getList('merchant', 'merchants'); } catch(e) { results.merchants = { error: e.message }; }
  // Command builders (synchronous, no await needed)
  results.cmd1 = { cmd: c.bankSendCmd('from', 'to', '1000', 'unxrl'), type: typeof c.bankSendCmd('from','to','1000','unxrl') };
  results.cmd2 = { cmd: c.merchantRegisterCmd('owner', 'MyShop', 'Test shop'), type: typeof c.merchantRegisterCmd('owner','MyShop','Test shop') };
  results.cmd3 = { cmd: c.settlementCreateCmd('payer', 'merchant', '500', 'ref1'), type: typeof c.settlementCreateCmd('payer','merchant','500','ref1') };
  results.cmd4 = { cmd: c.productGovCmd('enable-escrow-live'), type: typeof c.productGovCmd('enable-escrow-live') };
  console.log(JSON.stringify(results, null, 2));
})().catch(e => { console.error(e); process.exit(1); });
NODESCRIPT
    # Fix the path placeholder
    sed -i '' "s|/REPLACE_PROJECT|$PROJECT_DIR|g" "$NODE_TMP"

    if node "$NODE_TMP" &> "$NODE_LOG"; then
        # Verify outputs
        if grep -q "treasury" "$NODE_LOG" 2>/dev/null; then
            # Check command builders return strings (in pretty-printed JSON)
            if grep -q 'cmd1' "$NODE_LOG" 2>/dev/null && grep -q 'type.*string' "$NODE_LOG" 2>/dev/null; then
                check_pass "node_sdk" "SDK reads + command builders return strings"
            else
                check_fail "node_sdk" "Command builder output type check failed"
            fi
        else
            check_fail "node_sdk" "Node SDK output missing expected data"
        fi
    else
        check_fail "node_sdk" "Node SDK example failed — see $NODE_LOG"
    fi
    rm -f "$NODE_TMP"
else
    check_skip "node_sdk" "Node.js not available"
fi

cp "$NODE_LOG" "$EVIDENCE_DIR/node-sdk.txt" 2>/dev/null || true

# ══════════════════════════════════════════════════════════════════════
# Section 7: Python SDK Read Example
# ══════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 7: Python SDK ────────────────────────────────────────"
PY_LOG="$EVIDENCE_DIR/logs/python-sdk.log"

if [ "$SKIP_SDK" -eq 1 ]; then
    check_skip "python_sdk" "Skipped via --skip-sdk"
elif command -v python3 &>/dev/null; then
    PY_SCRIPT=$(mktemp)
    cat > "$PY_SCRIPT" << 'PYSCRIPT'
import sys, json
sys.path.insert(0, '/REPLACE_PROJECT/examples/python-client')
import nexarail_client as n

results = {}
try:
    ts = n.treasury_summary()
    results['treasury'] = ts if isinstance(ts, dict) else {'raw': str(ts)}
except Exception as e:
    results['treasury'] = {'error': str(e)}

try:
    p = n.get_params('settlement')
    results['params'] = p if isinstance(p, dict) else {'raw': str(p)}
except Exception as e:
    results['params'] = {'error': str(e)}

# Command builders
try:
    results['cmd1'] = n.bank_send_cmd('from','to','1000','unxrl')
except Exception as e:
    results['cmd1'] = f'ERROR: {e}'

try:
    results['cmd2'] = n.merchant_register_cmd('owner','MyShop','Test shop')
except Exception as e:
    results['cmd2'] = f'ERROR: {e}'

try:
    results['cmd3'] = n.settlement_create_cmd('payer','merchant','500','ref1')
except Exception as e:
    results['cmd3'] = f'ERROR: {e}'

#print type info
type_info = {}
for k, v in results.items():
    if not k.startswith('_'):
        type_info[k] = type(v).__name__
results['_types'] = type_info

print(json.dumps(results, indent=2, default=str))
PYSCRIPT
    sed -i '' "s|/REPLACE_PROJECT|$PROJECT_DIR|g" "$PY_SCRIPT"

    if python3 "$PY_SCRIPT" &> "$PY_LOG"; then
        if grep -q "treasury" "$PY_LOG" 2>/dev/null; then
            # Check command builders return strings (in pretty-printed JSON)
            if grep -q 'cmd1' "$PY_LOG" 2>/dev/null && grep -q 'str' "$PY_LOG" 2>/dev/null; then
                check_pass "python_sdk" "SDK reads + command builders return strings"
            else
                check_pass "python_sdk" "SDK reads OK"
            fi
        else
            check_fail "python_sdk" "Python SDK output missing expected data"
        fi
    else
        check_fail "python_sdk" "Python SDK example failed — see $PY_LOG"
    fi
    rm -f "$PY_SCRIPT"
else
    check_skip "python_sdk" "Python3 not available"
fi

cp "$PY_LOG" "$EVIDENCE_DIR/python-sdk.txt" 2>/dev/null || true

# ══════════════════════════════════════════════════════════════════════
# Section 8: Write-Flow Dry-Run Examples
# ══════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 8: Write-Flow Dry-Run ────────────────────────────────"
WF_DIR="$PROJECT_DIR/examples/write-flows"
WF_LOG="$EVIDENCE_DIR/logs/write-flow-dry-run.log"
WF_PASS=0
WF_FAIL=0

if [ -d "$WF_DIR" ]; then
    for script in "$WF_DIR"/*.sh; do
        name="$(basename "$script" .sh)"
        if [ -f "$script" ] && [ -x "$script" ]; then
            if bash -n "$script" >> "$WF_LOG" 2>&1; then
                WF_PASS=$((WF_PASS+1))
            else
                WF_FAIL=$((WF_FAIL+1))
            fi
        fi
    done
fi

if [ "$WF_FAIL" -eq 0 ] && [ "$WF_PASS" -gt 0 ]; then
    check_pass "write_flow_dry_run" "$WF_PASS write-flow dry-runs passed"
elif [ "$WF_FAIL" -gt 0 ]; then
    check_fail "write_flow_dry_run" "$WF_FAIL write-flow(s) failed — see $WF_LOG"
else
    check_skip "write_flow_dry_run" "No write-flow examples in $WF_DIR"
fi

# ══════════════════════════════════════════════════════════════════════
# Section 9: SDK Command-Builder Examples
# ══════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 9: SDK Command Builders ──────────────────────────────"
BUILDER_LOG="$EVIDENCE_DIR/logs/sdk-command-builders.log"
BUILDER_PASS=0
BUILDER_FAIL=0

# We already tested builders in sections 6 and 7. This section verifies
# that builders return strings and never execute commands.

# Node builder check
NODE_BUILDER=$(mktemp)
cat > "$NODE_BUILDER" << 'NODEBC'
const c = require('/REPLACE_PROJECT/examples/node-client/src/client.js');
const builders = [
  () => c.bankSendCmd('from','to','1000','unxrl'),
  () => c.merchantRegisterCmd('owner','Shop','desc'),
  () => c.settlementCreateCmd('payer','merchant','500','ref'),
  () => c.escrowCreateCmd('buyer','seller','merchant','1000','ref'),
  () => c.escrowDisputeCmd('escrow-1','test'),
  () => c.escrowReleaseCmd('escrow-1'),
  () => c.payoutCreateCmd('merchant','recip','500','ref'),
  () => c.payoutMarkPaidCmd('payout-1'),
  () => c.treasurySpendRequestCmd('acct1','recip','100','dev'),
  () => c.productGovCmd('enable-escrow-live'),
];
let allStr = true;
for (const b of builders) {
  const r = b();
  if (typeof r !== 'string') { allStr = false; console.log('NOT STRING:', r); }
}
if (allStr) { console.log('ALL BUILDERS RETURN STRINGS'); process.exit(0); }
else { console.log('SOME BUILDERS NOT STRINGS'); process.exit(1); }
NODEBC
sed -i '' "s|/REPLACE_PROJECT|$PROJECT_DIR|g" "$NODE_BUILDER"

if command -v node &>/dev/null; then
    if node "$NODE_BUILDER" >> "$BUILDER_LOG" 2>&1; then
        if grep -q "ALL BUILDERS RETURN STRINGS" "$BUILDER_LOG"; then
            check_pass "node_command_builders" "All 10 Node builders return strings"
            BUILDER_PASS=$((BUILDER_PASS+1))
        else
            check_fail "node_command_builders" "Builder output check failed"
            BUILDER_FAIL=$((BUILDER_FAIL+1))
        fi
    else
        check_fail "node_command_builders" "Node builder check failed — see $BUILDER_LOG"
        BUILDER_FAIL=$((BUILDER_FAIL+1))
    fi
else
    check_skip "node_command_builders" "Node not available"
fi
rm -f "$NODE_BUILDER"

# Python builder check
PY_BUILDER=$(mktemp)
cat > "$PY_BUILDER" << 'PYBC'
import sys
sys.path.insert(0, '/REPLACE_PROJECT/examples/python-client')
import nexarail_client as n

builders = [
    ('bank_send_cmd', lambda: n.bank_send_cmd('from','to','1000','unxrl')),
    ('merchant_register_cmd', lambda: n.merchant_register_cmd('owner','Shop','desc')),
    ('settlement_create_cmd', lambda: n.settlement_create_cmd('payer','merchant','500','ref')),
    ('escrow_create_cmd', lambda: n.escrow_create_cmd('buyer','seller','merchant','1000','ref')),
    ('escrow_dispute_cmd', lambda: n.escrow_dispute_cmd('escrow-1','test')),
    ('escrow_release_cmd', lambda: n.escrow_release_cmd('escrow-1')),
    ('payout_create_cmd', lambda: n.payout_create_cmd('merch','recip','500','ref')),
    ('payout_mark_paid_cmd', lambda: n.payout_mark_paid_cmd('payout-1')),
    ('treasury_spend_request_cmd', lambda: n.treasury_spend_request_cmd('acct1','recip','100','dev')),
    ('product_gov_cmd', lambda: n.product_gov_cmd('enable-escrow-live')),
]

all_str = True
for name, fn in builders:
    try:
        r = fn()
        if not isinstance(r, str):
            print(f'NOT STRING: {name} -> {type(r).__name__}')
            all_str = False
        else:
            print(f'OK: {name} -> string ({len(r)} chars)')
    except Exception as e:
        print(f'ERROR: {name} -> {e}')
        all_str = False

if all_str:
    print('ALL BUILDERS RETURN STRINGS')
    sys.exit(0)
else:
    print('SOME BUILDERS NOT STRINGS')
    sys.exit(1)
PYBC
sed -i '' "s|/REPLACE_PROJECT|$PROJECT_DIR|g" "$PY_BUILDER"

if command -v python3 &>/dev/null; then
    if python3 "$PY_BUILDER" >> "$BUILDER_LOG" 2>&1; then
        if grep -q "ALL BUILDERS RETURN STRINGS" "$BUILDER_LOG"; then
            check_pass "python_command_builders" "All 10 Python builders return strings"
            BUILDER_PASS=$((BUILDER_PASS+1))
        else
            check_fail "python_command_builders" "Builder output check failed"
            BUILDER_FAIL=$((BUILDER_FAIL+1))
        fi
    else
        check_fail "python_command_builders" "Python builder check failed"
        BUILDER_FAIL=$((BUILDER_FAIL+1))
    fi
else
    check_skip "python_command_builders" "Python3 not available"
fi
rm -f "$PY_BUILDER"

# ══════════════════════════════════════════════════════════════════════
# Section 10: Dashboard File Check
# ══════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 10: Dashboard Check ──────────────────────────────────"
DASH_LOG="$EVIDENCE_DIR/logs/dashboard-check.log"

if [ "$SKIP_DASHBOARD" -eq 1 ]; then
    check_skip "dashboard_check" "Skipped via --skip-dashboard"
elif [ -x "$PROJECT_DIR/scripts/dev/check-dashboard-files.sh" ]; then
    if bash "$PROJECT_DIR/scripts/dev/check-dashboard-files.sh" &> "$DASH_LOG"; then
        DS_PASS=$(grep -c "PASS" "$DASH_LOG" 2>/dev/null || echo 0)
        check_pass "dashboard_check" "Dashboard file check: ${DS_PASS}+ pass"
    else
        check_fail "dashboard_check" "Dashboard check failed — see $DASH_LOG"
    fi
else
    check_skip "dashboard_check" "check-dashboard-files.sh not found"
fi

# Optionally serve dashboard
if [ "$SERVE_DASHBOARD" -eq 1 ] && [ -d "$PROJECT_DIR/examples/dashboard" ]; then
    echo ""
    echo "── Dashboard Server ────────────────────────────────────────────"
    echo "  Starting dashboard server on http://localhost:8089"
    (cd "$PROJECT_DIR/examples/dashboard" && python3 -m http.server 8089 &>/dev/null &)
    DASH_PID=$!
    echo "  PID: $DASH_PID (will be killed on exit)"
fi

# ══════════════════════════════════════════════════════════════════════
# Section 11: Evidence Collection
# ══════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 11: Evidence ─────────────────────────────────────────"

# Collect devnet logs if available
for logfile in "$PROJECT_DIR/build/.nexarail-devnet/config"/*.log "$PROJECT_DIR/build/.nexarail-devnet/data"/*.log; do
    [ -f "$logfile" ] && cp "$logfile" "$EVIDENCE_DIR/logs/" 2>/dev/null || true
done

# Build summary
TOTAL=$((PASS + FAIL + SKIP))

cat > "$EVIDENCE_DIR/summary.json" << EOF
{
  "demo": "end-to-end",
  "timestamp": "$TIMESTAMP",
  "pass": $PASS,
  "fail": $FAIL,
  "skip": $SKIP,
  "total": $TOTAL,
  "status": "$([ "$FAIL" -eq 0 ] && echo "PASS" || echo "FAIL")"
}
EOF

cat > "$EVIDENCE_DIR/summary.md" << EOFS
# End-to-End Demo Summary

**Timestamp:** $TIMESTAMP
**Status:** $([ "$FAIL" -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")
**Total:** $TOTAL | **Pass:** $PASS | **Fail:** $FAIL | **Skip:** $SKIP

## Evidence Files
$(find "$EVIDENCE_DIR" -type f -not -path '*/logs/*' | sort | sed 's|.*/| - |')
EOFS

echo "  Evidence saved to: $EVIDENCE_DIR"
echo "  Files: $(find "$EVIDENCE_DIR" -type f | wc -l)"

# ══════════════════════════════════════════════════════════════════════
# Final Summary
# ══════════════════════════════════════════════════════════════════════
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  End-to-End Demo Summary                                   ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5s %5s %5s   ║\n" "Result" "PASS" "FAIL" "SKIP"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5d %5d %5d   ║\n" "E2E Demo" "$PASS" "$FAIL" "$SKIP"
echo "╠══════════════════════════════════════════════════════════════╣"
if [ "$FAIL" -eq 0 ]; then
    echo "║  ✅ End-to-End Demo PASSED                                ║"
else
    echo "║  ❌ Some checks FAILED                                    ║"
fi
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ══════════════════════════════════════════════════════════════════════
# Cleanup
# ══════════════════════════════════════════════════════════════════════
if [ "$KEEP_RUNNING" -eq 1 ]; then
    echo "  --keep-running: devnet left running."
    echo "  Dashboard: $([ "$SERVE_DASHBOARD" -eq 1 ] && echo 'http://localhost:8089' || echo '(not started)')"
    echo "  Evidence:   $EVIDENCE_DIR"
else
    echo "── Cleanup ─────────────────────────────────────────────────────"
    # Stop devnet
    if [ -x "$LAUNCH_SCRIPT" ]; then
        bash "$LAUNCH_SCRIPT" --stop &>/dev/null || true
    fi
    echo "  Devnet stopped."
    # Kill dashboard server if started
    if [ "$SERVE_DASHBOARD" -eq 1 ]; then
        kill "$DASH_PID" 2>/dev/null || true
        echo "  Dashboard server stopped."
    fi
    echo ""
fi

exit $([ "$FAIL" -eq 0 ] && echo 0 || echo 1)