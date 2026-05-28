#!/usr/bin/env bash
# NexaRail — Product-Flow Harness Self-Test
# Verifies harness script meets minimum safety requirements.
set -Eeuo pipefail

HARNESS="${1:-scripts/testnet/run-product-flow-rehearsal.sh}"
if [ ! -f "$HARNESS" ]; then echo "❌ Harness not found: $HARNESS"; exit 1; fi

PASS=0; FAIL=0
check() { local n="$1" r="$2"; if [ "$r" -eq 0 ]; then PASS=$((PASS+1)); echo "  ✅ $n"; else FAIL=$((FAIL+1)); echo "  ❌ $n"; fi; }

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  NexaRail — Product-Flow Harness Self-Test                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo "  Harness: $HARNESS ($(wc -l < "$HARNESS") lines)"
echo ""

# 1. Bash syntax
bash -n "$HARNESS" 2>/dev/null; check "Bash syntax valid" $?

# 2. No active exec > >(tee) pattern (exclude comments)
if grep 'exec > >(tee' "$HARNESS" | grep -vE "^\s*#" >/dev/null 2>&1; then
    check "No active exec > >(tee) pattern" 1
else
    check "No active exec > >(tee) pattern" 0
fi

# 3. Required features
grep -q "setup_evidence()" "$HARNESS"; check "setup_evidence() exists" $?
bash "$HARNESS" --help 2>&1 | grep -q "Usage:\|usage:"; check "--help works" $?
grep -q -- "--suite" "$HARNESS"; check "--suite flag" $?
grep -q -- "--no-spawn" "$HARNESS"; check "--no-spawn flag" $?
grep -q -- "--keep-running" "$HARNESS"; check "--keep-running flag" $?
grep -q -- "--global-timeout" "$HARNESS"; check "--global-timeout flag" $?
grep -q "trap.*ERR\|trap.*EXIT" "$HARNESS"; check "Trap handlers exist" $?
grep -q "failure-stage" "$HARNESS"; check "Failure stage tracking" $?

# 4. Required suites
for suite in "smoke" "settlement" "merchant" "escrow" "treasury" "payout" "safety"; do
    grep -q "$suite" "$HARNESS"; check "  $suite suite" $?
done

# 5. No rm -rf of active evidence
if grep "rm.*\$EVIDENCE_DIR\|rm.*\$RUN_LOG" "$HARNESS" >/dev/null 2>&1; then
    check "No destructive rm of active evidence" 1
else
    check "No destructive rm of active evidence" 0
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Results                         PASS  FAIL                ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-30s %4s  %4s               ║\n" "Harness checks" "$PASS" "$FAIL"
echo "╠══════════════════════════════════════════════════════════════╣"
[ "$FAIL" -eq 0 ] && echo "║  ✅ All harness checks pass              ║" || echo "║  ❌ Some checks failed                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
exit $([ "$FAIL" -eq 0 ] && echo 0 || echo 1)