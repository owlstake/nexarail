# RC2 Decision Criteria

## Purpose

Define the evidence needed to decide whether NexaRail should cut `v0.1.1-rc2` after the post-RC1 hardening work.

This decision document does not change launch status. Mainnet remains NO-GO, public testnet remains NO-GO, external validators remain pending, SDK packages remain local-only, and live flags remain false by default.

## Criteria

| Criterion | Current Evidence | Status |
|---|---|---|
| Code changes since RC1 are reviewable | `git diff v0.1.0-rc1..main` spans validation fixes, tests, harnesses, release docs, and evidence docs | Met |
| Validation fixes landed | Phase 14B/14C validation, governance-authority, params-event, and error-message hardening | Met |
| Governance vote reliability fixed | Phase 16A.7 routed votes through each validator RPC and added retry/sequence refresh | Met |
| Test coverage expanded | Phase 14D state-transition/invariant tests and Phase 15A bounded fuzz/invariant framework | Met |
| Five-agent runtime validated | Phase 16A multi-node validation, restart recovery, soak, and load profiling | Mostly met |
| Product-flow replay rerun | Phase 16A.6: 486 PASS / 1 transient vote tx failure; proposal still passed | Needs targeted replay before tag |
| Soak/restart/load evidence captured | Restart recovery passed; Phase 16C load passed; Phase 16D L1/L2/L3 local trend baseline captured; one-hour soak raw stability passed but canonical rerun remains pending | Defer gate |
| CI status | Repo-level CI reported passing before Phase 16E; readiness script can optionally query `gh` if available | Manual/current check required |
| Documentation updated | Post-RC1 rollup, recommendation, checklist, draft release notes, comparison, indexes | In progress in Phase 16E |
| Safety wording status | Phase 16C safety audit passed; Phase 16E audit required before commit | In progress in Phase 16E |

## Decision Options

### Option A - Cut RC2 Now

Use only if:
- canonical one-hour soak evidence is complete and clean
- targeted governance replay after Phase 16A.7 is clean
- readiness script returns `RC2_GO`
- verification and safety audit pass

Current status: not recommended.

### Option B - Defer RC2 Until One-Hour Soak Is Canonical

Use if the post-RC1 code and load evidence are strong, but the Phase 16B.2 one-hour soak still has non-canonical harness accounting.

Current status: recommended.

### Option C - Defer RC2 Until Product-Flow Replay Has 0 Failed TXs

Use if the only remaining release-quality doubt is the Phase 16A.6 transient vote tx failure.

Current status: recommended as a paired gate with Option B.

### Option D - Defer RC2 Until External Validator Rehearsal

Use if RC2 is intended to represent external validator readiness.

Current status: not required for a local-evaluation RC2, but required before any external validator or public testnet claim.

### Option E - No RC2 Needed

Keep `main` as a post-RC1 hardening branch and do not cut a new release candidate.

Current status: acceptable if the release goal is documentation-only, but weaker for reviewers because RC1 binaries do not include all post-RC1 hardening.

## Decision

Recommended decision: **RC2 preparation: yes. RC2 tag/release: defer.**

Phase 16E readiness check result:

```text
scripts/release/check-rc2-readiness.sh
PASS=29 FAIL=0 SKIP=0 WARN=2 DEFER=2 BLOCK=0
Recommendation: RC2_DEFER
```

Required before changing this to `RC2_GO`:
- rerun one-hour five-agent soak with the patched canonical harness
- run targeted product-flow/governance replay after the Phase 16A.7 vote reliability fix
- rerun full verification and safety audit
- run `scripts/release/check-rc2-readiness.sh` and receive `RC2_GO`
