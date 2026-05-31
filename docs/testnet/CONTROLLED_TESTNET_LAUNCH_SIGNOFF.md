# Controlled Testnet Launch Sign-off

**Network:** `nexarail-testnet-1`
**Document:** `docs/testnet/CONTROLLED_TESTNET_LAUNCH_SIGNOFF.md`
**Status:** APPROVED_FOR_GENESIS_PUBLICATION

This document is the single sign-off record for the controlled external-validator testnet launch. The freeze gate script (`scripts/testnet/check-final-genesis-freeze-gate.sh`) reads the `**Status:**` line above; any value beginning with `APPROVED` advances the static gate, `PENDING` defers it, and `BLOCKED` blocks it.

Current state: the final controlled-testnet genesis artifacts have been frozen and may be **distributed** to validators. The controlled testnet itself is **not live** until block production and validator connectivity are evidenced under a separate launch step. This is **NOT MAINNET**. External decentralisation is not claimed until external-validator block-production is evidenced. NXRL is not buyable and has no monetary value. No token sale is announced or implied. Product live-funds flags remain false by default.

## Approval Note

Final genesis (SHA256 `4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095`) may be distributed to validators via the published raw GitHub links. The controlled testnet is **not declared live** until coordinator + NodeSync `nexaraild` services are running against the same SHA, blocks are producing, and the validator set is observed in `/net_info`. Mainnet remains **NO-GO**.

## Sign-off Fields

| Field | Value |
|---|---|
| Final genesis SHA256 | `4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095` |
| Binary / source tag | `v0.1.0-rc1-cli-hotfix` (build commit `3d0d434`) |
| Persistent peers | `2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656` (coordinator peers appended at coordinator startup) |
| Validator count | 6 (NodeSync + 5 coordinator-operated) |
| NodeSync status | gentx accepted; remote `nexaraild` start scheduled for the launch window — coordinator must verify `/net_info` peer + signing |
| Coordinator validators status | starting against final genesis under `run-controlled-testnet-dry-run.sh` with `--keep-running` |
| P2P handshake status | DEFERRED — verified against NodeSync only after NodeSync starts the real service |
| Live funds flags false | PASS — freeze gate `live-flags-check.json` reports `ALL_FALSE` |
| Denom audit | PASS (Phase 17E.1 — `coordination/audits/phase17e1-denom-audit.json`) |
| Rollback plan acknowledged | PASS — `docs/testnet/CONTROLLED_TESTNET_INCIDENT_RESPONSE.md` |
| Launch time UTC | `2026-05-30T12:03:32Z` (coordinator rolling start) |
| Coordinator approval | APPROVED — Bradley Johnston (rolling start authorised) |
| NodeSync acknowledgement | PENDING — to be recorded once NodeSync starts the real service and a peer handshake is observed |
| Genesis publication | APPROVED — final artifacts in `releases/testnet-genesis/nexarail-testnet-1/` may be distributed to validators |
| Network launch | PENDING — controlled testnet remains NOT LIVE until coordinator + NodeSync `nexaraild` is running and `/net_info` confirms validator set |
| Final decision | APPROVED for genesis publication and validator distribution; rolling launch decision recorded separately once handshake evidence exists |

## How To Approve

1. Run the freeze gate against the final candidate, supplying a real coordinator probe RPC and requiring both P2P and signoff:
   ```bash
   scripts/testnet/check-final-genesis-freeze-gate.sh \
     --genesis releases/testnet-genesis/nexarail-testnet-1-candidate/genesis.json \
     --expected-sha256 4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095 \
     --peer 2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656 \
     --probe-rpc http://127.0.0.1:26657 \
     --require-p2p \
     --require-signoff
   ```
2. Confirm the freeze gate prints `Decision: FREEZE_GO` once the signoff line below is set to `APPROVED`.
3. Update the Sign-off Fields table with the actual final values.
4. Replace the `**Status:**` value above with `APPROVED` and add the sign-off block below.

## Sign-off Block

```text
Coordinator: Bradley Johnston
NodeSync:    PENDING (acknowledgement to be recorded after NodeSync handshake)
Date UTC:    2026-05-30T12:03:32Z
Genesis:     4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095
Decision:    APPROVED (rolling controlled start; external-decentralisation deferred until external-validator block-signing observed)
```

## Hard-Stop Reasons

Replace `**Status:**` with `BLOCKED` if any of these hold:

- final genesis SHA256 does not match the freeze gate `--expected-sha256` argument;
- denom audit returns `FAIL`;
- any product live-funds flag is `true` in the candidate genesis;
- secret material (private keys, mnemonics, `node_key.json`, `priv_validator_key.json`) is found in the candidate release artifacts;
- NodeSync is missing from the genesis validator set;
- final public genesis folder is already populated (would indicate accidental publish).
