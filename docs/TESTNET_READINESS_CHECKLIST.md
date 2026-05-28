# NexaRail Testnet Readiness Checklist

**Document:** docs/TESTNET_READINESS_CHECKLIST.md
**Date:** 2026-05-26
**Target:** Phase 6 (Preparation) → Phase 8A (API, CLI, Runtime Hardening) (Gentx Collection & Genesis Assembly)

## Code & Tests

- [ ] Code freeze: no new protocol features
- [x] Full test suite: 14 packages, ~332 tests, all pass
- [x] `go build ./...` passes
- [x] `go vet ./...` passes
- [x] `go mod tidy && go mod verify` passes
- [x] All live flags default false, verified in tests
- [x] Live fund flows tested (escrow, treasury, payout, settlement progressive)

## Documentation

- [x] `TESTNET_PLAN.md` — scope, timeline, participants
- [x] `VALIDATOR_ONBOARDING.md` — hardware, install, keys, gentx
- [x] `GENESIS_CEREMONY.md` — chain ID, allocation, gentx collection
- [x] `FAUCET_PLAN.md` — rate limits, anti-abuse, security
- [x] `EXPLORER_AND_RPC.md` — explorer options, endpoint plan
- [x] `GOVERNANCE_TESTING.md` — proposal templates for all 6 flags
- [x] `BUG_BOUNTY_DRAFT.md` — scope, severity, disclosure (needs legal review)
- [x] `TESTNET_RUNBOOK.md` — launch, halt, upgrade, debugging
- [x] `PHASE_5_LIVE_FUNDS_STATUS.md` — module-by-module status
- [x] `LIMITATIONS.md` — updated with deferred items
- [x] `LIVE_FLAGS_MATRIX.md` — flag inventory with dependencies

## Scripts

- [x] `scripts/testnet/init-testnet-validator.sh` — validator node init
- [x] `scripts/testnet/collect-gentx.sh` — gentx collection tool
- [x] `scripts/testnet/validate-genesis.sh` — genesis validation
- [x] `scripts/testnet/check-node-health.sh` — node health check
- [x] `scripts/live-flags-smoke-test.sh` — flag default verification
- [x] `scripts/live-funds-e2e-test.sh` — manual E2E test commands

## GitHub & Community

- [x] Bug report template — `.github/bug_report.md`
- [x] Security report template — `.github/security_report.md`
- [x] Validator onboarding template — `.github/validator_onboarding.md`
- [x] Pull request template — `.github/pull_request_template.md`
- [ ] Discord server configured with testnet channels (TBD)
- [x] Testnet announcement drafted (docs/testnet/CONTROLLED_TESTNET_ANNOUNCEMENT_DRAFT.md)
- [x] Announcement finalised (docs/testnet/CONTROLLED_REGISTRATION_ANNOUNCEMENT_FINAL.md)

## Audit & Legal

- [x] `AUDIT_PACKAGE_INDEX.md` — external auditor index
- [x] `LEGAL_REVIEW_PACKAGE.md` — legal review prep (needs counsel)
- [ ] External security audit engaged
- [ ] Legal counsel engaged
- [ ] Testnet disclaimer reviewed by counsel

## Pre-Launch Actions (Before Public Testnet)

- [ ] Finalise chain ID (`nexarail-testnet-1`)
- [ ] Create genesis template
- [ ] Deploy seed node(s)
- [ ] Deploy faucet
- [ ] Deploy explorer
- [ ] Deploy RPC / REST / gRPC endpoints
- [ ] Configure monitoring
- [ ] Announce genesis ceremony
- [ ] Open validator registration
- [ ] Collect and validate gentx
- [ ] Publish final genesis + checksum
- [ ] Coordinate launch time

## Phase 7A — Controlled Registration Launch Pack

- [x] `CONTROLLED_VALIDATOR_REGISTRATION.md` — registration overview and requirements
- [x] `VALIDATOR_APPLICATION_FORM.md` — standardised application form
- [x] `VALIDATOR_ACCEPTANCE_CHECKLIST.md` — pre-launch checklist for validators
- [x] `VALIDATOR_COMMUNICATIONS_PLAN.md` — communication channels and protocols
- [x] `GENESIS_SUBMISSION_INSTRUCTIONS.md` — gentx creation and submission
- [x] `CONTROLLED_TESTNET_ANNOUNCEMENT_DRAFT.md` — public announcement draft
- [x] `FAQ.md` — frequently asked questions
- [x] `GENESIS_COORDINATOR_RUNBOOK.md` — internal coordinator operations
- [x] `.github/ISSUE_TEMPLATE/testnet_validator_application.md` — GitHub issue template
- [x] README updated with controlled registration status
- [x] `PUBLIC_VALIDATOR_REGISTRATION_GATE.md` updated

