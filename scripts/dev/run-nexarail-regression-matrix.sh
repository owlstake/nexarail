#!/usr/bin/env bash
# NexaRail — Comprehensive Regression Matrix Runner
#
# Runs a battery of checks against the NexaRail codebase to verify
# correctness, safety, and readiness. Supports fast and full modes.
#
# Usage:
#   bash scripts/dev/run-nexarail-regression-matrix.sh [--fast|--full] [options]
#
# Flags:
#   --fast              Fast checks only: go mod verify, go build, go test,
#                       predeployment-check, rc1 verify, dashboard files, local demo script
#   --full              Full checks: fast + launch devnet + smoke + dashboard + local demo
#   --with-devnet       Include devnet-dependent checks in full mode
#   --with-e2e-demo     Include end-to-end demo (requires --full, --with-devnet)
#   --with-dashboard    Serve dashboard during full check
#   --skip-build        Skip go build steps
#   --evidence-dir <p>  Override evidence output directory
#   -h, --help          Show this help
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
DEFAULT_EVIDENCE_DIR="$PROJECT_DIR/rehearsals/regression-matrix/evidence/$TIMESTAMP"
EVIDENCE_DIR="$DEFAULT_EVIDENCE_DIR"

MODE="fast"
WITH_DEVNET=0
WITH_DASHBOARD=0
SKIP_BUILD=0

PASS=0
FAIL=0
SKIP=0
TOTAL=0
FAILED_CHECKS=""

# ── Helpers ────────────────────────────────────────────────────────────────
usage() {
    cat <<EOF
Usage: scripts/dev/run-nexarail-regression-matrix.sh [OPTIONS]

Run comprehensive NexaRail regression checks.

Modes:
  --fast              FAST mode (default): go build/test, RC1 verification,
                      dashboard check, local demo script check
  --full              FULL mode: fast checks + devnet + smoke tests + local demo

Options:
  --with-devnet       Include devnet-dependent checks (requires --full)
  --with-e2e-demo     Include end-to-end demo (requires --full, --with-devnet)
  --with-dashboard    Serve dashboard during check (requires --full)
  --skip-build        Skip Go build steps
  --evidence-dir <p>  Override evidence output directory (default: $DEFAULT_EVIDENCE_DIR)
  -h, --help          Show this help
EOF
    exit 0
}

# ── Parse args ────────────────────────────────────────────────────────────
while [ "$#" -gt 0 ]; do
    case "$1" in
        --fast) MODE="fast"; shift ;;
        --full) MODE="full"; shift ;;
        --with-devnet) WITH_DEVNET=1; shift ;;
        --with-dashboard) WITH_DASHBOARD=1; shift ;;
        --with-e2e-demo) E2E=1; shift ;;
        --skip-build) SKIP_BUILD=1; shift ;;
        --evidence-dir) EVIDENCE_DIR="${2:-}"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

mkdir -p "$EVIDENCE_DIR"

HEADER="╔══════════════════════════════════════════════════════════════╗
║  NexaRail — Regression Matrix Runner                        ║
║  Mode: ${MODE}
║  Evidence: ${EVIDENCE_DIR}
╚══════════════════════════════════════════════════════════════╝"

echo "$HEADER"

# ── Evidence helpers ──────────────────────────────────────────────────────
write_env() {
    local env_file="$EVIDENCE_DIR/environment.txt"
    cat > "$env_file" <<EOF
OS: $(uname -srm 2>/dev/null || echo "unknown")
Go Version: $(go version 2>/dev/null || echo "go not found")
Git Commit: $(git -C "$PROJECT_DIR" rev-parse HEAD 2>/dev/null || echo "unknown")
Git Branch: $(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
Date: $(date -u '+%Y-%m-%dT%H:%M:%SZ')
Host: $(hostname 2>/dev/null || echo "unknown")
Mode: ${MODE}
With Devnet: ${WITH_DEVNET}
With Dashboard: ${WITH_DASHBOARD}
Skip Build: ${SKIP_BUILD}
EOF
    echo "  [INFO] Environment written: $env_file"
}

section() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  § $*"
    echo "═══════════════════════════════════════════════════════════════"
}

check_pass() {
    local check_name="$1"
    local msg="${2:-PASS}"
    PASS=$((PASS + 1))
    echo "  ✅ PASS: $check_name — $msg"
    echo "PASS: $check_name — $msg" >> "$EVIDENCE_DIR/$check_name.txt"
}

