#!/usr/bin/env bash
# NexaRail — Module Hardening Tests
#
# Runs targeted message validation, state transition, invariant, and fuzz tests
# for all 6 product modules: merchant, fees, settlement, escrow, treasury, payout.
#
# LOCAL DEVNET ONLY — NOT MAINNET
#
# Usage:
#   bash scripts/testnet/run-module-hardening-tests.sh
#   bash scripts/testnet/run-module-hardening-tests.sh --coverage
#   bash scripts/testnet/run-module-hardening-tests.sh --fuzz
#   bash scripts/testnet/run-module-hardening-tests.sh --quick
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUN_FUZZ=0
RUN_COVERAGE=0
QUICK=0

PASS=0
FAIL=0
SKIP=0
PASS_MARK="  \033[32m✅ PASS\033[0m"
FAIL_MARK="  \033[31m❌ FAIL\033[0m"
SKIP_MARK="  \033[33m⏭️  SKIP\033[0m"
check_pass() { echo -e "${PASS_MARK} $1 — $2"; PASS=$((PASS+1)); }
check_fail() { echo -e "${FAIL_MARK} $1 — $2"; FAIL=$((FAIL+1)); }
check_skip() { echo -e "${SKIP_MARK} $1 — $2"; SKIP=$((SKIP+1)); }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --coverage) RUN_COVERAGE=1; shift ;;
        --fuzz)     RUN_FUZZ=1; shift ;;
        --quick)    QUICK=1; shift ;;
        *) echo "Unknown: $1"; exit 1 ;;
    esac
done

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  NexaRail — Module Hardening Tests                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# ── All module test targets ──────────────────────────────────
MODULES=(
    "x/common/..."
    "x/merchant/types/..."
    "x/merchant/keeper/..."
    "x/fees/types/..."
    "x/fees/keeper/..."
    "x/settlement/types/..."
    "x/settlement/keeper/..."
    "x/escrow/types/..."
    "x/escrow/keeper/..."
    "x/treasury/types/..."
    "x/treasury/keeper/..."
    "x/payout/types/..."
    "x/payout/keeper/..."
)

# ── Section 1: Unit Tests ───────────────────────────────────
echo ""
echo "── Section 1: Unit Tests ────────────────────────────────────────"
UNIT_PASS=0
UNIT_FAIL=0
for pkg in "${MODULES[@]}"; do
    # Count test functions
    test_count=$(cd "$PROJECT_DIR" && go test -list ".*" "$pkg" 2>/dev/null | grep -c "^Test" || echo 0)
    if [ "$test_count" -gt 0 ]; then
        if [ "$QUICK" -eq 1 ]; then
            # Run with count=1 to avoid cache
            if (cd "$PROJECT_DIR" && go test -count=1 "$pkg" &>/dev/null); then
                UNIT_PASS=$((UNIT_PASS+1))
            else
                UNIT_FAIL=$((UNIT_FAIL+1))
            fi
        else
            if (cd "$PROJECT_DIR" && go test "$pkg" &>/dev/null); then
                UNIT_PASS=$((UNIT_PASS+1))
            else
                UNIT_FAIL=$((UNIT_FAIL+1))
            fi
        fi
    else
        check_skip "no_tests" "$pkg — no tests"
    fi
done

if [ "$UNIT_FAIL" -eq 0 ]; then
    check_pass "unit_tests" "$UNIT_PASS packages, 0 failures"
else
    check_fail "unit_tests" "$UNIT_FAIL packages failed"
fi

# ── Section 2: Run full go test for all packages ────────────
echo ""
echo "── Section 2: Full Test Suite ───────────────────────────────────"
cd "$PROJECT_DIR"
OUTPUT_FILE=$(mktemp)
if go test ./... -count=1 2>"$OUTPUT_FILE" >"$OUTPUT_FILE"; then
    PASS_COUNT=$(grep -c "^ok" "$OUTPUT_FILE" 2>/dev/null || echo 0)
    FAIL_COUNT=$(grep -c "^FAIL" "$OUTPUT_FILE" 2>/dev/null || echo 0)
    if [ "$FAIL_COUNT" -eq 0 ]; then
        check_pass "full_suite" "All $PASS_COUNT packages pass"
    else
        check_fail "full_suite" "$FAIL_COUNT packages failed"
    fi
