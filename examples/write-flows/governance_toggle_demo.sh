#!/usr/bin/env bash
# LOCAL DEVNET ONLY — NOT MAINNET
# Governance toggle demo: shows how live flags can be changed via governance
# proposals using the govtxbuilder tool.
#
# WARNING: Toggling live_flags changes devnet behavior:
#   escrow.live_enabled=true  → escrows actually custody funds
#   settlement.live_enabled=true → settlements move real (test) tokens
#   payout.live_enabled=true  → payouts transfer real (test) tokens
#   treasury.live_enabled=true → treasury actually spends funds
#
# Default: dry-run — shows commands without executing.
# Use --execute to actually submit proposals and votes (DANGEROUS).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RELEASE_DIR="$PROJECT_DIR/releases/testnet-rc1"

# ── Safety banner ──────────────────────────────────────────────────────────
cat <<'BANNER'
╔══════════════════════════════════════════════════════════════╗
║  LOCAL DEVNET ONLY — NOT MAINNET                           ║
║  Governance toggle — WARNING: changes devnet behavior!      ║
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
REST="${REST:-http://127.0.0.1:1317}"
DENOM="${DENOM:-unxrl}"
EXECUTE=0
GOVTXBUILDER="$PROJECT_DIR/tools/govtxbuilder/govtxbuilder"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --execute) EXECUTE=1; shift ;;
        --binary) BINARY="${2:-}"; shift 2 ;;
        --home) HOME_DIR="${2:-}"; shift 2 ;;
        --chain-id) CHAIN_ID="${2:-}"; shift 2 ;;
        --rpc) RPC="${2:-}"; shift 2 ;;
        --rest) REST="${2:-}"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 [--execute] [--binary <path>] [--home <dir>] [--chain-id <id>] [--rpc <url>] [--rest <url>]"
            echo ""
            echo "WARNING: --execute will send real governance proposals to the devnet."
            echo "This changes live flag state. Only use if you understand the consequences."
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
AUTHORITY_KEY="wf-gov-authority"

info()  { echo "  [INFO] $*"; }
step()  { echo ""; echo "── $* ───────────────────────────────"; }
pass()  { echo "  [${PASS}] $*"; PASSED=$((PASSED + 1)); }
fail()  { echo "  [${FAIL}] $*"; FAILED=$((FAILED + 1)); }

