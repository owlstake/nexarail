#!/usr/bin/env bash
# NexaRail - Phase 9U agent long-soak collector.
#
# TESTNET/DEVNET ONLY. Requires agents to be started explicitly first, usually:
#   scripts/testnet/spawn-validator-agents.sh --clean
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../.. && pwd)"
AGENT_DIR="$PROJECT_DIR/rehearsals/validator-agents"
BINARY="$PROJECT_DIR/build/nexaraild"
TIMESTAMP="${SOAK_TIMESTAMP:-$(date -u +%Y%m%dT%H%M%SZ)}"
EVIDENCE_DIR_DEFAULT="$AGENT_DIR/long-soak/evidence/$TIMESTAMP"
EVIDENCE_DIR="${SOAK_EVIDENCE_DIR:-$EVIDENCE_DIR_DEFAULT}"
DURATION_RAW="10m"
SAMPLE_INTERVAL_RAW="60s"
QUERY_INTERVAL_RAW="15m"

AGENTS=(
    "alpha:27657:1417"
    "bravo:27667:1418"
    "charlie:27677:1419"
    "delta:27687:1420"
    "echo:27697:1421"
)

usage() {
    cat <<EOF
Usage: scripts/testnet/run-agent-soak-test.sh [--duration 60m] [options]

Options:
  --duration VALUE        Soak duration. Supports Ns, Nm, Nh, or plain minutes.
  --interval VALUE        Status sample interval. Default: 60s.
  --query-interval VALUE  Full readback interval. Default: 15m.
  --evidence-dir PATH     Evidence directory. Default: rehearsals/validator-agents/long-soak/evidence/<timestamp>.
  -h, --help              Show this help.

Legacy positional minutes are still accepted, e.g.:
  scripts/testnet/run-agent-soak-test.sh 60
EOF
}

parse_duration_seconds() {
    local raw="$1"
    case "$raw" in
        *s) echo "${raw%s}" ;;
        *m) echo "$(( ${raw%m} * 60 ))" ;;
        *h) echo "$(( ${raw%h} * 3600 ))" ;;
        ''|*[!0-9]*)
            echo "Invalid duration: $raw" >&2
            exit 2
            ;;
        *) echo "$(( raw * 60 ))" ;;
    esac
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --duration)
            DURATION_RAW="${2:-}"
            shift 2
            ;;
        --interval)
            SAMPLE_INTERVAL_RAW="${2:-}"
            shift 2
            ;;
        --query-interval)
            QUERY_INTERVAL_RAW="${2:-}"
            shift 2
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
            if [[ "$1" =~ ^[0-9]+$ ]]; then
                DURATION_RAW="${1}m"
                shift
            else
                echo "Unknown argument: $1" >&2
                usage
                exit 2
            fi
            ;;
    esac
done

DURATION_SECONDS="$(parse_duration_seconds "$DURATION_RAW")"
SAMPLE_INTERVAL_SECONDS="$(parse_duration_seconds "$SAMPLE_INTERVAL_RAW")"
QUERY_INTERVAL_SECONDS="$(parse_duration_seconds "$QUERY_INTERVAL_RAW")"

if [ "$DURATION_SECONDS" -le 0 ] || [ "$SAMPLE_INTERVAL_SECONDS" -le 0 ] || [ "$QUERY_INTERVAL_SECONDS" -le 0 ]; then
    echo "Duration and intervals must be greater than zero." >&2
    exit 2
fi

mkdir -p "$EVIDENCE_DIR/status-samples" "$EVIDENCE_DIR/query-samples" "$EVIDENCE_DIR/logs"
printf '%s\n' "$TIMESTAMP" > "$AGENT_DIR/phase9u-latest-evidence-timestamp.txt"
printf '%s\n' "$EVIDENCE_DIR" > "$AGENT_DIR/phase9u-latest-evidence-path.txt"

json_get() {
    local file="$1"
    local expr="$2"
    jq -r "$expr" "$file" 2>/dev/null || echo ""
}

status_url() {
    local rpc="$1"
    local endpoint="$2"
    curl -s --max-time 5 "http://127.0.0.1:${rpc}/${endpoint}"
}

agent_pid() {
    local name="$1"
    local pid_file="$AGENT_DIR/pids/${name}.pid"
    if [ -f "$pid_file" ]; then
        cat "$pid_file"
    fi
}

