# Multi-Machine Rehearsal Plan

**Date:** 2026-05-27  
**Chain:** planned rehearsal for `nexarail-testnet-1`  
**Scope:** Linux or production-like multi-machine testnet rehearsal

## Purpose

The multi-machine rehearsal proves that NexaRail can operate beyond the local agent-testnet environment. It validates external host setup, network reachability, genesis distribution, persistent peer configuration, block production, query/readback, transaction inclusion, governance, and restart recovery.

This rehearsal is required before any public/external testnet launch GO decision.

## Linux Requirement

Validator hosts should run Linux. Preferred:

- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS

macOS remains acceptable for local development only. It should not be used as the primary proof for the external validator rehearsal.

## Machine Count

| Count | Use |
|---:|---|
| 3 machines or VPS instances | Minimum rehearsal |
| 5 machines or VPS instances | Preferred rehearsal |
| 7 machines or VPS instances | Stronger operator and network diversity |

Each machine must run one validator identity. Do not copy `priv_validator_key.json` between machines.

## Networking Assumptions

- Each validator has a static public IP or stable DNS name.
- Each validator can reach every other validator over P2P.
- Coordinator has each validator's node ID and public P2P address.
- RPC/API exposure is optional and should be restricted or rate-limited when public.
- Validators can SSH into their own hosts for logs and restart operations.

## Ports

| Port | Protocol | Purpose | Exposure |
|---:|---|---|---|
| 26656 | TCP | CometBFT P2P | Required between validators |
| 26657 | TCP | CometBFT RPC | Optional; restrict or rate-limit |
| 1317 | TCP | Cosmos REST API | Optional; restrict or rate-limit |
| 9090 | TCP | gRPC | Optional; restrict or private |
| 26660 | TCP | Prometheus metrics | Optional; private only |

## Firewall Rules

Minimum:

```text
allow tcp/26656 from accepted validator IPs
allow ssh from operator/admin IPs
deny public access to validator private keys and home directories
```

Optional controlled public endpoints:

```text
allow tcp/26657 only if RPC exposure is approved
allow tcp/1317 only if API exposure is approved
allow tcp/9090 only if gRPC exposure is approved
```

Validators should not expose `26660` publicly.

## Time Sync

All machines must run NTP or systemd-timesyncd:

```bash
timedatectl status
```

Success criteria:

- `System clock synchronized: yes`
- NTP service active
- no meaningful drift during launch window

## Genesis Distribution

Coordinator provides:

- final rehearsal genesis file;
- SHA256 checksum;
- chain ID;
- persistent peer list;
- launch time;
- release tag or commit.

Each validator must:

```bash
cp genesis.json ~/.nexarail/config/genesis.json
sha256sum ~/.nexarail/config/genesis.json
./build/nexaraild validate-genesis
```

The checksum must match the coordinator-published value.

## Persistent Peers

Coordinator creates a peer list in this format:

```text
nodeid1@ip1:26656,nodeid2@ip2:26656,nodeid3@ip3:26656
```

Each validator writes it into:

```toml
persistent_peers = "nodeid1@ip1:26656,nodeid2@ip2:26656,nodeid3@ip3:26656"
```

Validators should verify their own node ID:

```bash
./build/nexaraild tendermint show-node-id
```

If the binary returns `unknown command "tendermint"`, the build is the pre-hotfix RC1 release. Build from source tag `v0.1.0-rc1-cli-hotfix` or later. Use prebuilt hotfix binaries only after release assets and checksums are published through the verified release channel. The same group is also reachable via `comet show-node-id` or `cometbft show-node-id`.

## Seed Node Option

A seed node is optional for the rehearsal. If used:

- it should not hold validator keys;
- it should run with PEX enabled;
- it should publish a stable seed address;
- validators may use both `seeds` and `persistent_peers`.

For a 3-to-5 validator controlled rehearsal, persistent peers are sufficient.

## Rehearsal Flow

1. Accept validators and collect host metadata.
2. Build or distribute the release candidate binary.
3. Generate rehearsal genesis.
4. Distribute genesis and checksum.
5. Collect node IDs and validator pubkeys.
6. Publish persistent peer list.
7. Validators configure hosts and confirm readiness.
8. Start all validators at the scheduled launch time.
9. Observe block production for at least 30 minutes.
10. Run query/readback.
11. Submit a testnet-only bank transaction.
12. Submit and vote on one governance proposal if scheduled.
13. Restart one validator and verify catch-up.
14. Restart all validators and verify block production resumes.
15. Collect evidence from every node.

## Evidence To Collect

Each node:

- system information;
- binary version;
- git commit or release tag;
- genesis checksum;
- node ID;
- validator pubkey;
- `/status`;
- `/net_info`;
- `/validators`;
- latest block height;
- module params;
- live flags;
- node logs;
- service manager status if systemd is used;
- firewall/time-sync evidence where available.

Helper:

```bash
scripts/testnet/collect-multi-machine-evidence.sh
```

Run this on each validator host after launch, after the 30-minute block-production sample, and after restart tests.

Coordinator:

- final genesis file and checksum;
- persistent peer list;
- validator set;
- launch timeline;
- query/readback summary;
- tx hashes;
- proposal ID and vote tx hashes if governance is rehearsed;
- restart evidence;
- final live flags.

## Success Criteria

Minimum success:

- 3 Linux validators start from the same genesis.
- Chain ID is `nexarail-testnet-1` or the approved rehearsal chain ID.
- Block production continues for at least 30 minutes.
- Peer count is healthy for the cohort size.
- Validator set matches expected accepted validators.
- Query/readback passes across available nodes.
- A testnet bank tx is included with code `0`.
- One-validator restart succeeds and catches up.
- All-validator restart succeeds and block production resumes.
- Final live flags remain `false`.
- No unhandled consensus panics in logs.

Preferred success:

- 5 Linux validators complete the same checks.
- Governance proposal/vote lifecycle is rehearsed.
- Evidence package is complete and indexed.

## Failure Handling

If the rehearsal fails:

- stop public claims immediately;
- preserve logs and configs;
- classify failure as config, network, runtime, genesis, or operator issue;
- update `LAUNCH_GO_NO_GO_REVIEW.md`;
- do not proceed to public/external launch until a rerun passes.
