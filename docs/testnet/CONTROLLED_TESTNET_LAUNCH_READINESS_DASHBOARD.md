# Controlled Testnet Launch Readiness Dashboard

**Network:** `nexarail-testnet-1`
**Last updated:** 2026-05-30
**Launch status:** NOT LAUNCHED

| Area | Status | Notes |
|---|---|---|
| Intake status | PARTIAL | NodeSync accepted; additional validators pending |
| Gentx status | PARTIAL | Accepted: 1; rejected: 0 |
| Genesis status | DEFERRED | Final public genesis not frozen or assembled |
| Peers status | READY - one accepted external validator | NodeSync DNS peer generated |
| Endpoint status | PARTIAL | NodeSync P2P DNS endpoint confirmed; RPC/API/gRPC pending |
| Launch window status | PENDING | No UTC launch time set |
| Monitor script status | READY - REHEARSED | Local coordinator endpoints monitored against external candidate genesis |
| Launch-hour evidence status | REHEARSED - LOCAL LIMITATION | 600-second local evidence capture returned expected validator-count failure because NodeSync is not locally signing |
| Rollback readiness | READY | Rollback criteria documented |
| Incident response readiness | READY | `docs/testnet/CONTROLLED_TESTNET_INCIDENT_RESPONSE.md` |
| Support readiness | READY | `docs/testnet/VALIDATOR_SUPPORT_TRIAGE_TEMPLATE.md` |
| Safety status | READY | Mainnet NO-GO; no token sale; no monetary value; live flags false |

## Current Blockers

- Real CometBFT P2P handshake with NodeSync is not yet performed; NodeSync's `nc` listener on TCP `26656` is informational only (Phase 17H freeze gate records it as `INFO`, not gating).
- Coordinator launch sign-off (`docs/testnet/CONTROLLED_TESTNET_LAUNCH_SIGNOFF.md`) is `PENDING`.
- NodeSync RPC/API/gRPC endpoints remain pending.
- Final public genesis freeze decision remains `FREEZE_DEFER` per the Phase 17H gate.

## Phase 17H Freeze Gate

Authoritative checker: `scripts/testnet/check-final-genesis-freeze-gate.sh`.

Latest run (2026-05-30T09:04:22Z): `FREEZE_DEFER` — 12 pass / 0 fail / 2 defer.

Pass: candidate exists, SHA256 matches, `validate-genesis`, denom audit, live flags false, NodeSync gentx accepted, NodeSync in genesis, NodeSync persistent peer, host resolves, no secret material, final public genesis folder empty, all required docs present.

Defer: CometBFT handshake not probed yet, coordinator sign-off pending.

Evidence: `rehearsals/controlled-testnet/freeze-gate/evidence/20260530T090422Z/`.

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

1. At launch window, publish the final genesis SHA and persistent peer list to NodeSync (use `docs/testnet/NODESYNC_LAUNCH_WINDOW_INSTRUCTIONS.md`).
2. Have NodeSync start the real `nexaraild` service.
3. Spin up a coordinator probe node, then re-run the freeze gate:
   ```bash
   scripts/testnet/check-final-genesis-freeze-gate.sh \
     --genesis releases/testnet-genesis/nexarail-testnet-1-candidate/genesis.json \
     --expected-sha256 4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095 \
     --peer 2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656 \
     --probe-rpc http://127.0.0.1:26657 \
     --require-p2p --require-signoff
   ```
4. Update `docs/testnet/CONTROLLED_TESTNET_LAUNCH_SIGNOFF.md` to `APPROVED` only after the gate returns `FREEZE_GO`.
5. Only then copy the candidate to `releases/testnet-genesis/nexarail-testnet-1/` as the published final genesis.

Do not publish final public genesis or claim a public launch until the gate returns `FREEZE_GO`.
