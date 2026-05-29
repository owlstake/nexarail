# Phase 17A Controlled Testnet Launch Plan

**Date:** 2026-05-29
**Status:** launch candidate preparation
**Network:** `nexarail-testnet-1`
**Build source:** `v0.1.0-rc1-cli-hotfix` or later verified commit

## Objective

Prepare a controlled external-validator testnet launch candidate using source-built binaries, verified validator intake, collected gentxs, a final genesis, persistent peers, and explicit launch-window coordination.

This phase prepares the launch package and rehearsal evidence. It does not declare a live public network until accepted external validators are running from the final genesis and the coordinator has verified block production.

## Safety Boundary

- This is testnet infrastructure only.
- This is not mainnet.
- NXRL is not offered for sale.
- Testnet denominations have no monetary value.
- No product live-funds flags are enabled by default.
- External decentralisation is not claimed until accepted external validators are running and evidenced.

## Chain ID

`nexarail-testnet-1`

## Validator Requirements

- Linux host, preferably Ubuntu 22.04 LTS or 24.04 LTS.
- Static public IP or stable DNS.
- Open P2P port, default `26656`.
- Go toolchain compatible with the repository build.
- `git`, `make`, `curl`, `jq`, `python3`, and standard build tools.
- NTP/time sync enabled.
- Secure key custody and responsive operator contact during the launch window.

## Build Source

Primary path is source-build only until prebuilt release assets are uploaded with verified permissions:

```bash
git clone https://github.com/Bookings-cpu/nexarail.git
cd nexarail
git checkout v0.1.0-rc1-cli-hotfix
make build
./build/nexaraild version
```

Validators must report the exact build tag or commit in their intake record.

## Gentx Collection

1. Accepted validators initialise a fresh home for `nexarail-testnet-1`.
2. Validators create or recover their validator account locally.
3. Validators record node ID, consensus pubkey, account address, operator address, host, P2P port, OS, architecture, and build tag or commit.
4. Validators generate a gentx only after the coordinator confirms the genesis-account funding amount and chain ID.
5. Validators submit only the `gentx-*.json` file and intake template.
6. Coordinator verifies every gentx with `scripts/testnet/verify-controlled-testnet-gentx.sh`.
7. Rejected gentxs are returned with the exact failed check and must be regenerated before the gentx freeze.

Validators must never submit mnemonics, account keys, node keys, validator signing keys, keyrings, SSH keys, or node data directories.

## Final Genesis Assembly

The coordinator assembles the candidate genesis with:

```bash
scripts/testnet/assemble-controlled-testnet-genesis.sh \
  --gentx-dir <verified-gentx-dir> \
  --output-dir releases/testnet-genesis/nexarail-testnet-1
```

The script:

- starts from a clean base genesis;
- sets `chain_id` to `nexarail-testnet-1`;
- funds gentx delegator accounts for testnet operation;
- keeps all product live flags false;
- sets testnet governance parameters;
- collects verified gentxs;
- runs `validate-genesis`;
- writes `genesis.json`, `SHA256SUMS`, and `manifest.json`.

The coordinator publishes the genesis SHA256 before the launch window.

## Seeds And Persistent Peers

The coordinator collects node IDs and host details from validator intake records and generates peer configuration with:

```bash
scripts/testnet/generate-persistent-peers.sh \
  --input <validator-intake.csv-or-json> \
  --output-dir releases/testnet-genesis/nexarail-testnet-1/peers
```

If a seed or bootnode is available, it is published separately. Persistent peers remain the required baseline for the first launch window.

## Launch Timeline

| Stage | Owner | Gate |
|---|---|---|
| T-7d to T-3d | Coordinator | Accept validators and open intake |
| T-3d to T-1d | Validators | Submit intake and gentx |
| T-24h | Coordinator | Verify gentxs and freeze validator set |
| T-12h | Coordinator | Publish genesis candidate, checksum, and peer list |
| T-2h | Validators | Confirm checksum, peer config, and readiness |
| T-0 | Validators | Start nodes from final genesis |
| T+10 blocks | Coordinator | Confirm block production and validator set |
| T+100 blocks | Coordinator | Confirm peers, signing, and no unexpected halts |
| T+1h | Coordinator | Publish launch-candidate status update |

The timeline can be compressed only if every accepted validator confirms readiness and the coordinator documents the reason.

## Coordinator Responsibilities

- Maintain accepted-validator registry.
- Collect and validate intake records.
- Verify gentxs and reject unsafe or malformed submissions.
- Assemble final genesis.
- Publish genesis checksum and persistent peers.
- Confirm every validator has verified the final checksum.
- Monitor first 10 blocks, first 100 blocks, and first hour.
- Maintain halt/rollback authority for the controlled launch window.
- Keep status wording accurate: preparing until launch evidence exists.

## Validator Responsibilities

- Build from the approved tag or commit.
- Keep local keys and node data private.
- Submit intake and gentx by the deadline.
- Verify genesis checksum before launch.
- Configure persistent peers.
- Open P2P port and restrict RPC/API exposure unless explicitly coordinated.
- Be present during launch and report status promptly.
- Share sanitised logs only.

## Rollback Plan

Rollback conditions:

- fewer than the accepted threshold of validators start from the final genesis;
- chain halt or no block production after the launch window begins;
- final genesis checksum mismatch across validators;
- wrong chain ID, wrong validator set, or unexpected live flag value;
- validator key compromise or accidental secret disclosure;
- material gentx or peer-list error.

Rollback actions:

1. Coordinator calls halt in the support channel.
2. Validators stop `nexaraild`.
3. Validators preserve logs and do not delete data until evidence is collected.
4. Coordinator records the failed genesis checksum and failed height.
5. Coordinator prepares a corrected genesis candidate or reopens gentx collection.
6. Relaunch requires a new checksum and launch-window confirmation.

## Launch Candidate Status

Phase 17A status is **preparing** until external validators are running from the published final genesis and the first launch evidence is recorded.

## Local Dry-Run Result

The controlled-testnet launch tooling passed a local five-validator dry-run on 2026-05-29:

- five gentxs verified;
- final rehearsal genesis assembled and validated;
- persistent peers generated;
- five local validators started;
- height 20 reached;
- validator set count was 5;
- product live flags remained false;
- `tendermint show-node-id` and `comet show-node-id` passed.

Dry-run results are recorded in `docs/testnet/PHASE_17A_CONTROLLED_TESTNET_DRY_RUN_RESULTS.md`. This is rehearsal evidence only; the public controlled testnet remains not launched.

## Phase 17B Handoff

Phase 17B moves this plan into real intake coordination:

- registry: `coordination/validators/validator-intake.csv`;
- pending gentxs: `coordination/validators/gentxs/`;
- verified gentxs: `coordination/validators/verified/`;
- rejected gentxs: `coordination/validators/rejected/`;
- peer output: `coordination/validators/peer-info/`;
- status doc: `docs/testnet/PHASE_17B_VALIDATOR_INTAKE_AND_GENESIS_CANDIDATE.md`.

Final genesis remains pending until verified external gentxs exist.
