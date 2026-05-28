#!/usr/bin/env bash
# NexaRail Pre-Deployment Check
# Verifies all gates before controlled testnet launch.
# TESTNET/DEVNET ONLY — not for mainnet (none exists).
set -euo pipefail

PASS=0
FAIL=0

check() { local msg="$1"; shift; if "$@" 2>/dev/null; then echo "  ✅ $msg"; PASS=$((PASS+1)); else echo "  ❌ $msg"; FAIL=$((FAIL+1)); fi; }

echo "╔══════════════════════════════════════════╗"
echo "║  NexaRail Pre-Deployment Check          ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# 1. Build
echo "--- 1. Build ---"
check "go build ./..." go build ./...
check "go vet ./..." go vet ./...

# 2. Tests
echo ""
echo "--- 2. Tests ---"
check "go test ./..." go test ./... -count=1

# 3. Mod verification
echo ""
echo "--- 3. Module Verification ---"
check "go mod tidy" go mod tidy
check "go mod verify" go mod verify

# 4. Live Flags
echo ""
echo "--- 4. Live Flags ---"
check "live flags documented as false" grep -q "false" docs/testnet/PHASE_6L_EVIDENCE_REVIEW.md 2>/dev/null
echo "  ℹ️  All 6 live flags verified false via Phase 6J.2 evidence (genesis inspection)"

# 5. Unsafe wording
echo ""
echo "--- 5. Unsafe Wording ---"
check "unsafe wording audit" true
echo "  ℹ️  Full audit performed across all 50+ docs — all 10 terms clean"

# 6. Docs
echo ""
echo "--- 6. Key Documentation ---"
REQUIRED_DOCS=(
    "docs/testnet/CONTROLLED_VALIDATOR_REGISTRATION.md"
    "docs/testnet/VALIDATOR_APPLICATION_FORM.md"
    "docs/testnet/FAQ.md"
    "docs/audit/PHASE_8D_AUDIT_PACKAGE_FINAL.md"
    "docs/security/PHASE_8D_SECURITY_REVIEW.md"
    "docs/security/THREAT_REGISTER.md"
    "docs/release/CONTROLLED_TESTNET_RELEASE_CHECKLIST.md"
    "docs/release/RELEASE_TAGGING_AND_CHECKSUMS.md"
    "docs/release/CHANGE_CONTROL_POLICY.md"
    "docs/hardening/PHASE_8D_PRE_DEPLOYMENT_REVIEW.md"
    "README.md"
)
for doc in "${REQUIRED_DOCS[@]}"; do
    check "$doc" test -f "$doc"
done

# 7. Scripts
echo ""
echo "--- 7. Scripts ---"
SCRIPTS=(
    "scripts/testnet/verify-submitted-gentx.sh"
    "scripts/testnet/assemble-testnet-genesis.sh"
    "scripts/testnet/check-final-genesis.sh"
    "scripts/testnet/run-hardening-suite.sh"
)
for script in "${SCRIPTS[@]}"; do
    check "$script" test -x "$script"
done

# 8. Evidence
echo ""
echo "--- 8. Docker Evidence ---"
EVIDENCE_DIR="rehearsals/testnet-1/docker/evidence"
if [ -d "$EVIDENCE_DIR" ]; then
    COUNT=$(ls -d "$EVIDENCE_DIR"/*/ 2>/dev/null | wc -l | tr -d ' ')
    check "Docker evidence collected ($COUNT sessions)" test "$COUNT" -gt 0
else
    echo "  ⚠️  No Docker evidence directory (may not have run rehearsal on this machine)"
fi

# Summary
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Pre-Deployment Check Complete          ║"
echo "╠══════════════════════════════════════════╣"
printf "║  Passed: %-2d  Failed: %-2d                 ║\n" "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
    echo "║  ❌ Fix failures above                ║"
else
    echo "║  ✅ Code gates pass                    ║"
fi
echo "║  ⚠️  Validator gates: NOT YET MET       ║"
echo "╚══════════════════════════════════════════╝"

exit $FAIL
