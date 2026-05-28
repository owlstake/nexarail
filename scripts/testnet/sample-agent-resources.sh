#!/usr/bin/env bash
# NexaRail - local validator-agent resource sampler
#
# TESTNET/DEVNET ONLY. Samples local process/resource metrics without sudo.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
AGENT_DIR="$PROJECT_DIR/rehearsals/validator-agents"
EVIDENCE_DIR="${EVIDENCE_DIR:-$AGENT_DIR/load-sim/evidence/resources-$(date -u +%Y%m%dT%H%M%SZ)}"
INTERVAL=30
DURATION=0
STOP_FILE=""
ONCE=0

AGENTS=(alpha bravo charlie delta echo)

usage() {
    cat <<EOF
Usage: scripts/testnet/sample-agent-resources.sh [options]

Options:
  --evidence-dir <path>   Directory for resources.tsv and resources-summary.json
  --interval <seconds>    Sampling interval. Default: 30
  --duration <seconds>    Optional max duration. Default: unlimited until stop-file
  --stop-file <path>      Stop when this file exists
  --once                  Take one sample and write summary
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --evidence-dir) EVIDENCE_DIR="${2:-}"; shift 2 ;;
        --interval) INTERVAL="${2:-}"; shift 2 ;;
        --duration) DURATION="${2:-}"; shift 2 ;;
        --stop-file) STOP_FILE="${2:-}"; shift 2 ;;
        --once) ONCE=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

case "$INTERVAL:$DURATION" in
    *[!0-9:]*|"") echo "Numeric options must be non-negative integers." >&2; exit 2 ;;
esac
[ "$INTERVAL" -gt 0 ] || { echo "--interval must be >0" >&2; exit 2; }

mkdir -p "$EVIDENCE_DIR"
RESOURCES_TSV="$EVIDENCE_DIR/resources.tsv"
SUMMARY_JSON="$EVIDENCE_DIR/resources-summary.json"

if [ ! -f "$RESOURCES_TSV" ]; then
    printf 'epoch\ttime_utc\tagent\tpid\tcpu_percent\trss_kb\topen_files\tprocess_uptime\tdata_dir_kb\tload1\tload5\tload15\n' > "$RESOURCES_TSV"
fi

load_average() {
    if command -v sysctl >/dev/null 2>&1; then
        sysctl -n vm.loadavg 2>/dev/null | awk '{gsub(/[{}]/,""); print $1 "\t" $2 "\t" $3}' && return 0
    fi
    if [ -r /proc/loadavg ]; then
        awk '{print $1 "\t" $2 "\t" $3}' /proc/loadavg && return 0
    fi
    printf '\t\t\n'
}

agent_pid() {
    local name="$1" pid_file pid
    pid_file="$AGENT_DIR/pids/${name}.pid"
    if [ -f "$pid_file" ]; then
        pid="$(cat "$pid_file" 2>/dev/null || true)"
        if [ -n "$pid" ] && kill -0 "$pid" >/dev/null 2>&1; then
            echo "$pid"
            return 0
        fi
    fi
    pgrep -f "nexaraild.*$AGENT_DIR/$name" 2>/dev/null | head -1 || true
}

sample_once() {
    local epoch utc load_vals load1 load5 load15 name pid cpu rss uptime open_files data_kb ps_line
    epoch="$(date +%s)"
    utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    load_vals="$(load_average)"
    load1="$(printf '%s' "$load_vals" | awk '{print $1}')"
    load5="$(printf '%s' "$load_vals" | awk '{print $2}')"
    load15="$(printf '%s' "$load_vals" | awk '{print $3}')"

    for name in "${AGENTS[@]}"; do
        pid="$(agent_pid "$name")"
        cpu=""
        rss=""
        uptime=""
        open_files=""
        if [ -n "$pid" ]; then
            ps_line="$(ps -p "$pid" -o %cpu= -o rss= -o etime= 2>/dev/null | awk '{$1=$1; print}' || true)"
            cpu="$(printf '%s' "$ps_line" | awk '{print $1}')"
            rss="$(printf '%s' "$ps_line" | awk '{print $2}')"
            uptime="$(printf '%s' "$ps_line" | awk '{print $3}')"
            if command -v lsof >/dev/null 2>&1; then
                open_files="$(lsof -p "$pid" 2>/dev/null | wc -l | tr -d ' ')"
            fi
        fi
        if [ -d "$AGENT_DIR/$name" ]; then
            data_kb="$(du -sk "$AGENT_DIR/$name" 2>/dev/null | awk '{print $1}')"
        else
            data_kb=""
        fi
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$epoch" "$utc" "$name" "$pid" "$cpu" "$rss" "$open_files" "$uptime" "$data_kb" "$load1" "$load5" "$load15" \
            >> "$RESOURCES_TSV"
    done
}

