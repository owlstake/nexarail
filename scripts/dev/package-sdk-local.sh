#!/usr/bin/env bash
# NexaRail — Local SDK Package Archive Creator
#
# Validates SDK checks, sources version info, and creates local tarball
# archives of the Node.js and Python client SDKs under releases/sdk-local/.
#
# This is for LOCAL DEVNET ONLY — NOT published to npm or PyPI.
#
# Usage:
#   bash scripts/dev/package-sdk-local.sh
#
# Returns non-zero if packaging fails.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RELEASES_DIR="$PROJECT_DIR/releases/sdk-local"

NODE_CLIENT_DIR="$PROJECT_DIR/examples/node-client"
PYTHON_CLIENT_DIR="$PROJECT_DIR/examples/python-client"

PASS=0
FAIL=0
SKIP=0

# ── Safety: must be in the NexaRail project directory ──────────────────
if [ ! -f "$PROJECT_DIR/go.mod" ] && [ ! -f "$PROJECT_DIR/Makefile" ]; then
    echo "  ❌ Not in NexaRail project directory (no go.mod or Makefile found)."
    echo "     Expected project root at: $PROJECT_DIR"
    exit 1
fi

# ── Required commands ──────────────────────────────────────────────────
if ! command -v tar &>/dev/null; then
    echo "  ❌ 'tar' is required but not found on PATH."
    exit 1
fi

if ! command -v shasum &>/dev/null; then
    echo "  ❌ 'shasum' is required but not found on PATH."
    exit 1
fi

# ── Colors ─────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_pass() {
    local label="$1"
    local detail="${2:-}"
    PASS=$((PASS + 1))
    printf "  ${GREEN}✅ PASS${NC}  %s\n" "$label"
    [ -n "$detail" ] && printf "        %s\n" "$detail"
}

check_fail() {
    local label="$1"
    local detail="${2:-}"
    FAIL=$((FAIL + 1))
    printf "  ${RED}❌ FAIL${NC}  %s\n" "$label"
    [ -n "$detail" ] && printf "        %s\n" "$detail"
}

check_skip() {
    local label="$1"
    local detail="${2:-}"
    SKIP=$((SKIP + 1))
    printf "  ${YELLOW}⏭️  SKIP${NC}  %s\n" "$label"
    [ -n "$detail" ] && printf "        %s\n" "$detail"
}

# ── Header ─────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  NexaRail — Local SDK Package Archive Creator              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# 0. Validate SDK checks (soft-fail)
# ═══════════════════════════════════════════════════════════════════════════
echo "── Step 0: Run SDK Package Checks ────────────────────────────────"

CHECK_SCRIPT="$PROJECT_DIR/scripts/dev/check-sdk-packages.sh"
if [ -f "$CHECK_SCRIPT" ] && [ -x "$CHECK_SCRIPT" ]; then
    echo "    Running: $CHECK_SCRIPT"
    set +e
    bash "$CHECK_SCRIPT" > /tmp/nexarail-sdk-check-prepackage.log 2>&1
    check_rc=$?
    set -e
    if [ "$check_rc" -eq 0 ]; then
        check_pass "SDK pre-package checks" "All SDK checks passed"
    else
        check_fail "SDK pre-package checks" "Check failed (exit $check_rc) — see /tmp/nexarail-sdk-check-prepackage.log"
        echo ""
        echo "  ⚠️  Packaging will continue, but SDK checks reported failures."
        echo "     Review /tmp/nexarail-sdk-check-prepackage.log for details."
    fi
else
    check_skip "SDK pre-package checks" "check-sdk-packages.sh not found or not executable"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 1. Source version information
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Step 1: Source Version Information ─────────────────────────────"

NODE_VERSION=""
PYTHON_VERSION=""
SDK_VERSION=""

if [ -f "$NODE_CLIENT_DIR/VERSION" ]; then
    NODE_VERSION=$(cat "$NODE_CLIENT_DIR/VERSION" | tr -d '[:space:]')
    check_pass "Node version" "$NODE_VERSION"
else
    check_fail "Node version" "VERSION file not found in $NODE_CLIENT_DIR"
    NODE_VERSION="0.0.0"
fi

