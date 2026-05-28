#!/usr/bin/env bash
# NexaRail — Five-Agent Load Simulation and Throughput Profiling
#
# TESTNET/DEVNET ONLY. Uses local validator-agent homes and zero-value unxrl.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BINARY="$PROJECT_DIR/build/nexaraild"
AGENT_DIR="$PROJECT_DIR/rehearsals/validator-agents"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
EVIDENCE_DIR="${EVIDENCE_DIR:-$AGENT_DIR/load-sim/evidence/$TIMESTAMP}"
CHAIN_ID="nexarail-agent-testnet-1"
DENOM="unxrl"

DURATION=600
TX_RATE=1
QUERY_RATE=5
CONCURRENCY=2
SAMPLE_INTERVAL=30
SKIP_TX=0
SKIP_QUERY=0
SKIP_GOV=1
KEEP_RUNNING=0
RESOURCE_SAMPLING=0
RESOURCE_INTERVAL=30
LABEL=""
NO_CLEAN=0
REUSE_RUNNING=0
RESOURCE_PID=""
RESOURCE_STOP_FILE=""

cleanup_resource_sampler_on_exit() {
    if [ -n "${RESOURCE_PID:-}" ] && kill -0 "$RESOURCE_PID" >/dev/null 2>&1; then
        [ -n "${RESOURCE_STOP_FILE:-}" ] && touch "$RESOURCE_STOP_FILE"
        wait "$RESOURCE_PID" 2>/dev/null || true
    fi
}
trap cleanup_resource_sampler_on_exit EXIT

AGENTS=(
    "alpha:27657:1417"
    "bravo:27667:1418"
    "charlie:27677:1419"
    "delta:27687:1420"
    "echo:27697:1421"
)

usage() {
    cat <<EOF
Usage: scripts/testnet/run-five-agent-load-sim.sh [options]

Options:
  --duration <seconds>          Load window duration. Default: 600
  --tx-rate <n>                 Target tx attempts per second. Default: 1
  --query-rate <n>              Target query attempts per second. Default: 5
  --concurrency <n>             Query concurrency and max tx workers. Default: 2
  --sample-interval <seconds>   Runtime sampling interval. Default: 30
  --skip-tx                     Disable bank tx load
  --skip-query                  Disable query load
  --skip-gov                    Keep governance vote reliability skipped
  --keep-running                Leave agents running after evidence capture
  --resource-sampling           Capture process/resource metrics during load
  --resource-interval <seconds> Resource sample interval. Default: 30
  --label <name>                Optional run label for summaries
  --no-clean                    Skip explicit pre-clean; spawn still performs safe clean validation
  --reuse-running               Reuse already-running local five-agent runtime; skip spawn/clean
  --evidence-dir <path>         Evidence output directory
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --duration) DURATION="${2:-}"; shift 2 ;;
        --tx-rate) TX_RATE="${2:-}"; shift 2 ;;
        --query-rate) QUERY_RATE="${2:-}"; shift 2 ;;
        --concurrency) CONCURRENCY="${2:-}"; shift 2 ;;
        --sample-interval) SAMPLE_INTERVAL="${2:-}"; shift 2 ;;
        --skip-tx) SKIP_TX=1; shift ;;
        --skip-query) SKIP_QUERY=1; shift ;;
        --skip-gov) SKIP_GOV=1; shift ;;
        --keep-running) KEEP_RUNNING=1; shift ;;
        --resource-sampling) RESOURCE_SAMPLING=1; shift ;;
        --resource-interval) RESOURCE_INTERVAL="${2:-}"; shift 2 ;;
        --label) LABEL="${2:-}"; shift 2 ;;
        --no-clean) NO_CLEAN=1; shift ;;
        --reuse-running) REUSE_RUNNING=1; shift ;;
        --evidence-dir) EVIDENCE_DIR="${2:-}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

case "$DURATION:$TX_RATE:$QUERY_RATE:$CONCURRENCY:$SAMPLE_INTERVAL:$RESOURCE_INTERVAL" in
    *[!0-9:]*|"") echo "Numeric options must be positive integers." >&2; exit 2 ;;
esac
[ "$DURATION" -gt 0 ] || { echo "--duration must be >0" >&2; exit 2; }
[ "$TX_RATE" -ge 0 ] || { echo "--tx-rate must be >=0" >&2; exit 2; }
[ "$QUERY_RATE" -ge 0 ] || { echo "--query-rate must be >=0" >&2; exit 2; }
[ "$CONCURRENCY" -gt 0 ] || { echo "--concurrency must be >0" >&2; exit 2; }
[ "$SAMPLE_INTERVAL" -gt 0 ] || { echo "--sample-interval must be >0" >&2; exit 2; }
[ "$RESOURCE_INTERVAL" -gt 0 ] || { echo "--resource-interval must be >0" >&2; exit 2; }

mkdir -p "$EVIDENCE_DIR"/{accounts,cleanup,health,logs,queries,spawn,tx}

TX_RESULTS="$EVIDENCE_DIR/tx-results.jsonl"
QUERY_RESULTS="$EVIDENCE_DIR/query-results.jsonl"
SAMPLES="$EVIDENCE_DIR/samples.tsv"
: > "$TX_RESULTS"
: > "$QUERY_RESULTS"
echo -e "elapsed\ttime_utc\tagent\theight\tpeers\tcatching_up\tvalidator_count" > "$SAMPLES"

