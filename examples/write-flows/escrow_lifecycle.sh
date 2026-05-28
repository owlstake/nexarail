#!/usr/bin/env bash
# LOCAL DEVNET ONLY — NOT MAINNET
# Basic escrow lifecycle: create an escrow, then release it.
# Since escrow.live_enabled=false, no actual funds are held in escrow custody.
# This is a metadata-only demo of the escrow state machine.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RELEASE_DIR="$PROJECT_DIR/releases/testnet-rc1"

# ── Safety banner ──────────────────────────────────────────────────────────
cat <<'BANNER'
╔══════════════════════════════════════════════════════════════╗
║  LOCAL DEVNET ONLY — NOT MAINNET                           ║
║  Escrow created in metadata-only mode.                     ║
║  escrow.live_enabled=false → no fund movement.             ║
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
BUYER_KEY="wf-escrow-buyer"
SELLER_KEY="wf-escrow-seller"
ESCROW_ID="wf-escrow-$(date +%s)"

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
BUYER_ADDR=$(ensure_key "$BUYER_KEY")
SELLER_ADDR=$(ensure_key "$SELLER_KEY")
info "Buyer address:  $BUYER_ADDR"
info "Seller address: $SELLER_ADDR"

if [ "$BUYER_ADDR" = "UNKNOWN" ] || [ "$SELLER_ADDR" = "UNKNOWN" ]; then
    if [ "$EXECUTE" -eq 1 ]; then
        fail "Could not resolve keys"
        exit 1
    else
        [ "$BUYER_ADDR" = "UNKNOWN" ] && BUYER_ADDR="nxr1dryrunbuyerxxxxxxxxxxxxxxxxxxxxxxxx"
        [ "$SELLER_ADDR" = "UNKNOWN" ] && SELLER_ADDR="nxr1dryrunsellerxxxxxxxxxxxxxxxxxxxxxxx"
        info "Dry-run mode: using simulated addresses"
        info "Buyer address:  $BUYER_ADDR"
        info "Seller address: $SELLER_ADDR"
    fi
fi
pass "Keys resolved"

# ── 2. Fund buyer ───────────────────────────────────────────────────────────
step "2. Ensure buyer has funds"
BUYER_BAL=$("$BINARY" query bank balances "$BUYER_ADDR" --node "$RPC" --output json 2>/dev/null || echo '{}')
BUYER_FUNDS=$(echo "$BUYER_BAL" | jq -r '.balances // [] | map(select(.denom=="'"$DENOM"'") | .amount) | .[0] // "0"' 2>/dev/null)
info "Buyer balance: $BUYER_FUNDS$DENOM"

if [ "$BUYER_FUNDS" = "0" ] && [ "$EXECUTE" -eq 1 ]; then
    exec_or_dry "Fund buyer" "$BINARY" add-genesis-account "$BUYER_ADDR" "10000000${DENOM}" --home "$HOME_DIR"
    pass "Buyer funded"
fi

# ── 3. Create escrow ────────────────────────────────────────────────────────
step "3. Create escrow"
ESCROW_AMOUNT="1000000${DENOM}"
echo "  Escrow ID:  $ESCROW_ID"
echo "  Buyer:      $BUYER_ADDR"
echo "  Seller:     $SELLER_ADDR"
echo "  Amount:     $ESCROW_AMOUNT"
echo "  Merchant:   wf-escrow-merchant"

