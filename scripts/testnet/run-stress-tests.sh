#!/usr/bin/env bash
# NexaRail Stress Test Suite
# Runs invariant, fuzz, randomized, and failure injection tests.
# TESTNET/DEVNET ONLY.
set -euo pipefail

PASS=0
FAIL=0

echo "╔══════════════════════════════════════════╗"
echo "║  NexaRail Stress Test Suite             ║"
echo "║  Phase 8E                               ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# 1. Full test suite
echo "═══ 1. Full Test Suite ═══"
if go test ./... -count=1 2>&1 | grep -q "^FAIL"; then
    echo "  ❌ Full test suite failed"
    FAIL=$((FAIL+1))
else
    echo "  ✅ Full test suite passed"
    PASS=$((PASS+1))
fi

# 2. Invariant tests
echo ""
echo "═══ 2. Invariant Tests ═══"
INVARIANT_COUNT=$(go test ./... -run "Invariant" -count=1 2>&1 | grep -c "^--- PASS.*Invariant" || true)
echo "  Invariant tests passed: $INVARIANT_COUNT"
if [ "${INVARIANT_COUNT:-0}" -gt 0 ]; then
    echo "  ✅ Invariant tests present and passing"
    PASS=$((PASS+1))
else
    echo "  ⚠️  No invariant tests found"
fi

# 3. Fuzz tests
echo ""
echo "═══ 3. Fuzz Tests ═══"
FUZZ_COUNT=$(go test ./... -run "Fuzz" -count=1 2>&1 | grep -c "^--- PASS.*Fuzz" || true)
echo "  Fuzz tests passed: $FUZZ_COUNT"
if [ "${FUZZ_COUNT:-0}" -gt 0 ]; then
    echo "  ✅ Fuzz tests present and passing"
    PASS=$((PASS+1))
else
    echo "  ⚠️  No fuzz tests found"
fi

# 4. Randomized tests
echo ""
echo "═══ 4. Randomized Tests ═══"
RANDOM_COUNT=$(go test ./... -run "Random" -count=1 2>&1 | grep -c "^--- PASS.*Random" || true)
echo "  Randomized tests passed: $RANDOM_COUNT"
if [ "${RANDOM_COUNT:-0}" -gt 0 ]; then
    echo "  ✅ Randomized tests present and passing"
    PASS=$((PASS+1))
else
    echo "  ⚠️  No randomized tests found"
fi

# 5. Failure injection tests
echo ""
echo "═══ 5. Failure Injection Tests ═══"
FAILURE_COUNT=$(go test ./... -run "Failure" -count=1 2>&1 | grep -c "^--- PASS.*Failure" || true)
echo "  Failure injection tests passed: $FAILURE_COUNT"
if [ "${FAILURE_COUNT:-0}" -gt 0 ]; then
    echo "  ✅ Failure injection tests present and passing"
    PASS=$((PASS+1))
else
    echo "  ⚠️  No failure injection tests found"
fi

# 6. Build and vet
echo ""
echo "═══ 6. Build & Vet ═══"
if go build ./... 2>&1 && go vet ./... 2>&1; then
    echo "  ✅ Build and vet passed"
    PASS=$((PASS+1))
else
    echo "  ❌ Build or vet failed"
    FAIL=$((FAIL+1))
fi

# Summary
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Stress Test Suite Complete             ║"
echo "╠══════════════════════════════════════════╣"
printf "║  Passed: %-2d  Failed: %-2d                 ║\n" "$PASS" "$FAIL"
echo "║  Invariants: $INVARIANT_COUNT  Fuzz: $FUZZ_COUNT          ║"
echo "║  Random: $RANDOM_COUNT  Failure: $FAILURE_COUNT              ║"
echo "╚══════════════════════════════════════════╝"

exit $FAIL
