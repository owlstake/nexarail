#!/usr/bin/env bash
# NexaRail Docker Rehearsal — LOGS
set -euo pipefail
DOCKER_DIR="$(cd "$(dirname "$0")" && cd ../../rehearsals/testnet-1/docker && pwd)"
echo "=== NexaRail Docker Rehearsal Logs ==="
cd "$DOCKER_DIR"
docker-compose logs --tail=50 2>/dev/null || echo "docker-compose not available"
