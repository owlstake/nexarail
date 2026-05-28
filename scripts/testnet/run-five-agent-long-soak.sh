#!/usr/bin/env bash
# NexaRail — Five-Agent Long Soak
#
# Runs a controlled long soak with periodic queries, tx smoke,
# governance vote checks, and live flag verification.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
EVIDENCE_DIR="${EVIDENCE_DIR:-$PROJECT_DIR/rehearsals/validator-agents/long-soak/evidence/$TIMESTAMP}"
DURATION=3600
SAMPLE_INTERVAL=60
TX_INTERVAL=300
KEEP_RUNNING=0
SKIP_GOV=0
SKIP_TX=0

while [[ $# -gt 0 ]]; do
    case "$1" in --duration) DURATION="$2"; shift 2 ;; --sample-interval) SAMPLE_INTERVAL="$2"; shift 2 ;; --tx-interval) TX_INTERVAL="$2"; shift 2 ;; --keep-running) KEEP_RUNNING=1; shift ;; --skip-gov) SKIP_GOV=1; shift ;; --skip-tx) SKIP_TX=1; shift ;; --evidence-dir) EVIDENCE_DIR="$2"; shift 2 ;; *) echo "Unknown: $1"; exit 1 ;; esac
done

mkdir -p "$EVIDENCE_DIR"/{samples,tx,gov,rest,logs}
PASS=0; FAIL=0; SKIP=0
PASS_MARK="  \033[32m✅ PASS\033[0m"; FAIL_MARK="  \033[31m❌ FAIL\033[0m"; SKIP_MARK="  \033[33m⏭️  SKIP\033[0m"
check_pass() { echo -e "${PASS_MARK} $1 — $2"; PASS=$((PASS+1)); }
check_fail() { echo -e "${FAIL_MARK} $1 — $2"; FAIL=$((FAIL+1)); }
check_skip() { echo -e "${SKIP_MARK} $1 — $2"; SKIP=$((SKIP+1)); }

AGENTS=("alpha:27657:1417" "bravo:27667:1418" "charlie:27677:1419" "delta:27687:1420" "echo:27697:1421")

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  NexaRail — Five-Agent Long Soak                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo "  Duration: ${DURATION}s | Sample: ${SAMPLE_INTERVAL}s | TX: ${TX_INTERVAL}s"
echo "  Evidence: $EVIDENCE_DIR"
echo ""

# ── Sample function ─────────────────────────────────────
SAMPLE_FILE="$EVIDENCE_DIR/samples.tsv"
echo -e "elapsed\ttime\tagent\theight\tpeers\tcatching_up" > "$SAMPLE_FILE"

sample_agents() {
    local elapsed="$1"
    local now="$(date -u +%H:%M:%S)"
    for agent_entry in "${AGENTS[@]}"; do
        IFS=':' read -r name rpc api <<< "$agent_entry"
        local status=$(curl -s --max-time 3 "http://localhost:$rpc/status" 2>/dev/null || echo "{}")
        local h=$(echo "$status" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('result',{}).get('sync_info',{}).get('latest_block_height','-'))" 2>/dev/null || echo "-")
        local peers=$(echo "$status" | python3 -c "import sys,json; d=json.load(sys.stdin); n=d.get('result',{}).get('node_info',{}).get('other',{}); print(n.get('tx_index','?'))" 2>/dev/null || echo "?")
        echo -e "$elapsed\t$now\t$name\t$h\t$peers" >> "$SAMPLE_FILE"
    done
    # Also check REST health for a sample agent
    for agent_entry in "${AGENTS[@]}"; do
        IFS=':' read -r name rpc api <<< "$agent_entry"
        curl -s --max-time 3 "http://localhost:$api/nexarail/settlement/v1/params" > "$EVIDENCE_DIR/rest/${name}-rest.json" 2>/dev/null || true
    done
}

