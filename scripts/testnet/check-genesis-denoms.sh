#!/usr/bin/env bash
# NexaRail Genesis Denom Auditor
# Phase 17E.1 — verifies the candidate genesis denom fields all match the
# expected staking/bond denom for `nexarail-testnet-1`.
#
# Usage:
#   scripts/testnet/check-genesis-denoms.sh \
#     --genesis releases/testnet-genesis/nexarail-testnet-1-candidate/genesis.json \
#     --expected-denom unxrl \
#     [--output report.json]
#
# Exit codes:
#   0 PASS — all required denom fields match the expected denom.
#   1 FAIL — at least one required field uses the wrong denom.
#   2 usage / runtime error.
set -Eeuo pipefail

GENESIS=""
EXPECTED_DENOM="unxrl"
OUTPUT=""
SUSPICIOUS_DENOMS=("stake" "uatom" "atom" "token" "nstake")

usage() {
    cat <<EOF
Usage: scripts/testnet/check-genesis-denoms.sh [options]

Options:
  --genesis <path>              path to genesis.json to audit (required)
  --expected-denom <denom>      expected staking/bond denom (default: unxrl)
  --output <path>               optional JSON summary output path
  -h, --help                    show this help
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --genesis) GENESIS="$2"; shift 2 ;;
        --expected-denom) EXPECTED_DENOM="$2"; shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

if [ -z "$GENESIS" ]; then
    echo "ERROR: --genesis is required" >&2
    usage >&2
    exit 2
fi
if [ ! -f "$GENESIS" ]; then
    echo "ERROR: genesis file not found: $GENESIS" >&2
    exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq is required" >&2
    exit 2
fi

echo "=== NexaRail Genesis Denom Audit ==="
echo "Genesis:        $GENESIS"
echo "Expected denom: $EXPECTED_DENOM"
echo ""

PASS=0
FAIL=0
WARN=0
declare -a CHECKS=()

record() {
    # record <status> <field> <got>
    local status="$1" field="$2" got="$3"
    CHECKS+=("$status|$field|$got")
    case "$status" in
        PASS) echo "  ✅ PASS $field = $got"; PASS=$((PASS+1)) ;;
        FAIL) echo "  ❌ FAIL $field = $got (expected $EXPECTED_DENOM)"; FAIL=$((FAIL+1)) ;;
        WARN) echo "  ⚠️  WARN $field = $got"; WARN=$((WARN+1)) ;;
        SKIP) echo "  ➖ SKIP $field (not present)" ;;
    esac
}

check_required() {
    # check_required <field-label> <jq-expr>
    local label="$1" expr="$2"
    local got
    got=$(jq -r "$expr // empty" "$GENESIS")
    if [ -z "$got" ]; then
        record SKIP "$label" ""
    elif [ "$got" = "$EXPECTED_DENOM" ]; then
        record PASS "$label" "$got"
    else
        record FAIL "$label" "$got"
    fi
}

