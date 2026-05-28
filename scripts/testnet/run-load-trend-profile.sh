#!/usr/bin/env bash
# NexaRail - local five-agent load trend profiler
#
# TESTNET/DEVNET ONLY. Runs repeated local load profiles and summarizes trends.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
AGENT_DIR="$PROJECT_DIR/rehearsals/validator-agents"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
EVIDENCE_DIR="${EVIDENCE_DIR:-$AGENT_DIR/load-trends/evidence/$TIMESTAMP}"
LEVELS="L1,L2,L3,L4"
DURATION=600
STOP_ON_FAIL=0
INCLUDE_L5=0
REUSE_BETWEEN_LEVELS=0

usage() {
    cat <<EOF
Usage: scripts/testnet/run-load-trend-profile.sh [options]

Options:
  --levels L1,L2,L3,L4       Comma-separated levels to run. Default: L1,L2,L3,L4
  --duration <seconds>       Per-level duration. Default: 600
  --stop-on-fail             Stop after first failed level
  --include-l5               Allow optional L5 exploratory level
  --evidence-dir <path>      Trend evidence directory
  --reuse-between-levels     Keep agents running and reuse runtime between levels
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --levels) LEVELS="${2:-}"; shift 2 ;;
        --duration) DURATION="${2:-}"; shift 2 ;;
        --stop-on-fail) STOP_ON_FAIL=1; shift ;;
        --include-l5) INCLUDE_L5=1; shift ;;
        --evidence-dir) EVIDENCE_DIR="${2:-}"; shift 2 ;;
        --reuse-between-levels) REUSE_BETWEEN_LEVELS=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

case "$DURATION" in
    *[!0-9]*|"") echo "--duration must be a positive integer." >&2; exit 2 ;;
esac
[ "$DURATION" -gt 0 ] || { echo "--duration must be >0" >&2; exit 2; }

mkdir -p "$EVIDENCE_DIR"
LEVEL_RESULTS="$EVIDENCE_DIR/level-results.tsv"
LEVEL_PATHS="$EVIDENCE_DIR/level-evidence-paths.txt"
RESOURCE_COMPARISON="$EVIDENCE_DIR/resource-comparison.tsv"
: > "$LEVEL_PATHS"
printf 'level\tduration\ttx_rate\tquery_rate\tconcurrency\tevidence\tphase_pass\tstart_height\tfinal_height\theight_delta\taverage_block_time_seconds\ttx_attempted\ttx_included\ttx_failed\tquery_attempted\tquery_success\tquery_failed\ttx_p50_ms\ttx_p95_ms\tquery_p50_ms\tquery_p95_ms\tpeer_range\tvalidator_range\tlive_flags_false\tpanic_scan\tchecktx_scan\tdescriptor_scan\tmax_cpu_percent\tmax_rss_kb\tmax_open_files\tmax_data_dir_kb\tfailure_class\n' > "$LEVEL_RESULTS"
printf 'level\tevidence\tresource_samples\tmax_cpu_percent\tmax_rss_kb\tmax_open_files\tmax_data_dir_kb\tload1_avg\tload1_max\tload5_avg\tload5_max\n' > "$RESOURCE_COMPARISON"

level_config() {
    case "$1" in
        L1) echo "1 5 2" ;;
        L2) echo "2 10 4" ;;
        L3) echo "4 20 6" ;;
        L4) echo "6 30 8" ;;
        L5) echo "8 40 10" ;;
        *) return 1 ;;
    esac
}

