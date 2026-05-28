#!/usr/bin/env bash
# NexaRail — Stop RC1 Devnet
#
# Stops RC1 devnet processes launched by launch-rc1-devnet.sh.
# Default: only kills processes whose binary path matches releases/testnet-rc1/binaries/nexaraild-*
#
# TESTNET/DEVNET ONLY.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RELEASE_DIR="$PROJECT_DIR/releases/testnet-rc1"
DEVNET_DIR="$PROJECT_DIR/rehearsals/rc1-devnet"

FORCE=0
EVIDENCE_DIR=""

usage() {
    cat <<EOF
Usage: scripts/release/stop-rc1-devnet.sh [OPTIONS]

Options:
  --evidence-dir <path>  Collect final logs into <path>/diagnostics
  --force                Kill matching nexaraild processes without checking home path
  -h|--help              Show this help

Default: kills only processes whose binary matches releases/testnet-rc1/binaries/nexaraild-*
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --evidence-dir) EVIDENCE_DIR="${2:-}"; shift 2 ;;
        --force)        FORCE=1; shift ;;
        -h|--help)      usage; exit 0 ;;
        *)              echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

if [ -n "$EVIDENCE_DIR" ]; then
    mkdir -p "$EVIDENCE_DIR/diagnostics"
    exec > >(tee -a "$EVIDENCE_DIR/diagnostics/stop-rc1-devnet.log") 2>&1
fi

RC1_BIN_PREFIX="$RELEASE_DIR/binaries/nexaraild-"

echo "=== Stopping RC1 Devnet ==="
echo "  Binary prefix: $RC1_BIN_PREFIX"
echo "  Force mode: $([ "$FORCE" -eq 1 ] && echo 'yes' || echo 'no')"
echo "  Devnet dir: $DEVNET_DIR"
echo ""

STOPPED=0
SURVIVORS=0

# ── Helper: kill a PID by process match ─────────────────
kill_rc1_process() {
    local pid="$1"
    local source="$2"
    [ -z "$pid" ] && return 0

    local cmd
    cmd="$(ps -p "$pid" -o command= 2>/dev/null || true)"
    [ -z "$cmd" ] && return 0

    # Default: only kill if binary path matches rc1 prefix
    if [ "$FORCE" -ne 1 ]; then
        if ! printf '%s\n' "$cmd" | grep -qF "$RC1_BIN_PREFIX"; then
            echo "  skip (binary not in $RC1_BIN_PREFIX): PID $pid ($source)"
            SURVIVORS=$((SURVIVORS + 1))
            return 0
        fi
        # Also skip if command includes the devnet home path (extra safety)
        if printf '%s\n' "$cmd" | grep -qF ".nexarail-devnet" || printf '%s\n' "$cmd" | grep -qF "$DEVNET_DIR"; then
            : # it's ours
        else
            echo "  skip (home not devnet): PID $pid ($source)"
            SURVIVORS=$((SURVIVORS + 1))
            return 0
        fi
    fi

    if kill "$pid" >/dev/null 2>&1; then
        echo "  stopped PID $pid ($source)"
        STOPPED=$((STOPPED + 1))
    else
        echo "  PID $pid already stopped ($source)"
    fi
}

# ── 1. Stop via PID files ───────────────────────────────
echo "--- PID files ---"
for pid_file in "$DEVNET_DIR/pids/"*.pid; do
    [ -f "$pid_file" ] || continue
    name="$(basename "$pid_file" .pid)"
    pid="$(cat "$pid_file" 2>/dev/null || true)"
    echo "  Found: $name (PID $pid)"
    kill_rc1_process "$pid" "pid-file:$name"
    rm -f "$pid_file"
done

# ── 2. Stop via tmux sessions (five-agent pattern) ──────
echo ""
echo "--- Tmux sessions ---"
for session in nexarail-devnet-alpha nexarail-devnet-bravo nexarail-devnet-charlie nexarail-devnet-delta nexarail-devnet-echo; do
    if command -v tmux >/dev/null 2>&1 && tmux has-session -t "$session" 2>/dev/null; then
        tmux kill-session -t "$session" >/dev/null 2>&1 || true
        echo "  stopped tmux session $session"
        STOPPED=$((STOPPED + 1))
    fi
done

# ── 3. Kill orphaned RC1-binpath processes ──────────────
echo ""
echo "--- Orphaned process scan ---"
ORPHANS=$(pgrep -f "nexaraild" 2>/dev/null || true)
if [ -n "$ORPHANS" ]; then
    while IFS= read -r pid; do
        [ -z "$pid" ] && continue
        kill_rc1_process "$pid" "orphan"
    done <<< "$ORPHANS"
fi

sleep 1

# ── 4. Force-kill survivors if --force ──────────────────
if [ "$FORCE" -eq 1 ]; then
    echo ""
    echo "--- Force kill survivors ---"
    sleep 2
    REMAINING=$(pgrep -f "nexaraild" 2>/dev/null || true)
    if [ -n "$REMAINING" ]; then
        while IFS= read -r pid; do
            [ -z "$pid" ] && continue
            if kill -KILL "$pid" >/dev/null 2>&1; then
                echo "  force-stopped PID $pid"
                STOPPED=$((STOPPED + 1))
            fi
        done <<< "$REMAINING"
    fi
fi

# ── 5. Collect evidence ─────────────────────────────────
if [ -n "$EVIDENCE_DIR" ] && [ -d "$DEVNET_DIR/logs" ]; then
    echo ""
    echo "--- Collecting final logs ---"
    mkdir -p "$EVIDENCE_DIR/diagnostics/logs"
    cp -r "$DEVNET_DIR/logs/"* "$EVIDENCE_DIR/diagnostics/logs/" 2>/dev/null || true
    echo "  Logs copied to $EVIDENCE_DIR/diagnostics/logs"

    # Save process snapshot
    pgrep -la nexaraild > "$EVIDENCE_DIR/diagnostics/after-stop-pgrep.txt" 2>&1 || true
    ps aux 2>/dev/null | grep '[n]exaraild' > "$EVIDENCE_DIR/diagnostics/after-stop-ps.txt" || true
fi

# ── 6. Final check ──────────────────────────────────────
REMAINING_COUNT=0
FINAL_PIDS=$(pgrep -f "nexaraild" 2>/dev/null || true)
if [ -n "$FINAL_PIDS" ]; then
    while IFS= read -r pid; do
        [ -z "$pid" ] && continue
        cmd="$(ps -p "$pid" -o command= 2>/dev/null || true)"
        if [ -n "$cmd" ]; then
            REMAINING_COUNT=$((REMAINING_COUNT + 1))
        fi
    done <<< "$FINAL_PIDS"
fi

echo ""
echo "=== Stop complete: stopped $STOPPED item(s) ==="

if [ "$REMAINING_COUNT" -gt 0 ]; then
    echo "  ⚠️  $REMAINING_COUNT nexaraild process(es) still running (not RC1 devnet)"
    exit 1
fi

echo "  ✅ All RC1 devnet processes stopped"
echo "  Logs preserved at: $DEVNET_DIR/logs/"
exit 0
