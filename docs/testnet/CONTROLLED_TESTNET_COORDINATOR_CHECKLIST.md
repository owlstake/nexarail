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

## Gentx Validation

- [ ] Store submitted gentxs in a coordinator-only working directory.
- [ ] Store pending gentxs in `coordination/validators/gentxs/`.
- [ ] Run `scripts/testnet/verify-controlled-testnet-gentx.sh` for every gentx.
- [ ] Copy verified gentxs to `coordination/validators/verified/`.
- [ ] Copy rejected gentxs to `coordination/validators/rejected/` with reason files.
- [ ] Confirm gentxs are collected into a `nexarail-testnet-1` genesis and `collect-gentxs` signature validation passes.
- [ ] Confirm self-delegation denom is `unxrl`.
- [ ] Confirm moniker and operator address are present.
- [ ] Confirm no private material or live-flag edits appear in gentx files.
- [ ] Return failed gentxs with exact failure reasons before freeze.
- [ ] Freeze accepted gentx set.

## Genesis Assembly

- [ ] Run `scripts/testnet/assemble-controlled-testnet-genesis.sh`.
- [ ] Do not assemble final genesis until verified gentx count is greater than zero.
- [ ] Confirm `validate-genesis` passes.
- [ ] Confirm all product live flags remain false.
- [ ] Write final genesis to `releases/testnet-genesis/nexarail-testnet-1/genesis.json`.
- [ ] Write `SHA256SUMS`.
- [ ] Write `manifest.json`.
- [ ] Verify genesis SHA256 independently.

## Peers

- [ ] Run `scripts/testnet/generate-persistent-peers.sh`.
- [ ] Write peer output to `coordination/validators/peer-info/`.
- [ ] Review warnings for missing node IDs, hosts, or ports.
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
