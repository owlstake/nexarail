#!/usr/bin/env bash
# NexaRail — Product Flow Split Suites Runner (v2)
#
# Runs product-flow suites sequentially against a single five-agent spawn.
# Parses results from product-flow evidence directories.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
EVIDENCE_BASE="$PROJECT_DIR/rehearsals/validator-agents/product-flow-suites/evidence/$TIMESTAMP"
SUITES=("smoke" "settlement" "merchant" "escrow" "treasury" "payout" "safety")
TIMEOUT_PER_SUITE=900
CONTINUE_ON_FAIL=0
STOP_AFTER=""

while [[ $# -gt 0 ]]; do
    case "$1" in --force-clean-first) ;; --stop-after) STOP_AFTER="$2"; shift 2 ;; --global-timeout-per-suite) TIMEOUT_PER_SUITE="$2"; shift 2 ;; --evidence-dir) EVIDENCE_BASE="$2"; shift 2 ;; --continue-on-fail) CONTINUE_ON_FAIL=1; shift ;; *) echo "Unknown: $1"; exit 1 ;; esac
done

mkdir -p "$EVIDENCE_BASE"
PASS=0; FAIL=0; SKIP=0; TOTAL=0; RESULTS=""
TOTAL_START=$SECONDS

CLEAN="$PROJECT_DIR/scripts/testnet/clean-validator-agent-runtime.sh"
SPAWN="$PROJECT_DIR/scripts/testnet/spawn-validator-agents.sh"
STOP="$PROJECT_DIR/scripts/testnet/stop-validator-agents.sh"
PF="$PROJECT_DIR/scripts/testnet/run-product-flow-rehearsal.sh"

echo "NexaRail — Product Flow Split Suites"
echo "Evidence: $EVIDENCE_BASE"
echo ""

# Clean
bash "$CLEAN" --force &>/dev/null || true
echo "  Cleaned"

# Spawn once
bash "$SPAWN" --clean --force-clean --agent-count 5 &>"$EVIDENCE_BASE/spawn.log"
echo "  Spawned"

# Wait for height
for i in $(seq 1 60); do
    H=$(curl -s --max-time 2 "http://localhost:27657/status" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('result',{}).get('sync_info',{}).get('latest_block_height','0'))" 2>/dev/null || echo "0")
    [ "$H" -ge 5 ] 2>/dev/null && echo "  Ready at height $H" && break
    [ "$i" -eq 60 ] && { echo "  Timeout"; exit 1; }
    sleep 1
done

# Run suites
for suite in "${SUITES[@]}"; do
    SUITE_DIR="$EVIDENCE_BASE/$suite"
    mkdir -p "$SUITE_DIR"

    SUITE_START=$SECONDS
    set +e
    bash "$PF" --suite "$suite" --no-spawn --global-timeout "$TIMEOUT_PER_SUITE" &>"$SUITE_DIR/run.log"
    RC=$?
    SUITE_DURATION=$((SECONDS - SUITE_START))
    set -e

    # Look for result in evidence dir
    EV_DIR=$(ls -dt "$PROJECT_DIR/rehearsals/validator-agents/product-flows/evidence/"* 2>/dev/null | head -1 || echo "")
    PF_PASS=0; PF_FAIL=0
    if [ -n "$EV_DIR" ]; then
        PF_PASS=$(grep "^PASS" "$EV_DIR/result-events.log" 2>/dev/null | wc -l | tr -d ' ')
        PF_FAIL=$(grep "^FAIL" "$EV_DIR/result-events.log" 2>/dev/null | wc -l | tr -d ' ')
    fi

    if [ "$RC" -eq 0 ] && [ "$PF_FAIL" -eq 0 ]; then
        echo "  ✅ $suite — PASS (${SUITE_DURATION}s)"
        PASS=$((PASS+1)); RESULTS="${RESULTS}✅ $suite: PASS (${SUITE_DURATION}s)\n"
    else
        echo "  ❌ $suite — FAIL (exit=$RC, ${SUITE_DURATION}s, fails=$PF_FAIL)"
        FAIL=$((FAIL+1)); RESULTS="${RESULTS}❌ $suite: FAIL (${SUITE_DURATION}s, exit=$RC)\n"
        tail -3 "$SUITE_DIR/run.log" 2>/dev/null | sed 's/^/  /' || true
        [ "$CONTINUE_ON_FAIL" -eq 0 ] && break
    fi
    TOTAL=$((TOTAL+1))
    [ -n "$STOP_AFTER" ] && [ "$suite" = "$STOP_AFTER" ] && break
done

# Live flags
python3 -c "
import json, urllib.request
r={}
for p in [1417,1418,1419,1420,1421]:
    for m in ['settlement','escrow','payout','treasury']:
        try:
            d=json.loads(urllib.request.urlopen(f'http://localhost:{p}/nexarail/{m}/v1/params',timeout=3).read())
            r[f'a{p}_{m}']=d.get('params',d).get('live_enabled','?')
        except Exception as e:
            r[f'a{p}_{m}']=str(e)[:50]
json.dump(r,open('$EVIDENCE_BASE/live-flags.json','w'),indent=2)
" 2>/dev/null || echo "Live flags unavailable"

# Summary
TOTAL_DURATION=$((SECONDS - TOTAL_START))
echo "$RESULTS" > "$EVIDENCE_BASE/results.txt"
cat > "$EVIDENCE_BASE/summary.json" << EOF
{"timestamp":"$TIMESTAMP","pass":$PASS,"fail":$FAIL,"skip":$SKIP,"total":$TOTAL,"duration_seconds":$TOTAL_DURATION}
EOF

echo ""
echo "═══ Summary ═══"
echo "Pass: $PASS  Fail: $FAIL  Skip: $SKIP"
echo "Duration: ${TOTAL_DURATION}s"
echo ""

# Stop
bash "$STOP" &>/dev/null || true
echo "  Stopped"

exit $([ "$FAIL" -eq 0 ] && echo 0 || echo 1)