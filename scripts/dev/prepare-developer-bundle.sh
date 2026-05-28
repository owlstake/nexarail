#!/usr/bin/env bash
# NexaRail — Developer Onboarding Bundle Creator
#
# Creates a timestamped archive of developer assets: docs, SDK archives,
# examples, scripts, and manifests. Excludes binaries, private keys,
# node data, and evidence logs by default.
#
# LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS
#
# Usage:
#   bash scripts/dev/prepare-developer-bundle.sh
#   bash scripts/dev/prepare-developer-bundle.sh --include-rc1-binaries
#   bash scripts/dev/prepare-developer-bundle.sh --include-evidence-index
#   bash scripts/dev/prepare-developer-bundle.sh --skip-checks
#   bash scripts/dev/prepare-developer-bundle.sh --output-dir /tmp

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUTPUT_DIR="$PROJECT_DIR/releases/developer-bundles"
INCLUDE_BINARIES=0
INCLUDE_EVIDENCE=0
SKIP_CHECKS=0

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
        --include-rc1-binaries) INCLUDE_BINARIES=1; shift ;;
        --include-evidence-index) INCLUDE_EVIDENCE=1; shift ;;
        --skip-checks) SKIP_CHECKS=1; shift ;;
        --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
        *) echo "  ❌ Unknown flag: $1"; exit 1 ;;
    esac
done

mkdir -p "$OUTPUT_DIR"

BUNDLE_NAME="nexarail-developer-bundle-${TIMESTAMP}"
BUNDLE_DIR="/tmp/${BUNDLE_NAME}"
ARCHIVE_PATH="$OUTPUT_DIR/${BUNDLE_NAME}.tar.gz"
CHECKSUM_PATH="$OUTPUT_DIR/${BUNDLE_NAME}.sha256"
MANIFEST_PATH="$OUTPUT_DIR/manifest-${TIMESTAMP}.json"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  NexaRail — Developer Onboarding Bundle Creator            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo "  Timestamp: $TIMESTAMP"
echo "  Output:    $OUTPUT_DIR"
echo ""

# ══════════════════════════════════════════════════════════════════════
# Step 1: Run Checks (unless --skip-checks)
# ══════════════════════════════════════════════════════════════════════
echo "── Step 1: Prerequisite Checks ─────────────────────────────────"

if [ "$SKIP_CHECKS" -eq 0 ]; then
    if [ -x "$PROJECT_DIR/scripts/dev/check-sdk-packages.sh" ]; then
        if bash "$PROJECT_DIR/scripts/dev/check-sdk-packages.sh" > /dev/null 2>&1; then
            check_pass "sdk_checks" "SDK package checks passed"
        else
            check_fail "sdk_checks" "SDK package checks failed — run check-sdk-packages.sh first"
        fi
    fi

    if [ -x "$PROJECT_DIR/scripts/dev/run-nexarail-regression-matrix.sh" ]; then
        if bash "$PROJECT_DIR/scripts/dev/run-nexarail-regression-matrix.sh --fast" > /dev/null 2>&1; then
            check_pass "regression_fast" "Fast regression checks passed"
        else
            check_fail "regression_fast" "Fast regression failed — run regression matrix first"
        fi
    fi
else
    check_skip "sdk_checks" "Skipped via --skip-checks"
    check_skip "regression_fast" "Skipped via --skip-checks"
fi

# ══════════════════════════════════════════════════════════════════════
# Step 2: Assemble Bundle
# ══════════════════════════════════════════════════════════════════════
echo ""
echo "── Step 2: Assemble Bundle ─────────────────────────────────────"

rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR"/{docs,examples,scripts,releases}

# Core docs
for f in docs/NEXARAIL_LITEPAPER.md docs/release/RC1_REVIEWER_README.md docs/release/RC1_QUICKSTART.md docs/release/RC1_EVIDENCE_SUMMARY.md; do
    if [ -f "$PROJECT_DIR/$f" ]; then
        mkdir -p "$BUNDLE_DIR/$(dirname $f)"
        cp "$PROJECT_DIR/$f" "$BUNDLE_DIR/$f"
    fi
done

# docs/developers/
if [ -d "$PROJECT_DIR/docs/developers" ]; then
    mkdir -p "$BUNDLE_DIR/docs/developers"
    cp -r "$PROJECT_DIR/docs/developers/"* "$BUNDLE_DIR/docs/developers/" 2>/dev/null || true
fi

# docs/api/
if [ -d "$PROJECT_DIR/docs/api" ]; then
    mkdir -p "$BUNDLE_DIR/docs/api"
    cp -r "$PROJECT_DIR/docs/api/"* "$BUNDLE_DIR/docs/api/" 2>/dev/null || true
fi

# docs/audit/
if [ -d "$PROJECT_DIR/docs/audit" ]; then
    mkdir -p "$BUNDLE_DIR/docs/audit"
    cp -r "$PROJECT_DIR/docs/audit/"* "$BUNDLE_DIR/docs/audit/" 2>/dev/null || true
fi

