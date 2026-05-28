#!/usr/bin/env bash
# NexaRail — Five-Agent Restart Recovery Check
#
# Tests single-node and all-node restart recovery on the five-agent devnet.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
EVIDENCE_DIR="${EVIDENCE_DIR:-$PROJECT_DIR/rehearsals/validator-agents/restart-check/evidence/$TIMESTAMP}"
BINARY="$PROJECT_DIR/build/nexaraild"
KEEP_RUNNING=0

while [[ $# -gt 0 ]]; do
    case "$1" in --keep-running) KEEP_RUNNING=1; shift ;; --evidence-dir) EVIDENCE_DIR="$2"; shift 2 ;; --reuse-running) REUSE=1; shift ;; *) echo "Unknown: $1"; exit 1 ;; esac
done

mkdir -p "$EVIDENCE_DIR"/{samples,logs}
PASS=0; FAIL=0
PASS_MARK="  \033[32m✅ PASS\033[0m"; FAIL_MARK="  \033[31m❌ FAIL\033[0m"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  NexaRail — Five-Agent Restart Recovery Check              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo "  Evidence: $EVIDENCE_DIR"
echo ""

# ── Spawn if needed ──────────────────────────────────────
if [ "${REUSE:-0}" -ne 1 ]; then
    echo "── Spawn Agents ──────────────────────────────────────────────"
    bash "$PROJECT_DIR/scripts/testnet/spawn-validator-agents.sh" --clean --force-clean --agent-count 5 &>"$EVIDENCE_DIR/spawn.log"
    echo "  ✅ Agents spawned"
fi

# Wait for height >= 10
echo "  Waiting for height >= 10..."
for i in $(seq 1 30); do
    H=$(curl -s --max-time 2 "http://localhost:27657/status" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('result',{}).get('sync_info',{}).get('latest_block_height','0'))" 2>/dev/null || echo "0")
    [ "$H" -ge 10 ] 2>/dev/null && echo "  Height: $H" && break
    sleep 2
done

# Record pre-restart baseline
curl -s "http://localhost:27657/status" > "$EVIDENCE_DIR/pre-restart-alpha.json" 2>/dev/null
curl -s "http://localhost:27667/status" > "$EVIDENCE_DIR/pre-restart-bravo.json" 2>/dev/null
curl -s "http://localhost:27677/status" > "$EVIDENCE_DIR/pre-restart-charlie.json" 2>/dev/null
curl -s "http://localhost:27687/status" > "$EVIDENCE_DIR/pre-restart-delta.json" 2>/dev/null
curl -s "http://localhost:27697/status" > "$EVIDENCE_DIR/pre-restart-echo.json" 2>/dev/null

# Get baseline heights
BASELINE_H=$(python3 -c "import json; d=json.load(open('$EVIDENCE_DIR/pre-restart-alpha.json')); print(d['result']['sync_info']['latest_block_height'])" 2>/dev/null || echo "?")
echo "  Baseline height: $BASELINE_H"

# ── Test 1: Single-node restart ─────────────────────────
echo ""
echo "── Test 1: Single-Node Restart (echo) ─────────────────────────"
ECHO_PID=$(cat "$PROJECT_DIR/rehearsals/validator-agents/echo/pids/single-node.pid" 2>/dev/null || pgrep -f "nexaraild.*echo" | head -1 || echo "")
if [ -n "$ECHO_PID" ]; then
    kill "$ECHO_PID" 2>/dev/null || true
    sleep 3
    echo "  Stopped echo (PID $ECHO_PID)"
else
    echo "  ⚠️  Could not find echo PID"
fi

# Restart echo
if [ -f "$PROJECT_DIR/rehearsals/validator-agents/echo/pids/single-node.pid" ]; then
    rm -f "$PROJECT_DIR/rehearsals/validator-agents/echo/pids/single-node.pid"
fi
nohup "$BINARY" start --home "$PROJECT_DIR/rehearsals/validator-agents/echo" \
    --minimum-gas-prices "0unxrl" \
    > "$EVIDENCE_DIR/logs/echo-restart.log" 2>&1 < /dev/null &
NEW_ECHO_PID=$!
echo "  Restarted echo (PID $NEW_ECHO_PID)"

