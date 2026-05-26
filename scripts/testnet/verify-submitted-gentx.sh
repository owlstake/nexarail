#!/usr/bin/env bash
# NexaRail Testnet — Gentx Verification Script
# Validates a single gentx file against the 22-point checklist.
# Usage: ./scripts/testnet/verify-submitted-gentx.sh <gentx.json> [registry-file]
#   registry-file: optional JSON file listing accepted validators for duplicate checks
set -euo pipefail

GENTX="${1:-}"
REGISTRY="${2:-}"

if [ -z "$GENTX" ] || [ ! -f "$GENTX" ]; then
    echo "Usage: $0 <gentx.json> [registry-file]"
    echo "  registry-file: optional JSON file listing accepted validator monikers and pubkeys"
    exit 1
fi

PASS=0
FAIL=0
WARN=0
check() { local msg="$1"; shift; if "$@"; then echo "  ✅ $msg"; PASS=$((PASS+1)); else echo "  ❌ $msg"; FAIL=$((FAIL+1)); fi; }

echo "=== Gentx Verification: $(basename "$GENTX") ==="
echo ""

# 1. JSON validity
check "JSON valid" python3 -c "import json; json.load(open('$GENTX'))" 2>/dev/null

# Extract fields
MONIKER=$(python3 -c "import json; g=json.load(open('$GENTX')); print(g['body']['messages'][0].get('description',{}).get('moniker',''))" 2>/dev/null || echo "")
CHAIN_ID=$(python3 -c "import json; g=json.load(open('$GENTX')); print(g['body']['messages'][0].get('chain_id',''))" 2>/dev/null || echo "")
AMOUNT=$(python3 -c "import json; g=json.load(open('$GENTX')); print(g['body']['messages'][0].get('value',{}).get('amount','0'))" 2>/dev/null || echo "0")
DENOM=$(python3 -c "import json; g=json.load(open('$GENTX')); print(g['body']['messages'][0].get('value',{}).get('denom',''))" 2>/dev/null || echo "")
OP_ADDR=$(python3 -c "import json; g=json.load(open('$GENTX')); print(g['body']['messages'][0].get('validator_address',''))" 2>/dev/null || echo "")
PUBKEY_TYPE=$(python3 -c "import json; g=json.load(open('$GENTX')); print(g['body']['messages'][0].get('pubkey',{}).get('@type',''))" 2>/dev/null || echo "")
PUBKEY_KEY=$(python3 -c "import json; g=json.load(open('$GENTX')); print(g['body']['messages'][0].get('pubkey',{}).get('key',''))" 2>/dev/null || echo "")
COMM_RATE=$(python3 -c "import json; g=json.load(open('$GENTX')); print(g['body']['messages'][0].get('commission',{}).get('rate','0'))" 2>/dev/null || echo "0")
COMM_MAX=$(python3 -c "import json; g=json.load(open('$GENTX')); print(g['body']['messages'][0].get('commission',{}).get('max_rate','0'))" 2>/dev/null || echo "0")
COMM_CHANGE=$(python3 -c "import json; g=json.load(open('$GENTX')); print(g['body']['messages'][0].get('commission',{}).get('max_change_rate','0'))" 2>/dev/null || echo "0")
MSG_TYPE=$(python3 -c "import json; g=json.load(open('$GENTX')); print(g['body']['messages'][0].get('@type',''))" 2>/dev/null || echo "")

echo ""
echo "  Moniker:        $MONIKER"
echo "  Chain ID:       $CHAIN_ID"
echo "  Amount:         $AMOUNT $DENOM"
echo "  Operator:       $OP_ADDR"
echo "  Pubkey type:    $PUBKEY_TYPE"
echo "  Pubkey:         ${PUBKEY_KEY:0:24}..."
echo "  Commission:     $COMM_RATE / $COMM_MAX / $COMM_CHANGE"
echo "  Message type:   $MSG_TYPE"
echo ""

# 2. Moniker present
[ -n "$MONIKER" ] && check "Moniker present" true || check "Moniker present" false

# 3. Chain ID
[ "$CHAIN_ID" = "nexarail-testnet-1" ] && check "Chain ID = nexarail-testnet-1" true || check "Chain ID = nexarail-testnet-1 (got: $CHAIN_ID)" false

# 4. Denom
[ "$DENOM" = "unxrl" ] && check "Denom = unxrl" true || check "Denom = unxrl (got: $DENOM)" false

