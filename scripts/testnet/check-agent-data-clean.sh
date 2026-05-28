#!/usr/bin/env bash
# NexaRail — Validator Agent Stale Data Guard
#
# TESTNET/DEVNET ONLY.
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
AGENT_DIR="$PROJECT_DIR/rehearsals/validator-agents"
MODE="strict"
JSON=0
EVIDENCE_DIR=""

usage() {
    cat <<EOF
Usage: scripts/testnet/check-agent-data-clean.sh [--clean|--allow-reuse|--reuse-data] [--json] [--evidence-dir PATH]

Default: fail if validator-agent homes contain stale runtime state.
  --clean        Allow stale files because caller will wipe before spawn.
  --allow-reuse  Allow stale files because caller explicitly requested reuse.
  --reuse-data   Alias for --allow-reuse.
  --json         Emit machine-readable JSON summary.
  --evidence-dir Save text and JSON summaries under PATH/diagnostics.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --clean)
            MODE="clean"
            shift
            ;;
        --allow-reuse|--reuse-data)
            MODE="reuse-data"
            shift
            ;;
        --json)
            JSON=1
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

AGENTS=(alpha bravo charlie delta echo)
CHECKS=(
    "data/application.db"
    "data/blockstore.db"
    "data/state.db"
    "config/genesis.json"
    "logs"
    "pid"
)
FOUND=0
TEXT_OUT="$(mktemp)"
JSON_OUT="$(mktemp)"
trap 'rm -f "$TEXT_OUT" "$JSON_OUT"' EXIT

{
    echo "=== Validator Agent Data Clean Check ==="
    echo "Agent dir: $AGENT_DIR"
    echo "Mode: $MODE"
    echo ""
} > "$TEXT_OUT"

printf '{"agent_dir":%s,"mode":%s,"agents":[' \
    "$(jq -Rn --arg v "$AGENT_DIR" '$v')" \
    "$(jq -Rn --arg v "$MODE" '$v')" > "$JSON_OUT"

first_agent=1
for agent in "${AGENTS[@]}"; do
    home="$AGENT_DIR/$agent"
    agent_found=0
    findings=()

    [ "$first_agent" -eq 0 ] && printf ',' >> "$JSON_OUT"
    first_agent=0
    printf '{"name":%s,"home":%s,"findings":[' \
        "$(jq -Rn --arg v "$agent" '$v')" \
        "$(jq -Rn --arg v "$home" '$v')" >> "$JSON_OUT"

    if [ ! -d "$home" ]; then
        echo "  OK  $agent: home does not exist" >> "$TEXT_OUT"
        printf ']}' >> "$JSON_OUT"
        continue
    fi

    for rel in "${CHECKS[@]}"; do
        case "$rel" in
            logs)
                path="$AGENT_DIR/logs/${agent}.log"
                ;;
            pid)
                path="$AGENT_DIR/pids/${agent}.pid"
                ;;
            *)
                path="$home/$rel"
                ;;
        esac
        if [ -e "$path" ]; then
            FOUND=1
            agent_found=1
            findings+=("$rel")
            echo "  STALE $agent: found $rel" >> "$TEXT_OUT"
        fi
    done

    for i in "${!findings[@]}"; do
        [ "$i" -gt 0 ] && printf ',' >> "$JSON_OUT"
        printf '%s' "$(jq -Rn --arg v "${findings[$i]}" '$v')" >> "$JSON_OUT"
    done
    printf ']}' >> "$JSON_OUT"

    if [ "$agent_found" -eq 0 ]; then
        echo "  OK  $agent: no guarded runtime files found" >> "$TEXT_OUT"
    fi
done

printf '],"found":%s}' "$([ "$FOUND" -eq 1 ] && echo true || echo false)" >> "$JSON_OUT"
echo "" >> "$TEXT_OUT"

if [ "$FOUND" -eq 0 ]; then
    echo "PASS Agent data clean: no guarded stale files found" >> "$TEXT_OUT"
    EXIT_CODE=0
else
    case "$MODE" in
        clean)
            echo "PASS Stale files detected; clean mode selected, caller must wipe before spawn" >> "$TEXT_OUT"
            EXIT_CODE=0
            ;;
        reuse-data)
            echo "PASS Stale files detected; reuse explicitly permitted for diagnostics" >> "$TEXT_OUT"
            EXIT_CODE=0
            ;;
        *)
            echo "FAIL Refusing to spawn against stale validator data" >> "$TEXT_OUT"
            EXIT_CODE=1
            ;;
    esac
fi

if [ -n "$EVIDENCE_DIR" ]; then
    mkdir -p "$EVIDENCE_DIR/diagnostics"
    cp "$TEXT_OUT" "$EVIDENCE_DIR/diagnostics/check-agent-data-clean.txt"
    cp "$JSON_OUT" "$EVIDENCE_DIR/diagnostics/check-agent-data-clean.json"
fi

if [ "$JSON" -eq 1 ]; then
    cat "$JSON_OUT"
    echo ""
else
    cat "$TEXT_OUT"
fi

exit "$EXIT_CODE"