check_fail() {
    local check_name="$1"
    local msg="${2:-FAIL}"
    FAIL=$((FAIL + 1))
    echo "  ❌ FAIL: $check_name — $msg"
    echo "FAIL: $check_name — $msg" >> "$EVIDENCE_DIR/$check_name.txt"
    FAILED_CHECKS="${FAILED_CHECKS}  ❌ $check_name — $msg"$'\n'
}

check_skip() {
    local check_name="$1"
    local msg="${2:-SKIP}"
    SKIP=$((SKIP + 1))
    echo "  ⏭️  SKIP: $check_name — $msg"
    echo "SKIP: $check_name — $msg" >> "$EVIDENCE_DIR/$check_name.txt"
}

record_check() {
    local check_name="$1"
    local exit_code="$2"
    local label="${3:-$check_name}"
    TOTAL=$((TOTAL + 1))
    if [ "$exit_code" -eq 0 ]; then
        check_pass "$check_name" "$label"
    else
        check_fail "$check_name" "$label (exit code $exit_code)"
    fi
}

run_check() {
    local check_name="$1"
    shift
    local cmd=("$@")
    local evidence_file="$EVIDENCE_DIR/$check_name.txt"

    echo ""
    echo "── $check_name ──────────────────────────────────────────"
    echo "  Running: ${cmd[*]}"
    echo "  Evidence: $evidence_file"

    set +e
    "${cmd[@]}" > "$evidence_file" 2>&1
    local rc=$?
    set -e

    record_check "$check_name" "$rc"
    return $rc
}

# ── Checks ────────────────────────────────────────────────────────────────

write_env

# These will be populated by each test section
FAST_CHECKS_PASS=0
FAST_CHECKS_FAIL=0
FAST_CHECKS_SKIP=0
FULL_CHECKS_PASS=0
FULL_CHECKS_FAIL=0
FULL_CHECKS_SKIP=0

# ── FAST CHECKS ───────────────────────────────────────────────────────────
section "FAST CHECKS"

# 1. go mod verify
run_check "go_mod_verify" bash -c "cd '$PROJECT_DIR' && go mod verify" || true

# 2. go build (unless --skip-build)
if [ "$SKIP_BUILD" -eq 1 ]; then
    check_skip "go_build" "Skipped (--skip-build)"
else
    run_check "go_build" bash -c "cd '$PROJECT_DIR' && go build ./..." || true
fi

# 3. go test
run_check "go_test" bash -c "cd '$PROJECT_DIR' && go test ./... -count=1" || true

# 4. predeployment check
run_check "predeployment_check" bash "$PROJECT_DIR/scripts/testnet/predeployment-check.sh" || true

# 5. RC1 verify
if [ -f "$PROJECT_DIR/scripts/release/verify-testnet-rc1.sh" ]; then
    run_check "rc1_verify" bash "$PROJECT_DIR/scripts/release/verify-testnet-rc1.sh" || true
else
    check_skip "rc1_verify" "verify-testnet-rc1.sh not found"
fi

# 6. Dashboard files check
if [ -f "$PROJECT_DIR/scripts/dev/check-dashboard-files.sh" ] && [ -x "$PROJECT_DIR/scripts/dev/check-dashboard-files.sh" ]; then
    run_check "dashboard_files_check" bash "$PROJECT_DIR/scripts/dev/check-dashboard-files.sh" || true
else
    check_skip "dashboard_files_check" "check-dashboard-files.sh not found or not executable"
fi

# 7. Local demo script check
if [ -f "$SCRIPT_DIR/check-local-demo-script.sh" ]; then
    run_check "local_demo_script_check" bash "$SCRIPT_DIR/check-local-demo-script.sh" || true
else
    # Self-check: the check script should exist now
    check_skip "local_demo_script_check" "check-local-demo-script.sh not found — run this from scripts/dev/"
fi

# 8. SDK package check
if [ -f "$PROJECT_DIR/scripts/dev/check-sdk-packages.sh" ] && [ -x "$PROJECT_DIR/scripts/dev/check-sdk-packages.sh" ]; then
    run_check "sdk_package_check" bash "$PROJECT_DIR/scripts/dev/check-sdk-packages.sh" || true
else
    check_skip "sdk_package_check" "check-sdk-packages.sh not found or not executable"
fi

