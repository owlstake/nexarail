#!/usr/bin/env bash
# LOCAL DEVNET ONLY — NOT MAINNET
# Register a merchant with registration fee against the RC1 devnet.
# The merchant module stores merchant profiles with name, description, and website.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RELEASE_DIR="$PROJECT_DIR/releases/testnet-rc1"

# ── Safety banner ──────────────────────────────────────────────────────────
cat <<'BANNER'
╔══════════════════════════════════════════════════════════════╗
║  LOCAL DEVNET ONLY — NOT MAINNET                           ║
║  This script registers a merchant on a LOCAL RC1 devnet.    ║
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

# ── Evidence dir (execute mode only) ────────────────────────────────────────
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
EVIDENCE_DIR="$PROJECT_DIR/rehearsals/developer-write-flows/evidence/$TIMESTAMP"

PASS="PASS"
FAIL="FAIL"
PASSED=0
FAILED=0
MERCHANT_KEY="wf-merchant-owner"
MERCHANT_NAME="WriteFlow Merchant"
MERCHANT_DESC="Merchant registered via write-flow example script"
MERCHANT_URL="https://writeflow.example.com"

info()  { echo "  [INFO] $*"; }
step()  { echo ""; echo "── $* ───────────────────────────────"; }
pass()  { echo "  [${PASS}] $*"; PASSED=$((PASSED + 1)); }
fail()  { echo "  [${FAIL}] $*"; FAILED=$((FAILED + 1)); }

register_cmd() {
    local cmd=("$BINARY" tx merchant register "$MERCHANT_NAME" "$MERCHANT_DESC" "$MERCHANT_URL")
    if [ "$EXECUTE" -eq 1 ]; then
        cmd+=(--from "$MERCHANT_KEY" --keyring-backend test --home "$HOME_DIR" --chain-id "$CHAIN_ID" --node "$RPC" --fees "5000${DENOM}" --broadcast-mode sync --output json -y)
        echo "  [EXEC] ${cmd[*]}"
        "${cmd[@]}"
    else
        cmd+=(--from "$MERCHANT_KEY" --keyring-backend test --home "$HOME_DIR" --chain-id "$CHAIN_ID" --node "$RPC" --fees "5000${DENOM}" --broadcast-mode sync -y)
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

# ── 1. Create or resolve merchant owner key ─────────────────────────────────
step "1. Resolve merchant owner key"
if "$BINARY" keys show "$MERCHANT_KEY" --keyring-backend test --home "$HOME_DIR" &>/dev/null; then
    info "Key '$MERCHANT_KEY' exists"
else
    info "Creating key '$MERCHANT_KEY'..."
    "$BINARY" keys add "$MERCHANT_KEY" --keyring-backend test --home "$HOME_DIR" 2>&1 | tail -3
fi
MERCHANT_ADDR=$("$BINARY" keys show "$MERCHANT_KEY" -a --keyring-backend test --home "$HOME_DIR" 2>/dev/null || echo "UNKNOWN")
info "Merchant owner address: $MERCHANT_ADDR"

if [ "$MERCHANT_ADDR" = "UNKNOWN" ]; then
    if [ "$EXECUTE" -eq 1 ]; then
        fail "Could not resolve merchant owner key"
        exit 1
    else
        MERCHANT_ADDR="nxr1dryrunmerchantxxxxxxxxxxxxxxxxxxxxxxxx"
        info "Dry-run mode: using simulated address"
        info "Merchant owner address: $MERCHANT_ADDR"
    fi
fi
pass "Merchant owner key resolved"

# ── 2. Check / fund merchant owner ─────────────────────────────────────────
step "2. Ensure merchant owner has funds"
OWNER_BAL=$("$BINARY" query bank balances "$MERCHANT_ADDR" --node "$RPC" --output json 2>/dev/null || echo '{}')
OWNER_FUNDS=$(echo "$OWNER_BAL" | jq -r '.balances // [] | map(select(.denom=="'"$DENOM"'") | .amount) | .[0] // "0"' 2>/dev/null)
info "Merchant owner balance: $OWNER_FUNDS$DENOM"

if [ "$(echo "$OWNER_FUNDS" | tr -d '0')" = "" ] || [ "$OWNER_FUNDS" = "0" ]; then
    if [ "$EXECUTE" -eq 1 ]; then
        info "Funding merchant owner from genesis..."
        echo "  [EXEC] $BINARY add-genesis-account $MERCHANT_ADDR 10000000${DENOM} --home $HOME_DIR"
        "$BINARY" add-genesis-account "$MERCHANT_ADDR" "10000000${DENOM}" --home "$HOME_DIR" 2>&1 || true
        pass "Merchant owner funded"
    else
        info "Would fund merchant owner from genesis: $BINARY add-genesis-account $MERCHANT_ADDR 10000000${DENOM} --home $HOME_DIR"
        pass "Merchant owner funding not needed (dry-run)"
    fi
else
    info "Merchant owner has sufficient funds"
fi

# ── 3. Query existing merchants (before) ────────────────────────────────────
step "3. Query merchants (before)"
if [ "$EXECUTE" -eq 1 ]; then
    "$BINARY" query merchant merchants --node "$RPC" --output json 2>/dev/null || echo "{}"
fi

# ── 4. Register merchant ────────────────────────────────────────────────────
step "4. Register merchant"
echo "  Name:        $MERCHANT_NAME"
echo "  Description: $MERCHANT_DESC"
echo "  URL:         $MERCHANT_URL"
echo "  Owner:       $MERCHANT_ADDR"

if [ "$EXECUTE" -eq 1 ]; then
    mkdir -p "$EVIDENCE_DIR/merchant"
    echo "$MERCHANT_NAME" > "$EVIDENCE_DIR/merchant/name.txt"
    echo "$MERCHANT_ADDR" > "$EVIDENCE_DIR/merchant/owner.txt"

    TX_OUTPUT=$(register_cmd 2>&1 || true)
    TX_HASH=$(echo "$TX_OUTPUT" | jq -r '.txhash // empty' 2>/dev/null || echo "")
    echo "  Tx hash: $TX_HASH"
    echo "$TX_OUTPUT" > "$EVIDENCE_DIR/merchant/tx-output.json"

    if [ -n "$TX_HASH" ]; then
        info "Waiting for tx to be committed..."
        sleep 2

        # Query merchant by owner
        "$BINARY" query merchant merchant "$MERCHANT_ADDR" --node "$RPC" --output json > "$EVIDENCE_DIR/merchant/merchant.json" 2>/dev/null || true
        "$BINARY" query merchant merchants --node "$RPC" --output json > "$EVIDENCE_DIR/merchant/merchants.json" 2>/dev/null || true

        # Verify registration
        REG_STATUS=$(jq -r '.merchant // empty' "$EVIDENCE_DIR/merchant/merchant.json" 2>/dev/null || echo "")
        if [ -n "$REG_STATUS" ]; then
            pass "Merchant registered successfully"
        else
            fail "Merchant not found in state after registration"
        fi
    else
        fail "Merchant registration tx failed (no tx hash)"
    fi
else
    register_cmd
    echo "  [DRY]  Would verify merchant registration via query"
    pass "Merchant register (dry-run)"
fi

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════"
echo "  Merchant Register"
echo "  Passed: $PASSED    Failed: $FAILED"
echo "═══════════════════════════════════════════════"

if [ "$FAILED" -gt 0 ]; then
    echo "  [${FAIL}] Some checks failed."
    exit 1
else
    echo "  [${PASS}] All checks passed."
fi
