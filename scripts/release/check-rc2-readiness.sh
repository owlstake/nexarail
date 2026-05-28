#!/usr/bin/env bash
# NexaRail - RC2 readiness check
#
# Does not tag, upload, publish, or make launch claims.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
EVIDENCE_DIR="${EVIDENCE_DIR:-$PROJECT_DIR/rehearsals/rc2-readiness/evidence/$TIMESTAMP}"

PASS=0
FAIL=0
SKIP=0
WARN=0
DEFER=0
BLOCK=0

mkdir -p "$EVIDENCE_DIR"
SUMMARY="$EVIDENCE_DIR/summary.txt"
: > "$SUMMARY"

log() {
    echo "$*" | tee -a "$SUMMARY"
}

pass() {
    PASS=$((PASS + 1))
    log "PASS $1"
}

fail() {
    FAIL=$((FAIL + 1))
    log "FAIL $1"
}

skip() {
    SKIP=$((SKIP + 1))
    log "SKIP $1"
}

warn() {
    WARN=$((WARN + 1))
    log "WARN $1"
}

defer() {
    DEFER=$((DEFER + 1))
    log "DEFER $1"
}

block() {
    BLOCK=$((BLOCK + 1))
    log "BLOCK $1"
}

run_step() {
    local name="$1"
    shift
    local out="$EVIDENCE_DIR/${name}.log"
    log "RUN $name: $*"
    if "$@" > "$out" 2>&1; then
        pass "$name"
        return 0
    fi
    fail "$name (see $out)"
    BLOCK=$((BLOCK + 1))
    return 1
}

check_file() {
    local path="$1"
    if [ -f "$PROJECT_DIR/$path" ]; then
        pass "required file: $path"
    else
        fail "missing required file: $path"
        BLOCK=$((BLOCK + 1))
    fi
}

check_script() {
    local path="$1"
    if [ -x "$PROJECT_DIR/$path" ]; then
        pass "required executable: $path"
    else
        fail "missing executable: $path"
        BLOCK=$((BLOCK + 1))
    fi
}

cd "$PROJECT_DIR" || exit 1

log "NexaRail RC2 readiness check"
log "Timestamp UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
log "Project: $PROJECT_DIR"
log "Evidence: $EVIDENCE_DIR"
log ""

branch="$(git branch --show-current 2>/dev/null || echo unknown)"
commit="$(git rev-parse HEAD 2>/dev/null || echo unknown)"
status="$(git status --short 2>/dev/null || true)"
log "Branch: $branch"
log "Commit: $commit"
if [ -n "$status" ]; then
    warn "git status dirty"
    printf '%s\n' "$status" > "$EVIDENCE_DIR/git-status.txt"
else
    pass "git status clean"
fi

if command -v gh >/dev/null 2>&1; then
    if gh auth status >/dev/null 2>&1; then
        if gh run list -L 1 --json status,conclusion,headSha,workflowName > "$EVIDENCE_DIR/gh-latest-run.json" 2>"$EVIDENCE_DIR/gh-latest-run.err"; then
            conclusion="$(python3 - "$EVIDENCE_DIR/gh-latest-run.json" <<'PY'
import json, sys
data=json.load(open(sys.argv[1]))
print((data[0].get("conclusion") or data[0].get("status") or "unknown") if data else "none")
PY
)"
            if [ "$conclusion" = "success" ]; then
                pass "latest GitHub workflow success"
            else
                warn "latest GitHub workflow status: $conclusion"
            fi
        else
            skip "GitHub workflow query failed; manual CI check required"
        fi
    else
        skip "gh CLI not authenticated; manual CI check required"
    fi
else
    skip "gh CLI unavailable; manual CI check required"
fi

for file in \
    docs/release/RC2_DECISION_CRITERIA.md \
    docs/release/POST_RC1_HARDENING_EVIDENCE_ROLLUP.md \
    docs/release/RC2_RECOMMENDATION.md \
    docs/release/RC2_RELEASE_CHECKLIST.md \
    docs/release/GITHUB_RELEASE_V0.1.1_RC2_DRAFT.md \
    docs/release/RC1_TO_RC2_COMPARISON.md \
    docs/release/TECHNICAL_STATUS_ONE_PAGER.md \
    docs/release/KNOWN_LIMITATIONS_INDEX.md \
    docs/release/REVIEWER_HANDOFF.md \
    docs/testnet/AGENT_TESTNET_EVIDENCE_INDEX.md \
    docs/audit/AUDIT_PACKAGE_INDEX.md; do
    check_file "$file"
