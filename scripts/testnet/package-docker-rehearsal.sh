#!/usr/bin/env bash
# NexaRail Docker Rehearsal Packager
# Creates a distributable tar.gz with everything needed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
DOCKER_DIR="$PROJECT_DIR/rehearsals/testnet-1/docker"
OUTPUT="$DOCKER_DIR/nexarail-docker-rehearsal-pack.tar.gz"

echo "=== Packaging Nexarail Docker Rehearsal ==="

# Build if needed
[ -f "$PROJECT_DIR/build/nexaraild" ] || (cd "$PROJECT_DIR" && make build)

# Prepare genesis
"$SCRIPT_DIR/prepare-docker-3-validator-rehearsal.sh"

# Collect files
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/nexarail-docker-rehearsal"

cp "$DOCKER_DIR/docker-compose.yml" "$TMPDIR/nexarail-docker-rehearsal/"
cp "$DOCKER_DIR/README.md" "$TMPDIR/nexarail-docker-rehearsal/"
cp "$DOCKER_DIR/p2p-summary.txt" "$TMPDIR/nexarail-docker-rehearsal/"
cp -r "$DOCKER_DIR/validator-notes" "$TMPDIR/nexarail-docker-rehearsal/"
cp "$SCRIPT_DIR/run-docker-3-validator-rehearsal.sh" "$TMPDIR/nexarail-docker-rehearsal/"
cp "$SCRIPT_DIR/query-docker-3-validator-rehearsal.sh" "$TMPDIR/nexarail-docker-rehearsal/"
cp "$SCRIPT_DIR/stop-docker-3-validator-rehearsal.sh" "$TMPDIR/nexarail-docker-rehearsal/"
cp "$SCRIPT_DIR/logs-docker-3-validator-rehearsal.sh" "$TMPDIR/nexarail-docker-rehearsal/"
cp "$SCRIPT_DIR/collect-docker-rehearsal-evidence.sh" "$TMPDIR/nexarail-docker-rehearsal/"
cp "$PROJECT_DIR/docs/testnet/PHASE_6K_EXTERNAL_DOCKER_EXECUTION.md" "$TMPDIR/nexarail-docker-rehearsal/"
cp "$PROJECT_DIR/docs/testnet/EXTERNAL_REHEARSAL_OPERATOR_CHECKLIST.md" "$TMPDIR/nexarail-docker-rehearsal/"
cp "$PROJECT_DIR/docs/testnet/PUBLIC_VALIDATOR_REGISTRATION_GATE.md" "$TMPDIR/nexarail-docker-rehearsal/"

chmod +x "$TMPDIR/nexarail-docker-rehearsal/"*.sh

cd "$TMPDIR"
tar -czf "$OUTPUT" nexarail-docker-rehearsal/
rm -rf "$TMPDIR"

echo "✅ Package created: $OUTPUT"
echo "Size: $(du -h "$OUTPUT" | awk '{print $1}')"
echo ""
echo "To use:"
echo "  tar -xzf $OUTPUT"
echo "  cd nexarail-docker-rehearsal"
echo "  ./prepare-docker-3-validator-rehearsal.sh  # if genesis not pre-built"
echo "  docker-compose up -d"
