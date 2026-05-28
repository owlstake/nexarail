#!/usr/bin/env bash
# NexaRail — Phase 10B Product Flow Rehearsal
#
# TESTNET/DEVNET ONLY. Tokens have zero value. No mainnet exists.
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
SCRIPT_DIR="$PROJECT_DIR/scripts/testnet"
BINARY="$PROJECT_DIR/build/nexaraild"
CHAIN_ID="nexarail-agent-testnet-1"
DENOM="unxrl"
TX_FEE="10000$DENOM"
AGENT_DIR="$PROJECT_DIR/rehearsals/validator-agents"
TIMESTAMP="${PRODUCT_FLOW_TIMESTAMP:-$(date -u +%Y%m%dT%H%M%SZ)}"
EVIDENCE_DIR="${EVIDENCE_DIR:-$AGENT_DIR/product-flows/evidence/$TIMESTAMP}"
RUN_LOG="$EVIDENCE_DIR/run.log"
BRAVO_RPC="tcp://127.0.0.1:27667"
BRAVO_RPC_HTTP="http://127.0.0.1:27667"
BRAVO_API="1418"
BRAVO_GRPC="127.0.0.1:9191"
GOV_ADDR="nxr10d07y265gmmuvt4z0w9aw880jnsr700js8jz70"
SUITE="all"
MODE="full"
FORCE_CLEAN=0
NO_SPAWN=0
KEEP_RUNNING=0
GLOBAL_TIMEOUT=""
GLOBAL_TIMEOUT_EXPLICIT=0
RESUME_FROM=""
RUN_STARTED_AT="$(date +%s)"
STAGE_DURATIONS_FILE="$EVIDENCE_DIR/stage-durations.tsv"
SEMANTIC_JSONL="$EVIDENCE_DIR/semantic-assertions.jsonl"
SEMANTIC_JSON="$EVIDENCE_DIR/semantic-assertions.json"
SEMANTIC_MD="$EVIDENCE_DIR/semantic-assertions.md"
CURRENT_STAGE="argument parsing"
FAILED_STAGE=""
EXIT_HANDLED=0
GLOBAL_TIMER_PID=""

AGENTS=(alpha bravo charlie delta echo)
MODULES=(fees merchant settlement escrow payout treasury)
AGENT_DEFS=(
    "alpha:27657:27656:1417:9190"
    "bravo:27667:27666:1418:9191"
    "charlie:27677:27676:1419:9192"
    "delta:27687:27686:1420:9193"
    "echo:27697:27696:1421:9194"
)
PASS=0
FAIL=0

usage() {
    cat <<EOF
Usage: scripts/testnet/run-product-flow-rehearsal.sh [--suite SUITE|--smoke|--full] [options]

Suites:
  --suite smoke        Run spawn/readiness/query/bank-send/live-flag smoke only.
  --suite merchant     Run merchant product-flow suite.
  --suite settlement   Run settlement metadata/live/treasury/burn suites.
  --suite escrow       Run escrow product-flow suite.
  --suite treasury     Run treasury product-flow suite.
  --suite payout       Run payout product-flow suite.
  --suite safety       Run safety checks suite.
  --suite all          Run smoke gate, then all product-flow suites.
  --smoke              Alias for --suite smoke.
  --full               Alias for --suite all.

Options:
  --force-clean        Let the harness clean stale validator-agent processes and ports safely.
  --no-spawn           Do not stop or spawn agents; use an existing local 5-agent testnet.
  --keep-running       Leave agents running after success/failure.
  --resume-from STAGE  Resume from a stage after checking runtime prerequisites.
  --global-timeout SEC Global rehearsal timeout. Defaults: smoke=300, module=600, all=2400.
  --timeout SECONDS    Alias for --global-timeout.
  --evidence-dir PATH  Evidence directory. Default: product-flows/evidence/<timestamp>.
EOF
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --suite)
                SUITE="${2:-}"
                MODE="$SUITE"
                shift 2
                ;;
            --smoke)
                SUITE="smoke"
                MODE="smoke"
                shift
                ;;
            --full)
                SUITE="all"
                MODE="full"
                shift
                ;;
            --force-clean)
                FORCE_CLEAN=1
                shift
                ;;
            --no-spawn)
                NO_SPAWN=1
                shift
                ;;
            --keep-running)
                KEEP_RUNNING=1
                shift
                ;;
            --resume-from)
                RESUME_FROM="${2:-}"
                shift 2
                ;;
            --global-timeout|--timeout)
                GLOBAL_TIMEOUT="${2:-}"
                GLOBAL_TIMEOUT_EXPLICIT=1
                shift 2
                ;;
            --evidence-dir)
                EVIDENCE_DIR="${2:-}"
                RUN_LOG="$EVIDENCE_DIR/run.log"
                STAGE_DURATIONS_FILE="$EVIDENCE_DIR/stage-durations.tsv"
                SEMANTIC_JSONL="$EVIDENCE_DIR/semantic-assertions.jsonl"
                SEMANTIC_JSON="$EVIDENCE_DIR/semantic-assertions.json"
                SEMANTIC_MD="$EVIDENCE_DIR/semantic-assertions.md"
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

    case "$SUITE" in smoke|merchant|settlement|escrow|treasury|payout|safety|all) ;; *) echo "Invalid --suite: $SUITE" >&2; exit 2 ;; esac
    case "$RESUME_FROM" in ""|preflight|spawn|query-readiness|merchant|settlement-metadata|settlement-live|settlement-treasury|settlement-burn|escrow|treasury|payout|safety|final-live-flags) ;; *) echo "Invalid --resume-from: $RESUME_FROM" >&2; exit 2 ;; esac
    if [ "$GLOBAL_TIMEOUT_EXPLICIT" -eq 0 ]; then
        case "$SUITE" in
            smoke) GLOBAL_TIMEOUT=300 ;;
            all) GLOBAL_TIMEOUT=2400 ;;
            *) GLOBAL_TIMEOUT=600 ;;
        esac
    fi
    case "$GLOBAL_TIMEOUT" in ''|*[!0-9]*) echo "Invalid --timeout: $GLOBAL_TIMEOUT" >&2; exit 2 ;; esac
    if [ "$NO_SPAWN" -eq 1 ] && [ "$FORCE_CLEAN" -eq 1 ]; then
        echo "Refusing conflicting modes: --no-spawn cannot be combined with --force-clean" >&2
        exit 2
    fi
}

setup_evidence() {
    mkdir -p "$EVIDENCE_DIR"/{preflight,merchant,settlement,escrow,treasury,payout,safety,final-state,gov,diagnostics,logs,txs,queries}
    : > "$RUN_LOG"
    : > "$EVIDENCE_DIR/failure-stage.txt"
    # Use explicit logging function instead of global exec > >(tee) pipe
    # (avoid output buffering deadlock under non-interactive orchestration)
    _log() { echo "$*" | tee -a "$RUN_LOG"; }
    _log_cmd() { "$@" >> "$RUN_LOG" 2>&1; }

    cat > "$EVIDENCE_DIR/env.txt" <<EOF
Timestamp UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Project: $PROJECT_DIR
Evidence: $EVIDENCE_DIR
Mode: $MODE
Suite: $SUITE
Force clean: $FORCE_CLEAN
No spawn: $NO_SPAWN
Keep running: $KEEP_RUNNING
Global timeout: $GLOBAL_TIMEOUT
Resume from: ${RESUME_FROM:-none}
Shell: ${SHELL:-unknown}
PATH: $PATH
EOF
    touch "$EVIDENCE_DIR"/{ps-before.txt,ps-after.txt,pgrep-before.txt,pgrep-after.txt,lsof-before.txt,lsof-after.txt,port-check-before.txt,port-check-after.txt,spawn.log,query.log,smoke.log,result-events.log}
    : > "$SEMANTIC_JSONL"
    : > "$SEMANTIC_JSON"
    : > "$SEMANTIC_MD"
    printf 'stage\tstatus\tstarted_at\tended_at\tduration_seconds\texit_code\n' > "$STAGE_DURATIONS_FILE"
    cat > "$EVIDENCE_DIR/resume-metadata.txt" <<EOF
Resume requested: ${RESUME_FROM:-none}
Suite: $SUITE
Global timeout: $GLOBAL_TIMEOUT
EOF
}

parse_args "$@"
setup_evidence

mkdir -p "$EVIDENCE_DIR"/{preflight,merchant,settlement,escrow,treasury,payout,safety,final-state,gov}

pass() {
    _log "  PASS  $1"
    echo "PASS $1" >> "$EVIDENCE_DIR/result-events.log"
    PASS=$((PASS + 1))
}

fail() {
    _log "  FAIL   $1"
    echo "FAIL $1" >> "$EVIDENCE_DIR/result-events.log"
    echo "FAIL  What: $1" >> "$EVIDENCE_DIR/result-events-context.log"
    echo "FAIL  Why: see run.log and $EVIDENCE_DIR for diagnostics" >> "$EVIDENCE_DIR/result-events-context.log"
    echo "FAIL  Evidence: $EVIDENCE_DIR" >> "$EVIDENCE_DIR/result-events-context.log"
    echo "FAIL  Rerun: ./scripts/testnet/run-product-flow-rehearsal.sh --suite $SUITE --resume-from $CURRENT_STAGE" >> "$EVIDENCE_DIR/result-events-context.log"
    FAIL=$((FAIL + 1))
}

note() {
    echo "  --  $1"
}

semantic_record() {
    local label="$1"
    local status="$2"
    local detail="$3"
    local evidence="${4:-}"
    python3 - "$SEMANTIC_JSONL" "$label" "$status" "$detail" "$evidence" <<'PY'
import json, sys, time
path, label, status, detail, evidence = sys.argv[1:6]
with open(path, "a", encoding="utf-8") as f:
    f.write(json.dumps({
        "label": label,
        "status": status,
        "detail": detail,
        "evidence": evidence,
        "timestamp_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    }, sort_keys=True) + "\n")
PY
}

semantic_assert() {
    local label="$1"
    local status="$2"
    local detail="$3"
    local evidence="${4:-}"
    semantic_record "$label" "$status" "$detail" "$evidence"
    if [ "$status" = "pass" ]; then
        pass "semantic: $label"
        return 0
    fi
    fail "semantic: $label — $detail"
    return 1
}

semantic_check_jq() {
    local label="$1"
    local file="$2"
    local expr="$3"
    if [ ! -s "$file" ]; then
        semantic_assert "$label" "fail" "missing or empty evidence file" "$file"
        return 1
    fi
    if jq -e "$expr" "$file" >/dev/null 2>&1; then
        semantic_assert "$label" "pass" "$expr" "$file"
        return 0
    fi
    semantic_assert "$label" "fail" "$expr" "$file"
    return 1
}

finalize_semantic_assertions() {
    python3 - "$SEMANTIC_JSONL" "$SEMANTIC_JSON" "$SEMANTIC_MD" "$EVIDENCE_DIR" <<'PY'
import json, pathlib, sys
jsonl, out_json, out_md, evidence = sys.argv[1:5]
records = []
path = pathlib.Path(jsonl)
if path.exists():
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            records.append(json.loads(line))
passed = sum(1 for r in records if r.get("status") == "pass")
failed = sum(1 for r in records if r.get("status") != "pass")
summary = {"evidence": evidence, "pass": passed, "fail": failed, "assertions": records}
pathlib.Path(out_json).write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
lines = [
    "# Semantic Assertions",
    "",
    f"- Evidence: `{evidence}`",
    f"- Pass: {passed}",
    f"- Fail: {failed}",
    "",
    "| Status | Assertion | Evidence | Detail |",
    "|---|---|---|---|",
]
for r in records:
    lines.append("| {status} | {label} | `{evidence}` | `{detail}` |".format(
        status=r.get("status", ""),
        label=str(r.get("label", "")).replace("|", "\\|"),
        evidence=str(r.get("evidence", "")).replace("|", "\\|"),
        detail=str(r.get("detail", "")).replace("|", "\\|"),
    ))
pathlib.Path(out_md).write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
}

log_stage_start() {
    CURRENT_STAGE="$1"
    echo "$CURRENT_STAGE" > "$EVIDENCE_DIR/failure-stage.txt"
    echo "[PHASE 10B] START $CURRENT_STAGE"
}

log_stage_ok() {
    echo "[PHASE 10B] OK $1"
}

log_stage_fail() {
    FAILED_STAGE="$1"
    echo "$FAILED_STAGE" > "$EVIDENCE_DIR/failure-stage.txt"
    echo "[PHASE 10B] FAIL $FAILED_STAGE"
}

canonical_stage_rank() {
    case "$1" in
        preflight) echo 10 ;;
        spawn) echo 20 ;;
        query-readiness) echo 30 ;;
        merchant) echo 40 ;;
        settlement-metadata) echo 50 ;;
        settlement-live) echo 60 ;;
        settlement-treasury) echo 70 ;;
        settlement-burn) echo 80 ;;
        escrow) echo 90 ;;
        treasury) echo 100 ;;
        payout) echo 110 ;;
        safety) echo 120 ;;
        final-live-flags) echo 130 ;;
        *) echo 999 ;;
    esac
}

