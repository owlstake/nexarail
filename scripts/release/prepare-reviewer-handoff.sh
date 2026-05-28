#!/usr/bin/env bash
# NexaRail — Prepare Reviewer Handoff Bundle
#
# Creates a timestamped archive of all reviewer-facing assets:
# docs, scripts, release artifacts, developer bundle, and evidence summaries.
#
# LOCAL DEVNET ONLY — NOT MAINNET
#
# Usage:
#   bash scripts/release/prepare-reviewer-handoff.sh
#   bash scripts/release/prepare-reviewer-handoff.sh --include-evidence-summaries
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUTPUT_DIR="$PROJECT_DIR/releases/reviewer-handoff"
INCLUDE_EVIDENCE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --include-evidence-summaries) INCLUDE_EVIDENCE=1; shift ;;
        *) echo "  ❌ Unknown: $1"; exit 1 ;;
    esac
done

mkdir -p "$OUTPUT_DIR"

BUNDLE_NAME="nexarail-reviewer-handoff-${TIMESTAMP}"
BUNDLE_DIR="/tmp/${BUNDLE_NAME}"
ARCHIVE_PATH="$OUTPUT_DIR/${BUNDLE_NAME}.tar.gz"
CHECKSUM_PATH="$OUTPUT_DIR/${BUNDLE_NAME}.sha256"
MANIFEST_PATH="$OUTPUT_DIR/manifest-${TIMESTAMP}.json"

PASS=0; FAIL=0; SKIP=0
PASS_MARK="  \033[32m✅ PASS\033[0m"
FAIL_MARK="  \033[31m❌ FAIL\033[0m"
SKIP_MARK="  \033[33m⏭️  SKIP\033[0m"

check_pass() { echo -e "${PASS_MARK} $1 — $2"; PASS=$((PASS+1)); }
check_fail() { echo -e "${FAIL_MARK} $1 — $2"; FAIL=$((FAIL+1)); }
check_skip() { echo -e "${SKIP_MARK} $1 — $2"; SKIP=$((SKIP+1)); }

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  NexaRail — Reviewer Handoff Bundle Creator                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo "  Timestamp: $TIMESTAMP"
echo ""

# ── Step 1: Assemble ──────────────────────────────────────────
echo "── Step 1: Assemble Bundle ────────────────────────────────────"
rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR/release-docs"
mkdir -p "$BUNDLE_DIR/developer-docs"
mkdir -p "$BUNDLE_DIR/scripts"

# Release docs
for f in REVIEWER_HANDOFF.md TECHNICAL_STATUS_ONE_PAGER.md REVIEWER_COMMAND_SHEET.md \
    KNOWN_LIMITATIONS_INDEX.md GITHUB_RELEASE_V0.1.0_RC1.md; do
    if [ -f "$PROJECT_DIR/docs/release/$f" ]; then
        cp "$PROJECT_DIR/docs/release/$f" "$BUNDLE_DIR/release-docs/$f"
    fi
done

# Key developer docs
for f in DEVELOPER_QUICKSTART.md LOCAL_DEMO_GUIDE.md SDK_PACKAGE_PREPARATION.md \
    SDK_RC1_RELEASE_NOTES.md ONBOARDING_CHECKLIST.md CONTRIBUTOR_TESTING_GUIDE.md \
    END_TO_END_DEMO_SCENARIO.md END_TO_END_DEMO_SUMMARY.md DEMO_REGRESSION_MATRIX.md \
    DEVELOPER_ASSETS_INVENTORY.md; do
    if [ -f "$PROJECT_DIR/docs/developers/$f" ]; then
        cp "$PROJECT_DIR/docs/developers/$f" "$BUNDLE_DIR/developer-docs/$f"
    fi
done

# Portal
if [ -d "$PROJECT_DIR/docs/portal" ]; then
    cp -r "$PROJECT_DIR/docs/portal" "$BUNDLE_DIR/portal"
fi

# Release scripts
for s in launch-rc1-devnet.sh stop-rc1-devnet.sh query-rc1-devnet.sh verify-rc1-devnet.sh \
    verify-testnet-rc1.sh; do
    if [ -f "$PROJECT_DIR/scripts/release/$s" ]; then
        cp "$PROJECT_DIR/scripts/release/$s" "$BUNDLE_DIR/scripts/$s"
    fi
done

# RC1 docs and manifests (not binaries)
cp -r "$PROJECT_DIR/releases/testnet-rc1/docs" "$BUNDLE_DIR/rc1-docs" 2>/dev/null || true
cp -r "$PROJECT_DIR/releases/testnet-rc1/manifests" "$BUNDLE_DIR/rc1-manifests" 2>/dev/null || true
cp -r "$PROJECT_DIR/releases/testnet-rc1/checksums" "$BUNDLE_DIR/rc1-checksums" 2>/dev/null || true

