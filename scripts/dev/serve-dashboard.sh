#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# serve-dashboard.sh
#
# Helper script to serve the NexaRail developer dashboard locally.
#
# Detects available HTTP server (python3, python, node http-server, npx serve)
# and defaults to python3 -m http.server.
#
# Usage: scripts/dev/serve-dashboard.sh [--port PORT]
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DASHBOARD_DIR="${SCRIPT_DIR}/examples/dashboard"
PORT="${PORT:-8088}"

# ── parse args ─────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --port)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --port requires a value" >&2
        exit 1
      fi
      PORT="$2"
      shift 2
      ;;
    --port=*)
      PORT="${1#*=}"
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [--port PORT]"
      echo ""
      echo "Serves the developer dashboard from ${DASHBOARD_DIR}"
      echo ""
      echo "Options:"
      echo "  --port PORT  HTTP port (default: 8088)"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 [--port PORT]" >&2
      exit 1
      ;;
  esac
done

# ── validate dashboard directory ──────────────────────────────────────────
if [[ ! -d "$DASHBOARD_DIR" ]]; then
  echo "Error: Dashboard directory not found: ${DASHBOARD_DIR}" >&2
  echo "Run from the nexarail project root." >&2
  exit 1
fi

# ── detect available HTTP server ──────────────────────────────────────────
SERVER_CMD=""
SERVER_LABEL=""

if command -v python3 &>/dev/null; then
  SERVER_CMD="python3 -m http.server ${PORT}"
  SERVER_LABEL="python3 http.server"
elif command -v python &>/dev/null; then
  SERVER_CMD="python -m http.server ${PORT}"
  SERVER_LABEL="python http.server"
elif command -v node &>/dev/null && npm list -g http-server &>/dev/null 2>&1; then
  SERVER_CMD="http-server ${DASHBOARD_DIR} -p ${PORT}"
  SERVER_LABEL="node http-server"
elif command -v npx &>/dev/null; then
  SERVER_CMD="npx serve ${DASHBOARD_DIR} -p ${PORT}"
  SERVER_LABEL="npx serve"
else
  echo "Error: No suitable HTTP server found." >&2
  echo "Install python3 or run: npm install -g http-server" >&2
  exit 1
fi

# ── print info and serve ──────────────────────────────────────────────────
echo "═══ NexaRail — Developer Dashboard ════════════════════════════"
echo "  Server:    ${SERVER_LABEL}"
echo "  Port:      ${PORT}"
echo "  Directory: ${DASHBOARD_DIR}"
echo ""
echo "  Dashboard URL: http://localhost:${PORT}"
echo ""
echo "  Press Ctrl+C to stop."
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Catch Ctrl+C gracefully
cleanup() {
  echo ""
  echo "Shutting down dashboard server..."
  exit 0
}
trap cleanup SIGINT SIGTERM

cd "$DASHBOARD_DIR"
exec $SERVER_CMD
