# Controlled Testnet Coordinator Checklist

**Network:** `nexarail-testnet-1`
**Status:** launch candidate preparation

## Phase 18A Internal Coordinator Candidate

- [x] Create internal coordinator candidate plan.
- [x] Keep external-validator intake open while coordinator readiness work continues.
- [x] Generate coordinator-only local gentxs.
- [x] Assemble internal coordinator candidate under `releases/testnet-genesis/coordinator-candidate/`.
- [x] Mark the artifact `INTERNAL COORDINATOR CANDIDATE — NOT FINAL PUBLIC GENESIS`.
- [x] Validate genesis and compute SHA256.
- [x] Confirm product live flags remain false.
- [x] Run local dry-run from the generated candidate to height 20.
- [x] Confirm validator count matches the five internal coordinator validators.
- [x] Confirm node ID helper commands work.
- [x] Confirm no panic/fatal log markers in the dry-run evidence.
- [x] Confirm this candidate is not treated as final public genesis.

## Intake

- [ ] Publish validator intake template.
- [ ] Confirm accepted validator list.
- [ ] Populate `coordination/validators/validator-intake.csv` with non-secret intake records only.
- [ ] Collect moniker, contact, operator address, account address, node ID, host, P2P port, gentx hash, build tag/commit, OS/arch, and sentry layout.
- [ ] Confirm each validator acknowledged testnet-only and no monetary-value terms.
- [ ] Confirm no validator sent secrets or node data.
- [ ] Run `scripts/testnet/validate-validator-intake.sh`.

## Public Join Readiness

- [x] Source-build path documented.
- [x] CLI node ID commands documented and verified from source.
- [x] Gentx command documented.
- [x] Intake form exists.
- [x] Gentx verifier exists.
- [x] Genesis assembler exists.
- [x] Persistent peers generator exists.
- [x] Runbook exists.
- [x] Status document exists.
- [x] Endpoint inventory template exists.
- [x] Monitoring script exists.
- [ ] Support channel placeholder replaced with the final launch-window channel.
- [ ] Final public genesis reviewed after verified external gentxs exist.
- [ ] Launch time confirmed.

## Phase 18B Intake Execution

- [x] Create external validator intake execution doc.
- [x] Create submission tracker.
- [x] Create validator intake message pack.
- [x] Validate current intake state.
- [x] Confirm no external validator submissions were present before NodeSync.
- [x] Confirm registry remained empty until real submissions arrived.
- [x] Generate waiting-state persistent peer outputs.
- [x] Create final genesis freeze decision.
- [x] Defer final public genesis while launch criteria remain unmet.
- [x] Add real public validator records after receipt.
- [x] Verify submitted gentxs.
- [x] Generate external persistent peers from complete records.
- [ ] Freeze final public genesis after accepted external gentxs exist.

## Phase 18C Launch Operations

- [x] Create incident response runbook.
- [x] Create launch-day command sheet.
- [x] Create first-hour evidence collection script.
- [x] Create genesis publication checklist.
- [x] Create validator support triage template.
- [x] Create launch readiness dashboard.
- [x] Confirm launch-hour evidence collection handles empty endpoint inventory.
- [x] Confirm readiness monitor handles empty endpoint inventory.
- [ ] Run launch-hour evidence against real external endpoints after validators submit them.
- [ ] Replace launch-window placeholders with final UTC time, genesis hash, and peer string.

## Phase 17C First External Submission

- [x] Record NodeSync public metadata in the submission tracker.
- [x] Record NodeSync P2P-only endpoint in the endpoint inventory.
- [x] Confirm the gentx JSON file content was initially not present in the coordinator workspace.
- [x] Keep the accepted intake registry unchanged until the gentx file was received and verified.
- [x] Fix validator docs to require `add-genesis-account` before `gentx`.
- [x] Receive the original NodeSync gentx JSON file.
- [x] Verify the NodeSync gentx SHA256.
- [x] Run the direct controlled gentx verifier for NodeSync.
- [x] Copy NodeSync gentx to `coordination/validators/verified/` only after verification passes.
- [x] Generate persistent peers from accepted records after verification.
- [x] Confirm NodeSync final peer host uses DNS.
- [ ] Re-run final genesis freeze gate after coordinator launch criteria are satisfied.

