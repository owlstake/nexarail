# Controlled Testnet Next Steps

**Date:** 2026-05-27  
**Scope:** next operational phase after Phase 9W agent runtime readiness consolidation

## Objective

Move from local agent-testnet runtime readiness to controlled public/external testnet readiness without adding product modules, changing economics, or enabling live flags by default.

## Phase 9X Activation Package

Phase 9X adds the operational package needed to start external validator activation:

- `PHASE_9X_EXTERNAL_VALIDATOR_ACTIVATION.md` for cohort targets, acceptance criteria, and operational gates.
- `MULTI_MACHINE_REHEARSAL_PLAN.md` for Linux/multi-machine rehearsal requirements.
- `EXTERNAL_VALIDATOR_ACTION_PACK.md` for validator-facing setup and gentx instructions.
- `VALIDATOR_RECRUITMENT_SHORTLIST_TARGETS.md` for placeholder target tracking without invented names.
- `EXTERNAL_GENTX_COLLECTION_READY_CHECK.md` for gentx acceptance and inclusion checks.
- `MULTI_MACHINE_EVIDENCE_CHECKLIST.md` for required rehearsal proof.
- `scripts/testnet/prepare-multi-machine-validator.sh` for Linux validator setup assistance.
- `scripts/testnet/collect-multi-machine-evidence.sh` for node evidence capture.

Phase 9X does not complete external onboarding. It prepares the handoff from local agent proof to external or multi-machine execution.

## 1. External Validator Cohort

Goal: form the first external validator cohort for the planned `nexarail-testnet-1` launch.

Required actions:

- Confirm minimum cohort target: 3 validators minimum, 5 preferred, 7 strong.
- Re-open or execute the existing validator application process.
- Score applicants using `docs/testnet/VALIDATOR_SCORING_RUBRIC.md`.
- Record accepted validators in `docs/testnet/GENESIS_VALIDATOR_SET_DRAFT.md`.
- Confirm operator contact details and backup contacts.
- Confirm each operator can run Linux or a production-like environment.

Exit criteria:

- At least 3 external validators accepted.
- Communication channel active.
- Each accepted validator acknowledges gentx and launch requirements.

## 2. Multi-Machine / Linux Rehearsal

Goal: prove the node runtime outside the local agent environment.

Required actions:

- Run a Linux build and node start rehearsal.
- Run at least a 3-validator multi-machine or production-like supervised rehearsal.
- Use `scripts/testnet/prepare-multi-machine-validator.sh` to standardise node setup where useful.
- Use `scripts/testnet/collect-multi-machine-evidence.sh` to capture per-node evidence.
- Validate peer connectivity, block production, and query/readback.
- Validate stop/start restart recovery under the target supervisor.
- Capture logs, versions, checksums, and evidence paths.

Exit criteria:

- Multi-machine or Linux rehearsal evidence captured.
- No unqualified external-validator or mainnet claims added.
- Remaining operational gaps documented.

## 3. Final Genesis Candidate

Goal: assemble a launch candidate only after external gentxs are received.

Required actions:

- Collect external gentxs with `scripts/testnet/collect-gentx.sh`.
- Validate each gentx with `scripts/testnet/verify-submitted-gentx.sh`.
- Run `docs/testnet/EXTERNAL_GENTX_COLLECTION_READY_CHECK.md` as the acceptance checklist.
- Assemble genesis with `scripts/testnet/assemble-testnet-genesis.sh`.
- Run `scripts/testnet/check-final-genesis.sh`.
- Verify all live flags remain `false`.
- Record genesis checksum and validator set.

Exit criteria:

- Final genesis candidate exists.
- Genesis checksum published internally.
- All external gentxs are validated and indexed.

## 4. Release Tag and Checksums

Goal: make the testnet binary and genesis artefacts reproducible for validators.

Required actions:

- Create release candidate notes in `docs/release/FINAL_RELEASE_CANDIDATE_NOTES.md`.
- Tag the release candidate.
- Build release artefacts for the target environment.
- Generate SHA256 checksums for binary and genesis files.
- Update `docs/release/RELEASE_TAGGING_AND_CHECKSUMS.md` if procedure drift is found.
- Freeze release-candidate inputs before final genesis publication: source commit, binary checksum, genesis checksum, peer list, and launch instructions.

Exit criteria:

- Release tag recorded.
- Checksums published.
- Validator instructions reference exact artefacts.

## 5. Public RPC / API Endpoint Plan

Goal: define access endpoints for validators and observers without implying mainnet availability.

Required actions:

- Decide whether coordinator-operated RPC/API endpoints are required for launch.
- Assign endpoint hosts, ports, TLS, rate limits, and monitoring.
- Prepare CometBFT RPC, REST API, and gRPC endpoint documentation.
- Define fallback endpoint policy.
- Add endpoint status to `docs/testnet/EXPLORER_AND_RPC.md`.

Exit criteria:

- RPC/API plan approved.
- Monitoring and incident response path documented.
- No public endpoint is announced before launch sign-off.

## 6. Validator Communication Plan

Goal: coordinate accepted validators through gentx, genesis, launch, and incident handling.

Required actions:

- Create the validator communication channel.
- Publish accepted-validator onboarding instructions.
- Schedule gentx submission and launch windows.
- Confirm backup contacts.
- Share halt/reset and incident reporting procedure.
- Keep all public wording testnet-only.

Exit criteria:

- Every accepted validator has acknowledged the launch process.
- Coordinator has a single source of truth for launch state.
- Incident process is ready before genesis is published.

## 7. Audit and Legal Review

Goal: prepare for external review without treating internal evidence as a substitute.

Required actions:

- Update `docs/audit/AUDIT_PACKAGE_INDEX.md` with Phase 9W evidence.
- Prepare auditor handoff for runtime, module, governance, and live-flag evidence.
- Prepare legal review package with current disclaimers.
- Keep token sale, investment, returns, price, listing, and mainnet claims prohibited.

Exit criteria:

- External audit path identified.
- Legal review path identified.
- Review blockers are tracked before any mainnet consideration.

## GO / NO-GO Guardrails

| Area | Status after Phase 9X |
|---|---|
| Agent-testnet runtime readiness | GO |
| Public/external testnet launch | NO-GO until external validators, gentxs, final genesis, endpoints, and communications are ready |
| Mainnet | NO-GO |

## Recommended Next Phase

Phase 9Y should execute external validator recruitment, accepted-validator channel setup, and the first multi-machine/Linux rehearsal.
