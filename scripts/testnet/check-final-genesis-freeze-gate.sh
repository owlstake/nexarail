#!/usr/bin/env bash
# NexaRail Final Genesis Freeze Gate
# Phase 17H — single authoritative checker that emits FREEZE_GO / FREEZE_DEFER / FREEZE_BLOCKED.
#
# Usage:
#   scripts/testnet/check-final-genesis-freeze-gate.sh \
#     --genesis releases/testnet-genesis/nexarail-testnet-1-candidate/genesis.json \
#     --expected-sha256 4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095 \
#     --peer 2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656 \
#     [--probe-rpc http://127.0.0.1:26657] \
#     [--require-p2p] [--require-signoff] \
#     [--output-dir rehearsals/controlled-testnet/freeze-gate/evidence/<ts>]
#
# Exit codes:
#   0  decision = FREEZE_GO or FREEZE_DEFER (run completed without infra error)
#   1  decision = FREEZE_BLOCKED
#   2  usage / runtime error
#
# Decisions:
#   FREEZE_BLOCKED  any hard check failed (bad SHA/denom/secrets/live-flags/missing NodeSync, etc.)
#   FREEZE_DEFER    no hard failures, but optional/expected preconditions are still pending
#                   (real P2P handshake, coordinator/NodeSync sign-off, etc.)
#   FREEZE_GO       all required and gated checks pass; safe to freeze final public genesis.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

GENESIS=""
EXPECTED_SHA256=""
PEER=""
PROBE_RPC=""
REQUIRE_P2P=0
REQUIRE_SIGNOFF=0
OUTPUT_DIR=""
EXPECTED_DENOM="${NEXARAIL_DENOM:-unxrl}"
CHAIN_ID="${NEXARAIL_CHAIN_ID:-nexarail-testnet-1}"
BINARY="${NEXARAIL_BINARY:-$PROJECT_DIR/build/nexaraild}"

usage() {
    cat <<EOF
Usage: scripts/testnet/check-final-genesis-freeze-gate.sh [options]

Required:
  --genesis <path>              candidate genesis JSON
  --expected-sha256 <hash>      expected SHA256 of the candidate genesis
  --peer <nodeid@host:port>     NodeSync persistent peer entry to verify

Optional:
  --probe-rpc <url>             coordinator probe RPC (e.g. http://127.0.0.1:26657) for /net_info
  --require-p2p                 fail with FREEZE_BLOCKED if probe-rpc is missing or peer count = 0
  --require-signoff             fail with FREEZE_BLOCKED if signoff doc is not marked APPROVED
  --output-dir <path>           evidence directory (default: rehearsals/controlled-testnet/freeze-gate/evidence/<ts>)
  -h, --help                    show this help
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --genesis) GENESIS="$2"; shift 2 ;;
        --expected-sha256) EXPECTED_SHA256="$2"; shift 2 ;;
        --peer) PEER="$2"; shift 2 ;;
        --probe-rpc) PROBE_RPC="$2"; shift 2 ;;
        --require-p2p) REQUIRE_P2P=1; shift ;;
        --require-signoff) REQUIRE_SIGNOFF=1; shift ;;
        --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

if [ -z "$GENESIS" ] || [ -z "$EXPECTED_SHA256" ] || [ -z "$PEER" ]; then
    echo "ERROR: --genesis, --expected-sha256, and --peer are required" >&2
    usage >&2
    exit 2
fi

TS="$(date -u +%Y%m%dT%H%M%SZ)"
if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR="$PROJECT_DIR/rehearsals/controlled-testnet/freeze-gate/evidence/$TS"
fi
mkdir -p "$OUTPUT_DIR"

