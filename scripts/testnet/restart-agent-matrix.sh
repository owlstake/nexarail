#!/usr/bin/env bash
# NexaRail - Phase 9V restart investigation matrix.
#
# TESTNET/DEVNET ONLY. This script exercises local validator-agent restart
# paths and writes timestamped evidence for each case.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
BINARY="$PROJECT_DIR/build/nexaraild"
AGENT_DIR="$PROJECT_DIR/rehearsals/validator-agents"
CHAIN_ID="nexarail-agent-testnet-1"
DENOM="unxrl"
TIMESTAMP="${PHASE9V_TIMESTAMP:-$(date -u +%Y%m%dT%H%M%SZ)}"
EVIDENCE_DIR="${PHASE9V_EVIDENCE_DIR:-$AGENT_DIR/restart-investigation/evidence/$TIMESTAMP}"
INCLUDE_LONG_SOAK=0
LONG_SOAK_DURATION="60m"
SHORT_SOAK_DURATION="5m"

NAMES=(alpha bravo charlie delta echo)
MONIKERS=(nxrl-validator-agent-alpha nxrl-validator-agent-bravo nxrl-validator-agent-charlie nxrl-validator-agent-delta nxrl-validator-agent-echo)
RPCS=(27657 27667 27677 27687 27697)
P2PS=(27656 27666 27676 27686 27696)
APIS=(1417 1418 1419 1420 1421)
GRPCS=(9190 9191 9192 9193 9194)
MODULES=(fees merchant settlement escrow payout treasury)

usage() {
    cat <<EOF
Usage: scripts/testnet/restart-agent-matrix.sh [options]

Options:
  --include-long-soak       Run the Phase 9V 5-agent restart-after-soak case with a 60m soak.
  --long-soak-duration VAL  Override long soak duration. Default: 60m.
  --short-soak-duration VAL Override short soak duration used when long soak is skipped. Default: 5m.
  --evidence-dir PATH       Evidence directory. Default: rehearsals/validator-agents/restart-investigation/evidence/<timestamp>.
  -h, --help                Show this help.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --include-long-soak)
            INCLUDE_LONG_SOAK=1
            shift
            ;;
        --long-soak-duration)
            LONG_SOAK_DURATION="${2:-}"
            shift 2
            ;;
        --short-soak-duration)
            SHORT_SOAK_DURATION="${2:-}"
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
            echo "Unknown argument: $1" >&2
            usage
            exit 2
            ;;
    esac
done

mkdir -p "$EVIDENCE_DIR"
printf '%s\n' "$TIMESTAMP" > "$AGENT_DIR/phase9v-latest-evidence-timestamp.txt"
printf '%s\n' "$EVIDENCE_DIR" > "$AGENT_DIR/phase9v-latest-evidence-path.txt"

MATRIX_TSV="$EVIDENCE_DIR/matrix-results.tsv"
printf 'case_id\tlabel\tagents\trestart_mode\tblock_resumes\tqueries_work\tpanics\tstart_height\trestart_height\tfinal_height\tpeer_range\tvalidator_range\tproposer\tbank_tx_hash\tevidence_path\tnotes\n' > "$MATRIX_TSV"