classify_failure() {
    python3 - "$1" <<'PY'
import json, sys
path = sys.argv[1]
try:
    with open(path) as f:
        s = json.load(f)
except Exception:
    print("script_limitation")
    raise SystemExit
if s.get("phase_pass") is True:
    print("none")
    raise SystemExit
tx_failed = s.get("tx", {}).get("failed_by_class", {})
if "sequence" in tx_failed:
    print("tx_sequence_pressure")
elif "mempool" in tx_failed:
    print("mempool_saturation")
elif "timeout" in tx_failed:
    print("tx_timeout")
elif "checktx" in tx_failed:
    print("unrecovered_checktx")
elif s.get("query", {}).get("failed", 0):
    failed = s.get("query", {}).get("failed_by_endpoint", {})
    if any(str(k).startswith("rpc_") for k in failed):
        print("rpc_timeout")
    else:
        print("rest_timeout")
elif not s.get("height_delta") or s.get("height_delta", 0) <= 0:
    print("consensus_stall")
elif s.get("validator_count_range", [None, None])[0] != 5 or s.get("validator_count_range", [None, None])[1] != 5:
    print("validator_set_drift")
elif any((s.get("scan_counts", {}).get(k) or 0) > 0 for k in ("panic", "checktx", "descriptor")):
    print("log_scan_failure")
else:
    print("script_limitation")
PY
}

append_level_result() {
    local level="$1" evidence="$2" tx_rate="$3" query_rate="$4" concurrency="$5" failure_class="$6"
    python3 - "$LEVEL_RESULTS" "$RESOURCE_COMPARISON" "$level" "$DURATION" "$tx_rate" "$query_rate" "$concurrency" "$evidence" "$failure_class" <<'PY'
import json, os, sys
level_results, resource_comparison, level, duration, tx_rate, query_rate, concurrency, evidence, failure_class = sys.argv[1:]

def load(path, default):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return default

def value(v):
    if v is None:
        return ""
    if isinstance(v, float):
        return f"{v:.6g}"
    if isinstance(v, bool):
        return str(v).lower()
    return str(v)

s = load(os.path.join(evidence, "summary.json"), {})
r = load(os.path.join(evidence, "resources-summary.json"), {})
tx = s.get("tx", {})
query = s.get("query", {})
scans = s.get("scan_counts", {})
peer = s.get("peer_count_range", ["", ""])
val = s.get("validator_count_range", ["", ""])
row = [
    level, duration, tx_rate, query_rate, concurrency, evidence,
    s.get("phase_pass"), s.get("start_height"), s.get("final_height"), s.get("height_delta"),
    s.get("average_block_time_seconds"), tx.get("attempted"), tx.get("included_code_0"),
    sum((tx.get("failed_by_class") or {}).values()), query.get("attempted"), query.get("success"),
    query.get("failed"), tx.get("p50_inclusion_latency_ms"), tx.get("p95_inclusion_latency_ms"),
    query.get("p50_latency_ms"), query.get("p95_latency_ms"),
    f"{peer[0]}-{peer[1]}", f"{val[0]}-{val[1]}", s.get("final_live_flags_false"),
    scans.get("panic"), scans.get("checktx"), scans.get("descriptor"),
    r.get("max_cpu_percent"), r.get("max_rss_kb"), r.get("max_open_files"), r.get("max_data_dir_kb"),
    failure_class,
]
with open(level_results, "a") as f:
    f.write("\t".join(value(x) for x in row) + "\n")

loadavg = r.get("load_average", {})
resource_row = [
    level, evidence, r.get("samples"), r.get("max_cpu_percent"), r.get("max_rss_kb"),
    r.get("max_open_files"), r.get("max_data_dir_kb"),
    loadavg.get("load1", {}).get("avg"), loadavg.get("load1", {}).get("max"),
    loadavg.get("load5", {}).get("avg"), loadavg.get("load5", {}).get("max"),
]
with open(resource_comparison, "a") as f:
    f.write("\t".join(value(x) for x in resource_row) + "\n")
PY
}