echo "=== NexaRail Final Genesis Freeze Gate ==="
echo "Timestamp UTC:   $TS"
echo "Genesis:         $GENESIS"
echo "Expected SHA256: $EXPECTED_SHA256"
echo "Peer:            $PEER"
echo "Probe RPC:       ${PROBE_RPC:-<unset>}"
echo "Require P2P:     $REQUIRE_P2P"
echo "Require signoff: $REQUIRE_SIGNOFF"
echo "Output dir:      $OUTPUT_DIR"
echo ""

PASS=0
FAIL=0
DEFER=0
declare -a CHECKS=()

record() {
    # record <severity> <check> <detail>
    # severity: PASS | FAIL | DEFER | INFO
    local sev="$1" name="$2" detail="$3"
    CHECKS+=("$sev|$name|$detail")
    case "$sev" in
        PASS)  echo "  ✅ PASS  $name — $detail"; PASS=$((PASS+1)) ;;
        FAIL)  echo "  ❌ FAIL  $name — $detail"; FAIL=$((FAIL+1)) ;;
        DEFER) echo "  ⏸ DEFER $name — $detail"; DEFER=$((DEFER+1)) ;;
        INFO)  echo "  ℹ️  INFO  $name — $detail" ;;
    esac
}

# ---------- 1. genesis file exists ----------
echo "--- Candidate Genesis Integrity ---"
if [ ! -f "$GENESIS" ]; then
    record FAIL "genesis-file-exists" "missing: $GENESIS"
else
    record PASS "genesis-file-exists" "$GENESIS"
fi

# ---------- 2. SHA256 match ----------
if [ -f "$GENESIS" ]; then
    if command -v sha256sum >/dev/null 2>&1; then
        ACTUAL_SHA=$(sha256sum "$GENESIS" | awk '{print $1}')
    else
        ACTUAL_SHA=$(shasum -a 256 "$GENESIS" | awk '{print $1}')
    fi
    if [ "$ACTUAL_SHA" = "$EXPECTED_SHA256" ]; then
        record PASS "candidate-sha256" "$ACTUAL_SHA"
    else
        record FAIL "candidate-sha256" "got=$ACTUAL_SHA expected=$EXPECTED_SHA256"
    fi
else
    ACTUAL_SHA=""
fi

# ---------- 3. validate-genesis ----------
if [ -f "$GENESIS" ] && [ -x "$BINARY" ]; then
    VG_HOME="$(mktemp -d)"
    mkdir -p "$VG_HOME/config"
    cp "$GENESIS" "$VG_HOME/config/genesis.json"
    if "$BINARY" --home "$VG_HOME" validate-genesis "$VG_HOME/config/genesis.json" \
        >"$OUTPUT_DIR/validate-genesis.txt" 2>&1; then
        record PASS "validate-genesis" "passes"
    else
        record FAIL "validate-genesis" "see $OUTPUT_DIR/validate-genesis.txt"
    fi
    rm -rf "$VG_HOME"
else
    record FAIL "validate-genesis" "binary $BINARY missing or unreadable genesis"
fi

# ---------- 4. denom audit ----------
DENOM_REPORT="$OUTPUT_DIR/denom-audit.json"
if [ -f "$GENESIS" ] && [ -x "$SCRIPT_DIR/check-genesis-denoms.sh" ]; then
    if "$SCRIPT_DIR/check-genesis-denoms.sh" \
        --genesis "$GENESIS" \
        --expected-denom "$EXPECTED_DENOM" \
        --output "$DENOM_REPORT" >"$OUTPUT_DIR/denom-audit.log" 2>&1; then
        record PASS "denom-audit" "$DENOM_REPORT"
    else
        record FAIL "denom-audit" "see $OUTPUT_DIR/denom-audit.log"
    fi
else
    record FAIL "denom-audit" "auditor missing"
fi

# ---------- 5. live flags false ----------
echo ""
echo "--- Live Funds Flags ---"
LIVE_REPORT="$OUTPUT_DIR/live-flags-check.json"
if [ -f "$GENESIS" ]; then
    python3 - "$GENESIS" "$LIVE_REPORT" <<'PY'
