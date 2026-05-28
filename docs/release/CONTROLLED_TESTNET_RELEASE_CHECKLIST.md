# Controlled Testnet Release Checklist — NexaRail

**Date:** 2026-05-26
**Target:** nexarail-testnet-1
**Status:** Pre-release verification

---

## Pre-Release Gates

### Code Freeze

| # | Check | Status |
|---|---|---|
| 1 | No new protocol features added | ✅ |
| 2 | No economics changes | ✅ |
| 3 | No live flags enabled by default | ✅ |
| 4 | `go build ./...` passes | ✅ |
| 5 | `go vet ./...` passes | ✅ |
| 6 | `go test ./...` passes (15 packages, ~465 tests) | ✅ |
| 7 | Hardening suite run | ⚠️ Script prepared, not executed |

### Genesis Readiness

| # | Check | Status |
|---|---|---|
| 8 | Chain ID = `nexarail-testnet-1` | ✅ |
| 9 | Denom = `unxrl` | ✅ |
| 10 | Bech32 prefix = `nxr` | ✅ |
| 11 | All 6 live flags = false | ✅ |
| 12 | Custom modules present in genesis (6) | ✅ |
| 13 | Genesis assembly scripts ready | ✅ |
| 14 | Gentx verification script ready | ✅ |
| 15 | Genesis checksum script ready | ✅ |

### Validator Set

| # | Check | Status |
|---|---|---|
| 16 | ≥ 3 validators accepted | ❌ 0 validators |
| 17 | All validators on Linux | ❌ No validators |
| 18 | All gentxs collected and verified | ❌ 0 gentxs |
| 19 | Persistent peer list compiled | ❌ Awaiting validators |
| 20 | Validator communication channel ready | ⬜ Not created |

### Docker / Linux Rehearsal

| # | Check | Status |
|---|---|---|
| 21 | Docker 3-validator rehearsal completed | ✅ |
| 22 | Block height > 20 reached | ✅ |
| 23 | All peers ≥ 2 | ✅ |
| 24 | Chain ID confirmed | ✅ |
| 25 | Validator set = 3 | ✅ |
| 26 | Evidence collected | ✅ |
| 27 | macOS instability noted → Linux required | ✅ |

### Documentation

| # | Check | Status |
|---|---|---|
| 28 | All Phase 7A-G docs complete | ✅ |
| 29 | All Phase 8A-D docs complete | ✅ |
| 30 | Audit package finalised | ✅ |
| 31 | Security review complete | ✅ |
| 32 | Threat register populated | ✅ |
| 33 | Release checklist (this doc) | ✅ |
| 34 | FAQ covers testnet-only status | ✅ |

### Unsafe Wording

| # | Check | Status |
|---|---|---|
| 35 | No "mainnet live" in docs | ✅ |
| 36 | No "buy NXRL" in docs | ✅ |
| 37 | No "token sale" (positive) | ✅ |
| 38 | No "investment" (positive) | ✅ |
| 39 | Testnet-only disclaimers present | ✅ |

### Release Assets

| # | Check | Status |
|---|---|---|
| 40 | Release tag created | ⬜ Not yet |
| 41 | Linux binary built | ✅ |
| 42 | macOS binary built | ✅ |
| 43 | Checksums generated | ⬜ Not yet |
| 44 | Checksum file published | ⬜ Not yet |

### Operations

| # | Check | Status |
|---|---|---|
| 45 | Rollback plan documented | ✅ |
| 46 | Chain halt procedure documented | ✅ |
| 47 | Emergency contacts collected | ❌ No validators |
| 48 | Monitoring configured | ⬜ |
| 49 | Faucet deployment planned | ⬜ |

---

## Gate Summary

| Category | Passed | Remaining |
|---|---|---|
| Code Freeze | 6/7 | 1 (runtime suite not executed) |
| Genesis Readiness | 8/8 | 0 |
| Validator Set | 0/5 | 5 |
| Docker Rehearsal | 7/7 | 0 |
| Documentation | 7/7 | 0 |
| Unsafe Wording | 5/5 | 0 |
| Release Assets | 2/4 | 2 |
| Operations | 2/5 | 3 |

**Total: 37/49 gates passed. 12 remaining — all operational (validators, release assets, ops).**

---

## Rollback Plan

If the controlled testnet launch fails:

1. Coordinator declares halt in communication channel
2. All validators stop nodes
3. Coordinator diagnoses root cause
4. If genesis fix needed: new genesis, new checksum, new launch time
5. If minor fix: coordinated restart at new T-0
6. All validators wipe data if genesis change: `rm -rf ~/.nexarail/data/`
7. New genesis placed, new peer list distributed
8. New T-0 announced

## Decision

**🔴 NO-GO for launch.** Validator onboarding and gentx collection must complete first. All other gates pass.

---

## Phase 8G — Final Hardening & Sign-Off Gates

| # | Check | Status |
|---|---|---|
| 50 | Final hardening report completed | ✅ |
| 51 | Pre-launch sign-off completed | ✅ |
| 52 | Linux execution guide created | ✅ |
| 53 | Release candidate notes created | ✅ |
| 54 | Hardening suite passes (run-hardening-suite.sh) | ⚠️ Prepared, not executed on Linux |
| 55 | Stress suite passes (run-stress-tests.sh) | ✅ |
| 56 | Predeployment check passes (23/23) | ✅ |
| 57 | Ops scripts improved with PASS/FAIL | ✅ |
| 58 | Technical GO / Operational NO-GO decision recorded | ✅ |

**New total: 46/58 passed. Remaining: 12 (all operational/validator).**

---

## RC1 Packaging Gates

**Target:** testnet-rc1 packaging verification
**Date:** 2026-05-28
**Status:** In preparation

| # | Check | Status |
|---|---|---|
| 59 | Binary built for linux/amd64 and darwin/arm64 | ⬜ |
| 60 | Checksums generated and verified | ⬜ |
| 61 | Release notes complete | ⬜ |
| 62 | Known limitations documented | ⬜ |
| 63 | Evidence manifest complete | ⬜ |
| 64 | Validator action pack included | ⬜ |
| 65 | Genesis placeholder included | ⬜ |
| 66 | Private keys excluded | ⬜ |
| 67 | Predeployment check passed | ⬜ |
| 68 | Manifest JSON created | ⬜ |
| 69 | Verification script created and passing | ⬜ |
| 70 | Launch status still NO-GO for public/mainnet | ⬜ |

**RC1 Packaging: 0/12 passed.**
