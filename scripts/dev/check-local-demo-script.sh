#!/usr/bin/env bash
# NexaRail — Check Local Demo Script
#
# Safety and completeness check for scripts/dev/run-local-demo.sh.
# Verifies existence, syntax, referenced scripts, docs, forbidden wording,
# key leakage, and evidence file naming.
#
# Usage: bash scripts/dev/check-local-demo-script.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEMO_SCRIPT="$SCRIPT_DIR/run-local-demo.sh"

PASS=0
FAIL=0
FAILURES=""
CHECK_NUM=0

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  NexaRail — Local Demo Script Check                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

heading() { echo ""; echo "─── Check $CHECK_NUM: $* ───"; }
pass()   { echo "  ✅ PASS: $*"; PASS=$((PASS + 1)); }
fail()   { echo "  ❌ FAIL: $*"; FAIL=$((FAIL + 1)); FAILURES="${FAILURES}  FAIL: $*"$'\n'; }
skip()   { echo "  ⏭️  SKIP: $*"; }

count_matches() {
    local pattern="$1" file="$2"
    # grep -c prints count to stdout regardless of exit code.
    # Exit 1 (0 matches) should not trigger a || fallback duplicate.
    local c
    c=$(grep -ciE "$pattern" "$file" 2>/dev/null) || true
    printf '%s' "$c" | tr -dc '0-9'
}

# ── Check 1: Script exists and is executable ──────────────────────────────
CHECK_NUM=1
heading "File Existence and Executability"

if [ -f "$DEMO_SCRIPT" ]; then
    pass "run-local-demo.sh exists"
else
    fail "run-local-demo.sh not found at $DEMO_SCRIPT"
fi

if [ -x "$DEMO_SCRIPT" ]; then
    pass "run-local-demo.sh is executable"
else
    fail "run-local-demo.sh is NOT executable (run: chmod +x $DEMO_SCRIPT)"
    chmod +x "$DEMO_SCRIPT" 2>/dev/null && pass "Made executable"
fi

# ── Check 2: Bash syntax ────────────────────────────────────────────
CHECK_NUM=2
heading "Bash Syntax (bash -n)"

if [ -f "$DEMO_SCRIPT" ]; then
    if bash -n "$DEMO_SCRIPT" 2>/dev/null; then
        pass "bash -n: syntax OK"
    else
        SYNTAX_ERR=$(bash -n "$DEMO_SCRIPT" 2>&1 || true)
        fail "bash -n: syntax errors detected"
        echo "    $SYNTAX_ERR"
    fi
else
    skip "Script missing — cannot check syntax"
fi

# ── Check 3: All referenced scripts exist ───────────────────────────
CHECK_NUM=3
heading "Referenced Script Existence"

# run-local-demo.sh calls these scripts via bash subprocesses.
REFERRED_SCRIPTS=(
    "$PROJECT_DIR/scripts/release/launch-rc1-devnet.sh"
    "$PROJECT_DIR/scripts/release/stop-rc1-devnet.sh"
    "$PROJECT_DIR/scripts/dev/run-developer-examples-smoke.sh"
    "$PROJECT_DIR/scripts/dev/run-write-flow-examples-smoke.sh"
    "$PROJECT_DIR/scripts/dev/check-dashboard-files.sh"
    "$PROJECT_DIR/scripts/dev/serve-dashboard.sh"
)

for path in "${REFERRED_SCRIPTS[@]}"; do
    name="$(basename "$path")"
    if [ -f "$path" ]; then
        pass "Referenced script exists: $name"
    else
        fail "Referenced script NOT found: $path"
    fi
done

# ── Check 4: Referenced documentation exists ────────────────────────
CHECK_NUM=4
heading "Referenced Documentation Existence"

for doc in "docs/developers/LOCAL_DEMO_GUIDE.md" "docs/developers/DEVELOPER_QUICKSTART.md"; do
    if [ -f "$PROJECT_DIR/$doc" ]; then
        pass "Key doc exists: $doc"
    else
        skip "Key doc not found: $doc (not blocking)"
    fi
done

# ── Check 5: Forbidden wording ──────────────────────────────────────
CHECK_NUM=5
heading "Forbidden Wording Scan"

check_forbidden() {
    local pattern="$1" display="$2" negated_ok="${3:-0}"
    local total
    total=$(count_matches "$pattern" "$DEMO_SCRIPT")

    if [ "$total" = "0" ]; then
        pass "No forbidden wording: \"$display\""
        return
    fi

    if [ "$negated_ok" = "1" ]; then
        local negated
        negated=$(count_matches "no.*${pattern}" "$DEMO_SCRIPT")
        # Use awk-safe integer comparison since shell may struggle with heredoc
        if [ "$total" -le "$negated" ] 2>/dev/null; then
            pass "Forbidden pattern '$display' used only in safety negation ✓"
            echo "    (found $total occurrence(s), all properly negated)"
        else
            fail "Forbidden pattern '$display' found without proper negation"
            echo "    Found $total occurrences, only $negated negated"
            grep -inE "$pattern" "$DEMO_SCRIPT" 2>/dev/null | head -5 | sed 's/^/    /'
        fi
    else
        fail "Forbidden wording found: \"$display\""
        echo "    Found $total occurrence(s):"
        grep -inE "$pattern" "$DEMO_SCRIPT" 2>/dev/null | head -5 | sed 's/^/    /'
    fi
}

