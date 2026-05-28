#!/usr/bin/env bash
# NexaRail — Clean Validator Agent Runtime
#
# Aggressively but safely cleans up validator agent processes and ports.
# Will NOT kill nexaraild processes outside the rehearsals tree unless --force.
#
# TESTNET/DEVNET ONLY — NOT MAINNET — Tokens have zero value.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
FORCE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --force) FORCE=1; shift ;;
        *) echo "Unknown: $1"; exit 1 ;;
    esac
done

KILLED_PIDS=()
KILLED_PORTS=()

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  NexaRail — Clean Validator Agent Runtime                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# ── Step 1: Try normal stop ──────────────────────────────
echo ""
echo "── Step 1: Normal Stop ────────────────────────────────────────"
STOP_SCRIPT="$PROJECT_DIR/scripts/testnet/stop-validator-agents.sh"
if [ -x "$STOP_SCRIPT" ]; then
    if bash "$STOP_SCRIPT" &> /dev/null; then
        echo "  ✅ Normal stop succeeded"
    else
        echo "  ⚠️  Normal stop had issues, proceeding with aggressive cleanup"
    fi
else
    echo "  ⚠️  Stop script not found"
fi

# ── Step 2: Kill validator-agent nexaraild processes ────
echo ""
echo "── Step 2: Kill Agent Processes ──────────────────────────────"
AGENT_PIDS=$(pgrep -f "nexaraild.*validator-agent\|nexaraild.*alpha\|nexaraild.*bravo\|nexaraild.*charlie\|nexaraild.*delta\|nexaraild.*echo" 2>/dev/null || true)
if [ -n "$AGENT_PIDS" ]; then
    echo "  Killing $AGENT_PIDS" | wc -w | tr -d ' '
    for pid in $AGENT_PIDS; do
        kill "$pid" 2>/dev/null && KILLED_PIDS+=("$pid") || true
    done
    sleep 2
    # Force kill survivors
    for pid in $AGENT_PIDS; do
        kill -9 "$pid" 2>/dev/null && KILLED_PIDS+=("$pid") || true
    done
    sleep 1
    echo "  ✅ Killed ${#KILLED_PIDS[@]} agent processes"
else
    echo "  ✅ No agent processes found"
fi

# Also kill product-flow and tee processes that may hang
pkill -f "run-product-flow-rehearsal" 2>/dev/null || true
pkill -f "run-product-flow-suites" 2>/dev/null || true
pkill -f "tee -a.*product-flow" 2>/dev/null || true

# ── Step 3: Kill other stale nexaraild (only with --force) ──
echo ""
echo "── Step 3: Other nexaraild Processes ──────────────────────────"
OTHER_PIDS=$(pgrep -f "nexaraild" 2>/dev/null | grep -v "validator-agent\|alpha\|bravo\|charlie\|delta\|echo" || true)
if [ -n "$OTHER_PIDS" ]; then
    echo "  Found non-agent nexaraild processes: $(echo $OTHER_PIDS | wc -w | tr -d ' ')"
    if [ "$FORCE" -eq 1 ]; then
        for pid in $OTHER_PIDS; do
            kill "$pid" 2>/dev/null || true
        done
        sleep 1
        for pid in $OTHER_PIDS; do
            kill -9 "$pid" 2>/dev/null || true
        done
        echo "  ✅ Killed with --force"
    else
        echo "  ⏭️  Skipped (use --force to kill non-agent nexaraild)"
    fi
else
    echo "  ✅ No other nexaraild processes"
fi

# ── Step 4: Clear stale PID files ──────────────────────────
echo ""
echo "── Step 4: PID Files ──────────────────────────────────────────"
PID_FILES=$(find "$PROJECT_DIR/rehearsals/validator-agents" -name "*.pid" 2>/dev/null || true)
if [ -n "$PID_FILES" ]; then
    echo "  Removing stale PID files: $(echo "$PID_FILES" | wc -l | tr -d ' ')"
    rm -f $PID_FILES
    echo "  ✅ Cleared"
else
    echo "  ✅ No stale PID files"
fi

# ── Step 5: Check ports ──────────────────────────────────
echo ""
echo "── Step 5: Port Check ─────────────────────────────────────────"
PORTS=(27657 27667 27677 27687 27697 1417 1418 1419 1420 1421 9190 9191 9192 9193 9194)
for port in "${PORTS[@]}"; do
    owner=$(lsof -i :$port -P 2>/dev/null | grep LISTEN | awk '{print $1, $2}' | head -1 || true)
    if [ -n "$owner" ]; then
        echo "  Port $port: $owner"
        if echo "$owner" | grep -qi "nexaraild"; then
            KILLED_PORTS+=("$port")
        fi
    fi
done

if [ ${#KILLED_PORTS[@]} -eq 0 ]; then
    echo "  ✅ All agent ports free"
fi

# ── Step 6: Summary ──────────────────────────────────────
echo ""
echo "── Summary ────────────────────────────────────────────────────"
echo "  Processes killed: ${#KILLED_PIDS[@]}"
echo "  Ports still occupied by nexaraild: ${#KILLED_PORTS[@]}"
echo "  Final agent processes: $(pgrep -f "nexaraild.*validator-agent" 2>/dev/null | wc -l | tr -d ' ')"
echo ""

exit $([ ${#KILLED_PORTS[@]} -eq 0 ] && echo 0 || echo 1)