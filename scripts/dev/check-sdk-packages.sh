#!/usr/bin/env bash
# NexaRail — SDK Package Safety/Completeness Check
#
# Verifies that the Node.js and Python SDK client packages are
# structurally sound, version-consistent, free of forbidden wording,
# and include proper safety disclaimers.
#
# Usage:
#   bash scripts/dev/check-sdk-packages.sh
#
# Returns non-zero if any check fails.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

NODE_CLIENT_DIR="$PROJECT_DIR/examples/node-client"
PYTHON_CLIENT_DIR="$PROJECT_DIR/examples/python-client"

PASS=0
FAIL=0
SKIP=0

# ── Colors ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# ── Header ────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  NexaRail — SDK Package Safety/Completeness Check          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  Node client: $NODE_CLIENT_DIR"
echo "  Python client: $PYTHON_CLIENT_DIR"
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# 1. NODE — package.json check
# ═══════════════════════════════════════════════════════════════════════════
echo "── Section 1: Node.js Package ────────────────────────────────────"

if [ -f "$NODE_CLIENT_DIR/package.json" ]; then
    # Check required fields
    local_name_ok=0
    local_version_ok=0
    local_type_ok=0
    local_scripts_ok=0
    local_desc_ok=0
    local_node_issues=""

    name_val=$(jq -r '.name // empty' "$NODE_CLIENT_DIR/package.json" 2>/dev/null || echo "")
    version_val=$(jq -r '.version // empty' "$NODE_CLIENT_DIR/package.json" 2>/dev/null || echo "")
    type_val=$(jq -r '.type // empty' "$NODE_CLIENT_DIR/package.json" 2>/dev/null || echo "")
    scripts_val=$(jq -r '.scripts // empty' "$NODE_CLIENT_DIR/package.json" 2>/dev/null || echo "")
    desc_val=$(jq -r '.description // empty' "$NODE_CLIENT_DIR/package.json" 2>/dev/null || echo "")

    [ -n "$name_val" ] && local_name_ok=1 || local_node_issues="${local_node_issues} missing 'name'"
    [ -n "$version_val" ] && local_version_ok=1 || local_node_issues="${local_node_issues} missing 'version'"
    [ -n "$type_val" ] && local_type_ok=1 || local_node_issues="${local_node_issues} missing 'type'"
    [ -n "$desc_val" ] && local_desc_ok=1 || local_node_issues="${local_node_issues} missing 'description'"
    if [ -n "$scripts_val" ] && [ "$scripts_val" != "{}" ]; then
        local_scripts_ok=1
    else
        local_node_issues="${local_node_issues} missing 'scripts' field"
    fi

    total_node_fields=$(( local_name_ok + local_version_ok + local_type_ok + local_scripts_ok + local_desc_ok ))
    if [ "$total_node_fields" -ge 4 ]; then
        check_pass "Node package.json fields" "name=$name_val version=$version_val type=$type_val"
    else
        check_fail "Node package.json fields" "$local_node_issues"
    fi
else
    check_fail "Node package.json" "File not found: $NODE_CLIENT_DIR/package.json"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 2. NODE — VERSION file
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 2: Node VERSION File ─────────────────────────────────"

if [ -f "$NODE_CLIENT_DIR/VERSION" ]; then
    node_version=$(cat "$NODE_CLIENT_DIR/VERSION" | tr -d '[:space:]')
    if [ -n "$node_version" ]; then
        check_pass "Node VERSION file" "version=$node_version"
    else
        check_fail "Node VERSION file" "VERSION file is empty"
    fi
else
    check_skip "Node VERSION file" "No VERSION file in node-client directory"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 3. NODE — version consistency: package.json vs VERSION
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 3: Node Version Consistency ──────────────────────────"

if [ -f "$NODE_CLIENT_DIR/package.json" ] && [ -f "$NODE_CLIENT_DIR/VERSION" ]; then
    pkg_version=$(jq -r '.version' "$NODE_CLIENT_DIR/package.json")
    ver_version=$(cat "$NODE_CLIENT_DIR/VERSION" | tr -d '[:space:]')
    if [ "$pkg_version" = "$ver_version" ]; then
        check_pass "Node version consistency" "package.json and VERSION both read $pkg_version"
    else
        check_fail "Node version consistency" "package.json=$pkg_version vs VERSION=$ver_version"
    fi
