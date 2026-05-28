#!/usr/bin/env bash
# NexaRail Test Coverage Summary
# Runs go test -cover across all packages and prints a summary.
# TESTNET/DEVNET ONLY.
set -euo pipefail

echo "╔══════════════════════════════════════════╗"
echo "║  NexaRail Test Coverage Summary         ║"
echo "╚══════════════════════════════════════════╝"
echo ""

COVERAGE_FILE=$(mktemp)

# Run tests with coverage
go test ./... -cover -coverprofile="${COVERAGE_FILE}.out" -count=1 2>&1 | while IFS= read -r line; do
    if echo "$line" | grep -q "^ok.*coverage:"; then
        pkg=$(echo "$line" | awk '{print $2}')
        cov=$(echo "$line" | grep -o "coverage: [0-9.]*%" | awk '{print $2}')
        echo "  $pkg  $cov"
    elif echo "$line" | grep -q "^?"; then
        pkg=$(echo "$line" | awk '{print $2}')
        echo "  $pkg  (no test files)"
    fi
done

echo ""
echo "--- Package Summary ---"
go test ./... -cover -count=1 2>&1 | grep -E "coverage:|no test files" | while IFS= read -r line; do
    echo "$line" | sed 's/\t/  /g'
done

# Cleanup
rm -f "${COVERAGE_FILE}" "${COVERAGE_FILE}.out"

echo ""
echo "For detailed HTML coverage:"
echo "  go test ./... -coverprofile=coverage.out"
echo "  go tool cover -html=coverage.out"