agent_resource_sample() {
    local name="$1"
    local pid cpu mem rss
    pid="$(agent_pid "$name" || true)"
    if [ -n "${pid:-}" ] && kill -0 "$pid" 2>/dev/null; then
        read -r cpu mem rss < <(ps -p "$pid" -o %cpu= -o %mem= -o rss= 2>/dev/null | awk '{print $1, $2, $3}')
        printf '%s\t%s\t%s\t%s' "${pid:-0}" "${cpu:-0}" "${mem:-0}" "${rss:-0}"
    else
        printf '0\t0\t0\t0'
    fi
}

require_runtime() {
    local reachable=0
    if [ ! -x "$BINARY" ]; then
        echo "Binary not found or not executable: $BINARY" >&2
        exit 1
    fi

    for agent_def in "${AGENTS[@]}"; do
        IFS=':' read -r name rpc api <<< "$agent_def"
        if status_url "$rpc" "status" | jq -e '.result.sync_info.latest_block_height' >/dev/null 2>&1; then
            reachable=$((reachable + 1))
        else
            echo "Agent not reachable for soak preflight: $name RPC:$rpc API:$api" >&2
        fi
    done

    if [ "$reachable" -ne "${#AGENTS[@]}" ]; then
        echo "Expected ${#AGENTS[@]} running agents, found $reachable. Start with spawn-validator-agents.sh --clean first." >&2
        exit 1
    fi
}

run_query_sample() {
    local sample="$1"
    local qdir="$EVIDENCE_DIR/query-samples/sample-${sample}"
    mkdir -p "$qdir"
    echo "sample=$sample timestamp_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$qdir/context.txt"
    if QUERY_TIMESTAMP="${TIMESTAMP}-sample-${sample}" EVIDENCE_DIR="$qdir" \
        "$PROJECT_DIR/scripts/testnet/query-validator-agents.sh" > "$qdir/query.log" 2>&1; then
        :
    else
        echo "query-validator-agents exited non-zero for sample $sample" >> "$qdir/query.log"
    fi

    local pass fail skip
    pass="$(awk -F': ' '/^PASS:/ {print $2}' "$qdir/summary.txt" 2>/dev/null | tail -1)"
    fail="$(awk -F': ' '/^FAIL:/ {print $2}' "$qdir/summary.txt" 2>/dev/null | tail -1)"
    skip="$(awk -F': ' '/^SKIP:/ {print $2}' "$qdir/summary.txt" 2>/dev/null | tail -1)"
    printf '%s\t%s\t%s\t%s\t%s\n' "$sample" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${pass:-0}" "${fail:-1}" "${skip:-0}" >> "$EVIDENCE_DIR/query-summary.tsv"
}

sample_runtime() {
    local sample="$1"
    local ts epoch sample_dir max_height min_height
    ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    epoch="$(date +%s)"
    sample_dir="$EVIDENCE_DIR/status-samples/sample-${sample}"
    mkdir -p "$sample_dir"

    max_height=0
    min_height=0

    echo "=== Sample $sample ($ts) ==="
    for agent_def in "${AGENTS[@]}"; do
        IFS=':' read -r name rpc api <<< "$agent_def"
        local status_file net_file validators_file height peers catching_up val_count resources
        status_file="$sample_dir/${name}-status.json"
        net_file="$sample_dir/${name}-net_info.json"
        validators_file="$sample_dir/${name}-validators.json"

        status_url "$rpc" "status" > "$status_file" 2>/dev/null || echo '{}' > "$status_file"
        status_url "$rpc" "net_info" > "$net_file" 2>/dev/null || echo '{}' > "$net_file"
        status_url "$rpc" "validators" > "$validators_file" 2>/dev/null || echo '{}' > "$validators_file"

        height="$(json_get "$status_file" '.result.sync_info.latest_block_height // "0"')"
        peers="$(json_get "$net_file" '.result.n_peers // "0"')"
        catching_up="$(json_get "$status_file" '.result.sync_info.catching_up // "true"')"
        val_count="$(json_get "$validators_file" '.result.validators | length // 0')"
        resources="$(agent_resource_sample "$name")"

        if [ "${height:-0}" -gt "$max_height" ] 2>/dev/null; then
            max_height="$height"
        fi
        if [ "$min_height" -eq 0 ] || { [ "${height:-0}" -gt 0 ] && [ "$height" -lt "$min_height" ]; } 2>/dev/null; then
            min_height="$height"
        fi

        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$sample" "$ts" "$epoch" "$name" "${height:-0}" "${peers:-0}" "${catching_up:-unknown}" "${val_count:-0}" "$resources" \
            >> "$EVIDENCE_DIR/samples.tsv"
        echo "  $name: height=${height:-0} peers=${peers:-0} validators=${val_count:-0} catching_up=${catching_up:-unknown}"
    done

    printf '%s\t%s\t%s\t%s\n' "$sample" "$ts" "$min_height" "$max_height" >> "$EVIDENCE_DIR/height-range.tsv"
}

