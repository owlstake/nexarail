# RC2 Recommendation

## Recommendation

**RC2 preparation: yes. RC2 tag/release: defer.**

The post-RC1 branch is materially stronger than RC1 and is worth packaging into an RC2 candidate, but not before two release-quality evidence gaps are closed:
- canonical one-hour five-agent soak rerun with the patched harness
- targeted product-flow/governance replay after the Phase 16A.7 vote sequence/routing fix

Readiness script result during Phase 16E:

```text
PASS=29 FAIL=0 SKIP=0 WARN=2 DEFER=2 BLOCK=0
Recommendation: RC2_DEFER
Evidence: rehearsals/rc2-readiness/evidence/20260528T234901Z/
```

Safety audit result during Phase 16E:

```text
PASS
Evidence: rehearsals/rc2-readiness/evidence/phase16e-safety-audit-20260528T235319Z/
```

## Reasons

- Validation and event hardening landed after RC1.
- State-transition, invariant, and bounded fuzz coverage expanded after RC1.
- Five-agent local runtime validation is materially stronger after RC1.
- Restart recovery passed.
- Phase 16C local load simulation passed at smoke, 10-minute, and heavier profiles.
- Phase 16D captured L1/L2/L3 trend evidence with resource sampling.
- Live flags remained false across the relevant local evidence.
- Log scans in the relevant load evidence were clean.

## Blockers Before RC2 Tag

| Blocker | Why It Matters | Required Evidence |
|---|---|---|
| Canonical one-hour soak rerun | Current one-hour raw stability passed, but original harness accounting was partial | Patched-harness one-hour run with clean `summary.json`, tx evidence, REST/RPC health, live flags false, clean scans |
| Targeted governance/product-flow replay | Phase 16A.6 had one transient vote tx failure before the Phase 16A.7 fix | Replay affected governance path or full product-flow suite with 0 failed txs |
| RC2 readiness script | Release must be mechanically checked before tag | `scripts/release/check-rc2-readiness.sh` returns `RC2_GO` |
| Safety wording audit | Release docs must not widen launch claims | Audit passes with only explicit denials, technical terms, or scanner patterns |

## Go / No-Go Table

| Gate | Current Status | RC2 Decision |
|---|---|---|
| Code hardening since RC1 | Met | GO |
| Test coverage expansion | Met | GO |
| Five-agent local runtime validation | Mostly met | GO for local evaluation |
| Product-flow replay | 486 PASS / 1 transient failure, fixed afterward | DEFER until targeted replay |
| One-hour soak | Raw stability passed, canonical harness rerun pending | DEFER |
| Load simulation | Phase 16C passed | GO for local evidence |
| Trend profiling | L1/L2/L3 captured; L4 partial | GO for local trend baseline, not a release blocker |
| External validators | Pending | NO-GO for public/external claims |
| Public testnet | Not launched | NO-GO |
| Mainnet | Not launched | NO-GO |

## Exact Next Required Evidence

1. Run patched one-hour soak:

```bash
scripts/testnet/run-five-agent-long-soak.sh --duration 3600 --sample-interval 30 --tx-interval 120 --evidence-dir rehearsals/validator-agents/long-soak/evidence/phase16e-canonical-soak-<timestamp>
```

2. Run targeted governance/product-flow replay:

```bash
scripts/testnet/run-product-flow-rehearsal.sh --suite settlement --force-clean --global-timeout 1800
```

If time permits, run the full suite:

```bash
scripts/testnet/run-product-flow-rehearsal.sh --suite all --force-clean --global-timeout 5400
```

3. Rerun:

```bash
scripts/release/check-rc2-readiness.sh
```

## Proposed RC2 Scope

Include:
- validation fixes
- params-event and error-message improvements
- state-transition, invariant, and fuzz test expansion
- governance vote reliability hardening
- five-agent local runtime harness hardening
- restart, soak, load, and trend profiling evidence docs
- updated reviewer/release docs

## Proposed RC2 Excluded Items

Exclude:
- public testnet launch
- mainnet launch
- external validator activation claims
- SDK publishing to npm/PyPI
- production throughput claims
- economics changes
- default live-flag enablement
- product module additions
