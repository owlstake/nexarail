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

## Build Instructions - Source Build Primary

```bash
sudo apt update
sudo apt install -y build-essential git curl jq make gcc

git clone https://github.com/Bookings-cpu/nexarail.git
cd nexarail
git checkout v0.1.0-rc1-cli-hotfix
make build

./build/nexaraild version
go test ./...
```

Source build is the primary validator path until prebuilt hotfix assets are available through a verified release upload. If a release binary is provided later, verify its checksum before use.

## Key Generation

Initialise your node:

```bash
export NXR_HOME="$HOME/.nexarail-testnet"
export NXR_CHAIN_ID="nexarail-testnet-1"

./build/nexaraild init <your-moniker> --chain-id "$NXR_CHAIN_ID" --home "$NXR_HOME"
```

Record your node ID:

```bash
./build/nexaraild tendermint show-node-id --home "$NXR_HOME"
./build/nexaraild comet show-node-id --home "$NXR_HOME"
```

The two commands should return the same 40-character node ID. `cometbft show-node-id` also resolves to the same helper group.

If the binary returns `unknown command "tendermint"`, you are running the pre-hotfix RC1 release (`v0.1.0-rc1`). Build from source tag `v0.1.0-rc1-cli-hotfix` or later. Use prebuilt hotfix binaries only after release assets and checksums are published through the verified release channel.

Record your validator consensus pubkey:

```bash
./build/nexaraild tendermint show-validator --home "$NXR_HOME"
```

Create your validator account key:

```bash
./build/nexaraild keys add <key-name> --home "$NXR_HOME" --keyring-backend test
./build/nexaraild keys show <key-name> -a --home "$NXR_HOME" --keyring-backend test
./build/nexaraild keys show <key-name> --bech val -a --home "$NXR_HOME" --keyring-backend test
```

Back up the mnemonic offline. Never share it with the coordinator.

## Gentx Creation

After the coordinator provides the genesis template and confirms your account funding:

First add your validator account to the local gentx-preparation genesis:

```bash
./build/nexaraild add-genesis-account <key-name-or-address> 1000000000unxrl \
  --home "$NXR_HOME" \
  --keyring-backend test
```

This is a local gentx preparation step only. The coordinator assembles final genesis separately from accepted gentxs.

Then create the gentx:

```bash
./build/nexaraild gentx <key-name> 500000000unxrl \
  --moniker <your-moniker> \
  --chain-id "$NXR_CHAIN_ID" \
  --commission-rate 0.05 \
  --commission-max-rate 0.20 \
  --commission-max-change-rate 0.01 \
  --min-self-delegation 1 \
  --keyring-backend test \
  --home "$NXR_HOME"
```

Verify the gentx exists:

```bash
ls "$NXR_HOME/config/gentx/gentx-"*.json
shasum -a 256 "$NXR_HOME/config/gentx/gentx-"*.json
```

## Gentx Submission

Submit only:

```text
$NXR_HOME/config/gentx/gentx-*.json
```

Send it through the coordinator-approved support channel or repository process once announced. Until that channel is announced, keep the gentx local and complete `docs/testnet/VALIDATOR_INTAKE_TEMPLATE.md`.

Never submit:

- mnemonic phrase;
- account private key;
- `priv_validator_key.json`;
- `node_key.json`;
- keyring files or directories;
- SSH keys;
- data directory.

The coordinator will validate gentxs with `scripts/testnet/verify-controlled-testnet-gentx.sh`, assemble the final genesis candidate, and publish the checksum.

## Intake Registry Fields

Send the coordinator these non-secret values:

```text
validator_id:
moniker:
contact:
operator_address:
account_address:
node_id:
public_host:
p2p_port:
gentx_filename:
gentx_sha256:
build_tag: v0.1.0-rc1-cli-hotfix
build_commit:
os_arch:
status: submitted
notes:
```

Coordinator registry path: `coordination/validators/validator-intake.csv`.

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
./build/nexaraild start --home "$NXR_HOME" --minimum-gas-prices 0.025unxrl
```

Firewall baseline:

```bash
sudo ufw allow 26656/tcp
sudo ufw deny 26657/tcp
sudo ufw deny 1317/tcp
```

Expose RPC/API only to trusted IPs if the coordinator explicitly asks for it.

Optional systemd unit, after replacing paths and user:

```ini
[Unit]
Description=NexaRail controlled testnet validator
After=network-online.target
Wants=network-online.target

[Service]
User=nexarail
WorkingDirectory=/opt/nexarail
ExecStart=/opt/nexarail/build/nexaraild start --home /var/lib/nexarail --minimum-gas-prices 0.025unxrl
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
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

## Troubleshooting

| Symptom | Likely cause | Action |
|---|---|---|
| `unknown command "tendermint"` | Pre-hotfix binary | Build from `v0.1.0-rc1-cli-hotfix` or later. |
| `node_key.json: no such file or directory` | Node home not initialised | Run `init` with the same `--home`. |
| Genesis checksum mismatch | Wrong file or stale candidate | Stop and ask coordinator for the current checksum. |
| No peers | Wrong node ID, host, port, or firewall | Confirm `persistent_peers`, public P2P reachability, and `26656/tcp`. |
| Gentx rejected | Chain ID, denom, moniker, or address issue | Regenerate after applying coordinator feedback. |

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
