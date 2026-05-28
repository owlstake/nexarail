#!/usr/bin/env bash
# NexaRail — Run Write-Flow Examples Smoke Test
#
# Verifies all write-flow scripts exist, syntax-checks them, checks RC1 devnet
# liveness, and runs each in dry-run mode. Collects evidence.
#
# Use --execute to actually submit transactions (DANGEROUS — only on local devnet).
set -euo pipefail

# ── Safety banner ──────────────────────────────────────────────────────────
cat <<'BANNER'
╔══════════════════════════════════════════════════════════════╗
║  NexaRail — Write-Flow Examples Smoke Test                 ║
║  LOCAL DEVNET ONLY. Tokens have ZERO monetary value.        ║
╚══════════════════════════════════════════════════════════════╝
BANNER

SCRIPT_DIR="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
WRITE_FLOWS_DIR="$PROJECT_DIR/examples/write-flows"
RELEASE_DIR="$PROJECT_DIR/releases/testnet-rc1"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
EVIDENCE_DIR="$PROJECT_DIR/rehearsals/developer-write-flows/evidence/$TIMESTAMP"

RPC="${RPC:-http://127.0.0.1:26657}"
REST="${REST:-http://127.0.0.1:1317}"
EXECUTE=0

PASS=0
FAIL=0
FAILURES=""

# ── Helpers ────────────────────────────────────────────────────────────────
pass() { echo "  [PASS]  $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL]  $1"; FAIL=$((FAIL + 1)); FAILURES="${FAILURES}  FAIL: $1${2:+ ($2)}"$'\n'; }

info()  { echo "  [INFO] $*"; }
step()  { echo ""; echo "── $* ──────────────────────────────────"; }

# ── Argument handling ─────────────────────────────────────────────────────
while [ "$#" -gt 0 ]; do
    case "$1" in
        --execute) EXECUTE=1; shift ;;
        --rpc)     RPC="${2:-}"; shift 2 ;;
        --rest)    REST="${2:-}"; shift 2 ;;
        -h|--help)
            cat <<EOF
Usage: scripts/dev/run-write-flow-examples-smoke.sh [OPTIONS]

