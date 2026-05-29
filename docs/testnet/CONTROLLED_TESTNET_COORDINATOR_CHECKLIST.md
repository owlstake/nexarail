# Controlled Testnet Coordinator Checklist

**Network:** `nexarail-testnet-1`
**Status:** launch candidate preparation

## Intake

- [ ] Publish validator intake template.
- [ ] Confirm accepted validator list.
- [ ] Populate `coordination/validators/validator-intake.csv` with non-secret intake records only.
- [ ] Collect moniker, contact, operator address, account address, node ID, host, P2P port, gentx hash, build tag/commit, OS/arch, and sentry layout.
- [ ] Confirm each validator acknowledged testnet-only and no monetary-value terms.
- [ ] Confirm no validator sent secrets or node data.
- [ ] Run `scripts/testnet/validate-validator-intake.sh`.

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
