#!/usr/bin/env bash
# LOCAL DEVNET ONLY — NOT MAINNET
# Treasury spend request flow.
# Since treasury.live_enabled=false, this is a metadata-only spend request —
# no actual funds are withdrawn from the treasury module account.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RELEASE_DIR="$PROJECT_DIR/releases/testnet-rc1"

# ── Safety banner ──────────────────────────────────────────────────────────
cat <<'BANNER'
╔══════════════════════════════════════════════════════════════╗
║  LOCAL DEVNET ONLY — NOT MAINNET                           ║
║  Treasury spend request in metadata-only mode.              ║
║  treasury.live_enabled=false → no actual spend.             ║
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
AUTHORITY_KEY="wf-treasury-auth"
SPEND_ID="wf-spend-$(date +%s)"
ACCOUNT_ID="wf-treasury-acct-$(date +%s)"

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

# ── 1. Resolve authority key ────────────────────────────────────────────────
step "1. Resolve authority key"
AUTH_ADDR=$(ensure_key "$AUTHORITY_KEY")
info "Authority address: $AUTH_ADDR"

if [ "$AUTH_ADDR" = "UNKNOWN" ]; then
    if [ "$EXECUTE" -eq 1 ]; then
        fail "Could not resolve authority key"
        exit 1
    else
        AUTH_ADDR="nxr1dryrunauthorityxxxxxxxxxxxxxxxxxxxxxxxx"
        info "Dry-run mode: using simulated address"
        info "Authority address: $AUTH_ADDR"
    fi
fi
pass "Authority key resolved"

# ── 2. Fund authority ──────────────────────────────────────────────────────
step "2. Ensure authority has funds"
AUTH_BAL=$("$BINARY" query bank balances "$AUTH_ADDR" --node "$RPC" --output json 2>/dev/null || echo '{}')
AUTH_FUNDS=$(echo "$AUTH_BAL" | jq -r '.balances // [] | map(select(.denom=="'"$DENOM"'") | .amount) | .[0] // "0"' 2>/dev/null)
info "Authority balance: $AUTH_FUNDS$DENOM"
if [ "$AUTH_FUNDS" = "0" ] && [ "$EXECUTE" -eq 1 ]; then
    exec_or_dry "Fund authority" "$BINARY" add-genesis-account "$AUTH_ADDR" "10000000${DENOM}" --home "$HOME_DIR"
    pass "Authority funded"
fi

if [ "$EXECUTE" -eq 1 ]; then
    mkdir -p "$EVIDENCE_DIR/treasury"

    # ── 3. Create treasury account ──────────────────────────────────────────
    step "3. Create treasury account"
    info "Creating treasury account: $ACCOUNT_ID"
    TX_OUTPUT=$(exec_or_dry "Create treasury account" "$BINARY" tx treasury create-account "$ACCOUNT_ID" "Treasury Account for write-flow demo" \
        --from "$AUTHORITY_KEY" --keyring-backend test --home "$HOME_DIR" --chain-id "$CHAIN_ID" --node "$RPC" --fees "5000${DENOM}" --broadcast-mode sync --output json -y 2>&1 || true)
    ACCT_TX_HASH=$(echo "$TX_OUTPUT" | jq -r '.txhash // empty' 2>/dev/null || echo "")
    echo "  Account create tx hash: $ACCT_TX_HASH"
    echo "$TX_OUTPUT" > "$EVIDENCE_DIR/treasury/account-create.json"

    if [ -n "$ACCT_TX_HASH" ]; then
        sleep 2
        "$BINARY" query treasury account "$ACCOUNT_ID" --node "$RPC" --output json > "$EVIDENCE_DIR/treasury/account.json" 2>/dev/null || true
        ACCT_EXISTS=$(jq -r '.account.id // .account_id // ""' "$EVIDENCE_DIR/treasury/account.json" 2>/dev/null || echo "")
        if [ -n "$ACCT_EXISTS" ]; then pass "Treasury account created"; else fail "Treasury account not found"; fi
    else
        fail "Treasury account creation failed"
    fi

    # ── 4. Create spend request ─────────────────────────────────────────────
    step "4. Create spend request"
    RECIPIENT="$AUTH_ADDR"  # spend back to authority
    SPEND_AMOUNT="100000${DENOM}"
    SPEND_PURPOSE="WriteFlow treasury spend demo"
    info "Spend ID: $SPEND_ID"
    info "Account:  $ACCOUNT_ID"
    info "Recipient: $RECIPIENT"
    info "Amount:   $SPEND_AMOUNT"

    TX_OUTPUT=$(exec_or_dry "Create spend request" "$BINARY" tx treasury create-spend "$SPEND_ID" "$ACCOUNT_ID" "$RECIPIENT" "$SPEND_AMOUNT" "$SPEND_PURPOSE" \
        --from "$AUTHORITY_KEY" --keyring-backend test --home "$HOME_DIR" --chain-id "$CHAIN_ID" --node "$RPC" --fees "5000${DENOM}" --broadcast-mode sync --output json -y 2>&1 || true)
    SPEND_TX_HASH=$(echo "$TX_OUTPUT" | jq -r '.txhash // empty' 2>/dev/null || echo "")
    echo "  Spend create tx hash: $SPEND_TX_HASH"
    echo "$TX_OUTPUT" > "$EVIDENCE_DIR/treasury/spend-create.json"

    if [ -n "$SPEND_TX_HASH" ]; then
        sleep 2
        "$BINARY" query treasury spend "$SPEND_ID" --node "$RPC" --output json > "$EVIDENCE_DIR/treasury/spend.json" 2>/dev/null || true
        "$BINARY" query treasury spends --node "$RPC" --output json > "$EVIDENCE_DIR/treasury/spends.json" 2>/dev/null || true
        "$BINARY" query treasury summary --node "$RPC" --output json > "$EVIDENCE_DIR/treasury/summary.json" 2>/dev/null || true
        SPEND_STATUS=$(jq -r '.spend.status // .status // ""' "$EVIDENCE_DIR/treasury/spend.json" 2>/dev/null || echo "")
        if [ -n "$SPEND_STATUS" ]; then pass "Treasury spend request created (status: $SPEND_STATUS)"; else fail "Spend request not found"; fi
    else
        fail "Treasury spend request failed"
    fi
else
    echo ""
    echo "  [DRY]  # Step 3: Create treasury account"
    echo "  [DRY]  $BINARY tx treasury create-account $ACCOUNT_ID \"Treasury Account for write-flow demo\" --from $AUTHORITY_KEY --keyring-backend test --home $HOME_DIR --chain-id $CHAIN_ID --node $RPC --fees 5000${DENOM} -y"
    echo ""
    echo "  [DRY]  # Step 4: Create spend request"
    echo "  [DRY]  $BINARY tx treasury create-spend $SPEND_ID $ACCOUNT_ID $AUTH_ADDR 100000${DENOM} \"WriteFlow treasury spend demo\" --from $AUTHORITY_KEY --keyring-backend test --home $HOME_DIR --chain-id $CHAIN_ID --node $RPC --fees 5000${DENOM} -y"
    echo ""
    echo "  [DRY]  Would verify treasury account and spend request via state queries"
    pass "Treasury spend (dry-run)"
fi

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════"
echo "  Treasury Spend Test"
echo "  Passed: $PASSED    Failed: $FAILED"
echo "═══════════════════════════════════════════════"
if [ "$FAILED" -gt 0 ]; then exit 1; else exit 0; fi