# 9. Developer portal check
if [ -f "$PROJECT_DIR/scripts/dev/check-developer-portal.sh" ] && [ -x "$PROJECT_DIR/scripts/dev/check-developer-portal.sh" ]; then
    run_check "portal_check" bash "$PROJECT_DIR/scripts/dev/check-developer-portal.sh" || true
else
    check_skip "portal_check" "check-developer-portal.sh not found or not executable"
fi

# Count fast results
# We already tracked via run_check / check_pass / check_fail
# Reset and re-tabulate from evidence files
FAST_NAMES=("go_mod_verify" "go_build" "go_test" "predeployment_check" "rc1_verify" "dashboard_files_check" "local_demo_script_check" "sdk_package_check" "portal_check")
for check in "${FAST_NAMES[@]}"; do
    ef="$EVIDENCE_DIR/$check.txt"
    if [ -f "$ef" ]; then
        grep -q "^PASS:" "$ef" && FAST_CHECKS_PASS=$((FAST_CHECKS_PASS + 1)) || true
        head -1 "$ef" | grep -q "^FAIL:" && FAST_CHECKS_FAIL=$((FAST_CHECKS_FAIL + 1)) || true
        head -1 "$ef" | grep -q "^SKIP:" && FAST_CHECKS_SKIP=$((FAST_CHECKS_SKIP + 1)) || true
    fi
done

echo ""
echo "── FAST CHECKS Summary ──────────────────────────────────────"
echo "  PASS: $FAST_CHECKS_PASS | FAIL: $FAST_CHECKS_FAIL | SKIP: $FAST_CHECKS_SKIP"

# ── FULL CHECKS (only if --full) ──────────────────────────────────────────
if [ "$MODE" = "full" ]; then
    section "FULL CHECKS (Devnet-Dependent)"

    # 8. Launch devnet (if --with-devnet)
    if [ "$WITH_DEVNET" -eq 1 ]; then
        if [ -f "$PROJECT_DIR/scripts/release/launch-rc1-devnet.sh" ]; then
            run_check "launch_devnet" bash "$PROJECT_DIR/scripts/release/launch-rc1-devnet.sh" --single-node --clean --keep-running --evidence-dir "$EVIDENCE_DIR" || true
        else
            check_skip "launch_devnet" "launch-rc1-devnet.sh not found"
        fi
    else
        check_skip "launch_devnet" "Skipped (use --with-devnet for devnet-dependent checks)"
    fi

    # 9. Developer smoke (requires devnet)
    if [ "$WITH_DEVNET" -eq 1 ]; then
        if [ -f "$PROJECT_DIR/scripts/dev/run-developer-examples-smoke.sh" ]; then
            run_check "developer_smoke" bash "$PROJECT_DIR/scripts/dev/run-developer-examples-smoke.sh" || true
        else
            check_skip "developer_smoke" "run-developer-examples-smoke.sh not found"
        fi
    else
        check_skip "developer_smoke" "Requires --with-devnet"
    fi

    # 10. Write-flow smoke (requires devnet)
    if [ "$WITH_DEVNET" -eq 1 ]; then
        if [ -f "$PROJECT_DIR/scripts/dev/run-write-flow-examples-smoke.sh" ]; then
            run_check "writeflow_smoke" bash "$PROJECT_DIR/scripts/dev/run-write-flow-examples-smoke.sh" || true
        else
            check_skip "writeflow_smoke" "run-write-flow-examples-smoke.sh not found"
        fi
    else
        check_skip "writeflow_smoke" "Requires --with-devnet"
    fi

    # 11. Local demo (requires devnet)
    if [ "$WITH_DEVNET" -eq 1 ]; then
        DEMO_ARGS=""
        [ "$WITH_DASHBOARD" -eq 1 ] && DEMO_ARGS="$DEMO_ARGS --serve-dashboard"
        DEMO_ARGS="$DEMO_ARGS --skip-smoke --evidence-dir $EVIDENCE_DIR/local-demo-evidence"
        if [ -f "$PROJECT_DIR/scripts/dev/run-local-demo.sh" ]; then
            run_check "local_demo_with_devnet" bash "$PROJECT_DIR/scripts/dev/run-local-demo.sh" $DEMO_ARGS || true
        else
            check_skip "local_demo_with_devnet" "run-local-demo.sh not found"
        fi
    else
        check_skip "local_demo_with_devnet" "Requires --with-devnet"
    fi

    # 12. SDK local package
    run_check "sdk_local_package" bash "$PROJECT_DIR/scripts/dev/package-sdk-local.sh" || true

