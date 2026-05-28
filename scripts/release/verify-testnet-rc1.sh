#!/usr/bin/env bash
#
# verify-testnet-rc1.sh — NexaRail Testnet RC1 Packaging Verification
#
# Checks all required binaries, docs, scripts, and release assets
# are present and correctly formed. Exits with failure count.
#
# Usage: ./scripts/release/verify-testnet-rc1.sh
# Run from repo root: /Users/bradleyjohnston/workspace/nexarail

set -euo pipefail

# ── Colours ──────────────────────────────────────────────
PASS="✅ "
FAIL="❌ "
INFO="ℹ️  "
RESET=""

# ── Counters ─────────────────────────────────────────────
passed=0
failed=0

# ── Helpers ──────────────────────────────────────────────
check_file() {
    local label="$1" path="$2"
    if [[ -f "$path" ]]; then
        echo "${PASS}${label}${RESET}"
        passed=$((passed + 1))
    else
        echo "${FAIL}${label}${RESET}"
        failed=$((failed + 1))
    fi
}

check_dir() {
    local label="$1" path="$2"
    if [[ -d "$path" ]]; then
        echo "${PASS}${label}${RESET}"
        passed=$((passed + 1))
    else
        echo "${FAIL}${label}${RESET}"
        failed=$((failed + 1))
    fi
}

check_no_file() {
    local label="$1"
    local glob="$2"
    local matches
    matches=$(find "$RELEASE_DIR" -type f -name "$glob" 2>/dev/null || true)
    if [[ -z "$matches" ]]; then
        echo "${PASS}${label}${RESET}"
        passed=$((passed + 1))
    else
        echo "${FAIL}${label} — found: $matches${RESET}"
        failed=$((failed + 1))
    fi
}

check_no_path_containing() {
    local label="$1"
    local pattern="$2"
    local matches
    matches=$(find "$RELEASE_DIR" -type f -name "$pattern" 2>/dev/null || true)
    if [[ -z "$matches" ]]; then
        echo "${PASS}${label}${RESET}"
        passed=$((passed + 1))
    else
        echo "${FAIL}${label} — found: $matches${RESET}"
        failed=$((failed + 1))
    fi
}

verify_checksum() {
    local binary="$1" expected_hash="$2"
    local actual_hash
    if [[ ! -f "$binary" ]]; then
        echo "${FAIL}Checksum: $binary not found${RESET}"
        failed=$((failed + 1))
        return
    fi
    if command -v shasum &>/dev/null; then
        actual_hash=$(shasum -a 256 "$binary" | cut -d' ' -f1)
    elif command -v sha256sum &>/dev/null; then
        actual_hash=$(sha256sum "$binary" | cut -d' ' -f1)
    else
        echo "${FAIL}Checksum: no sha256 tool available${RESET}"
        failed=$((failed + 1))
        return
    fi
    if [[ "$actual_hash" == "$expected_hash" ]]; then
        echo "${PASS}Checksum: $(basename "$binary") matches${RESET}"
        passed=$((passed + 1))
    else
        echo "${FAIL}Checksum: $(basename "$binary") MISMATCH (expected $expected_hash, got $actual_hash)${RESET}"
        failed=$((failed + 1))
    fi
}

# ── Determine paths ──────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RELEASE_DIR="$REPO_ROOT/releases/testnet-rc1"
BIN_DIR="$RELEASE_DIR/binaries"
CHECKSUM_FILE="$RELEASE_DIR/checksums/SHA256SUMS"

echo ""
echo "══════════════════════════════════════════════════════"
echo "  NexaRail Testnet RC1 — Packaging Verification"
echo "  Date:            $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "  Repo root:       $REPO_ROOT"
echo "  Release dir:     $RELEASE_DIR"
echo "══════════════════════════════════════════════════════"
echo ""

# ── 1. Verify release root directory ────────────────────
echo "── [Release Directory] ──────────────────────────────"
check_dir  "Release root exists" "$RELEASE_DIR"

# ── 2. Verify binaries exist ────────────────────────────
echo ""
echo "── [Binaries] ───────────────────────────────────────"
check_file "nexaraild-darwin-arm64" "$BIN_DIR/nexaraild-darwin-arm64"
check_file "nexaraild-linux-amd64"  "$BIN_DIR/nexaraild-linux-amd64"