else
    check_fail "full_suite" "Test suite failed"
    tail -20 "$OUTPUT_FILE"
fi
rm -f "$OUTPUT_FILE"

# ── Section 3: Module-Specific Invariants ───────────────────
echo ""
echo "── Section 3: Invariant Tests ───────────────────────────────────"
INV_PASS=0
INV_FAIL=0

# Run specific invariant tests if they exist
for pattern in "TestInvariant\|TestInvariant\|TestGenesis\|TestValidate\|TestParams"; do
    test_names=$(cd "$PROJECT_DIR" && go test -list ".*" ./x/... 2>/dev/null | grep "$pattern" | head -20 || true)
    for test in $test_names; do
        if (cd "$PROJECT_DIR" && go test -count=1 -run "$test" ./x/... &>/dev/null); then
            INV_PASS=$((INV_PASS+1))
        else
            INV_FAIL=$((INV_FAIL+1))
        fi
    done
done

if [ "$INV_FAIL" -eq 0 ]; then
    check_pass "invariant_tests" "$INV_PASS invariant/genesis/validate tests pass"
else
    check_fail "invariant_tests" "$INV_FAIL tests failed"
fi

# ── Section 4: Fuzz Tests (optional) ────────────────────────
echo ""
echo "── Section 4: Fuzz Tests ─────────────────────────────────────────"
if [ "$RUN_FUZZ" -eq 1 ]; then
    FUZZ_PASS=0
    FUZZ_FAIL=0
    for pattern in "Fuzz\|FuzzValidate\|FuzzMsg" ; do
        fuzz_tests=$(cd "$PROJECT_DIR" && go test -list ".*" ./x/... 2>/dev/null | grep "$pattern" | head -10 || true)
        for test in $fuzz_tests; do
            if (cd "$PROJECT_DIR" && go test -count=1 -fuzz="$test" -fuzztime=5s ./x/... &>/dev/null); then
                FUZZ_PASS=$((FUZZ_PASS+1))
            else
                FUZZ_FAIL=$((FUZZ_FAIL+1))
            fi
        done
    done
    if [ "$FUZZ_FAIL" -eq 0 ]; then
        check_pass "fuzz_tests" "$FUZZ_PASS fuzz tests pass"
    else
        check_fail "fuzz_tests" "$FUZZ_FAIL fuzz tests failed"
    fi
else
    check_skip "fuzz_tests" "Use --fuzz to run fuzz tests"
fi

# ── Section 5: Coverage (optional) ──────────────────────────
echo ""
echo "── Section 5: Test Coverage ─────────────────────────────────────"
if [ "$RUN_COVERAGE" -eq 1 ]; then
    COV_FILE=$(mktemp)
    (cd "$PROJECT_DIR" && go test -coverprofile="$COV_FILE" ./x/... 2>/dev/null)
    TOTAL_COV=$(go tool cover -func="$COV_FILE" 2>/dev/null | grep "total:" | awk '{print $3}' || echo "unknown")
    echo "  Overall coverage (x/ modules): $TOTAL_COV"
    check_pass "coverage" "Coverage: $TOTAL_COV"
    rm -f "$COV_FILE"
else
    check_skip "coverage" "Use --coverage to run coverage"
fi

# ── Summary ─────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Module Hardening Tests Summary                            ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5s %5s %5s   ║\n" "Result" "PASS" "FAIL" "SKIP"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5d %5d %5d   ║\n" "Hardening" "$PASS" "$FAIL" "$SKIP"
echo "╠══════════════════════════════════════════════════════════════╣"
if [ "$FAIL" -eq 0 ]; then
    echo "║  ✅ All hardening tests passed                             ║"
else
    echo "║  ❌ Some tests failed                                      ║"
fi
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

exit $([ "$FAIL" -eq 0 ] && echo 0 || echo 1)