# docs/hardening/ (only RC1-related, not all)
if [ -d "$PROJECT_DIR/docs/hardening" ]; then
    mkdir -p "$BUNDLE_DIR/docs/hardening"
    for f in "$PROJECT_DIR/docs/hardening/"*; do
        bname=$(basename "$f")
        case "$bname" in
            PHASE_10*|PHASE_11*|PHASE_12*) cp "$f" "$BUNDLE_DIR/docs/hardening/$bname" ;;
            *) ;;
        esac
    done
fi

# examples/*
for dir in rest node-client python-client dashboard write-flows; do
    if [ -d "$PROJECT_DIR/examples/$dir" ]; then
        mkdir -p "$BUNDLE_DIR/examples/$dir"
        cp -r "$PROJECT_DIR/examples/$dir/"* "$BUNDLE_DIR/examples/$dir/" 2>/dev/null || true
    fi
done

# scripts/dev/ (all)
if [ -d "$PROJECT_DIR/scripts/dev" ]; then
    mkdir -p "$BUNDLE_DIR/scripts/dev"
    cp -r "$PROJECT_DIR/scripts/dev/"* "$BUNDLE_DIR/scripts/dev/" 2>/dev/null || true
fi

# scripts/release/ (key scripts)
for s in launch-rc1-devnet.sh query-rc1-devnet.sh verify-testnet-rc1.sh stop-rc1-devnet.sh; do
    if [ -f "$PROJECT_DIR/scripts/release/$s" ]; then
        mkdir -p "$BUNDLE_DIR/scripts/release"
        cp "$PROJECT_DIR/scripts/release/$s" "$BUNDLE_DIR/scripts/release/$s"
    fi
done

# releases/sdk-local/
if [ -d "$PROJECT_DIR/releases/sdk-local" ]; then
    mkdir -p "$BUNDLE_DIR/releases/sdk-local"
    cp -r "$PROJECT_DIR/releases/sdk-local/"* "$BUNDLE_DIR/releases/sdk-local/" 2>/dev/null || true
fi

# Portal source and build output
if [ -d "$PROJECT_DIR/docs/portal" ]; then
    mkdir -p "$BUNDLE_DIR/docs/portal"
    cp -r "$PROJECT_DIR/docs/portal/"* "$BUNDLE_DIR/docs/portal/" 2>/dev/null || true
fi

# Portal source and build output
if [ -d "$PROJECT_DIR/docs/portal" ]; then
    mkdir -p "$BUNDLE_DIR/docs/portal"
    cp -r "$PROJECT_DIR/docs/portal/"* "$BUNDLE_DIR/docs/portal/" 2>/dev/null || true
fi
if [ -d "$PROJECT_DIR/site/developer-portal" ]; then
    mkdir -p "$BUNDLE_DIR/site/developer-portal"
    cp -r "$PROJECT_DIR/site/developer-portal/"* "$BUNDLE_DIR/site/developer-portal/" 2>/dev/null || true
fi

# .github/ (workflows and templates)
if [ -d "$PROJECT_DIR/.github" ]; then
    mkdir -p "$BUNDLE_DIR/.github"
    cp -r "$PROJECT_DIR/.github/"* "$BUNDLE_DIR/.github/" 2>/dev/null || true
fi

# README.md
cp "$PROJECT_DIR/README.md" "$BUNDLE_DIR/README.md" 2>/dev/null || true

# RC1 binaries (optional)
if [ "$INCLUDE_BINARIES" -eq 1 ] && [ -d "$PROJECT_DIR/releases/testnet-rc1/binaries" ]; then
    mkdir -p "$BUNDLE_DIR/releases/testnet-rc1/binaries"
    cp -r "$PROJECT_DIR/releases/testnet-rc1/binaries/"* "$BUNDLE_DIR/releases/testnet-rc1/binaries/" 2>/dev/null || true
    check_pass "rc1_binaries" "RC1 binaries included in bundle"
else
    check_skip "rc1_binaries" "Not included (use --include-rc1-binaries)"
fi

# Evidence index (optional)
if [ "$INCLUDE_EVIDENCE" -eq 1 ]; then
    mkdir -p "$BUNDLE_DIR/rehearsals"
    # Include only indexes and summaries, not raw logs
    for dir in rehearsal-docs product-flows regression-matrix end-to-end-demo; do
        idx="$PROJECT_DIR/rehearsals/$dir"
        if [ -d "$idx" ]; then
            mkdir -p "$BUNDLE_DIR/rehearsals/$dir"
            find "$idx" -name "summary.json" -o -name "summary.md" -o -name "index*" -o -name "manifest*" 2>/dev/null | while read f; do
                rel=$(echo "$f" | sed "s|$PROJECT_DIR/||")
                mkdir -p "$BUNDLE_DIR/$(dirname $rel)"
                cp "$f" "$BUNDLE_DIR/$rel"
            done
        fi
    done
    check_pass "evidence_index" "Evidence summaries included in bundle"
else
    check_skip "evidence_index" "Not included (use --include-evidence-index)"
fi

check_pass "bundle_assembled" "Bundle directory created at $BUNDLE_DIR"

