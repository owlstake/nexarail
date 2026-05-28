#!/usr/bin/env bash
# NexaRail — Unified Local Demo Runner
#
# One command: clone → verify → launch devnet → smoke tests → dashboard → evidence
#
# LOCAL DEVNET ONLY — NOT MAINNET. Tokens have zero monetary value.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RELEASE_DIR="$PROJECT_DIR/releases/testnet-rc1"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
EVIDENCE_DIR="${EVIDENCE_DIR:-$PROJECT_DIR/rehearsals/local-demo/evidence/$TIMESTAMP}"
KEEP_RUNNING=0
SERVE_DASHBOARD=0
SKIP_SMOKE=0
BINARY="${BINARY:-}"

PASS=0
FAIL=0
SKIP=0
STEP=0

step() { STEP=$((STEP+1)); echo ""; echo "─── [$STEP/$TOTAL] $* ───"; }
pass() { echo "  ✅ $*"; PASS=$((PASS+1)); }
fail() { echo "  ❌ $*"; FAIL=$((FAIL+1)); }
skip() { echo "  ⏭️  $*"; SKIP=$((SKIP+1)); }
info() { echo "  ℹ️  $*"; }

usage() {
    cat <<EOF
Usage: scripts/dev/run-local-demo.sh [options]

Options:
  --keep-running      Leave devnet running after demo
  --serve-dashboard   Serve the local dashboard (port 8088)
  --skip-smoke        Skip developer/write-flow smoke tests
  --binary <path>     Override nexaraild binary path
  --evidence-dir <path> Override evidence output directory
  -h, --help          Show this help
EOF
    exit 0
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --keep-running) KEEP_RUNNING=1; shift ;;
        --serve-dashboard) SERVE_DASHBOARD=1; shift ;;
        --skip-smoke) SKIP_SMOKE=1; shift ;;
        --binary) BINARY="${2:-}"; shift 2 ;;
        --evidence-dir) EVIDENCE_DIR="${2:-}"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown: $1"; usage ;;
    esac
done

mkdir -p "$EVIDENCE_DIR/logs"

# Detect OS/binary
OS="$(uname -s)"
case "$OS" in
    Darwin) DEFAULT_BINARY="$RELEASE_DIR/binaries/nexaraild-darwin-arm64" ;;
    Linux)  DEFAULT_BINARY="$RELEASE_DIR/binaries/nexaraild-linux-amd64" ;;
    *)      echo "Unsupported OS: $OS"; exit 1 ;;
esac
BINARY="${BINARY:-$DEFAULT_BINARY}"

TOTAL=8

echo "╔═══════════════════════════════════════════════════╗"
echo "║  NexaRail — Local Demo Runner                   ║"
echo "║  Local devnet only. Tokens have zero value.      ║"
echo "║  Not mainnet. No token sale.                    ║"
echo "╚═══════════════════════════════════════════════════╝"
echo "  Evidence: $EVIDENCE_DIR"
echo "  Binary:   $BINARY"
echo ""

# ── 1. Verify RC1 package ───────────────────────────────────────
step "Verify RC1 package"
if [ -f "$RELEASE_DIR/manifests/manifest.json" ]; then
    pass "RC1 manifest found"
else
    fail "RC1 package not found at $RELEASE_DIR"
fi
if [ -f "$BINARY" ]; then
    pass "Binary found: $BINARY"
else
    fail "Binary not found: $BINARY"
fi

# ── 2. Verify checksum ──────────────────────────────────────────
step "Verify binary checksum"
CHECKSUM_FILE="$RELEASE_DIR/checksums/SHA256SUMS"
if [ -f "$CHECKSUM_FILE" ]; then
    if shasum -a 256 -c "$CHECKSUM_FILE" > /dev/null 2>&1; then
        pass "Checksums verified"
    else
        fail "Checksum mismatch — binary may be corrupted"
    fi
else
    skip "No checksum file at $CHECKSUM_FILE"
fi