## Phase 7B — Outreach, Intake & Operations

- [x] `VALIDATOR_INTAKE_PIPELINE.md` — intake stages, SLAs, decision flow
- [x] `VALIDATOR_SCORING_RUBRIC.md` — 7-category scoring for technical review
- [x] `VALIDATOR_EMAIL_TEMPLATES.md` — 7 standardised email templates
- [x] `DISCORD_TELEGRAM_MODERATION_GUIDE.md` — community moderation rules
- [x] `CONTROLLED_REGISTRATION_ANNOUNCEMENT_FINAL.md` — final publishable announcement
- [x] `VALIDATOR_REGISTRATION_TRACKER_TEMPLATE.csv` — tracking spreadsheet
- [x] `GENESIS_GENTX_REVIEW_CHECKLIST.md` — 22-point gentx verification
- [x] Unsafe wording audit clean
- [x] Full verification (go mod tidy/verify, build, vet, test) green

## Phase 7C — Outreach Execution & Intake Tracking

- [x] `PHASE_7C_OUTREACH_EXECUTION.md` — execution plan, targets, channels
- [x] `VALIDATOR_SHORTLIST.md` — scored applicant tracking table
- [x] `VALIDATOR_OUTREACH_LOG.md` + CSV — outreach contact tracking
- [x] `GENESIS_VALIDATOR_SET_DRAFT.md` + CSV — accepted validator set draft
- [x] `VALIDATOR_COORDINATION_MESSAGE.md` — onboarding message for accepted validators
- [x] Unsafe wording audit clean
- [x] Full verification green

## Phase 7D — Validator Application Review & Gentx Coordination

- [x] `PHASE_7D_APPLICATION_REVIEW.md` — 5-step review framework with SLAs
- [x] `VALIDATOR_SHORTLIST.md` updated — per-category scores, review timestamps
- [x] `GENESIS_VALIDATOR_SET_DRAFT.md` updated — 7 validator slots
- [x] `GENTX_SUBMISSION_WINDOW.md` — gentx timeline, process, deadline
- [x] `GENTX_VALIDATION_RESULTS.md` — 22-point verification tracker
- [x] `ACCEPTED_VALIDATOR_ONBOARDING.md` — 10-step onboarding guide
- [x] `REJECTED_OR_WAITLISTED_VALIDATOR_RESPONSES.md` — 8 rejection codes
- [x] Unsafe wording audit clean
- [x] Full verification green

## Phase 7E — Gentx Collection, Genesis Assembly & Pre-Launch Freeze

- [x] `PHASE_7E_GENTX_COLLECTION.md` — collection process, validation, resubmission
- [x] `GENESIS_ASSEMBLY_LOG.md` — step-by-step assembly log with checksums
- [x] `GENESIS_VALIDATION_REPORT.md` — per-gentx validation, live flags, integrity
- [x] `TESTNET_LAUNCH_COORDINATION.md` — sync instructions, monitoring, halt/reset
- [x] `PRE_LAUNCH_FREEZE_CHECKLIST.md` — 47-point freeze checklist
- [x] `GENESIS_VALIDATOR_SET_DRAFT.md` updated — gentx tracking columns
- [x] `verify-submitted-gentx.sh` — 12+ check automated gentx validator
- [x] `assemble-testnet-genesis.sh` — automated genesis assembly
- [x] `check-final-genesis.sh` — 20+ check genesis integrity validator
- [x] Unsafe wording audit clean
- [x] Full verification green

- [x] README states "testnet only"
- [x] No token sale, no airdrop, no investment claims
- [x] Testnet disclaimer includes "zero monetary value"
- [x] Validator onboarding includes testnet code of conduct
- [x] No mainnet timeline published or promised

## Readiness Assessment

| Area | Status |
|---|---|
| Code quality | ✅ Ready |
| Test coverage | ✅ Ready |
| Documentation | ✅ Ready |
| Scripts / tools | ✅ Ready |
| GitHub templates | ✅ Ready |
| Audit package | ✅ Ready (auditor not yet engaged) |
| Legal package | ✅ Ready (counsel not yet engaged) |
| Infrastructure | 🔜 Needs deployment |
| Community | 🔜 Needs Discord + announcement |
| Pre-launch actions | 🔜 Pending |
| External reviews | 🔜 Pending |

