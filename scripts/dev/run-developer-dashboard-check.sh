#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# run-developer-dashboard-check.sh
#
# Combined script for the RC1 developer dashboard:
#   1. Checks dashboard files for existence and safety markers
#   2. Optionally serves the dashboard (--serve) for a short period
#   3. Saves evidence to rehearsals/developer-dashboard/evidence/<timestamp>/
#   4. Writes summary evidence
#
# Usage: scripts/dev/run-developer-dashboard-check.sh [--serve [--duration SECS]]
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DASHBOARD_DIR="${SCRIPT_DIR}/examples/dashboard"
CHECK_SCRIPT="${SCRIPT_DIR}/scripts/dev/check-dashboard-files.sh"
SERVE_SCRIPT="${SCRIPT_DIR}/scripts/dev/serve-dashboard.sh"
EVIDENCE_DIR="${SCRIPT_DIR}/rehearsals/developer-dashboard/evidence/$(date +%Y%m%d-%H%M%S)"

SERVE_MODE=false
SERVE_DURATION=30

# ── parse args ─────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --serve)
      SERVE_MODE=true
      shift
      if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
        SERVE_DURATION="$1"
        shift
      fi
      ;;
    --duration)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --duration requires a value" >&2
        exit 1
      fi
      SERVE_DURATION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--serve [DURATION]]"
      echo ""
      echo "Checks developer dashboard files and optionally serves the dashboard."
      echo ""
      echo "Options:"
      echo "  --serve [DURATION]  Start server for DURATION seconds (default: 30)"
      echo "  --duration SECONDS  Duration to serve (alias for --serve SECONDS)"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 [--serve [DURATION]]" >&2
      exit 1
      ;;
  esac
done

# ── setup evidence directory ──────────────────────────────────────────────
mkdir -p "$EVIDENCE_DIR"

# Record environment info
cat > "${EVIDENCE_DIR}/env.txt" <<EOF
Script: run-developer-dashboard-check.sh
Date: $(date -u '+%Y-%m-%dT%H:%M:%SZ')
Host: $(hostname)
Dashboard: ${DASHBOARD_DIR}
Serve Mode: ${SERVE_MODE}
Serve Duration: ${SERVE_DURATION}s
EOF

# Record git state if available
if git -C "$SCRIPT_DIR" rev-parse --git-dir &>/dev/null; then
  git -C "$SCRIPT_DIR" rev-parse HEAD > "${EVIDENCE_DIR}/git-commit.txt" 2>/dev/null || true
  git -C "$SCRIPT_DIR" status --porcelain > "${EVIDENCE_DIR}/git-status.txt" 2>/dev/null || true
fi

echo "═══════════════════════════════════════════════════════════════"
echo "  NexaRail — RC1 Developer Dashboard Check"
echo "  Evidence: ${EVIDENCE_DIR}"
echo "═══════════════════════════════════════════════════════════════"

# ── Step 1: Check dashboard files ─────────────────────────────────────────
echo ""
echo "═══ Step 1: Dashboard File Check ═════════════════════════════"
CHECK_EXIT=0
if [[ -x "$CHECK_SCRIPT" ]]; then
  set +e
  bash "$CHECK_SCRIPT" 2>&1 > "${EVIDENCE_DIR}/check-results.txt"
  CHECK_EXIT=$?
  set -e
  cat "${EVIDENCE_DIR}/check-results.txt"
else
  echo "  [WARN] check-dashboard-files.sh not found or not executable"
  echo "  Running file checks inline..."

  # Inline fallback
  PASS=0
  FAIL=0
  pass() { echo "  [PASS]  $1"; PASS=$((PASS + 1)); }
  fail() { echo "  [FAIL]  $1"; FAIL=$((FAIL + 1)); }

  for file in index.html app.js styles.css README.md; do
    if [[ -f "${DASHBOARD_DIR}/${file}" ]]; then
      pass "${file} exists"
    else
      fail "${file} not found"
    fi
  done
  {
    echo ""
    echo "  PASS: ${PASS}  FAIL: ${FAIL}"
  } >> "${EVIDENCE_DIR}/check-results.txt"
  CHECK_EXIT=$FAIL
fi

