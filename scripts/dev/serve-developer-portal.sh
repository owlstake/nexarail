#!/usr/bin/env bash
# NexaRail — Serve Developer Portal
#
# Builds (unless --no-build) and serves the developer portal on localhost.
# LOCAL DEVNET ONLY — NOT MAINNET — No external hosting.
#
# Usage:
#   bash scripts/dev/serve-developer-portal.sh
#   bash scripts/dev/serve-developer-portal.sh --no-build
#   bash scripts/dev/serve-developer-portal.sh --port 9090
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="$PROJECT_DIR/site/developer-portal"
PORT=8090
NO_BUILD=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-build) NO_BUILD=1; shift ;;
        --port) PORT="$2"; shift 2 ;;
        *) echo "  ❌ Unknown: $1"; exit 1 ;;
    esac
done

if [ "$NO_BUILD" -eq 0 ]; then
    echo "  Building portal..."
    if ! bash "$SCRIPT_DIR/build-developer-portal.sh"; then
        echo "  ❌ Build failed"
        exit 1
    fi
fi

if [ ! -d "$OUTPUT_DIR" ]; then
    echo "  ❌ Portal not built. Run build-developer-portal.sh first."
    exit 1
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  NexaRail Developer Portal — Local Server                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo "  URL:      http://localhost:$PORT"
echo "  Source:   $OUTPUT_DIR"
echo "  Press Ctrl+C to stop."
echo ""

cd "$OUTPUT_DIR"
python3 -m http.server "$PORT"
echo "  Server stopped."