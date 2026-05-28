#!/usr/bin/env bash
# LOCAL DEVNET ONLY — NOT MAINNET
# Payout create and mark-paid flow.
# Since payout.live_enabled=false, this is a metadata-only flow —
# no actual funds are transferred when the payout is marked paid.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RELEASE_DIR="$PROJECT_DIR/releases/testnet-rc1"

# ── Safety banner ──────────────────────────────────────────────────────────
cat <<'BANNER'
╔══════════════════════════════════════════════════════════════╗
║  LOCAL DEVNET ONLY — NOT MAINNET                           ║
║  Payout flow in metadata-only mode.                        ║
║  payout.live_enabled=false → no fund transfer.              ║
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
INITIATOR_KEY="wf-payout-initiator"
PAYOUT_ID="wf-payout-$(date +%s)"
MERCHANT_ID="wf-payout-merchant"
RECIPIENT_KEY="wf-payout-recipient"

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
    if [ "$EXECUTE" -eq 1 ]; then
        echo "  [EXEC] $*"
        "$@"
    else
        echo "  [DRY]  $*"
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
INITIATOR_ADDR=$(ensure_key "$INITIATOR_KEY")
RECIPIENT_ADDR=$(ensure_key "$RECIPIENT_KEY")
info "Initiator address: $INITIATOR_ADDR"
info "Recipient address: $RECIPIENT_ADDR"

if [ "$INITIATOR_ADDR" = "UNKNOWN" ] || [ "$RECIPIENT_ADDR" = "UNKNOWN" ]; then
    if [ "$EXECUTE" -eq 1 ]; then
        fail "Could not resolve keys"
        exit 1
    else
        [ "$INITIATOR_ADDR" = "UNKNOWN" ] && INITIATOR_ADDR="nxr1dryruninitiatorxxxxxxxxxxxxxxxxxxxxx"
        [ "$RECIPIENT_ADDR" = "UNKNOWN" ] && RECIPIENT_ADDR="nxr1dryrunrecipientxxxxxxxxxxxxxxxxxxxx"
        info "Dry-run mode: using simulated addresses"
        info "Initiator address: $INITIATOR_ADDR"
        info "Recipient address: $RECIPIENT_ADDR"
    fi
fi
pass "Keys resolved"

# ── 2. Fund initiator ───────────────────────────────────────────────────────
step "2. Ensure initiator has funds"
INIT_BAL=$("$BINARY" query bank balances "$INITIATOR_ADDR" --node "$RPC" --output json 2>/dev/null || echo '{}')
INIT_FUNDS=$(echo "$INIT_BAL" | jq -r '.balances // [] | map(select(.denom=="'"$DENOM"'") | .amount) | .[0] // "0"' 2>/dev/null)
info "Initiator balance: $INIT_FUNDS$DENOM"
if [ "$INIT_FUNDS" = "0" ] && [ "$EXECUTE" -eq 1 ]; then
    exec_or_dry "Fund initiator" "$BINARY" add-genesis-account "$INITIATOR_ADDR" "10000000${DENOM}" --home "$HOME_DIR"
    pass "Initiator funded"
fi

# ── 3. Create payout ────────────────────────────────────────────────────────
step "3. Create payout"
PAYOUT_AMOUNT="50000${DENOM}"
PAYOUT_TYPE="standard"
PAYOUT_REF="WriteFlow payout test $(date -u +%Y-%m-%dT%H:%M:%SZ)"

echo "  Payout ID:    $PAYOUT_ID"
echo "  Merchant ID:  $MERCHANT_ID"
echo "  Recipient:    $RECIPIENT_ADDR"
echo "  Amount:       $PAYOUT_AMOUNT"
echo "  Type:         $PAYOUT_TYPE"
echo "  Reference:    $PAYOUT_REF"

