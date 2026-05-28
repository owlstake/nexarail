# Phase 9B — Autonomous Validator Agents

**Date:** 2026-05-26
**Chain:** nexarail-agent-testnet-1
**Status:** Active

---

## Purpose

Create and operate an independent cohort of autonomous validator agents for the NexaRail testnet. These agents function as separate validators — each with its own identity, keys, ports, and duties — enabling the network to operate without waiting for external human validators.

## Agent Validator Model

Each agent is a separate `nexaraild` process with:
- Unique home directory
- Unique keyring (test backend)
- Unique validator key (priv_validator_key.json)
- Unique node key (node_key.json)
- Unique set of ports (RPC, P2P, API, gRPC)
- Unique moniker
- Unique gentx

All agents run on the same machine with `allow_duplicate_ip = true` and `addr_book_strict = false` — standard for local multi-validator testnets.

## Validator Agent Count

| Tier | Count | Names |
|---|---|---|
| Minimum | 3 | alpha, bravo, charlie |
| Preferred | 5 | alpha, bravo, charlie, delta, echo |

## Chain Configuration

| Parameter | Value |
|---|---|
| Chain ID | `nexarail-agent-testnet-1` |
| Denom | `unxrl` |
| Ticker | `NXRL` |
| Bech32 Prefix | `nxr` |
| Voting Period | 30s (agent testnet — accelerated) |
| Bond Denom | `unxrl` |
| Minimum Gas Price | `0unxrl` |

## Operating Assumptions

- All agents run on the same Linux machine (or macOS for testing)
- Ports are non-conflicting and unique per agent
- Test keyring backend used (no real security required)
- Chain may be reset at any time
- Live funds disabled by default
- This is NOT a mainnet — no real value

## Agent Responsibilities

| Agent | Role | Primary Duty |
|---|---|---|
| alpha | Genesis coordinator | Config verification, genesis validation, launch confirmation |
| bravo | Network monitor | Peer connectivity, block height, uptime monitoring |
| charlie | Governance | Proposal submission, voting, parameter verification |
| delta | API/CLI | REST/gRPC/CLI smoke testing |
| echo | Recovery | Halt recovery, restart testing, incident reporting |

## Launch Process

1. Build `nexaraild`
2. Run `spawn-validator-agents.sh` — creates homes, keys, gentxs, genesis, starts all agents
3. Wait for block height > 20
4. Run `query-validator-agents.sh` — verify all agents healthy
5. Run `validator-agent-governance-test.sh` — test governance lifecycle
6. Collect evidence
7. Stop agents with `stop-validator-agents.sh`

## Reporting Process

Each agent reports:
- Status via RPC query
- Peer connectivity via net_info
- Block height via status endpoint
- Module params via REST/gRPC

Aggregated in `VALIDATOR_AGENT_REHEARSAL_RESULTS.md` and `rehearsals/validator-agents/evidence/`.

## Success Criteria

- [ ] ≥ 3 agent validators start and produce blocks
- [ ] Block height > 20
- [ ] All agents in validator set
- [ ] Peer connectivity: each agent has ≥ N-1 peers
- [ ] All 6 live flags confirmed false
- [ ] Governance proposal passes (enable → verify → disable → verify)
- [ ] All module params queryable
- [ ] Evidence collected

## Failure Criteria

- Fewer than 3 agents operational
- Block production halts
- Governance proposal fails to pass
- Live flags not all false at start
- ⚠️ macOS Docker instability may apply — document if encountered