check_forbidden "mainnet.*live|live.*mainnet" "mainnet live / live mainnet" "1"
check_forbidden "buy.*NXRL|buy.*nxrl|purchase.*NXRL|purchase.*nxrl" "buy/purchase NXRL" "0"
check_forbidden "token.sale" "token sale" "1"
check_forbidden "(^|[^n][^o][^t] )investment" "investment as positive" "0"
check_forbidden "guaranteed" "guaranteed" "0"
check_forbidden "(^|[^a-z])profit([^a-z]|$)" "profit" "0"
check_forbidden "(^|[^a-z])APY([^a-z]|$)" "APY" "0"
check_forbidden "(^|[^a-z])returns([^a-z]|$)" "returns" "0"
check_forbidden "(^|[^a-z])price([^a-z]|$)" "price" "0"
check_forbidden "(^|[^a-z])listing([^a-z]|$)" "listing" "0"

# ── Check 6: Private key / mnemonic / seed phrase scan ────────────
CHECK_NUM=6
heading "Sensitive Key Material Scan"

check_sensitive() {
    local pattern="$1" display="$2"
    local total
    total=$(count_matches "$pattern" "$DEMO_SCRIPT")

    if [ "$total" = "0" ]; then
        pass "No sensitive term: \"$display\""
        return
    fi

    # Check if any occurrence is near a safety warning
    local has_warning=0
    while IFS=: read -r line_num rest; do
        [ -z "$line_num" ] && continue
        for offset in 0 1 2; do
            local check_line=$((line_num + offset))
            [ "$check_line" -lt 1 ] && continue
            local context
            context=$(sed -n "${check_line}p" "$DEMO_SCRIPT" 2>/dev/null || true)
            if echo "$context" | grep -qiE "warning|safety|unsafe|danger|not.*secure|never.*share|do.*not.*expose" 2>/dev/null; then
                has_warning=1
                break
            fi
        done
        [ "$has_warning" -eq 1 ] && break
    done < <(grep -inE "$pattern" "$DEMO_SCRIPT" 2>/dev/null || true)

    if [ "$has_warning" -eq 1 ]; then
        pass "Sensitive term '$display' has accompanying safety warning ✓"
    else
        fail "Sensitive term '$display' found without safety warning"
        grep -inE "$pattern" "$DEMO_SCRIPT" 2>/dev/null | head -3 | sed 's/^/    /'
    fi
}

check_sensitive "private.key" "private key"
check_sensitive "private_key" "private_key"
check_sensitive "mnemonic" "mnemonic"
check_sensitive "seed.phrase" "seed phrase"
check_sensitive "seed_phrase" "seed_phrase"
check_sensitive "secret.key" "secret key"
check_sensitive "secret_key" "secret_key"

# ── Check 7: Evidence file names are mentioned ─────────────────────
CHECK_NUM=7
heading "Evidence File Name References"

for ef in "summary.json" "summary.md" "devnet-status.json" "live-flags.json"; do
    if grep -qF "$ef" "$DEMO_SCRIPT" 2>/dev/null; then
        pass "Evidence file referenced: $ef"
    else
        fail "Evidence file NOT referenced: $ef"
    fi
done

if grep -q "EVIDENCE_DIR" "$DEMO_SCRIPT" 2>/dev/null; then
    pass "EVIDENCE_DIR variable is used for evidence output"
else
    fail "EVIDENCE_DIR variable not found in script"
fi

# ── Check 8: Safety banner present ────────────────────────────────
CHECK_NUM=8
heading "Safety Banner"

for phrase in "not mainnet" "no token sale" "zero monetary value"; do
    if grep -qiF "$phrase" "$DEMO_SCRIPT" 2>/dev/null; then
        pass "Safety phrase found: \"$phrase\""
    else
        fail "Safety phrase missing: \"$phrase\""
    fi
done

# ── Summary ─────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Local Demo Script Check — Summary"
echo "  PASS: $PASS  FAIL: $FAIL"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "  Script checked: $DEMO_SCRIPT"
echo "  Lines: $(wc -l < "$DEMO_SCRIPT" 2>/dev/null || echo "?")"

if [ -n "$FAILURES" ]; then
    echo ""
    echo "── Failures ──────────────────────────────────────────────"
    echo -n "$FAILURES"
fi

echo ""
exit "$FAIL"