## Phase 8A — API, CLI & Runtime Hardening

- [x] `PHASE_8A_API_ROUTE_AUDIT.md` — full audit of all 6 custom modules
- [x] REST gateway routes implemented — 17 new endpoints across 6 modules
- [x] `x/common/rest.go` — shared REST gateway helper
- [x] `cli-e2e-smoke-test.sh` — CLI E2E smoke test
- [x] `api-smoke-test.sh` — REST/gRPC smoke test
- [x] `RUNTIME_CONFIG_HARDENING.md` — devnet, testnet, and production configs
- [x] Debug commands: `debug-live-flags`, `debug-module-summary` (in addition to existing `debug-p2p-config`)
- [x] `CLI_E2E_TESTING.md` — CLI test documentation
- [x] `API_SMOKE_TESTING.md` — API test documentation
- [x] Unsafe wording audit clean
- [x] Full verification (go mod tidy/verify, build, vet, test) green — 15 packages

## Phase 8B — Module Test Gap Hardening

- [x] `PHASE_8B_TEST_GAP_AUDIT.md` — gap analysis across all 6 modules
- [x] CLI command registration tests — 4 new app tests (command trees, help, debug)
- [x] REST gateway route tests — verified via build + documented
- [x] Genesis tests added — escrow, payout, treasury (15 tests)
- [x] Query edge-case tests — not-found, empty state, exists (8 tests)
- [x] Live flag safety tests — app-level all-flags-false invariant
- [x] Module account permission tests — burner permission verification
- [x] Debug command tests — Help() non-panic across all modules
- [x] `TEST_COVERAGE_MATRIX.md` — per-package coverage breakdown
- [x] `LIVE_FUNDS_TEST_COVERAGE.md` — live flag and invariant coverage
- [x] `API_CLI_TEST_COVERAGE.md` — CLI, REST, gRPC test coverage
- [x] `test-coverage-summary.sh` — automated coverage reporting
- [x] Unsafe wording audit clean
- [x] Full verification green — all 15 packages pass

## Phase 8G — Final Hardening & Pre-Launch Sign-Off

- [x] `PHASE_8G_FINAL_HARDENING_REPORT.md` — technical GO / operational NO-GO
- [x] `PRE_LAUNCH_SIGN_OFF.md` — 7-section sign-off (engineering, security, release, ops, docs, validators, legal)
- [x] `LINUX_HARDENING_EXECUTION_GUIDE.md` — Linux environment, Docker rehearsal, hardening suite
- [x] `FINAL_RELEASE_CANDIDATE_NOTES.md` — version, checksums, live flags, limitations
- [x] Ops scripts improved — export-state.sh, check-upgrade-readiness.sh
- [x] Release checklist updated — Phase 8G gates added
- [x] Full verification green — all 15 packages pass (~497 tests)
- [x] Stress suite passes — invariants, fuzz, random, failure
- [x] Predeployment check: 23/23
- [x] Unsafe wording audit clean
- [x] Technical: ✅ GO | Operational: 🔴 NO-GO (0 validators)

## Phase 9W — Agent Testnet Runtime Readiness Consolidation

- [x] `PHASE_9W_AGENT_RUNTIME_READINESS_REPORT.md` — consolidated runtime readiness report complete
- [x] `AGENT_TESTNET_EVIDENCE_INDEX.md` — Phase 9T, 9U, and 9V evidence index complete
- [x] `AGENT_TESTNET_LIMITATIONS.md` — limitations documented; agent validators are not external validators
- [x] `CONTROLLED_TESTNET_NEXT_STEPS.md` — next operational phase documented
- [x] Restart matrix passed — single-validator, 3-agent, 5-agent, height-20, post-soak, one-node, simultaneous all-node, sequential all-node, standard direct
- [x] Long soak passed — 3602s, height 12 to 685, 425 pass / 0 fail / 0 skip
- [x] Governance evidenced — proposal 1 enabled escrow live flag, proposal 2 disabled it, final flags false
- [x] Runtime bank tx evidenced — inclusion code 0
- [x] Final live flags all false
- [x] Technical agent-testnet readiness: GO
- [x] Public/external testnet launch: NO-GO until external validators and gentxs are complete
- [x] Mainnet: NO-GO