done

for script in \
    scripts/release/check-rc2-readiness.sh \
    scripts/testnet/run-five-agent-load-sim.sh \
    scripts/testnet/sample-agent-resources.sh \
    scripts/testnet/run-load-trend-profile.sh \
    scripts/testnet/check-product-flow-harness.sh \
    scripts/testnet/predeployment-check.sh \
    scripts/dev/run-nexarail-regression-matrix.sh \
    scripts/release/verify-testnet-rc1.sh; do
    check_script "$script"
done

run_step go_mod_verify go mod verify || true
run_step go_build go build ./... || true
run_step go_test go test ./... || true
run_step predeployment_check scripts/testnet/predeployment-check.sh || true
run_step regression_fast scripts/dev/run-nexarail-regression-matrix.sh --fast || true
if [ -d releases/testnet-rc1 ]; then
    run_step rc1_verify scripts/release/verify-testnet-rc1.sh || true
else
    skip "RC1 assets not present locally"
fi
run_step product_flow_harness scripts/testnet/check-product-flow-harness.sh || true

if [ -f docs/testnet/PHASE_16B2_ONE_HOUR_SOAK_RESULTS.md ]; then
    pass "one-hour soak report present"
    if grep -qiE "PARTIAL|requires rerunning|requires one rerun|canonical.*pending" docs/testnet/PHASE_16B2_ONE_HOUR_SOAK_RESULTS.md; then
        defer "canonical one-hour soak rerun pending"
    else
        pass "canonical one-hour soak appears complete"
    fi
else
    fail "one-hour soak report missing"
    BLOCK=$((BLOCK + 1))
fi

if [ -f docs/testnet/PHASE_16A6_FULL_PRODUCT_FLOW_REPLAY.md ]; then
    pass "product-flow replay report present"
    if grep -q "486 PASS / 1 FAIL" docs/testnet/PHASE_16A6_FULL_PRODUCT_FLOW_REPLAY.md; then
        defer "targeted post-fix governance/product-flow replay pending"
    else
        pass "product-flow replay has no recorded failed tx"
    fi
else
    fail "product-flow replay report missing"
    BLOCK=$((BLOCK + 1))
fi

pattern='mainnet live|buy NXRL|token sale|investment|guaranteed|profit|APY|returns|price|listing|external decentralisation|independent validators|private key|mnemonic|seed phrase|npm publish|PyPI publish'
rg -n -i "$pattern" README.md docs scripts \
    --glob '!docs/portal/**' \
    --glob '!**/*.png' \
    --glob '!**/*.jpg' \
    > "$EVIDENCE_DIR/safety-wording-scan.txt" 2>/dev/null || true
warn "safety wording scan written for manual classification"

recommendation="RC2_GO"
if [ "$BLOCK" -gt 0 ] || [ "$FAIL" -gt 0 ]; then
    recommendation="RC2_BLOCKED"
elif [ "$DEFER" -gt 0 ]; then
    recommendation="RC2_DEFER"
fi

cat > "$EVIDENCE_DIR/summary.json" <<EOF
{
  "pass": $PASS,
  "fail": $FAIL,
  "skip": $SKIP,
  "warn": $WARN,
  "defer": $DEFER,
  "block": $BLOCK,
  "recommendation": "$recommendation",
  "branch": "$branch",
  "commit": "$commit"
}
EOF

log ""
log "Summary: PASS=$PASS FAIL=$FAIL SKIP=$SKIP WARN=$WARN DEFER=$DEFER BLOCK=$BLOCK"
log "Readiness recommendation: $recommendation"

case "$recommendation" in
    RC2_GO) exit 0 ;;
    RC2_DEFER) exit 10 ;;
    *) exit 20 ;;
esac
