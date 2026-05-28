#!/usr/bin/env bash
# NexaRail — Invariant Checks
#
# Runs invariant unit tests and module hardening checks.
# LOCAL DEVNET ONLY — NOT MAINNET
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0; FAIL=0; SKIP=0
PASS_MARK="  \033[32m✅ PASS\033[0m"
FAIL_MARK="  \033[31m❌ FAIL\033[0m"
SKIP_MARK="  \033[33m⏭️  SKIP\033[0m"
check_pass() { echo -e "${PASS_MARK} $1 — $2"; PASS=$((PASS+1)); }
check_fail() { echo -e "${FAIL_MARK} $1 — $2"; FAIL=$((FAIL+1)); }
check_skip() { echo -e "${SKIP_MARK} $1 — $2"; SKIP=$((SKIP+1)); }

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  NexaRail — Invariant Checks                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# ── Fee split invariant ─────────────────────────────────
echo ""
echo "── Fee Split Invariant ─────────────────────────────────────────"
cd "$PROJECT_DIR"
if go test ./x/fees/types/... -count=1 -run "TestFeeSplit|TestLiveFlags" -v 2>&1 | grep -q "PASS"; then
    check_pass "fee_split" "Fee split invariant tests pass"
else
    check_fail "fee_split" "Fee split invariant tests failed"
fi

# ── Escrow terminal state ──────────────────────────────
echo ""
echo "── Escrow Terminal State Invariant ────────────────────────────"
if go test ./x/escrow/types/... -count=1 -run "TestEscrowTerminal|TestLiveFlagsDefaultFalseEscrow" -v 2>&1 | grep -q "PASS"; then
    check_pass "escrow_terminal" "Escrow terminal state tests pass"
else
    check_fail "escrow_terminal" "Escrow terminal state tests failed"
fi

# ── Payout terminal state ──────────────────────────────
echo ""
echo "── Payout Terminal State Invariant ────────────────────────────"
if go test ./x/payout/types/... -count=1 -run "TestPayoutTerminal|TestLiveFlagsDefaultFalsePayout" -v 2>&1 | grep -q "PASS"; then
    check_pass "payout_terminal" "Payout terminal state tests pass"
else
    check_fail "payout_terminal" "Payout terminal state tests failed"
fi

# ── Treasury terminal state ────────────────────────────
echo ""
echo "── Treasury Terminal State Invariant ──────────────────────────"
if go test ./x/treasury/types/... -count=1 -run "TestTreasurySpendTerminal" -v 2>&1 | grep -q "PASS"; then
    check_pass "treasury_terminal" "Treasury terminal state tests pass"
else
    check_fail "treasury_terminal" "Treasury terminal state tests failed"
fi

# ── Settlement live flag ──────────────────────────────
echo ""
echo "── Settlement Live Flag Invariant ─────────────────────────────"
if go test ./x/settlement/types/... -count=1 -run "TestLiveFlagsDefaultFalseSettlement|TestSettlementLiveDisabled" -v 2>&1 | grep -q "PASS"; then
    check_pass "settlement_live" "Settlement live flag invariant passes"
else
    check_fail "settlement_live" "Settlement live flag invariant failed"
fi

# ── Module hardening (quick) ──────────────────────────
echo ""
echo "── Module Hardening (Quick) ────────────────────────────────────"
if bash "$PROJECT_DIR/scripts/testnet/run-module-hardening-tests.sh" --quick 2>&1 > /dev/null; then
    check_pass "module_hardening" "All module hardening quick tests pass"
else
    check_fail "module_hardening" "Module hardening tests failed"
fi

# ── Summary ─────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Invariant Checks Summary                                 ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5s %5s %5s   ║\n" "Result" "PASS" "FAIL" "SKIP"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5d %5d %5d   ║\n" "Invariants" "$PASS" "$FAIL" "$SKIP"
echo "╠══════════════════════════════════════════════════════════════╣"
[ "$FAIL" -eq 0 ] && echo "║  ✅ All invariants pass                                       ║" || echo "║  ❌ Some invariants failed                                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
exit $([ "$FAIL" -eq 0 ] && echo 0 || echo 1)