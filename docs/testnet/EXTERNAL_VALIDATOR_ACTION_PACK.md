# External Validator Action Pack

**Date:** 2026-05-27  
**Audience:** accepted or candidate NexaRail testnet validators  
**Network:** planned controlled public/external testnet, `nexarail-testnet-1`

## What NexaRail Is

NexaRail is a Cosmos SDK + CometBFT Layer 1 under development for payment and settlement infrastructure. It includes modules for merchant registration, settlement, escrow, payout, treasury, and fee policy.

All fund-moving functionality is disabled by default behind governance-controlled live flags.

## Current Technical Status

- Local 5-agent runtime readiness is proven.
- Clean-spawn block production passed.
- Query/readback passed.
- Runtime bank transaction inclusion passed.
- Governance proposal/vote lifecycle passed with final state readback.
- 60-minute local soak passed.
- Persistence-safe restart matrix passed.
- Public/external testnet launch is not live yet.

## Critical Disclaimer

- No public mainnet is live.
- NXRL has not been offered for sale.
- There is no token sale.
- Testnet tokens have zero monetary value.
- Participation is infrastructure testing only and is not an investment.
- Agent validators do not represent external decentralisation.
- External validator onboarding remains pending until accepted validators are running.

## Validator Requirements

Minimum:

- Linux host, preferably Ubuntu 22.04 LTS or 24.04 LTS.
- 4 vCPU, 8 GB RAM, 100 GB SSD.
- Static public IP or stable DNS.
- Open P2P port `26656`.
- Go 1.22+.
- `git`, `make`, `curl`, `jq`, build tools.
- NTP/time sync enabled.
- Ability to safeguard keys and respond during launch window.

Recommended:

- 200 GB NVMe storage.
- Monitoring and alerting.
- Restricted RPC/API exposure.
- Backup operator contact.

## Build Instructions

```bash
sudo apt update
sudo apt install -y build-essential git curl jq make gcc

git clone https://github.com/Bookings-cpu/nexarail.git
cd nexarail
git checkout <release-tag-or-commit>
make build

./build/nexaraild version
go test ./...
```

If a release binary is provided, verify its checksum before use.

## Key Generation

Initialise your node:

```bash
./build/nexaraild init <your-moniker> --chain-id nexarail-testnet-1
```

Record your node ID:

```bash
./build/nexaraild tendermint show-node-id
```

Record your validator consensus pubkey:

```bash
./build/nexaraild tendermint show-validator
```

Create your validator account key:

```bash
./build/nexaraild keys add <key-name> --keyring-backend file
./build/nexaraild keys show <key-name> -a --keyring-backend file
```

Back up the mnemonic offline. Never share it with the coordinator.

## Gentx Creation

After the coordinator provides the genesis template and confirms your account funding:

```bash
./build/nexaraild gentx <key-name> 500000000unxrl \
  --chain-id nexarail-testnet-1 \
  --commission-rate 0.05 \
  --commission-max-rate 0.20 \
  --commission-max-change-rate 0.01 \
  --min-self-delegation 1 \
  --keyring-backend file
```

Verify the gentx exists:

```bash
ls ~/.nexarail/config/gentx/gentx-*.json
```

## Gentx Submission

Submit only:

```text
~/.nexarail/config/gentx/gentx-*.json
```

Never submit:

- mnemonic phrase;
- account private key;
- `priv_validator_key.json`;
- `node_key.json`;
- keyring directory;
- SSH keys.

The coordinator will validate gentxs, assemble the final genesis candidate, and publish the checksum.

## Configuration

Coordinator will provide:

- genesis file;
- genesis checksum;
- persistent peers;
- launch time;
- support channel;
- release tag or binary checksum.

Required config:

```toml
persistent_peers = "<coordinator-provided-peer-list>"
minimum-gas-prices = "0.025unxrl"
```

Start command at launch:

```bash
./build/nexaraild start --minimum-gas-prices 0.025unxrl
```

Optional setup helper:

```bash
scripts/testnet/prepare-multi-machine-validator.sh \
  --moniker <your-moniker> \
  --genesis-file genesis.json \
  --genesis-sha256 <coordinator-published-sha256> \
  --persistent-peers "<coordinator-provided-peer-list>"
```

## Support Channel

Support channel is pending coordinator setup. Accepted validators must be present in the support channel before gentx freeze and launch scheduling.

Use the channel for:

- node setup questions;
- gentx validation issues;
- peer connectivity checks;
- launch readiness;
- incidents and restarts.

Do not share private keys or mnemonics in the support channel.

## Timeline

| Stage | Status |
|---|---|
| Candidate outreach | Pending |
| Validator acceptance | Pending |
| Support channel setup | Pending |
| Gentx submission window | Pending |
| Final genesis candidate | Pending |
| Multi-machine rehearsal | Pending |
| Public/external testnet launch | NO-GO until gates pass |

## Expected Responsibilities

Accepted validators are expected to:

- run a Linux validator node;
- maintain uptime during rehearsal;
- keep keys secure;
- provide node ID, validator pubkey, address, moniker, and host details;
- submit gentx before deadline;
- verify genesis checksum;
- join launch coordination channel;
- participate in governance rehearsal if scheduled;
- restart safely when requested;
- share evidence requested by the coordinator.

## Coordinator Boundary

The coordinator can help with setup, genesis, peer lists, and evidence collection. The coordinator will never request private keys, mnemonics, SSH keys, or validator signing keys.
