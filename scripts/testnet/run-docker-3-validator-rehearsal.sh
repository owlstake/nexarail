#!/usr/bin/env bash
# NexaRail Docker 3-Validator Rehearsal — RUN
set -euo pipefail
DOCKER_DIR="$(cd "$(dirname "$0")" && cd ../../rehearsals/testnet-1/docker && pwd)"

echo "=== NexaRail Docker Rehearsal ==="

# PRECONDITION: Docker must be available
if ! command -v docker &>/dev/null; then
    echo "❌ FATAL: Docker is not installed."
    echo "   Install: https://docs.docker.com/desktop/ or brew install --cask docker"
    echo "   Alternative for Mac: brew install colima && colima start"
    exit 1
fi
echo "Preparing genesis..."
"$(dirname "$0")/prepare-docker-3-validator-rehearsal.sh"

echo ""
echo "Starting Docker containers..."
cd "$DOCKER_DIR"
docker-compose up -d

echo "Waiting for block production..."
for i in $(seq 5 5 120); do
    sleep 5
    H=$(curl -s http://127.0.0.1:26657/status 2>/dev/null | jq -r '.result.sync_info.latest_block_height // "0"')
    P=$(curl -s http://127.0.0.1:26657/net_info 2>/dev/null | jq -r '.result.n_peers // "0"')
    echo "  [${i}s] Height=$H Peers=$P"
    if [ "${H:-0}" -ge 3 ] 2>/dev/null; then
        echo ""
        echo "╔══════════════════════════════════════════╗"
        echo "║  🚀 3 VALIDATORS PRODUCING BLOCKS!     ║"
        echo "║  Height: $H  Peers: $P                ║"
        echo "╚══════════════════════════════════════════╝"
        echo "Query: scripts/testnet/query-docker-3-validator-rehearsal.sh"
        exit 0
    fi
done
echo "⚠️ Timeout. Check: docker-compose -f $DOCKER_DIR/docker-compose.yml logs"
exit 1