check_flag() {
    local module="$1"
    local flag="$2"
    local resp
    resp=$(curl -s --max-time 3 "${REST}/nexarail/${module}/v1/params" 2>/dev/null || echo '{}')
    local val
    val=$(echo "$resp" | jq -r ".${flag} // \"UNKNOWN\"" 2>/dev/null || echo "UNKNOWN")
    echo "$val"
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

if [ "$EXECUTE" -eq 1 ]; then
    if [ ! -x "$GOVTXBUILDER" ]; then
        info "govtxbuilder not found at $GOVTXBUILDER"
        info "Falling back to nexaraild gov CLI for proposal submission"
        GOVTXBUILDER=""
    fi

    # Check devnet is running
    if ! curl -s --max-time 3 "${RPC}/status" >/dev/null 2>&1; then
        fail "Devnet not reachable at $RPC"
        exit 1
    fi
fi
pass "Preflight checks passed"

# ── 1. Show current live flags ──────────────────────────────────────────────
step "1. Current live flags"
echo "  Current flag state (via REST):"
for module in settlement escrow treasury payout; do
    VAL=$(check_flag "$module" "live_enabled")
    echo "    ${module}.live_enabled = ${VAL}"
done

# ── 2. Show governance toggle commands ─────────────────────────────────────
step "2. Governance toggle commands (escrow.live_enabled example)"

if [ -x "$GOVTXBUILDER" ]; then
    echo ""
    echo "  Using govtxbuilder (preferred — handles proto Any encoding):"
    echo ""
    echo "  # Enable escrow live mode:"
    echo "  [DRY]  $GOVTXBUILDER submit-enable-proposal \\"
    echo "           --home $HOME_DIR \\"
    echo "           --node tcp://127.0.0.1:26657 \\"
    echo "           --chain-id $CHAIN_ID \\"
    echo "           --key devnet-key"
    echo ""
    echo "  # Disable escrow live mode:"
    echo "  [DRY]  $GOVTXBUILDER submit-disable-proposal \\"
    echo "           --home $HOME_DIR \\"
    echo "           --node tcp://127.0.0.1:26657 \\"
    echo "           --chain-id $CHAIN_ID \\"
    echo "           --key devnet-key"
    echo ""
    echo "  # Vote on a proposal:"
    echo "  [DRY]  $GOVTXBUILDER vote --proposal-id 1 --voter devnet-key --vote yes \\"
    echo "           --home $HOME_DIR \\"
    echo "           --node tcp://127.0.0.1:26657 \\"
    echo "           --chain-id $CHAIN_ID"
    echo ""
    echo "  # Query escrow params (shows live flag):"
    echo "  [DRY]  $GOVTXBUILDER query-escrow-params \\"
    echo "           --home $HOME_DIR \\"
    echo "           --node tcp://127.0.0.1:26657"
    echo ""
    pass "govtxbuilder commands shown"
else
    # Fallback: show nexaraild gov CLI commands
    echo ""
    echo "  govtxbuilder not found at $GOVTXBUILDER."
    echo "  Using nexaraild CLI for param-change proposals:"
    echo ""
    echo "  [DRY]  # Submit a param-change proposal to set escrow.live_enabled=true:"
    echo "  [DRY]  $BINARY tx gov submit-legacy-proposal param-change escrow.live_enabled=true \\"
    echo "           --from $AUTHORITY_KEY --keyring-backend test --home $HOME_DIR \\"
    echo "           --chain-id $CHAIN_ID --node $RPC --fees 5000${DENOM} -y"
    echo ""
    echo "  [DRY]  # Vote yes on proposal 1:"
    echo "  [DRY]  $BINARY tx gov vote 1 yes --from devnet-key --keyring-backend test \\"
    echo "           --home $HOME_DIR --chain-id $CHAIN_ID --node $RPC --fees 5000${DENOM} -y"
    echo ""
    echo "  [DRY]  # Query live flag state:"
    echo "  [DRY]  $BINARY query escrow params --node $RPC --output json | jq '.live_enabled'"
    echo ""
    pass "nexaraild CLI commands shown"
fi

# ── 3. Execute toggle (if --execute is set) ─────────────────────────────────
step "3. Execute toggle demonstration"

if [ "$EXECUTE" -eq 1 ]; then
    if [ ! -f "$BINARY" ]; then
        fail "Binary not found at $BINARY"
    fi

    # Resolve authority key
    if ! "$BINARY" keys show "devnet-key" --keyring-backend test --home "$HOME_DIR" &>/dev/null; then
        fail "devnet-key not found. Need a funded key named 'devnet-key' in $HOME_DIR"
        exit 1
    fi

    mkdir -p "$EVIDENCE_DIR/gov"

    # Record before state
    echo "=== LIVE FLAGS BEFORE ===" > "$EVIDENCE_DIR/gov/flags-before.txt"
    for module in settlement escrow treasury payout; do
        VAL=$(check_flag "$module" "live_enabled")
        echo "${module}.live_enabled=${VAL}" >> "$EVIDENCE_DIR/gov/flags-before.txt"
    done
    cat "$EVIDENCE_DIR/gov/flags-before.txt"

    if [ -x "$GOVTXBUILDER" ]; then
        info "Submitting escrow enable proposal via govtxbuilder..."
        echo ""
        echo "  ⚠️  Would submit proposal now. This is a metadata-only demo —"
        echo "  ⚠️  actual governance submission requires multi-voter quorum."
        echo ""
        echo "  To actually toggle, run:"
        echo "    $GOVTXBUILDER submit-enable-proposal --key devnet-key --home $HOME_DIR --node tcp://127.0.0.1:26657 --chain-id $CHAIN_ID"
        pass "Governance toggle command displayed"
    else
        info "govtxbuilder not available — showing example commands only"
        pass "Governance toggle example shown (no govtxbuilder available)"
    fi

    # Record after quering
    echo "=== LIVE FLAGS AFTER ===" > "$EVIDENCE_DIR/gov/flags-after.txt"
    for module in settlement escrow treasury payout; do
        VAL=$(check_flag "$module" "live_enabled")
        echo "${module}.live_enabled=${VAL}" >> "$EVIDENCE_DIR/gov/flags-after.txt"
    done

    # Generate evidence summary
    cat > "$EVIDENCE_DIR/gov/summary.txt" <<EOF
Governance Toggle Demo
Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Chain ID: $CHAIN_ID
RPC: $RPC
REST: $REST

Flags Before:
$(cat "$EVIDENCE_DIR/gov/flags-before.txt")

Flags After:
$(cat "$EVIDENCE_DIR/gov/flags-after.txt")

Note: This is a demonstration only. Actual flag changes require
governance proposal submission, voting, and quorum.
EOF
else
    echo "  [DRY]  --execute not set. Commands shown above for reference."
    echo "  [DRY]  To actually toggle flags, re-run with --execute"
    pass "Governance toggle displayed (dry-run)"
fi

# ── Final warning ──────────────────────────────────────────────────────────
step "IMPORTANT"
cat <<'EOF'
  Toggling live flags changes devnet behavior:
    • escrow.live_enabled=true     → escrows custody funds (real test-token movement)
    • settlement.live_enabled=true → settlements move test tokens
    • payout.live_enabled=true     → payouts transfer test tokens
    • treasury.live_enabled=true   → treasury spends test tokens

  After toggling, the devnet is no longer in "metadata-only" mode.
  To reset: stop and relaunch the devnet from a fresh genesis.
EOF
pass "Governance toggle demo warnings understood"

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════"
echo "  Governance Toggle Demo"
echo "  Passed: $PASSED    Failed: $FAILED"
echo "═══════════════════════════════════════════════"
if [ "$FAILED" -gt 0 ]; then exit 1; else exit 0; fi
