# Phase 8D — Pre-Deployment Review

**Date:** 2026-05-26
**Reviewer:** Clove
**Decision:** 🔴 NO-GO (operational — no validators)

---

## What Is Ready

| Area | Status |
|---|---|
| **Code quality** | ✅ 15 packages, ~465 tests, all passing |
| **Module completeness** | ✅ 6 custom modules implemented and tested |
| **API surface** | ✅ 17 REST endpoints, gRPC services, CLI commands |
| **Debug tooling** | ✅ 3 debug commands, 4 smoke scripts |
| **Docker rehearsal** | ✅ 3 validators, height >20, peers ≥2 |
| **Live flags** | ✅ All 6 default to false |
| **Genesis tooling** | ✅ Assembly, validation, checksum scripts |
| **Security review** | ✅ 15 categories reviewed, threat register populated |
| **Audit package** | ✅ Finalised for external review |
| **Documentation** | ✅ 50+ documents across design, security, testnet, hardening |
| **Unsafe wording** | ✅ Clean across all docs and scripts |
| **Change control** | ✅ Policy documented and active |
| **Release tooling** | ✅ Tagging, checksum, verification procedures |

## What Is NOT Ready

| Area | Status | Blocker |
|---|---|---|
| **Validator set** | ❌ 0 validators | No applications received |
| **Gentx collection** | ❌ 0 gentxs | No accepted validators |
| **Genesis assembly** | ❌ Not built | No gentxs to include |
| **Communication channel** | ❌ Not created | No validators to communicate with |
| **Launch time** | ❌ Not set | No genesis, no validators |
| **Runtime smoke tests** | ⚠️ Not executed | No running node |
| **Hardening suite** | ⚠️ Script prepared | Not executed (no node) |
| **Release tag** | ⚠️ Not created | Awaiting launch readiness |
| **Faucet** | ⚠️ Not deployed | Genesis can include faucet account |
| **Explorer** | ⚠️ Not deployed | Optional for controlled testnet |

## Blocking Issues

| # | Issue | Severity | Action Required |
|---|---|---|---|
| 1 | No validators onboarded | **Critical** | Execute validator outreach |
| 2 | No gentxs collected | **Critical** | Onboard validators, collect gentxs |
| 3 | No genesis candidate | **Critical** | Assemble after gentx collection |
| 4 | No communication channel | High | Create Discord/Telegram |

## Non-Blocking Issues

| # | Issue | Severity | Notes |
|---|---|---|---|
| 5 | macOS Docker instability | Medium | Requires Linux hosts for validators — documented |
| 6 | gRPC-Gateway manual wiring | Low | Works but not proto-generated — documented |
| 7 | No formal third-party audit | Medium | Audit package ready, auditor not engaged |
| 8 | No legal review | Medium | Legal package ready, counsel not engaged |
| 9 | Runtime smoke not executed | Low | Scripts prepared, can run on Linux host |
| 10 | Faucet not deployed | Low | Can be added post-genesis |

## Recommended Actions Before Launch

1. **Execute validator outreach** — post to GitHub, forums, direct contacts
2. **Accept ≥ 3 validators** — score against rubric, send acceptance packages
3. **Collect gentxs** — open window, verify with `verify-submitted-gentx.sh`
4. **Assemble genesis** — run `assemble-testnet-genesis.sh`
5. **Verify genesis** — run `check-final-genesis.sh`
6. **Create communication channel** — Discord or Telegram
7. **Run hardening suite on Linux host** — `run-hardening-suite.sh`
8. **Create release tag** — follow `RELEASE_TAGGING_AND_CHECKSUMS.md`
9. **Publish genesis + checksum** — distribute to validators
10. **Coordinate launch** — T-0 synchronised

## GO / NO-GO Status

**🔴 NO-GO** — controlled testnet launch cannot proceed.

**Reason:** Zero validators onboarded. All 49 operational gates must pass for GO. Currently 37 pass (code, docs, rehearsal, security) and 12 remain (all validator/genesis/ops).

**Path to GO:** Complete validator outreach → onboard ≥3 validators → collect gentxs → assemble genesis → publish checksums → coordinate launch.
