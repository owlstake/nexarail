#!/usr/bin/env bash
# NexaRail - Phase 9U soak evidence summariser.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../.. && pwd)"
AGENT_DIR="$PROJECT_DIR/rehearsals/validator-agents"

SOAK_DIR="${1:-}"
if [ -z "$SOAK_DIR" ] && [ -f "$AGENT_DIR/phase9u-latest-evidence-path.txt" ]; then
    SOAK_DIR="$(cat "$AGENT_DIR/phase9u-latest-evidence-path.txt")"
fi
if [ -z "$SOAK_DIR" ]; then
    SOAK_DIR="$(ls -dt "$AGENT_DIR"/long-soak/evidence/*/ 2>/dev/null | head -1 || true)"
fi

if [ -z "$SOAK_DIR" ] || [ ! -d "$SOAK_DIR" ]; then
    echo "Usage: $0 <soak-evidence-dir>"
    exit 1
fi

summary_env="$SOAK_DIR/summary.env"
if [ -f "$summary_env" ]; then
    # shellcheck disable=SC1090
    source "$summary_env"
fi

echo "=== Phase 9U Soak Summary: $(basename "$SOAK_DIR") ==="
echo "Evidence: $SOAK_DIR"
echo ""

if [ -f "$SOAK_DIR/final-summary.md" ]; then
    sed -n '1,80p' "$SOAK_DIR/final-summary.md"
    echo ""
fi

echo "Height range samples:"
if [ -f "$SOAK_DIR/height-range.tsv" ]; then
    column -t -s $'\t' "$SOAK_DIR/height-range.tsv" 2>/dev/null || cat "$SOAK_DIR/height-range.tsv"
else
    echo "  missing height-range.tsv"
fi

echo ""
echo "Query samples:"
if [ -f "$SOAK_DIR/query-summary.tsv" ]; then
    column -t -s $'\t' "$SOAK_DIR/query-summary.tsv" 2>/dev/null || cat "$SOAK_DIR/query-summary.tsv"
else
    echo "  missing query-summary.tsv"
fi

echo ""
echo "Final per-agent sample:"
if [ -f "$SOAK_DIR/samples.tsv" ]; then
    awk -F'\t' '
        NR == 1 {next}
        {rows[$4] = $0}
        END {
            for (name in rows) print rows[name]
        }
    ' "$SOAK_DIR/samples.tsv" | sort | column -t -s $'\t' 2>/dev/null || true
else
    echo "  missing samples.tsv"
fi

echo ""
panic_count="${PANIC_COUNT:-$(wc -l < "$SOAK_DIR/panic-scan.txt" 2>/dev/null || echo 0)}"
query_fail="${QUERY_FAIL:-0}"
echo "Panics: $panic_count"
echo "Query failures: $query_fail"

if [ "${panic_count:-0}" -eq 0 ] && [ "${query_fail:-0}" -eq 0 ]; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi
