#!/usr/bin/env bash
# NexaRail — Phase 9T Validator Agent Governance Lifecycle Test
#
# Runs the escrow live flag enable/disable lifecycle against the local
# 5-agent testnet and captures final state readback evidence.
#
# TESTNET/DEVNET ONLY. Tokens have zero value. No mainnet exists.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
BINARY="$PROJECT_DIR/build/nexaraild"
CHAIN_ID="nexarail-agent-testnet-1"
AGENT_DIR="$PROJECT_DIR/rehearsals/validator-agents"
BRAVO_RPC="tcp://127.0.0.1:27667"
BRAVO_RPC_HTTP="http://127.0.0.1:27667"
BRAVO_API="1418"
BRAVO_HOME="$AGENT_DIR/bravo"
TIMESTAMP="${GOV_TIMESTAMP:-$(date -u +%Y%m%dT%H%M%SZ)}"
EVIDENCE_DIR="${EVIDENCE_DIR:-$AGENT_DIR/clean-spawn-governance/evidence/$TIMESTAMP}"
mkdir -p "$EVIDENCE_DIR"

AGENTS=(alpha bravo charlie delta echo)
MODULES=(fees merchant settlement escrow payout treasury)
PASS=0
FAIL=0

pass() { echo "  OK  $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL $1"; FAIL=$((FAIL+1)); }

json_get() {
    local file="$1"
    local expr="$2"
    jq -r "$expr" "$file" 2>/dev/null || echo ""
}

record_context() {
    cat > "$EVIDENCE_DIR/run-context.txt" <<EOF
Timestamp UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Project: $PROJECT_DIR
Chain ID: $CHAIN_ID
RPC: $BRAVO_RPC
API: $BRAVO_API
Evidence: $EVIDENCE_DIR
EOF
}

require_runtime() {
    if [ ! -x "$BINARY" ]; then
        echo "Binary not found or not executable: $BINARY"
        exit 1
    fi
    if ! curl -s --max-time 5 "$BRAVO_RPC_HTTP/status" > "$EVIDENCE_DIR/preflight-status.json" 2>&1; then
        echo "Agent not reachable on $BRAVO_RPC_HTTP"
        echo "Run: scripts/testnet/spawn-validator-agents.sh --clean"
        exit 1
    fi
    pass "agent testnet reachable"
}