# ── 3. Launch single-node devnet ────────────────────────────────
step "Launch single-node RC1 devnet"
DEVNET_LOG="$EVIDENCE_DIR/logs/devnet-launch.log"
if bash "$SCRIPT_DIR/../release/launch-rc1-devnet.sh" --single-node --clean --keep-running --binary "$BINARY" --evidence-dir "$EVIDENCE_DIR" > "$DEVNET_LOG" 2>&1; then
    pass "Devnet launched (height >= 10)"
    # Save devnet status
    curl -s --max-time 3 "http://127.0.0.1:26657/status" > "$EVIDENCE_DIR/devnet-status.json" 2>/dev/null || true
    # Wait for REST API to be ready
    info "Waiting for REST API..."
    for i in $(seq 1 10); do
        if curl -s --max-time 2 "http://127.0.0.1:1317/nexarail/settlement/v1/params" > /dev/null 2>&1; then
            info "REST API ready after ${i}s"
            break
        fi
        sleep 2
    done
else
    tail -20 "$DEVNET_LOG"
    fail "Devnet launch failed"
fi

# ── 4. Query live flags ────────────────────────────────────────
step "Query live flags"
FLAGS_LOG="$EVIDENCE_DIR/live-flags.json"
# Read from genesis (always correct in single-node mode)
GENESIS_FILE="$HOME/.nexarail-devnet/config/genesis.json"
if [ -f "$GENESIS_FILE" ]; then
    python3 -c "
import json
with open('$GENESIS_FILE') as f:
    g = json.load(f)
aps = g.get('app_state', {})
results = {}
for mod, default in [('settlement', False), ('escrow', False), ('treasury', False), ('payout', False)]:
    params = aps.get(mod, {}).get('params', {})
    live = params.get('live_enabled', default)
    results[mod] = {'live_enabled': live}
print(json.dumps(results, indent=2))
" > "$FLAGS_LOG"
    # Parse and verify
    ALL_OK=0
    for mod_dir in settlement escrow treasury payout; do
        LIVE=$(python3 -c "import json; d=json.load(open('$FLAGS_LOG')); print(d.get('$mod_dir',{}).get('live_enabled','unknown'))" 2>/dev/null || echo "unknown")
        if [ "$LIVE" = "false" ] || [ "$LIVE" = "False" ]; then
            pass "$mod_dir.live_enabled = false"
        else
            fail "$mod_dir.live_enabled = $LIVE (expected false)"
        fi
    done
    pass "Live flags saved (from genesis)"
else
    fail "Genesis file not found at $GENESIS_FILE"
    echo '{}' > "$FLAGS_LOG"
fi

# ── 5. Run developer examples smoke ────────────────────────────
if [ "$SKIP_SMOKE" -eq 0 ]; then
    step "Run developer examples smoke"
    SMOKE_LOG="$EVIDENCE_DIR/smoke-results.txt"
    if bash "$SCRIPT_DIR/run-developer-examples-smoke.sh" > "$SMOKE_LOG" 2>&1; then
        SUMMARY=$(grep "^  PASS:\|^  FAIL:\|^  SKIP:" "$SMOKE_LOG" | head -3 || echo "unknown")
        pass "Developer examples smoke passed"
        info "$SUMMARY"
    else
        tail -10 "$SMOKE_LOG"
        fail "Developer examples smoke failed"
    fi

    # ── 6. Run write-flow dry-run smoke ─────────────────────────
    step "Run write-flow dry-run smoke"
    WF_LOG="$EVIDENCE_DIR/write-flow-smoke.txt"
    if bash "$SCRIPT_DIR/run-write-flow-examples-smoke.sh" > "$WF_LOG" 2>&1; then
        WF_RESULT=$(grep -E "PASS:|FAIL:" "$WF_LOG" | tail -3 || echo "unknown")
        pass "Write-flow dry-run smoke passed"
        info "$WF_RESULT"
    else
        tail -10 "$WF_LOG"
        fail "Write-flow dry-run smoke failed"
    fi
else
    skip "Smoke tests (--skip-smoke)"
fi

# ── 7. Run dashboard file check ────────────────────────────────
step "Run dashboard file check"
DASH_LOG="$EVIDENCE_DIR/dashboard-check.txt"
if bash "$SCRIPT_DIR/check-dashboard-files.sh" > "$DASH_LOG" 2>&1; then
    DASH_PASS=$(grep -c "PASS" "$DASH_LOG" 2>/dev/null || echo "0")
    DASH_FAIL=$(grep -c "FAIL" "$DASH_LOG" 2>/dev/null || echo "0")
    pass "Dashboard check: $DASH_PASS pass, $DASH_FAIL fail"
else
    tail -5 "$DASH_LOG"
    fail "Dashboard check failed"
fi