if [ -f "$PYTHON_CLIENT_DIR/VERSION" ]; then
    PYTHON_VERSION=$(cat "$PYTHON_CLIENT_DIR/VERSION" | tr -d '[:space:]')
    check_pass "Python version" "$PYTHON_VERSION"
else
    check_fail "Python version" "VERSION file not found in $PYTHON_CLIENT_DIR"
    PYTHON_VERSION="0.0.0"
fi

# Use project-level VERSION if exists, otherwise use node version
if [ -f "$PROJECT_DIR/VERSION" ]; then
    SDK_VERSION=$(cat "$PROJECT_DIR/VERSION" | tr -d '[:space:]')
else
    SDK_VERSION="$NODE_VERSION"
fi

echo "    SDK version: $SDK_VERSION"

# ═══════════════════════════════════════════════════════════════════════════
# 2. Create releases/sdk-local/ directory
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Step 2: Prepare Output Directory ───────────────────────────────"

mkdir -p "$RELEASES_DIR"
check_pass "Output directory" "$RELEASES_DIR"

# ═══════════════════════════════════════════════════════════════════════════
# 3. Package Node.js client archive
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Step 3: Package Node.js Client ─────────────────────────────────"

NODE_TGZ="nexarail-node-devnet-client-${NODE_VERSION}.tgz"
NODE_TGZ_PATH="$RELEASES_DIR/$NODE_TGZ"

# Verify with npm pack --dry-run (soft-fail if npm not available)
NPM_DRY_RUN_OK=0
if command -v npm &>/dev/null && [ -f "$NODE_CLIENT_DIR/package.json" ]; then
    echo "    Running: npm pack --dry-run (from $NODE_CLIENT_DIR)"
    set +e
    npm_pack_output=$(cd "$NODE_CLIENT_DIR" && npm pack --dry-run 2>/dev/null)
    npm_pack_rc=$?
    set -e
    if [ "$npm_pack_rc" -eq 0 ]; then
        NPM_DRY_RUN_OK=1
        check_pass "npm pack --dry-run" "Node package verified (safe)"
    else
        check_fail "npm pack --dry-run" "npm pack reported issues (exit $npm_pack_rc) — proceeding with manual tar"
    fi
else
    check_skip "npm pack --dry-run" "npm not available — proceeding with manual tar"
fi

# Create manual .tgz archive using tar directly
echo "    Creating archive: $NODE_TGZ"
set +e
cd "$PROJECT_DIR/examples" && tar -czf "$NODE_TGZ_PATH" node-client/ 2>&1
tar_rc=$?
set -e

if [ "$tar_rc" -eq 0 ] && [ -f "$NODE_TGZ_PATH" ]; then
    NODE_SIZE=$(stat -f "%z" "$NODE_TGZ_PATH" 2>/dev/null || stat --format="%s" "$NODE_TGZ_PATH" 2>/dev/null || echo "?")
    check_pass "Node archive created" "$NODE_TGZ ($NODE_SIZE bytes)"
else
    check_fail "Node archive creation" "tar failed (exit $tar_rc)"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 4. Package Python client archive
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Step 4: Package Python Client ──────────────────────────────────"

PYTHON_TGZ="nexarail-python-devnet-client-${PYTHON_VERSION}.tar.gz"
PYTHON_TGZ_PATH="$RELEASES_DIR/$PYTHON_TGZ"

# Create source tar.gz archive of examples/python-client/
echo "    Creating archive: $PYTHON_TGZ"
set +e
cd "$PROJECT_DIR/examples" && tar -czf "$PYTHON_TGZ_PATH" python-client/ 2>&1
py_tar_rc=$?
set -e

if [ "$py_tar_rc" -eq 0 ] && [ -f "$PYTHON_TGZ_PATH" ]; then
    PYTHON_SIZE=$(stat -f "%z" "$PYTHON_TGZ_PATH" 2>/dev/null || stat --format="%s" "$PYTHON_TGZ_PATH" 2>/dev/null || echo "?")
    check_pass "Python archive created" "$PYTHON_TGZ ($PYTHON_SIZE bytes)"
else
    check_fail "Python archive creation" "tar failed (exit $py_tar_rc)"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 5. Generate SHA256 checksums
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Step 5: Generate SHA256 Checksums ──────────────────────────────"

CHECKSUMS_FILE="$RELEASES_DIR/checksums.sha256"

