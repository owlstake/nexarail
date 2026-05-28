#!/usr/bin/env bash
# NexaRail — Product Flow Split Suites Runner
#
# Runs product-flow suites one by one against the five-agent devnet.
# Each suite has its own timeout and evidence collection.
# Combined results are summarized at the end.
#
# TESTNET/DEVNET ONLY — NOT MAINNET — Tokens have zero value.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
EVIDENCE_BASE="$PROJECT_DIR/rehearsals/validator-agents/product-flow-suites/evidence/$TIMESTAMP"
SUITES=("smoke" "settlement" "merchant" "escrow" "treasury" "payout" "safety")
TIMEOUT_PER_SUITE=900
FORCE_CLEAN=0
REUSE_RUNNING=0
CONTINUE_ON_FAIL=0
STOP_AFTER=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --force-clean-first) FORCE_CLEAN=1; shift ;;
        --reuse-running) REUSE_RUNNING=1; shift ;;
        --stop-after) STOP_AFTER="$2"; shift 2 ;;
        --global-timeout-per-suite) TIMEOUT_PER_SUITE="$2"; shift 2 ;;
        --evidence-dir) EVIDENCE_BASE="$2"; shift 2 ;;
        --continue-on-fail) CONTINUE_ON_FAIL=1; shift ;;
        *) echo "  ❌ Unknown: $1"; exit 1 ;;
    esac
done

mkdir -p "$EVIDENCE_BASE"
PASS=0; FAIL=0; SKIP=0; TOTAL=0
RESULTS=""

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  NexaRail — Product Flow Split Suites                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo "  Timestamp: $TIMESTAMP"
echo "  Evidence:  $EVIDENCE_BASE"
echo "  Timeout:   ${TIMEOUT_PER_SUITE}s per suite"
echo ""

# ── Spawn agents if needed ──────────────────────────────
SPAWN_SCRIPT="$PROJECT_DIR/scripts/testnet/spawn-validator-agents.sh"
STOP_SCRIPT="$PROJECT_DIR/scripts/testnet/stop-validator-agents.sh"
PF_SCRIPT="$PROJECT_DIR/scripts/testnet/run-product-flow-rehearsal.sh"

if [ "$REUSE_RUNNING" -eq 0 ] || [ "$FORCE_CLEAN" -eq 1 ]; then
    echo "── Spawn Agents ──────────────────────────────────────────────"
    if [ -x "$SPAWN_SCRIPT" ]; then
        if bash "$SPAWN_SCRIPT" --clean --force-clean --agent-count 5 &> "$EVIDENCE_BASE/spawn.log"; then
            echo "  ✅ Agents spawned"
        else
            echo "  ❌ Agent spawn failed"
            exit 1
        fi
    else
        echo "  ⚠️  Spawn script not found"
    fi
fi

# Wait for height >= 5
echo "  Waiting for height >= 5..."
for i in $(seq 1 30); do
    H=$(curl -s --max-time 2 "http://localhost:27657/status" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('result',{}).get('sync_info',{}).get('latest_block_height','0'))" 2>/dev/null || echo "0")
    [ "$H" -ge 5 ] 2>/dev/null && echo "  Height: $H" && break
    sleep 2
done

# ── Run each suite ──────────────────────────────────────
echo ""
echo "── Run Suites ──────────────────────────────────────────────────"
for suite in "${SUITES[@]}"; do
    if [ -n "$STOP_AFTER" ] && [ "$suite" = "$STOP_AFTER" ]; then
        echo "  ⏹️  Stopping after $suite (--stop-after)"
        break
    fi

    echo ""
    echo "  ═══ $suite ═══"
    SUITE_DIR="$EVIDENCE_BASE/$suite"
    mkdir -p "$SUITE_DIR"
    SUITE_LOG="$SUITE_DIR/suite.log"

    if [ -x "$PF_SCRIPT" ]; then
        set +e
        SECONDS=0
        bash "$PF_SCRIPT" --suite "$suite" --no-spawn --global-timeout "$TIMEOUT_PER_SUITE" &> "$SUITE_LOG"
        RC=$?
        DURATION=$SECONDS
        set -e

        # Parse result
        PF_PASS=$(grep -oP "PASS[^0-9]*[0-9]+" "$SUITE_LOG" 2>/dev/null | grep -oP "[0-9]+" | tail -1 || echo "0")
        PF_FAIL=$(grep -oP "FAIL[^0-9]*[0-9]+" "$SUITE_LOG" 2>/dev/null | grep -oP "[0-9]+" | tail -1 || echo "0")

        if [ "$RC" -eq 0 ] && [ "$PF_FAIL" = "0" ]; then
            echo "  ✅ $suite — PASS (${PF_PASS}/${PF_FAIL}, ${DURATION}s)"
            PASS=$((PASS+1))
            RESULTS="${RESULTS}  ✅ $suite: ${PF_PASS} pass / ${PF_FAIL} fail (${DURATION}s)\n"
        else
            echo "  ❌ $suite — FAIL (${PF_PASS}/${PF_FAIL}, ${DURATION}s, exit=$RC)"
            FAIL=$((FAIL+1))
            RESULTS="${RESULTS}  ❌ $suite: ${PF_PASS} pass / ${PF_FAIL} fail (${DURATION}s, exit=$RC)\n"
            tail -5 "$SUITE_LOG" | sed 's/^/      /'
            if [ "$CONTINUE_ON_FAIL" -eq 0 ]; then
                echo "  Stopping (use --continue-on-fail to continue)"
                break
            fi
        fi
        TOTAL=$((TOTAL+1))
    else
        echo "  ⏭️  $suite — script not found"
        SKIP=$((SKIP+1))
    fi
