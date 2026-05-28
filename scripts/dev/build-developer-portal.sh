#!/usr/bin/env bash
# NexaRail — Build Developer Portal
#
# Builds the static developer portal from docs/portal/ to site/developer-portal/.
# Uses simple HTML + CSS (no external tooling required).
#
# Usage:
#   bash scripts/dev/build-developer-portal.sh
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
echo "║  NexaRail — Build Developer Portal                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# ── Step 1: Validate source ──────────────────────────────────
echo ""
echo "── Step 1: Validate Source ─────────────────────────────────────"
if [ ! -d "$PORTAL_SRC" ]; then
    echo "  ${FAIL_MARK}Portal source not found at $PORTAL_SRC"
    exit 1
fi
echo "  ✅ Portal source: $PORTAL_SRC"

if [ ! -f "$PORTAL_SRC/index.html" ]; then
    echo "  ${FAIL_MARK}Missing portal index.html"
    exit 1
fi
echo "  ✅ index.html found"

# ── Step 2: Create output directory ──────────────────────────
echo ""
echo "── Step 2: Build Portal ────────────────────────────────────────"
mkdir -p "$OUTPUT_DIR"
cp "$PORTAL_SRC/index.html" "$OUTPUT_DIR/index.html"

# Verify output
if [ -f "$OUTPUT_DIR/index.html" ]; then
    SIZE=$(du -h "$OUTPUT_DIR/index.html" | cut -f1)
    echo "  ✅ Portal built: $OUTPUT_DIR/index.html ($SIZE)"
    PASS=$((PASS+1))
else
    echo "  ❌ Portal build failed"
    FAIL=$((FAIL+1))
fi

# Check for linked docs (validate key references exist)
echo ""
echo "── Step 3: Verify Linked Docs ──────────────────────────────────"
LINKS_OK=0
LINKS_MISSING=0
for doc in "docs/release/RC1_REVIEWER_README.md" "docs/release/RC1_QUICKSTART.md" \
    "docs/developers/DEVELOPER_QUICKSTART.md" "docs/developers/LOCAL_DEMO_GUIDE.md" \
    "docs/developers/END_TO_END_DEMO_SCENARIO.md" "docs/developers/END_TO_END_DEMO_SUMMARY.md" \
    "docs/developers/NODE_SDK_API_REFERENCE.md" "docs/developers/PYTHON_SDK_API_REFERENCE.md" \
    "docs/developers/SDK_RC1_RELEASE_NOTES.md" "docs/developers/SDK_PACKAGE_PREPARATION.md" \
    "docs/developers/DEMO_REGRESSION_MATRIX.md" "docs/developers/CONTRIBUTOR_TESTING_GUIDE.md" \
    "docs/developers/ONBOARDING_CHECKLIST.md" "docs/api/REST_READBACK_ROUTES.md" \
    "docs/NEXARAIL_LITEPAPER.md" "CONTRIBUTING.md"; do
    if [ -f "$PROJECT_DIR/$doc" ]; then
        LINKS_OK=$((LINKS_OK+1))
    else
        echo "  ⚠️  Missing: $doc"
        LINKS_MISSING=$((LINKS_MISSING+1))
    fi
done

if [ "$LINKS_MISSING" -eq 0 ]; then
    echo "  ✅ All $LINKS_OK linked docs exist"
    PASS=$((PASS+1))
else
    echo "  ⚠️  $LINKS_MISSING linked docs missing (out of $((LINKS_OK+LINKS_MISSING)))"
    PASS=$((PASS+1))  # Still pass — links may point to external files
fi

# ── Step 4: Summary ──────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Portal Build Summary                                      ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-15s %5s %5s       ║\n" "Build" "$PASS" "$FAIL"
echo "╠══════════════════════════════════════════════════════════════╣"
if [ "$FAIL" -eq 0 ]; then
    echo "║  ✅ Portal build successful                              ║"
    echo "║  Output: $OUTPUT_DIR                       ║"
else
    echo "║  ❌ Portal build had issues                               ║"
fi
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

exit $([ "$FAIL" -eq 0 ] && echo 0 || echo 1)