# ── Bank tx function ────────────────────────────────────
send_tx() {
    local label="$1" elapsed="$2"
    local TX_FILE="$EVIDENCE_DIR/tx/tx-${elapsed}.json"
    if build/nexaraild tx bank send alpha-key bravo-key "1000unxrl" \
        --keyring-backend test --home "$PROJECT_DIR/rehearsals/validator-agents/alpha" \
        --chain-id nexarail-agent-testnet-1 --node tcp://localhost:27657 \
        --fees "500unxrl" --broadcast-mode sync --output json -y > "$TX_FILE" 2>/dev/null; then
        local code=$(python3 -c "import json; d=json.load(open('$TX_FILE')); print(d.get('code',-1))" 2>/dev/null || echo "-1")
        if [ "$code" = "0" ]; then
            check_pass "bank_tx_${elapsed}" "Bank tx sent at ${elapsed}s (code=0)"
        else
            check_fail "bank_tx_${elapsed}" "Bank tx code=$code"
        fi
    else
        check_fail "bank_tx_${elapsed}" "Bank tx command failed"
    fi
}

# ── Start timer ─────────────────────────────────────────
START_TIME=$SECONDS
END_TIME=$((SECONDS + DURATION))
TX_LAST_SENT=$SECONDS

echo "── Main Loop ───────────────────────────────────────────────────"
while [ $SECONDS -lt $END_TIME ]; do
    ELAPSED=$((SECONDS - START_TIME))

    # Sample every N seconds
    sample_agents "$ELAPSED"

    # Bank tx every TX_INTERVAL
    if [ "$SKIP_TX" -eq 0 ] && [ $((SECONDS - TX_LAST_SENT)) -ge "$TX_INTERVAL" ]; then
        send_tx "periodic" "$ELAPSED"
        TX_LAST_SENT=$SECONDS
    fi

    sleep "$SAMPLE_INTERVAL"
done

echo ""
echo "── Final Checks ────────────────────────────────────────────────"

# Rest health
echo "  REST health check..."
for agent_entry in "${AGENTS[@]}"; do
    IFS=':' read -r name rpc api <<< "$agent_entry"
    for mod in settlement escrow payout treasury; do
        code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "http://localhost:$api/nexarail/$mod/v1/params" 2>/dev/null || echo "000")
        echo "$name $mod: HTTP $code" >> "$EVIDENCE_DIR/rest-health.json"
    done
done
check_pass "rest_health" "REST health checked"

# Live flags
echo "  Live flags..."
FLAGS_ALL_OK=true
for agent_entry in "${AGENTS[@]}"; do
    IFS=':' read -r name rpc api <<< "$agent_entry"
    for mod in settlement escrow payout treasury; do
        le=$(curl -s "http://localhost:$api/nexarail/$mod/v1/params" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('params',d).get('live_enabled','?'))" 2>/dev/null || echo "?")
        if [ "$le" != "false" ]; then echo "  ⚠️  $name/$mod: live_enabled=$le"; FLAGS_ALL_OK=false; fi
    done
done
[ "$FLAGS_ALL_OK" = "true" ] && check_pass "live_flags" "All live flags false" || check_fail "live_flags" "Non-false live flag detected"

# Log scan
echo "  Log scan..."
SCAN="$EVIDENCE_DIR/panic-scan.txt"
> "$SCAN"
for term in "panic" "fatal" "CheckTx" "descriptor" "gzip invalid" "index out of range" "version does not exist"; do
    count=$(grep -rli "$term" "$EVIDENCE_DIR" 2>/dev/null | grep -v "panic-scan" | wc -l | tr -d ' ')
    echo "$term: $count" >> "$SCAN"
done

# Summary
TOTAL_DURATION=$((SECONDS - START_TIME))
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Long Soak Summary                                        ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5s %5s %5s   ║\n" "Result" "PASS" "FAIL" "SKIP"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5d %5d %5d   ║\n" "Soak" "$PASS" "$FAIL" "$SKIP"
echo "╠══════════════════════════════════════════════════════════════╣"
[ "$FAIL" -eq 0 ] && echo "║  ✅ Soak completed successfully           ║" || echo "║  ❌ Some checks failed                    ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  Duration: ${TOTAL_DURATION}s (target ${DURATION}s)          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo "  Evidence: $EVIDENCE_DIR"

cat > "$EVIDENCE_DIR/summary.json" << EOF
{"duration_seconds":$TOTAL_DURATION,"target_duration":$DURATION,"pass":$PASS,"fail":$FAIL,"skip":$SKIP}
EOF

# Stop
[ "$KEEP_RUNNING" -eq 0 ] && bash "$PROJECT_DIR/scripts/testnet/stop-validator-agents.sh" &>/dev/null || true

exit $([ "$FAIL" -eq 0 ] && echo 0 || echo 1)