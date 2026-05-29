#!/usr/bin/env bash
# Verify a controlled-testnet gentx without requiring network access.
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
BINARY="${NEXARAIL_BINARY:-$PROJECT_DIR/build/nexaraild}"
CHAIN_ID="${NEXARAIL_CHAIN_ID:-nexarail-testnet-1}"
DENOM="${NEXARAIL_DENOM:-unxrl}"
MIN_SELF_DELEGATION="${MIN_SELF_DELEGATION:-500000000}"
GENTX=""

usage() {
    cat <<EOF
Usage: scripts/testnet/verify-controlled-testnet-gentx.sh <gentx.json> [options]

Options:
  --chain-id <id>      expected chain ID (default: $CHAIN_ID)
  --denom <denom>      expected self-delegation denom (default: $DENOM)
  --binary <path>      nexaraild binary for address parsing checks
  --min-amount <amt>   minimum self-delegation amount (default: $MIN_SELF_DELEGATION)
  -h, --help           show this help
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --chain-id) CHAIN_ID="$2"; shift 2 ;;
        --denom) DENOM="$2"; shift 2 ;;
        --binary) BINARY="$2"; shift 2 ;;
        --min-amount) MIN_SELF_DELEGATION="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *)
            if [ -z "$GENTX" ]; then
                GENTX="$1"
                shift
            else
                echo "Unknown argument: $1" >&2
                usage >&2
                exit 2
            fi
            ;;
    esac
done

if [ -z "$GENTX" ] || [ ! -f "$GENTX" ]; then
    usage >&2
    exit 2
fi

PASS=0
FAIL=0
WARN=0

pass() { printf 'PASS %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf 'FAIL %s\n' "$1"; FAIL=$((FAIL + 1)); }
warn() { printf 'WARN %s\n' "$1"; WARN=$((WARN + 1)); }

json_field() {
    python3 - "$GENTX" "$1" <<'PY'
import json
import sys

path = sys.argv[2].split(".")
with open(sys.argv[1]) as f:
    data = json.load(f)
cur = data
for part in path:
    if part.isdigit():
        cur = cur[int(part)]
    else:
        cur = cur.get(part, "")
print(cur if cur is not None else "")
PY
}

echo "Controlled testnet gentx verification"
echo "File: $GENTX"
echo "Expected chain ID: $CHAIN_ID"
echo "Expected denom: $DENOM"
echo ""

if python3 -m json.tool "$GENTX" >/dev/null 2>&1; then
    pass "valid JSON"
else
    fail "invalid JSON"
    echo "Summary: PASS=$PASS FAIL=$FAIL WARN=$WARN"
    exit 1
fi

MSG_TYPE="$(json_field "body.messages.0.@type" 2>/dev/null || true)"
MONIKER="$(json_field "body.messages.0.description.moniker" 2>/dev/null || true)"
MSG_CHAIN_ID="$(json_field "body.messages.0.chain_id" 2>/dev/null || true)"
AMOUNT="$(json_field "body.messages.0.value.amount" 2>/dev/null || true)"
MSG_DENOM="$(json_field "body.messages.0.value.denom" 2>/dev/null || true)"
DELEGATOR="$(json_field "body.messages.0.delegator_address" 2>/dev/null || true)"
OPERATOR="$(json_field "body.messages.0.validator_address" 2>/dev/null || true)"
PUBKEY_TYPE="$(json_field "body.messages.0.pubkey.@type" 2>/dev/null || true)"
PUBKEY_KEY="$(json_field "body.messages.0.pubkey.key" 2>/dev/null || true)"

printf 'Moniker: %s\n' "${MONIKER:-missing}"
printf 'Chain ID: %s\n' "${MSG_CHAIN_ID:-missing}"
printf 'Delegator: %s\n' "${DELEGATOR:-missing}"
printf 'Operator: %s\n' "${OPERATOR:-missing}"
printf 'Self delegation: %s%s\n' "${AMOUNT:-missing}" "${MSG_DENOM:+ $MSG_DENOM}"
printf 'Pubkey type: %s\n' "${PUBKEY_TYPE:-missing}"
echo ""

case "$MSG_TYPE" in
    *MsgCreateValidator) pass "message type is MsgCreateValidator" ;;
    *) fail "message type is not MsgCreateValidator: ${MSG_TYPE:-missing}" ;;
esac

[ -n "$MONIKER" ] && pass "validator moniker present" || fail "validator moniker missing"
if [ -n "$MSG_CHAIN_ID" ]; then
    [ "$MSG_CHAIN_ID" = "$CHAIN_ID" ] && pass "chain ID matches" || fail "chain ID mismatch: ${MSG_CHAIN_ID:-missing}"
else
    warn "chain ID not embedded in gentx JSON; collect-gentxs validates signature against genesis chain ID"
fi
[ "$MSG_DENOM" = "$DENOM" ] && pass "self-delegation denom matches" || fail "self-delegation denom mismatch: ${MSG_DENOM:-missing}"

if python3 - "$AMOUNT" "$MIN_SELF_DELEGATION" <<'PY'
import sys
try:
    amount = int(sys.argv[1])
    minimum = int(sys.argv[2])
except Exception:
    sys.exit(1)
sys.exit(0 if amount >= minimum else 1)
PY
then
    pass "self-delegation amount meets minimum"
else
    fail "self-delegation amount below minimum: ${AMOUNT:-missing}"
fi

if printf '%s\n' "$DELEGATOR" | grep -Eq '^nxr1[0-9a-z]{38,}$'; then
    pass "delegator account address format"
else
    fail "delegator account address format: ${DELEGATOR:-missing}"
fi

if printf '%s\n' "$OPERATOR" | grep -Eq '^nxrvaloper1[0-9a-z]{38,}$'; then
    pass "operator address format"
else
    fail "operator address format: ${OPERATOR:-missing}"
fi

[ -n "$PUBKEY_KEY" ] && pass "consensus pubkey present" || fail "consensus pubkey missing"
case "$PUBKEY_TYPE" in
    *ed25519*) pass "consensus pubkey type is ed25519" ;;
    *) fail "unexpected consensus pubkey type: ${PUBKEY_TYPE:-missing}" ;;
esac

if grep -Eiq 'priv_key|private_key|mnemonic|seed phrase|seed_phrase|node_key|priv_validator|BEGIN (RSA|EC|OPENSSH|PRIVATE)' "$GENTX"; then
    fail "private key material pattern found"
else
    pass "no private key material patterns"
fi

if grep -Eiq 'live_enabled|treasury_routing_enabled|burn_routing_enabled' "$GENTX"; then
    fail "unexpected product live flag field found"
else
    pass "no product live flag changes in gentx"
fi

echo ""
echo "Summary: PASS=$PASS FAIL=$FAIL WARN=$WARN"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
