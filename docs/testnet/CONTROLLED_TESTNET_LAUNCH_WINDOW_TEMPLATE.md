# Controlled Testnet Launch Window Template

**Network:** `nexarail-testnet-1`
**Status:** template only; launch time pending

## Launch Window

| Field | Value |
|---|---|
| Planned date/time UTC | TBD |
| Coordinator | TBD |
| Communication channel | TBD |
| Binary/tag | `v0.1.0-rc1-cli-hotfix` or later reviewed source tag |
| Genesis hash | TBD |
| Persistent peers | TBD |
| Seed nodes | TBD |
| Final genesis freeze decision | `FREEZE_DEFER` until verified external gentxs exist |

## Freeze Gate Before Scheduling

- [ ] Accepted external validator count is greater than zero.
- [ ] Verified gentx count matches accepted validator count.
- [ ] Endpoint inventory is complete enough for launch monitoring.
- [ ] Persistent peers generated from accepted records.
- [ ] Final public genesis candidate assembled and validated.
- [ ] Genesis checksum independently verified.
- [ ] Product live flags remain false.
- [ ] No secret material in launch artifacts.
- [ ] Support channel and coordinator contact path confirmed.

## First-Block Checklist

- [ ] Final genesis checksum matches published `SHA256SUMS`.
- [ ] All participating validators confirm configured chain ID `nexarail-testnet-1`.
- [ ] All participating validators start from the final genesis.
- [ ] First block is produced.
- [ ] RPC `/status` reports expected chain ID.
- [ ] Validator set count matches final manifest.
- [ ] Product live flags remain false.

## First-100-Block Checklist

- [ ] Height reaches 100.
- [ ] Blocks continue progressing.
- [ ] `catching_up` is false for expected endpoints.
- [ ] Peer count is non-zero and stable enough for launch conditions.
- [ ] Validator set count remains expected.
- [ ] No unexpected validator-set divergence is reported.
- [ ] REST/API health checks pass where endpoints are provided.

## First-Hour Checklist

- [ ] Blocks continue progressing through the first hour.
- [ ] No halt is observed.
- [ ] No panic or fatal health note is reported by operators.
- [ ] Product live flags remain false.
- [ ] Coordinator records status, validators, peers, and live-flag evidence.
- [ ] Public status update is published only after evidence exists.

## Rollback Criteria

- No blocks are produced after launch-window start.
- Final genesis checksum mismatch.
- Validator set differs from final manifest.
- Any product live flag is unexpectedly true.
- Persistent peer or seed configuration prevents consensus.
- Validator secret exposure is reported.
- Coordinator cannot contact enough validators to maintain launch safety.
- Material runtime panic or fatal error blocks launch.

## Communication Placeholder

Use the launch coordination channel confirmed by the coordinator before T-15m. Do not publish final genesis, peer strings, or launch status outside the approved channel until the coordinator marks the launch-window artifact final.
