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

- NodeSync P2P TCP `26656` is not reachable from the coordinator side.
- NodeSync RPC/API/gRPC endpoints remain pending.
- Final public genesis freeze decision remains `FREEZE_DEFER`.

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

Ask NodeSync to open/listen on TCP `26656`, recheck reachability, then re-run the final genesis freeze gate. Do not publish final public genesis or claim a public launch until launch criteria and evidence exist.
