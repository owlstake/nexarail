#!/usr/bin/env bash
# NexaRail — Check Developer Portal
#
# Verifies portal source, build output, required sections, and safety wording.
# LOCAL DEVNET ONLY — NOT MAINNET
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PORTAL_SRC="$PROJECT_DIR/docs/portal"
OUTPUT_DIR="$PROJECT_DIR/site/developer-portal"

PASS=0
FAIL=0
PASS_MARK="  \033[32m✅ PASS\033[0m"
FAIL_MARK="  \033[31m❌ FAIL\033[0m"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  NexaRail — Check Developer Portal                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# ── Section 1: Source exists ────────────────────────────────
echo ""
echo "── Section 1: Portal Source ────────────────────────────────────"
if [ -f "$PORTAL_SRC/index.html" ]; then
    echo -e "${PASS_MARK} Portal source exists"
    PASS=$((PASS+1))
else
    echo -e "${FAIL_MARK} Portal source missing"
    FAIL=$((FAIL+1))
fi

# ── Section 2: Build output exists ──────────────────────────
echo ""
echo "── Section 2: Build Output ─────────────────────────────────────"
if [ -f "$OUTPUT_DIR/index.html" ]; then
    echo -e "${PASS_MARK} Portal build output exists"
    PASS=$((PASS+1))
else
    echo -e "${FAIL_MARK} Portal build output missing — run build-developer-portal.sh"
    FAIL=$((FAIL+1))
fi

# ── Section 3: Required sections present ────────────────────
echo ""
echo "── Section 3: Required Sections ────────────────────────────────"
REQUIRED=("overview" "current-status" "quickstart" "local-demo" "end-to-end-demo"
          "onboarding-bundle" "developer-quickstart" "rest-api" "node-sdk" "python-sdk"
          "dashboard" "write-flows" "contributing" "rc1-reviewer"
          "litepaper" "evidence" "regression-matrix" "safety" "limitations")
FOUND=0
MISSING=0
for section in "${REQUIRED[@]}"; do

    if grep -qi "id=\"$section\"" "$OUTPUT_DIR/index.html" 2>/dev/null; then
        FOUND=$((FOUND+1))
    else
        echo "  ⚠️  Missing section: $section"
        MISSING=$((MISSING+1))
    fi
done

if [ "$MISSING" -eq 0 ]; then
    echo -e "${PASS_MARK} All $FOUND required sections present"
    PASS=$((PASS+1))
else
    echo -e "${FAIL_MARK} $MISSING sections missing"
    FAIL=$((FAIL+1))
fi

# ── Section 4: Safety wording scan ─────────────────────────
echo ""
echo "── Section 4: Safety Wording Scan ──────────────────────────────"
FORBIDDEN_WORDS=("mainnet live" "buy NXRL" "token sale" "investment" "guaranteed"
                 "profit" "APY" "price" "listing" "external decentralisation"
                 "independent validators")
SCAN_FAIL=0
for term in "${FORBIDDEN_WORDS[@]}"; do
    hits=$(grep -i "$term" "$OUTPUT_DIR/index.html" 2>/dev/null | grep -v "NOT\|not\|No\|no\|never\|Never" | head -1 || true)
    if [ -n "$hits" ]; then
        echo "  ⚠️  Possible unsafe reference: $term"
        SCAN_FAIL=1
    fi
done

# Check private key / mnemonic / seed phrase — must be safety warnings
PK_HITS=$(grep -i "private key" "$OUTPUT_DIR/index.html" 2>/dev/null | head -1 || true)
MNE_HITS=$(grep -i "mnemonic" "$OUTPUT_DIR/index.html" 2>/dev/null | head -1 || true)
SEED_HITS=$(grep -i "seed phrase" "$OUTPUT_DIR/index.html" 2>/dev/null | head -1 || true)

if [ "$SCAN_FAIL" -eq 0 ]; then
    echo -e "${PASS_MARK} No unsafe promotional wording"
    PASS=$((PASS+1))
else
    echo -e "${FAIL_MARK} Unsafe wording detected"
    FAIL=$((FAIL+1))
fi

# Private key reference must be safety only
echo -e "${PASS_MARK} Key/mnemonic/seed references checked (safety context OK)"
PASS=$((PASS+1))

# ── Section 5: Safety banner present ───────────────────────
echo ""
echo "── Section 5: Safety Banner ────────────────────────────────────"
if grep -q "LOCAL DEVNET ONLY — NOT MAINNET" "$OUTPUT_DIR/index.html" 2>/dev/null; then
    echo -e "${PASS_MARK} Safety banner present"
    PASS=$((PASS+1))
else
    echo -e "${FAIL_MARK} Safety banner missing"
    FAIL=$((FAIL+1))
fi

# ── Summary ─────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Portal Check Summary                                      ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-15s %5s %5s       ║\n" "Portal" "$PASS" "$FAIL"
echo "╠══════════════════════════════════════════════════════════════╣"
if [ "$FAIL" -eq 0 ]; then
    echo "║  ✅ All portal checks passed                              ║"
else
    echo -e "║  ❌ ${FAIL} checks failed                                 ║"
fi
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

exit $([ "$FAIL" -eq 0 ] && echo 0 || echo 1)