# 5. Self-delegation amount
AMOUNT_NUM=$(echo "$AMOUNT" | tr -d '"')
[ "${AMOUNT_NUM:-0}" -ge 500000000 ] 2>/dev/null && check "Self-delegation ≥ 500,000,000 unxrl" true || check "Self-delegation ≥ 500,000,000 unxrl (got: $AMOUNT)" false

# 6. Operator address format
echo "$OP_ADDR" | grep -q "^nxrvaloper" && check "Operator address starts with nxrvaloper" true || check "Operator address starts with nxrvaloper (got: $OP_ADDR)" false

# 7. Consensus pubkey present
[ -n "$PUBKEY_KEY" ] && check "Consensus pubkey present" true || check "Consensus pubkey present" false

# 8. Pubkey type
echo "$PUBKEY_TYPE" | grep -q "ed25519" && check "Pubkey type is ed25519" true || check "Pubkey type is ed25519 (got: $PUBKEY_TYPE)" false

# 9. Message type
echo "$MSG_TYPE" | grep -q "MsgCreateValidator" && check "Message type is MsgCreateValidator" true || check "Message type is MsgCreateValidator (got: $MSG_TYPE)" false

# 10. Commission rate vs max
COMM_RATE_NUM=$(echo "$COMM_RATE" | tr -d '"')
COMM_MAX_NUM=$(echo "$COMM_MAX" | tr -d '"')
COMM_CHANGE_NUM=$(echo "$COMM_CHANGE" | tr -d '"')
python3 -c "exit(0 if float('${COMM_RATE_NUM:-0}') <= float('${COMM_MAX_NUM:-0}') else 1)" 2>/dev/null && check "Commission rate ≤ max rate" true || check "Commission rate ≤ max rate (rate=$COMM_RATE, max=$COMM_MAX)" false

# 11. Commission ranges
python3 -c "exit(0 if 0 <= float('${COMM_RATE_NUM:-0}') <= 0.20 else 1)" 2>/dev/null && check "Commission rate in range [0, 0.20]" true || check "Commission rate in range [0, 0.20] (got: $COMM_RATE)" false
python3 -c "exit(0 if 0 <= float('${COMM_MAX_NUM:-0}') <= 0.20 else 1)" 2>/dev/null && check "Max rate in range [0, 0.20]" true || check "Max rate in range [0, 0.20] (got: $COMM_MAX)" false
python3 -c "exit(0 if 0 <= float('${COMM_CHANGE_NUM:-0}') <= 0.10 else 1)" 2>/dev/null && check "Max change rate in range [0, 0.10]" true || check "Max change rate in range [0, 0.10] (got: $COMM_CHANGE)" false

# 12. Duplicate checks (if registry provided)
if [ -n "$REGISTRY" ] && [ -f "$REGISTRY" ]; then
    echo ""
    echo "  --- Duplicate checks (registry: $(basename "$REGISTRY")) ---"

    # Check duplicate moniker
    DUP_MONIKER=$(python3 -c "
import json
with open('$REGISTRY') as f:
    reg = json.load(f)
monikers = [v.get('moniker','') for v in reg.get('validators',[])]
print('DUPLICATE' if '$MONIKER' in monikers else '')
" 2>/dev/null || echo "")
    if [ "$DUP_MONIKER" = "DUPLICATE" ]; then
        check "Moniker unique (in registry)" false
    else
        check "Moniker unique (in registry)" true
    fi

    # Check duplicate pubkey
    DUP_PUBKEY=$(python3 -c "
import json
with open('$REGISTRY') as f:
    reg = json.load(f)
pubkeys = [v.get('pubkey','') for v in reg.get('validators',[])]
print('DUPLICATE' if '$PUBKEY_KEY' in pubkeys else '')
" 2>/dev/null || echo "")
    if [ "$DUP_PUBKEY" = "DUPLICATE" ]; then
        check "Pubkey unique (in registry)" false
    else
        check "Pubkey unique (in registry)" true
    fi
else
    WARN=$((WARN+2))
    echo ""
    echo "  ⚠️  No registry file provided — duplicate checks skipped"
    echo "  ⚠️  Provide a registry JSON to check duplicates"
fi

# 13. Summary
echo ""
echo "═══════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed, $WARN skipped"
if [ "$FAIL" -gt 0 ]; then
    echo "  Verdict: ❌ FAILED"
    exit 1
else
    echo "  Verdict: ✅ PASSED"
fi
echo "═══════════════════════════════════════════"