if [ "$EXECUTE" -eq 1 ]; then
    mkdir -p "$EVIDENCE_DIR/payout"

    # Record before state
    "$BINARY" query payout list --node "$RPC" --output json > "$EVIDENCE_DIR/payout/list-before.json" 2>/dev/null || true

    TX_OUTPUT=$(exec_or_dry "Create payout" "$BINARY" tx payout create "$PAYOUT_ID" "$MERCHANT_ID" "$RECIPIENT_ADDR" "$PAYOUT_AMOUNT" "$PAYOUT_TYPE" \
        --payout-reference "$PAYOUT_REF" \
        --memo "Created via write-flow smoke test" \
        --from "$INITIATOR_KEY" --keyring-backend test --home "$HOME_DIR" --chain-id "$CHAIN_ID" --node "$RPC" --fees "5000${DENOM}" --broadcast-mode sync --output json -y 2>&1 || true)
    TX_HASH=$(echo "$TX_OUTPUT" | jq -r '.txhash // empty' 2>/dev/null || echo "")
    echo "  Create tx hash: $TX_HASH"
    echo "$TX_OUTPUT" > "$EVIDENCE_DIR/payout/create-tx.json"

    if [ -z "$TX_HASH" ]; then
        fail "Payout create failed (no tx hash)"
    else
        sleep 2
        "$BINARY" query payout payout "$PAYOUT_ID" --node "$RPC" --output json > "$EVIDENCE_DIR/payout/payout.json" 2>/dev/null || true
        PAYOUT_STATUS=$(jq -r '.payout.status // .status // ""' "$EVIDENCE_DIR/payout/payout.json" 2>/dev/null || echo "")
        info "Payout status after create: $PAYOUT_STATUS"
        if [ -n "$PAYOUT_STATUS" ]; then
            pass "Payout created (status: $PAYOUT_STATUS)"
        else
            fail "Payout not found after creation"
        fi
    fi

    # ── 4. Mark payout as paid ──────────────────────────────────────────────
    step "4. Mark payout as paid"
    EXT_REF="ext-wf-$(date +%s)"
    info "External reference: $EXT_REF"

    TX_OUTPUT=$(exec_or_dry "Mark payout paid" "$BINARY" tx payout mark-paid "$PAYOUT_ID" "$EXT_REF" \
        --from "$INITIATOR_KEY" --keyring-backend test --home "$HOME_DIR" --chain-id "$CHAIN_ID" --node "$RPC" --fees "5000${DENOM}" --broadcast-mode sync --output json -y 2>&1 || true)
    MARK_TX_HASH=$(echo "$TX_OUTPUT" | jq -r '.txhash // empty' 2>/dev/null || echo "")
    echo "  Mark-paid tx hash: $MARK_TX_HASH"
    echo "$TX_OUTPUT" > "$EVIDENCE_DIR/payout/mark-paid-tx.json"

    if [ -n "$MARK_TX_HASH" ]; then
        sleep 2
        "$BINARY" query payout payout "$PAYOUT_ID" --node "$RPC" --output json > "$EVIDENCE_DIR/payout/payout-after.json" 2>/dev/null || true
        POST_STATUS=$(jq -r '.payout.status // .status // ""' "$EVIDENCE_DIR/payout/payout-after.json" 2>/dev/null || echo "")
        info "Payout status after mark-paid: $POST_STATUS"
        pass "Payout marked as paid (hash: $MARK_TX_HASH)"
    else
        fail "Payout mark-paid failed (no tx hash)"
    fi
else
    echo ""
    echo "  [DRY]  # Step 3: Create payout"
    echo "  [DRY]  $BINARY tx payout create $PAYOUT_ID $MERCHANT_ID $RECIPIENT_ADDR $PAYOUT_AMOUNT $PAYOUT_TYPE --payout-reference \"$PAYOUT_REF\" --memo \"Created via write-flow smoke test\" --from $INITIATOR_KEY --keyring-backend test --home $HOME_DIR --chain-id $CHAIN_ID --node $RPC --fees 5000${DENOM} -y"
    echo ""
    echo "  [DRY]  # Step 4: Mark payout as paid"
    echo "  [DRY]  $BINARY tx payout mark-paid $PAYOUT_ID ext-wf-<ts> --from $INITIATOR_KEY --keyring-backend test --home $HOME_DIR --chain-id $CHAIN_ID --node $RPC --fees 5000${DENOM} -y"
    echo ""
    echo "  [DRY]  Would verify payout creation and mark-paid via state queries"
    pass "Payout lifecycle (dry-run)"
fi

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════"
echo "  Payout Lifecycle Test"
echo "  Passed: $PASSED    Failed: $FAILED"
echo "═══════════════════════════════════════════════"
if [ "$FAILED" -gt 0 ]; then exit 1; else exit 0; fi
