# Phase 9X - External Validator Activation

**Date:** 2026-05-27  
**Scope:** external validator cohort activation and multi-machine/Linux rehearsal preparation  
**Status:** preparation complete; external cohort and rehearsal still pending

## Current Technical GO Status

Phase 9W established technical GO for the local agent-testnet runtime path:

- 5 local agent validators produced blocks.
- Clean-spawn query/readback passed.
- Runtime bank transaction inclusion passed.
- Governance proposal/vote lifecycle passed with final state readback.
- 60-minute soak passed.
- Persistence-safe restart matrix passed.
- Final live flags remained `false`.

This is a local agent-testnet technical GO only.

## External Launch NO-GO Status

Public/external testnet launch remains NO-GO until the following are complete:

- external validator cohort accepted;
- Linux or production-like multi-machine rehearsal completed;
- external gentxs collected and validated;
- final genesis candidate assembled;
- release tag and checksums published;
- validator communication channel active;
- public RPC/API endpoint plan approved.

Mainnet remains NO-GO.

## Why External Validators Are Still Required

Local agent validators prove engineering runtime behaviour under controlled local conditions. They do not prove:

- external operator readiness;
- external operator infrastructure operations;
- multi-machine networking;
- public IP and firewall setup;
- clock synchronisation across hosts;
- external gentx submission quality;
- coordinator launch process under real validator participation;
- external validator participation or external decentralisation.

External validators are required before any public/external testnet launch because they are the first proof that the network can operate outside the local development environment.

## Target Cohort Size

| Cohort | Size | Purpose |
|---|---:|---|
| Minimum launch cohort | 3 validators | Smallest useful public/external testnet rehearsal |
| Preferred cohort | 5 validators | Better fault-tolerance and peer-network coverage |
| Strong cohort | 7 validators | Stronger operational diversity and rehearsal depth |

The Phase 9X activation target is 5 accepted validators, with a minimum of 3.

## Acceptance Criteria

Validators should be accepted only if they meet these criteria:

- Linux host available, preferably Ubuntu 22.04 LTS or 24.04 LTS.
- 4+ vCPU, 8+ GB RAM, 100+ GB SSD minimum for the rehearsal.
- Static public IP or stable DNS.
- Port `26656` open for P2P.
- RPC/API exposure agreed with coordinator; public RPC is optional and should be rate-limited if enabled.
- NTP/time synchronisation enabled.
- Can build `nexaraild` from source or verify a release binary.
- Can generate and safeguard validator keys.
- Can create and submit a valid gentx.
- Understands this is testnet-only: no mainnet, no token sale, no monetary value, no investment framing.
- Responds to coordinator messages within the rehearsal window.

## Required Operator Acknowledgements

Each accepted validator should acknowledge:

- they will not share private keys, node keys, validator keys, or mnemonics;
- they will not run duplicate validators with the same `priv_validator_key.json`;
- they understand testnet state can be reset;
- they understand all live fund flags default to `false`;
- they understand participation does not imply any future allocation, payment, return, listing, or mainnet role;
- they will provide node ID, validator pubkey, operator address, moniker, IP/host, and support contact to the coordinator.

## Next Operational Gates

| Gate | Status | Exit criteria |
|---|---|---|
| Validator shortlist | Pending | Candidate targets tracked with priority and next action |
| Validator acceptance | Pending | At least 3 accepted validators |
| Communication channel | Pending | All accepted validators present and acknowledged |
| Linux/multi-machine rehearsal | Pending | 3+ machines produce blocks and pass evidence checklist |
| External gentx collection | Pending | All accepted gentxs validate and are indexed |
| Final genesis candidate | Pending | Genesis assembled, live flags false, checksum recorded |
| Release candidate freeze | Pending | Tag, binary checksum, genesis checksum, and validator instructions published |
| Public/external launch review | Pending | Updated go/no-go review after gentx and rehearsal evidence |

## GO / NO-GO

| Area | Decision |
|---|---|
| Local agent-testnet runtime readiness | GO |
| External validator cohort activation | Pending |
| Multi-machine/Linux rehearsal | Pending |
| Public/external testnet launch | NO-GO |
| Mainnet | NO-GO |

## Phase 9X Completion Boundary

Phase 9X prepares the activation path. It does not complete external validator onboarding, does not collect live external gentxs, does not launch public endpoints, and does not launch a public/external testnet.

## Phase 9X Outputs

- `docs/testnet/MULTI_MACHINE_REHEARSAL_PLAN.md`
- `docs/testnet/EXTERNAL_VALIDATOR_ACTION_PACK.md`
- `docs/testnet/VALIDATOR_RECRUITMENT_SHORTLIST_TARGETS.md`
- `docs/testnet/EXTERNAL_GENTX_COLLECTION_READY_CHECK.md`
- `docs/testnet/MULTI_MACHINE_EVIDENCE_CHECKLIST.md`
- `scripts/testnet/prepare-multi-machine-validator.sh`
- `scripts/testnet/collect-multi-machine-evidence.sh`
