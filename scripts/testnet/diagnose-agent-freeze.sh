#!/usr/bin/env bash
# NexaRail — validator-agent freeze diagnostics
#
# TESTNET/DEVNET ONLY. Non-interactive evidence collector.
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
SCRIPT_DIR="$PROJECT_DIR/scripts/testnet"
AGENT_DIR="$PROJECT_DIR/rehearsals/validator-agents"
EVIDENCE_DIR="$AGENT_DIR/diagnostics/evidence/$(date -u +%Y%m%dT%H%M%SZ)"
LABEL="diagnostic"
KILL=0

usage() {
    cat <<EOF
Usage: scripts/testnet/diagnose-agent-freeze.sh --evidence-dir PATH --label LABEL [--kill]

Collects non-interactive diagnostics for local validator-agent freezes.
--kill only terminates nexaraild processes whose command line includes the validator-agent home.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --evidence-dir)
            EVIDENCE_DIR="${2:-}"
            shift 2
            ;;
        --label)
            LABEL="${2:-}"
            shift 2
            ;;
        --kill)
            KILL=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "" >&2
            echo "ERROR: Unknown argument: $1" >&2
            echo "Why: The script accepts: --evidence-dir PATH, --label LABEL, --kill" >&2
            echo "Rerun with correct arguments, e.g.:" >&2
            echo "  $0 --evidence-dir \"$EVIDENCE_DIR\" --label \"$LABEL\"" >&2
            echo "" >&2
            usage >&2
            exit 2
            ;;
    esac
done

DIAG_DIR="$EVIDENCE_DIR/diagnostics/$LABEL"
mkdir -p "$DIAG_DIR"/{logs,configs,status}

run_txt() {
    local outfile="$1"
    shift
    {
        echo "$ $*"
        "$@" 2>&1 || true
    } > "$outfile"
}

append_cmd() {
    local outfile="$1"
    shift
    {
        echo ""
        echo "$ $*"
        "$@" 2>&1 || true
    } >> "$outfile"
}

port_report() {
    local outfile="$1"
    : > "$outfile"
    for port in 27657 27667 27677 27687 27697 27656 27666 27676 27686 27696 1417 1418 1419 1420 1421 9190 9191 9192 9193 9194; do
        {
            echo "### port $port"
            lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>&1 || true
        } >> "$outfile"
    done
}

agent_pids() {
    pgrep -f "nexaraild.*validator-agents" 2>/dev/null || true
}

kill_agent_pids() {
    local pids pid
    pids="$(agent_pids)"
    [ -z "$pids" ] && return 0
    printf '%s\n' "$pids" | while read -r pid; do
        [ -z "$pid" ] && continue
        if ps -p "$pid" -o command= 2>/dev/null | grep -q "$AGENT_DIR"; then
            echo "killing validator-agent PID $pid (cmd: $(ps -p "$pid" -o command= 2>/dev/null || echo 'unknown'))" >> "$DIAG_DIR/killed-pids.txt"
            kill "$pid" >/dev/null 2>&1 || echo "warning: kill $pid failed — process may have already exited" >> "$DIAG_DIR/killed-pids.txt"
        else
            echo "skipped non-validator-agent PID $pid (cmd: $(ps -p "$pid" -o command= 2>/dev/null || echo 'unknown')) — does not match AGENT_DIR=$AGENT_DIR" >> "$DIAG_DIR/killed-pids.txt"
        fi
    done
    sleep 2
    pids="$(agent_pids)"
    [ -z "$pids" ] && return 0
    printf '%s\n' "$pids" | while read -r pid; do
        [ -z "$pid" ] && continue
        if ps -p "$pid" -o command= 2>/dev/null | grep -q "$AGENT_DIR"; then
            echo "force killing validator-agent PID $pid" >> "$DIAG_DIR/killed-pids.txt"
            kill -KILL "$pid" >/dev/null 2>&1 || true
        fi
    done
}