# ── Step 2: Optionally serve the dashboard ────────────────────────────────
if [[ "$SERVE_MODE" == true ]]; then
  echo ""
  echo "═══ Step 2: Serving Dashboard (${SERVE_DURATION}s) ════════════"

  # Start server in background and capture PID
  if [[ -x "$SERVE_SCRIPT" ]]; then
    bash "$SERVE_SCRIPT" --port 8089 &
    SERVE_PID=$!
  else
    # Inline server fallback
    python3 -m http.server 8089 --directory "$DASHBOARD_DIR" &
    SERVE_PID=$!
  fi

  echo "  Server PID: ${SERVE_PID}"
  echo "  Dashboard:  http://localhost:8089"
  echo "  Serving for ${SERVE_DURATION} seconds..."

  # Verify server started
  sleep 2
  if kill -0 "$SERVE_PID" 2>/dev/null; then
    echo "  [PASS] Server is running"

    # Curl the dashboard to verify it responds
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8089/index.html 2>/dev/null || echo "000")
    if [[ "$HTTP_STATUS" != "000" ]]; then
      echo "  [INFO] HTTP ${HTTP_STATUS} from index.html"
      curl -s http://localhost:8089/index.html > "${EVIDENCE_DIR}/served-index.html" 2>/dev/null || true
    else
      echo "  [WARN] Could not reach server at localhost:8089"
    fi
  else
    echo "  [FAIL] Server failed to start or stopped prematurely"
  fi

  # Wait remaining duration
  sleep $((SERVE_DURATION - 2)) 2>/dev/null || true

  # Graceful shutdown
  echo "  Stopping server (PID ${SERVE_PID})..."
  kill "$SERVE_PID" 2>/dev/null || true
  wait "$SERVE_PID" 2>/dev/null || true
  echo "  Server stopped."
else
  echo ""
  echo "═══ Step 2: Skipped (no --serve flag) ═══════════════════════"
  echo "  Pass --serve to spin up the dashboard for smoke testing."
fi

# ── Write summary evidence ────────────────────────────────────────────────
SUMMARY_FILE="${EVIDENCE_DIR}/summary.txt"
{
  echo "═══════════════════════════════════════════════════════════════"
  echo "  NexaRail — RC1 Developer Dashboard Check"
  echo "  $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "  Host: $(hostname)"
  echo "═══════════════════════════════════════════════════════════════"
  echo ""
  echo "  Dashboard:     ${DASHBOARD_DIR}"
  echo "  Serve Mode:    ${SERVE_MODE}"
  echo "  Serve Duration: ${SERVE_DURATION}s"
  echo "  Check Exit:    ${CHECK_EXIT}"
  echo "  Evidence:      ${EVIDENCE_DIR}"
  echo ""
  echo "── Checks ──────────────────────────────────────────────────"
  if [[ -f "${EVIDENCE_DIR}/check-results.txt" ]]; then
    grep -E "\[(PASS|FAIL|SKIP)\]" "${EVIDENCE_DIR}/check-results.txt" 2>/dev/null || true
  fi
  echo ""
  if [[ "$CHECK_EXIT" -eq 0 ]]; then
    echo "  Overall: ALL CHECKS PASSED"
  else
    echo "  Overall: ${CHECK_EXIT} check(s) FAILED"
  fi
  echo ""
  echo "── Files ───────────────────────────────────────────────────"
  for file in index.html app.js styles.css README.md; do
    if [[ -f "${DASHBOARD_DIR}/${file}" ]]; then
      lines=$(wc -l < "${DASHBOARD_DIR}/${file}" | tr -d ' ')
      echo "  ${file}: ${lines} lines"
    else
      echo "  ${file}: MISSING"
    fi
  done
  echo ""
  echo "═══════════════════════════════════════════════════════════════"
} > "$SUMMARY_FILE"
cat "$SUMMARY_FILE"

echo ""
echo "═══ Complete ═════════════════════════════════════════════════"
echo "  Evidence saved to: ${EVIDENCE_DIR}/"
echo "  Summary:           ${EVIDENCE_DIR}/summary.txt"
echo "═══════════════════════════════════════════════════════════════"

exit "$CHECK_EXIT"
