#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# check-dashboard-files.sh
#
# Smoke check for developer dashboard files.
# Verifies existence, safety markers, and forbidden patterns.
# Exits with the count of failures (0 = all good).
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DASHBOARD_DIR="${SCRIPT_DIR}/examples/dashboard"

PASS=0
FAIL=0
FAILURES=""

# ── helpers ────────────────────────────────────────────────────────────────
pass() { echo "  [PASS]  $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL]  $1"; FAIL=$((FAIL + 1)); FAILURES="${FAILURES}  FAIL: $1${2:+ ($2)}"$'\n'; }

heading() {
  echo ""
  echo "── $1 ───────────────────────────────────────"
}

pass_skip() {
  # Helper: mark pass if condition true, else fail
  local label="$1"
  shift
  if "$@"; then
    pass "$label"
  else
    fail "$label"
  fi
}

# ── main ───────────────────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════════"
echo "  NexaRail — Developer Dashboard File Check"
echo "  Dashboard: ${DASHBOARD_DIR}"
echo "═══════════════════════════════════════════════════════════════"

# ── 1. File existence checks ──────────────────────────────────────────────
heading "File Existence"

for file in index.html app.js styles.css README.md; do
  if [[ -f "${DASHBOARD_DIR}/${file}" ]]; then
    lines=$(wc -l < "${DASHBOARD_DIR}/${file}" | tr -d ' ')
    pass "${file} exists (${lines} lines)"
  else
    fail "${file} — not found"
  fi
done

# ── 2. Safety banner checks (index.html) ──────────────────────────────────
heading "Safety Banner (index.html)"

INDEX_FILE="${DASHBOARD_DIR}/index.html"

if [[ -f "$INDEX_FILE" ]]; then
  for phrase in "not mainnet" "no token sale" "no monetary value" "live funds disabled"; do
    if grep -qi "$phrase" "$INDEX_FILE" &>/dev/null; then
      pass "Safety banner phrase found: \"${phrase}\""
    else
      fail "Safety banner missing phrase: \"${phrase}\""
    fi
  done

  # Count occurrences of safety-like warnings as a summary
  safety_count=$(grep -ciE "(not.mainnet|no.token.sale|no.monetary.value|live.funds.disabled|for.demo.purposes|not.real.funds|testnet)" "$INDEX_FILE" 2>/dev/null || echo 0)
  echo "  → Safety-related markers found: ${safety_count}"
else
  fail "index.html not found — skipping safety banner checks"
  fail "index.html not found — skipping safety banner checks"
  fail "index.html not found — skipping safety banner checks"
  fail "index.html not found — skipping safety banner checks"
fi

# ── 3. Wallet/crypto code checks (app.js) ─────────────────────────────────
heading "Forbidden Code Patterns (app.js)"

APP_FILE="${DASHBOARD_DIR}/app.js"

if [[ -f "$APP_FILE" ]]; then
  for pattern in wallet privateKey mnemonic "private_key" "secret" "keystore"; do
    if grep -qi "$pattern" "$APP_FILE" &>/dev/null; then
      fail "Forbidden pattern found: \"${pattern}\""
    else
      pass "No \"${pattern}\" pattern found"
    fi
  done
else
  fail "app.js not found — skipping forbidden pattern checks"
  fail "app.js not found — skipping forbidden pattern checks"
  fail "app.js not found — skipping forbidden pattern checks"
  fail "app.js not found — skipping forbidden pattern checks"
  fail "app.js not found — skipping forbidden pattern checks"
fi

# ── 4. External API hardcoding check ──────────────────────────────────────
heading "External API Endpoints"

check_external_api() {
  local file="$1"
  local label="$2"
  if [[ ! -f "$file" ]]; then
    fail "${label} — file not found, skipping API check"
    return
  fi

  local api_lines
  # Find lines with http:// or https:// URLs that are NOT localhost
  api_lines=$(grep -noE 'https?://[a-zA-Z0-9.-]+' "$file" 2>/dev/null | grep -iv 'localhost\|docs\.nexarail\.dev\|github\.com' || true)

  if [[ -z "$api_lines" ]]; then
    pass "${label}: No external API endpoints hardcoded"
  else
    echo "  Found potential external endpoint(s) in ${label}:"
    while IFS= read -r line; do
      echo "    $line"
    done <<< "$api_lines"
    fail "${label}: External API endpoints found (see above)"
  fi
}

for file in index.html app.js styles.css; do
  [[ -f "${DASHBOARD_DIR}/${file}" ]] && check_external_api "${DASHBOARD_DIR}/${file}" "${file}"
done

# ── 5. Forbidden wording check ────────────────────────────────────────────
heading "Forbidden Wording"

forbidden_check() {
  local file="$1"
  local label="$2"
  if [[ ! -f "$file" ]]; then
    fail "${label} — file not found, skipping forbidden wording check"
    return
  fi

  local found=""

  # "mainnet live" (positive framing without safety qualifier)
  if grep -qiE '(mainnet.*live|live.*mainnet)' "$file" &>/dev/null; then
    found="${found}  → 'mainnet live' wording detected (should be 'not mainnet')\n"
  fi

  # "buy NXRL" or "buy \$NXRL" or "purchase NXRL" (suggests trading)
  if grep -qiE '(buy|purchase).*(NXRL|nxrl)' "$file" &>/dev/null; then
    found="${found}  → 'buy/purchase NXRL' wording detected\n"
  fi

  # "token sale" as positive (without "no" qualifier)
  if grep -qiE 'token.sale' "$file" &>/dev/null; then
    # Check if it's negated with "no"
    if ! grep -qiE 'no.*token.sale' "$file" &>/dev/null; then
      found="${found}  → 'token sale' detected without negative qualifier\n"
    fi
  fi

  if [[ -n "$found" ]]; then
    echo "  Forbidden wording in ${label}:"
    echo -e "$found"
    fail "${label}: Forbidden wording detected"
  else
    pass "${label}: No forbidden wording"
  fi
}

for file in index.html app.js styles.css README.md; do
  [[ -f "${DASHBOARD_DIR}/${file}" ]] && forbidden_check "${DASHBOARD_DIR}/${file}" "${file}"
done

# ── 6. Line counts summary ───────────────────────────────────────────────
heading "Line Counts"

echo "  File                      Lines"
echo "  ─────────────────────────────────"
total=0
for file in index.html app.js styles.css README.md; do
  if [[ -f "${DASHBOARD_DIR}/${file}" ]]; then
    lines=$(wc -l < "${DASHBOARD_DIR}/${file}" | tr -d ' ')
    printf "  %-25s %5d\n" "${file}" "${lines}"
    total=$((total + lines))
  else
    printf "  %-25s   %s\n" "${file}" "(missing)"
  fi
done
echo "  ─────────────────────────────────"
printf "  %-25s %5d\n" "Total" "${total}"

# ── Summary ───────────────────────────────────────────────────────────────
echo ""
echo "── Summary ──────────────────────────────────────────────────"
echo "  PASS: ${PASS}  FAIL: ${FAIL}"
echo "─────────────────────────────────────────────────────────────"

if [[ -n "$FAILURES" ]]; then
  echo ""
  echo "── Failures ──────────────────────────────────────────────"
  echo -n "$FAILURES"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
exit "$FAIL"
