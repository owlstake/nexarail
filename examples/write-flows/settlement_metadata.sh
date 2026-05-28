#!/usr/bin/env bash
# LOCAL DEVNET ONLY — NOT MAINNET
# Create a settlement record in metadata-only mode.
# Since settlement.live_enabled=false, no actual funds move — the settlement
# is recorded as a metadata entry in the module state.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RELEASE_DIR="$PROJECT_DIR/releases/testnet-rc1"

# ── Safety banner ──────────────────────────────────────────────────────────
cat <<'BANNER'
╔══════════════════════════════════════════════════════════════╗
║  LOCAL DEVNET ONLY — NOT MAINNET                           ║
║  Settlement record created in metadata-only mode.           ║
║  live_enabled=false → no actual fund movement.              ║
║  Tokens have ZERO monetary value. No token sale.            ║
╚══════════════════════════════════════════════════════════════╝
BANNER

# ── OS detection ────────────────────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
    Darwin) DEFAULT_BINARY="$RELEASE_DIR/binaries/nexaraild-darwin-arm64" ;;
    Linux)  DEFAULT_BINARY="$RELEASE_DIR/binaries/nexaraild-linux-amd64"  ;;
    *)      echo "Unsupported OS: $OS"; exit 1 ;;
esac

# ── Defaults ────────────────────────────────────────────────────────────────
BINARY="${BINARY:-$DEFAULT_BINARY}"
HOME_DIR="${HOME_DIR:-$HOME/.nexarail-devnet}"
CHAIN_ID="${CHAIN_ID:-nexarail-devnet-1}"
RPC="${RPC:-http://127.0.0.1:26657}"
DENOM="${DENOM:-unxrl}"
EXECUTE=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --execute) EXECUTE=1; shift ;;
        --binary) BINARY="${2:-}"; shift 2 ;;
        --home) HOME_DIR="${2:-}"; shift 2 ;;
        --chain-id) CHAIN_ID="${2:-}"; shift 2 ;;
        --rpc) RPC="${2:-}"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 [--execute] [--binary <path>] [--home <dir>] [--chain-id <id>] [--rpc <url>]"
            exit 0 ;;
        *) echo "Unknown: $1"; exit 1 ;;
    esac
done

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
EVIDENCE_DIR="$PROJECT_DIR/rehearsals/developer-write-flows/evidence/$TIMESTAMP"

PASS="PASS"
FAIL="FAIL"
PASSED=0
FAILED=0
PAYER_KEY="wf-settlement-payer"
MERCHANT_KEY="wf-settlement-merchant"

info()  { echo "  [INFO] $*"; }
step()  { echo ""; echo "── $* ───────────────────────────────"; }
pass()  { echo "  [${PASS}] $*"; PASSED=$((PASSED + 1)); }
fail()  { echo "  [${FAIL}] $*"; FAILED=$((FAILED + 1)); }

ensure_key() {
    local key="$1"
    if "$BINARY" keys show "$key" --keyring-backend test --home "$HOME_DIR" &>/dev/null; then
        info "Key '$key' exists"
    else
        info "Creating key '$key'..."
        "$BINARY" keys add "$key" --keyring-backend test --home "$HOME_DIR" 2>&1 | tail -3
    fi
    local addr
    addr=$("$BINARY" keys show "$key" -a --keyring-backend test --home "$HOME_DIR" 2>/dev/null || echo "UNKNOWN")
    echo "$addr"
}

exec_or_dry() {
    local label="$1"
    shift
    local cmd=("$@")
    if [ "$EXECUTE" -eq 1 ]; then
        echo "  [EXEC] ${cmd[*]}"
        "${cmd[@]}"
    else
        echo "  [DRY]  ${cmd[*]}"
    fi
}

# ── Preflight ───────────────────────────────────────────────────────────────
step "Preflight"
if [ ! -x "$BINARY" ]; then
    fail "Binary not found: $BINARY"
    exit 1
fi
pass "Binary found: $BINARY"

# ── 1. Resolve keys ─────────────────────────────────────────────────────────
step "1. Resolve keys"
PAYER_ADDR=$(ensure_key "$PAYER_KEY")
MERCHANT_ADDR=$(ensure_key "$MERCHANT_KEY")
info "Payer address:    $PAYER_ADDR"
info "Merchant address: $MERCHANT_ADDR"

if [ "$PAYER_ADDR" = "UNKNOWN" ] || [ "$MERCHANT_ADDR" = "UNKNOWN" ]; then
    if [ "$EXECUTE" -eq 1 ]; then
        fail "Could not resolve keys"
        exit 1
    else
        [ "$PAYER_ADDR" = "UNKNOWN" ] && PAYER_ADDR="nxr1dryrunpayerxxxxxxxxxxxxxxxxxxxxxxxxx"
        [ "$MERCHANT_ADDR" = "UNKNOWN" ] && MERCHANT_ADDR="nxr1dryrunmerchantxxxxxxxxxxxxxxxxxxxxx"
        info "Dry-run mode: using simulated addresses"
        info "Payer address:    $PAYER_ADDR"
        info "Merchant address: $MERCHANT_ADDR"
    fi
fi
pass "Keys resolved"