check_array_unique_denom() {
    # check_array_unique_denom <field-label> <jq-expr-returning-array-of-denoms>
    local label="$1" expr="$2"
    local denoms
    denoms=$(jq -r "[$expr] | unique | .[]" "$GENESIS" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
    if [ -z "$denoms" ]; then
        record SKIP "$label" ""
        return
    fi
    if [ "$denoms" = "$EXPECTED_DENOM" ]; then
        record PASS "$label" "$denoms"
    else
        record FAIL "$label" "$denoms"
    fi
}

echo "--- Required Denom Fields ---"

# 1. staking bond denom
check_required "staking.params.bond_denom" '.app_state.staking.params.bond_denom'

# 2. mint denom
check_required "mint.params.mint_denom" '.app_state.mint.params.mint_denom'

# 3. gov min_deposit (modern + legacy paths)
GOV_DENOMS=$(jq -r '
    [
        ( .app_state.gov.params.min_deposit // [] | .[]?.denom ),
        ( .app_state.gov.deposit_params.min_deposit // [] | .[]?.denom ),
        ( .app_state.gov.params.expedited_min_deposit // [] | .[]?.denom )
    ] | unique | .[]
' "$GENESIS" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
if [ -z "$GOV_DENOMS" ]; then
    record SKIP "gov.*min_deposit.denom" ""
elif [ "$GOV_DENOMS" = "$EXPECTED_DENOM" ]; then
    record PASS "gov.*min_deposit.denom" "$GOV_DENOMS"
else
    record FAIL "gov.*min_deposit.denom" "$GOV_DENOMS"
fi

# 4. crisis constant fee
check_required "crisis.constant_fee.denom" '.app_state.crisis.constant_fee.denom'

# 5. bank balances
check_array_unique_denom "bank.balances[].coins[].denom" \
    '.app_state.bank.balances[]?.coins[]?.denom'

# 6. bank supply
check_array_unique_denom "bank.supply[].denom" \
    '.app_state.bank.supply[]?.denom'

# 7. bank denom_metadata bases (warning if empty, error if present and wrong)
DM_COUNT=$(jq -r '(.app_state.bank.denom_metadata // []) | length' "$GENESIS")
if [ "$DM_COUNT" = "0" ]; then
    record WARN "bank.denom_metadata" "empty (consider adding ${EXPECTED_DENOM} metadata for explorers)"
else
    DM_BASES=$(jq -r '[.app_state.bank.denom_metadata[].base] | unique | .[]' "$GENESIS" | tr '\n' ',' | sed 's/,$//')
    if [ "$DM_BASES" = "$EXPECTED_DENOM" ]; then
        record PASS "bank.denom_metadata[].base" "$DM_BASES"
    else
        record FAIL "bank.denom_metadata[].base" "$DM_BASES"
    fi
fi

# 8. gentx self-delegations
check_array_unique_denom "genutil.gen_txs[*].MsgCreateValidator.value.denom" \
    '.app_state.genutil.gen_txs[]?.body.messages[]? | select((.["@type"] // "") | endswith("MsgCreateValidator")) | .value.denom'

# 9. distribution community pool
check_array_unique_denom "distribution.fee_pool.community_pool[].denom" \
    '.app_state.distribution.fee_pool.community_pool[]?.denom'

echo ""
echo "--- Suspicious Denom Scan ---"
SUSPICIOUS_HITS=""
for d in "${SUSPICIOUS_DENOMS[@]}"; do
    # Count occurrences of "stake" as an exact JSON string value (not substring).
    count=$( (grep -o "\"$d\"" "$GENESIS" || true) | wc -l | tr -d ' ' )
    if [ "$count" != "0" ]; then
        record WARN "suspicious-denom:\"$d\"" "occurs $count time(s)"
        SUSPICIOUS_HITS="$SUSPICIOUS_HITS $d:$count"
    fi
done
if [ -z "$SUSPICIOUS_HITS" ]; then
    echo "  ✅ no suspicious denom strings found"
fi

echo ""
echo "--- Summary ---"
echo "PASS=$PASS  FAIL=$FAIL  WARN=$WARN"

STATUS="PASS"
if [ "$FAIL" -gt 0 ]; then
    STATUS="FAIL"
fi
echo "Result: $STATUS"

if [ -n "$OUTPUT" ]; then
    mkdir -p "$(dirname "$OUTPUT")"
    {
        printf '{\n'
        printf '  "genesis": "%s",\n' "$GENESIS"
        printf '  "expected_denom": "%s",\n' "$EXPECTED_DENOM"
        printf '  "status": "%s",\n' "$STATUS"
        printf '  "pass": %d,\n' "$PASS"
        printf '  "fail": %d,\n' "$FAIL"
        printf '  "warn": %d,\n' "$WARN"
        printf '  "checks": [\n'
        first=1
        for line in "${CHECKS[@]}"; do
            s=${line%%|*}; rest=${line#*|}
            f=${rest%%|*}; g=${rest#*|}
            if [ "$first" = "1" ]; then first=0; else printf ',\n'; fi
            printf '    {"status": "%s", "field": "%s", "got": "%s"}' "$s" "$f" "$g"
        done
        printf '\n  ]\n}\n'
    } > "$OUTPUT"
    echo "Wrote report: $OUTPUT"
fi

if [ "$STATUS" = "FAIL" ]; then
    exit 1
fi
exit 0