write_summary() {
    python3 - "$RESOURCES_TSV" "$SUMMARY_JSON" <<'PY'
import csv, json, statistics, sys
from collections import defaultdict

tsv, out = sys.argv[1:]
rows = []
try:
    with open(tsv) as f:
        for row in csv.DictReader(f, delimiter="\t"):
            rows.append(row)
except FileNotFoundError:
    rows = []

def num(row, key):
    try:
        value = row.get(key, "")
        if value == "":
            return None
        return float(value)
    except Exception:
        return None

def stats(values):
    values = [v for v in values if isinstance(v, (int, float))]
    if not values:
        return {"avg": None, "max": None}
    return {"avg": sum(values) / len(values), "max": max(values)}

by_agent = defaultdict(list)
for row in rows:
    by_agent[row.get("agent", "unknown")].append(row)

agents = {}
max_cpu = 0.0
max_rss = 0.0
max_open_files = 0.0
max_data_dir_kb = 0.0
for agent, items in sorted(by_agent.items()):
    cpu = [num(r, "cpu_percent") for r in items]
    rss = [num(r, "rss_kb") for r in items]
    open_files = [num(r, "open_files") for r in items]
    data_dir = [num(r, "data_dir_kb") for r in items]
    agent_summary = {
        "samples": len(items),
        "pid_seen": any((r.get("pid") or "") for r in items),
        "cpu_percent": stats(cpu),
        "rss_kb": stats(rss),
        "open_files": stats(open_files),
        "data_dir_kb": stats(data_dir),
    }
    agents[agent] = agent_summary
    for value in [agent_summary["cpu_percent"]["max"]]:
        if isinstance(value, (int, float)):
            max_cpu = max(max_cpu, value)
    for value in [agent_summary["rss_kb"]["max"]]:
        if isinstance(value, (int, float)):
            max_rss = max(max_rss, value)
    for value in [agent_summary["open_files"]["max"]]:
        if isinstance(value, (int, float)):
            max_open_files = max(max_open_files, value)
    for value in [agent_summary["data_dir_kb"]["max"]]:
        if isinstance(value, (int, float)):
            max_data_dir_kb = max(max_data_dir_kb, value)

load1 = [num(r, "load1") for r in rows]
load5 = [num(r, "load5") for r in rows]
load15 = [num(r, "load15") for r in rows]
summary = {
    "samples": len(rows),
    "agents": agents,
    "max_cpu_percent": max_cpu if rows else None,
    "max_rss_kb": max_rss if rows else None,
    "max_open_files": max_open_files if rows else None,
    "max_data_dir_kb": max_data_dir_kb if rows else None,
    "load_average": {
        "load1": stats(load1),
        "load5": stats(load5),
        "load15": stats(load15),
    },
}
with open(out, "w") as f:
    json.dump(summary, f, indent=2)
    f.write("\n")
PY
}

START_EPOCH="$(date +%s)"
while true; do
    sample_once
    [ "$ONCE" -eq 1 ] && break
    [ -n "$STOP_FILE" ] && [ -f "$STOP_FILE" ] && break
    if [ "$DURATION" -gt 0 ]; then
        now="$(date +%s)"
        [ $((now - START_EPOCH)) -ge "$DURATION" ] && break
    fi
    sleep "$INTERVAL"
done

write_summary
