# Multi-Machine Evidence Checklist

**Date:** 2026-05-27  
**Scope:** evidence required from external/multi-machine NexaRail rehearsal

## Coordinator Evidence

| Evidence | Required | Status | Path / notes |
|---|---|---|---|
| Rehearsal start time | Yes | ☐ | |
| Release tag or commit | Yes | ☐ | |
| Binary checksum | Yes | ☐ | |
| Genesis file | Yes | ☐ | |
| Genesis checksum | Yes | ☐ | |
| Validator roster | Yes | ☐ | |
| Persistent peer list | Yes | ☐ | |
| Launch timeline | Yes | ☐ | |
| Final summary | Yes | ☐ | |

## Per-Node Evidence

Collect from every validator:

| Evidence | Required | Status | Path / notes |
|---|---|---|---|
| System info | Yes | ☐ | `uname`, OS release, CPU/RAM/disk |
| Time sync status | Yes | ☐ | `timedatectl status` |
| Binary version | Yes | ☐ | `nexaraild version` |
| Node ID | Yes | ☐ | `nexaraild tendermint show-node-id` |
| Validator pubkey | Yes | ☐ | `nexaraild tendermint show-validator` |
| Node status | Yes | ☐ | `/status` |
| Validator set | Yes | ☐ | `/validators` |
| Peer count | Yes | ☐ | `/net_info` |
| Block height | Yes | ☐ | latest height at sample time |
| Logs | Yes | ☐ | service logs or node stdout |

## Runtime Evidence

| Evidence | Required | Success criteria |
|---|---|---|
| Block production after 30m | Yes | Height advances continuously for 30 minutes |
| Query/readback | Yes | Status, validators, bank balances, module params, and live flags readable |
| Bank tx | Yes | Testnet-only bank send included with code `0` |
| Governance proposal/vote | Preferred | Proposal submitted, votes included, final state read back |
| Restart one validator | Yes | Restarted validator catches up; network continues |
| Restart all validators | Yes | Chain resumes block production |
| Final live flags false | Yes | All six live flags read as `false` |
| Panic scan | Yes | No unhandled consensus panics |

## Query / Readback Set

Required:

- `/status`;
- `/net_info`;
- `/validators`;
- bank balances for at least one funded address;
- fees params;
- merchant params;
- settlement params;
- escrow params;
- payout params;
- treasury params;
- final live flags.

Final live flags must read:

```text
settlement.live_enabled=false
settlement.treasury_routing_enabled=false
settlement.burn_routing_enabled=false
escrow.live_enabled=false
payout.live_enabled=false
treasury.live_enabled=false
```

## Restart Evidence

One-validator restart:

- [ ] record pre-stop height;
- [ ] stop one validator only;
- [ ] verify other validators continue producing blocks;
- [ ] restart stopped validator;
- [ ] verify it catches up;
- [ ] collect logs and status.

All-validator restart:

- [ ] record pre-stop height;
- [ ] stop all validators cleanly;
- [ ] restart all validators;
- [ ] verify block production resumes above pre-stop height;
- [ ] run query/readback;
- [ ] scan logs for panics.

## Success Decision

The rehearsal passes only if:

- at least 3 external/multi-machine validators complete the run;
- block production continues after 30 minutes;
- query/readback succeeds;
- bank tx inclusion succeeds;
- restart tests pass;
- final live flags remain false;
- evidence is complete enough for audit and launch review.

The rehearsal fails if:

- fewer than 3 validators can participate;
- chain cannot produce blocks;
- validators cannot connect to peers;
- genesis checksums diverge;
- live flags are enabled by default;
- restart recovery fails;
- logs show unhandled consensus panics.
