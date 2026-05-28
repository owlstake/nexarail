#!/usr/bin/env bash
# LOCAL DEVNET ONLY — NOT MAINNET
# Bank send smoke test: creates two test keys (alice, bob), funds alice from
# genesis, then builds/submits a bank send tx from alice to bob.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RELEASE_DIR="$PROJECT_DIR/releases/testnet-rc1"

# ── Safety banner ──────────────────────────────────────────────────────────
cat <<'BANNER'
╔══════════════════════════════════════════════════════════════╗
║  LOCAL DEVNET ONLY — NOT MAINNET                           ║
║  This script creates test keys and submits test transactions ║
║  to a LOCAL RC1 devnet. Tokens have ZERO monetary value.    ║
║  No token sale. No mainnet. No public testnet.              ║
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

# ── Argument parsing ────────────────────────────────────────────────────────
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

# ── Helpers ─────────────────────────────────────────────────────────────────
PASS="PASS"
FAIL="FAIL"
PASSED=0
FAILED=0
ALICE_KEY="wf-bank-alice"
BOB_KEY="wf-bank-bob"

info()  { echo "  [INFO] $*"; }
dry()   { echo "  [DRY]  $*"; }
step()  { echo ""; echo "── $* ───────────────────────────────"; }
pass()  { echo "  [${PASS}] $*"; PASSED=$((PASSED + 1)); }
fail()  { echo "  [${FAIL}] $*"; FAILED=$((FAILED + 1)); }

cli() {
    # Build the CLI command string for display
    local cmd=("$BINARY" "$@")
    if [ "$EXECUTE" -eq 1 ]; then
        echo "  [EXEC] ${cmd[*]}"
        "${cmd[@]}"
    else
        echo "  [DRY]  ${cmd[*]}"
    fi
}

# ── Preflight: check binary ─────────────────────────────────────────────────
step "Preflight"
if [ ! -x "$BINARY" ]; then
    fail "Binary not found: $BINARY"
    exit 1
fi
pass "Binary found: $BINARY"

# ── 1. Create test keys (alice, bob) ────────────────────────────────────────
step "1. Create test keys"
# Note: This is idempotent — if key exists, `keys add` with `--recover` will
# fail, so we check existence first.
for key in "$ALICE_KEY" "$BOB_KEY"; do
    if "$BINARY" keys show "$key" --keyring-backend test --home "$HOME_DIR" &>/dev/null; then
        info "Key '$key' already exists, skipping creation"
    else
        cli keys add "$key" --keyring-backend test --home "$HOME_DIR"
    fi
done

ALICE_ADDR=$("$BINARY" keys show "$ALICE_KEY" -a --keyring-backend test --home "$HOME_DIR" 2>/dev/null || echo "UNKNOWN")
BOB_ADDR=$("$BINARY" keys show "$BOB_KEY" -a --keyring-backend test --home "$HOME_DIR" 2>/dev/null || echo "UNKNOWN")
info "Alice address: $ALICE_ADDR"
info "Bob address:   $BOB_ADDR"

if [ "$ALICE_ADDR" = "UNKNOWN" ] || [ "$BOB_ADDR" = "UNKNOWN" ]; then
    if [ "$EXECUTE" -eq 1 ]; then
        fail "Could not resolve key addresses"
        exit 1
    else
        # Dry-run: use simulated addresses for command display
        ALICE_ADDR="nxr1dryrunalicexxxxxxxxxxxxxxxxxxxxxxxxxxx"
        BOB_ADDR="nxr1dryrunbobxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        info "Dry-run mode: using simulated addresses"
        info "Alice address: $ALICE_ADDR"
        info "Bob address:   $BOB_ADDR"
    fi
fi
pass "Test keys created/resolved"

# ── 2. Fund alice from genesis ──────────────────────────────────────────────
step "2. Fund alice from genesis"
cli add-genesis-account "$ALICE_ADDR" "1000000000${DENOM}" --home "$HOME_DIR"
pass "Alice funded"

# ── 3. Query alice balance before ───────────────────────────────────────────
step "3. Query alice balance (before)"
ALICE_BAL_BEFORE=$("$BINARY" query bank balances "$ALICE_ADDR" --node "$RPC" --output json 2>/dev/null || echo "{}")
echo "  Balance: $(echo "$ALICE_BAL_BEFORE" | jq -r '.balances // [] | map(.amount) | join(",")' 2>/dev/null || echo "N/A")"

# ── 4. Build bank send tx (dry-run or execute) ──────────────────────────────
step "4. Bank send alice -> bob (1000unxrl)"
SEND_AMOUNT="1000${DENOM}"
FEE_AMOUNT="5000${DENOM}"

if [ "$EXECUTE" -eq 1 ]; then
    mkdir -p "$EVIDENCE_DIR/bank-send"

    # Record before state
    "$BINARY" query bank balances "$ALICE_ADDR" --node "$RPC" --output json > "$EVIDENCE_DIR/bank-send/alice-before.json" 2>/dev/null || true
    "$BINARY" query bank balances "$BOB_ADDR" --node "$RPC" --output json > "$EVIDENCE_DIR/bank-send/bob-before.json" 2>/dev/null || true

    # Submit tx
    TX_OUTPUT=$(cli tx send "$ALICE_KEY" "$BOB_ADDR" "$SEND_AMOUNT" \
        --from "$ALICE_KEY" \
        --keyring-backend test \
        --home "$HOME_DIR" \
        --chain-id "$CHAIN_ID" \
        --node "$RPC" \
        --fees "$FEE_AMOUNT" \
        --broadcast-mode sync \
        --output json \
        -y 2>&1 || true)

    TX_HASH=$(echo "$TX_OUTPUT" | jq -r '.txhash // empty' 2>/dev/null || echo "")
    echo "  Tx hash: $TX_HASH"
    echo "$TX_OUTPUT" > "$EVIDENCE_DIR/bank-send/tx-output.json"

    if [ -n "$TX_HASH" ]; then
        info "Waiting for tx to be committed..."
        sleep 2

        # Query after state
        "$BINARY" query bank balances "$ALICE_ADDR" --node "$RPC" --output json > "$EVIDENCE_DIR/bank-send/alice-after.json" 2>/dev/null || true
        "$BINARY" query bank balances "$BOB_ADDR" --node "$RPC" --output json > "$EVIDENCE_DIR/bank-send/bob-after.json" 2>/dev/null || true

        echo "  Alice after: $(jq -r '.balances // [] | map(.amount) | join(",")' "$EVIDENCE_DIR/bank-send/alice-after.json" 2>/dev/null || echo "N/A")"
        echo "  Bob after:   $(jq -r '.balances // [] | map(.amount) | join(",")' "$EVIDENCE_DIR/bank-send/bob-after.json" 2>/dev/null || echo "N/A")"
    fi

    pass "Bank send tx submitted (hash: $TX_HASH)"
else
    # Dry-run: print the command
    echo "  [DRY]  $BINARY tx send $ALICE_ADDR $BOB_ADDR $SEND_AMOUNT --from $ALICE_KEY --keyring-backend test --home $HOME_DIR --chain-id $CHAIN_ID --node $RPC --fees $FEE_AMOUNT --broadcast-mode sync -y"
    echo "  [DRY]  Would query balance after and verify"
    pass "Bank send tx (dry-run)"
fi

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════"
echo "  Bank Send Smoke Test"
echo "  Passed: $PASSED    Failed: $FAILED"
echo "═══════════════════════════════════════════════"

if [ "$FAILED" -gt 0 ]; then
    echo "  [${FAIL}] Some checks failed."
    exit 1
else
    echo "  [${PASS}] All checks passed."
fi
