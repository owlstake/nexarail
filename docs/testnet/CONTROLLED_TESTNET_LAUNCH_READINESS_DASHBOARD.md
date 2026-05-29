# Controlled Testnet Launch Readiness Dashboard

**Network:** `nexarail-testnet-1`
**Last updated:** 2026-05-29
**Launch status:** NOT LAUNCHED

| Area | Status | Notes |
|---|---|---|
| Intake status | WAITING | Validator submissions: 0 |
| Gentx status | WAITING | Accepted: 0; rejected: 0 |
| Genesis status | DEFERRED | Final public genesis not frozen or assembled |
| Peers status | WAITING | Persistent peers require complete external records |
| Endpoint status | WAITING | Endpoint inventory is header-only |
| Launch window status | PENDING | No UTC launch time set |
| Monitor script status | READY | `scripts/testnet/monitor-controlled-testnet-readiness.sh` exists and handles empty inventory |
| Launch-hour evidence status | READY | `scripts/testnet/collect-launch-hour-evidence.sh` exists and handles empty inventory |
| Rollback readiness | READY | Rollback criteria documented |
| Incident response readiness | READY | `docs/testnet/CONTROLLED_TESTNET_INCIDENT_RESPONSE.md` |
| Support readiness | READY | `docs/testnet/VALIDATOR_SUPPORT_TRIAGE_TEMPLATE.md` |
| Safety status | READY | Mainnet NO-GO; no token sale; no monetary value; live flags false |

## Current Blockers

- No external validator records received.
- No external gentxs received.
- No endpoint inventory records received.
- Persistent peers cannot be generated.
- Final public genesis freeze decision remains `FREEZE_DEFER`.

## Next Coordinator Action

Continue validator-facing intake using `docs/testnet/VALIDATOR_INTAKE_MESSAGE_PACK.md`. Do not publish final public genesis or claim a public launch until verified external validators are ready and evidence exists.