now_ms() {
    python3 - <<'PY'
import time
print(int(time.time() * 1000))
PY
}

json_str() {
    python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().rstrip("\n")))' 2>/dev/null
}

agent_home() {
    printf '%s/%s\n' "$AGENT_DIR" "$1"
}

agent_addr() {
    local name="$1"
    "$BINARY" keys show "${name}-key" -a --keyring-backend test --home "$(agent_home "$name")" 2>/dev/null
}

classify_tx_failure() {
    local file="$1"
    if grep -qi "sequence" "$file" 2>/dev/null; then
        echo "sequence"
    elif grep -qi "insufficient" "$file" 2>/dev/null; then
        echo "insufficient_funds"
    elif grep -qi "timed out\\|timeout\\|deadline" "$file" 2>/dev/null; then
        echo "timeout"
    elif grep -qi "CheckTx" "$file" 2>/dev/null; then
        echo "checktx"
    elif grep -qi "mempool" "$file" 2>/dev/null; then
        echo "mempool"
    else
        echo "broadcast"
    fi
}

wait_for_readiness() {
    echo "  Waiting for all agents to reach RPC/validator readiness..."
    local ready=0
    for _ in $(seq 1 60); do
        ready=1
        for def in "${AGENTS[@]}"; do
            IFS=':' read -r name rpc api <<< "$def"
            h=$(curl -s --max-time 3 "http://127.0.0.1:$rpc/status" 2>/dev/null | jq -r '.result.sync_info.latest_block_height // "0"' 2>/dev/null || echo "0")
            vc=$(curl -s --max-time 3 "http://127.0.0.1:$rpc/validators" 2>/dev/null | jq -r '.result.validators | length // 0' 2>/dev/null || echo "0")
            if ! [ "${h:-0}" -ge 10 ] 2>/dev/null || [ "${vc:-0}" != "5" ]; then
                ready=0
            fi
        done
        [ "$ready" -eq 1 ] && return 0
        sleep 2
    done
    return 1
}

sample_agents() {
    local elapsed="$1"
    local t
    t="$(date -u +%H:%M:%S)"
    for def in "${AGENTS[@]}"; do
        IFS=':' read -r name rpc api <<< "$def"
        status=$(curl -s --max-time 3 "http://127.0.0.1:$rpc/status" 2>/dev/null || echo "{}")
        net=$(curl -s --max-time 3 "http://127.0.0.1:$rpc/net_info" 2>/dev/null || echo "{}")
        vals=$(curl -s --max-time 3 "http://127.0.0.1:$rpc/validators" 2>/dev/null || echo "{}")
        h=$(printf '%s' "$status" | jq -r '.result.sync_info.latest_block_height // "-"' 2>/dev/null || echo "-")
        cu=$(printf '%s' "$status" | jq -r 'if (.result.sync_info | type == "object" and has("catching_up")) then .result.sync_info.catching_up else "?" end' 2>/dev/null || echo "?")
        peers=$(printf '%s' "$net" | jq -r '.result.n_peers // "?"' 2>/dev/null || echo "?")
        vc=$(printf '%s' "$vals" | jq -r '.result.validators | length // "?"' 2>/dev/null || echo "?")
        echo -e "$elapsed\t$t\t$name\t$h\t$peers\t$cu\t$vc" >> "$SAMPLES"
    done
}

record_account_snapshots() {
    echo "  Recording account addresses and sequence snapshots..."
    local addr first=1
    printf '{\n' > "$EVIDENCE_DIR/accounts/addresses.json"
    for def in "${AGENTS[@]}"; do
        IFS=':' read -r name rpc api <<< "$def"
        addr="$(agent_addr "$name")"
        [ "$first" -eq 0 ] && printf ',\n' >> "$EVIDENCE_DIR/accounts/addresses.json"
        first=0
        printf '  "%s": "%s"' "$name" "$addr" >> "$EVIDENCE_DIR/accounts/addresses.json"
        "$BINARY" query auth account "$addr" --node "tcp://127.0.0.1:$rpc" --output json \
            > "$EVIDENCE_DIR/accounts/${name}-before.json" 2> "$EVIDENCE_DIR/accounts/${name}-before.json.err" || true
        "$BINARY" query bank balances "$addr" --node "tcp://127.0.0.1:$rpc" --output json \
            > "$EVIDENCE_DIR/accounts/${name}-balance-before.json" 2> "$EVIDENCE_DIR/accounts/${name}-balance-before.json.err" || true
    done
    printf '\n}\n' >> "$EVIDENCE_DIR/accounts/addresses.json"
}

record_account_after_snapshots() {
    local addr
    for def in "${AGENTS[@]}"; do
        IFS=':' read -r name rpc api <<< "$def"
        addr="$(agent_addr "$name")"
        "$BINARY" query auth account "$addr" --node "tcp://127.0.0.1:$rpc" --output json \
            > "$EVIDENCE_DIR/accounts/${name}-after.json" 2> "$EVIDENCE_DIR/accounts/${name}-after.json.err" || true
        "$BINARY" query bank balances "$addr" --node "tcp://127.0.0.1:$rpc" --output json \
            > "$EVIDENCE_DIR/accounts/${name}-balance-after.json" 2> "$EVIDENCE_DIR/accounts/${name}-balance-after.json.err" || true
    done
}

