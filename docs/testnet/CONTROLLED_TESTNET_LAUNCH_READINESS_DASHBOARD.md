# Controlled Testnet Launch Readiness Dashboard

**Network:** `nexarail-testnet-1`
**Last updated:** 2026-05-29
**Launch status:** NOT LAUNCHED

| Area | Status | Notes |
|---|---|---|
| Intake status | PARTIAL | NodeSync accepted; additional validators pending |
| Gentx status | PARTIAL | Accepted: 1; rejected: 0 |
| Genesis status | DEFERRED | Final public genesis not frozen or assembled |
| Peers status | PARTIAL | NodeSync peer generated; DNS/IP host confirmation pending |
| Endpoint status | PARTIAL | NodeSync P2P-only metadata received; DNS/IP confirmation pending; RPC/API/gRPC pending |
| Launch window status | PENDING | No UTC launch time set |
| Monitor script status | READY | `scripts/testnet/monitor-controlled-testnet-readiness.sh` exists and handles empty inventory |
| Launch-hour evidence status | READY | `scripts/testnet/collect-launch-hour-evidence.sh` exists and handles empty inventory |
| Rollback readiness | READY | Rollback criteria documented |
| Incident response readiness | READY | `docs/testnet/CONTROLLED_TESTNET_INCIDENT_RESPONSE.md` |
| Support readiness | READY | `docs/testnet/VALIDATOR_SUPPORT_TRIAGE_TEMPLATE.md` |
| Safety status | READY | Mainnet NO-GO; no token sale; no monetary value; live flags false |

## Current Blockers

- NodeSync DNS/IP peer host confirmation pending.
- NodeSync RPC/API/gRPC endpoints remain pending.
- Final public genesis freeze decision remains `FREEZE_DEFER`.

## Next Coordinator Action

Confirm NodeSync final peer host, continue validator-facing intake using `docs/testnet/VALIDATOR_INTAKE_MESSAGE_PACK.md`, and do not publish final public genesis or claim a public launch until launch criteria and evidence exist.
