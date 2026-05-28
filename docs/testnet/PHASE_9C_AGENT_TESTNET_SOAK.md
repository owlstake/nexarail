# Phase 9C — Agent Testnet Soak

**Date:** 2026-05-26
**Chain:** nexarail-agent-testnet-1

---

## Purpose

Run an extended multi-validator soak test using the 5 autonomous validator agents. Verify stability beyond a short launch rehearsal — blocks must continue for the full duration without halt, crashes, or live flag changes.

## Current Phase 9B Results

| Metric | Value |
|---|---|
| Chain ID | nexarail-agent-testnet-1 |
| Validator agent count | 5 |
| gen_txs | 5 |
| Short rehearsal height | 18+ |
| All live flags false | ✅ |
| 4/5 agents produced blocks | ✅ (alpha RPC had port conflict) |

## Soak Parameters

| Parameter | Value |
|---|---|
| Target duration | 60 minutes (minimum 10 minutes if constrained) |
| Status collection interval | 60 seconds |
| Minimum block height delta | > 0 (blocks must advance) |
| Max peer count drop | 0 (no agent should lose all peers) |
| Live flags check frequency | Every 5 minutes |
| Evidence path | `rehearsals/validator-agents/soak/<timestamp>/` |

## Metrics to Collect

| Metric | Method |
|---|---|
| Block height per agent | `curl /status` each interval |
| Peer count per agent | `curl /net_info` each interval |
| Validator set | `curl /validators` each interval |
| Live flags state | Genesis inspection |
| Module params | REST/gRPC if available |
| Agent process status | PID check per interval |
| Panics/errors | Log scanning |

## Success Criteria

- [ ] All 5 agents remain running for full duration
- [ ] Block height increases steadily (~5-6s per block expected)
- [ ] No agent drops below 4 peers
- [ ] Validator set remains at 5
- [ ] All 6 live flags remain false
- [ ] No panics in any agent log
- [ ] Height delta > 0 (blocks were produced throughout)

## Failure Criteria

- Block production halts
- Any agent crashes without recovery
- Peer count drops to 0 for any agent
- Live flag unexpectedly changes
- Panic detected in logs

## Limitations

- All agents run on a single machine — not representative of distributed validator topology
- Alpha RPC port may conflict with SSH tunnels on macOS
- REST API not yet functional on agent testnet (app.toml fix needed)
- macOS Docker instability does not apply (native processes)
- This is an internal test — does not represent external decentralisation

## External Decentralisation Disclaimer

These 5 validator agents run on a single machine under a single operator. They do not represent network decentralisation. External decentralisation requires validators operated by independent parties on separate infrastructure. This soak test validates the consensus and runtime stability of the chain, not decentralisation.