## Phase 17D External Validator Genesis Candidate

- [x] Decide candidate composition: NodeSync plus five coordinator-operated validators.
- [x] Assemble controlled external-validator genesis candidate for review.
- [x] Mark candidate as not final public genesis.
- [x] Verify NodeSync is present in candidate genesis.
- [x] Regenerate persistent peers from accepted intake records.
- [x] Confirm NodeSync DNS resolves.
- [x] Record TCP 26656 reachability result.
- [x] Dry-run candidate to height 20 with validator set count 6.
- [x] Keep final freeze decision deferred.
- [ ] Confirm NodeSync P2P TCP reachability before launch freeze.
- [ ] Complete final public genesis review.
- [ ] Confirm launch window and coordinator sign-off.

## Phase 17E NodeSync Reachability And Freeze Gate

- [x] Recheck NodeSync DNS.
- [x] Record DNS TTL.
- [x] Check TCP 26656 against DNS host.
- [x] Check TCP 26656 against direct IP.
- [x] Rerun candidate genesis SHA256 check.
- [x] Rerun candidate `validate-genesis`.
- [x] Verify NodeSync remains in candidate genesis.
- [x] Verify candidate product live flags remain false.
- [x] Verify no secret material pattern in candidate release artifacts.
- [x] Keep freeze decision deferred because TCP 26656 is not reachable.
- [ ] Confirm NodeSync has opened/listens on TCP 26656 before freeze.
- [ ] Copy candidate artifacts to final public genesis folder only after `FREEZE_GO`.

## Phase 17F Coordinator Launch Rehearsal

- [x] Rehearse the external-validator genesis candidate with five coordinator signers.
- [x] Confirm candidate dry-run reaches height 50.
- [x] Confirm validator set count reports 6.
- [x] Confirm NodeSync is present in the validator set but not locally simulated.
- [x] Confirm product live flags remain false during rehearsal.
- [x] Confirm REST params are queryable during rehearsal.
- [x] Confirm no panic/fatal log markers in the dry-run evidence.
- [x] Run launch-hour evidence collector against local coordinator endpoints.
- [x] Run readiness monitor against local coordinator endpoints.
- [x] Record NodeSync reachability as `NOT_REACHABLE`.
- [ ] Re-run P2P reachability after NodeSync confirms TCP 26656 is open.
- [ ] Re-run final genesis freeze gate after NodeSync reachability and launch sign-off.

## Phase 17E.1 Genesis Denom Audit And P2P Preconditions

- [x] Receive NodeSync clarification that Phase 17E refusal was because the real node was not started yet.
- [x] Note that a temporary `nc` listener on 26656 is not evidence of CometBFT P2P readiness.
- [x] Add `scripts/testnet/check-genesis-denoms.sh` to formalise denom audit.
- [x] Run denom audit on the candidate: `PASS` (7 pass / 0 fail / 1 warn).
- [x] Confirm `staking.params.bond_denom = unxrl` and all linked denoms.
- [x] Confirm no `stake`/`uatom`/`atom`/`token`/`nstake` strings present.
- [x] Confirm no genesis fix required; candidate SHA256 unchanged.
- [x] Record real P2P freeze preconditions (`docs/testnet/PHASE_17E1_GENESIS_DENOM_AUDIT_AND_P2P_PRECONDITIONS.md`).
- [ ] Verify real CometBFT peer handshake (real `nexaraild start`, real `/net_info` peer count > 0) before `FREEZE_GO`.
- [ ] Seed `bank.denom_metadata` for `unxrl` ahead of public freeze (non-blocking; explorer/UX nicety).

## Phase 17H Freeze Gate And Launch Packet