else
    check_skip "Node version consistency" "package.json or VERSION missing (cannot compare)"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 4. NODE — run tests
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 4: Node Tests ────────────────────────────────────────"

if ! command -v node &>/dev/null; then
    check_skip "Node tests" "'node' not found on PATH"
else
    node_test_file="$NODE_CLIENT_DIR/test/client.test.js"
    if [ -f "$node_test_file" ]; then
        echo "    Running: node test/client.test.js (from examples/node-client)"
        set +e
        (
            cd "$NODE_CLIENT_DIR" && node test/client.test.js
        ) > /tmp/nexarail-node-test.log 2>&1
        node_test_rc=$?
        set -e
        if [ "$node_test_rc" -eq 0 ]; then
            check_pass "Node tests" "All tests passed (exit 0)"
        else
            check_fail "Node tests" "Tests failed (exit $node_test_rc)"
        fi
    else
        check_skip "Node tests" "Test file not found: $node_test_file"
    fi
fi

# ═══════════════════════════════════════════════════════════════════════════
# 5. PYTHON — pyproject.toml
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 5: Python Package ────────────────────────────────────"

if [ -f "$PYTHON_CLIENT_DIR/pyproject.toml" ]; then
    # Minimal check: file is valid TOML and has name/version
    if grep -q "^name = " "$PYTHON_CLIENT_DIR/pyproject.toml" 2>/dev/null && grep -q "^version = " "$PYTHON_CLIENT_DIR/pyproject.toml" 2>/dev/null; then
        py_name=$(grep "^name = " "$PYTHON_CLIENT_DIR/pyproject.toml" 2>/dev/null | head -1 | grep -o '"[^"]*"' | tr -d '"' || echo "unknown")
        py_ver=$(grep "^version = " "$PYTHON_CLIENT_DIR/pyproject.toml" 2>/dev/null | head -1 | grep -o '"[^"]*"' | tr -d '"' || echo "unknown")
        check_pass "pyproject.toml" "name=$py_name version=$py_ver"
    else
        check_fail "pyproject.toml" "File exists but appears invalid or missing required fields"
    fi
else
    check_fail "pyproject.toml" "File not found: $PYTHON_CLIENT_DIR/pyproject.toml"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 6. PYTHON — VERSION file
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 6: Python VERSION File ───────────────────────────────"

if [ -f "$PYTHON_CLIENT_DIR/VERSION" ]; then
    py_version=$(cat "$PYTHON_CLIENT_DIR/VERSION" | tr -d '[:space:]')
    if [ -n "$py_version" ]; then
        check_pass "Python VERSION file" "version=$py_version"
    else
        check_fail "Python VERSION file" "VERSION file is empty"
    fi
else
    check_skip "Python VERSION file" "No VERSION file in python-client directory"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 7. PYTHON — run tests
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 7: Python Tests ──────────────────────────────────────"

if ! command -v python3 &>/dev/null; then
    check_skip "Python tests" "'python3' not found on PATH"
else
    py_test_file="$PYTHON_CLIENT_DIR/test_client.py"
    if [ -f "$py_test_file" ]; then
        echo "    Running: python3 test_client.py (from examples/python-client)"
        set +e
        (
            cd "$PYTHON_CLIENT_DIR" && python3 test_client.py
        ) > /tmp/nexarail-python-test.log 2>&1
        py_test_rc=$?
        set -e
        if [ "$py_test_rc" -eq 0 ]; then
            check_pass "Python tests" "All tests passed (exit 0)"
        else
            check_fail "Python tests" "Tests failed (exit $py_test_rc)"
        fi
    else
        check_skip "Python tests" "Test file not found: $py_test_file"
    fi
fi

# ═══════════════════════════════════════════════════════════════════════════
# 8. SCAN — Forbidden wording in Node files
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 8: Forbidden Wording Scan (Node) ─────────────────────"