if [ "$MODE" = "full" ] && [ "$E2E" -eq 1 ]; then
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "  9. End-to-End Developer Demo"
    echo ""
    run_check "end_to_end_demo" bash "$PROJECT_DIR/scripts/dev/run-end-to-end-demo.sh" || true
    check_skip "end_to_end_demo" "run-end-to-end-demo.sh not found or not executable"
fi
    check_skip "sdk_local_package" "package-sdk-local.sh not found or not executable"

    # 13. Stop devnet
    if [ "$WITH_DEVNET" -eq 1 ]; then
        if [ -f "$PROJECT_DIR/scripts/release/stop-rc1-devnet.sh" ]; then
            run_check "stop_devnet" bash "$PROJECT_DIR/scripts/release/stop-rc1-devnet.sh" --evidence-dir "$EVIDENCE_DIR" || true
        else
            check_skip "stop_devnet" "stop-rc1-devnet.sh not found"
        fi
    else
        check_skip "stop_devnet" "Devnet was not started"
    fi

    # Count full results
    FULL_NAMES=("launch_devnet" "developer_smoke" "writeflow_smoke" "local_demo_with_devnet" "sdk_local_package" "end_to_end_demo" "stop_devnet")
    for check in "${FULL_NAMES[@]}"; do
        ef="$EVIDENCE_DIR/$check.txt"
        if [ -f "$ef" ]; then
            grep -q "^PASS:" "$ef" && FULL_CHECKS_PASS=$((FULL_CHECKS_PASS + 1)) || true
            head -1 "$ef" | grep -q "^FAIL:" && FULL_CHECKS_FAIL=$((FULL_CHECKS_FAIL + 1)) || true
            head -1 "$ef" | grep -q "^SKIP:" && FULL_CHECKS_SKIP=$((FULL_CHECKS_SKIP + 1)) || true
        fi
    done
fi

# ── Write summary evidence ────────────────────────────────────────────────
section "Writing Evidence Summary"

write_summary_json() {
    local json_file="$EVIDENCE_DIR/summary.json"
    cat > "$json_file" <<EOF
{
  "regression": "NexaRail Regression Matrix",
  "timestamp": "$TIMESTAMP",
  "mode": "$MODE",
  "with_devnet": $WITH_DEVNET,
  "with_dashboard": $WITH_DASHBOARD,
  "skip_build": $SKIP_BUILD,
  "fast_checks": {
    "pass": $FAST_CHECKS_PASS,
    "fail": $FAST_CHECKS_FAIL,
    "skip": $FAST_CHECKS_SKIP
  },
  "full_checks": {
    "pass": $FULL_CHECKS_PASS,
    "fail": $FULL_CHECKS_FAIL,
    "skip": $FULL_CHECKS_SKIP
  },
  "total": {
    "pass": $((FAST_CHECKS_PASS + FULL_CHECKS_PASS)),
    "fail": $((FAST_CHECKS_FAIL + FULL_CHECKS_FAIL)),
    "skip": $((FAST_CHECKS_SKIP + FULL_CHECKS_SKIP))
  },
  "evidence_dir": "$EVIDENCE_DIR",
  "environment": {
    "os": "$(uname -srm 2>/dev/null || echo 'unknown')",
    "go": "$(go version 2>/dev/null || echo 'go not found')",
    "git": "$(git -C "$PROJECT_DIR" rev-parse HEAD 2>/dev/null || echo 'unknown')"
  },
  "evidence_files": [
    "summary.json",
    "summary.md",
    "environment.txt"
  ]
}
EOF
    python3 -m json.tool "$json_file" > /dev/null 2>&1 && echo "  ✅ summary.json written" || {
        echo "  ⚠️  summary.json may be malformed (no python3 json.tool available)"
    }
}