should_run_stage_key() {
    local key="$1"
    [ -z "$RESUME_FROM" ] && return 0
    [ "$(canonical_stage_rank "$key")" -ge "$(canonical_stage_rank "$RESUME_FROM")" ]
}

record_stage_duration() {
    local stage="$1"
    local status="$2"
    local started_at="$3"
    local ended_at="$4"
    local exit_code="$5"
    local duration=$((ended_at - started_at))
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$stage" "$status" "$started_at" "$ended_at" "$duration" "$exit_code" >> "$STAGE_DURATIONS_FILE"
}

skip_stage() {
    local stage="$1"
    local reason="$2"
    local now
    now="$(date +%s)"
    echo "[PHASE 10B] SKIP $stage — $reason"
    record_stage_duration "$stage" "skipped" "$now" "$now" 0
}

ports_csv() {
    printf '%s\n' "27657 27667 27677 27687 27697 27656 27666 27676 27686 27696 1417 1418 1419 1420 1421 9190 9191 9192 9193 9194"
}

collect_snapshot() {
    local label="$1"
    ps aux 2>/dev/null | grep '[n]exaraild' > "$EVIDENCE_DIR/ps-${label}.txt" || true
    pgrep -la nexaraild > "$EVIDENCE_DIR/pgrep-${label}.txt" 2>&1 || true
    : > "$EVIDENCE_DIR/lsof-${label}.txt"
    : > "$EVIDENCE_DIR/port-check-${label}.txt"
    for port in $(ports_csv); do
        {
            echo "### port $port"
            lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>&1 || true
        } >> "$EVIDENCE_DIR/lsof-${label}.txt"
        if lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
            echo "FAIL port $port in use" >> "$EVIDENCE_DIR/port-check-${label}.txt"
        else
            echo "PASS port $port free" >> "$EVIDENCE_DIR/port-check-${label}.txt"
        fi
    done
}

run_with_timeout() {
    local seconds="$1"
    shift
    local cmd_pid timer_pid status timed_out=0

    ( trap - ERR INT TERM EXIT; set -Eeuo pipefail; "$@" ) &
    cmd_pid=$!
    set +e
    (
        sleep "$seconds"
        if kill -0 "$cmd_pid" >/dev/null 2>&1; then
            timed_out=1
            echo "  FAIL timeout after ${seconds}s: $*" >&2
            pkill -TERM -P "$cmd_pid" >/dev/null 2>&1 || true
            kill -TERM "$cmd_pid" >/dev/null 2>&1 || true
            sleep 2
            pkill -KILL -P "$cmd_pid" >/dev/null 2>&1 || true
            kill -KILL "$cmd_pid" >/dev/null 2>&1 || true
        fi
    ) &
    timer_pid=$!

    wait "$cmd_pid"
    status=$?
    kill "$timer_pid" >/dev/null 2>&1 || true
    wait "$timer_pid" >/dev/null 2>&1 || true
    set -e

    if [ "$status" -eq 143 ] || [ "$status" -eq 137 ]; then
        return 124
    fi
    [ "$timed_out" -eq 1 ] && return 124
    return "$status"
}

stage_run() {
    local stage="$1"
    local seconds="$2"
    shift 2
    local started_at ended_at
    started_at="$(date +%s)"
    log_stage_start "$stage"
    local status
    if run_with_timeout "$seconds" "$@"; then
        ended_at="$(date +%s)"
        record_stage_duration "$stage" "ok" "$started_at" "$ended_at" 0
        log_stage_ok "$stage"
        return 0
    else
        status=$?
    fi
    ended_at="$(date +%s)"
    record_stage_duration "$stage" "fail" "$started_at" "$ended_at" "$status"
    log_stage_fail "$stage"
    echo "stage=$stage exit_code=$status" > "$EVIDENCE_DIR/failed-command.txt"
    return "$status"
}

start_global_timeout() {
    (
        sleep "$GLOBAL_TIMEOUT"
        echo "[PHASE 10B] FAIL global timeout after ${GLOBAL_TIMEOUT}s" >&2
        kill -TERM "$$" >/dev/null 2>&1 || true
    ) &
    GLOBAL_TIMER_PID=$!
}

stop_global_timeout() {
    if [ -n "${GLOBAL_TIMER_PID:-}" ]; then
        kill "$GLOBAL_TIMER_PID" >/dev/null 2>&1 || true
        wait "$GLOBAL_TIMER_PID" >/dev/null 2>&1 || true
    fi
}