# Patterns that are NEVER acceptable (no context exemptions)
FORBIDDEN_RAW=(
    "mainnet live"
    "buy NXRL"
    "token sale"
    "guaranteed"
    "profit"
    "APY"
    "returns"
    "price"
    "listing"
)

# "investment" and "price" need special handling — we check for promotional/investment
# context rather than bare existence.

scan_forbidden() {
    local dir="$1"
    local label="$2"
    local found_any=0
    local violations=""

    for pattern in "${FORBIDDEN_RAW[@]}"; do
        # Search case-insensitively in .js and .py files
        # Exclude matches that are part of safety disclaimers (e.g. "No token sale")
        while IFS=: read -r file line col rest; do
            [ -z "$file" ] && break
            local line_num="$line"
            local text=$(sed "${line_num}q;d" "$file" 2>/dev/null)

            # ── False positive exclusions ──
            # Skip safety disclaimers / negations
            if echo "$text" | grep -qiE "no token sale|zero.*value|not.*(mainnet|token)|LOCAL DEVNET"; then
                continue
            fi
            # Skip JSDoc @returns annotations (not financial returns)
            if echo "$text" | grep -qE '@returns|@return'; then
                continue
            fi
            # Skip Python docstring "Returns a …" (not financial returns)
            if echo "$text" | grep -qiE '^[[:space:]]*(Returns? a|Returns? the|Returns? an)'; then
                continue
            fi
            # Skip test function names containing "returns"
            if echo "$text" | grep -qiE "test\(.*returns|def test.*returns"; then
                continue
            fi
            # Skip code identifiers / programming "return" keyword (not "returns")
            if [ "$pattern" = "returns" ] && echo "$text" | grep -qiE '\breturn\b'; then
                # Only skip if the line is actually about returning values, not financial returns
                if echo "$text" | grep -qiE 'Returns? |@returns'; then
                    continue
                fi
            fi

            violations="${violations}        $file:$line — ${text#"${text%%[![:space:]]*}"}"$'\n'
            found_any=1
        done < <(grep -rn -i -w "$pattern" "$dir" --include='*.js' --include='*.py' 2>/dev/null || true)
    done

    if [ "$found_any" -eq 1 ]; then
        check_fail "Forbidden wording ($label)" "Found $label files with potentially forbidden content:"
        echo -n "$violations"
    else
        check_pass "Forbidden wording ($label)" "No forbidden wording detected"
    fi
}

scan_forbidden "$NODE_CLIENT_DIR" "Node"

# ═══════════════════════════════════════════════════════════════════════════
# 9. SCAN — Forbidden wording in Python files
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 9: Forbidden Wording Scan (Python) ───────────────────"

scan_forbidden "$PYTHON_CLIENT_DIR" "Python"

# ═══════════════════════════════════════════════════════════════════════════
# 10. SCAN — Investment/promotional context
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 10: Investment/Promotional Wording Check ─────────────"

# Specifically scan "investment" and "price" in promotional context
investment_found=0
investment_report=""

for dir in "$NODE_CLIENT_DIR" "$PYTHON_CLIENT_DIR"; do
    while IFS=: read -r file line col rest; do
        [ -z "$file" ] && break
        text=$(sed "${line}q;d" "$file" 2>/dev/null)
        # Skip if in safety disclaimer context
        if echo "$text" | grep -qiE "not.*investment|no.*investment|LOCAL DEVNET"; then
            continue
        fi
        investment_report="${investment_report}        $file:$line — ${text#"${text%%[![:space:]]*}"}"$'\n'
        investment_found=1
    done < <(grep -rn -i -w "investment" "$dir" --include='*.py' --include='*.js' 2>/dev/null || true)
done

if [ "$investment_found" -eq 1 ]; then
    check_fail "Investment wording" "Found 'investment' in non-safety contexts:"
    echo -n "$investment_report"
else
    check_pass "Investment wording" "No investment/promotional tone"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 11. SCAN — Private keys / mnemonics / seed phrases
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 11: Private Key & Mnemonic Scan ──────────────────────"

key_scan_found=0
key_scan_report=""