import json, sys, pathlib
genesis_path, out_path = sys.argv[1], sys.argv[2]
g = json.load(open(genesis_path))
app = g.get("app_state", {})
flag_paths = [
    ("escrow.params.live_enabled",      ["escrow","params","live_enabled"]),
    ("payout.params.live_enabled",      ["payout","params","live_enabled"]),
    ("treasury.params.live_enabled",    ["treasury","params","live_enabled"]),
    ("settlement.params.live_enabled",  ["settlement","params","live_enabled"]),
    ("settlement.params.live_fees",     ["settlement","params","live_fees"]),
    ("settlement.params.live_routing",  ["settlement","params","live_routing"]),
]
out = {"checks": [], "all_false": True, "missing": []}
for label, path in flag_paths:
    node = app
    found = True
    for p in path:
        if isinstance(node, dict) and p in node:
            node = node[p]
        else:
            found = False
            break
    if not found:
        out["missing"].append(label)
        out["checks"].append({"flag": label, "present": False, "value": None})
    else:
        value_is_false = (node is False) or (isinstance(node, str) and node.lower() == "false")
        out["checks"].append({"flag": label, "present": True, "value": node, "false": value_is_false})
        if not value_is_false:
            out["all_false"] = False
pathlib.Path(out_path).write_text(json.dumps(out, indent=2))
print("ALL_FALSE" if out["all_false"] else "FOUND_TRUE")
PY
    LIVE_RESULT=$(python3 -c "import json,sys; d=json.load(open('$LIVE_REPORT')); print('ALL_FALSE' if d['all_false'] else 'FOUND_TRUE')")
    if [ "$LIVE_RESULT" = "ALL_FALSE" ]; then
        record PASS "live-flags-false" "all known flags absent-or-false (report: $LIVE_REPORT)"
    else
        record FAIL "live-flags-false" "see $LIVE_REPORT"
    fi
else
    record FAIL "live-flags-false" "no genesis"
fi

# ---------- 6. NodeSync gentx accepted ----------
echo ""
echo "--- NodeSync ---"
NODESYNC_NODE_ID="$(echo "$PEER" | sed -E 's/^([0-9a-fA-F]+)@.*$/\1/')"
NODESYNC_HOST="$(echo "$PEER" | sed -E 's/^[0-9a-fA-F]+@([^:]+):.*$/\1/')"
GENTX_VERIFIED="$PROJECT_DIR/coordination/validators/verified/gentx-${NODESYNC_NODE_ID}.json"
if [ -f "$GENTX_VERIFIED" ]; then
    record PASS "nodesync-gentx-accepted" "$GENTX_VERIFIED"
else
    record FAIL "nodesync-gentx-accepted" "missing: $GENTX_VERIFIED"
fi