write_failure_thresholds() {
    cat > "$EVIDENCE_DIR/failure-thresholds.md" <<'EOF'
# Phase 16D Failure Thresholds

These thresholds apply only to local five-agent devnet trend profiling.

Use the previous clean level as the conservative local ceiling when any threshold is crossed:

- tx inclusion rate below 99%
- repeated sequence failures
- mempool or broadcast failures that persist beyond isolated transients
- query success below 99.5%
- repeated RPC or REST timeouts
- block height does not advance across at least two sample intervals
- validator count drops below 5
- peer count becomes unstable or unavailable
- any validator-agent process exits unexpectedly
- resource pressure coincides with tx/query failures
- panic/fatal, unrecovered CheckTx, descriptor, unknownproto, or gzip scan is nonzero
- final live flags are not false

Classification labels:

- `tx_sequence_pressure`
- `mempool_saturation`
- `tx_timeout`
- `rpc_timeout`
- `rest_timeout`
- `process_resource_pressure`
- `consensus_stall`
- `validator_set_drift`
- `log_scan_failure`
- `script_limitation`

Interpretation rule: do not describe any level as production throughput. Use "local five-agent devnet observed throughput".
EOF
}

write_safety_scan() {
    local pattern='mainnet live|buy NXRL|token sale|investment|guaranteed|profit|APY|returns|price|listing|external decentralisation|independent validators|private key|mnemonic|seed phrase|npm publish|PyPI publish'
    {
        echo "Phase 16D generated-evidence safety scan"
        echo "Timestamp UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo ""
        if rg -n -i "$pattern" "$EVIDENCE_DIR" --glob '!**/logs/**' --glob '!**/tx/**' --glob '!**/queries/**' 2>/dev/null; then
            true
        else
            echo "No generated-evidence matches."
        fi
    } > "$EVIDENCE_DIR/safety-scan.txt"
}

write_trend_summary() {
    python3 - "$EVIDENCE_DIR" "$LEVEL_RESULTS" "$LEVEL_PATHS" <<'PY'
import csv, json, os, sys

root, level_results, level_paths = sys.argv[1:]
rows = []
with open(level_results) as f:
    for row in csv.DictReader(f, delimiter="\t"):
        rows.append(row)

def as_float(row, key):
    try:
        value = row.get(key, "")
        if value == "":
            return None
        return float(value)
    except Exception:
        return None

def as_bool(row, key):
    return str(row.get(key, "")).lower() == "true"

clean = []
for row in rows:
    tx_attempted = as_float(row, "tx_attempted") or 0
    tx_included = as_float(row, "tx_included") or 0
    query_attempted = as_float(row, "query_attempted") or 0
    query_success = as_float(row, "query_success") or 0
    clean_level = (
        as_bool(row, "phase_pass")
        and (tx_attempted == 0 or tx_included == tx_attempted)
        and (query_attempted == 0 or query_success == query_attempted)
        and row.get("live_flags_false") == "true"
        and row.get("panic_scan") in ("0", "0.0")
        and row.get("checktx_scan") in ("0", "0.0")
        and row.get("descriptor_scan") in ("0", "0.0")
    )
    if clean_level:
        clean.append(row)

ceiling = clean[-1]["level"] if clean else "none"
summary = {
    "phase": "16D",
    "evidence": root,
    "levels": rows,
    "clean_levels": [r["level"] for r in clean],
    "conservative_local_ceiling": ceiling,
    "interpretation": "local five-agent devnet observed throughput only; not production throughput",
}
with open(os.path.join(root, "trend-summary.json"), "w") as f:
    json.dump(summary, f, indent=2)
    f.write("\n")

lines = [
    "# Phase 16D Trend Summary",
    "",
    f"Evidence: `{root}`",
    "",
    f"Conservative local ceiling: `{ceiling}`",
    "",
    "Interpretation: local five-agent devnet observed throughput only. This is not production throughput and does not imply public network performance.",
    "",
    "| Level | Pass | Height Delta | Tx Included / Attempted | Query Success / Attempted | Tx p95 ms | Query p95 ms | Max CPU % | Max RSS KB | Failure Class |",
    "|---|---:|---:|---:|---:|---:|---:|---:|---:|---|",
]
for row in rows:
    lines.append(
        f"| {row['level']} | {row['phase_pass']} | {row['height_delta']} | "
        f"{row['tx_included']} / {row['tx_attempted']} | {row['query_success']} / {row['query_attempted']} | "
        f"{row['tx_p95_ms']} | {row['query_p95_ms']} | {row['max_cpu_percent']} | {row['max_rss_kb']} | {row['failure_class']} |"
    )
lines.extend([
    "",
    "## Evidence Paths",
    "",
])
try:
    with open(level_paths) as f:
        for line in f:
            line = line.strip()
            if line:
                lines.append(f"- `{line}`")
except FileNotFoundError:
    pass
lines.append("")
with open(os.path.join(root, "trend-summary.md"), "w") as f:
    f.write("\n".join(lines))
PY
}

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  NexaRail - Local Load Trend Profile                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo "  Levels: $LEVELS"
echo "  Duration: ${DURATION}s per level"
echo "  Evidence: $EVIDENCE_DIR"
echo ""