- [x] Add `scripts/testnet/check-final-genesis-freeze-gate.sh` (single authoritative gate).
- [x] Run freeze gate against candidate: `FREEZE_DEFER` (12 pass / 0 fail / 2 defer).
- [x] Add `docs/testnet/CONTROLLED_TESTNET_LAUNCH_SIGNOFF.md` with PENDING status.
- [x] Add `docs/testnet/CONTROLLED_TESTNET_FINAL_LAUNCH_PACKET_DRAFT.md` (DRAFT — NOT FINAL).
- [x] Add `docs/testnet/NODESYNC_LAUNCH_WINDOW_INSTRUCTIONS.md` (DRAFT).
- [ ] At launch window: re-run freeze gate with `--probe-rpc … --require-p2p --require-signoff` against the final genesis.
- [ ] Mark launch sign-off `APPROVED` only after freeze gate returns `FREEZE_GO`.
- [ ] Copy candidate to `releases/testnet-genesis/nexarail-testnet-1/` only after `FREEZE_GO`.

## Gentx Validation

- [ ] Store submitted gentxs in a coordinator-only working directory.
- [x] Store pending gentxs in `coordination/validators/gentxs/`.
- [x] Run `scripts/testnet/verify-controlled-testnet-gentx.sh` for every received gentx.
- [x] Copy verified gentxs to `coordination/validators/verified/`.
- [ ] Copy rejected gentxs to `coordination/validators/rejected/` with reason files.
- [x] Confirm accepted gentxs are collected into a `nexarail-testnet-1` review candidate and `collect-gentxs` signature validation passes.
- [x] Confirm self-delegation denom is `unxrl`.
- [x] Confirm moniker and operator address are present.
- [x] Confirm no private material or live-flag edits appear in gentx files.
- [ ] Return failed gentxs with exact failure reasons before freeze.
- [ ] Freeze accepted gentx set.

## Genesis Assembly

- [x] Run `scripts/testnet/assemble-controlled-testnet-genesis.sh` for the Phase 17D review candidate.
- [ ] Do not assemble final genesis until verified gentx count is greater than zero.
- [ ] Confirm `validate-genesis` passes.
- [ ] Confirm all product live flags remain false.
- [ ] Write final genesis to `releases/testnet-genesis/nexarail-testnet-1/genesis.json`.
- [ ] Write `SHA256SUMS`.
- [ ] Write `manifest.json`.
- [ ] Verify genesis SHA256 independently.

## Peers

- [x] Run `scripts/testnet/generate-persistent-peers.sh`.
- [x] Write peer output to `coordination/validators/peer-info/`.
- [x] Review warnings for missing node IDs, hosts, or ports.
- [x] Resolve NodeSync DNS/IP peer host confirmation.
- [ ] Publish persistent peers string.
- [ ] Publish per-validator peer snippets.
- [ ] Publish seed or bootnode information if available.

## Pre-Launch

- [ ] Publish final genesis checksum.
- [ ] Confirm every validator verifies checksum locally.
- [ ] Confirm P2P port open for every validator.
- [ ] Confirm every validator has configured persistent peers.
- [ ] Confirm every validator is present in the support channel.
- [ ] Confirm launch window and fallback window.

## Launch Window

- [ ] T-15m: final readiness check.
- [ ] T-5m: confirm no replacement gentxs or peer changes.
- [ ] T-0: validators start nodes.
- [ ] First 10 blocks: confirm chain ID, height, peer count, validator set count, and signing.
- [ ] First 100 blocks: confirm continued block production, no unexpected jailed validators, and stable peers.
- [ ] First hour: confirm no halt, no checksum mismatch, live flags false, and validators reachable.

## Halt And Rollback Conditions

- [ ] No blocks after launch window start.
- [ ] Validator set differs from final manifest.
- [ ] Genesis checksum mismatch.
- [ ] Any product live flag unexpectedly true.
- [ ] Material peer configuration error blocks consensus.
- [ ] Validator secret exposure.
- [ ] Coordinator cannot contact enough validators to maintain launch safety.

## Post-Launch Candidate Evidence

- [ ] Save block height at 10 blocks.
- [ ] Save block height at 100 blocks.
- [ ] Save first-hour status.
- [ ] Save validator set query.
- [ ] Save live-flag query output.
- [ ] Save peer count evidence.
- [ ] Publish status update only after evidence exists.