# ---------- 7. NodeSync present in genesis ----------
if [ -f "$GENESIS" ]; then
    PRESENT=$(jq -r --arg pk "" '
        [ .app_state.genutil.gen_txs[]?.body.messages[]?
          | select((.["@type"] // "") | endswith("MsgCreateValidator"))
          | .pubkey.key // (.consensus_pubkey.key // "")
        ] | unique | length
    ' "$GENESIS" 2>/dev/null || echo "0")
    # The above is just a sanity check that we have validators; do exact NodeSync detection by pubkey from the gentx.
    if [ -f "$GENTX_VERIFIED" ]; then
        NS_PUBKEY=$(jq -r '.body.messages[]? | select((.["@type"] // "") | endswith("MsgCreateValidator")) | .pubkey.key' "$GENTX_VERIFIED" 2>/dev/null || echo "")
        if [ -n "$NS_PUBKEY" ] && jq -e --arg k "$NS_PUBKEY" '
            [ .app_state.genutil.gen_txs[]?.body.messages[]?
              | select((.["@type"] // "") | endswith("MsgCreateValidator"))
              | .pubkey.key
            ] | index($k) != null
        ' "$GENESIS" >/dev/null 2>&1; then
            record PASS "nodesync-in-genesis" "consensus pubkey present in genutil.gen_txs"
        else
            record FAIL "nodesync-in-genesis" "consensus pubkey $NS_PUBKEY not found"
        fi
    else
        record FAIL "nodesync-in-genesis" "no verified gentx to compare"
    fi
fi

# ---------- 8. NodeSync persistent peer present ----------
PEERS_FILE="$PROJECT_DIR/coordination/validators/peer-info/persistent-peers.txt"
if [ -f "$PEERS_FILE" ] && grep -Fq "$PEER" "$PEERS_FILE"; then
    record PASS "nodesync-persistent-peer" "$PEERS_FILE"
else
    record FAIL "nodesync-persistent-peer" "missing from $PEERS_FILE"
fi

# ---------- 9. host resolves & TCP state recorded ----------
echo ""
echo "--- P2P Reachability ---"
REACH_REPORT="$OUTPUT_DIR/reachability.json"
DNS_A=""
if command -v dig >/dev/null 2>&1; then
    DNS_A=$(dig +short "$NODESYNC_HOST" A 2>/dev/null | head -1 || true)
fi
if [ -z "$DNS_A" ] && command -v getent >/dev/null 2>&1; then
    DNS_A=$(getent ahostsv4 "$NODESYNC_HOST" 2>/dev/null | awk 'NR==1{print $1}')
fi
if [ -z "$DNS_A" ]; then
    DNS_A=$(python3 -c "import socket,sys; print(socket.gethostbyname('$NODESYNC_HOST'))" 2>/dev/null || echo "")
fi
if [ -n "$DNS_A" ]; then
    record PASS "nodesync-host-resolves" "$NODESYNC_HOST -> $DNS_A"
else
    record FAIL "nodesync-host-resolves" "$NODESYNC_HOST did not resolve"
fi

TCP_STATE="UNKNOWN"
if command -v nc >/dev/null 2>&1; then
    if nc -vz -w 5 "$NODESYNC_HOST" 26656 >"$OUTPUT_DIR/nc-dns.txt" 2>&1; then
        TCP_STATE="OPEN"
    else
        TCP_STATE="REFUSED_OR_TIMEOUT"
    fi
fi
record INFO "nodesync-tcp-26656" "$TCP_STATE (recorded only; not gating)"

# ---------- 10. real CometBFT handshake probe (optional) ----------
PEER_COUNT="unknown"
HANDSHAKE_STATUS="NOT_PROBED"
if [ -n "$PROBE_RPC" ]; then
    if curl -fsS --max-time 5 "${PROBE_RPC%/}/net_info" > "$OUTPUT_DIR/net_info.json" 2>"$OUTPUT_DIR/net_info.err"; then
        PEER_COUNT=$(jq -r '.result.n_peers // "0"' "$OUTPUT_DIR/net_info.json" 2>/dev/null || echo "0")
        HAS_PEER=$(jq -r --arg id "$NODESYNC_NODE_ID" '[.result.peers[]?.node_info.id] | index($id) // null' "$OUTPUT_DIR/net_info.json" 2>/dev/null || echo "null")
        if [ "$HAS_PEER" != "null" ] && [ "$HAS_PEER" != "" ]; then
            HANDSHAKE_STATUS="HANDSHAKE_OK"
            record PASS "cometbft-handshake" "n_peers=$PEER_COUNT, includes NodeSync"
        else
            HANDSHAKE_STATUS="HANDSHAKE_MISSING_PEER"
            if [ "$REQUIRE_P2P" = "1" ]; then
                record FAIL "cometbft-handshake" "n_peers=$PEER_COUNT, NodeSync absent"
            else
                record DEFER "cometbft-handshake" "n_peers=$PEER_COUNT, NodeSync absent (deferred)"
            fi
        fi
    else
        HANDSHAKE_STATUS="PROBE_FAILED"
        if [ "$REQUIRE_P2P" = "1" ]; then
            record FAIL "cometbft-handshake" "probe failed: see $OUTPUT_DIR/net_info.err"
        else
            record DEFER "cometbft-handshake" "probe failed: see $OUTPUT_DIR/net_info.err"
        fi
    fi
else
    HANDSHAKE_STATUS="NOT_PROBED"
    if [ "$REQUIRE_P2P" = "1" ]; then
        record FAIL "cometbft-handshake" "--probe-rpc required by --require-p2p"
    else
        record DEFER "cometbft-handshake" "no --probe-rpc supplied (real handshake pending at launch window)"
    fi
fi

cat > "$REACH_REPORT" <<EOF
{
  "host": "$NODESYNC_HOST",
  "dns_a": "$DNS_A",
  "tcp_26656": "$TCP_STATE",
  "probe_rpc": "${PROBE_RPC:-}",
  "handshake_status": "$HANDSHAKE_STATUS",
  "n_peers": "$PEER_COUNT"
}
EOF

# ---------- 11. no secret material in candidate artifacts ----------
echo ""
echo "--- Secret Material Scan ---"
SECRET_SCAN="$OUTPUT_DIR/secret-scan.txt"
CANDIDATE_DIR="$(dirname "$GENESIS")"
{
    echo "scan_root: $CANDIDATE_DIR"
    echo "patterns: priv_validator_key|node_key|mnemonic|seed phrase|BEGIN PRIVATE KEY|BEGIN OPENSSH PRIVATE KEY"
} > "$SECRET_SCAN"
SECRET_HITS=0
if [ -d "$CANDIDATE_DIR" ]; then
    # filenames
    FOUND_FILES=$(find "$CANDIDATE_DIR" \( -iname "priv_validator_key.json" -o -iname "node_key.json" -o -iname "*.keyring*" -o -iname "*.mnemonic*" \) 2>/dev/null || true)
    if [ -n "$FOUND_FILES" ]; then
        echo "FILE_MATCHES:" >> "$SECRET_SCAN"
        echo "$FOUND_FILES" >> "$SECRET_SCAN"
        SECRET_HITS=$((SECRET_HITS+1))
    fi
    # contents
    CONTENT_HITS=$( (grep -RIl -E "(BEGIN (OPENSSH )?PRIVATE KEY|mnemonic|seed phrase|priv_key|node_key\.json)" "$CANDIDATE_DIR" 2>/dev/null || true) )
    if [ -n "$CONTENT_HITS" ]; then
        echo "CONTENT_MATCHES:" >> "$SECRET_SCAN"
        echo "$CONTENT_HITS" >> "$SECRET_SCAN"
        SECRET_HITS=$((SECRET_HITS+1))
    fi
fi
if [ "$SECRET_HITS" = "0" ]; then
    record PASS "no-secret-material" "no matches in $CANDIDATE_DIR"
else
    record FAIL "no-secret-material" "see $SECRET_SCAN"
fi

# ---------- 12. final genesis is not accidentally marked launched ----------
FINAL_DIR="$PROJECT_DIR/releases/testnet-genesis/$CHAIN_ID"
if [ -d "$FINAL_DIR" ] && [ -f "$FINAL_DIR/genesis.json" ]; then
    record FAIL "final-genesis-not-published" "$FINAL_DIR/genesis.json exists"
else
    record PASS "final-genesis-not-published" "no published genesis at $FINAL_DIR"
fi

# ---------- 13. required docs exist ----------
echo ""
echo "--- Required Docs ---"
DOCS_REPORT="$OUTPUT_DIR/docs-check.json"
REQUIRED_DOCS=(
    "docs/testnet/FINAL_GENESIS_FREEZE_DECISION.md"
    "docs/testnet/PHASE_17E1_GENESIS_DENOM_AUDIT_AND_P2P_PRECONDITIONS.md"
    "docs/testnet/CONTROLLED_TESTNET_LAUNCH_WINDOW_TEMPLATE.md"
    "docs/testnet/CONTROLLED_TESTNET_LAUNCH_DAY_COMMANDS.md"
    "docs/testnet/CONTROLLED_TESTNET_INCIDENT_RESPONSE.md"
    "docs/testnet/CONTROLLED_TESTNET_RUNBOOK.md"
    "docs/testnet/CONTROLLED_TESTNET_COORDINATOR_CHECKLIST.md"
)
LAUNCH_PACKET_DOCS=(
    "docs/testnet/CONTROLLED_TESTNET_FINAL_LAUNCH_PACKET_DRAFT.md"
    "docs/testnet/NODESYNC_LAUNCH_WINDOW_INSTRUCTIONS.md"
    "docs/testnet/CONTROLLED_TESTNET_LAUNCH_SIGNOFF.md"
)
DOC_PASS=0
DOC_FAIL=0
{
    printf '{\n  "required": [\n'
    first=1
    for d in "${REQUIRED_DOCS[@]}"; do
        [ $first -eq 1 ] && first=0 || printf ',\n'
        if [ -f "$PROJECT_DIR/$d" ]; then
            printf '    {"path":"%s","present":true}' "$d"
            DOC_PASS=$((DOC_PASS+1))
        else
            printf '    {"path":"%s","present":false}' "$d"
            DOC_FAIL=$((DOC_FAIL+1))
        fi
    done
    printf '\n  ],\n  "launch_packet": [\n'
    first=1
    for d in "${LAUNCH_PACKET_DOCS[@]}"; do
        [ $first -eq 1 ] && first=0 || printf ',\n'
        if [ -f "$PROJECT_DIR/$d" ]; then
            printf '    {"path":"%s","present":true}' "$d"
            DOC_PASS=$((DOC_PASS+1))
        else
            printf '    {"path":"%s","present":false}' "$d"
            DOC_FAIL=$((DOC_FAIL+1))
        fi
    done
    printf '\n  ]\n}\n'
} > "$DOCS_REPORT"
if [ "$DOC_FAIL" = "0" ]; then
    record PASS "required-docs" "all $DOC_PASS docs present"
else
    record FAIL "required-docs" "$DOC_FAIL missing (see $DOCS_REPORT)"
fi

# ---------- 14. coordinator sign-off ----------
echo ""
echo "--- Sign-off ---"
SIGNOFF_DOC="$PROJECT_DIR/docs/testnet/CONTROLLED_TESTNET_LAUNCH_SIGNOFF.md"
SIGNOFF_STATUS="PENDING"
if [ -f "$SIGNOFF_DOC" ]; then
    if grep -Eq '^\*\*Status:\*\*[[:space:]]+APPROVED' "$SIGNOFF_DOC"; then
        SIGNOFF_STATUS="APPROVED"
        record PASS "coordinator-signoff" "APPROVED"
    elif grep -Eq '^\*\*Status:\*\*[[:space:]]+BLOCKED' "$SIGNOFF_DOC"; then
        SIGNOFF_STATUS="BLOCKED"
        record FAIL "coordinator-signoff" "BLOCKED"
    else
        SIGNOFF_STATUS="PENDING"
        if [ "$REQUIRE_SIGNOFF" = "1" ]; then
            record FAIL "coordinator-signoff" "PENDING (required)"
        else
            record DEFER "coordinator-signoff" "PENDING"
        fi
    fi
else
    if [ "$REQUIRE_SIGNOFF" = "1" ]; then
        record FAIL "coordinator-signoff" "signoff doc missing"
    else
        record DEFER "coordinator-signoff" "signoff doc missing"
    fi
fi

# ---------- decision ----------
echo ""
echo "--- Decision ---"
DECISION="FREEZE_GO"
if [ "$FAIL" -gt 0 ]; then
    DECISION="FREEZE_BLOCKED"
elif [ "$DEFER" -gt 0 ]; then
    DECISION="FREEZE_DEFER"
fi

echo "PASS=$PASS  FAIL=$FAIL  DEFER=$DEFER"
echo "Decision: $DECISION"

# ---------- write summaries ----------
SUMMARY_JSON="$OUTPUT_DIR/freeze-gate-summary.json"
SUMMARY_MD="$OUTPUT_DIR/freeze-gate-summary.md"

{
    printf '{\n'
    printf '  "timestamp_utc": "%s",\n' "$TS"
    printf '  "chain_id": "%s",\n' "$CHAIN_ID"
    printf '  "genesis": "%s",\n' "$GENESIS"
    printf '  "expected_sha256": "%s",\n' "$EXPECTED_SHA256"
    printf '  "actual_sha256": "%s",\n' "$ACTUAL_SHA"
    printf '  "peer": "%s",\n' "$PEER"
    printf '  "probe_rpc": "%s",\n' "${PROBE_RPC:-}"
    printf '  "require_p2p": %s,\n' "$REQUIRE_P2P"
    printf '  "require_signoff": %s,\n' "$REQUIRE_SIGNOFF"
    printf '  "tcp_26656": "%s",\n' "$TCP_STATE"
    printf '  "handshake_status": "%s",\n' "$HANDSHAKE_STATUS"
    printf '  "signoff_status": "%s",\n' "$SIGNOFF_STATUS"
    printf '  "pass": %d,\n' "$PASS"
    printf '  "fail": %d,\n' "$FAIL"
    printf '  "defer": %d,\n' "$DEFER"
    printf '  "decision": "%s",\n' "$DECISION"
    printf '  "checks": [\n'
    first=1
    for line in "${CHECKS[@]}"; do
        sev=${line%%|*}; rest=${line#*|}
        name=${rest%%|*}; detail=${rest#*|}
        [ $first -eq 1 ] && first=0 || printf ',\n'
        printf '    {"severity":"%s","check":"%s","detail":%s}' \
            "$sev" "$name" "$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$detail")"
    done
    printf '\n  ]\n}\n'
} > "$SUMMARY_JSON"

{
    echo "# Final Genesis Freeze Gate Summary"
    echo
    echo "- Timestamp UTC: $TS"
    echo "- Chain ID: $CHAIN_ID"
    echo "- Genesis: \`$GENESIS\`"
    echo "- Expected SHA256: \`$EXPECTED_SHA256\`"
    echo "- Actual SHA256: \`$ACTUAL_SHA\`"
    echo "- Peer: \`$PEER\`"
    echo "- Probe RPC: \`${PROBE_RPC:-<unset>}\`"
    echo "- TCP 26656: \`$TCP_STATE\`"
    echo "- Handshake: \`$HANDSHAKE_STATUS\`"
    echo "- Signoff: \`$SIGNOFF_STATUS\`"
    echo "- PASS=$PASS  FAIL=$FAIL  DEFER=$DEFER"
    echo "- Decision: **$DECISION**"
    echo
    echo "## Checks"
    echo
    for line in "${CHECKS[@]}"; do
        sev=${line%%|*}; rest=${line#*|}
        name=${rest%%|*}; detail=${rest#*|}
        echo "- $sev — \`$name\` — $detail"
    done
    echo
    echo "## Safety Boundary"
    echo
    echo "Controlled external-validator testnet remains NOT LAUNCHED. Mainnet remains NO-GO. External decentralisation is not claimed. NXRL is not buyable and has no monetary value. No token sale is announced or implied. Product live-funds flags remain false by default."
} > "$SUMMARY_MD"

echo "Summary JSON: $SUMMARY_JSON"
echo "Summary MD:   $SUMMARY_MD"

if [ "$DECISION" = "FREEZE_BLOCKED" ]; then
    exit 1
fi
exit 0