# ── 2. Check / fund payer ──────────────────────────────────────────────────
step "2. Check payer funds"
PAYER_BAL=$("$BINARY" query bank balances "$PAYER_ADDR" --node "$RPC" --output json 2>/dev/null || echo '{}')
PAYER_FUNDS=$(echo "$PAYER_BAL" | jq -r '.balances // [] | map(select(.denom=="'"$DENOM"'") | .amount) | .[0] // "0"' 2>/dev/null)
info "Payer balance: $PAYER_FUNDS$DENOM"
if [ "$PAYER_FUNDS" = "0" ] && [ "$EXECUTE" -eq 1 ]; then
    info "Funding payer from genesis..."
    exec_or_dry "Fund payer" "$BINARY" add-genesis-account "$PAYER_ADDR" "10000000${DENOM}" --home "$HOME_DIR"
    pass "Payer funded"
fi

# ── 3. Register a merchant for settlement ───────────────────────────────────
step "3. Ensure merchant exists"
if [ "$EXECUTE" -eq 1 ]; then
    # Check if the merchant key already has a registered merchant
    MERCHANT_CHECK=$("$BINARY" query merchant merchant "$MERCHANT_ADDR" --node "$RPC" --output json 2>/dev/null || echo '{}')
    MERCHANT_EXISTS=$(echo "$MERCHANT_CHECK" | jq -r '.merchant.owner // empty' 2>/dev/null || echo "")
    if [ -n "$MERCHANT_EXISTS" ]; then
        info "Merchant already registered for $MERCHANT_ADDR"
    else
        info "Registering merchant for settlement..."
        exec_or_dry "Register merchant" "$BINARY" tx merchant register "Settlement Merchant" "Merchant for settlement metadata test" "https://settlement.example.com" \
            --from "$MERCHANT_KEY" --keyring-backend test --home "$HOME_DIR" --chain-id "$CHAIN_ID" --node "$RPC" --fees "5000${DENOM}" --broadcast-mode sync -y
        sleep 2
    fi
    pass "Merchant ready"
else
    info "Would register merchant if not already registered"
    pass "Merchant readiness (dry-run)"
fi

# ── 4. Create settlement record ─────────────────────────────────────────────
step "4. Create settlement record"
SETTLEMENT_METADATA="WriteFlow settlement test $(date -u +%Y-%m-%dT%H:%M:%SZ)"
SETTLEMENT_AMOUNT="5000000${DENOM}"

echo "  Payer:    $PAYER_ADDR"
echo "  Merchant: $MERCHANT_ADDR"
echo "  Amount:   $SETTLEMENT_AMOUNT"
echo "  Metadata: $SETTLEMENT_METADATA"

if [ "$EXECUTE" -eq 1 ]; then
    mkdir -p "$EVIDENCE_DIR/settlement"

    # Record before state
    "$BINARY" query bank balances "$PAYER_ADDR" --node "$RPC" --output json > "$EVIDENCE_DIR/settlement/payer-before.json" 2>/dev/null || true
    "$BINARY" query settlement list --node "$RPC" --output json > "$EVIDENCE_DIR/settlement/list-before.json" 2>/dev/null || true

    TX_OUTPUT=$(exec_or_dry "Create settlement" "$BINARY" tx settlement create "$MERCHANT_ADDR" "$SETTLEMENT_AMOUNT" \
        --metadata "$SETTLEMENT_METADATA" \
        --from "$PAYER_KEY" --keyring-backend test --home "$HOME_DIR" --chain-id "$CHAIN_ID" --node "$RPC" --fees "5000${DENOM}" --broadcast-mode sync --output json -y 2>&1 || true)
    TX_HASH=$(echo "$TX_OUTPUT" | jq -r '.txhash // empty' 2>/dev/null || echo "")
    echo "  Tx hash: $TX_HASH"
    echo "$TX_OUTPUT" > "$EVIDENCE_DIR/settlement/tx-output.json"

    if [ -n "$TX_HASH" ]; then
        sleep 2
        "$BINARY" query bank balances "$PAYER_ADDR" --node "$RPC" --output json > "$EVIDENCE_DIR/settlement/payer-after.json" 2>/dev/null || true
        "$BINARY" query settlement list --node "$RPC" --output json > "$EVIDENCE_DIR/settlement/list-after.json" 2>/dev/null || true
        "$BINARY" query settlement by-payer "$PAYER_ADDR" --node "$RPC" --output json > "$EVIDENCE_DIR/settlement/payer-settlements.json" 2>/dev/null || true

        # Since live_enabled=false, payer balance should NOT have decreased
        # Verify settlement exists in state
        SETTLEMENT_COUNT=$(jq -r '.settlements // [] | length' "$EVIDENCE_DIR/settlement/list-after.json" 2>/dev/null || echo "0")
        if [ "$SETTLEMENT_COUNT" -gt 0 ]; then
            pass "Settlement record created (count: $SETTLEMENT_COUNT)"
        else
            fail "No settlement records found after creation"
        fi
    else
        fail "Settlement creation tx failed (no tx hash)"
    fi
else
    echo "  [DRY]  $BINARY tx settlement create $MERCHANT_ADDR $SETTLEMENT_AMOUNT --metadata \"$SETTLEMENT_METADATA\" --from $PAYER_KEY --keyring-backend test --home $HOME_DIR --chain-id $CHAIN_ID --node $RPC --fees 5000${DENOM} --broadcast-mode sync -y"
    echo "  [DRY]  Would verify settlement record exists in state"
    pass "Settlement create (dry-run)"
fi

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════"
echo "  Settlement Metadata Test"
echo "  Passed: $PASSED    Failed: $FAILED"
echo "═══════════════════════════════════════════════"
if [ "$FAILED" -gt 0 ]; then exit 1; else exit 0; fi
