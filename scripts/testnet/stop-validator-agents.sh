#!/usr/bin/env bash
# NexaRail — Stop Validator Agents
#
# TESTNET/DEVNET ONLY. Stops only local validator-agent runtime by default.
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
SCRIPT_DIR="$PROJECT_DIR/scripts/testnet"
AGENT_DIR="$PROJECT_DIR/rehearsals/validator-agents"
FORCE=0
ALL_NEXARAILD=0
EVIDENCE_DIR=""

usage() {
    cat <<EOF
Usage: scripts/testnet/stop-validator-agents.sh [--force] [--all-nexaraild] [--evidence-dir PATH]

Default behavior:
  - stops nexarail-agent-* tmux sessions;
  - stops PID-file processes;
  - stops orphaned nexaraild processes whose command line includes the validator-agent home;
  - never kills unrelated nexaraild processes.

Options:
  --force          Escalate surviving validator-agent processes to SIGKILL.
  --all-nexaraild  Explicitly allow stopping every nexaraild process on this machine.
  --evidence-dir   Save stop diagnostics under PATH/diagnostics.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --force)
            FORCE=1
            shift
            ;;
        --all-nexaraild)
            ALL_NEXARAILD=1
            shift
            ;;
        --evidence-dir)
            EVIDENCE_DIR="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [ -n "$EVIDENCE_DIR" ]; then
    mkdir -p "$EVIDENCE_DIR/diagnostics"
    exec > >(tee -a "$EVIDENCE_DIR/diagnostics/stop-validator-agents.log") 2>&1
fi

agent_process_pids() {
    if [ "$ALL_NEXARAILD" -eq 1 ]; then
        pgrep -f "nexaraild" 2>/dev/null || true
    else
        pgrep -f "nexaraild.*validator-agents" 2>/dev/null || true
    fi
}

safe_kill_pid() {
    local pid="$1"
    local label="$2"
    local cmd
    [ -z "$pid" ] && return 0
    cmd="$(ps -p "$pid" -o command= 2>/dev/null || true)"
    [ -z "$cmd" ] && return 0
    if [ "$ALL_NEXARAILD" -ne 1 ] && ! printf '%s\n' "$cmd" | grep -q "$AGENT_DIR"; then
        echo "  skip non-agent nexaraild PID $pid ($label): $cmd"
        return 0
    fi
    if kill "$pid" >/dev/null 2>&1; then
        echo "  stopped PID $pid ($label)"
        STOPPED=$((STOPPED + 1))
    else
        echo "  PID $pid already stopped ($label)"
    fi
}

force_kill_survivors() {
    local pid cmd
    [ "$FORCE" -eq 0 ] && return 0
    sleep 2
    agent_process_pids | while read -r pid; do
        [ -z "$pid" ] && continue
        cmd="$(ps -p "$pid" -o command= 2>/dev/null || true)"
        [ -z "$cmd" ] && continue
        if [ "$ALL_NEXARAILD" -eq 1 ] || printf '%s\n' "$cmd" | grep -q "$AGENT_DIR"; then
            if kill -KILL "$pid" >/dev/null 2>&1; then
                echo "  force stopped PID $pid"
            fi
        fi
    done
}

record_diagnostics() {
    [ -z "$EVIDENCE_DIR" ] && return 0
    {
        echo "Timestamp UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "Force: $FORCE"
        echo "All nexaraild: $ALL_NEXARAILD"
        echo "Agent dir: $AGENT_DIR"
    } > "$EVIDENCE_DIR/diagnostics/stop-context.txt"
    pgrep -la nexaraild > "$EVIDENCE_DIR/diagnostics/stop-pgrep-after.txt" 2>&1 || true
    ps aux 2>/dev/null | grep '[n]exaraild' > "$EVIDENCE_DIR/diagnostics/stop-ps-after.txt" || true
    "$SCRIPT_DIR/diagnose-agent-freeze.sh" --evidence-dir "$EVIDENCE_DIR" --label stop-after \
        > "$EVIDENCE_DIR/diagnostics/stop-after-diagnose.log" 2>&1 || true
}

echo "=== Stopping Validator Agents ==="
STOPPED=0

for name in alpha bravo charlie delta echo; do
    session="nexarail-agent-${name}"
    if command -v tmux >/dev/null 2>&1 && tmux has-session -t "$session" 2>/dev/null; then
        tmux kill-session -t "$session" >/dev/null 2>&1 || true
        echo "  stopped tmux session $session"
        STOPPED=$((STOPPED + 1))
    fi

    pid_file="$AGENT_DIR/pids/${name}.pid"
    if [ -f "$pid_file" ]; then
        pid="$(cat "$pid_file" 2>/dev/null || true)"
        safe_kill_pid "$pid" "$name pid-file"
        rm -f "$pid_file"
    else
        echo "  $name: no PID file"
    fi
done

agent_process_pids | while read -r pid; do
    [ -z "$pid" ] && continue
    safe_kill_pid "$pid" "orphan"
done

force_kill_survivors
sleep 1

remaining="$(agent_process_pids | sed '/^$/d' | wc -l | tr -d ' ')"
if [ "${remaining:-0}" -gt 0 ]; then
    echo ""
    echo "  remaining validator-agent nexaraild process(es):"
    agent_process_pids | sed '/^$/d' | while read -r pid; do
        echo "    PID $pid $(ps -p "$pid" -o command= 2>/dev/null || true)"
    done
else
    echo ""
    echo "  no validator-agent nexaraild processes running"
fi

record_diagnostics

echo ""
echo "=== Stop complete: stopped $STOPPED item(s) ==="
echo "Logs preserved at: $AGENT_DIR/logs/"

if [ "${remaining:-0}" -gt 0 ]; then
    exit 1
fi
