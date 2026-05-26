#!/usr/bin/env bash
# NexaRail Local 3-Validator Rehearsal — STOP
# Kills all validator processes started by run-local-3-validator-rehearsal.sh.
set -euo pipefail

REHEARSAL_DIR="rehearsals/testnet-1"
PID_FILE="$REHEARSAL_DIR/logs/pids.txt"

echo "=== Stopping NexaRail Rehearsal Validators ==="

if [ ! -f "$PID_FILE" ]; then
    echo "No PID file found. Looking for nexaraild processes..."
    pkill -f "nexaraild start" 2>/dev/null || echo "  No processes found"
    exit 0
fi

while IFS= read -r pid; do
    if kill -0 "$pid" 2>/dev/null; then
        echo "  Stopping PID: $pid"
        kill "$pid" 2>/dev/null || true
    else
        echo "  PID $pid already stopped"
    fi
done < "$PID_FILE"

# Wait for processes to exit
sleep 2

# Clean up any remaining
pkill -f "nexaraild start" 2>/dev/null || true

rm -f "$PID_FILE"
echo "✅ All validators stopped."