write_summary_md() {
    local md_file="$EVIDENCE_DIR/summary.md"
    local total_pass=$((FAST_CHECKS_PASS + FULL_CHECKS_PASS))
    local total_fail=$((FAST_CHECKS_FAIL + FULL_CHECKS_FAIL))
    local total_skip=$((FAST_CHECKS_SKIP + FULL_CHECKS_SKIP))
    local total_checks=$((total_pass + total_fail + total_skip))

    cat > "$md_file" <<EOF
# NexaRail Regression Matrix — Evidence Summary

**Date:** $(date -u)
**Mode:** ${MODE}
**Evidence root:** \`${EVIDENCE_DIR}\`

## Results

| Group | Pass | Fail | Skip |
|---|---|---|---|
| FAST_CHECKS | ${FAST_CHECKS_PASS} | ${FAST_CHECKS_FAIL} | ${FAST_CHECKS_SKIP} |
| FULL_CHECKS | ${FULL_CHECKS_PASS} | ${FULL_CHECKS_FAIL} | ${FULL_CHECKS_SKIP} |
| **Total** | **${total_pass}** | **${total_fail}** | **${total_skip}** |

## Check Details

### FAST_CHECKS

EOF

    for check in "${FAST_NAMES[@]}"; do
        ef="$EVIDENCE_DIR/$check.txt"
        if [ -f "$ef" ]; then
            status=$(head -1 "$ef")
            echo "| ${check} | ${status} |" >> "$md_file"
        else
            echo "| ${check} | ⏭️ MISSING |" >> "$md_file"
        fi
    done

    if [ "$MODE" = "full" ]; then
        cat >> "$md_file" <<EOF

### FULL_CHECKS

EOF
        for check in "${FULL_NAMES[@]}"; do
            ef="$EVIDENCE_DIR/$check.txt"
            if [ -f "$ef" ]; then
                status=$(head -1 "$ef")
                echo "| ${check} | ${status} |" >> "$md_file"
            else
                echo "| ${check} | ⏭️ MISSING |" >> "$md_file"
            fi
        done
    fi

    cat >> "$md_file" <<EOF

## Environment

- **OS:** $(uname -srm 2>/dev/null || echo 'unknown')
- **Go:** $(go version 2>/dev/null || echo 'go not found')
- **Git:** $(git -C "$PROJECT_DIR" rev-parse HEAD 2>/dev/null || echo 'unknown')
- **Timestamp:** ${TIMESTAMP}

## Evidence Files

EOF

    for ef_path in "$EVIDENCE_DIR"/*.txt "$EVIDENCE_DIR"/summary.json "$EVIDENCE_DIR"/summary.md "$EVIDENCE_DIR"/environment.txt; do
        [ -f "$ef_path" ] || continue
        ef_name=$(basename "$ef_path")
        ef_size=$(wc -c < "$ef_path" | tr -d ' ')
        echo "- \`${ef_name}\` (${ef_size} bytes)" >> "$md_file"
    done

    echo ""
    echo "  ✅ summary.md written"
}

write_summary_json
write_summary_md

# ── Final output ──────────────────────────────────────────────────────────
TOTAL_PASS=$((FAST_CHECKS_PASS + FULL_CHECKS_PASS))
TOTAL_FAIL=$((FAST_CHECKS_FAIL + FULL_CHECKS_FAIL))
TOTAL_SKIP=$((FAST_CHECKS_SKIP + FULL_CHECKS_SKIP))

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Regression Matrix Complete                                ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5s %5s %5s\n" "Group" "PASS" "FAIL" "SKIP"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5d %5d %5d\n" "FAST_CHECKS" "$FAST_CHECKS_PASS" "$FAST_CHECKS_FAIL" "$FAST_CHECKS_SKIP"
printf "║  %-20s %5d %5d %5d\n" "FULL_CHECKS" "$FULL_CHECKS_PASS" "$FULL_CHECKS_FAIL" "$FULL_CHECKS_SKIP"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-20s %5d %5d %5d\n" "TOTAL" "$TOTAL_PASS" "$TOTAL_FAIL" "$TOTAL_SKIP"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  Evidence: $EVIDENCE_DIR"
echo "  Summary:  $EVIDENCE_DIR/summary.md"

if [ -n "$FAILED_CHECKS" ]; then
    echo ""
    echo "── Failed Checks ──────────────────────────────────────────"
    echo -n "$FAILED_CHECKS"
    echo ""
    echo "  ❌ ${TOTAL_FAIL} failure(s) detected."
else
    echo ""
    echo "  ✅ All ${TOTAL_PASS} checks passed."
fi

if [ "$MODE" = "full" ] && [ "$WITH_DEVNET" -eq 1 ]; then
    echo ""
    echo "  ⚠️  Devnet was started during this run."
    echo "     If --keep-running was used, you may need to stop it manually:"
    echo "     bash scripts/release/stop-rc1-devnet.sh"
fi

echo ""
exit "$TOTAL_FAIL"