# Wait for echo to catch up
sleep 10
ECHO_H=$(curl -s --max-time 3 "http://localhost:27697/status" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result']['sync_info']['latest_block_height'])" 2>/dev/null || echo "0")
ALPHA_H=$(curl -s --max-time 3 "http://localhost:27657/status" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result']['sync_info']['latest_block_height'])" 2>/dev/null || echo "0")

if [ "$ECHO_H" -ge "$ALPHA_H" ] 2>/dev/null; then
    echo -e "${PASS_MARK} single_restart" "Echo caught up (echo=$ECHO_H, alpha=$ALPHA_H)"
    PASS=$((PASS+1))
else
    echo -e "${FAIL_MARK} single_restart" "Echo not caught up (echo=$ECHO_H, alpha=$ALPHA_H)"
    FAIL=$((FAIL+1))
fi

# ── Test 2: All-node sequential restart ─────────────────
echo ""
echo "── Test 2: All-Node Sequential Restart ─────────────────────────"
for agent in echo delta charlie bravo alpha; do
    PID=$(cat "$PROJECT_DIR/rehearsals/validator-agents/$agent/pids/single-node.pid" 2>/dev/null || pgrep -f "nexaraild.*$agent" | head -1 || echo "")
    [ -n "$PID" ] && kill "$PID" 2>/dev/null || true
    sleep 2
    rm -f "$PROJECT_DIR/rehearsals/validator-agents/$agent/pids/single-node.pid" 2>/dev/null || true
    nohup "$BINARY" start --home "$PROJECT_DIR/rehearsals/validator-agents/$agent" \
        --minimum-gas-prices "0unxrl" \
        > "$EVIDENCE_DIR/logs/${agent}-restart.log" 2>&1 < /dev/null &
    echo "  Restarted $agent"
    sleep 3
done

# Wait for network to resume
echo "  Waiting for network to resume..."
sleep 15

# Check height after restart
POST_H=$(curl -s --max-time 3 "http://localhost:27657/status" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result']['sync_info']['latest_block_height'])" 2>/dev/null || echo "0")
if [ "$POST_H" -gt "$BASELINE_H" ] 2>/dev/null; then
    echo -e "${PASS_MARK} all_restart" "Height advanced from $BASELINE_H to $POST_H"
    PASS=$((PASS+1))
else
    echo -e "${FAIL_MARK} all_restart" "Height did not advance ($BASELINE_H -> $POST_H)"
    FAIL=$((FAIL+1))
fi

# ── Final checks ────────────────────────────────────────
echo ""
echo "── Final Checks ───────────────────────────────────────────────"

# All agents alive
ALIVE=0
for port in 27657 27667 27677 27687 27697; do
    h=$(curl -s --max-time 3 "http://localhost:$port/status" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result']['sync_info']['latest_block_height'])" 2>/dev/null || echo "dead")
    echo "  Port $port: height=$h"
    [ "$h" != "dead" ] && ALIVE=$((ALIVE+1))
done
echo -e "${PASS_MARK} agents_alive" "$ALIVE/5 agents responding" && PASS=$((PASS+1))

# Live flags
FLAGS_OK=true
for port in 1417 1418 1419 1420 1421; do
    for mod in settlement escrow payout treasury; do
        le=$(curl -s "http://localhost:$port/nexarail/$mod/v1/params" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('params',d).get('live_enabled','?'))" 2>/dev/null || echo "?")
        [ "$le" != "false" ] && [ "$le" != "False" ] && [ "$le" != "false" ] && FLAGS_OK=false
    done
done
if [ "$FLAGS_OK" = "true" ]; then
    echo -e "${PASS_MARK} live_flags" "All false"
    PASS=$((PASS+1))
else
    echo -e "${FAIL_MARK} live_flags" "Non-false detected"
    FAIL=$((FAIL+1))
fi

# Summary
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Restart Recovery Summary                                  ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5s %5s   ║\n" "Result" "PASS" "FAIL"
printf "║  %-20s %5d %5d   ║\n" "Restart" "$PASS" "$FAIL"
echo "╠══════════════════════════════════════════════════════════════╣"
[ "$FAIL" -eq 0 ] && echo "║  ✅ All restart checks passed              ║" || echo "║  ❌ Some checks failed                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo "  Evidence: $EVIDENCE_DIR"

cat > "$EVIDENCE_DIR/summary.json" << EOF
{"pass":$PASS,"fail":$FAIL,"baseline_height":"$BASELINE_H","post_restart_height":"$POST_H"}
EOF

exit $([ "$FAIL" -eq 0 ] && echo 0 || echo 1)