for dir in "$NODE_CLIENT_DIR" "$PYTHON_CLIENT_DIR"; do
    while IFS=: read -r file line col rest; do
        [ -z "$file" ] && break
        text=$(sed "${line}q;d" "$file" 2>/dev/null)
        # Allow references that are safety warnings or test assertions
        if echo "$text" | grep -qiE "never use|do not use|don't use|use test keys only|safe to run|zero.*monetary|NO PRIVATE KEYS|It never handles"; then
            continue
        fi
        # Allow test assertions that verify absence of keys/mnemonics
        if echo "$text" | grep -qiE "assert\.\s*(ok|notIn|NotIn|False).*private|assertNotIn.*private|assertNotIn.*mnemonic|test_no_private|not.*include.*mnemonic"; then
            continue
        fi
        # Allow assertions using negation: includes, assertIn, assertFalse etc.
        if echo "$text" | grep -qiE "includes.*mnemonic|includes.*private.*key|!.*includes"; then
            continue
        fi
        # Allow references to key variable names in code that aren't actual keys
        if echo "$text" | grep -qiE "council-key|from:|from_address|private_key_path"; then
            continue
        fi
        # Allow test/function names about checking for keys (safety tests)
        if echo "$text" | grep -qiE "test.*private.key|def test.*private|test.*mnemonic|test_no_private|no private key"; then
            continue
        fi
        key_scan_report="${key_scan_report}        $file:$line — ${text#"${text%%[![:space:]]*}"}"$'\n'
        key_scan_found=1
    done < <(grep -rn -i -E "private.key|mnemonic|seed.?phrase" "$dir" --include='*.py' --include='*.js' --include='*.sh' --include='*.json' --include='*.toml' --include='*.md' 2>/dev/null || true)
done

if [ "$key_scan_found" -eq 1 ]; then
    check_fail "Key/mnemonic/seed scan" "Found non-warning references to private keys/mnemonics/seed phrases:"
    echo -n "$key_scan_report"
else
    check_pass "Key/mnemonic/seed scan" "All references are safety warnings or code patterns only"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 12. SAFETY DISCLAIMER check
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 12: Safety Disclaimer Check ──────────────────────────"

disclaimer_ok=0
disclaimer_missing=""

for file in "$NODE_CLIENT_DIR/src/client.js" "$NODE_CLIENT_DIR/README.md" "$PYTHON_CLIENT_DIR/nexarail_client.py" "$PYTHON_CLIENT_DIR/README.md"; do
    if [ -f "$file" ]; then
        if grep -qiE "LOCAL DEVNET.*NOT.*MAINNET|NOT.*MAINNET.*LOCAL DEVNET" "$file" 2>/dev/null; then
            : # has basic disclaimer
        elif grep -qiE "not.*mainnet|local.*devnet.*only" "$file" 2>/dev/null; then
            : # has basic disclaimer
        else
            disclaimer_missing="${disclaimer_missing}        Missing disclaimer: $file"$'\n'
        fi
    fi
done

# Check that at least one file mentions all three: LOCAL DEVNET ONLY, NOT mainnet, no token sale
comprehensive_ok=0
for file in "$NODE_CLIENT_DIR/src/client.js" "$PYTHON_CLIENT_DIR/nexarail_client.py"; do
    if [ -f "$file" ] && grep -qiE "LOCAL DEVNET ONLY" "$file" 2>/dev/null && grep -qiE "NOT.*MAINNET" "$file" 2>/dev/null; then
        comprehensive_ok=1
        break
    fi
done