log() {
    printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

json_get() {
    local file="$1"
    local expr="$2"
    jq -r "$expr" "$file" 2>/dev/null || echo ""
}

agent_home() {
    local idx="$1"
    printf '%s/%s' "$AGENT_DIR" "${NAMES[$idx]}"
}

height_for_idx() {
    local idx="$1"
    curl -s --max-time 4 "http://127.0.0.1:${RPCS[$idx]}/status" 2>/dev/null \
        | jq -r '.result.sync_info.latest_block_height // "0"' 2>/dev/null || echo "0"
}

max_height() {
    local count="$1"
    local max=0
    local i h
    for ((i = 0; i < count; i++)); do
        h="$(height_for_idx "$i")"
        if [ "${h:-0}" -gt "$max" ] 2>/dev/null; then
            max="$h"
        fi
    done
    echo "$max"
}

wait_for_min_height() {
    local count="$1"
    local target="$2"
    local timeout="$3"
    local deadline h
    deadline=$(( $(date +%s) + timeout ))
    while [ "$(date +%s)" -lt "$deadline" ]; do
        h="$(max_height "$count")"
        if [ "${h:-0}" -ge "$target" ] 2>/dev/null; then
            echo "$h"
            return 0
        fi
        sleep 2
    done
    echo "$(max_height "$count")"
    return 1
}

wait_for_block_advance() {
    local count="$1"
    local delta="$2"
    local timeout="$3"
    local outfile="$4"
    local start target deadline h
    start="$(max_height "$count")"
    target=$((start + delta))
    deadline=$(( $(date +%s) + timeout ))

    while [ "$(date +%s)" -lt "$deadline" ]; do
        h="$(max_height "$count")"
        if [ "${h:-0}" -ge "$target" ] 2>/dev/null; then
            {
                echo "START_HEIGHT=$start"
                echo "FINAL_HEIGHT=$h"
                echo "BLOCK_RESUMES=yes"
            } > "$outfile"
            return 0
        fi
        sleep 2
    done

    h="$(max_height "$count")"
    {
        echo "START_HEIGHT=$start"
        echo "FINAL_HEIGHT=$h"
        echo "BLOCK_RESUMES=no"
    } > "$outfile"
    return 1
}

stop_agent_graceful() {
    local idx="$1"
    local name="${NAMES[$idx]}"
    local session="nexarail-agent-${name}"
    local pid_file="$AGENT_DIR/pids/${name}.pid"
    local pid=""

    if [ -f "$pid_file" ]; then
        pid="$(cat "$pid_file")"
    fi

    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        kill -TERM "$pid" 2>/dev/null || true
        for _ in $(seq 1 20); do
            kill -0 "$pid" 2>/dev/null || break
            sleep 0.5
        done
    fi

    if command -v tmux >/dev/null 2>&1; then
        tmux kill-session -t "$session" >/dev/null 2>&1 || true
    fi
    rm -f "$pid_file"
}

stop_all_graceful() {
    local count="${1:-5}"
    local i
    for ((i = 0; i < count; i++)); do
        stop_agent_graceful "$i"
    done
    sleep 2
}

start_agent_direct() {
    local idx="$1"
    local case_dir="$2"
    local name="${NAMES[$idx]}"
    local home
    home="$(agent_home "$idx")"
    local session="nexarail-agent-${name}"
    local runtime_log="$AGENT_DIR/logs/${name}.log"
    local case_log="$case_dir/${name}-direct-start.log"
    mkdir -p "$AGENT_DIR/logs" "$AGENT_DIR/pids" "$case_dir"

    if command -v tmux >/dev/null 2>&1; then
        tmux kill-session -t "$session" >/dev/null 2>&1 || true
        tmux new-session -d -s "$session" \
            "exec \"$BINARY\" start --home \"$home\" --minimum-gas-prices \"0$DENOM\" --api.enable --api.address \"tcp://0.0.0.0:${APIS[$idx]}\" --api.enabled-unsafe-cors --grpc.enable --grpc.address \"0.0.0.0:${GRPCS[$idx]}\" > \"$runtime_log\" 2>&1"
        tmux display-message -p -t "$session" "#{pane_pid}" > "$AGENT_DIR/pids/${name}.pid"
    else
        nohup "$BINARY" start --home "$home" --minimum-gas-prices "0$DENOM" \
            --api.enable --api.address "tcp://0.0.0.0:${APIS[$idx]}" --api.enabled-unsafe-cors \
            --grpc.enable --grpc.address "0.0.0.0:${GRPCS[$idx]}" \
            > "$runtime_log" 2>&1 < /dev/null &
        echo $! > "$AGENT_DIR/pids/${name}.pid"
    fi

    {
        echo "agent=$name"
        echo "home=$home"
        echo "rpc=${RPCS[$idx]}"
        echo "api=${APIS[$idx]}"
        echo "grpc=${GRPCS[$idx]}"
        echo "pid=$(cat "$AGENT_DIR/pids/${name}.pid" 2>/dev/null || true)"
        echo "runtime_log=$runtime_log"
    } > "$case_log"
}

start_all_direct() {
    local count="$1"
    local case_dir="$2"
    local i
    for ((i = 0; i < count; i++)); do
        start_agent_direct "$i" "$case_dir"
        sleep 1
    done
}

copy_runtime_logs() {
    local count="$1"
    local case_dir="$2"
    local i name
    mkdir -p "$case_dir/logs"
    for ((i = 0; i < count; i++)); do
        name="${NAMES[$i]}"
        cp "$AGENT_DIR/logs/${name}.log" "$case_dir/logs/${name}.log" 2>/dev/null || true
    done
}

panic_scan() {
    local count="$1"
    local case_dir="$2"
    local i name
    : > "$case_dir/panic-scan.txt"
    for ((i = 0; i < count; i++)); do
        name="${NAMES[$i]}"
        if [ -f "$AGENT_DIR/logs/${name}.log" ]; then
            rg -n "panic|nil pointer|PrepareProposal|ProcessProposal" "$AGENT_DIR/logs/${name}.log" \
                >> "$case_dir/panic-scan.txt" 2>/dev/null || true
        fi
    done
    wc -l < "$case_dir/panic-scan.txt" | tr -d ' '
}

collect_observation() {
    local count="$1"
    local case_dir="$2"
    local label="$3"
    local pass=0 fail=0
    local min_peers="" max_peers=0 min_vals="" max_vals=0 maxh=0
    local i name rpc api home node status_file net_file validators_file h peers vals addr_file

    mkdir -p "$case_dir/queries"
    echo "case=$label timestamp_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$case_dir/queries/context.txt"

    for ((i = 0; i < count; i++)); do
        name="${NAMES[$i]}"
        rpc="${RPCS[$i]}"
        api="${APIS[$i]}"
        home="$(agent_home "$i")"
        node="tcp://127.0.0.1:$rpc"
        status_file="$case_dir/queries/${name}-status.json"
        net_file="$case_dir/queries/${name}-net_info.json"
        validators_file="$case_dir/queries/${name}-validators.json"

        curl -s --max-time 5 "http://127.0.0.1:$rpc/status" > "$status_file" 2>/dev/null || echo '{}' > "$status_file"
        curl -s --max-time 5 "http://127.0.0.1:$rpc/net_info" > "$net_file" 2>/dev/null || echo '{}' > "$net_file"
        curl -s --max-time 5 "http://127.0.0.1:$rpc/validators" > "$validators_file" 2>/dev/null || echo '{}' > "$validators_file"

        h="$(json_get "$status_file" '.result.sync_info.latest_block_height // "0"')"
        peers="$(json_get "$net_file" '.result.n_peers // "0"')"
        vals="$(json_get "$validators_file" '.result.validators | length // 0')"

        if [ "${h:-0}" -gt 0 ] 2>/dev/null; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
        if [ "${vals:-0}" -eq "$count" ] 2>/dev/null; then pass=$((pass + 1)); else fail=$((fail + 1)); fi

        if [ "${h:-0}" -gt "$maxh" ] 2>/dev/null; then maxh="$h"; fi
        if [ -z "$min_peers" ] || [ "${peers:-0}" -lt "$min_peers" ] 2>/dev/null; then min_peers="${peers:-0}"; fi
        if [ "${peers:-0}" -gt "$max_peers" ] 2>/dev/null; then max_peers="${peers:-0}"; fi
        if [ -z "$min_vals" ] || [ "${vals:-0}" -lt "$min_vals" ] 2>/dev/null; then min_vals="${vals:-0}"; fi
        if [ "${vals:-0}" -gt "$max_vals" ] 2>/dev/null; then max_vals="${vals:-0}"; fi

        addr_file="$case_dir/queries/${name}-address.txt"
        if "$BINARY" keys show "${name}-key" -a --keyring-backend test --home "$home" > "$addr_file" 2>/dev/null; then
            "$BINARY" query bank balances "$(cat "$addr_file")" --node "$node" --output json \
                > "$case_dir/queries/${name}-bank-balances.json" 2> "$case_dir/queries/${name}-bank-balances.err"
            if jq -e '.balances' "$case_dir/queries/${name}-bank-balances.json" >/dev/null 2>&1; then
                pass=$((pass + 1))
            else
                fail=$((fail + 1))
            fi
        else
            fail=$((fail + 1))
        fi
    done

    api="${APIS[0]}"
    for mod in "${MODULES[@]}"; do
        curl -s --max-time 5 "http://127.0.0.1:$api/nexarail/$mod/v1/params" \
            > "$case_dir/queries/alpha-${mod}-params.json" 2>/dev/null || echo '{}' > "$case_dir/queries/alpha-${mod}-params.json"
        if jq -e '.params' "$case_dir/queries/alpha-${mod}-params.json" >/dev/null 2>&1; then
            pass=$((pass + 1))
        else
            fail=$((fail + 1))
        fi
    done

    {
        echo "settlement.live_enabled=$(json_get "$case_dir/queries/alpha-settlement-params.json" '.params.live_enabled')"
        echo "settlement.treasury_routing_enabled=$(json_get "$case_dir/queries/alpha-settlement-params.json" '.params.treasury_routing_enabled')"
        echo "settlement.burn_routing_enabled=$(json_get "$case_dir/queries/alpha-settlement-params.json" '.params.burn_routing_enabled')"
        echo "escrow.live_enabled=$(json_get "$case_dir/queries/alpha-escrow-params.json" '.params.live_enabled')"
        echo "payout.live_enabled=$(json_get "$case_dir/queries/alpha-payout-params.json" '.params.live_enabled')"
        echo "treasury.live_enabled=$(json_get "$case_dir/queries/alpha-treasury-params.json" '.params.live_enabled')"
    } > "$case_dir/queries/live-flags.txt"

    while IFS='=' read -r _ val; do
        if [ "$val" = "false" ] || [ "$val" = "False" ]; then
            pass=$((pass + 1))
        else
            fail=$((fail + 1))
        fi
    done < "$case_dir/queries/live-flags.txt"

    curl -s --max-time 5 "http://127.0.0.1:${RPCS[0]}/dump_consensus_state" \
        > "$case_dir/queries/alpha-dump-consensus-state.json" 2>/dev/null || echo '{}' > "$case_dir/queries/alpha-dump-consensus-state.json"
    local proposer
    proposer="$(json_get "$case_dir/queries/alpha-dump-consensus-state.json" '.result.round_state.proposer.address // .result.round_state.proposer // "unknown"')"
    [ -z "$proposer" ] && proposer="unknown"

    local panic_count queries_work
    panic_count="$(panic_scan "$count" "$case_dir")"
    if [ "$fail" -eq 0 ]; then queries_work="yes"; else queries_work="no"; fi

    copy_runtime_logs "$count" "$case_dir"

    {
        printf 'LABEL=%q\n' "$label"
        echo "QUERY_PASS=$pass"
        echo "QUERY_FAIL=$fail"
        echo "QUERIES_WORK=$queries_work"
        echo "PANIC_COUNT=$panic_count"
        echo "PANICS=$([ "$panic_count" -eq 0 ] && echo no || echo yes)"
        echo "HEIGHT=$maxh"
        echo "PEER_RANGE=${min_peers:-0}-${max_peers:-0}"
        echo "VALIDATOR_RANGE=${min_vals:-0}-${max_vals:-0}"
        printf 'PROPOSER=%q\n' "$proposer"
    } > "$case_dir/observation.env"
}

record_case() {
    local case_id="$1"
    local label="$2"
    local count="$3"
    local mode="$4"
    local case_dir="$5"
    local notes="${6:-}"
    local bank_tx_hash="${7:-}"
    local block_resumes="no" start_height=0 restart_height=0 final_height=0
    local queries_work="no" panics="yes" peer_range="0-0" validator_range="0-0" proposer="unknown"

    if [ -f "$case_dir/block-advance.env" ]; then
        # shellcheck disable=SC1090
        source "$case_dir/block-advance.env"
        block_resumes="${BLOCK_RESUMES:-no}"
        restart_height="${START_HEIGHT:-0}"
        final_height="${FINAL_HEIGHT:-0}"
    fi
    if [ -f "$case_dir/start-height.txt" ]; then
        start_height="$(cat "$case_dir/start-height.txt")"
    else
        start_height="$restart_height"
    fi
    if [ -f "$case_dir/observation.env" ]; then
        # shellcheck disable=SC1090
        source "$case_dir/observation.env"
        queries_work="${QUERIES_WORK:-no}"
        panics="${PANICS:-yes}"
        peer_range="${PEER_RANGE:-0-0}"
        validator_range="${VALIDATOR_RANGE:-0-0}"
        proposer="${PROPOSER:-unknown}"
        [ "${HEIGHT:-0}" -gt "$final_height" ] 2>/dev/null && final_height="$HEIGHT"
    fi

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$case_id" "$label" "$count" "$mode" "$block_resumes" "$queries_work" "$panics" \
        "$start_height" "$restart_height" "$final_height" "$peer_range" "$validator_range" "$proposer" \
        "${bank_tx_hash:-none}" "$case_dir" "$notes" >> "$MATRIX_TSV"
}

run_clean_spawn() {
    local count="$1"
    local case_dir="$2"
    mkdir -p "$case_dir"
    log "Clean spawn count=$count evidence=$case_dir"
    SPAWN_TIMESTAMP="${TIMESTAMP}-$(basename "$case_dir")-clean" \
        "$SCRIPT_DIR/spawn-validator-agents.sh" --clean --agent-count "$count" \
        > "$case_dir/clean-spawn.log" 2>&1
    local code=$?
    echo "$code" > "$case_dir/clean-spawn.exit"
    return "$code"
}

run_reuse_restart() {
    local count="$1"
    local case_dir="$2"
    mkdir -p "$case_dir"
    log "Graceful stop before reuse-data restart count=$count"
    stop_all_graceful "$count"
    log "Reuse-data restart count=$count"
    SPAWN_TIMESTAMP="${TIMESTAMP}-$(basename "$case_dir")-reuse" \
        "$SCRIPT_DIR/spawn-validator-agents.sh" --reuse-data --agent-count "$count" \
        > "$case_dir/reuse-restart.log" 2>&1
    local code=$?
    echo "$code" > "$case_dir/reuse-restart.exit"
    return "$code"
}

run_bank_tx() {
    local case_dir="$1"
    local tx_dir="$case_dir/bank-tx-after-restart"
    local from_home="$AGENT_DIR/bravo"
    local to_home="$AGENT_DIR/alpha"
    local from_key="bravo-key"
    local to_addr txhash code
    mkdir -p "$tx_dir"

    "$BINARY" keys show alpha-key -a --keyring-backend test --home "$to_home" > "$tx_dir/to-address.txt" 2> "$tx_dir/to-address.err"
    to_addr="$(cat "$tx_dir/to-address.txt" 2>/dev/null || true)"
    "$BINARY" query bank balances "$to_addr" --node "tcp://127.0.0.1:${RPCS[0]}" --output json > "$tx_dir/alpha-balance-before.json" 2>&1 || true

    {
        echo "# Phase 9V bank tx after restart"
        date -u +%Y-%m-%dT%H:%M:%SZ
        echo "from=$from_key"
        echo "to=$to_addr"
    } > "$tx_dir/bank-tx.log"

    "$BINARY" tx send "$from_key" "$to_addr" "123$DENOM" \
        --from "$from_key" --keyring-backend test --home "$from_home" \
        --chain-id "$CHAIN_ID" --node "tcp://127.0.0.1:${RPCS[1]}" \
        --yes --fees "2000$DENOM" --gas 200000 --broadcast-mode sync --output json \
        > "$tx_dir/broadcast.json" 2> "$tx_dir/broadcast.err"
    code=$?
    echo "$code" > "$tx_dir/broadcast-code.txt"
    txhash="$(jq -r '.txhash // empty' "$tx_dir/broadcast.json" 2>/dev/null || true)"
    echo "$txhash" > "$tx_dir/txhash.txt"

    if [ -n "$txhash" ]; then
        sleep 7
        curl -s --max-time 10 "http://127.0.0.1:${RPCS[0]}/tx?hash=0x${txhash}" \
            > "$tx_dir/tx-inclusion.json" 2> "$tx_dir/tx-inclusion.err" || true
        jq -r '.result.tx_result.code // "missing"' "$tx_dir/tx-inclusion.json" > "$tx_dir/inclusion-code.txt" 2>/dev/null || echo "missing" > "$tx_dir/inclusion-code.txt"
    else
        echo "missing" > "$tx_dir/inclusion-code.txt"
    fi

    "$BINARY" query bank balances "$to_addr" --node "tcp://127.0.0.1:${RPCS[0]}" --output json > "$tx_dir/alpha-balance-after.json" 2>&1 || true
    cat "$tx_dir/txhash.txt"
}

run_reuse_case() {
    local case_id="$1"
    local label="$2"
    local count="$3"
    local wait_target="${4:-20}"
    local case_dir="$EVIDENCE_DIR/$case_id"
    mkdir -p "$case_dir"

    if ! run_clean_spawn "$count" "$case_dir"; then
        collect_observation "$count" "$case_dir" "$label" || true
        record_case "$case_id" "$label" "$count" "wrapper-reuse-data" "$case_dir" "clean spawn failed"
        return 1
    fi
    wait_for_min_height "$count" "$wait_target" 180 > "$case_dir/start-height.txt" || true
    if ! run_reuse_restart "$count" "$case_dir"; then
        collect_observation "$count" "$case_dir" "$label" || true
        record_case "$case_id" "$label" "$count" "wrapper-reuse-data" "$case_dir" "reuse restart command failed"
        return 1
    fi
    wait_for_block_advance "$count" 3 90 "$case_dir/block-advance.env" || true
    collect_observation "$count" "$case_dir" "$label" || true
    record_case "$case_id" "$label" "$count" "wrapper-reuse-data" "$case_dir" ""
}

run_standard_direct_case() {
    local case_id="standard-direct"
    local label="Single-node standard direct start, clean stop, direct restart"
    local case_dir="$EVIDENCE_DIR/$case_id"
    mkdir -p "$case_dir"

    run_clean_spawn 1 "$case_dir" || true
    wait_for_min_height 1 20 180 > "$case_dir/start-height.txt" || true
    stop_all_graceful 1
    start_agent_direct 0 "$case_dir"
    wait_for_block_advance 1 3 90 "$case_dir/direct-first-start-block-advance.env" || true
    stop_all_graceful 1
    start_agent_direct 0 "$case_dir"
    wait_for_block_advance 1 3 90 "$case_dir/block-advance.env" || true
    collect_observation 1 "$case_dir" "$label" || true
    record_case "$case_id" "$label" 1 "direct-node-restart" "$case_dir" ""
}

run_one_node_case() {
    local case_id="F-one-node"
    local label="Restart alpha only while other 4 validators continue"
    local case_dir="$EVIDENCE_DIR/$case_id"
    mkdir -p "$case_dir"

    run_clean_spawn 5 "$case_dir" || true
    wait_for_min_height 5 20 180 > "$case_dir/start-height.txt" || true
    stop_agent_graceful 0
    wait_for_block_advance 5 3 90 "$case_dir/network-with-alpha-stopped.env" || true
    start_agent_direct 0 "$case_dir"
    wait_for_block_advance 5 3 90 "$case_dir/block-advance.env" || true
    collect_observation 5 "$case_dir" "$label" || true
    record_case "$case_id" "$label" 5 "direct-one-node-restart" "$case_dir" ""
}

run_all_direct_case() {
    local case_id="G-all-direct-simultaneous"
    local label="Restart all 5 validators simultaneously using direct start"
    local case_dir="$EVIDENCE_DIR/$case_id"
    mkdir -p "$case_dir"

    run_clean_spawn 5 "$case_dir" || true
    wait_for_min_height 5 20 180 > "$case_dir/start-height.txt" || true
    stop_all_graceful 5
    start_all_direct 5 "$case_dir"
    wait_for_block_advance 5 3 120 "$case_dir/block-advance.env" || true
    collect_observation 5 "$case_dir" "$label" || true
    local txhash
    txhash="$(run_bank_tx "$case_dir" || true)"
    record_case "$case_id" "$label" 5 "direct-all-node-restart" "$case_dir" "" "$txhash"
}

run_all_sequential_case() {
    local case_id="H-all-direct-sequential"
    local label="Restart all 5 validators sequentially while network continues"
    local case_dir="$EVIDENCE_DIR/$case_id"
    local i
    mkdir -p "$case_dir"

    run_clean_spawn 5 "$case_dir" || true
    wait_for_min_height 5 20 180 > "$case_dir/start-height.txt" || true
    for ((i = 0; i < 5; i++)); do
        stop_agent_graceful "$i"
        sleep 3
        start_agent_direct "$i" "$case_dir"
        wait_for_block_advance 5 2 90 "$case_dir/${NAMES[$i]}-sequential-advance.env" || true
    done
    wait_for_block_advance 5 3 90 "$case_dir/block-advance.env" || true
    collect_observation 5 "$case_dir" "$label" || true
    record_case "$case_id" "$label" 5 "direct-sequential-node-restart" "$case_dir" ""
}

run_soak_restart_case() {
    local case_id="E-5-agent-after-soak"
    local label="5-agent restart after soak"
    local case_dir="$EVIDENCE_DIR/$case_id"
    local soak_duration="$SHORT_SOAK_DURATION"
    local note="short soak used because --include-long-soak was not set"
    mkdir -p "$case_dir"

    if [ "$INCLUDE_LONG_SOAK" -eq 1 ]; then
        soak_duration="$LONG_SOAK_DURATION"
        note="full requested soak duration"
    fi

    run_clean_spawn 5 "$case_dir" || true
    wait_for_min_height 5 20 180 > "$case_dir/start-height.txt" || true
    SOAK_TIMESTAMP="${TIMESTAMP}-${case_id}" SOAK_EVIDENCE_DIR="$case_dir/soak" \
        "$SCRIPT_DIR/run-agent-soak-test.sh" --duration "$soak_duration" --interval 60s --query-interval 15m \
        > "$case_dir/soak.log" 2>&1 || true
    run_reuse_restart 5 "$case_dir" || true
    wait_for_block_advance 5 3 120 "$case_dir/block-advance.env" || true
    collect_observation 5 "$case_dir" "$label" || true
    record_case "$case_id" "$label" 5 "wrapper-reuse-data-after-soak" "$case_dir" "$note"
}

cleanup() {
    "$SCRIPT_DIR/stop-validator-agents.sh" > "$EVIDENCE_DIR/final-stop.log" 2>&1 || true
}
trap cleanup EXIT

if [ ! -x "$BINARY" ]; then
    echo "Binary not found or not executable: $BINARY" >&2
    exit 1
fi

cat > "$EVIDENCE_DIR/run-context.txt" <<EOF
Timestamp UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Project: $PROJECT_DIR
Binary: $BINARY
Agent dir: $AGENT_DIR
Evidence dir: $EVIDENCE_DIR
Include long soak: $INCLUDE_LONG_SOAK
Long soak duration: $LONG_SOAK_DURATION
Short soak duration: $SHORT_SOAK_DURATION
EOF

log "Phase 9V restart matrix evidence: $EVIDENCE_DIR"

"$SCRIPT_DIR/stop-validator-agents.sh" > "$EVIDENCE_DIR/initial-stop.log" 2>&1 || true

run_reuse_case "A-single-validator" "Single-validator clean start, clean stop, reuse-data restart" 1 20
run_reuse_case "B-three-agent" "3-agent clean start, clean stop, reuse-data restart" 3 20
run_reuse_case "C-five-agent" "5-agent clean start, clean stop, reuse-data restart" 5 20
run_reuse_case "D-five-agent-height20" "5-agent immediate restart at height 20" 5 20
run_soak_restart_case
run_one_node_case
run_all_direct_case
run_all_sequential_case
run_standard_direct_case

cat > "$EVIDENCE_DIR/final-summary.md" <<EOF
# Phase 9V Restart Matrix Summary

- Timestamp UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Evidence: $EVIDENCE_DIR
- Long soak case used: $([ "$INCLUDE_LONG_SOAK" -eq 1 ] && echo "$LONG_SOAK_DURATION" || echo "$SHORT_SOAK_DURATION diagnostic soak")

## Matrix

EOF

{
    echo '```text'
    column -t -s $'\t' "$MATRIX_TSV" 2>/dev/null || cat "$MATRIX_TSV"
    echo '```'
} >> "$EVIDENCE_DIR/final-summary.md"

log "Phase 9V restart matrix complete"
cat "$EVIDENCE_DIR/final-summary.md"