done

# ── Final live flags ────────────────────────────────────
echo ""
echo "── Final Live Flags ───────────────────────────────────────────"
FLAGS_FILE="$EVIDENCE_BASE/final-live-flags.json"
python3 -c "
import json, subprocess, sys
result = {}
for port in [1417, 1418, 1419, 1420, 1421]:
    for mod in ['settlement','escrow','payout','treasury']:
        import urllib.request
        try:
            d = json.loads(urllib.request.urlopen(f'http://localhost:{port}/nexarail/{mod}/v1/params', timeout=3).read())
            p = d.get('params', d)
            le = p.get('live_enabled', '?')
            tr = p.get('treasury_routing_enabled', '?')
            br = p.get('burn_routing_enabled', '?')
            result[f'agent_{port}_{mod}'] = {'live_enabled': le, 'treasury_routing': tr, 'burn_routing': br}
        except Exception as e:
            result[f'agent_{port}_{mod}'] = {'error': str(e)}
with open('$FLAGS_FILE', 'w') as f:
    json.dump(result, f, indent=2)
print('  Live flags saved')
" 2>/dev/null || echo "  Could not query live flags"

# Check for non-false flags
NON_FALSE=$(python3 -c "import json; d=json.load(open('$FLAGS_FILE')); non=[k for k,v in d.items() if v.get('live_enabled') != False and v.get('live_enabled') != '?']; print(len(non))" 2>/dev/null || echo "0")
if [ "$NON_FALSE" -eq 0 ]; then
    echo "  ✅ All live flags false"
else
    echo "  ⚠️  $NON_FALSE non-false live flags detected"
fi

# ── Scan logs for errors ───────────────────────────────
echo ""
echo "── Log Scan ────────────────────────────────────────────────────"
SCAN_TERMS=("panic" "fatal" "unknownproto" "descriptor" "CheckTx" "index out of range" "gzip invalid" "version does not exist" "failed to load state")
SCAN_FILE="$EVIDENCE_BASE/log-scan.txt"
> "$SCAN_FILE"
for term in "${SCAN_TERMS[@]}"; do
    count=$(grep -rli "$term" "$EVIDENCE_BASE" 2>/dev/null | grep -v "$SCAN_FILE" | wc -l | tr -d ' ')
    echo "  $term: $count files with matches" >> "$SCAN_FILE"
done
cat "$SCAN_FILE"

# ── Combined summary ───────────────────────────────────
echo ""
echo "── Combined Summary ────────────────────────────────────────────"

cat > "$EVIDENCE_BASE/combined-summary.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "pass": $PASS,
  "fail": $FAIL,
  "skip": $SKIP,
  "total": $TOTAL,
  "timeout_per_suite": $TIMEOUT_PER_SUITE,
  "status": "$([ "$FAIL" -eq 0 ] && echo "PASS" || echo "FAIL")"
}
EOF

cat > "$EVIDENCE_BASE/combined-summary.md" << EOF
# Product-Flow Split Suites — Combined Summary

**Timestamp:** $TIMESTAMP
**Status:** $([ "$FAIL" -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")
**Total:** $TOTAL | **Pass:** $PASS | **Fail:** $FAIL | **Skip:** $SKIP

## Per-Suite Results
$(printf "$RESULTS")

## Final Live Flags
$(python3 -c "import json; d=json.load(open('$FLAGS_FILE')); print('\n'.join([f'- {k}: live_enabled={v[\"live_enabled\"]}' for k,v in sorted(d.items())]))" 2>/dev/null || echo "(unavailable)")

## Log Scan
$(cat "$SCAN_FILE")

## Evidence
- Combined: $EVIDENCE_BASE
EOF

# ── Stop agents ───────────────────────────────────────
if [ -x "$STOP_SCRIPT" ]; then
    echo ""
    echo "── Stop Agents ──────────────────────────────────────────────"
    bash "$STOP_SCRIPT" &> /dev/null || true
    echo "  Agents stopped"
fi

# ── Summary ─────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Product-Flow Suites Summary                               ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5s %5s %5s   ║\n" "Result" "PASS" "FAIL" "SKIP"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5d %5d %5d   ║\n" "Suites" "$PASS" "$FAIL" "$SKIP"
echo "╠══════════════════════════════════════════════════════════════╣"
if [ "$FAIL" -eq 0 ]; then
    echo "║  ✅ All suites passed                                     ║"
else
    echo "║  ❌ Some suites failed                                    ║"
fi
echo "╚══════════════════════════════════════════════════════════════╝"
echo "  Evidence: $EVIDENCE_BASE"
echo ""

exit $([ "$FAIL" -eq 0 ] && echo 0 || echo 1)