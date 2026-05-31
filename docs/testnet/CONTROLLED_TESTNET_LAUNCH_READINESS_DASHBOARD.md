# Controlled Testnet Launch Readiness Dashboard

**Network:** `nexarail-testnet-1`
**Last updated:** 2026-05-31
**Launch status:** PENDING / NOT LIVE — final controlled-testnet genesis PUBLISHED; coordinator-operated nodes rehearsing locally only; external-validator block-signing pending

| Area | Status | Notes |
|---|---|---|
| Intake status | PARTIAL | NodeSync accepted; additional validators pending |
| Gentx status | PARTIAL | Accepted: 1; rejected: 0 |
| Genesis status | PUBLISHED | `releases/testnet-genesis/nexarail-testnet-1/` sha256 `4ced9f71...` (Phase 17I.0) |
| Peers status | READY | NodeSync DNS peer in published `persistent-peers.txt`; coordinator local peers appended at startup |
| Endpoint status | PARTIAL | NodeSync P2P DNS endpoint confirmed; RPC/API/gRPC pending |
| Launch window status | DEFERRED | Network launch pending external-validator handshake evidence |
| Monitor script status | RUNNING locally | `rehearsals/controlled-testnet/launch-hour/evidence/20260530T121242Z/samples.tsv` (coordinator-only rehearsal) |
| Launch-hour evidence status | LOCAL REHEARSAL ONLY | 60-min sampler against coordinator quorum; not public launch evidence |
| Rollback readiness | READY | Rollback criteria documented |
| Incident response readiness | READY | `docs/testnet/CONTROLLED_TESTNET_INCIDENT_RESPONSE.md` |
| Support readiness | READY | `docs/testnet/VALIDATOR_SUPPORT_TRIAGE_TEMPLATE.md` |
| Safety status | READY | Mainnet NO-GO; no token sale; no monetary value; live flags false; external decentralisation not claimed |

## Current Blockers

- NodeSync real `nexaraild` start is pending; coordinator launch packet sent at `coordination/outreach/2026-05-30-nodesync-launch-window.md`.
- External-validator block-signing evidence is required before the controlled external-validator testnet can be marked `LIVE` and the external-decentralisation claim becomes eligible for review.

## Phase 17H Freeze Gate

Authoritative checker: `scripts/testnet/check-final-genesis-freeze-gate.sh`.

Pre-publish run (2026-05-30T12:03:32Z): `PASS=12 FAIL=0 DEFER=1` — only DEFER is live CometBFT handshake (can only be probed once NodeSync starts). Coordinator advanced to `FREEZE_GO` for the **rolling controlled start** at the same timestamp.

After publish, the same static gate against the candidate path reports `FREEZE_BLOCKED` because `releases/testnet-genesis/nexarail-testnet-1/` is now populated. This is expected after rolling start and is not a regression.

Evidence: `rehearsals/controlled-testnet/freeze-gate/evidence/20260530T120332Z/`, `rehearsals/controlled-testnet/freeze-gate/evidence/20260530T121059Z/` (post-publish snapshot).

## Phase 17F Rehearsal Status

- candidate genesis: `releases/testnet-genesis/nexarail-testnet-1-candidate/genesis.json`;
- candidate SHA256: `4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095`;
- dry-run result: pass to height 50 with validator set count 6;
- local coordinator signers: 5;
- NodeSync: included in validator set, not locally simulated;
- launch-hour evidence: `rehearsals/controlled-testnet/launch-hour/evidence/20260530T013213Z/` returned `FAIL` when validator count drifted from 6 to 5 after NodeSync was not locally signing;
- readiness monitor: pass during the local monitor window with validator count 6, peer count 4, block progression, and live flags false;
- freeze decision: `FREEZE_DEFER`.

## Next Coordinator Action

1. Wait for NodeSync to start the real `nexaraild` service against the final genesis (packet sent at `coordination/outreach/2026-05-30-nodesync-launch-window.md`).
2. Verify NodeSync `node_id` appears in coordinator `/net_info` peer list and that the height continues to advance.
3. Confirm NodeSync precommits (or at minimum is present and connected) and that product live flags remain false.
4. Update `docs/testnet/CONTROLLED_TESTNET_STATUS.md` to mark the controlled external-validator testnet `LIVE` once external-validator block-signing is evidenced.
5. Mainnet remains `NO-GO`. NXRL has no monetary value. No token sale is announced or implied. External decentralisation is not claimed until external-validator block-signing evidence is collected.