run_tx_worker() {
    local worker="$1"
    local interval_ms="$2"
    local attempt=0
    local sender_def recipient_def sender sender_rpc recipient recipient_addr start_ms end_ms latency_ms tx_file err_file txhash code class include_file include_code rpc_hash
    while [ "$(date +%s)" -lt "$RUN_END_EPOCH" ]; do
        sender_def="${AGENTS[$((worker % ${#AGENTS[@]}))]}"
        recipient_def="${AGENTS[$(((worker + 1) % ${#AGENTS[@]}))]}"
        IFS=':' read -r sender sender_rpc _ <<< "$sender_def"
        IFS=':' read -r recipient _ _ <<< "$recipient_def"
        recipient_addr="$(agent_addr "$recipient")"
        tx_file="$EVIDENCE_DIR/tx/tx-worker${worker}-${attempt}.json"
        err_file="$EVIDENCE_DIR/tx/tx-worker${worker}-${attempt}.err"
        include_file="$EVIDENCE_DIR/tx/tx-worker${worker}-${attempt}-included.json"
        start_ms="$(now_ms)"

        "$BINARY" tx send "${sender}-key" "$recipient_addr" "1000$DENOM" \
            --keyring-backend test --home "$(agent_home "$sender")" \
            --chain-id "$CHAIN_ID" --node "tcp://127.0.0.1:$sender_rpc" \
            --fees "500$DENOM" --broadcast-mode sync --output json -y \
            > "$tx_file" 2> "$err_file"
        rc=$?

        txhash=""
        code="-1"
        include_code="-1"
        class=""
        if [ "$rc" -ne 0 ]; then
            class="$(classify_tx_failure "$err_file")"
        else
            code="$(jq -r '.code // 0' "$tx_file" 2>/dev/null || echo "-1")"
            txhash="$(jq -r '.txhash // ""' "$tx_file" 2>/dev/null || echo "")"
            if [ "$code" != "0" ]; then
                class="$(classify_tx_failure "$tx_file")"
            elif [ -n "$txhash" ]; then
                class="inclusion_failure"
                rpc_hash="0x$txhash"
                for _ in $(seq 1 30); do
                    sleep 1
                    if curl -s --max-time 5 "http://127.0.0.1:$sender_rpc/tx?hash=$rpc_hash" \
                        > "$include_file" 2> "$include_file.err"; then
                        if ! jq -e '.result.tx_result' "$include_file" >/dev/null 2>&1; then
                            curl -s --max-time 5 "http://127.0.0.1:$sender_rpc/tx?hash=$txhash" \
                                > "$include_file" 2> "$include_file.err" || true
                        fi
                    fi
                    if jq -e '.result.tx_result' "$include_file" >/dev/null 2>&1; then
                        include_code="$(jq -r '.result.tx_result.code // -1' "$include_file" 2>/dev/null || echo "-1")"
                        if [ "$include_code" = "0" ]; then
                            class="included"
                        else
                            class="checktx"
                        fi
                        break
                    fi
                done
            else
                class="broadcast"
            fi
        fi

        end_ms="$(now_ms)"
        latency_ms=$((end_ms - start_ms))
        printf '{"time":"%s","worker":%s,"attempt":%s,"sender":"%s","recipient":"%s","txhash":"%s","broadcast_rc":%s,"broadcast_code":%s,"included_code":%s,"latency_ms":%s,"class":"%s"}\n' \
            "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$worker" "$attempt" "$sender" "$recipient" "$txhash" "$rc" "$code" "$include_code" "$latency_ms" "$class" \
            >> "$TX_RESULTS"

        attempt=$((attempt + 1))
        elapsed_ms=$(( $(now_ms) - start_ms ))
        if [ "$interval_ms" -gt "$elapsed_ms" ]; then
            sleep_seconds=$(( (interval_ms - elapsed_ms + 999) / 1000 ))
            sleep "$sleep_seconds"
        fi
    done
}

run_query_once() {
    local seq="$1"
    local agent_index="$2"
    local endpoint_index="$3"
    local def endpoint_def name rpc api endpoint base path url out meta status latency seconds bytes pass
    def="${AGENTS[$agent_index]}"
    endpoint_def="${QUERY_ENDPOINTS[$endpoint_index]}"
    IFS=':' read -r name rpc api <<< "$def"
    IFS='|' read -r endpoint base path <<< "$endpoint_def"
    if [ "$base" = "rpc" ]; then
        url="http://127.0.0.1:$rpc$path"
    else
        url="http://127.0.0.1:$api$path"
    fi
    out="$EVIDENCE_DIR/queries/query-${seq}.json"
    meta=$(curl -s -o "$out" -w "%{http_code} %{time_total} %{size_download}" --max-time 5 "$url" 2>"$out.err")
    status=$(printf '%s' "$meta" | awk '{print $1}')
    seconds=$(printf '%s' "$meta" | awk '{print $2}')
    bytes=$(printf '%s' "$meta" | awk '{print $3}')
    latency=$(awk -v s="${seconds:-0}" 'BEGIN { printf "%d", s * 1000 }')
    pass=false
    if [ "$status" = "200" ] && jq -e . "$out" >/dev/null 2>&1; then
        pass=true
        rm -f "$out.err"
    fi
    printf '{"time":"%s","seq":%s,"agent":"%s","endpoint":"%s","base":"%s","status_code":%s,"latency_ms":%s,"bytes":%s,"pass":%s}\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$seq" "$name" "$endpoint" "$base" "${status:-0}" "${latency:-0}" "${bytes:-0}" "$pass" \
        >> "$QUERY_RESULTS"
}

