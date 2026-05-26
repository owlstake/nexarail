#!/usr/bin/env bash
# NexaRail Docker Rehearsal — STOP
set -euo pipefail
DOCKER_DIR="$(cd "$(dirname "$0")" && cd ../../rehearsals/testnet-1/docker && pwd)"
echo "=== Stopping NexaRail Docker Rehearsal ==="
cd "$DOCKER_DIR"
docker-compose down 2>/dev/null && echo "✅ Containers stopped" || echo "⚠️ docker-compose not available"
echo "Validator data preserved at: $DOCKER_DIR/validator-notes/"