write_summary() {
    local stop_epoch elapsed start_height final_height height_delta avg_block_time
    local min_peers max_peers min_vals max_vals panic_count error_count query_pass query_fail query_skip sample_count
    stop_epoch="$(date +%s)"
    elapsed=$((stop_epoch - START_EPOCH))
    sample_count="$(awk -F'\t' 'NR>1 {seen[$1]=1} END {print length(seen)}' "$EVIDENCE_DIR/samples.tsv" 2>/dev/null || echo 0)"

    start_height="$(awk -F'\t' '$4=="alpha" {print $5; exit}' "$EVIDENCE_DIR/samples.tsv" 2>/dev/null || echo 0)"
    final_height="$(awk -F'\t' '$4=="alpha" {h=$5} END{print h+0}' "$EVIDENCE_DIR/samples.tsv" 2>/dev/null || echo 0)"
    height_delta=$((final_height - start_height))
    if [ "$height_delta" -gt 0 ]; then
        avg_block_time="$(awk -v e="$elapsed" -v h="$height_delta" 'BEGIN { printf "%.2f", e / h }')"
    else
        avg_block_time="n/a"
    fi

    min_peers="$(awk -F'\t' 'NR>1 {if (m=="" || $6<m) m=$6} END{print m+0}' "$EVIDENCE_DIR/samples.tsv")"
    max_peers="$(awk -F'\t' 'NR>1 {if ($6>m) m=$6} END{print m+0}' "$EVIDENCE_DIR/samples.tsv")"
    min_vals="$(awk -F'\t' 'NR>1 {if (m=="" || $8<m) m=$8} END{print m+0}' "$EVIDENCE_DIR/samples.tsv")"
    max_vals="$(awk -F'\t' 'NR>1 {if ($8>m) m=$8} END{print m+0}' "$EVIDENCE_DIR/samples.tsv")"

    grep -Rni "panic" "$AGENT_DIR/logs" > "$EVIDENCE_DIR/panic-scan.txt" 2>/dev/null || true
    grep -RniE "error|failed|panic" "$AGENT_DIR/logs" > "$EVIDENCE_DIR/error-scan.txt" 2>/dev/null || true
    panic_count="$(wc -l < "$EVIDENCE_DIR/panic-scan.txt" | tr -d ' ')"
    error_count="$(wc -l < "$EVIDENCE_DIR/error-scan.txt" | tr -d ' ')"

    query_pass="$(awk -F'\t' 'NR>1 {s+=$3} END{print s+0}' "$EVIDENCE_DIR/query-summary.tsv" 2>/dev/null || echo 0)"
    query_fail="$(awk -F'\t' 'NR>1 {s+=$4} END{print s+0}' "$EVIDENCE_DIR/query-summary.tsv" 2>/dev/null || echo 0)"
    query_skip="$(awk -F'\t' 'NR>1 {s+=$5} END{print s+0}' "$EVIDENCE_DIR/query-summary.tsv" 2>/dev/null || echo 0)"

    for name in alpha bravo charlie delta echo; do
        cp "$AGENT_DIR/logs/${name}.log" "$EVIDENCE_DIR/logs/${name}.log" 2>/dev/null || true
    done

    cat > "$EVIDENCE_DIR/final-summary.md" <<EOF
# Phase 9U Long Soak Summary

- Timestamp UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Evidence: $EVIDENCE_DIR
- Target duration: ${DURATION_SECONDS}s
- Actual duration: ${elapsed}s
- Status samples: $sample_count
- Agent sample rows: $((sample_count * ${#AGENTS[@]}))
- Start height: $start_height
- Final height: $final_height
- Height delta: $height_delta
- Average block time: ${avg_block_time}s
- Peer count range: ${min_peers}-${max_peers}
- Validator set range: ${min_vals}-${max_vals}
- Query totals: ${query_pass} pass / ${query_fail} fail / ${query_skip} skip
- Panic scan count: $panic_count
- Error/failed/panic grep count: $error_count
- Missed blocks: not available from the current local agent collector
EOF

    cat > "$EVIDENCE_DIR/summary.env" <<EOF
EVIDENCE_DIR=$EVIDENCE_DIR
TARGET_DURATION_SECONDS=$DURATION_SECONDS
ACTUAL_DURATION_SECONDS=$elapsed
START_HEIGHT=$start_height
FINAL_HEIGHT=$final_height
HEIGHT_DELTA=$height_delta
AVERAGE_BLOCK_TIME_SECONDS=$avg_block_time
PEER_COUNT_MIN=$min_peers
PEER_COUNT_MAX=$max_peers
VALIDATOR_SET_MIN=$min_vals
VALIDATOR_SET_MAX=$max_vals
QUERY_PASS=$query_pass
QUERY_FAIL=$query_fail
QUERY_SKIP=$query_skip
PANIC_COUNT=$panic_count
ERROR_SCAN_COUNT=$error_count
EOF
}

require_runtime

cat > "$EVIDENCE_DIR/run-context.txt" <<EOF
Timestamp UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Project: $PROJECT_DIR
Agent dir: $AGENT_DIR
Evidence dir: $EVIDENCE_DIR
Duration: $DURATION_RAW ($DURATION_SECONDS seconds)
Sample interval: $SAMPLE_INTERVAL_RAW ($SAMPLE_INTERVAL_SECONDS seconds)
Query interval: $QUERY_INTERVAL_RAW ($QUERY_INTERVAL_SECONDS seconds)
EOF

printf 'sample\ttimestamp_utc\tepoch\tagent\theight\tpeers\tcatching_up\tvalidator_count\tpid\tcpu_pct\tmem_pct\trss_kb\n' > "$EVIDENCE_DIR/samples.tsv"
printf 'sample\ttimestamp_utc\tmin_height\tmax_height\n' > "$EVIDENCE_DIR/height-range.tsv"
printf 'sample\ttimestamp_utc\tpass\tfail\tskip\n' > "$EVIDENCE_DIR/query-summary.tsv"

echo "Phase 9U long soak"
echo "Evidence: $EVIDENCE_DIR"
echo "Duration: $DURATION_SECONDS seconds"
echo "Sample interval: $SAMPLE_INTERVAL_SECONDS seconds"
echo "Query interval: $QUERY_INTERVAL_SECONDS seconds"
echo ""

START_EPOCH="$(date +%s)"
END_EPOCH=$((START_EPOCH + DURATION_SECONDS))
NEXT_QUERY_EPOCH="$START_EPOCH"
SAMPLE=0

while [ "$(date +%s)" -lt "$END_EPOCH" ]; do
    SAMPLE=$((SAMPLE + 1))
    sample_runtime "$SAMPLE"

    now="$(date +%s)"
    if [ "$now" -ge "$NEXT_QUERY_EPOCH" ]; then
        echo "  Running full query readback sample $SAMPLE"
        run_query_sample "$SAMPLE"
        NEXT_QUERY_EPOCH=$((now + QUERY_INTERVAL_SECONDS))
    fi

    now="$(date +%s)"
    remaining=$((END_EPOCH - now))
    if [ "$remaining" -le 0 ]; then
        break
    fi
    if [ "$remaining" -lt "$SAMPLE_INTERVAL_SECONDS" ]; then
        sleep "$remaining"
    else
        sleep "$SAMPLE_INTERVAL_SECONDS"
    fi
done

SAMPLE=$((SAMPLE + 1))
sample_runtime "$SAMPLE"
echo "  Running final full query readback sample $SAMPLE"
run_query_sample "$SAMPLE"

write_summary

cat "$EVIDENCE_DIR/final-summary.md"

if awk -F= '/^PANIC_COUNT=/ {exit ($2 == 0 ? 0 : 1)}' "$EVIDENCE_DIR/summary.env" && \
   awk -F= '/^QUERY_FAIL=/ {exit ($2 == 0 ? 0 : 1)}' "$EVIDENCE_DIR/summary.env"; then
    exit 0
fi

exit 1