# Remove existing checksums file if present
rm -f "$CHECKSUMS_FILE"

# Generate SHA256 checksums for each archive
sha_ok=0
sha_fail=0

for archive in "$NODE_TGZ_PATH" "$PYTHON_TGZ_PATH"; do
    if [ -f "$archive" ]; then
        archivename=$(basename "$archive")
        checksum=$(shasum -a 256 "$archive" | awk '{print $1}')
        echo "$checksum  $archivename" >> "$CHECKSUMS_FILE"
        check_pass "SHA256 for $archivename" "$checksum"
        sha_ok=$((sha_ok + 1))
    else
        archivename=$(basename "$archive")
        check_skip "SHA256 for $archivename" "Archive not found, skipping checksum"
        sha_fail=$((sha_fail + 1))
    fi
done

if [ "$sha_ok" -gt 0 ] && [ -f "$CHECKSUMS_FILE" ]; then
    check_pass "Checksums file" "$CHECKSUMS_FILE"
else
    check_fail "Checksums file" "No checksums were generated"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 6. Generate manifest.json
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Step 6: Generate Manifest ──────────────────────────────────────"

MANIFEST_FILE="$RELEASES_DIR/manifest.json"

# Compute SHA256 for each archive (for manifest)
NODE_SHA256=""
PYTHON_SHA256=""

if [ -f "$NODE_TGZ_PATH" ]; then
    NODE_SHA256=$(shasum -a 256 "$NODE_TGZ_PATH" | awk '{print $1}')
fi
if [ -f "$PYTHON_TGZ_PATH" ]; then
    PYTHON_SHA256=$(shasum -a 256 "$PYTHON_TGZ_PATH" | awk '{print $1}')
fi

CREATED_AT=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

cat > "$MANIFEST_FILE" <<EOF
{
  "sdk_version": "${SDK_VERSION}",
  "compatible_rc": "nexarail-devnet-1",
  "created_at": "${CREATED_AT}",
  "publishing_status": "not_published",
  "node": {
    "name": "@nexarail/devnet-client",
    "version": "${NODE_VERSION}",
    "source": "examples/node-client/",
    "archive": "${NODE_TGZ}",
    "sha256": "${NODE_SHA256}"
  },
  "python": {
    "name": "nexarail-devnet-client",
    "version": "${PYTHON_VERSION}",
    "source": "examples/python-client/",
    "archive": "${PYTHON_TGZ}",
    "sha256": "${PYTHON_SHA256}"
  },
  "notes": "LOCAL DEVNET ONLY — NOT PUBLISHED to npm or PyPI. For internal developer review only."
}
EOF

if [ -f "$MANIFEST_FILE" ]; then
    check_pass "Manifest created" "$MANIFEST_FILE"
else
    check_fail "Manifest creation" "Failed to write $MANIFEST_FILE"
fi

# ═══════════════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  SDK Local Package — Summary                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "  Archives:"
for archive in "$NODE_TGZ_PATH" "$PYTHON_TGZ_PATH"; do
    if [ -f "$archive" ]; then
        archivename=$(basename "$archive")
        archsize=$(stat -f "%z" "$archive" 2>/dev/null || stat --format="%s" "$archive" 2>/dev/null || echo "?")
        archsha=$(shasum -a 256 "$archive" | awk '{print $1}')
        printf "    📦 %-55s %8s bytes\n" "$archivename" "$archsize"
        printf "       SHA256: %s\n" "$archsha"
    else
        archivename=$(basename "$archive")
        printf "    ❌ %-55s %s\n" "$archivename" "NOT FOUND"
    fi
done

echo ""
echo "  Manifest:  $MANIFEST_FILE"
echo "  Checksums: $CHECKSUMS_FILE"
echo ""

echo "── Step Results ────────────────────────────────────────────────"
printf "  PASS: %d  |  FAIL: %d  |  SKIP: %d\n" "$PASS" "$FAIL" "$SKIP"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "  ⚠️  ${FAIL} failure(s) during packaging."
    echo "     Archives may be incomplete. Review output above."
    exit 1
else
    echo "  ✅ All packaging steps completed successfully."
    echo "     Archives available in: $RELEASES_DIR"
    echo "     These archives are LOCAL DEVNET ONLY — NOT for publishing."
    exit 0
fi