gov_address() {
    echo "nxr10d07y265gmmuvt4z0w9aw880jnsr700js8jz70"
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
        if curl -s --max-time 10 "$BRAVO_RPC_HTTP/tx?hash=$rpc_hash" > "$outfile" 2> "$outfile.err"; then
            rm -f "$outfile.err"
            if jq -e '.result.hash' "$outfile" > /dev/null 2>&1; then
                code="$(json_get "$outfile" '.result.tx_result.code // 0')"
				if [ "$code" = "0" ]; then
					pass "$label included code=0"
					return 0
				fi
				fail "$label included code=$code"
				return 1
			fi
        fi
        sleep 2
    done

    fail "$label not found by CometBFT tx query"
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

submit_proposal() {
    local desired="$1"
    local dir="$2"
    local title="$3"
    local gov_addr bravo_addr account_number sequence proposal_id tx_hash
    mkdir -p "$dir"

    gov_addr="$(gov_address)"
    bravo_addr=$("$BINARY" keys show bravo-key -a --keyring-backend test --home "$BRAVO_HOME")
    read -r account_number sequence < <(account_numbers "$bravo_addr" "$dir/bravo-account-before-submit.json")
    echo "account_number=$account_number sequence=$sequence" > "$dir/signing-account.txt"

    cat > "$dir/proposal.json" <<EOFPROP
{
  "title": "$title",
  "summary": "Testnet-only governance exercise. Tokens have zero value. No mainnet implications.",
  "messages": [
    {
      "@type": "/nexarail.escrow.v1.MsgUpdateParams",
      "authority": "$gov_addr",
      "params": {
        "escrows_enabled": true,
        "live_enabled": $desired,
        "max_reference_length": 120,
        "max_memo_length": 280,
        "max_dispute_reason_length": 1000,
        "max_resolution_note_length": 1000,
        "min_escrow_amount": {"denom": "unxrl", "amount": "1"},
        "default_expiry_seconds": 2592000
      }
    }
  ],
  "metadata": "",
  "deposit": "1000000unxrl",
  "expedited": false
}
EOFPROP

    "$BINARY" tx gov submit-proposal "$dir/proposal.json" \
        --from bravo-key --keyring-backend test --home "$BRAVO_HOME" \
        --chain-id "$CHAIN_ID" --node "$BRAVO_RPC" \
        --generate-only --fees "10000unxrl" \
        > "$dir/unsigned.json"

    "$BINARY" tx sign "$dir/unsigned.json" \
        --offline --account-number "$account_number" --sequence "$sequence" \
        --from bravo-key --keyring-backend test --home "$BRAVO_HOME" \
        --chain-id "$CHAIN_ID" \
        > "$dir/signed.json"

    broadcast_proto_tx "$dir/signed.json" "$dir" "$title" || return 1
    tx_hash="$(cat "$dir/txhash.txt")"
    wait_for_tx "$tx_hash" "$dir/submit-tx.json" "$title submit tx" || return 1

    proposal_id="$(latest_proposal_id "$dir/proposals-after-submit.json")"
    if [ -z "$proposal_id" ]; then
        fail "$title proposal ID readback"
        return 1
    fi
    echo "$proposal_id" > "$dir/proposal-id.txt"
    pass "$title proposal ID=$proposal_id"
}

vote_all_yes() {
    local proposal_id="$1"
    local dir="$2"
    local label="$3"
    mkdir -p "$dir/votes"
    : > "$dir/vote-tx-hashes.txt"

    for agent in "${AGENTS[@]}"; do
        local home="$AGENT_DIR/$agent"
        local outfile="$dir/votes/${agent}-vote.json"
        local tx_hash code
        echo "  $agent voting YES on proposal $proposal_id"
        if "$BINARY" tx gov vote "$proposal_id" yes \
            --from "${agent}-key" --keyring-backend test \
            --home "$home" \
            --chain-id "$CHAIN_ID" \
            --node "$BRAVO_RPC" \
            --fees "2000unxrl" \
            --broadcast-mode sync \
            --output json \
            -y > "$outfile" 2> "$outfile.err"; then
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
        else
            fail "$label $agent vote command"
        fi
        sleep 1
    done
}

query_params() {
    local mod="$1"
    local outfile="$2"
    curl -s --max-time 5 "http://127.0.0.1:$BRAVO_API/nexarail/$mod/v1/params" > "$outfile"
    jq -e '.params' "$outfile" > /dev/null
}

query_all_params() {
    local dir="$1"
    mkdir -p "$dir"
    for mod in "${MODULES[@]}"; do
        if query_params "$mod" "$dir/${mod}-params.json"; then
            pass "$mod params readback"
        else
            fail "$mod params readback"
        fi
    done
}

assert_escrow_live() {
    local expected="$1"
    local file="$2"
    local label="$3"
    local val
    val="$(json_get "$file" '.params.live_enabled')"
    if [ "$val" = "$expected" ]; then
        pass "$label escrow.live_enabled=$expected"
        return 0
    fi
    fail "$label escrow.live_enabled=${val:-missing}, expected $expected"
    return 1
}

final_live_flag_sweep() {
    local dir="$1"
    local failures=0
    mkdir -p "$dir"
    query_all_params "$dir"

    : > "$dir/final-live-flags.txt"
    for item in \
        "settlement.live_enabled:$dir/settlement-params.json:.params.live_enabled" \
        "settlement.treasury_routing_enabled:$dir/settlement-params.json:.params.treasury_routing_enabled" \
        "settlement.burn_routing_enabled:$dir/settlement-params.json:.params.burn_routing_enabled" \
        "escrow.live_enabled:$dir/escrow-params.json:.params.live_enabled" \
        "payout.live_enabled:$dir/payout-params.json:.params.live_enabled" \
        "treasury.live_enabled:$dir/treasury-params.json:.params.live_enabled"; do
        IFS=':' read -r label file expr <<< "$item"
        val="$(json_get "$file" "$expr")"
        echo "$label=$val" >> "$dir/final-live-flags.txt"
        if [ "$val" = "false" ] || [ "$val" = "False" ]; then
            pass "final $label=false"
        else
            fail "final $label=${val:-missing}"
            failures=$((failures+1))
        fi
    done

    return "$failures"
}

echo "╔══════════════════════════════════════════════════════╗"
echo "║  Phase 9T: Clean-Spawn Governance Readback          ║"
echo "║  Chain: $CHAIN_ID              ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "Evidence: $EVIDENCE_DIR"
echo ""

record_context
require_runtime

echo ""
echo "--- Pre-governance params readback ---"
query_all_params "$EVIDENCE_DIR/pre-governance-params"

echo ""
echo "--- Submit ENABLE proposal ---"
ENABLE_DIR="$EVIDENCE_DIR/enable"
submit_proposal "true" "$ENABLE_DIR" "TESTNET: Enable escrow.live_enabled - Phase 9T governance readback"
ENABLE_PROPOSAL_ID="$(cat "$ENABLE_DIR/proposal-id.txt")"

echo ""
echo "--- Vote YES on ENABLE proposal ---"
vote_all_yes "$ENABLE_PROPOSAL_ID" "$ENABLE_DIR" "enable"

echo ""
echo "--- Wait for ENABLE proposal final status ---"
wait_for_proposal_passed "$ENABLE_PROPOSAL_ID" "$ENABLE_DIR" "enable"
query_params escrow "$ENABLE_DIR/escrow-params-after-enable.json"
assert_escrow_live "true" "$ENABLE_DIR/escrow-params-after-enable.json" "after enable"

echo ""
echo "--- Submit DISABLE proposal ---"
DISABLE_DIR="$EVIDENCE_DIR/disable"
submit_proposal "false" "$DISABLE_DIR" "TESTNET: Disable escrow.live_enabled - Phase 9T governance readback"
DISABLE_PROPOSAL_ID="$(cat "$DISABLE_DIR/proposal-id.txt")"

echo ""
echo "--- Vote YES on DISABLE proposal ---"
vote_all_yes "$DISABLE_PROPOSAL_ID" "$DISABLE_DIR" "disable"

echo ""
echo "--- Wait for DISABLE proposal final status ---"
wait_for_proposal_passed "$DISABLE_PROPOSAL_ID" "$DISABLE_DIR" "disable"
query_params escrow "$DISABLE_DIR/escrow-params-after-disable.json"
assert_escrow_live "false" "$DISABLE_DIR/escrow-params-after-disable.json" "after disable"

echo ""
echo "--- Final live flag sweep ---"
final_live_flag_sweep "$EVIDENCE_DIR/final-state" || true

cat > "$EVIDENCE_DIR/summary.txt" <<EOF
NexaRail Phase 9T governance lifecycle summary
Timestamp UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Enable proposal ID: $ENABLE_PROPOSAL_ID
Disable proposal ID: $DISABLE_PROPOSAL_ID
Enable submit tx: $(cat "$ENABLE_DIR/txhash.txt" 2>/dev/null || true)
Disable submit tx: $(cat "$DISABLE_DIR/txhash.txt" 2>/dev/null || true)
Enable vote tx hashes:
$(cat "$ENABLE_DIR/vote-tx-hashes.txt" 2>/dev/null || true)
Disable vote tx hashes:
$(cat "$DISABLE_DIR/vote-tx-hashes.txt" 2>/dev/null || true)
LiveEnabled after enable: $(json_get "$ENABLE_DIR/escrow-params-after-enable.json" '.params.live_enabled')
LiveEnabled after disable: $(json_get "$DISABLE_DIR/escrow-params-after-disable.json" '.params.live_enabled')
Final live flags:
$(cat "$EVIDENCE_DIR/final-state/final-live-flags.txt" 2>/dev/null || true)
PASS: $PASS
FAIL: $FAIL
EOF

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Phase 9T Governance Test Summary                   ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  Evidence: $EVIDENCE_DIR"
echo "║  Enable proposal ID: $ENABLE_PROPOSAL_ID"
echo "║  Disable proposal ID: $DISABLE_PROPOSAL_ID"
printf "║  Checks passed:   %-34s║\n" "$PASS"
printf "║  Checks failed:   %-34s║\n" "$FAIL"
echo "╚══════════════════════════════════════════════════════╝"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