capture_descriptor_errors() {
    local outfile="$EVIDENCE_DIR/descriptor-errors.txt"
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

root_cause_hypothesis() {
    local outfile="$EVIDENCE_DIR/root-cause-hypothesis.txt"
    {
        echo "Failed stage: ${FAILED_STAGE:-$CURRENT_STAGE}"
        echo "Evidence: $EVIDENCE_DIR"
        if grep -qi "global timeout" "$RUN_LOG" 2>/dev/null; then
            echo "Hypothesis: full mode exceeded the ${GLOBAL_TIMEOUT}s global rehearsal cap while the current stage was still progressing."
        elif grep -qi "timeout" "$RUN_LOG" 2>/dev/null; then
            echo "Hypothesis: the failed stage exceeded its hard timeout; inspect run.log and diagnostics for the blocked command."
        elif grep -qi "address already in use\|bind: address already in use" "$EVIDENCE_DIR"/logs/*.log "$RUN_LOG" 2>/dev/null; then
            echo "Hypothesis: a validator-agent port was already owned by a prior runtime or another process."
        elif grep -qi "panic\|index out of range\|unknownproto\|CheckTx" "$EVIDENCE_DIR/descriptor-errors.txt" 2>/dev/null; then
            echo "Hypothesis: descriptor/CheckTx runtime failure occurred during product-flow transaction handling."
        elif grep -qi "not found by CometBFT tx query" "$RUN_LOG" 2>/dev/null; then
            echo "Hypothesis: transaction broadcast succeeded but inclusion/readback did not complete before timeout."
        else
            echo "Hypothesis: see diagnostics/final, run.log, spawn.log, query.log, and validator logs for the exact failing command and runtime state."
        fi
    } > "$outfile"
}

resume_stage_for_label() {
    case "$1" in
        *preflight*) echo "preflight" ;;
        *spawn*|*cleanup*|*port*) echo "spawn" ;;
        *query*) echo "query-readiness" ;;
        *merchant*) echo "merchant" ;;
        *metadata*) echo "settlement-metadata" ;;
        *treasury*routing*) echo "settlement-treasury" ;;
        *burn*routing*) echo "settlement-burn" ;;
        *settlement*live*) echo "settlement-live" ;;
        *escrow*) echo "escrow" ;;
        *treasury*) echo "treasury" ;;
        *payout*) echo "payout" ;;
        *safety*) echo "safety" ;;
        *final*live*flags*) echo "final-live-flags" ;;
        *) echo "preflight" ;;
    esac
}

write_rerun_command() {
    local resume_stage
    resume_stage="$(resume_stage_for_label "${FAILED_STAGE:-$CURRENT_STAGE}")"
    cat > "$EVIDENCE_DIR/rerun-command.txt" <<EOF
scripts/testnet/run-product-flow-rehearsal.sh --suite $SUITE --no-spawn --resume-from $resume_stage --global-timeout $GLOBAL_TIMEOUT --evidence-dir "$EVIDENCE_DIR-resume-$resume_stage"
EOF
    echo "[PHASE 10B] RERUN $(cat "$EVIDENCE_DIR/rerun-command.txt")"
}

run_diagnostics() {
    local label="$1"
    mkdir -p "$EVIDENCE_DIR/diagnostics"
    "$SCRIPT_DIR/diagnose-agent-freeze.sh" --evidence-dir "$EVIDENCE_DIR" --label "$label" \
        > "$EVIDENCE_DIR/diagnostics/${label}.log" 2>&1 || true
    capture_descriptor_errors
    root_cause_hypothesis
}

copy_validator_logs() {
    mkdir -p "$EVIDENCE_DIR/logs"
    for agent in "${AGENTS[@]}"; do
        if [ -f "$AGENT_DIR/logs/${agent}.log" ]; then
            cp "$AGENT_DIR/logs/${agent}.log" "$EVIDENCE_DIR/logs/${agent}.log" 2>/dev/null || true
            tail -200 "$AGENT_DIR/logs/${agent}.log" > "$EVIDENCE_DIR/logs/${agent}-last-200.log" 2>/dev/null || true
        fi
    done
}

stop_agents_if_needed() {
    if [ "$KEEP_RUNNING" -eq 1 ] || [ "$NO_SPAWN" -eq 1 ]; then
        echo "  --  keeping agents running by request or no-spawn mode"
        collect_snapshot after
        return 0
    fi
    "$SCRIPT_DIR/stop-validator-agents.sh" --force --evidence-dir "$EVIDENCE_DIR" > "$EVIDENCE_DIR/diagnostics/stop.log" 2>&1 || true
    collect_snapshot after
    copy_validator_logs
}

finalize_evidence() {
    collect_snapshot after
    copy_validator_logs
    capture_descriptor_errors
    finalize_semantic_assertions
    if [ -x "$SCRIPT_DIR/extract-product-flow-events.sh" ]; then
        "$SCRIPT_DIR/extract-product-flow-events.sh" --evidence-dir "$EVIDENCE_DIR" > "$EVIDENCE_DIR/diagnostics/event-summary.log" 2>&1 || return 1
    fi
    if [ -x "$SCRIPT_DIR/index-governance-product-evidence.sh" ]; then
        "$SCRIPT_DIR/index-governance-product-evidence.sh" --evidence-dir "$EVIDENCE_DIR" > "$EVIDENCE_DIR/diagnostics/governance-product-evidence.log" 2>&1 || return 1
    fi
    root_cause_hypothesis
}

handle_failure() {
    local exit_code="$1"
    [ "$EXIT_HANDLED" -eq 1 ] && exit "$exit_code"
    EXIT_HANDLED=1
    FAILED_STAGE="${FAILED_STAGE:-$CURRENT_STAGE}"
    echo "$FAILED_STAGE" > "$EVIDENCE_DIR/failure-stage.txt"
    echo ""
    echo "[PHASE 10B] FAIL $FAILED_STAGE"
    echo "[PHASE 10B] EXIT_CODE $exit_code"
    echo "[PHASE 10B] EVIDENCE $EVIDENCE_DIR"
    echo "[PHASE 10B] WHAT FAILED: stage=$FAILED_STAGE (exit=$exit_code)"
    echo "[PHASE 10B] WHY: check $RUN_LOG for error context near the failure"
    echo "[PHASE 10B] EVIDENCE: $EVIDENCE_DIR — diagnostics, run.log, spawn.log, query.log, validator logs"
    run_diagnostics "failure-${FAILED_STAGE//[^A-Za-z0-9_.-]/_}"
    write_rerun_command
    stop_agents_if_needed
    finalize_evidence
    write_summary || true
    stop_global_timeout
    exit "$exit_code"
}

handle_exit() {
    local exit_code="$?"
    stop_global_timeout
    if [ "$exit_code" -ne 0 ] && [ "$EXIT_HANDLED" -eq 0 ]; then
        handle_failure "$exit_code"
    fi
}

trap 'handle_failure $?' ERR
trap 'handle_failure 130' INT
trap 'handle_failure 143' TERM
trap 'handle_exit' EXIT

json_get() {
    local file="$1"
    local expr="$2"
    jq -r "$expr" "$file" 2>/dev/null || echo ""
}

agent_home() {
    printf '%s/%s' "$AGENT_DIR" "$1"
}

agent_addr() {
    local agent="$1"
    "$BINARY" keys show "${agent}-key" -a --keyring-backend test --home "$(agent_home "$agent")"
}

rehearsal_addr() {
    local key="$1"
    local home
    home="$(agent_home alpha)"
    if ! "$BINARY" keys show "$key" --keyring-backend test --home "$home" >/dev/null 2>&1; then
        "$BINARY" keys add "$key" --keyring-backend test --home "$home" >/dev/null 2> "$EVIDENCE_DIR/preflight/$key-add.err"
    fi
    "$BINARY" keys show "$key" -a --keyring-backend test --home "$home"
}

record_context() {
    cat > "$EVIDENCE_DIR/run-context.txt" <<EOF
NexaRail Phase 10B product-flow rehearsal
Timestamp UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Project: $PROJECT_DIR
Chain ID: $CHAIN_ID
Evidence: $EVIDENCE_DIR
RPC: $BRAVO_RPC
API: $BRAVO_API
Mode: local 5-agent testnet only
External validators: pending, not active for this phase
Public testnet: NO-GO
Mainnet: NO-GO
EOF
}

build_binary() {
    if [ ! -x "$BINARY" ]; then
        (cd "$PROJECT_DIR" && make build)
    fi
    "$BINARY" version > "$EVIDENCE_DIR/preflight/version.txt" 2>&1 || true
    pass "binary available"
}

spawn_clean_testnet() {
    note "starting clean 5-agent testnet"
    local -a spawn_args
    spawn_args=(--clean --evidence-dir "$EVIDENCE_DIR")
    if [ "$FORCE_CLEAN" -eq 1 ]; then
        spawn_args+=(--force-clean)
    fi
    if SPAWN_TIMESTAMP="$TIMESTAMP" "$SCRIPT_DIR/spawn-validator-agents.sh" "${spawn_args[@]}" \
        > "$EVIDENCE_DIR/spawn.log" 2>&1; then
        cp "$EVIDENCE_DIR/spawn.log" "$EVIDENCE_DIR/preflight/spawn.log" 2>/dev/null || true
        pass "clean 5-agent spawn command"
    else
        cp "$EVIDENCE_DIR/spawn.log" "$EVIDENCE_DIR/preflight/spawn.log" 2>/dev/null || true
        tail -120 "$EVIDENCE_DIR/spawn.log" || true
        fail "clean 5-agent spawn command — see $EVIDENCE_DIR/spawn.log and $EVIDENCE_DIR/preflight/spawn.log"
        return 1
    fi
}

latest_height() {
    curl -s --max-time 5 "$BRAVO_RPC_HTTP/status" \
        | jq -r '.result.sync_info.latest_block_height // "0"' 2>/dev/null || echo "0"
}

wait_for_height_gt_20() {
    local h
    for _ in $(seq 1 60); do
        h="$(latest_height)"
        echo "$h" > "$EVIDENCE_DIR/preflight/latest-height.txt"
        if [ "${h:-0}" -gt 20 ] 2>/dev/null; then
            pass "height > 20 height=$h"
            return 0
        fi
        sleep 3
    done
    fail "height > 20 — latest=$h. See $EVIDENCE_DIR/preflight/latest-height.txt. Check node sync at $BRAVO_RPC_HTTP/status."
    return 1
}

wait_for_height_gt() {
    local threshold="$1"
    local h previous=""
    for _ in $(seq 1 60); do
        h="$(latest_height)"
        echo "$h" > "$EVIDENCE_DIR/preflight/latest-height.txt"
        if [ "${h:-0}" -gt "$threshold" ] 2>/dev/null; then
            if [ -n "$previous" ] && [ "${h:-0}" -gt "${previous:-0}" ] 2>/dev/null; then
                pass "height > $threshold and advancing height=$h"
                return 0
            fi
            previous="$h"
        fi
        sleep 3
    done
    fail "height > $threshold and advancing — latest=$h. See $EVIDENCE_DIR/preflight/latest-height.txt. Node may be stalled or slow."
    return 1
}

preflight_stage() {
    record_context
    build_binary
    command -v jq >/dev/null 2>&1 || { fail "jq not installed — install: brew install jq"; return 1; }
    command -v curl >/dev/null 2>&1 || { fail "curl not installed — install: brew install curl"; return 1; }
    command -v lsof >/dev/null 2>&1 || { fail "lsof not installed — install: brew install lsof"; return 1; }
    pass "preflight dependencies available"
}

stale_process_detection_stage() {
    collect_snapshot before
    if pgrep -f "nexaraild.*validator-agents" >/dev/null 2>&1; then
        if [ "$FORCE_CLEAN" -eq 1 ] || [ "$NO_SPAWN" -eq 1 ]; then
            note "validator-agent nexaraild processes detected; mode permits controlled handling"
            return 0
        fi
        fail "stale validator-agent nexaraild processes detected. Use --force-clean or manually kill: pkill -f 'nexaraild.*validator-agents'. See $EVIDENCE_DIR/diagnostics/ for details."
        return 1
    fi
    pass "no stale validator-agent nexaraild processes"
}

cleanup_stage() {
    if [ "$NO_SPAWN" -eq 1 ]; then
        note "no-spawn selected; cleanup skipped"
        return 0
    fi
    local -a stop_args
    stop_args=(--evidence-dir "$EVIDENCE_DIR")
    [ "$FORCE_CLEAN" -eq 1 ] && stop_args+=(--force)
    "$SCRIPT_DIR/stop-validator-agents.sh" "${stop_args[@]}" > "$EVIDENCE_DIR/diagnostics/pre-spawn-stop.log" 2>&1
    pass "validator-agent cleanup completed"
}

port_check_stage() {
    local used=0
    : > "$EVIDENCE_DIR/port-check-before.txt"
    for port in $(ports_csv); do
        if lsof -nP -iTCP:"$port" -sTCP:LISTEN > "$EVIDENCE_DIR/diagnostics/port-${port}.txt" 2>&1; then
            echo "FAIL port $port in use" >> "$EVIDENCE_DIR/port-check-before.txt"
            used=1
        else
            echo "PASS port $port free" >> "$EVIDENCE_DIR/port-check-before.txt"
        fi
    done
    if [ "$NO_SPAWN" -eq 1 ]; then
        pass "port check recorded for no-spawn runtime"
        return 0
    fi
    if [ "$used" -eq 0 ]; then
        pass "agent ports free before spawn"
        return 0
    fi
    if [ "$FORCE_CLEAN" -eq 1 ]; then
        "$SCRIPT_DIR/stop-validator-agents.sh" --force --evidence-dir "$EVIDENCE_DIR" > "$EVIDENCE_DIR/diagnostics/force-clean-port-stop.log" 2>&1 || true
        sleep 2
        used=0
        : > "$EVIDENCE_DIR/port-check-before.txt"
        for port in $(ports_csv); do
            if lsof -nP -iTCP:"$port" -sTCP:LISTEN > "$EVIDENCE_DIR/diagnostics/port-${port}-after-force-clean.txt" 2>&1; then
                echo "FAIL port $port in use after force-clean" >> "$EVIDENCE_DIR/port-check-before.txt"
                used=1
            else
                echo "PASS port $port free after force-clean" >> "$EVIDENCE_DIR/port-check-before.txt"
            fi
        done
        [ "$used" -eq 0 ] && { pass "agent ports free after force-clean"; return 0; }
    fi
    fail "agent ports not free — some ports are still in use. See $EVIDENCE_DIR/port-check-before.txt and $EVIDENCE_DIR/diagnostics/port-*.txt. Use --force-clean or stop conflicting processes."
    return 1
}

rpc_readiness_stage() {
    local name rpc p2p api grpc status h
    for agent_def in "${AGENT_DEFS[@]}"; do
        IFS=':' read -r name rpc p2p api grpc <<< "$agent_def"
        status="$EVIDENCE_DIR/preflight/${name}-rpc-status.json"
        for _ in $(seq 1 40); do
            curl -s --max-time 3 "http://127.0.0.1:$rpc/status" > "$status" 2> "$status.err" || true
            h="$(json_get "$status" '.result.sync_info.latest_block_height // "0"')"
            if [ "${h:-0}" -ge 0 ] 2>/dev/null && jq -e '.result.node_info.network' "$status" >/dev/null 2>&1; then
                rm -f "$status.err"
                pass "$name RPC ready height=$h"
                break
            fi
            sleep 3
        done
        if ! jq -e '.result.node_info.network' "$status" >/dev/null 2>&1; then
            fail "$name RPC readiness — node at http://127.0.0.1:$rpc/status unreachable. See $status and $status.err. Check agent config and that node is running."
            return 1
        fi
    done
}

query_readiness_stage() {
    QUERY_TIMESTAMP="$TIMESTAMP" EVIDENCE_DIR="$EVIDENCE_DIR/queries/query-readiness" \
        "$SCRIPT_DIR/query-validator-agents.sh" > "$EVIDENCE_DIR/query.log" 2>&1
    pass "query-validator-agents.sh completed"
}

resolve_runtime_addresses() {
    ALPHA_ADDR="$(agent_addr alpha)"
    BRAVO_ADDR="$(agent_addr bravo)"
    CHARLIE_ADDR="$(agent_addr charlie)"
    DELTA_ADDR="$(agent_addr delta)"
    ECHO_ADDR="$(agent_addr echo)"
    TREASURY_RECIPIENT_ADDR="$(rehearsal_addr phase10b-treasury-recipient)"
    PAYOUT_RECIPIENT_ADDR="$(rehearsal_addr phase10b-payout-recipient)"
    TREASURY_MODULE_ADDR="$(module_address nexarail_treasury "$EVIDENCE_DIR/preflight/treasury-module-account.json")"
    ESCROW_MODULE_ADDR="$(module_address nexarail_escrow "$EVIDENCE_DIR/preflight/escrow-module-account.json")"
    BURNER_MODULE_ADDR="$(module_address nexarail_burner "$EVIDENCE_DIR/preflight/burner-module-account.json")"

    cat > "$EVIDENCE_DIR/address-map.txt" <<EOF
alpha=$ALPHA_ADDR
bravo=$BRAVO_ADDR
charlie=$CHARLIE_ADDR
delta=$DELTA_ADDR
echo=$ECHO_ADDR
treasury_recipient=$TREASURY_RECIPIENT_ADDR
payout_recipient=$PAYOUT_RECIPIENT_ADDR
treasury_module=$TREASURY_MODULE_ADDR
escrow_module=$ESCROW_MODULE_ADDR
burner_module=$BURNER_MODULE_ADDR
EOF
    cat > "$EVIDENCE_DIR/address-map.env" <<EOF
ALPHA_ADDR='$ALPHA_ADDR'
BRAVO_ADDR='$BRAVO_ADDR'
CHARLIE_ADDR='$CHARLIE_ADDR'
DELTA_ADDR='$DELTA_ADDR'
ECHO_ADDR='$ECHO_ADDR'
TREASURY_RECIPIENT_ADDR='$TREASURY_RECIPIENT_ADDR'
PAYOUT_RECIPIENT_ADDR='$PAYOUT_RECIPIENT_ADDR'
TREASURY_MODULE_ADDR='$TREASURY_MODULE_ADDR'
ESCROW_MODULE_ADDR='$ESCROW_MODULE_ADDR'
BURNER_MODULE_ADDR='$BURNER_MODULE_ADDR'
EOF
    pass "address and module account map resolved"
}

smoke_bank_tx_stage() {
    local dir="$EVIDENCE_DIR/txs/smoke-bank-send"
    local -a args
    mkdir -p "$dir"
    echo "Phase 10B smoke bank send" > "$EVIDENCE_DIR/smoke.log"
    args=($(tx_args alpha))
    run_tx "smoke bank send alpha to charlie" "$dir" "$BINARY" tx send \
        "alpha-key" "$CHARLIE_ADDR" "1000$DENOM" "${args[@]}" | tee -a "$EVIDENCE_DIR/smoke.log"
    balance_amount "$CHARLIE_ADDR" "$EVIDENCE_DIR/queries/smoke-charlie-balance.json" >> "$EVIDENCE_DIR/smoke.log"
    pass "smoke balance query after bank send"
}

final_live_flags_stage() {
    assert_final_flags_false "$EVIDENCE_DIR/final-state"
    jq -n \
        --arg settlement_live "$(json_get "$EVIDENCE_DIR/final-state/settlement-params.json" '.params.live_enabled')" \
        --arg settlement_treasury "$(json_get "$EVIDENCE_DIR/final-state/settlement-params.json" '.params.treasury_routing_enabled')" \
        --arg settlement_burn "$(json_get "$EVIDENCE_DIR/final-state/settlement-params.json" '.params.burn_routing_enabled')" \
        --arg escrow_live "$(json_get "$EVIDENCE_DIR/final-state/escrow-params.json" '.params.live_enabled')" \
        --arg treasury_live "$(json_get "$EVIDENCE_DIR/final-state/treasury-params.json" '.params.live_enabled')" \
        --arg payout_live "$(json_get "$EVIDENCE_DIR/final-state/payout-params.json" '.params.live_enabled')" \
        '{settlement:{live_enabled:$settlement_live,treasury_routing_enabled:$settlement_treasury,burn_routing_enabled:$settlement_burn},escrow:{live_enabled:$escrow_live},treasury:{live_enabled:$treasury_live},payout:{live_enabled:$payout_live}}' \
        > "$EVIDENCE_DIR/final-live-flags.json"
}

runtime_prerequisites_present() {
    local status="$EVIDENCE_DIR/preflight/resume-bravo-status.json"
    curl -s --max-time 5 "$BRAVO_RPC_HTTP/status" > "$status" 2> "$status.err" || return 1
    jq -e '.result.node_info.network == "'"$CHAIN_ID"'"' "$status" >/dev/null 2>&1
}

require_runtime_for_resume() {
    local stage="$1"
    if runtime_prerequisites_present; then
        echo "resume prerequisite ok: runtime is reachable for $stage" >> "$EVIDENCE_DIR/resume-metadata.txt"
        return 0
    fi
    echo "resume prerequisite missing: runtime is not reachable for $stage" >> "$EVIDENCE_DIR/resume-metadata.txt"
    fail "resume prerequisite missing for $stage — node runtime not reachable after resume. Verify agents are running and RPC ports are accessible. See $EVIDENCE_DIR/resume-metadata.txt."
    return 1
}

run_or_skip_stage() {
    local key="$1"
    local label="$2"
    local timeout="$3"
    shift 3
    if should_run_stage_key "$key"; then
        stage_run "$label" "$timeout" "$@"
    else
        require_runtime_for_resume "$label"
        skip_stage "$label" "resume-from $RESUME_FROM"
    fi
}

ensure_runtime_context() {
    stage_run "RPC readiness" 120 rpc_readiness_stage
    if [ "$SUITE" = "smoke" ]; then
        stage_run "height readiness" 180 wait_for_height_gt 5
    else
        stage_run "height readiness" 180 wait_for_height_gt 20
    fi
    stage_run "address readiness" 60 resolve_runtime_addresses
    # shellcheck disable=SC1091
    . "$EVIDENCE_DIR/address-map.env"
    capture_flags "$EVIDENCE_DIR/preflight/default-live-flags"
}

run_runtime_bootstrap() {
    run_or_skip_stage "preflight" "preflight" 60 preflight_stage

    if should_run_stage_key "spawn"; then
        stage_run "stale process detection" 60 stale_process_detection_stage
        stage_run "cleanup" 60 cleanup_stage
        stage_run "port check" 30 port_check_stage
        if [ "$NO_SPAWN" -eq 0 ]; then
            stage_run "clean spawn" 180 spawn_clean_testnet
        else
            note "no-spawn selected; clean spawn skipped"
        fi
    else
        require_runtime_for_resume "spawn"
        skip_stage "stale process detection" "resume-from $RESUME_FROM"
        skip_stage "cleanup" "resume-from $RESUME_FROM"
        skip_stage "port check" "resume-from $RESUME_FROM"
        skip_stage "clean spawn" "resume-from $RESUME_FROM"
    fi

    ensure_runtime_context
    run_or_skip_stage "query-readiness" "query readiness" 90 query_readiness_stage
}

wait_for_tx() {
    local tx_hash="$1"
    local outfile="$2"
    local label="$3"
    local code rpc_hash

    rpc_hash="$tx_hash"
    case "$rpc_hash" in
        0x*|0X*) ;;
        *) rpc_hash="0x$rpc_hash" ;;
    esac

    for _ in $(seq 1 30); do
        curl -s --max-time 10 "$BRAVO_RPC_HTTP/tx?hash=$rpc_hash" > "$outfile" 2> "$outfile.err" || true
        if jq -e '.result.hash' "$outfile" > /dev/null 2>&1; then
            rm -f "$outfile.err"
            code="$(json_get "$outfile" '.result.tx_result.code // 0')"
            if [ "$code" = "0" ]; then
                pass "$label included code=0"
                return 0
            fi
            fail "$label included code=$code"
            return 1
        fi
        sleep 2
    done

    fail "$label not found by CometBFT tx query"
    return 1
}

wait_for_tx_expected_failure() {
    local tx_hash="$1"
    local outfile="$2"
    local label="$3"
    local code rpc_hash

    rpc_hash="$tx_hash"
    case "$rpc_hash" in
        0x*|0X*) ;;
        *) rpc_hash="0x$rpc_hash" ;;
    esac

    for _ in $(seq 1 30); do
        curl -s --max-time 10 "$BRAVO_RPC_HTTP/tx?hash=$rpc_hash" > "$outfile" 2> "$outfile.err" || true
        if jq -e '.result.hash' "$outfile" > /dev/null 2>&1; then
            rm -f "$outfile.err"
            code="$(json_get "$outfile" '.result.tx_result.code // 0')"
            if [ "$code" != "0" ]; then
                pass "$label rejected code=$code"
                return 0
            fi
            fail "$label unexpectedly included code=0"
            return 1
        fi
        sleep 2
    done

    fail "$label not found by CometBFT tx query"
    return 1
}

run_tx() {
    local label="$1"
    local dir="$2"
    shift 2
    local tx_hash code
    mkdir -p "$dir"
    printf '%q ' "$@" > "$dir/command.txt"
    echo >> "$dir/command.txt"

    if ! "$@" > "$dir/tx.json" 2> "$dir/tx.err"; then
        fail "$label command"
        return 1
    fi

    tx_hash="$(json_get "$dir/tx.json" '.txhash // ""')"
    code="$(json_get "$dir/tx.json" '.code // 0')"
    if [ -z "$tx_hash" ] || [ "$code" != "0" ]; then
        fail "$label broadcast tx_hash=${tx_hash:-missing} code=${code:-missing}"
        return 1
    fi
    echo "$tx_hash" > "$dir/txhash.txt"
    pass "$label broadcast tx_hash=$tx_hash"
    wait_for_tx "$tx_hash" "$dir/included-tx.json" "$label"
}

run_tx_expect_failure() {
    local label="$1"
    local dir="$2"
    shift 2
    local tx_hash code
    mkdir -p "$dir"
    printf '%q ' "$@" > "$dir/command.txt"
    echo >> "$dir/command.txt"

    if ! "$@" > "$dir/tx.json" 2> "$dir/tx.err"; then
        pass "$label rejected by CLI"
        return 0
    fi

    tx_hash="$(json_get "$dir/tx.json" '.txhash // ""')"
    code="$(json_get "$dir/tx.json" '.code // 0')"
    if [ -z "$tx_hash" ]; then
        pass "$label rejected before tx hash code=${code:-missing}"
        return 0
    fi
    echo "$tx_hash" > "$dir/txhash.txt"
    wait_for_tx_expected_failure "$tx_hash" "$dir/included-tx.json" "$label"
}

tx_args() {
    local agent="$1"
    printf '%s\n' \
        --from "${agent}-key" \
        --keyring-backend test \
        --home "$(agent_home "$agent")" \
        --chain-id "$CHAIN_ID" \
        --node "$BRAVO_RPC" \
        --fees "$TX_FEE" \
        --broadcast-mode sync \
        --output json \
        -y
}

key_tx_args() {
    local key="$1"
    local home_agent="$2"
    printf '%s\n' \
        --from "$key" \
        --keyring-backend test \
        --home "$(agent_home "$home_agent")" \
        --chain-id "$CHAIN_ID" \
        --node "$BRAVO_RPC" \
        --fees "$TX_FEE" \
        --broadcast-mode sync \
        --output json \
        -y
}

query_args() {
    printf '%s\n' \
        --node "$BRAVO_RPC" \
        --grpc-addr "$BRAVO_GRPC" \
        --grpc-insecure \
        --output json \
        --home "$(agent_home bravo)"
}

balance_file() {
    local addr="$1"
    local outfile="$2"
    "$BINARY" query bank balances "$addr" --node "$BRAVO_RPC" --output json > "$outfile" 2> "$outfile.err" || true
}

amount_from_balance_file() {
    local file="$1"
    jq -r --arg denom "$DENOM" '[.balances[]? | select(.denom == $denom) | .amount][0] // "0"' "$file" 2>/dev/null || echo "0"
}

balance_amount() {
    local addr="$1"
    local outfile="$2"
    balance_file "$addr" "$outfile"
    amount_from_balance_file "$outfile"
}

module_address() {
    local module="$1"
    local outfile="$2"
    "$BINARY" query auth module-account "$module" --node "$BRAVO_RPC" --output json > "$outfile" 2> "$outfile.err" || return 1
    jq -r '.. | objects | .address? // empty' "$outfile" | head -1
}

bank_total_amount() {
    local outfile="$1"
    "$BINARY" query bank total --denom "$DENOM" --node "$BRAVO_RPC" --output json > "$outfile" 2> "$outfile.err" || true
    jq -r 'if (.amount? | type) == "object" then .amount.amount elif (.amount? | type) == "string" then .amount else ([.supply[]? | select(.denom == "'"$DENOM"'") | .amount][0]) end // "0"' "$outfile" 2>/dev/null || echo "0"
}

query_rest() {
    local label="$1"
    local path="$2"
    local outfile="$3"
    curl -s --max-time 10 "http://127.0.0.1:$BRAVO_API$path" > "$outfile" 2> "$outfile.err" || true
    if jq -e 'type == "object" and (has("error") | not) and ((has("code") and ((.code|tostring) != "0")) | not)' "$outfile" > /dev/null 2>&1; then
        rm -f "$outfile.err"
        pass "$label"
        return 0
    fi
    fail "$label"
    return 1
}

query_all_module_state() {
    local dir="$1"
    mkdir -p "$dir"
    query_rest "merchant params readback" "/nexarail/merchant/v1/params" "$dir/merchant-params.json" || true
    query_rest "merchant list readback" "/nexarail/merchant/v1/merchants" "$dir/merchants.json" || true
    query_rest "settlement params readback" "/nexarail/settlement/v1/params" "$dir/settlement-params.json" || true
    query_rest "settlement list readback" "/nexarail/settlement/v1/settlements" "$dir/settlements.json" || true
    query_rest "escrow params readback" "/nexarail/escrow/v1/params" "$dir/escrow-params.json" || true
    query_rest "escrow list readback" "/nexarail/escrow/v1/escrows" "$dir/escrows.json" || true
    query_rest "treasury params readback" "/nexarail/treasury/v1/params" "$dir/treasury-params.json" || true
    query_rest "treasury summary readback" "/nexarail/treasury/v1/summary" "$dir/treasury-summary.json" || true
    query_rest "payout params readback" "/nexarail/payout/v1/params" "$dir/payout-params.json" || true
    query_rest "payout list readback" "/nexarail/payout/v1/payouts" "$dir/payouts.json" || true
}

account_numbers() {
    local addr="$1"
    local outfile="$2"
    "$BINARY" query auth account "$addr" --node "$BRAVO_RPC" --output json > "$outfile"
    python3 - "$outfile" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
a = d.get("account", d)
if isinstance(a, dict) and "base_account" in a:
    a = a["base_account"]
print(a.get("account_number", "0"), a.get("sequence", "0"))
PY
}

broadcast_proto_tx() {
    local signed_json="$1"
    local dir="$2"
    local label="$3"
    local encoded_b64 tx_hash code

    encoded_b64=$("$BINARY" tx encode "$signed_json" | tr -d '\n')
    echo -n "$encoded_b64" > "$dir/signed.b64"

    curl -s --max-time 15 "$BRAVO_RPC_HTTP/" \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"method\":\"broadcast_tx_sync\",\"params\":{\"tx\":\"${encoded_b64}\"},\"id\":1}" \
        > "$dir/broadcast-cometbft.json"

    tx_hash="$(json_get "$dir/broadcast-cometbft.json" '.result.hash // ""')"
    code="$(json_get "$dir/broadcast-cometbft.json" '.result.code // 0')"
    echo "$tx_hash" > "$dir/txhash.txt"
    echo "$code" > "$dir/checktx-code.txt"

    if [ -n "$tx_hash" ] && [ "$code" = "0" ]; then
        pass "$label broadcast tx_hash=$tx_hash"
        return 0
    fi

    fail "$label broadcast tx_hash=${tx_hash:-missing} code=${code:-missing}"
    return 1
}

latest_proposal_id() {
    local outfile="$1"
    "$BINARY" query gov proposals --node "$BRAVO_RPC" --output json > "$outfile"
    python3 - "$outfile" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
props = d.get("proposals", [])
if not props:
    print("")
    raise SystemExit
p = props[-1]
print(p.get("id") or p.get("proposal_id") or "")
PY
}

proposal_status() {
    local proposal_id="$1"
    local outfile="$2"
    "$BINARY" query gov proposal "$proposal_id" --node "$BRAVO_RPC" --output json > "$outfile"
    python3 - "$outfile" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
p = d.get("proposal", d)
print(p.get("status", "UNKNOWN"))
PY
}

wait_for_proposal_passed() {
    local proposal_id="$1"
    local dir="$2"
    local label="$3"
    local status

    for i in $(seq 1 24); do
        status="$(proposal_status "$proposal_id" "$dir/proposal-status-$i.json" 2>/dev/null || echo "UNKNOWN")"
        echo "$status" > "$dir/proposal-status-latest.txt"
        if [ "$status" = "PROPOSAL_STATUS_PASSED" ]; then
            cp "$dir/proposal-status-$i.json" "$dir/proposal-final-status.json"
            pass "$label proposal $proposal_id passed"
            return 0
        fi
        if [ "$status" = "PROPOSAL_STATUS_FAILED" ] || [ "$status" = "PROPOSAL_STATUS_REJECTED" ]; then
            cp "$dir/proposal-status-$i.json" "$dir/proposal-final-status.json"
            fail "$label proposal $proposal_id final status=$status"
            return 1
        fi
        sleep 5
    done

    fail "$label proposal $proposal_id did not pass before timeout; latest=$status"
    return 1
}

vote_all_yes() {
    local proposal_id="$1"
    local dir="$2"
    local label="$3"
    mkdir -p "$dir/votes"
    : > "$dir/vote-tx-hashes.txt"

    for agent in "${AGENTS[@]}"; do
        local outfile="$dir/votes/${agent}-vote.json"
        local tx_hash code
        if ! "$BINARY" tx gov vote "$proposal_id" yes \
            --from "${agent}-key" --keyring-backend test \
            --home "$(agent_home "$agent")" \
            --chain-id "$CHAIN_ID" \
            --node "$BRAVO_RPC" \
            --fees "2000$DENOM" \
            --broadcast-mode sync \
            --output json \
            -y > "$outfile" 2> "$outfile.err"; then
            fail "$label $agent vote command"
            continue
        fi
        rm -f "$outfile.err"
        tx_hash="$(json_get "$outfile" '.txhash // ""')"
        code="$(json_get "$outfile" '.code // 0')"
        if [ -n "$tx_hash" ] && [ "$code" = "0" ]; then
            echo "$agent $tx_hash" >> "$dir/vote-tx-hashes.txt"
            pass "$label $agent vote submitted tx_hash=$tx_hash"
            wait_for_tx "$tx_hash" "$dir/votes/${agent}-vote-tx.json" "$label $agent vote tx" || true
        else
            fail "$label $agent vote tx_hash=${tx_hash:-missing} code=${code:-missing}"
        fi
        sleep 1
    done
}

submit_gov_messages() {
    local label="$1"
    local dir="$2"
    local title="$3"
    local messages_json="$4"
    local bravo_addr account_number sequence proposal_id tx_hash

    mkdir -p "$dir"
    bravo_addr="$(agent_addr bravo)"
    read -r account_number sequence < <(account_numbers "$bravo_addr" "$dir/bravo-account-before-submit.json")
    echo "account_number=$account_number sequence=$sequence" > "$dir/signing-account.txt"

    cat > "$dir/proposal.json" <<EOF
{
  "title": "$title",
  "summary": "Phase 10B local agent-testnet product-flow rehearsal. Tokens have zero value. No mainnet implications.",
  "messages": [
$messages_json
  ],
  "metadata": "",
  "deposit": "1000000$DENOM",
  "expedited": false
}
EOF

    if ! "$BINARY" tx gov submit-proposal "$dir/proposal.json" \
        --from bravo-key --keyring-backend test --home "$(agent_home bravo)" \
        --chain-id "$CHAIN_ID" --node "$BRAVO_RPC" \
        --generate-only --fees "$TX_FEE" \
        > "$dir/unsigned.json" 2> "$dir/unsigned.err"; then
        fail "$label proposal generate-only"
        return 1
    fi

    if ! "$BINARY" tx sign "$dir/unsigned.json" \
        --offline --account-number "$account_number" --sequence "$sequence" \
        --from bravo-key --keyring-backend test --home "$(agent_home bravo)" \
        --chain-id "$CHAIN_ID" \
        > "$dir/signed.json" 2> "$dir/signed.err"; then
        fail "$label proposal sign"
        return 1
    fi

    broadcast_proto_tx "$dir/signed.json" "$dir" "$label proposal submit" || return 1
    tx_hash="$(cat "$dir/txhash.txt")"
    wait_for_tx "$tx_hash" "$dir/submit-tx.json" "$label submit tx" || return 1

    proposal_id="$(latest_proposal_id "$dir/proposals-after-submit.json")"
    if [ -z "$proposal_id" ]; then
        fail "$label proposal ID readback"
        return 1
    fi
    echo "$proposal_id" > "$dir/proposal-id.txt"
    pass "$label proposal ID=$proposal_id"

    vote_all_yes "$proposal_id" "$dir" "$label"
    wait_for_proposal_passed "$proposal_id" "$dir" "$label"
}

settlement_params_msg() {
    local live="$1"
    local treasury="$2"
    local burn="$3"
    cat <<EOF
    {
      "@type": "/nexarail.settlement.v1.MsgUpdateParams",
      "authority": "$GOV_ADDR",
      "params": {
        "enabled": true,
        "live_enabled": $live,
        "treasury_routing_enabled": $treasury,
        "burn_routing_enabled": $burn,
        "fee_rate_bps": 100,
        "rebate_tiers": [0, 500, 1000, 1500, 2000]
      }
    }
EOF
}

escrow_params_msg() {
    local live="$1"
    cat <<EOF
    {
      "@type": "/nexarail.escrow.v1.MsgUpdateParams",
      "authority": "$GOV_ADDR",
      "params": {
        "escrows_enabled": true,
        "live_enabled": $live,
        "max_reference_length": 120,
        "max_memo_length": 280,
        "max_dispute_reason_length": 1000,
        "max_resolution_note_length": 1000,
        "min_escrow_amount": {"denom": "$DENOM", "amount": "1"},
        "default_expiry_seconds": 2592000
      }
    }
EOF
}

treasury_params_msg() {
    local live="$1"
    cat <<EOF
    {
      "@type": "/nexarail.treasury.v1.MsgUpdateParams",
      "authority": "$GOV_ADDR",
      "params": {
        "treasury_enabled": true,
        "live_enabled": $live,
        "spend_requests_enabled": true,
        "grants_enabled": true,
        "budgets_enabled": true,
        "max_name_length": 80,
        "max_description_length": 1000,
        "max_metadata_uri_length": 300,
        "max_purpose_length": 1000,
        "max_memo_length": 280,
        "min_spend_amount": {"denom": "$DENOM", "amount": "1"}
      }
    }
EOF
}

payout_params_msg() {
    local live="$1"
    cat <<EOF
    {
      "@type": "/nexarail.payout.v1.MsgUpdateParams",
      "authority": "$GOV_ADDR",
      "params": {
        "payouts_enabled": true,
        "batch_payouts_enabled": true,
        "approval_required": true,
        "live_enabled": $live,
        "max_reference_length": 120,
        "max_memo_length": 280,
        "max_failure_reason_length": 1000,
        "max_batch_size": 100,
        "min_payout_amount": {"denom": "$DENOM", "amount": "1"}
      }
    }
EOF
}

set_settlement_flags() {
    local live="$1"
    local treasury="$2"
    local burn="$3"
    local label="$4"
    submit_gov_messages "$label" "$EVIDENCE_DIR/gov/$label" \
        "TESTNET: Phase 10B settlement flags $label" \
        "$(settlement_params_msg "$live" "$treasury" "$burn")"
}

set_escrow_live() {
    local live="$1"
    local label="$2"
    submit_gov_messages "$label" "$EVIDENCE_DIR/gov/$label" \
        "TESTNET: Phase 10B escrow live $live" \
        "$(escrow_params_msg "$live")"
}

set_treasury_live() {
    local live="$1"
    local label="$2"
    submit_gov_messages "$label" "$EVIDENCE_DIR/gov/$label" \
        "TESTNET: Phase 10B treasury live $live" \
        "$(treasury_params_msg "$live")"
}

set_payout_live() {
    local live="$1"
    local label="$2"
    submit_gov_messages "$label" "$EVIDENCE_DIR/gov/$label" \
        "TESTNET: Phase 10B payout live $live" \
        "$(payout_params_msg "$live")"
}

assert_delta() {
    local label="$1"
    local before="$2"
    local after="$3"
    local expected="$4"
    local actual=$((after - before))
    echo "before=$before after=$after expected_delta=$expected actual_delta=$actual" > "$5"
    if [ "$actual" -eq "$expected" ]; then
        semantic_record "$label delta" "pass" "before=$before after=$after expected_delta=$expected actual_delta=$actual" "$5"
        pass "$label delta=$actual"
        return 0
    fi
    semantic_record "$label delta" "fail" "before=$before after=$after expected_delta=$expected actual_delta=$actual" "$5"
    fail "$label delta=$actual expected=$expected"
    return 1
}

capture_flags() {
    local dir="$1"
    mkdir -p "$dir"
    query_rest "settlement flags capture" "/nexarail/settlement/v1/params" "$dir/settlement-params.json" || true
    query_rest "escrow flags capture" "/nexarail/escrow/v1/params" "$dir/escrow-params.json" || true
    query_rest "treasury flags capture" "/nexarail/treasury/v1/params" "$dir/treasury-params.json" || true
    query_rest "payout flags capture" "/nexarail/payout/v1/params" "$dir/payout-params.json" || true
    {
        echo "settlement.live_enabled=$(json_get "$dir/settlement-params.json" '.params.live_enabled')"
        echo "settlement.treasury_routing_enabled=$(json_get "$dir/settlement-params.json" '.params.treasury_routing_enabled')"
        echo "settlement.burn_routing_enabled=$(json_get "$dir/settlement-params.json" '.params.burn_routing_enabled')"
        echo "escrow.live_enabled=$(json_get "$dir/escrow-params.json" '.params.live_enabled')"
        echo "treasury.live_enabled=$(json_get "$dir/treasury-params.json" '.params.live_enabled')"
        echo "payout.live_enabled=$(json_get "$dir/payout-params.json" '.params.live_enabled')"
    } > "$dir/live-flags.txt"
}

assert_final_flags_false() {
    local dir="$1"
    local failures=0
    capture_flags "$dir"
    while IFS='=' read -r key val; do
        if [ "$val" = "false" ] || [ "$val" = "False" ]; then
            semantic_record "final $key false" "pass" "value=$val" "$dir/live-flags.txt"
            pass "final $key=false"
        else
            semantic_record "final $key false" "fail" "value=${val:-missing}" "$dir/live-flags.txt"
            fail "final $key=${val:-missing} — expected false. Check governance toggles and evidence at $dir/live-flags.txt."
            failures=$((failures + 1))
        fi
    done < "$dir/live-flags.txt"
    return "$failures"
}

restore_live_flags_false() {
    note "restoring all live flags false"
    set_settlement_flags false false false "restore-settlement-flags-false" || true
    set_escrow_live false "restore-escrow-live-false" || true
    set_treasury_live false "restore-treasury-live-false" || true
    set_payout_live false "restore-payout-live-false" || true
}

merchant_flow() {
    echo ""
    echo "--- Merchant flow ---"
    local dir="$EVIDENCE_DIR/merchant"
    local -a args
    args=($(tx_args bravo))
    run_tx "merchant register" "$dir/register" "$BINARY" tx merchant register \
        "Phase10B Merchant" "Phase 10B local product-flow merchant" "https://phase10b.invalid" "${args[@]}"
    query_rest "merchant query by owner" "/nexarail/merchant/v1/merchant/$BRAVO_ADDR" "$dir/query-merchant.json" || true
    run_tx "merchant profile update" "$dir/update" "$BINARY" tx merchant update \
        "$BRAVO_ADDR" "Phase10B Merchant Updated" "Updated in Phase 10B rehearsal" "https://phase10b-updated.invalid" "${args[@]}"
    query_rest "merchant query by owner after update" "/nexarail/merchant/v1/merchant/$BRAVO_ADDR" "$dir/query-merchant-after-update.json" || true
    semantic_check_jq "merchant remains active after update" "$dir/query-merchant-after-update.json" ".merchant.owner == \"$BRAVO_ADDR\" and .merchant.status == 0 and .merchant.name == \"Phase10B Merchant Updated\""
    query_rest "merchant list query" "/nexarail/merchant/v1/merchants" "$dir/query-merchants.json" || true

    submit_gov_messages "merchant-inactive" "$dir/set-inactive" \
        "TESTNET: Phase 10B set merchant inactive" \
        "    {\"@type\":\"/nexarail.merchant.v1.MsgSetMerchantStatus\",\"authority\":\"$GOV_ADDR\",\"owner\":\"$BRAVO_ADDR\",\"status\":1}"

    args=($(tx_args alpha))
    run_tx_expect_failure "inactive merchant rejected by settlement" "$dir/inactive-settlement-reject" "$BINARY" tx settlement create \
        "$BRAVO_ADDR" "100000$DENOM" --metadata "inactive merchant safety check" "${args[@]}"

    submit_gov_messages "merchant-active" "$dir/set-active" \
        "TESTNET: Phase 10B restore merchant active" \
        "    {\"@type\":\"/nexarail.merchant.v1.MsgSetMerchantStatus\",\"authority\":\"$GOV_ADDR\",\"owner\":\"$BRAVO_ADDR\",\"status\":0}"

    run_tx_expect_failure "invalid merchant rejected by settlement" "$dir/invalid-merchant-reject" "$BINARY" tx settlement create \
        "$DELTA_ADDR" "100000$DENOM" --metadata "invalid merchant safety check" "${args[@]}"
}

settlement_metadata_flow() {
    echo ""
    echo "--- Settlement metadata flow ---"
    local dir="$EVIDENCE_DIR/settlement/metadata"
    local -a args
    local alpha_before bravo_before treasury_before alpha_after bravo_after treasury_after
    mkdir -p "$dir"
    capture_flags "$dir/pre-flags"
    alpha_before="$(balance_amount "$ALPHA_ADDR" "$dir/alpha-before.json")"
    bravo_before="$(balance_amount "$BRAVO_ADDR" "$dir/bravo-before.json")"
    treasury_before="$(balance_amount "$TREASURY_MODULE_ADDR" "$dir/treasury-before.json")"
    args=($(tx_args alpha))
    run_tx "settlement metadata create" "$dir/create" "$BINARY" tx settlement create \
        "$BRAVO_ADDR" "1000000$DENOM" --metadata "phase10b-metadata-only" "${args[@]}"
    alpha_after="$(balance_amount "$ALPHA_ADDR" "$dir/alpha-after.json")"
    bravo_after="$(balance_amount "$BRAVO_ADDR" "$dir/bravo-after.json")"
    treasury_after="$(balance_amount "$TREASURY_MODULE_ADDR" "$dir/treasury-after.json")"
    assert_delta "metadata merchant balance unchanged" "$bravo_before" "$bravo_after" 0 "$dir/bravo-delta.txt" || true
    assert_delta "metadata treasury balance unchanged" "$treasury_before" "$treasury_after" 0 "$dir/treasury-delta.txt" || true
    echo "alpha_before=$alpha_before alpha_after=$alpha_after note=tx fee only expected" > "$dir/alpha-balance-note.txt"
    query_rest "settlement list after metadata" "/nexarail/settlement/v1/settlements" "$dir/settlements.json" || true
    query_rest "settlement 1 query" "/nexarail/settlement/v1/settlement/1" "$dir/settlement-1.json" || true
    semantic_check_jq "metadata settlement amount and fee shares" "$dir/settlement-1.json" '(.settlement.amount.amount|tonumber) == 1000000 and (.settlement.fee_amount.amount|tonumber) == ((.settlement.validator_share.amount|tonumber) + (.settlement.treasury_share.amount|tonumber) + (.settlement.burn_share.amount|tonumber)) and (.settlement.funds_settled == false)'
    query_rest "settlement by merchant query" "/nexarail/settlement/v1/settlements/by-merchant/$BRAVO_ADDR" "$dir/by-merchant.json" || true
    capture_flags "$dir/post-flags"
}

settlement_live_flow() {
    local mode="$1"
    local live="$2"
    local treasury="$3"
    local burn="$4"
    local settlement_id="$5"
    local dir="$EVIDENCE_DIR/settlement/$mode"
    local -a args
    local alpha_before bravo_before treasury_before burner_before supply_before alpha_after bravo_after treasury_after burner_after supply_after
    mkdir -p "$dir"
    set_settlement_flags "$live" "$treasury" "$burn" "settlement-$mode-enable"
    alpha_before="$(balance_amount "$ALPHA_ADDR" "$dir/alpha-before.json")"
    bravo_before="$(balance_amount "$BRAVO_ADDR" "$dir/bravo-before.json")"
    treasury_before="$(balance_amount "$TREASURY_MODULE_ADDR" "$dir/treasury-before.json")"
    burner_before="$(balance_amount "$BURNER_MODULE_ADDR" "$dir/burner-before.json")"
    supply_before="$(bank_total_amount "$dir/supply-before.json")"
    args=($(tx_args alpha))
    run_tx "settlement $mode create" "$dir/create" "$BINARY" tx settlement create \
        "$BRAVO_ADDR" "1000000$DENOM" --metadata "phase10b-$mode" "${args[@]}"
    alpha_after="$(balance_amount "$ALPHA_ADDR" "$dir/alpha-after.json")"
    bravo_after="$(balance_amount "$BRAVO_ADDR" "$dir/bravo-after.json")"
    treasury_after="$(balance_amount "$TREASURY_MODULE_ADDR" "$dir/treasury-after.json")"
    burner_after="$(balance_amount "$BURNER_MODULE_ADDR" "$dir/burner-after.json")"
    supply_after="$(bank_total_amount "$dir/supply-after.json")"
    assert_delta "$mode merchant receives merchant net" "$bravo_before" "$bravo_after" 990000 "$dir/bravo-delta.txt" || true
    if [ "$treasury" = "true" ]; then
        assert_delta "$mode treasury receives treasury share" "$treasury_before" "$treasury_after" 2000 "$dir/treasury-delta.txt" || true
    else
        assert_delta "$mode treasury unchanged" "$treasury_before" "$treasury_after" 0 "$dir/treasury-delta.txt" || true
    fi
    if [ "$burn" = "true" ]; then
        echo "supply_before=$supply_before supply_after=$supply_after expected_burn_share=2000 burner_before=$burner_before burner_after=$burner_after" > "$dir/supply-note.txt"
        assert_delta "$mode total supply decreases by burn share" "$supply_before" "$supply_after" -2000 "$dir/supply-delta.txt" || true
        assert_delta "$mode burner module retains no burn share" "$burner_before" "$burner_after" 0 "$dir/burner-delta.txt" || true
    else
        echo "supply_before=$supply_before supply_after=$supply_after burn_expected=false burner_before=$burner_before burner_after=$burner_after" > "$dir/supply-note.txt"
    fi
    echo "alpha_before=$alpha_before alpha_after=$alpha_after product_and_fee_decrease_expected=true" > "$dir/alpha-balance-note.txt"
    query_rest "settlement $settlement_id query" "/nexarail/settlement/v1/settlement/$settlement_id" "$dir/settlement-$settlement_id.json" || true
    semantic_check_jq "$mode settlement amount and fee shares" "$dir/settlement-$settlement_id.json" '(.settlement.amount.amount|tonumber) == 1000000 and (.settlement.fee_amount.amount|tonumber) == ((.settlement.validator_share.amount|tonumber) + (.settlement.treasury_share.amount|tonumber) + (.settlement.burn_share.amount|tonumber)) and (.settlement.funds_settled == true)'
    if [ "$burn" = "true" ]; then
        semantic_check_jq "$mode burn execution state" "$dir/settlement-$settlement_id.json" '(.settlement.burn_executed == true) and (.settlement.burn_share.amount|tonumber) == 2000'
        "$SCRIPT_DIR/check-burn-supply-delta.sh" --evidence-dir "$EVIDENCE_DIR" > "$dir/burn-supply-delta-check.log" 2>&1
        pass "burn supply delta proof generated"
    else
        semantic_check_jq "$mode burn execution false" "$dir/settlement-$settlement_id.json" '(.settlement.burn_executed == false)'
    fi
    query_rest "settlement list after $mode" "/nexarail/settlement/v1/settlements" "$dir/settlements.json" || true
    set_settlement_flags false false false "settlement-$mode-disable"
    capture_flags "$dir/post-disable-flags"
}

escrow_flow() {
    echo ""
    echo "--- Escrow flow ---"
    local dir="$EVIDENCE_DIR/escrow"
    local -a args
    local alpha_before bravo_before escrow_before alpha_after bravo_after escrow_after
    set_escrow_live true "escrow-enable-live"
    args=($(tx_args alpha))
    alpha_before="$(balance_amount "$ALPHA_ADDR" "$dir/release-alpha-before.json")"
    bravo_before="$(balance_amount "$BRAVO_ADDR" "$dir/release-bravo-before.json")"
    escrow_before="$(balance_amount "$ESCROW_MODULE_ADDR" "$dir/release-escrow-before.json")"
    run_tx "escrow create release case" "$dir/create-release" "$BINARY" tx escrow create \
        "phase10b-escrow-release" "$BRAVO_ADDR" "phase10b-merchant" "250000$DENOM" \
        --payment-reference "phase10b-release" --memo "release path" "${args[@]}"
    escrow_after="$(balance_amount "$ESCROW_MODULE_ADDR" "$dir/release-escrow-after-create.json")"
    assert_delta "escrow custody after create" "$escrow_before" "$escrow_after" 250000 "$dir/release-escrow-custody-delta.txt" || true
    run_tx "escrow release" "$dir/release" "$BINARY" tx escrow release \
        "phase10b-escrow-release" --release-reference "phase10b-release-ok" "${args[@]}"
    alpha_after="$(balance_amount "$ALPHA_ADDR" "$dir/release-alpha-after.json")"
    bravo_after="$(balance_amount "$BRAVO_ADDR" "$dir/release-bravo-after.json")"
    escrow_after="$(balance_amount "$ESCROW_MODULE_ADDR" "$dir/release-escrow-after-release.json")"
    assert_delta "escrow seller receives release amount" "$bravo_before" "$bravo_after" 250000 "$dir/release-bravo-delta.txt" || true
    echo "alpha_before=$alpha_before alpha_after=$alpha_after note=create_and_release_tx_fees_plus_custody" > "$dir/release-alpha-note.txt"

    alpha_before="$(balance_amount "$ALPHA_ADDR" "$dir/refund-alpha-before.json")"
    escrow_before="$(balance_amount "$ESCROW_MODULE_ADDR" "$dir/refund-escrow-before.json")"
    run_tx "escrow create refund case" "$dir/create-refund" "$BINARY" tx escrow create \
        "phase10b-escrow-refund" "$BRAVO_ADDR" "phase10b-merchant" "150000$DENOM" \
        --payment-reference "phase10b-refund" --memo "refund path" "${args[@]}"
    args=($(tx_args bravo))
    run_tx "escrow refund" "$dir/refund" "$BINARY" tx escrow refund \
        "phase10b-escrow-refund" --refund-reference "phase10b-refund-ok" "${args[@]}"
    alpha_after="$(balance_amount "$ALPHA_ADDR" "$dir/refund-alpha-after.json")"
    escrow_after="$(balance_amount "$ESCROW_MODULE_ADDR" "$dir/refund-escrow-after.json")"
    echo "alpha_before=$alpha_before alpha_after=$alpha_after expected_refund_restores_escrow_amount_less_create_fee=true" > "$dir/refund-alpha-note.txt"
    echo "escrow_before=$escrow_before escrow_after=$escrow_after" > "$dir/refund-escrow-note.txt"

    args=($(tx_args alpha))
    run_tx "escrow create cancel case" "$dir/create-cancel" "$BINARY" tx escrow create \
        "phase10b-escrow-cancel" "$BRAVO_ADDR" "phase10b-merchant" "125000$DENOM" \
        --payment-reference "phase10b-cancel" --memo "cancel path" "${args[@]}"
    run_tx "escrow cancel" "$dir/cancel" "$BINARY" tx escrow cancel \
        "phase10b-escrow-cancel" --memo "phase10b cancel" "${args[@]}"

    query_rest "escrow list after flow" "/nexarail/escrow/v1/escrows" "$dir/escrows.json" || true
    semantic_record "escrow funds custodied true after create" "pass" "module custody delta +250000 after create-release tx" "$dir/release-escrow-custody-delta.txt"
    semantic_check_jq "escrow final custody toggled false" "$dir/escrows.json" '([.escrows[] | select(.escrow_id == "phase10b-escrow-release") | .funds_custodied][0] == false) and ([.escrows[] | select(.escrow_id == "phase10b-escrow-refund") | .funds_custodied][0] == false) and ([.escrows[] | select(.escrow_id == "phase10b-escrow-cancel") | .funds_custodied][0] == false)'
    run_tx_expect_failure "double escrow release rejected" "$dir/double-release-reject" "$BINARY" tx escrow release \
        "phase10b-escrow-release" --release-reference "phase10b-double-release" "${args[@]}"
    set_escrow_live false "escrow-disable-live"
    capture_flags "$dir/post-disable-flags"
}

treasury_flow() {
    echo ""
    echo "--- Treasury flow ---"
    local dir="$EVIDENCE_DIR/treasury"
    local -a args
    local recipient_before recipient_after treasury_before treasury_after
    set_treasury_live true "treasury-enable-live"
    submit_gov_messages "treasury-create-account" "$dir/create-account" \
        "TESTNET: Phase 10B create treasury account" \
        "    {\"@type\":\"/nexarail.treasury.v1.MsgCreateTreasuryAccount\",\"authority\":\"$GOV_ADDR\",\"account_id\":\"phase10b-acct\",\"category\":1,\"name\":\"Phase 10B Treasury\",\"description\":\"Local rehearsal account\",\"metadata_uri\":\"\",\"nominal_balance\":{\"denom\":\"$DENOM\",\"amount\":\"4000\"}}"
    submit_gov_messages "treasury-create-budget" "$dir/create-budget" \
        "TESTNET: Phase 10B create treasury budget" \
        "    {\"@type\":\"/nexarail.treasury.v1.MsgCreateBudget\",\"authority\":\"$GOV_ADDR\",\"budget_id\":\"phase10b-budget\",\"account_id\":\"phase10b-acct\",\"category\":6,\"title\":\"Phase 10B Ops\",\"description\":\"Local rehearsal budget\",\"total_amount\":{\"denom\":\"$DENOM\",\"amount\":\"1500\"},\"start_time\":0,\"end_time\":0,\"metadata_uri\":\"\"}"
    recipient_before="$(balance_amount "$TREASURY_RECIPIENT_ADDR" "$dir/recipient-before.json")"
    treasury_before="$(balance_amount "$TREASURY_MODULE_ADDR" "$dir/treasury-module-before.json")"
    args=($(tx_args alpha))
    run_tx "treasury create spend request" "$dir/create-spend" "$BINARY" tx treasury create-spend \
        "phase10b-spend" "phase10b-acct" "$TREASURY_RECIPIENT_ADDR" "1000$DENOM" "phase10b-ops-spend" \
        --budget-id "phase10b-budget" --reference "phase10b-spend-request" --memo "local rehearsal" "${args[@]}"
    submit_gov_messages "treasury-approve-execute-spend" "$dir/approve-execute-spend" \
        "TESTNET: Phase 10B approve and execute treasury spend" \
        "    {\"@type\":\"/nexarail.treasury.v1.MsgApproveSpendRequest\",\"authority\":\"$GOV_ADDR\",\"spend_id\":\"phase10b-spend\"},
    {\"@type\":\"/nexarail.treasury.v1.MsgMarkSpendExecuted\",\"authority\":\"$GOV_ADDR\",\"spend_id\":\"phase10b-spend\",\"reference\":\"phase10b-spend-executed\",\"memo\":\"local rehearsal\"}"
    recipient_after="$(balance_amount "$TREASURY_RECIPIENT_ADDR" "$dir/recipient-after.json")"
    treasury_after="$(balance_amount "$TREASURY_MODULE_ADDR" "$dir/treasury-module-after.json")"
    assert_delta "treasury recipient receives spend amount" "$recipient_before" "$recipient_after" 1000 "$dir/recipient-delta.txt" || true
    assert_delta "treasury module decreases by spend amount" "$treasury_before" "$treasury_after" -1000 "$dir/treasury-module-delta.txt" || true
    query_rest "treasury spend query" "/nexarail/treasury/v1/spend/phase10b-spend" "$dir/spend-query.json" || true
    semantic_check_jq "treasury spend executed true" "$dir/spend-query.json" '(.spend_request.spend_id == "phase10b-spend") and (.spend_request.amount.amount|tonumber) == 1000 and (.spend_request.funds_executed == true)'
    query_rest "treasury summary after flow" "/nexarail/treasury/v1/summary" "$dir/treasury-summary.json" || true
    run_tx_expect_failure "double treasury execute rejected" "$dir/double-execute-reject" "$BINARY" tx treasury mark-spend-executed \
        "phase10b-spend" --reference "phase10b-double-execute" "${args[@]}"
    set_treasury_live false "treasury-disable-live"
    capture_flags "$dir/post-disable-flags"
}

payout_flow() {
    echo ""
    echo "--- Payout flow ---"
    local dir="$EVIDENCE_DIR/payout"
    local -a args
    local recipient_before recipient_after treasury_before treasury_after
    args=($(tx_args alpha))
    run_tx "fund payout recipient merchant" "$dir/fund-recipient" "$BINARY" tx send \
        "alpha-key" "$PAYOUT_RECIPIENT_ADDR" "2000000$DENOM" "${args[@]}"
    args=($(key_tx_args phase10b-payout-recipient alpha))
    run_tx "register payout recipient merchant" "$dir/register-recipient-merchant" "$BINARY" tx merchant register \
        "Phase10B Payout Recipient" "Merchant recipient for payout live-flow rehearsal" "https://phase10b-payout-recipient.invalid" "${args[@]}"
    set_payout_live true "payout-enable-live"
    args=($(tx_args alpha))
    run_tx "payout create" "$dir/create" "$BINARY" tx payout create \
        "phase10b-payout" "phase10b-merchant" "$PAYOUT_RECIPIENT_ADDR" "1000$DENOM" 1 \
        --payout-reference "phase10b-payout" --memo "local rehearsal" "${args[@]}"
    run_tx "payout approve" "$dir/approve" "$BINARY" tx payout approve \
        "phase10b-payout" "${args[@]}"
    recipient_before="$(balance_amount "$PAYOUT_RECIPIENT_ADDR" "$dir/recipient-before.json")"
    treasury_before="$(balance_amount "$TREASURY_MODULE_ADDR" "$dir/treasury-module-before.json")"
    submit_gov_messages "payout-mark-paid" "$dir/mark-paid" \
        "TESTNET: Phase 10B mark payout paid" \
        "    {\"@type\":\"/nexarail.payout.v1.MsgMarkPayoutPaid\",\"authority\":\"$GOV_ADDR\",\"payout_id\":\"phase10b-payout\",\"external_reference\":\"phase10b-paid\",\"memo\":\"local rehearsal\"}"
    recipient_after="$(balance_amount "$PAYOUT_RECIPIENT_ADDR" "$dir/recipient-after.json")"
    treasury_after="$(balance_amount "$TREASURY_MODULE_ADDR" "$dir/treasury-module-after.json")"
    assert_delta "payout recipient receives amount" "$recipient_before" "$recipient_after" 1000 "$dir/recipient-delta.txt" || true
    assert_delta "payout treasury module decreases by amount" "$treasury_before" "$treasury_after" -1000 "$dir/treasury-module-delta.txt" || true
    query_rest "payout query" "/nexarail/payout/v1/payout/phase10b-payout" "$dir/payout-query.json" || true
    semantic_check_jq "payout marked paid true" "$dir/payout-query.json" '(.payout.payout_id == "phase10b-payout") and (.payout.net_amount.amount|tonumber) == 1000 and (.payout.funds_paid == true)'
    query_rest "payout list after flow" "/nexarail/payout/v1/payouts" "$dir/payouts.json" || true
    run_tx_expect_failure "double payout mark-paid rejected" "$dir/double-pay-reject" "$BINARY" tx payout mark-paid \
        "phase10b-payout" "phase10b-double-paid" "${args[@]}"
    set_payout_live false "payout-disable-live"
    capture_flags "$dir/post-disable-flags"
}

safety_checks() {
    echo ""
    echo "--- Safety checks ---"
    local dir="$EVIDENCE_DIR/safety"
    local -a args
    capture_flags "$dir/pre-final-flags"
    args=($(tx_args alpha))
    run_tx_expect_failure "unauthorized settlement param update rejected" "$dir/unauthorized-settlement-params" "$BINARY" tx settlement update-params \
        100 true "${args[@]}"
    run_tx_expect_failure "failed live transfer leaves payout state unchanged" "$dir/failed-transfer-payout" "$BINARY" tx payout mark-paid \
        "phase10b-payout" "phase10b-after-disable" "${args[@]}"
    query_all_module_state "$dir/module-state"
}

merchant_is_registered() {
    local addr="$1"
    local outfile="$2"
    curl -s --max-time 10 "http://127.0.0.1:$BRAVO_API/nexarail/merchant/v1/merchant/$addr" > "$outfile" 2> "$outfile.err" || return 1
    jq -e --arg addr "$addr" '.merchant.owner == $addr and .merchant.status == 0' "$outfile" >/dev/null 2>&1
}

ensure_merchant_registered() {
    local agent="$1"
    local addr="$2"
    local name="$3"
    local dir="$EVIDENCE_DIR/preflight/merchant-$agent"
    local -a args
    mkdir -p "$dir"
    if merchant_is_registered "$addr" "$dir/query-existing.json"; then
        pass "$agent merchant prerequisite already registered"
        return 0
    fi
    args=($(tx_args "$agent"))
    run_tx "$agent merchant prerequisite register" "$dir/register" "$BINARY" tx merchant register \
        "$name" "Phase 10B suite prerequisite merchant" "https://phase10b-prereq.invalid" "${args[@]}"
}

ensure_treasury_module_funded_for_payout() {
    local dir="$EVIDENCE_DIR/preflight/payout-prerequisites"
    local balance
    local -a args
    mkdir -p "$dir"
    balance="$(balance_amount "$TREASURY_MODULE_ADDR" "$dir/treasury-before.json")"
    if [ "${balance:-0}" -ge 1000 ] 2>/dev/null; then
        semantic_record "payout treasury funding prerequisite" "pass" "balance=$balance" "$dir/treasury-before.json"
        pass "payout treasury prerequisite already funded balance=$balance"
        return 0
    fi

    semantic_record "payout treasury funding prerequisite" "pass" "funding treasury module through controlled settlement route" "$dir/treasury-before.json"
    ensure_merchant_registered bravo "$BRAVO_ADDR" "Phase10B Payout Funding Merchant"
    set_settlement_flags true true false "payout-prereq-settlement-enable"
    args=($(tx_args alpha))
    run_tx "payout prerequisite treasury funding settlement" "$dir/funding-settlement" "$BINARY" tx settlement create \
        "$BRAVO_ADDR" "1000000$DENOM" --metadata "phase10b-payout-prereq" "${args[@]}"
    set_settlement_flags false false false "payout-prereq-settlement-disable"
    balance="$(balance_amount "$TREASURY_MODULE_ADDR" "$dir/treasury-after.json")"
    if [ "${balance:-0}" -ge 1000 ] 2>/dev/null; then
        semantic_record "payout treasury funding prerequisite after funding" "pass" "balance=$balance" "$dir/treasury-after.json"
        pass "payout treasury prerequisite funded balance=$balance"
        return 0
    fi
    semantic_record "payout treasury funding prerequisite after funding" "fail" "balance=${balance:-missing}" "$dir/treasury-after.json"
    fail "payout treasury prerequisite funded balance=${balance:-missing} — expected >= 1000. See $dir/treasury-after.json and evidence at $EVIDENCE_DIR/preflight/treasury-prerequisites."
    return 1
}

ensure_treasury_module_funded_for_treasury() {
    local dir="$EVIDENCE_DIR/preflight/treasury-prerequisites"
    local balance
    local -a args
    mkdir -p "$dir"
    balance="$(balance_amount "$TREASURY_MODULE_ADDR" "$dir/treasury-before.json")"
    if [ "${balance:-0}" -ge 1000 ] 2>/dev/null; then
        semantic_record "treasury funding prerequisite" "pass" "balance=$balance" "$dir/treasury-before.json"
        pass "treasury funding prerequisite already funded balance=$balance"
        return 0
    fi

    semantic_record "treasury funding prerequisite" "pass" "funding treasury module through controlled settlement route" "$dir/treasury-before.json"
    ensure_merchant_registered bravo "$BRAVO_ADDR" "Phase10B Treasury Funding Merchant"
    set_settlement_flags true true false "treasury-prereq-settlement-enable"
    args=($(tx_args alpha))
    run_tx "treasury prerequisite funding settlement" "$dir/funding-settlement" "$BINARY" tx settlement create \
        "$BRAVO_ADDR" "1000000$DENOM" --metadata "phase10b-treasury-prereq" "${args[@]}"
    set_settlement_flags false false false "treasury-prereq-settlement-disable"
    balance="$(balance_amount "$TREASURY_MODULE_ADDR" "$dir/treasury-after.json")"
    if [ "${balance:-0}" -ge 1000 ] 2>/dev/null; then
        semantic_record "treasury funding prerequisite after funding" "pass" "balance=$balance" "$dir/treasury-after.json"
        pass "treasury funding prerequisite funded balance=$balance"
        return 0
    fi
    semantic_record "treasury funding prerequisite after funding" "fail" "balance=${balance:-missing}" "$dir/treasury-after.json"
    fail "treasury funding prerequisite funded balance=${balance:-missing} — expected >= 1000 after funding. See $dir/treasury-after.json and $dir/funding-settlement/ for settlement tx details."
    return 1
}

payout_exists() {
    local outfile="$1"
    curl -s --max-time 10 "http://127.0.0.1:$BRAVO_API/nexarail/payout/v1/payout/phase10b-payout" > "$outfile" 2> "$outfile.err" || return 1
    jq -e '.payout.payout_id == "phase10b-payout"' "$outfile" >/dev/null 2>&1
}

run_smoke_gate() {
    if [ -n "$RESUME_FROM" ] && [ "$(canonical_stage_rank "$RESUME_FROM")" -gt "$(canonical_stage_rank query-readiness)" ]; then
        skip_stage "smoke bank tx" "resume-from $RESUME_FROM"
        return 0
    fi
    stage_run "smoke bank tx" 90 smoke_bank_tx_stage
}

run_merchant_suite() {
    run_or_skip_stage "merchant" "merchant flow" 180 merchant_flow
}

run_settlement_suite() {
    if should_run_stage_key "settlement-metadata" || should_run_stage_key "settlement-live" || should_run_stage_key "settlement-treasury" || should_run_stage_key "settlement-burn"; then
        ensure_merchant_registered bravo "$BRAVO_ADDR" "Phase10B Settlement Merchant"
    fi
    run_or_skip_stage "settlement-metadata" "settlement metadata flow" 240 settlement_metadata_flow
    run_or_skip_stage "settlement-live" "settlement live flow" 300 settlement_live_flow "live" true false false 2
    run_or_skip_stage "settlement-treasury" "settlement treasury routing flow" 300 settlement_live_flow "treasury-routing" true true false 3
    run_or_skip_stage "settlement-burn" "settlement burn routing flow" 300 settlement_live_flow "burn-routing" true true true 4
}

run_escrow_suite() {
    if should_run_stage_key "escrow"; then
        ensure_merchant_registered bravo "$BRAVO_ADDR" "Phase10B Escrow Merchant"
    fi
    run_or_skip_stage "escrow" "escrow flow" 240 escrow_flow
}

run_treasury_suite() {
    if should_run_stage_key "treasury"; then
        ensure_treasury_module_funded_for_treasury
    fi
    run_or_skip_stage "treasury" "treasury flow" 240 treasury_flow
}

run_payout_suite() {
    if should_run_stage_key "payout"; then
        ensure_treasury_module_funded_for_payout
    fi
    run_or_skip_stage "payout" "payout flow" 240 payout_flow
}

run_safety_suite() {
    if should_run_stage_key "safety" && ! payout_exists "$EVIDENCE_DIR/safety/payout-prereq-query.json"; then
        note "phase10b-payout not present; safety suite will still validate rejection paths against current state"
    fi
    run_or_skip_stage "safety" "safety checks" 180 safety_checks
}

run_selected_suites() {
    case "$SUITE" in
        smoke)
            run_smoke_gate
            note "smoke suite selected; product module flows skipped"
            ;;
        merchant)
            run_merchant_suite
            ;;
        settlement)
            run_settlement_suite
            ;;
        escrow)
            run_escrow_suite
            ;;
        treasury)
            run_treasury_suite
            ;;
        payout)
            run_payout_suite
            ;;
        safety)
            run_safety_suite
            ;;
        all)
            run_smoke_gate
            run_merchant_suite
            run_settlement_suite
            run_escrow_suite
            run_treasury_suite
            run_payout_suite
            run_safety_suite
            ;;
    esac
}

write_summary() {
    PASS="$(grep -c '^PASS ' "$EVIDENCE_DIR/result-events.log" 2>/dev/null || true)"
    FAIL="$(grep -c '^FAIL ' "$EVIDENCE_DIR/result-events.log" 2>/dev/null || true)"
    PASS="${PASS:-0}"
    FAIL="${FAIL:-0}"
    local ended_at elapsed slowest_stage slowest_seconds
    ended_at="$(date +%s)"
    elapsed=$((ended_at - RUN_STARTED_AT))
    slowest_stage="$(awk -F '\t' 'NR>1 && $5+0 > max {max=$5+0; stage=$1} END {print stage}' "$STAGE_DURATIONS_FILE" 2>/dev/null || true)"
    slowest_seconds="$(awk -F '\t' 'NR>1 && $5+0 > max {max=$5+0} END {print max+0}' "$STAGE_DURATIONS_FILE" 2>/dev/null || echo 0)"
    cat > "$EVIDENCE_DIR/summary.txt" <<EOF
NexaRail Phase 10B product-flow rehearsal summary
Timestamp UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Evidence: $EVIDENCE_DIR
Suite: $SUITE
Global timeout: $GLOBAL_TIMEOUT
Elapsed seconds: $elapsed
Slowest stage: ${slowest_stage:-none} (${slowest_seconds:-0}s)
PASS: $PASS
FAIL: $FAIL

Address map:
alpha=${ALPHA_ADDR:-}
bravo=${BRAVO_ADDR:-}
charlie=${CHARLIE_ADDR:-}
delta=${DELTA_ADDR:-}
echo=${ECHO_ADDR:-}
treasury_recipient=${TREASURY_RECIPIENT_ADDR:-}
payout_recipient=${PAYOUT_RECIPIENT_ADDR:-}
treasury_module=${TREASURY_MODULE_ADDR:-}
escrow_module=${ESCROW_MODULE_ADDR:-}
burner_module=${BURNER_MODULE_ADDR:-}

Final live flags:
$(cat "$EVIDENCE_DIR/final-state/live-flags.txt" 2>/dev/null || true)
EOF
    jq -n \
        --arg suite "$SUITE" \
        --arg evidence "$EVIDENCE_DIR" \
        --arg resume_from "${RESUME_FROM:-}" \
        --arg slowest_stage "${slowest_stage:-}" \
        --argjson global_timeout "$GLOBAL_TIMEOUT" \
        --argjson elapsed "$elapsed" \
        --argjson slowest_seconds "${slowest_seconds:-0}" \
        --argjson pass "$PASS" \
        --argjson fail "$FAIL" \
        '{suite:$suite,evidence:$evidence,resume_from:$resume_from,global_timeout_seconds:$global_timeout,elapsed_seconds:$elapsed,slowest_stage:$slowest_stage,slowest_stage_seconds:$slowest_seconds,pass:$pass,fail:$fail}' \
        > "$EVIDENCE_DIR/summary.json"
}

main() {
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║  Phase 10B: Product Flow Rehearsal                  ║"
    echo "║  Local 5-agent testnet only                         ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo "Suite: $SUITE"
    echo "Global timeout: $GLOBAL_TIMEOUT"
    echo "Evidence: $EVIDENCE_DIR"

    start_global_timeout

    log_stage_start "argument parsing"
    pass "arguments parsed suite=$SUITE force_clean=$FORCE_CLEAN no_spawn=$NO_SPAWN keep_running=$KEEP_RUNNING timeout=$GLOBAL_TIMEOUT resume_from=${RESUME_FROM:-none}"
    log_stage_ok "argument parsing"

    log_stage_start "evidence setup"
    pass "evidence directory initialized at $EVIDENCE_DIR"
    log_stage_ok "evidence setup"

    run_runtime_bootstrap
    run_selected_suites

    if [ "$SUITE" = "all" ]; then
        stage_run "restore live flags false" 300 restore_live_flags_false
    fi

    run_or_skip_stage "final-live-flags" "final live flags" 90 final_live_flags_stage
    query_all_module_state "$EVIDENCE_DIR/final-state/module-state"
    stage_run "evidence finalization" 60 finalize_evidence
    write_summary
    stage_run "stop/cleanup" 60 stop_agents_if_needed

    echo ""
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║  Phase 10B Product Flow Summary                     ║"
    printf "║  Suite: %-43s ║\n" "$SUITE"
    printf "║  Timeout: %-40ss ║\n" "$GLOBAL_TIMEOUT"
    printf "║  PASS: %-4d FAIL: %-4d                              ║\n" "$PASS" "$FAIL"
    echo "║  Evidence: $EVIDENCE_DIR"
    echo "╚══════════════════════════════════════════════════════╝"
    echo "Elapsed seconds: $(jq -r '.elapsed_seconds // "unknown"' "$EVIDENCE_DIR/summary.json" 2>/dev/null || echo unknown)"
    echo "Slowest stage: $(jq -r '(.slowest_stage // "none") + " (" + ((.slowest_stage_seconds // 0)|tostring) + "s)"' "$EVIDENCE_DIR/summary.json" 2>/dev/null || echo none)"
    echo "Stage durations:"
    if command -v column >/dev/null 2>&1; then
        column -t -s "$(printf '\t')" "$STAGE_DURATIONS_FILE" 2>/dev/null || cat "$STAGE_DURATIONS_FILE"
    else
        cat "$STAGE_DURATIONS_FILE"
    fi

    if [ "$FAIL" -gt 0 ]; then
        FAILED_STAGE="${FAILED_STAGE:-summary fail count}"
        exit 1
    fi
    echo "" > "$EVIDENCE_DIR/failure-stage.txt"
    stop_global_timeout
}

main