# Litepaper
if [ -f "$PROJECT_DIR/docs/NEXARAIL_LITEPAPER.md" ]; then
    cp "$PROJECT_DIR/docs/NEXARAIL_LITEPAPER.md" "$BUNDLE_DIR/"
fi

# README and CONTRIBUTING
cp "$PROJECT_DIR/README.md" "$BUNDLE_DIR/" 2>/dev/null || true
cp "$PROJECT_DIR/CONTRIBUTING.md" "$BUNDLE_DIR/" 2>/dev/null || true

# Developer bundle (latest)
latest_bundle=$(ls -t "$PROJECT_DIR/releases/developer-bundles/"*.tar.gz 2>/dev/null | head -1 || true)
if [ -n "$latest_bundle" ]; then
    cp "$latest_bundle" "$BUNDLE_DIR/"
    check_pass "developer_bundle" "Latest bundle included"
else
    check_skip "developer_bundle" "No developer bundle found"
fi

# SDK metadata
if [ -f "$PROJECT_DIR/releases/sdk-local/manifest.json" ]; then
    cp "$PROJECT_DIR/releases/sdk-local/manifest.json" "$BUNDLE_DIR/sdk-manifest.json"
    check_pass "sdk_manifest" "SDK manifest included"
else
    check_skip "sdk_manifest" "No SDK manifest found"
fi

# Evidence summaries (optional)
if [ "$INCLUDE_EVIDENCE" -eq 1 ]; then
    mkdir -p "$BUNDLE_DIR/evidence"
    for dir in regression-matrix end-to-end-demo; do
        latest_ev=$(ls -dt "$PROJECT_DIR/rehearsals/$dir/evidence/"* 2>/dev/null | head -1 || true)
        if [ -n "$latest_ev" ]; then
            mkdir -p "$BUNDLE_DIR/evidence/$dir"
            cp "$latest_ev/summary.json" "$BUNDLE_DIR/evidence/$dir/" 2>/dev/null || true
            cp "$latest_ev/summary.md" "$BUNDLE_DIR/evidence/$dir/" 2>/dev/null || true
        fi
    done
    check_pass "evidence_summaries" "Evidence summaries included"
else
    check_skip "evidence_summaries" "Use --include-evidence-summaries"
fi

check_pass "bundle_assembled" "Reviewer handoff bundle created"

# ── Step 2: Create archive ────────────────────────────────────
echo ""
echo "── Step 2: Create Archive ──────────────────────────────────────"
cd /tmp && tar czf "$ARCHIVE_PATH" "$(basename "$BUNDLE_DIR")" && cd "$PROJECT_DIR"
FILE_COUNT=$(find "$BUNDLE_DIR" -type f | wc -l)
ARCHIVE_SIZE=$(du -h "$ARCHIVE_PATH" 2>/dev/null | cut -f1)
check_pass "archive" "Archive: $ARCHIVE_PATH ($ARCHIVE_SIZE, $FILE_COUNT files)"

shasum -a 256 "$ARCHIVE_PATH" > "$CHECKSUM_PATH" && check_pass "checksum" "SHA256 written" || check_skip "checksum" "No shasum"

# ── Step 3: Manifest ──────────────────────────────────────────
echo ""
echo "── Step 3: Create Manifest ─────────────────────────────────────"
CKSUM=$(cat "$CHECKSUM_PATH" | awk '{print $1}' || echo "")
cat > "$MANIFEST_PATH" << EOF
{
  "bundle": "nexarail-reviewer-handoff",
  "timestamp": "$TIMESTAMP",
  "tag": "v0.1.0-rc1",
  "archive": "$(basename "$ARCHIVE_PATH")",
  "sha256": "$CKSUM",
  "size": "$ARCHIVE_SIZE",
  "file_count": $FILE_COUNT,
  "publishing_status": "not_published",
  "notes": "LOCAL DEVNET ONLY — NOT MAINNET. For external reviewer evaluation only."
}
EOF
check_pass "manifest" "Manifest created"

# ── Summary ───────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Reviewer Handoff Bundle Summary                           ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5s %5s %5s   ║\n" "Result" "PASS" "FAIL" "SKIP"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5d %5d %5d   ║\n" "Handoff" "$PASS" "$FAIL" "$SKIP"
echo "╠══════════════════════════════════════════════════════════════╣"
[ "$FAIL" -eq 0 ] && echo "║  ✅ Handoff bundle created successfully                     ║" || echo "║  ❌ Handoff bundle had failures                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo "  Archive:  $ARCHIVE_PATH"
echo "  Checksum: $CHECKSUM_PATH"
echo "  Manifest: $MANIFEST_PATH"

rm -rf "$BUNDLE_DIR"
exit $([ "$FAIL" -eq 0 ] && echo 0 || echo 1)