#!/usr/bin/env bash
# NexaRail Docker Rehearsal Evidence Collector
# Collects all proof artefacts for Phase 6K gate review.
set -euo pipefail

DOCKER_DIR="$(cd "$(dirname "$0")" && cd ../../rehearsals/testnet-1/docker && pwd)"
TS=$(date -u +%Y%m%dT%H%M%SZ)
EVDIR="$DOCKER_DIR/evidence/$TS"
mkdir -p "$EVDIR"

echo "=== NexaRail Docker Rehearsal Evidence Collector ==="
echo "Output: $EVDIR"

# PRECONDITION: Docker must be available
if ! command -v docker &>/dev/null; then
    echo "❌ FATAL: Docker is not installed on this machine."
    echo "   Install Docker Desktop: https://docs.docker.com/desktop/"
    echo "   Or on Mac: brew install --cask docker"
    echo "   Then re-run: ./scripts/testnet/run-docker-3-validator-rehearsal.sh"
    exit 1
fi

if ! docker-compose version &>/dev/null; then
    echo "❌ FATAL: docker-compose plugin not available."
    echo "   Docker Compose is included with Docker Desktop."
    echo "   Verify: docker-compose version"
    exit 1
fi

# PRECONDITION: At least one container must be running
RUNNING=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
if [ "$RUNNING" -eq 0 ]; then
    echo "❌ FATAL: No Docker containers are running."
    echo "   Run the rehearsal first:"
    echo "   ./scripts/testnet/run-docker-3-validator-rehearsal.sh"
    echo ""
    echo "   If the rehearsal script already ran, check:"
    echo "   docker-compose -f rehearsals/testnet-1/docker/docker-compose.yml ps -a"
    echo "   docker-compose -f rehearsals/testnet-1/docker/docker-compose.yml logs"
    exit 1
fi

# 1. Docker status
echo "--- docker ps ---"
docker ps --format '{{.ID}} {{.Names}} {{.Status}} {{.Ports}}' > "$EVDIR/docker-ps.txt" 2>/dev/null || echo "docker unavailable" > "$EVDIR/docker-ps.txt"
cat "$EVDIR/docker-ps.txt"

# 2. Docker compose ps
echo "--- docker-compose ps ---"
cd "$DOCKER_DIR"
docker-compose ps > "$EVDIR/docker-compose-ps.txt" 2>/dev/null || echo "compose unavailable" > "$EVDIR/docker-compose-ps.txt"
cat "$EVDIR/docker-compose-ps.txt"

# 3. Validator status
for i in 0 1 2; do
    case $i in 0) port=26657 ;; 1) port=26667 ;; 2) port=26677 ;; esac
    echo "--- val$i status ---"
    curl -s "http://127.0.0.1:$port/status" 2>/dev/null | jq '.' > "$EVDIR/val${i}-status.json" || echo '{"error":"RPC unreachable"}' > "$EVDIR/val${i}-status.json"
    H=$(jq -r '.result.sync_info.latest_block_height // "0"' "$EVDIR/val${i}-status.json")
    N=$(jq -r '.result.node_info.network // ""' "$EVDIR/val${i}-status.json")
    echo "  val$i: height=$H chain=$N"
done

# 4. Peer count
for i in 0 1 2; do
    case $i in 0) port=26657 ;; 1) port=26667 ;; 2) port=26677 ;; esac
    curl -s "http://127.0.0.1:$port/net_info" 2>/dev/null | jq '.' > "$EVDIR/val${i}-net_info.json" || echo '{}' > "$EVDIR/val${i}-net_info.json"
done

# 5. Validator set
curl -s "http://127.0.0.1:26657/validators" 2>/dev/null | jq '.' > "$EVDIR/validator-set.json" || echo '{}' > "$EVDIR/validator-set.json"
VAL_COUNT=$(jq '.result.validators | length // 0' "$EVDIR/validator-set.json" 2>/dev/null || echo "0")
echo "  Validators: $VAL_COUNT"

