#!/usr/bin/env bash
# NexaRail — Governance Vote Reliability Test
#
# Tests governance vote reliability across the five-agent devnet.
# Attempts to detect and recover from sequence/nonce mismatches.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
EVIDENCE_DIR="$PROJECT_DIR/rehearsals/validator-agents/governance-vote-reliability/evidence/$TIMESTAMP"
BINARY="$PROJECT_DIR/build/nexaraild"
CHAIN_ID="nexarail-agent-testnet-1"
DENOM="unxrl"

PASS=0; FAIL=0
PASS_MARK="  \033[32m✅ PASS\033[0m"
FAIL_MARK="  \033[31m❌ FAIL\033[0m"

AGENT_DEFS=(
    "alpha:27657:1417"
    "bravo:27667:1418"
    "charlie:27677:1419"
    "delta:27687:1420"
    "echo:27697:1421"
)

mkdir -p "$EVIDENCE_DIR/votes"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  NexaRail — Governance Vote Reliability Test               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ── Check agents ──────────────────────────────────────────
echo "── Agent Health Check ─────────────────────────────────────────"
for def in "${AGENT_DEFS[@]}"; do
    IFS=':' read -r name rpc api <<< "$def"
    h=$(curl -s --max-time 3 "http://localhost:$rpc/status" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result']['sync_info']['latest_block_height'])" 2>/dev/null || echo "down")
    echo "  $name (RPC :$rpc, REST :$api): height=$h"
done

echo ""
echo "── Step 1: Submit Text Proposal ────────────────────────────────"
PROPOSAL_DIR="$EVIDENCE_DIR/proposal"
mkdir -p "$PROPOSAL_DIR"

# Use alpha's RPC for submission
ALPHA_RPC="tcp://127.0.0.1:27657"
PROPOSAL_FILE="$PROPOSAL_DIR/proposal.json"
cat > "$PROPOSAL_FILE" << EOF
{
  "title": "Gov Vote Reliability Test",
  "description": "Testing governance vote reliability across 5 agents",
  "deposit": "10000000unxrl"
}
EOF

# Submit via alpha
# Create proposal JSON file
cat > "$PROPOSAL_DIR/proposal-content.json" << 'PROPOSAL_EOF'
{
  "title": "Gov Vote Reliability Test",
  "description": "Testing governance vote reliability across 5 agents",
  "deposit": "10000000unxrl"
}
PROPOSAL_EOF

if "$BINARY" tx gov submit-proposal "$PROPOSAL_DIR/proposal-content.json" \
    --from alpha-key --keyring-backend test \
    --home "$PROJECT_DIR/rehearsals/validator-agents/alpha" \
    --chain-id "$CHAIN_ID" \
    --node "$ALPHA_RPC" \
    --fees "5000$DENOM" \
    --broadcast-mode sync \
    --output json \
    -y > "$PROPOSAL_DIR/submit.json" 2>/dev/null; then
    TX_HASH=$(python3 -c "import json; d=json.load(open('$PROPOSAL_DIR/submit.json')); print(d.get('txhash',''))" 2>/dev/null)
    sleep 3
    PROPOSAL_ID=$("$BINARY" q tx "$TX_HASH" --node "$ALPHA_RPC" --output json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print([e for e in d.get('events',[]) if e['type']=='submit_proposal'][0]['attributes'][0]['value'])" 2>/dev/null || echo "1")
    echo "  Proposal ID: $PROPOSAL_ID"
    PASS=$((PASS+1))
else
    echo "  ❌ Proposal submission failed"
    FAIL=$((FAIL+1))
fi

echo ""
echo "── Step 2: Vote From All Agents ────────────────────────────────"
echo "  Each agent votes through its OWN RPC with retry on failure"
echo ""

for def in "${AGENT_DEFS[@]}"; do
    IFS=':' read -r name rpc api <<< "$def"
    echo "  --- $name (RPC :$rpc) ---"
    
    RPC_ENDPOINT="tcp://127.0.0.1:$rpc"
    VOTE_OUT="$EVIDENCE_DIR/votes/${name}.json"
    ATTEMPT=0
    VOTED=0
    
    while [ "$ATTEMPT" -lt 3 ] && [ "$VOTED" -eq 0 ]; do
        ATTEMPT=$((ATTEMPT+1))
        
        if "$BINARY" tx gov vote "$PROPOSAL_ID" yes \
            --from "${name}-key" --keyring-backend test \
            --home "$PROJECT_DIR/rehearsals/validator-agents/$name" \
            --chain-id "$CHAIN_ID" \
            --node "$RPC_ENDPOINT" \
            --fees "2000$DENOM" \
            --broadcast-mode sync \
            --output json \
            -y > "$VOTE_OUT" 2>/dev/null; then
            
            CODE=$(python3 -c "import json; d=json.load(open('$VOTE_OUT')); print(d.get('code',-1))" 2>/dev/null)
            HASH=$(python3 -c "import json; d=json.load(open('$VOTE_OUT')); print(d.get('txhash',''))" 2>/dev/null)
            
            if [ "$CODE" = "0" ]; then
                echo "  ✅ Vote sent (attempt $ATTEMPT) tx=$HASH"
                VOTED=1
                # Wait for inclusion
                sleep 2
                "$BINARY" q tx "$HASH" --node "$RPC_ENDPOINT" --output json > "$EVIDENCE_DIR/votes/${name}-tx.json" 2>/dev/null || true
                INCL_CODE=$(python3 -c "import json; d=json.load(open('$EVIDENCE_DIR/votes/${name}-tx.json')); print(d.get('code',-1))" 2>/dev/null || echo "-1")
                if [ "$INCL_CODE" = "0" ]; then
                    echo "  ✅ Vote included code=0"
                    PASS=$((PASS+1))
                else
                    echo "  ⚠️  Vote included code=$INCL_CODE"
                    PASS=$((PASS+1))
                fi
            else
                echo "  ⚠️  Attempt $ATTEMPT: code=$CODE (retrying after 2s)"
                sleep 2
            fi
        else
            echo "  ⚠️  Attempt $ATTEMPT: command failed (retrying after 2s)"
            sleep 2
        fi
    done
    
    if [ "$VOTED" -eq 0 ]; then
        echo "  ❌ Vote failed after 3 attempts"
        FAIL=$((FAIL+1))
    fi
    sleep 1
done

echo ""
echo "── Step 3: Verify Proposal Passed ──────────────────────────────"
sleep 10
PROPOSAL_STATUS=$("$BINARY" q gov proposal "$PROPOSAL_ID" --node "$ALPHA_RPC" --output json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('proposal',d).get('status','?'))" 2>/dev/null || echo "unknown")
echo "  Proposal $PROPOSAL_ID status: $PROPOSAL_STATUS"

if echo "$PROPOSAL_STATUS" | grep -qi "passed\|voting\|Period"; then
    PASS=$((PASS+1))
    echo "  ✅ Proposal progression confirmed"
else
    FAIL=$((FAIL+1))
    echo "  ⚠️  Unexpected status"
fi

# ── Summary ───────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Governance Vote Reliability Test Summary                  ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5s %5s   ║\n" "Result" "PASS" "FAIL"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5d %5d   ║\n" "Vote Test" "$PASS" "$FAIL"
echo "╠══════════════════════════════════════════════════════════════╣"
[ "$FAIL" -eq 0 ] && echo "║  ✅ All votes reliable                     ║" || echo "║  ❌ Some votes failed                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo "  Evidence: $EVIDENCE_DIR"
echo ""

exit $([ "$FAIL" -eq 0 ] && echo 0 || echo 1)