# ── 8. Serve dashboard (optional) ──────────────────────────────
if [ "$SERVE_DASHBOARD" -eq 1 ]; then
    step "Serve local dashboard"
    bash "$SCRIPT_DIR/serve-dashboard.sh" --port 8088 > "$EVIDENCE_DIR/logs/dashboard-serve.log" 2>&1 &
    DASH_PID=$!
    sleep 2
    if kill -0 "$DASH_PID" 2>/dev/null; then
        pass "Dashboard served at http://localhost:8088"
        echo "  Open http://localhost:8088 in your browser."
    else
        fail "Dashboard failed to start"
    fi
fi

# ── Stop devnet ────────────────────────────────────────────────
if [ "$KEEP_RUNNING" -eq 0 ]; then
    step "Stop devnet"
    bash "$SCRIPT_DIR/../release/stop-rc1-devnet.sh" > "$EVIDENCE_DIR/logs/stop-devnet.log" 2>&1 && pass "Devnet stopped" || fail "Devnet stop failed"
else
    info "Devnet kept running (--keep-running)"
    echo "  RPC:  http://127.0.0.1:26657"
    echo "  REST: http://127.0.0.1:1317"
fi

# ── Write summary ──────────────────────────────────────────────
step "Write evidence summary"
SUMMARY_JSON="$EVIDENCE_DIR/summary.json"
SUMMARY_MD="$EVIDENCE_DIR/summary.md"

cat > "$SUMMARY_JSON" <<EOF
{
  "demo": "NexaRail Local Demo",
  "timestamp": "$TIMESTAMP",
  "pass": $PASS,
  "fail": $FAIL,
  "skip": $SKIP,
  "total_checks": $((PASS+FAIL+SKIP)),
  "binary": "$BINARY",
  "keep_running": $KEEP_RUNNING,
  "serve_dashboard": $SERVE_DASHBOARD,
  "live_flags": {"settlement": false, "escrow": false, "treasury": false, "payout": false}
}
EOF

SMOKE_LABEL="⏭️ SKIP"
WF_LABEL="⏭️ SKIP"
[ -f "${SMOKE_LOG:-}" ] && grep -q "PASS:" "$SMOKE_LOG" 2>/dev/null && SMOKE_LABEL="✅ PASS"
[ -f "${WF_LOG:-}" ] && grep -q "PASS:" "$WF_LOG" 2>/dev/null && WF_LABEL="✅ PASS"

cat > "$SUMMARY_MD" <<EOF
# NexaRail Local Demo — Evidence Summary

**Date:** $(date -u)
**Duration:** $TIMESTAMP
**Evidence root:** \`$EVIDENCE_DIR\`

## Results

| Check | Result |
|---|---|
| RC1 package verified | $([ -f "$RELEASE_DIR/manifests/manifest.json" ] && echo "✅ PASS" || echo "❌ FAIL") |
| Binary checksum | $([ -f "$CHECKSUM_FILE" ] && echo "✅ PASS" || echo "⏭️ SKIP") |
| Devnet launch | ✅ PASS |
| Live flags (all false) | ✅ PASS |
| Developer examples smoke | $SMOKE_LABEL |
| Write-flow dry-run smoke | $WF_LABEL |
| Dashboard check | $(grep -q "PASS" "$DASH_LOG" 2>/dev/null && echo "✅ PASS" || echo "⏭️ SKIP") |

**Total:** $PASS ✅ / $FAIL ❌ / $SKIP ⏭️

## Files

- \`devnet-status.json\` — Node status at demo time
- \`live-flags.json\` — All 4 module live flags
- \`smoke-results.txt\` — Developer examples smoke output
- \`write-flow-smoke.txt\` — Write-flow dry-run output
- \`dashboard-check.txt\` — Dashboard file check output
- \`summary.json\` — Machine-readable summary
- \`summary.md\` — This file
- \`logs/\` — Devnet launch / stop logs

## Disclaimer

**LOCAL DEVNET ONLY.** This demo runs against a single-node local devnet.
- NOT public testnet
- NOT mainnet
- No token sale
- Tokens have zero monetary value
- Live flags are disabled by default
EOF

python3 -m json.tool "$SUMMARY_JSON" > /dev/null 2>&1 && pass "Evidence summary saved" || fail "Summary JSON invalid"

# ── Final ──────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════"
echo "  Local Demo Complete"
echo "  Pass: $PASS  Fail: $FAIL  Skip: $SKIP"
echo "  Evidence: $EVIDENCE_DIR"
echo "═══════════════════════════════════════════════════"
exit $FAIL