Options:
  --execute     Actually submit transactions (DANGEROUS — local devnet only)
  --rpc <url>   Override RPC endpoint (default: http://127.0.0.1:26657)
  --rest <url>  Override REST endpoint (default: http://127.0.0.1:1317)
  -h, --help    Show this help
EOF
            exit 0 ;;
        *) echo "Unknown: $1"; exit 1 ;;
    esac
done

# ── Danger warning if --execute ────────────────────────────────────────────
if [ "$EXECUTE" -eq 1 ]; then
    echo ""
    echo "  ⚠️  ⚠️  ⚠️  WARNING --execute MODE ⚠️  ⚠️  ⚠️"
    echo "  You have passed --execute. This will SUBMIT REAL TRANSACTIONS"
    echo "  to the devnet at ${RPC}."
    echo ""
    echo "  Make sure this is your LOCAL devnet, not a public network."
    echo "  Tokens have NO monetary value."
    echo ""
    echo "  Press ENTER to continue, or Ctrl-C to abort..."
    read -r
fi

# ── Write-flow scripts (ordered list — bash 3.2 compat) ──────────────────
SCRIPT_FILES=(
  bank_send_smoke.sh
  merchant_register.sh
  settlement_metadata.sh
  escrow_lifecycle.sh
  treasury_spend.sh
  payout_lifecycle.sh
  governance_toggle_demo.sh
)
SCRIPT_LABELS=(
  "Bank Send Smoke"
  "Merchant Register"
  "Settlement Metadata"
  "Escrow Lifecycle"
  "Treasury Spend"
  "Payout Lifecycle"
  "Governance Toggle Demo"
)

# Create a lookup helper
script_label() {
  local name="$1"
  for i in "${!SCRIPT_FILES[@]}"; do
    if [ "${SCRIPT_FILES[$i]}" = "$name" ]; then
      echo "${SCRIPT_LABELS[$i]}"
      return
    fi
  done
  echo "$name"
}

# ── Main ───────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Write-Flow Examples Smoke Test"
echo "  RPC:      ${RPC}"
echo "  REST:     ${REST}"
echo "  Evidence: ${EVIDENCE_DIR}"
echo "  Execute:  $([ "$EXECUTE" -eq 1 ] && echo "YES (DANGEROUS)" || echo "no (dry-run)")"
echo "═══════════════════════════════════════════════════════════════"

mkdir -p "$EVIDENCE_DIR"

# Record environment
{
    echo "RPC=${RPC}"
    echo "REST=${REST}"
    echo "Date: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "Host: $(hostname 2>/dev/null || echo 'unknown')"
    echo "Execute: ${EXECUTE}"
} > "$EVIDENCE_DIR/env.txt"

# ── Phase 1: Verify scripts exist and are syntax-clean ────────────────────
step "Phase 1: Verify script existence and syntax"

for script in "${SCRIPT_FILES[@]}"; do
    label="$(script_label "$script")"
    path="$WRITE_FLOWS_DIR/$script"

    if [ ! -f "$path" ]; then
        fail "$label" "Script not found at $path"
        continue
    fi

    if [ ! -x "$path" ]; then
        info "Making $script executable"
        chmod +x "$path"
    fi

    # Shell syntax check
    if bash -n "$path" 2>/dev/null; then
        pass "$label — syntax OK"
    else
        fail "$label" "Syntax check failed for $path"
    fi
done

# ── Phase 2: Check RC1 devnet is running ──────────────────────────────────
step "Phase 2: Check RC1 devnet liveness"

DEVNET_ALIVE=0
STATUS=$(curl -s --max-time 5 "${RPC}/status" 2>/dev/null || true)
if [ -n "$STATUS" ]; then
    HEIGHT=$(echo "$STATUS" | python3 -c "import sys,json; d=json.load(sys.stdin).get('result',{}).get('sync_info',{}); print(d.get('latest_block_height','?'))" 2>/dev/null || echo "?")
    CHAIN=$(echo "$STATUS" | python3 -c "import sys,json; d=json.load(sys.stdin).get('result',{}).get('node_info',{}); print(d.get('network','?'))" 2>/dev/null || echo "?")
    info "Devnet reachable — height=${HEIGHT}, chain=${CHAIN}"
    DEVNET_ALIVE=1

    # Record node status
    echo "$STATUS" > "$EVIDENCE_DIR/node_status.json"

    # Also check REST
    REST_OK=$(curl -s --max-time 3 "${REST}/cosmos/base/tendermint/v1beta1/node_info" 2>/dev/null | python3 -c "import sys,json; print(1 if json.load(sys.stdin).get('node') else 0)" 2>/dev/null || echo "0")
    if [ "$REST_OK" = "1" ]; then
        info "REST API reachable at ${REST}"
    else
        info "REST API not reachable at ${REST} (continuing anyway)"
    fi
else
    info "Devnet NOT reachable at ${RPC}"
    info "Scripts will run in dry-run mode but cannot execute."
fi

# Record live flags if REST is available
FLAGS_RESULT=$(curl -s --max-time 3 "${REST}/cosmos/base/tendermint/v1beta1/node_info" 2>/dev/null || echo '{}')
echo "$FLAGS_RESULT" | python3 -c "
import sys,json
d=json.load(sys.stdin)
with open('$EVIDENCE_DIR/flags.txt','w') as f:
    f.write(f'devnet_reachable: {DEVNET_ALIVE}\n')
" 2>/dev/null || echo "flags: unknown" > "$EVIDENCE_DIR/flags.txt"

# ── Phase 3: Run each write-flow script ───────────────────────────────────
step "Phase 3: Run write-flow scripts"

for script in "${SCRIPT_FILES[@]}"; do
    label="$(script_label "$script")"
    path="$WRITE_FLOWS_DIR/$script"

    if [ ! -f "$path" ]; then
        fail "$label" "Script missing"
        continue
    fi

    echo ""
    echo "  >>> Running: $script ($label)"
    echo "  ─────────────────────────────────────────────────"

    # Build args
    args=()
    if [ "$EXECUTE" -eq 1 ] && [ "$DEVNET_ALIVE" -eq 1 ]; then
        args+=(--execute)
    fi
    args+=(--rpc "$RPC")

    # Run the script and capture output
    set +e
    OUTPUT=$(bash "$path" "${args[@]}" 2>&1)
    RC=$?
    set -e

    echo "$OUTPUT" > "$EVIDENCE_DIR/${script}.log"
    echo "$OUTPUT"

    if [ "$RC" -eq 0 ]; then
        pass "$label"
    else
        fail "$label" "Exit code $RC (see ${EVIDENCE_DIR}/${script}.log)"
    fi
done

# ── Summary ────────────────────────────────────────────────────────────────
{
    echo "───────── Write-Flow Smoke Summary ──────────"
    echo "  PASS:  ${PASS}"
    echo "  FAIL:  ${FAIL}"
    echo "──────────────────────────────────────────────"
    echo "  Evidence: ${EVIDENCE_DIR}/"
    echo "  Devnet:   $([ "$DEVNET_ALIVE" -eq 1 ] && echo 'alive' || echo 'not reachable')"
    echo "  Execute:  $([ "$EXECUTE" -eq 1 ] && echo 'enabled (DANGEROUS)' || echo 'dry-run')"
} | tee "${EVIDENCE_DIR}/summary.txt"

echo ""
echo "── Evidence ──────────────────────────────────────────────────"
echo "  ${EVIDENCE_DIR}/"
echo "  ${EVIDENCE_DIR}/summary.txt"
echo ""

if [ -n "$FAILURES" ]; then
    echo "── Failures ──────────────────────────────────────────────"
    echo -n "$FAILURES"
    echo ""
fi

echo "═══════════════════════════════════════════════════════════════"

if [ "$FAIL" -gt 0 ]; then
    echo "  [FAIL] ${FAIL} failure(s) — review evidence for details."
    exit 1
else
    echo "  [PASS] All ${PASS} checks passed."
    exit 0
fi
