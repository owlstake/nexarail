# Controlled Testnet Launch Sign-off

**Network:** `nexarail-testnet-1`
**Document:** `docs/testnet/CONTROLLED_TESTNET_LAUNCH_SIGNOFF.md`
**Status:** PENDING

This document is the single sign-off record for the controlled external-validator testnet launch. The freeze gate script (`scripts/testnet/check-final-genesis-freeze-gate.sh`) reads the `**Status:**` line above; `APPROVED` advances the gate, `PENDING` defers it, and `BLOCKED` blocks it.

The controlled external-validator testnet is **NOT LAUNCHED**. Mainnet is **NO-GO**. External decentralisation is not claimed. NXRL is not buyable and has no monetary value. No token sale is announced or implied. Product live-funds flags remain false by default.

## Sign-off Fields

| Field | Value |
|---|---|
| Final genesis SHA256 | TBD (current candidate: `4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095`) |
| Binary / source tag | `v0.1.0-rc1-cli-hotfix` (or later reviewed source tag) |
| Persistent peers | `2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656` (plus coordinator peers at launch) |
| Validator count | 6 (NodeSync + 5 coordinator-operated) |
| NodeSync status | gentx accepted; service start scheduled for launch window |
| Coordinator validators status | rehearsed; standby until launch window |
| P2P handshake status | PENDING — verified via coordinator `/net_info` peer count > 0 against NodeSync |
| Live funds flags false | PENDING — confirmed via freeze gate `live-flags-check.json` |
| Denom audit | PASS (Phase 17E.1 — `coordination/audits/phase17e1-denom-audit.json`) |
| Rollback plan acknowledged | PENDING — `docs/testnet/CONTROLLED_TESTNET_INCIDENT_RESPONSE.md` |
| Launch time UTC | TBD |
| Coordinator approval | PENDING |
| NodeSync acknowledgement | PENDING |
| Final decision | PENDING |

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
Coordinator: <name>
NodeSync:    <name>
Date UTC:    <yyyy-mm-ddThh:mm:ssZ>
Genesis:     <sha256>
Decision:    PENDING
```

## Hard-Stop Reasons

Replace `**Status:**` with `BLOCKED` if any of these hold:

- final genesis SHA256 does not match the freeze gate `--expected-sha256` argument;
- denom audit returns `FAIL`;
- any product live-funds flag is `true` in the candidate genesis;
- secret material (private keys, mnemonics, `node_key.json`, `priv_validator_key.json`) is found in the candidate release artifacts;
- NodeSync is missing from the genesis validator set;
- final public genesis folder is already populated (would indicate accidental publish).