IFS=',' read -r -a REQUESTED_LEVELS <<< "$LEVELS"
OVERALL_RC=0
LEVEL_INDEX=0

for level in "${REQUESTED_LEVELS[@]}"; do
    level="$(printf '%s' "$level" | tr -d '[:space:]')"
    [ -z "$level" ] && continue
    if [ "$level" = "L5" ] && [ "$INCLUDE_L5" -ne 1 ]; then
        echo "  Skipping L5 because --include-l5 was not set"
        continue
    fi
    if ! cfg="$(level_config "$level")"; then
        echo "Unknown level: $level" >&2
        OVERALL_RC=1
        [ "$STOP_ON_FAIL" -eq 1 ] && break
        continue
    fi
    read -r tx_rate query_rate concurrency <<< "$cfg"
    level_dir="$EVIDENCE_DIR/$level"
    echo "── $level: tx-rate=$tx_rate query-rate=$query_rate concurrency=$concurrency ──"
    args=(
        --duration "$DURATION"
        --tx-rate "$tx_rate"
        --query-rate "$query_rate"
        --concurrency "$concurrency"
        --sample-interval 30
        --resource-sampling
        --resource-interval 30
        --label "$level"
        --evidence-dir "$level_dir"
    )
    if [ "$REUSE_BETWEEN_LEVELS" -eq 1 ]; then
        args+=(--keep-running)
        [ "$LEVEL_INDEX" -gt 0 ] && args+=(--reuse-running)
    fi
    set +e
    "$SCRIPT_DIR/run-five-agent-load-sim.sh" "${args[@]}" > "$level_dir.log" 2>&1
    rc=$?
    set +e
    echo "$level $level_dir" >> "$LEVEL_PATHS"
    failure_class="script_limitation"
    [ -f "$level_dir/summary.json" ] && failure_class="$(classify_failure "$level_dir/summary.json")"
    append_level_result "$level" "$level_dir" "$tx_rate" "$query_rate" "$concurrency" "$failure_class"
    if [ "$rc" -ne 0 ]; then
        echo "  $level failed rc=$rc class=$failure_class"
        OVERALL_RC=1
        [ "$STOP_ON_FAIL" -eq 1 ] && break
    else
        echo "  $level passed"
    fi
    LEVEL_INDEX=$((LEVEL_INDEX + 1))
done

if [ "$REUSE_BETWEEN_LEVELS" -eq 1 ]; then
    bash "$SCRIPT_DIR/stop-validator-agents.sh" --force --evidence-dir "$EVIDENCE_DIR" > "$EVIDENCE_DIR/final-stop.log" 2>&1 || true
    bash "$SCRIPT_DIR/clean-validator-agent-runtime.sh" --force > "$EVIDENCE_DIR/final-clean.log" 2>&1 || true
fi

write_failure_thresholds
write_safety_scan
write_trend_summary

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Load Trend Profile Complete                               ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "  Evidence: $EVIDENCE_DIR"
echo "  Summary:  $EVIDENCE_DIR/trend-summary.md"
echo "╚══════════════════════════════════════════════════════════════╝"

exit "$OVERALL_RC"