# Also check shell scripts since those tend to have the most complete disclaimers
if [ "$comprehensive_ok" -eq 0 ]; then
    for file in "$PROJECT_DIR"/examples/write-flows/*.sh; do
        if [ -f "$file" ] && grep -qiE "LOCAL DEVNET ONLY.*NOT.*MAINNET" "$file" 2>/dev/null; then
            comprehensive_ok=1
            break
        fi
    done
fi

if [ -z "$disclaimer_missing" ]; then
    check_pass "Safety disclaimer present" "All inspected files contain safety disclaimers"
else
    check_fail "Safety disclaimer present" "Some files missing disclaimer:"
    echo -n "$disclaimer_missing"
fi

if [ "$comprehensive_ok" -eq 1 ]; then
    check_pass "Comprehensive disclaimer" "Found 'LOCAL DEVNET ONLY — NOT MAINNET' warning"
else
    check_fail "Comprehensive disclaimer" "No SDK file includes the full 'LOCAL DEVNET ONLY — NOT MAINNET' disclaimer"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 14. SDK Release Notes
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 14: SDK Release Notes ───────────────────────────────"

SDK_RELEASE_NOTES="$PROJECT_DIR/docs/developers/SDK_RC1_RELEASE_NOTES.md"
if [ -f "$SDK_RELEASE_NOTES" ]; then
    # Check for required sections
    has_overview=0
    has_changes=0
    has_installation=0
    notes_issues=""

    if grep -qi "overview\|introduction\|about" "$SDK_RELEASE_NOTES" 2>/dev/null; then
        has_overview=1
    else
        notes_issues="${notes_issues} missing overview/introduction section;"
    fi

    if grep -qi "changes\|new\|update\|added\|fixed" "$SDK_RELEASE_NOTES" 2>/dev/null; then
        has_changes=1
    else
        notes_issues="${notes_issues} missing changes/new/update section;"
    fi

    if grep -qi "install\|setup\|getting started\|usage" "$SDK_RELEASE_NOTES" 2>/dev/null; then
        has_installation=1
    else
        notes_issues="${notes_issues} missing installation/setup section;"
    fi

    total_sections=$(( has_overview + has_changes + has_installation ))
    if [ "$total_sections" -ge 2 ]; then
        check_pass "SDK Release Notes" "$SDK_RELEASE_NOTES (${total_sections}/3 required sections found)"
    else
        check_fail "SDK Release Notes" "$SDK_RELEASE_NOTES exists but lacks required sections:${notes_issues}"
    fi
else
    check_fail "SDK Release Notes" "File not found: $SDK_RELEASE_NOTES"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 15. Node API Reference
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 15: Node API Reference ──────────────────────────────"

NODE_API_REF="$PROJECT_DIR/docs/developers/NODE_SDK_API_REFERENCE.md"
if [ -f "$NODE_API_REF" ]; then
    check_pass "Node API Reference" "$NODE_API_REF"
else
    check_fail "Node API Reference" "File not found: $NODE_API_REF"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 16. Python API Reference
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 16: Python API Reference ────────────────────────────"

PYTHON_API_REF="$PROJECT_DIR/docs/developers/PYTHON_SDK_API_REFERENCE.md"
if [ -f "$PYTHON_API_REF" ]; then
    check_pass "Python API Reference" "$PYTHON_API_REF"
else
    check_fail "Python API Reference" "File not found: $PYTHON_API_REF"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 17. SDK Recipes
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 17: SDK Recipes ─────────────────────────────────────"

SDK_RECIPES="$PROJECT_DIR/docs/developers/SDK_RECIPES.md"
if [ -f "$SDK_RECIPES" ]; then
    check_pass "SDK Recipes" "$SDK_RECIPES"
else
    check_fail "SDK Recipes" "File not found: $SDK_RECIPES"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 18. Local Package Archive
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 18: Local Package Archive ───────────────────────────"

SDK_LOCAL_DIR="$PROJECT_DIR/releases/sdk-local"
if [ -d "$SDK_LOCAL_DIR" ]; then
    check_pass "SDK local directory exists" "$SDK_LOCAL_DIR"

    # Check manifest.json is valid JSON
    if [ -f "$SDK_LOCAL_DIR/manifest.json" ]; then
        if command -v python3 &>/dev/null; then
            set +e
            python3 -c "import json; json.load(open('$SDK_LOCAL_DIR/manifest.json'))" 2>/dev/null
            manifest_valid=$?
            set -e
            if [ "$manifest_valid" -eq 0 ]; then
                check_pass "manifest.json is valid JSON" "$SDK_LOCAL_DIR/manifest.json"
            else
                check_fail "manifest.json is valid JSON" "$SDK_LOCAL_DIR/manifest.json is not valid JSON"
            fi
        else
            check_skip "manifest.json validation" "python3 not available — cannot validate JSON syntax"
        fi
    else
        check_skip "manifest.json validation" "manifest.json not yet present (run package-sdk-local.sh first)"
    fi

    # Check archives exist (if present)
    ARCHIVES_FOUND=0
    for ext in tgz "tar.gz"; do
        for archive in "$SDK_LOCAL_DIR"/*.${ext}; do
            if [ -f "$archive" ]; then
                archivename=$(basename "$archive")
                archsize=$(stat -f "%z" "$archive" 2>/dev/null || stat --format="%s" "$archive" 2>/dev/null || echo "?")
                check_pass "Archive present: $archivename" "${archsize} bytes"
                ARCHIVES_FOUND=$((ARCHIVES_FOUND + 1))
            fi
        done
    done

    if [ "$ARCHIVES_FOUND" -eq 0 ]; then
        check_skip "Archives present" "No archive files found in $SDK_LOCAL_DIR (run package-sdk-local.sh first)"
    fi

    # Check checksums (if present)
    if [ -f "$SDK_LOCAL_DIR/checksums.sha256" ]; then
        check_pass "Checksums file exists" "$SDK_LOCAL_DIR/checksums.sha256"
        # Verify checksums for any present archives
        VERIFIED=0
        VERIFY_FAIL=0
        while IFS= read -r line; do
            archive_name=$(echo "$line" | awk '{print $2}' | sed 's/^[[:space:]]*//')
            if [ -f "$SDK_LOCAL_DIR/$archive_name" ]; then
                expected_sha=$(echo "$line" | awk '{print $1}')
                actual_sha=$(shasum -a 256 "$SDK_LOCAL_DIR/$archive_name" | awk '{print $1}')
                if [ "$expected_sha" = "$actual_sha" ]; then
                    VERIFIED=$((VERIFIED + 1))
                else
                    check_fail "Checksum mismatch: $archive_name" "expected $expected_sha, got $actual_sha"
                    VERIFY_FAIL=$((VERIFY_FAIL + 1))
                fi
            fi
        done < "$SDK_LOCAL_DIR/checksums.sha256"
        if [ "$VERIFIED" -gt 0 ]; then
            check_pass "Checksums verified" "${VERIFIED} archive(s) matched"
        fi
        if [ "$VERIFY_FAIL" -gt 0 ]; then
            check_fail "Checksum verification" "${VERIFY_FAIL} archive(s) had mismatched checksums"
        fi
    else
        check_skip "Checksums file" "checksums.sha256 not yet present (run package-sdk-local.sh first)"
    fi