run_query_loop() {
    local seq=0 active=0 agent_i endpoint_i launched
    while [ "$(date +%s)" -lt "$RUN_END_EPOCH" ]; do
        launched=0
        while [ "$launched" -lt "$QUERY_RATE" ]; do
            agent_i=$((seq % ${#AGENTS[@]}))
            endpoint_i=$((seq % ${#QUERY_ENDPOINTS[@]}))
            run_query_once "$seq" "$agent_i" "$endpoint_i" &
            active=$((active + 1))
            seq=$((seq + 1))
            launched=$((launched + 1))
            if [ "$active" -ge "$CONCURRENCY" ]; then
                wait
                active=0
            fi
        done
        wait
        active=0
        sleep 1
    done
}

collect_rpc_health() {
    python3 - "$EVIDENCE_DIR/health/rpc-health.json" <<'PY'
import json, sys
json.dump([], open(sys.argv[1], "w"))
PY
    local first=1
    printf '[\n' > "$EVIDENCE_DIR/rpc-health.json"
    for def in "${AGENTS[@]}"; do
        IFS=':' read -r name rpc api <<< "$def"
        status=$(curl -s --max-time 5 "http://127.0.0.1:$rpc/status" 2>/dev/null || echo "{}")
        net=$(curl -s --max-time 5 "http://127.0.0.1:$rpc/net_info" 2>/dev/null || echo "{}")
        vals=$(curl -s --max-time 5 "http://127.0.0.1:$rpc/validators" 2>/dev/null || echo "{}")
        height=$(printf '%s' "$status" | jq -r '.result.sync_info.latest_block_height // "0"' 2>/dev/null || echo "0")
        catching=$(printf '%s' "$status" | jq -r 'if (.result.sync_info | type == "object" and has("catching_up")) then .result.sync_info.catching_up else true end' 2>/dev/null || echo "true")
        peers=$(printf '%s' "$net" | jq -r '.result.n_peers // "0"' 2>/dev/null || echo "0")
        validators=$(printf '%s' "$vals" | jq -r '.result.validators | length // 0' 2>/dev/null || echo "0")
        [ "$first" -eq 0 ] && printf ',\n' >> "$EVIDENCE_DIR/rpc-health.json"
        first=0
        printf '  {"agent":"%s","height":%s,"catching_up":%s,"peers":%s,"validator_count":%s}' \
            "$name" "${height:-0}" "${catching:-true}" "${peers:-0}" "${validators:-0}" >> "$EVIDENCE_DIR/rpc-health.json"
    done
    printf '\n]\n' >> "$EVIDENCE_DIR/rpc-health.json"
}

collect_rest_health() {
    local first=1
    printf '[\n' > "$EVIDENCE_DIR/rest-health.json"
    for def in "${AGENTS[@]}"; do
        IFS=':' read -r name rpc api <<< "$def"
        for path in \
            "/nexarail/fees/v1/params" \
            "/nexarail/merchant/v1/params" \
            "/nexarail/settlement/v1/params" \
            "/nexarail/escrow/v1/params" \
            "/nexarail/payout/v1/params" \
            "/nexarail/treasury/v1/params"; do
            code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://127.0.0.1:$api$path" 2>/dev/null || echo "000")
            [ "$first" -eq 0 ] && printf ',\n' >> "$EVIDENCE_DIR/rest-health.json"
            first=0
            printf '  {"agent":"%s","path":"%s","status_code":%s,"pass":%s}' "$name" "$path" "$code" "$([ "$code" = "200" ] && echo true || echo false)" >> "$EVIDENCE_DIR/rest-health.json"
        done
    done
    printf '\n]\n' >> "$EVIDENCE_DIR/rest-health.json"
}

collect_live_flags() {
    local first=1
    printf '[\n' > "$EVIDENCE_DIR/live-flags-final.json"
    for def in "${AGENTS[@]}"; do
        IFS=':' read -r name rpc api <<< "$def"
        for mod in settlement escrow payout treasury; do
            resp=$(curl -s --max-time 5 "http://127.0.0.1:$api/nexarail/$mod/v1/params" 2>/dev/null || echo "{}")
            live=$(printf '%s' "$resp" | jq -r 'if .params | has("live_enabled") then .params.live_enabled elif has("live_enabled") then .live_enabled else null end' 2>/dev/null || echo "null")
            [ "$first" -eq 0 ] && printf ',\n' >> "$EVIDENCE_DIR/live-flags-final.json"
            first=0
            printf '  {"agent":"%s","module":"%s","live_enabled":%s}' "$name" "$mod" "${live:-null}" >> "$EVIDENCE_DIR/live-flags-final.json"
            if [ "$mod" = "settlement" ]; then
                treasury=$(printf '%s' "$resp" | jq -r '.params.treasury_routing_enabled // null' 2>/dev/null || echo "null")
                burn=$(printf '%s' "$resp" | jq -r '.params.burn_routing_enabled // null' 2>/dev/null || echo "null")
                printf ',\n  {"agent":"%s","module":"settlement","treasury_routing_enabled":%s}' "$name" "${treasury:-null}" >> "$EVIDENCE_DIR/live-flags-final.json"
                printf ',\n  {"agent":"%s","module":"settlement","burn_routing_enabled":%s}' "$name" "${burn:-null}" >> "$EVIDENCE_DIR/live-flags-final.json"
            fi
        done
    done
    printf '\n]\n' >> "$EVIDENCE_DIR/live-flags-final.json"
}

scan_logs() {
    cp "$AGENT_DIR"/logs/*.log "$EVIDENCE_DIR/logs/" 2>/dev/null || true
    grep -rniE "panic|fatal" "$EVIDENCE_DIR/logs" > "$EVIDENCE_DIR/panic-scan.txt" 2>/dev/null || true
    grep -rni "CheckTx" "$EVIDENCE_DIR/logs" > "$EVIDENCE_DIR/checktx-scan.txt" 2>/dev/null || true
    grep -rniE "descriptor|unknownproto|unknown proto|gzip invalid|gzip" "$EVIDENCE_DIR/logs" > "$EVIDENCE_DIR/descriptor-scan.txt" 2>/dev/null || true
}

start_resource_sampler() {
    [ "$RESOURCE_SAMPLING" -eq 1 ] || return 0
    RESOURCE_STOP_FILE="$EVIDENCE_DIR/resource-stop.signal"
    rm -f "$RESOURCE_STOP_FILE" 2>/dev/null || true
    echo "  Resource sampling active every ${RESOURCE_INTERVAL}s"
    "$SCRIPT_DIR/sample-agent-resources.sh" \
        --evidence-dir "$EVIDENCE_DIR" \
        --interval "$RESOURCE_INTERVAL" \
        --stop-file "$RESOURCE_STOP_FILE" \
        > "$EVIDENCE_DIR/resource-sampler.log" 2>&1 &
    RESOURCE_PID="$!"
    echo "$RESOURCE_PID" > "$EVIDENCE_DIR/resource-sampler.pid"
}

stop_resource_sampler() {
    [ "$RESOURCE_SAMPLING" -eq 1 ] || return 0
    [ -n "$RESOURCE_STOP_FILE" ] && touch "$RESOURCE_STOP_FILE"
    if [ -n "$RESOURCE_PID" ]; then
        wait "$RESOURCE_PID" 2>/dev/null || true
    fi
    if [ ! -f "$EVIDENCE_DIR/resources-summary.json" ]; then
        "$SCRIPT_DIR/sample-agent-resources.sh" --evidence-dir "$EVIDENCE_DIR" --once \
            >> "$EVIDENCE_DIR/resource-sampler.log" 2>&1 || true
    fi
}

run_cleanup() {
    if [ "$KEEP_RUNNING" -eq 1 ]; then
        cat > "$EVIDENCE_DIR/cleanup/cleanup-status.json" <<EOF
{"keep_running":true,"stopped":false,"ports_free":false}
EOF
        return 0
    fi
    bash "$SCRIPT_DIR/stop-validator-agents.sh" --force --evidence-dir "$EVIDENCE_DIR" > "$EVIDENCE_DIR/cleanup/stop.log" 2>&1
    stop_rc=$?
    bash "$SCRIPT_DIR/clean-validator-agent-runtime.sh" --force > "$EVIDENCE_DIR/cleanup/clean.log" 2>&1
    clean_rc=$?
    pids=$(pgrep -f "nexaraild.*validator-agents" 2>/dev/null | wc -l | tr -d ' ')
    occupied=0
    for port in 27657 27667 27677 27687 27697 1417 1418 1419 1420 1421 9190 9191 9192 9193 9194; do
        if lsof -tiTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
            occupied=$((occupied + 1))
        fi
    done
    cat > "$EVIDENCE_DIR/cleanup/cleanup-status.json" <<EOF
{"keep_running":false,"stop_rc":$stop_rc,"clean_rc":$clean_rc,"remaining_agent_processes":$pids,"occupied_test_ports":$occupied,"stopped":$([ "$pids" = "0" ] && [ "$occupied" = "0" ] && echo true || echo false),"ports_free":$([ "$occupied" = "0" ] && echo true || echo false)}
EOF
}

write_summaries() {
    python3 - "$EVIDENCE_DIR" "$DURATION" "$TX_RATE" "$QUERY_RATE" "$CONCURRENCY" "$SAMPLE_INTERVAL" "$SKIP_GOV" "$RESOURCE_SAMPLING" "$RESOURCE_INTERVAL" "$LABEL" <<'PY'
import json, math, os, statistics, sys
from collections import Counter, defaultdict

evidence, duration, tx_rate, query_rate, concurrency, sample_interval, skip_gov, resource_sampling, resource_interval, label = sys.argv[1:]
duration = int(duration)

def read_jsonl(path):
    rows = []
    if not os.path.exists(path):
        return rows
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except Exception:
                rows.append({"parse_error": line})
    return rows

def load_json(path, default):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return default

def percentile(values, pct):
    values = sorted(v for v in values if isinstance(v, (int, float)))
    if not values:
        return None
    k = (len(values) - 1) * pct / 100
    lo = math.floor(k)
    hi = math.ceil(k)
    if lo == hi:
        return values[int(k)]
    return values[lo] + (values[hi] - values[lo]) * (k - lo)

samples = []
samples_path = os.path.join(evidence, "samples.tsv")
if os.path.exists(samples_path):
    with open(samples_path) as f:
        header = f.readline().strip().split("\t")
        for line in f:
            parts = line.rstrip("\n").split("\t")
            if len(parts) != len(header):
                continue
            item = dict(zip(header, parts))
            for key in ("elapsed", "height", "peers", "validator_count"):
                try:
                    item[key] = int(item[key])
                except Exception:
                    item[key] = None
            samples.append(item)

heights = [s["height"] for s in samples if isinstance(s.get("height"), int)]
elapsed = [s["elapsed"] for s in samples if isinstance(s.get("elapsed"), int)]
peers = [s["peers"] for s in samples if isinstance(s.get("peers"), int)]
validators = [s["validator_count"] for s in samples if isinstance(s.get("validator_count"), int)]

start_height = heights[0] if heights else None
final_height = heights[-1] if heights else None
height_delta = (final_height - start_height) if isinstance(start_height, int) and isinstance(final_height, int) else None
observed_duration = (max(elapsed) - min(elapsed)) if elapsed else 0
avg_block_time = (observed_duration / height_delta) if height_delta and height_delta > 0 else None

tx_rows = read_jsonl(os.path.join(evidence, "tx-results.jsonl"))
tx_classes = Counter(row.get("class", "unknown") for row in tx_rows)
tx_latency = [row.get("latency_ms") for row in tx_rows if row.get("class") == "included"]
tx_summary = {
    "attempted": len(tx_rows),
    "broadcast_success": sum(1 for row in tx_rows if row.get("broadcast_rc") == 0 and row.get("broadcast_code") == 0),
    "included_code_0": sum(1 for row in tx_rows if row.get("class") == "included" and row.get("included_code") == 0),
    "failed_by_class": {k: v for k, v in sorted(tx_classes.items()) if k != "included"},
    "p50_inclusion_latency_ms": percentile(tx_latency, 50),
    "p95_inclusion_latency_ms": percentile(tx_latency, 95),
}

query_rows = read_jsonl(os.path.join(evidence, "query-results.jsonl"))
query_latency = [row.get("latency_ms") for row in query_rows if row.get("pass") is True]
query_fail_endpoint = Counter(row.get("endpoint", "unknown") for row in query_rows if row.get("pass") is not True)
query_fail_agent = Counter(row.get("agent", "unknown") for row in query_rows if row.get("pass") is not True)
query_summary = {
    "attempted": len(query_rows),
    "success": sum(1 for row in query_rows if row.get("pass") is True),
    "failed": sum(1 for row in query_rows if row.get("pass") is not True),
    "failed_by_endpoint": dict(sorted(query_fail_endpoint.items())),
    "failed_by_agent": dict(sorted(query_fail_agent.items())),
    "p50_latency_ms": percentile(query_latency, 50),
    "p95_latency_ms": percentile(query_latency, 95),
}

rpc_health = load_json(os.path.join(evidence, "rpc-health.json"), [])
rest_health = load_json(os.path.join(evidence, "rest-health.json"), [])
live_flags = load_json(os.path.join(evidence, "live-flags-final.json"), [])
cleanup = load_json(os.path.join(evidence, "cleanup", "cleanup-status.json"), {})
resource_summary = load_json(os.path.join(evidence, "resources-summary.json"), {})

scan_counts = {}
for name, file_name in [
    ("panic", "panic-scan.txt"),
    ("checktx", "checktx-scan.txt"),
    ("descriptor", "descriptor-scan.txt"),
]:
    path = os.path.join(evidence, file_name)
    try:
        with open(path) as f:
            scan_counts[name] = sum(1 for line in f if line.strip())
    except Exception:
        scan_counts[name] = None

live_entries = [item for item in live_flags if "live_enabled" in item]
route_entries = [
    item
    for item in live_flags
    if "treasury_routing_enabled" in item or "burn_routing_enabled" in item
]
live_false = bool(live_entries) and all(item.get("live_enabled") is False for item in live_entries)
live_false = live_false and all(
    item.get("treasury_routing_enabled", False) in (False, None)
    and item.get("burn_routing_enabled", False) in (False, None)
    for item in route_entries
)
agents_alive = sum(1 for item in rpc_health if isinstance(item.get("height"), int) and item.get("height", 0) > 0)
rest_pass = all(item.get("pass") is True for item in rest_health) if rest_health else False
validator_min = min(validators) if validators else None
validator_max = max(validators) if validators else None
peer_min = min(peers) if peers else None
peer_max = max(peers) if peers else None

success = {
    "five_agents_alive": agents_alive == 5,
    "height_advances": bool(height_delta and height_delta > 0),
    "validator_set_remains_5": validator_min == 5 and validator_max == 5,
    "peer_count_sampled": peer_min is not None and peer_max is not None,
    "tx_inclusion_measured": tx_summary["attempted"] == 0 or tx_summary["included_code_0"] > 0,
    "tx_failures_classified": True,
    "query_health_measured": query_summary["attempted"] > 0 or int(query_rate) == 0,
    "queries_pass": query_summary["failed"] == 0,
    "rest_health_pass": rest_pass,
    "live_flags_false": live_false,
    "no_panic_or_fatal": scan_counts.get("panic") == 0,
    "no_unrecovered_checktx": scan_counts.get("checktx") == 0 and "checktx" not in tx_summary["failed_by_class"],
    "no_descriptor_unknownproto_gzip": scan_counts.get("descriptor") == 0,
    "resource_metrics_captured": int(resource_sampling) == 0 or resource_summary.get("samples", 0) > 0,
    "cleanup_clean": cleanup.get("stopped") is True or cleanup.get("keep_running") is True,
}
phase_pass = all(success.values())

summary = {
    "phase": "16C",
    "evidence": evidence,
    "label": label,
    "duration_seconds": duration,
    "settings": {
        "label": label,
        "duration_seconds": duration,
        "tx_rate": int(tx_rate),
        "query_rate": int(query_rate),
        "concurrency": int(concurrency),
        "sample_interval": int(sample_interval),
        "skip_gov": bool(int(skip_gov)),
        "resource_sampling": bool(int(resource_sampling)),
        "resource_interval": int(resource_interval),
    },
    "observed_duration_seconds": observed_duration,
    "sample_rows": len(samples),
    "start_height": start_height,
    "final_height": final_height,
    "height_delta": height_delta,
    "average_block_time_seconds": avg_block_time,
    "peer_count_range": [peer_min, peer_max],
    "validator_count_range": [validator_min, validator_max],
    "tx": tx_summary,
    "query": query_summary,
    "agents_alive_final": agents_alive,
    "rest_health_pass": rest_pass,
    "final_live_flags_false": live_false,
    "scan_counts": scan_counts,
    "resource": resource_summary,
    "governance": {"skipped": bool(int(skip_gov)), "reason": "Skipped to keep Phase 16C bank/query throughput baseline isolated from proposal/vote timing." if int(skip_gov) else "not implemented in this run"},
    "cleanup": cleanup,
    "success_criteria": success,
    "phase_pass": phase_pass,
}

with open(os.path.join(evidence, "tx-summary.json"), "w") as f:
    json.dump(tx_summary, f, indent=2)
    f.write("\n")
with open(os.path.join(evidence, "query-summary.json"), "w") as f:
    json.dump(query_summary, f, indent=2)
    f.write("\n")
with open(os.path.join(evidence, "summary.json"), "w") as f:
    json.dump(summary, f, indent=2)
    f.write("\n")

def fmt(v):
    return "n/a" if v is None else str(round(v, 2) if isinstance(v, float) else v)

md = f"""# Phase 16C Load Simulation Summary

## Verdict

Phase pass: `{str(phase_pass).lower()}`

Evidence: `{evidence}`

## Settings

| Metric | Value |
|---|---:|
| Duration target | {duration}s |
| Observed sample duration | {observed_duration}s |
| Tx rate target | {tx_rate}/s |
| Query rate target | {query_rate}/s |
| Concurrency | {concurrency} |
| Sample interval | {sample_interval}s |
| Label | {label or 'n/a'} |

## Chain Progress

| Metric | Value |
|---|---:|
| Start height | {fmt(start_height)} |
| Final height | {fmt(final_height)} |
| Height delta | {fmt(height_delta)} |
| Average block time | {fmt(avg_block_time)}s |
| Peer count range | {fmt(peer_min)}-{fmt(peer_max)} |
| Validator count range | {fmt(validator_min)}-{fmt(validator_max)} |

## Transaction Metrics

| Metric | Value |
|---|---:|
| Attempted | {tx_summary['attempted']} |
| Broadcast success | {tx_summary['broadcast_success']} |
| Included code 0 | {tx_summary['included_code_0']} |
| p50 inclusion latency ms | {fmt(tx_summary['p50_inclusion_latency_ms'])} |
| p95 inclusion latency ms | {fmt(tx_summary['p95_inclusion_latency_ms'])} |

Failed by class: `{tx_summary['failed_by_class']}`

## Query Metrics

| Metric | Value |
|---|---:|
| Attempted | {query_summary['attempted']} |
| Success | {query_summary['success']} |
| Failed | {query_summary['failed']} |
| p50 latency ms | {fmt(query_summary['p50_latency_ms'])} |
| p95 latency ms | {fmt(query_summary['p95_latency_ms'])} |

Failed by endpoint: `{query_summary['failed_by_endpoint']}`

## Final Checks

- REST health pass: `{str(rest_pass).lower()}`
- Final live flags false: `{str(live_false).lower()}`
- Panic/fatal scan lines: `{scan_counts.get('panic')}`
- CheckTx scan lines: `{scan_counts.get('checktx')}`
- Descriptor/unknown proto/gzip scan lines: `{scan_counts.get('descriptor')}`
- Resource samples: `{resource_summary.get('samples', 0) if resource_summary else 0}`
- Cleanup: `{cleanup}`

## Governance

Governance reliability during load was skipped to keep this throughput baseline isolated from proposal/vote timing.
"""
with open(os.path.join(evidence, "summary.md"), "w") as f:
    f.write(md)
PY
}

QUERY_ENDPOINTS=()

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  NexaRail — Five-Agent Load Simulation                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo "  Duration: ${DURATION}s | tx-rate: ${TX_RATE}/s | query-rate: ${QUERY_RATE}/s | concurrency: ${CONCURRENCY}"
[ -n "$LABEL" ] && echo "  Label: $LABEL"
echo "  Evidence: $EVIDENCE_DIR"
echo ""

if [ ! -x "$BINARY" ]; then
    echo "Binary not found or not executable: $BINARY" >&2
    exit 1
fi

cat > "$EVIDENCE_DIR/run-context.txt" <<EOF
Timestamp UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Project: $PROJECT_DIR
Binary: $BINARY
Chain ID: $CHAIN_ID
Duration: $DURATION
Tx rate: $TX_RATE
Query rate: $QUERY_RATE
Concurrency: $CONCURRENCY
Sample interval: $SAMPLE_INTERVAL
Skip tx: $SKIP_TX
Skip query: $SKIP_QUERY
Skip gov: $SKIP_GOV
Keep running: $KEEP_RUNNING
Resource sampling: $RESOURCE_SAMPLING
Resource interval: $RESOURCE_INTERVAL
Label: $LABEL
No clean: $NO_CLEAN
Reuse running: $REUSE_RUNNING
EOF

echo "── Runtime Setup ───────────────────────────────────────────────"
if [ "$REUSE_RUNNING" -eq 1 ]; then
    echo "  Reusing already-running local five-agent runtime"
    echo "reuse_running=true" > "$EVIDENCE_DIR/spawn/reuse-running.txt"
else
    if [ "$NO_CLEAN" -eq 0 ]; then
        bash "$SCRIPT_DIR/clean-validator-agent-runtime.sh" --force > "$EVIDENCE_DIR/cleanup/pre-clean.log" 2>&1 || true
    else
        echo "  Skipping explicit pre-clean; spawn still runs safe clean validation"
        echo "no_clean=true" > "$EVIDENCE_DIR/cleanup/pre-clean.log"
    fi
    if ! bash "$SCRIPT_DIR/spawn-validator-agents.sh" --clean --force-clean --no-tmux --agent-count 5 --evidence-dir "$EVIDENCE_DIR/spawn" > "$EVIDENCE_DIR/spawn/spawn.log" 2>&1; then
        echo "  Spawn failed. See $EVIDENCE_DIR/spawn/spawn.log" >&2
        exit 1
    fi
fi
if ! wait_for_readiness; then
    echo "  Agents did not become ready. See $EVIDENCE_DIR/spawn/." >&2
    exit 1
fi
record_account_snapshots

ALPHA_ADDR="$(jq -r '.alpha' "$EVIDENCE_DIR/accounts/addresses.json")"
QUERY_ENDPOINTS=(
    "rpc_status|rpc|/status"
    "rpc_net_info|rpc|/net_info"
    "rpc_validators|rpc|/validators"
    "bank_balance|api|/cosmos/bank/v1beta1/balances/$ALPHA_ADDR"
    "fees_params|api|/nexarail/fees/v1/params"
    "merchant_params|api|/nexarail/merchant/v1/params"
    "merchant_list|api|/nexarail/merchant/v1/merchants"
    "settlement_params|api|/nexarail/settlement/v1/params"
    "settlement_list|api|/nexarail/settlement/v1/settlements"
    "escrow_params|api|/nexarail/escrow/v1/params"
    "escrow_list|api|/nexarail/escrow/v1/escrows"
    "payout_params|api|/nexarail/payout/v1/params"
    "payout_list|api|/nexarail/payout/v1/payouts"
    "treasury_params|api|/nexarail/treasury/v1/params"
    "treasury_summary|api|/nexarail/treasury/v1/summary"
)

RUN_START_EPOCH="$(date +%s)"
RUN_END_EPOCH=$((RUN_START_EPOCH + DURATION))

echo "── Load Window ─────────────────────────────────────────────────"
sample_agents 0
start_resource_sampler

PIDS=()
if [ "$SKIP_TX" -eq 0 ] && [ "$TX_RATE" -gt 0 ]; then
    tx_workers="$CONCURRENCY"
    [ "$tx_workers" -gt 5 ] && tx_workers=5
    [ "$tx_workers" -lt 1 ] && tx_workers=1
    interval_ms=$(awk -v workers="$tx_workers" -v rate="$TX_RATE" 'BEGIN { if (rate <= 0) print 0; else printf "%d", (workers / rate) * 1000 }')
    [ "$interval_ms" -lt 1 ] && interval_ms=1
    for worker in $(seq 0 $((tx_workers - 1))); do
        run_tx_worker "$worker" "$interval_ms" &
        PIDS+=("$!")
    done
    echo "  Tx workers: $tx_workers"
else
    echo "  Tx load skipped"
fi

if [ "$SKIP_QUERY" -eq 0 ] && [ "$QUERY_RATE" -gt 0 ]; then
    run_query_loop &
    PIDS+=("$!")
    echo "  Query load active"
else
    echo "  Query load skipped"
fi

while [ "$(date +%s)" -lt "$RUN_END_EPOCH" ]; do
    elapsed=$(( $(date +%s) - RUN_START_EPOCH ))
    sample_agents "$elapsed"
    sleep "$SAMPLE_INTERVAL"
done

for pid in "${PIDS[@]}"; do
    wait "$pid" 2>/dev/null || true
done

echo "── Final Collection ────────────────────────────────────────────"
final_elapsed=$(( $(date +%s) - RUN_START_EPOCH ))
sample_agents "$final_elapsed"
record_account_after_snapshots
collect_rpc_health
collect_rest_health
collect_live_flags
scan_logs
stop_resource_sampler

if [ "$SKIP_GOV" -eq 1 ]; then
    cat > "$EVIDENCE_DIR/gov-summary.json" <<EOF
{"skipped":true,"reason":"Skipped to keep Phase 16C bank/query throughput baseline isolated from proposal/vote timing."}
EOF
else
    cat > "$EVIDENCE_DIR/gov-summary.json" <<EOF
{"skipped":true,"reason":"Governance reliability under load is not executed by this harness version."}
EOF
fi

run_cleanup
write_summaries

phase_pass=$(jq -r '.phase_pass' "$EVIDENCE_DIR/summary.json" 2>/dev/null || echo "false")
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Load Simulation Complete                                  ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "  Phase pass: $phase_pass"
echo "  Evidence: $EVIDENCE_DIR"
echo "╚══════════════════════════════════════════════════════════════╝"

[ "$phase_pass" = "true" ] && exit 0 || exit 1