config_snippets() {
    local outfile="$1"
    : > "$outfile"
    for agent in alpha bravo charlie delta echo; do
        home="$AGENT_DIR/$agent"
        {
            echo "### $agent"
            echo "home_exists=$([ -d "$home" ] && echo yes || echo no)"
            echo "config_exists=$([ -f "$home/config/config.toml" ] && echo yes || echo no)"
            echo "app_exists=$([ -f "$home/config/app.toml" ] && echo yes || echo no)"
            echo "data_exists=$([ -d "$home/data" ] && echo yes || echo no)"
            if [ -f "$home/config/config.toml" ]; then
                echo "--- config.toml ports ---"
                grep -E '^(proxy_app|laddr|persistent_peers|pex|addr_book_strict|allow_duplicate_ip) =' "$home/config/config.toml" 2>/dev/null || true
            fi
            if [ -f "$home/config/app.toml" ]; then
                echo "--- app.toml api/grpc snippets ---"
                awk '
                    /^\[(api|grpc|grpc-web|rosetta)\]$/ {show=1; print; next}
                    /^\[/ {show=0}
                    show && /^(enable|address) =/ {print}
                ' "$home/config/app.toml" 2>/dev/null || true
            fi
            echo ""
        } >> "$outfile"
    done
}

node_status() {
    for item in alpha:27657 bravo:27667 charlie:27677 delta:27687 echo:27697; do
        IFS=':' read -r agent rpc <<< "$item"
        curl -s --max-time 5 "http://127.0.0.1:$rpc/status" > "$DIAG_DIR/status/${agent}-status.json" 2> "$DIAG_DIR/status/${agent}-status.err" || true
        curl -s --max-time 5 "http://127.0.0.1:$rpc/net_info" > "$DIAG_DIR/status/${agent}-net_info.json" 2> "$DIAG_DIR/status/${agent}-net_info.err" || true
        curl -s --max-time 5 "http://127.0.0.1:$rpc/validators" > "$DIAG_DIR/status/${agent}-validators.json" 2> "$DIAG_DIR/status/${agent}-validators.err" || true
    done
}

latest_evidence() {
    {
        echo "### product-flow evidence"
        find "$AGENT_DIR/product-flows/evidence" -maxdepth 1 -type d 2>/dev/null | sort | tail -10 || true
        echo ""
        echo "### clean-spawn evidence"
        find "$AGENT_DIR/clean-spawn-governance/evidence" -maxdepth 1 -type d 2>/dev/null | sort | tail -10 || true
        echo ""
        echo "### latest spawn logs"
        find "$AGENT_DIR" -path '*spawn.log' -type f -print 2>/dev/null | sort | tail -10 || true
    } > "$DIAG_DIR/latest-evidence.txt"
}

validator_logs() {
    for agent in alpha bravo charlie delta echo; do
        if [ -f "$AGENT_DIR/logs/${agent}.log" ]; then
            cp "$AGENT_DIR/logs/${agent}.log" "$DIAG_DIR/logs/${agent}.log" 2>/dev/null || true
            tail -200 "$AGENT_DIR/logs/${agent}.log" > "$DIAG_DIR/logs/${agent}-last-200.log" 2>/dev/null || true
        else
            echo "missing $AGENT_DIR/logs/${agent}.log" > "$DIAG_DIR/logs/${agent}-missing.txt"
        fi
    done
}

descriptor_errors() {
    local outfile="$DIAG_DIR/descriptor-errors.txt"
    : > "$outfile"
    {
        find "$EVIDENCE_DIR" \
            \( -path "$EVIDENCE_DIR/diagnostics" -o -name descriptor-errors.txt \) -prune -o \
            -type f \( -name '*.log' -o -name '*.err' -o -name '*.json' -o -name 'run.log' -o -name 'spawn.log' -o -name 'query.log' \) -print 2>/dev/null
        find "$AGENT_DIR/logs" -type f -name '*.log' -print 2>/dev/null
    } | sort -u | while read -r file; do
        [ -f "$file" ] || continue
        grep -E -i "unknownproto|Descriptor|index out of range|gzip|invalid header|CheckTx|panic" "$file" 2>/dev/null | sed "s|^|$file:|" || true
    done > "$outfile"
}

cat > "$DIAG_DIR/context.txt" <<EOF
Timestamp UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Label: $LABEL
Project: $PROJECT_DIR
Agent dir: $AGENT_DIR
Evidence dir: $EVIDENCE_DIR
PWD: $(pwd)
EOF

run_txt "$DIAG_DIR/git-commit.txt" git -C "$PROJECT_DIR" rev-parse HEAD
run_txt "$DIAG_DIR/git-status.txt" git -C "$PROJECT_DIR" status --short
run_txt "$DIAG_DIR/go-version.txt" go version
run_txt "$DIAG_DIR/uname.txt" uname -a
run_txt "$DIAG_DIR/disk-space.txt" df -h "$PROJECT_DIR"
run_txt "$DIAG_DIR/ulimit.txt" sh -c 'ulimit -a'
run_txt "$DIAG_DIR/pgrep-nexaraild.txt" pgrep -la nexaraild
run_txt "$DIAG_DIR/ps-nexaraild.txt" sh -c "ps aux | grep '[n]exaraild'"
run_txt "$DIAG_DIR/tmux-ls.txt" tmux ls
port_report "$DIAG_DIR/lsof-agent-ports.txt"
latest_evidence
validator_logs
run_txt "$DIAG_DIR/pid-files.txt" sh -c "find '$AGENT_DIR/pids' -type f -maxdepth 1 -print -exec cat {} \\; 2>/dev/null"
config_snippets "$DIAG_DIR/config-snippets.txt"
node_status
descriptor_errors

if [ "$KILL" -eq 1 ]; then
    kill_agent_pids
    run_txt "$DIAG_DIR/pgrep-after-kill.txt" pgrep -la nexaraild
    port_report "$DIAG_DIR/lsof-after-kill.txt"
fi

cat > "$DIAG_DIR/summary.txt" <<EOF
NexaRail validator-agent diagnostic summary
Timestamp UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Label: $LABEL
Evidence: $EVIDENCE_DIR
Diagnostic dir: $DIAG_DIR
Validator-agent pids: $(agent_pids | tr '\n' ' ')
Descriptor/CheckTx matches: $(wc -l < "$DIAG_DIR/descriptor-errors.txt" 2>/dev/null || echo 0)
---
WHAT WAS COLLECTED:
- context.txt: diagnostic runtime context
- status/*.json: RPC status/net_info/validators per agent
- logs/: agent validator logs (last 200 lines)
- config-snippets.txt: config.toml/app.toml ports & api/grpc settings
- lsof-agent-ports.txt: port occupancy report
- pgrep-nexaraild.txt / ps-nexaraild.txt: process listing
- descriptor-errors.txt: descriptor/CheckTx error matches
- git-commit.txt, git-status.txt, go-version.txt: build state
---
COMMON FREEZE CAUSES:
- Descriptor proto mismatch (compile with matching buf version)
- gzip corrupt block (check disk space: df -h $PROJECT_DIR)
- Index out of range (stale data directory)
- Port conflict (check lsof-agent-ports.txt)
- Validator Jailed / not in active set (check status json)
- RPC not responding / port mismatch (check config.toml laddr)
---
RERUN: $0 --evidence-dir "$EVIDENCE_DIR" --label "$LABEL"${KILL:+ --kill}
EOF

echo ""
echo "========================================================"
echo "  NexaRail Validator-Agent Freeze Diagnostics"
echo "  Label: $LABEL"
echo "  Evidence: $DIAG_DIR"
echo "  Summary: $DIAG_DIR/summary.txt"
echo "========================================================"
echo ""
echo "  WHAT: Collected diagnostics for $LABEL"
echo "  WHY: See summary.txt for common freeze causes."
echo "  EVIDENCE: All diagnostic files in $DIAG_DIR/"
echo "  RERUN: $0 --evidence-dir \"$EVIDENCE_DIR\" --label \"$LABEL\"${KILL:+ --kill}"
echo ""