# 6. Module params
REST=http://127.0.0.1:1317
curl -s "$REST/cosmos/settlement/v1/params" 2>/dev/null | jq '.' > "$EVDIR/settlement-params.json" || echo '{}' > "$EVDIR/settlement-params.json"
curl -s "$REST/cosmos/escrow/v1/params" 2>/dev/null | jq '.' > "$EVDIR/escrow-params.json" || echo '{}' > "$EVDIR/escrow-params.json"
curl -s "$REST/cosmos/treasury/v1/params" 2>/dev/null | jq '.' > "$EVDIR/treasury-params.json" || echo '{}' > "$EVDIR/treasury-params.json"
curl -s "$REST/cosmos/payout/v1/params" 2>/dev/null | jq '.' > "$EVDIR/payout-params.json" || echo '{}' > "$EVDIR/payout-params.json"
curl -s "$REST/cosmos/fees/v1/params" 2>/dev/null | jq '.' > "$EVDIR/fees-params.json" || echo '{}' > "$EVDIR/fees-params.json"
curl -s "$REST/cosmos/merchant/v1/params" 2>/dev/null | jq '.' > "$EVDIR/merchant-params.json" || echo '{}' > "$EVDIR/merchant-params.json"

echo "--- Live flags ---"
for f in settlement escrow treasury payout; do
    LIVE=$(jq -r '.params.live_enabled // "N/A"' "$EVDIR/${f}-params.json" 2>/dev/null)
    echo "  $f.live_enabled: $LIVE"
done

# 7. Logs
for i in 0 1 2; do
    docker-compose -f "$DOCKER_DIR/docker-compose.yml" logs "val$i" --tail=200 2>/dev/null > "$EVDIR/val${i}-log.txt" || echo "docker logs unavailable" > "$EVDIR/val${i}-log.txt"
done

# 8. Genesis checksum + p2p summary
cp "$DOCKER_DIR/p2p-summary.txt" "$EVDIR/" 2>/dev/null || true
cp "$DOCKER_DIR/genesis-checksum.txt" "$EVDIR/" 2>/dev/null || true

# 9. Environment
echo "--- environment ---"
go version > "$EVDIR/go-version.txt" 2>/dev/null || echo "go not found" > "$EVDIR/go-version.txt"
docker --version > "$EVDIR/docker-version.txt" 2>/dev/null || echo "docker not found" > "$EVDIR/docker-version.txt"
git -C "$(dirname "$0")/../.." rev-parse HEAD > "$EVDIR/git-commit.txt" 2>/dev/null || echo "unknown" > "$EVDIR/git-commit.txt"
cat "$EVDIR/go-version.txt"
cat "$EVDIR/docker-version.txt"
echo "commit: $(cat "$EVDIR/git-commit.txt")"

# 10. Summary
cat > "$EVDIR/SUMMARY.txt" << EOF
NexaRail Docker Rehearsal Evidence
===================================
Timestamp: $TS
Chain ID: $(jq -r '.result.node_info.network // "unknown"' "$EVDIR/val0-status.json")
Height: $(jq -r '.result.sync_info.latest_block_height // "0"' "$EVDIR/val0-status.json")
Validators: $VAL_COUNT
Settlement live_enabled: $(jq -r '.params.live_enabled // "N/A"' "$EVDIR/settlement-params.json")
Escrow live_enabled: $(jq -r '.params.live_enabled // "N/A"' "$EVDIR/escrow-params.json")
Treasury live_enabled: $(jq -r '.params.live_enabled // "N/A"' "$EVDIR/treasury-params.json")
Payout live_enabled: $(jq -r '.params.live_enabled // "N/A"' "$EVDIR/payout-params.json")
EOF

echo ""
echo "=== Evidence collected at: $EVDIR ==="
cat "$EVDIR/SUMMARY.txt"