MERCHANT_ID="wf-escrow-merchant"
PAYMENT_REF="WriteFlow escrow test $(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [ "$EXECUTE" -eq 1 ]; then
    mkdir -p "$EVIDENCE_DIR/escrow"

    # Record before state
    "$BINARY" query escrow list --node "$RPC" --output json > "$EVIDENCE_DIR/escrow/list-before.json" 2>/dev/null || true
    "$BINARY" query escrow by-buyer "$BUYER_ADDR" --node "$RPC" --output json > "$EVIDENCE_DIR/escrow/buyer-before.json" 2>/dev/null || true

    TX_OUTPUT=$(exec_or_dry "Create escrow" "$BINARY" tx escrow create "$ESCROW_ID" "$SELLER_ADDR" "$MERCHANT_ID" "$ESCROW_AMOUNT" \
        --payment-reference "$PAYMENT_REF" \
        --memo "Created via write-flow smoke test" \
        --from "$BUYER_KEY" --keyring-backend test --home "$HOME_DIR" --chain-id "$CHAIN_ID" --node "$RPC" --fees "5000${DENOM}" --broadcast-mode sync --output json -y 2>&1 || true)
    TX_HASH=$(echo "$TX_OUTPUT" | jq -r '.txhash // empty' 2>/dev/null || echo "")
    echo "  Create tx hash: $TX_HASH"
    echo "$TX_OUTPUT" > "$EVIDENCE_DIR/escrow/create-tx.json"

    if [ -z "$TX_HASH" ]; then
        fail "Escrow create failed (no tx hash)"
    else
        sleep 2
        # Verify escrow exists
        "$BINARY" query escrow escrow "$ESCROW_ID" --node "$RPC" --output json > "$EVIDENCE_DIR/escrow/escrow.json" 2>/dev/null || true
        ESCROW_STATUS=$(jq -r '.escrow.status // .status // ""' "$EVIDENCE_DIR/escrow/escrow.json" 2>/dev/null || echo "")
        info "Escrow status: $ESCROW_STATUS"
        if [ -n "$ESCROW_STATUS" ]; then
            pass "Escrow created (status: $ESCROW_STATUS)"
        else
            fail "Escrow not found after creation"
        fi
    fi

    # ── 4. Release escrow ────────────────────────────────────────────────────
    step "4. Release escrow"
    TX_OUTPUT=$(exec_or_dry "Release escrow" "$BINARY" tx escrow release "$ESCROW_ID" \
        --from "$BUYER_KEY" --keyring-backend test --home "$HOME_DIR" --chain-id "$CHAIN_ID" --node "$RPC" --fees "5000${DENOM}" --broadcast-mode sync --output json -y 2>&1 || true)
    REL_TX_HASH=$(echo "$TX_OUTPUT" | jq -r '.txhash // empty' 2>/dev/null || echo "")
    echo "  Release tx hash: $REL_TX_HASH"
    echo "$TX_OUTPUT" > "$EVIDENCE_DIR/escrow/release-tx.json"

    if [ -n "$REL_TX_HASH" ]; then
        sleep 2
        "$BINARY" query escrow escrow "$ESCROW_ID" --node "$RPC" --output json > "$EVIDENCE_DIR/escrow/escrow-after-release.json" 2>/dev/null || true
        "$BINARY" query escrow list --node "$RPC" --output json > "$EVIDENCE_DIR/escrow/list-after.json" 2>/dev/null || true
        POST_REL_STATUS=$(jq -r '.escrow.status // .status // ""' "$EVIDENCE_DIR/escrow/escrow-after-release.json" 2>/dev/null || echo "")
        info "Escrow status after release: $POST_REL_STATUS"
        pass "Escrow release submitted (hash: $REL_TX_HASH)"
    else
        fail "Escrow release failed (no tx hash)"
    fi
else
    # Dry-run: show create + release commands
    echo "  [DRY]  $BINARY tx escrow create $ESCROW_ID $SELLER_ADDR $MERCHANT_ID $ESCROW_AMOUNT --payment-reference \"$PAYMENT_REF\" --memo \"Created via write-flow smoke test\" --from $BUYER_KEY --keyring-backend test --home $HOME_DIR --chain-id $CHAIN_ID --node $RPC --fees 5000${DENOM} -y"
    echo ""
    echo "  [DRY]  $BINARY tx escrow release $ESCROW_ID --from $BUYER_KEY --keyring-backend test --home $HOME_DIR --chain-id $CHAIN_ID --node $RPC --fees 5000${DENOM} -y"
    echo ""
    echo "  [DRY]  Would verify escrow creation and release via state queries"
    pass "Escrow lifecycle (dry-run)"
fi

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════"
echo "  Escrow Lifecycle Test"
echo "  Passed: $PASSED    Failed: $FAILED"
echo "═══════════════════════════════════════════════"
if [ "$FAILED" -gt 0 ]; then exit 1; else exit 0; fi