# ── 3. Verify checksums match ────────────────────────────
echo ""
echo "── [Checksums] ──────────────────────────────────────"
check_file "SHA256SUMS file" "$CHECKSUM_FILE"

if [[ -f "$CHECKSUM_FILE" ]]; then
    # Parse expected hashes (base-relative paths in the checksum file)
    while IFS=' ' read -r expected_hash _relpath; do
        [[ -z "$expected_hash" || "$expected_hash" == \#* ]] && continue
        # Convert relative path to absolute
        abs_path="$REPO_ROOT/$_relpath"
        if [[ -f "$abs_path" ]]; then
            verify_checksum "$abs_path" "$expected_hash"
        else
            # Try relative to release dir
            abs_path2="$RELEASE_DIR/$_relpath"
            if [[ -f "$abs_path2" ]]; then
                verify_checksum "$abs_path2" "$expected_hash"
            else
                echo "${FAIL}Checksum entry file not found: $_relpath${RESET}"
                failed=$((failed + 1))
            fi
        fi
    done < "$CHECKSUM_FILE"
else
    echo "${FAIL}SHA256SUMS file missing — cannot verify checksums${RESET}"
    failed=$((failed + 1))
fi

# ── 4. Verify required docs exist ────────────────────────
echo ""
echo "── [Required Documentation] ─────────────────────────"

RELEASE_DOCS_DIR="$REPO_ROOT/docs/release"
API_DOCS_DIR="$REPO_ROOT/docs/api"
HARDENING_DOCS_DIR="$REPO_ROOT/docs/hardening"
RELEASE_RC_DOCS_DIR="$RELEASE_DIR/docs"

# release notes, limitations, evidence manifest in docs/release/
check_file "TESTNET_RC1_RELEASE_NOTES.md"            "$RELEASE_DOCS_DIR/TESTNET_RC1_RELEASE_NOTES.md"
check_file "TESTNET_RC1_KNOWN_LIMITATIONS.md"         "$RELEASE_DOCS_DIR/TESTNET_RC1_KNOWN_LIMITATIONS.md"
check_file "TESTNET_RC1_EVIDENCE_MANIFEST.md"         "$RELEASE_DOCS_DIR/TESTNET_RC1_EVIDENCE_MANIFEST.md"

# API docs
check_file "REST_READBACK_ROUTES.md"                  "$API_DOCS_DIR/REST_READBACK_ROUTES.md"
check_file "REST_READBACK_LIMITATIONS.md"             "$API_DOCS_DIR/REST_READBACK_LIMITATIONS.md"

# Hardening
check_file "PHASE_10B_PRODUCT_FLOW_READINESS_FINAL.md" "$HARDENING_DOCS_DIR/PHASE_10B_PRODUCT_FLOW_READINESS_FINAL.md"

# Litepaper
check_file "NEXARAIL_LITEPAPER.md"                    "$REPO_ROOT/docs/NEXARAIL_LITEPAPER.md"
check_file "NEXARAIL_LITEPAPER_SUMMARY.md"            "$REPO_ROOT/docs/NEXARAIL_LITEPAPER_SUMMARY.md"

# Reviewer docs
check_file "RC1_REVIEWER_README.md"                   "$RELEASE_DOCS_DIR/RC1_REVIEWER_README.md"
check_file "RC1_QUICKSTART.md"                        "$RELEASE_DOCS_DIR/RC1_QUICKSTART.md"
check_file "RC1_EVIDENCE_SUMMARY.md"                  "$RELEASE_DOCS_DIR/RC1_EVIDENCE_SUMMARY.md"
check_file "RC1_REVIEW_CHECKLIST.md"                  "$RELEASE_DOCS_DIR/RC1_REVIEW_CHECKLIST.md"

# ── 5. Verify required scripts exist ────────────────────
echo ""
echo "── [Required Scripts] ───────────────────────────────"

SCRIPTS_TESTNET_DIR="$REPO_ROOT/scripts/testnet"
SCRIPTS_RELEASE_DIR="$REPO_ROOT/scripts/release"

check_file "prepare-multi-machine-validator.sh"  "$SCRIPTS_TESTNET_DIR/prepare-multi-machine-validator.sh"
check_file "collect-multi-machine-evidence.sh"   "$SCRIPTS_TESTNET_DIR/collect-multi-machine-evidence.sh"
check_file "check-final-genesis.sh"              "$SCRIPTS_TESTNET_DIR/check-final-genesis.sh"
check_file "verify-submitted-gentx.sh"           "$SCRIPTS_TESTNET_DIR/verify-submitted-gentx.sh"
check_file "api-smoke-test.sh"                   "$SCRIPTS_TESTNET_DIR/api-smoke-test.sh"
check_file "predeployment-check.sh"              "$SCRIPTS_TESTNET_DIR/predeployment-check.sh"
check_file "verify-testnet-rc1.sh (itself)"      "$SCRIPTS_RELEASE_DIR/verify-testnet-rc1.sh"

# ── 6. Verify no private key PEM files ──────────────────
echo ""
echo "── [Security: No Private Keys] ──────────────────────"

# Search the entire release directory for PEM files that look like private keys
pem_hits=$(find "$RELEASE_DIR" -type f \( -name "*.pem" -o -name "*.key" -o -name "priv_validator*" \) 2>/dev/null || true)
hidden_key_hits=$(find "$RELEASE_DIR" -type f -name "node_key*" 2>/dev/null || true)

combined_hits=""
if [[ -n "$pem_hits" ]]; then
    combined_hits="$pem_hits"
fi
if [[ -n "$hidden_key_hits" ]]; then
    combined_hits="$combined_hits"$'\n'"$hidden_key_hits"
fi

if [[ -z "$combined_hits" ]]; then
    echo "${PASS}No private key PEM files in release dir${RESET}"
    passed=$((passed + 1))
else
    echo "${FAIL}Private key file(s) found in release dir:${RESET}"
    echo "$combined_hits"
    failed=$((failed + 1))
fi

# ── 7. Verify no agent home data ─────────────────────────
echo ""
echo "── [Security: No Agent Home Data] ───────────────────"

check_no_path_containing ".node_key (no agent home data)"  ".node_key"
check_no_path_containing "priv_validator_key (no agent home data)" "priv_validator_key*"

# Also check in release dir for any config/ or data/ directories that might
# contain agent home artifacts
node_key_result=$(find "$RELEASE_DIR" -type f \( -name ".node_key" -o -name "priv_validator_key*" -o -name "node_key.json" -o -name "priv_validator_key.json" \) 2>/dev/null || true)
if [[ -z "$node_key_result" ]]; then
    echo "${PASS}Release dir: no .node_key or priv_validator_key files${RESET}"
    passed=$((passed + 1))
else
    echo "${FAIL}Found agent home data in release dir: $node_key_result${RESET}"
    failed=$((failed + 1))
fi

# ── 8. Verify manifest exists ───────────────────────────
echo ""
echo "── [Manifests] ──────────────────────────────────────"
check_file "manifest.json" "$RELEASE_DIR/manifests/manifest.json"

# ── 9. Verify genesis README exists ─────────────────────
echo ""
echo "── [Genesis] ────────────────────────────────────────"
check_file "genesis/README.md" "$RELEASE_DIR/genesis/README.md"

# ── 10. Verify scripts in releases dir ──────────────────
echo ""
echo "── [Release Distribution Scripts] ───────────────────"
check_file "api-smoke-test.sh (release)"                  "$RELEASE_DIR/scripts/api-smoke-test.sh"
check_file "collect-multi-machine-evidence.sh (release)"  "$RELEASE_DIR/scripts/collect-multi-machine-evidence.sh"
check_file "prepare-multi-machine-validator.sh (release)" "$RELEASE_DIR/scripts/prepare-multi-machine-validator.sh"
check_file "check-final-genesis.sh (release)"             "$RELEASE_DIR/scripts/check-final-genesis.sh"
check_file "verify-submitted-gentx.sh (release)"          "$RELEASE_DIR/scripts/verify-submitted-gentx.sh"
check_file "predeployment-check.sh (release)"             "$RELEASE_DIR/scripts/predeployment-check.sh"

# ── Summary ─────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
echo "  Verification Complete"
echo "  Passed: $passed    Failed: $failed"
echo "══════════════════════════════════════════════════════"
echo ""

if [[ $failed -gt 0 ]]; then
    echo "${FAIL}RC1 packaging verification FAILED — $failed check(s) failed.${RESET}"
else
    echo "${PASS}RC1 packaging verification PASSED.${RESET}"
fi
echo ""

exit "$failed"