# ══════════════════════════════════════════════════════════════════════
# Step 3: Scan Excluded Files
# ══════════════════════════════════════════════════════════════════════
echo ""
echo "── Step 3: Security Scan ────────────────────────────────────────"

EXCLUDE_FOUND=0
for pattern in "priv_validator_key" "node_key" "mnemonic" "seed phrase" "application.db" "blockstore.db" "state.db"; do
    hits=$(find "$BUNDLE_DIR" -type f -name "*${pattern}*" 2>/dev/null | head -3)
    if [ -n "$hits" ]; then
        echo "  ⚠️  EXCLUDED FILE FOUND: $pattern — $hits"
        EXCLUDE_FOUND=1
    fi
done

if [ "$EXCLUDE_FOUND" -eq 0 ]; then
    check_pass "exclusion_scan" "No excluded files found in bundle"
else
    check_fail "exclusion_scan" "Excluded files detected — see above"
fi

# Scan for .pem files
pem_hits=$(find "$BUNDLE_DIR" -name "*.pem" 2>/dev/null | head -3)
if [ -n "$pem_hits" ]; then
    check_fail "pem_check" ".pem files found in bundle"
else
    check_pass "pem_check" "No .pem files in bundle"
fi

# ══════════════════════════════════════════════════════════════════════
# Step 4: Create Archive
# ══════════════════════════════════════════════════════════════════════
echo ""
echo "── Step 4: Create Archive ──────────────────────────────────────"

cd /tmp
tar czf "$ARCHIVE_PATH" "$(basename "$BUNDLE_DIR")" 2>/dev/null
cd "$PROJECT_DIR"

if [ -f "$ARCHIVE_PATH" ]; then
    ARCHIVE_SIZE=$(du -h "$ARCHIVE_PATH" | cut -f1)
    FILE_COUNT=$(find "$BUNDLE_DIR" -type f | wc -l)
    check_pass "archive_created" "Bundle archive: $ARCHIVE_PATH ($ARCHIVE_SIZE, $FILE_COUNT files)"
else
    check_fail "archive_created" "Failed to create archive"
fi

# SHA256 checksum
if command -v shasum &>/dev/null; then
    shasum -a 256 "$ARCHIVE_PATH" > "$CHECKSUM_PATH"
    check_pass "checksum" "SHA256 written to $CHECKSUM_PATH"
elif command -v sha256sum &>/dev/null; then
    sha256sum "$ARCHIVE_PATH" > "$CHECKSUM_PATH"
    check_pass "checksum" "SHA256 written to $CHECKSUM_PATH"
else
    check_skip "checksum" "No SHA256 tool found"
fi

# ══════════════════════════════════════════════════════════════════════
# Step 5: Create Manifest
# ══════════════════════════════════════════════════════════════════════
echo ""
echo "── Step 5: Create Manifest ─────────────────────────────────────"

# Collect archive checksum
CKSUM=$(cat "$CHECKSUM_PATH" 2>/dev/null | awk '{print $1}' || echo "")

cat > "$MANIFEST_PATH" << EOF
{
  "bundle": "nexarail-developer-bundle",
  "timestamp": "$TIMESTAMP",
  "sdk_version": "0.1.0-dev",
  "compatible_rc": "nexarail-devnet-1",
  "archive": "$(basename "$ARCHIVE_PATH")",
  "sha256": "$CKSUM",
  "size": "$ARCHIVE_SIZE",
  "file_count": $FILE_COUNT,
  "included_binaries": $([ "$INCLUDE_BINARIES" -eq 1 ] && echo "true" || echo "false"),
  "included_evidence": $([ "$INCLUDE_EVIDENCE" -eq 1 ] && echo "true" || echo "false"),
  "publishing_status": "not_published",
  "notes": "LOCAL DEVNET ONLY — NOT PUBLISHED to npm or PyPI. For internal developer review only."
}
EOF

check_pass "manifest" "Manifest created at $MANIFEST_PATH"

# ══════════════════════════════════════════════════════════════════════
# Step 6: List Bundle Contents
# ══════════════════════════════════════════════════════════════════════
echo ""
echo "── Bundle Contents ────────────────────────────────────────────"
tar tzf "$ARCHIVE_PATH" 2>/dev/null | head -30
echo "  ... ($FILE_COUNT total files)"

# ══════════════════════════════════════════════════════════════════════
# Summary
# ══════════════════════════════════════════════════════════════════════
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Bundle Creation Summary                                   ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5s %5s %5s   ║\n" "Result" "PASS" "FAIL" "SKIP"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5d %5d %5d   ║\n" "Bundle Prep" "$PASS" "$FAIL" "$SKIP"
echo "╠══════════════════════════════════════════════════════════════╣"
if [ "$FAIL" -eq 0 ]; then
    echo "║  ✅ Bundle created successfully                            ║"
else
    echo "║  ❌ Bundle creation had failures                           ║"
fi
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  Archive:  $ARCHIVE_PATH"
echo "  Checksum: $CHECKSUM_PATH"
echo "  Manifest: $MANIFEST_PATH"

rm -rf "$BUNDLE_DIR"

exit $([ "$FAIL" -eq 0 ] && echo 0 || echo 1)