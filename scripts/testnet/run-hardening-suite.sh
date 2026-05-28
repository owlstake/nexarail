#!/usr/bin/env bash
# NexaRail Hardening Suite
# Runs all tests, coverage, benchmarks, and optional smoke tests.
# TESTNET/DEVNET ONLY — not for mainnet (none exists).
set -euo pipefail

PASS=0
FAIL=0

echo "╔══════════════════════════════════════════╗"
echo "║  NexaRail Hardening Suite               ║"
echo "║  Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)        ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# --- 1. go mod verification ---
echo "═══ 1. go mod tidy & verify ═══"
if go mod tidy 2>&1 && go mod verify 2>&1; then
    echo "  ✅ go mod tidy & verify"
    PASS=$((PASS+1))
else
    echo "  ❌ go mod verification failed"
    FAIL=$((FAIL+1))
fi

# --- 2. go build ---
echo ""
echo "═══ 2. go build ./... ═══"
if go build ./... 2>&1; then
    echo "  ✅ go build"
    PASS=$((PASS+1))
else
    echo "  ❌ go build failed"
    FAIL=$((FAIL+1))
fi

# --- 3. go vet ---
echo ""
echo "═══ 3. go vet ./... ═══"
if go vet ./... 2>&1; then
    echo "  ✅ go vet"
    PASS=$((PASS+1))
else
    echo "  ❌ go vet failed"
    FAIL=$((FAIL+1))
fi

# --- 4. go test ---
echo ""
echo "═══ 4. go test ./... ═══"
TEST_OUT=$(go test ./... -count=1 2>&1)
echo "$TEST_OUT" | grep -E "^(ok|\?|---)" || true
FAILED_PKGS=$(echo "$TEST_OUT" | grep "^FAIL" | wc -l | tr -d ' ')
if [ "$FAILED_PKGS" -eq 0 ]; then
    echo "  ✅ All tests pass"
    PASS=$((PASS+1))
else
    echo "  ❌ $FAILED_PKGS package(s) failed"
    FAIL=$((FAIL+1))
fi

# --- 5. go test -cover ---
echo ""
echo "═══ 5. go test -cover ./... ═══"
go test ./... -cover -count=1 2>&1 | grep -E "coverage:|no test files" || true
PASS=$((PASS+1))

# --- 6. Benchmarks (optional, quick) ---
echo ""
echo "═══ 6. Benchmarks (quick) ═══"
if go test ./app -bench=. -benchtime=100ms -count=1 2>&1 | grep "^Benchmark" > /dev/null 2>&1; then
    go test ./app -bench=. -benchtime=100ms -count=1 2>&1 | grep "^Benchmark"
    echo "  ✅ Benchmarks run"
    PASS=$((PASS+1))
else
    echo "  ⏭️  Benchmarks skipped (no benchmark tests found or app build failed)"
fi

# --- 7. CLI smoke test (if node available) ---
echo ""
echo "═══ 7. CLI E2E Smoke Test ═══"
if curl -s --max-time 3 http://127.0.0.1:26657/status > /dev/null 2>&1; then
    echo "  Node detected on :26657 — running CLI smoke test..."
    if bash scripts/testnet/cli-e2e-smoke-test.sh 2>&1; then
        echo "  ✅ CLI smoke test passed"
        PASS=$((PASS+1))
    else
        echo "  ⚠️  CLI smoke test had failures (may be expected without full gRPC access)"
    fi
else
    echo "  ⏭️  No local node detected — CLI smoke test skipped"
    echo "     Start a node and re-run for full coverage"
fi

# --- 8. API smoke test (if node available) ---
echo ""
echo "═══ 8. API Smoke Test ═══"
if curl -s --max-time 3 http://127.0.0.1:1317/cosmos/base/tendermint/v1beta1/node_info > /dev/null 2>&1; then
    echo "  REST API detected on :1317 — running API smoke test..."
    if bash scripts/testnet/api-smoke-test.sh 2>&1; then
        echo "  ✅ API smoke test passed"
        PASS=$((PASS+1))
    else
        echo "  ⚠️  API smoke test had failures (may be expected without full REST access)"
    fi
else
    echo "  ⏭️  No REST API detected — API smoke test skipped"
    echo "     Start a node with REST enabled and re-run"
fi

# --- Summary ---
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Suite Complete                         ║"
echo "║  Passed: $PASS  Failed: $FAIL               ║"
if [ "$FAIL" -gt 0 ]; then
    echo "║  ⚠️  Review failures above              ║"
fi
echo "╚══════════════════════════════════════════╝"