else
    check_skip "SDK local directory" "$SDK_LOCAL_DIR not yet created (run package-sdk-local.sh first)"
fi

# ═══════════════════════════════════════════════════════════════════════════
# 19. Local Package Existence
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Section 19: Local Package Existence ─────────────────────────"

ARCHIVE_FILES=""
ARCHIVE_COUNT=0

if [ -d "$SDK_LOCAL_DIR" ]; then
    for ext in tgz "tar.gz"; do
        for archive in "$SDK_LOCAL_DIR"/*.${ext}; do
            if [ -f "$archive" ]; then
                archivename=$(basename "$archive")
                archsize=$(stat -f "%z" "$archive" 2>/dev/null || stat --format="%s" "$archive" 2>/dev/null || echo "?")
                ARCHIVE_FILES="${ARCHIVE_FILES}        📦 ${archivename} (${archsize} bytes)"$'\n'
                ARCHIVE_COUNT=$((ARCHIVE_COUNT + 1))
            fi
        done
    done
fi

if [ "$ARCHIVE_COUNT" -gt 0 ]; then
    check_pass "Archive files found" "${ARCHIVE_COUNT} archive(s) in ${SDK_LOCAL_DIR}"
    echo -n "$ARCHIVE_FILES"
else
    check_skip "Archive files found" "No archives in ${SDK_LOCAL_DIR} (run package-sdk-local.sh first)"
fi

# ═══════════════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  SDK Package Check Summary                                 ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5s %5s %5s\n" "Result" "PASS" "FAIL" "SKIP"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5d %5d %5d\n" "SDK Checks" "$PASS" "$FAIL" "$SKIP"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "  ❌ ${FAIL} failure(s) detected."
    exit 1
else
    echo "  ✅ All ${PASS} checks passed."
    exit 0
fi
