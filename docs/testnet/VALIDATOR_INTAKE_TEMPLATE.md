# Validator Intake Template

**Network:** `nexarail-testnet-1`
**Status:** controlled external-validator testnet candidate

Submit one completed record per validator. Do not include secrets, key files, node data, account mnemonics, SSH keys, or private infrastructure notes.

## Markdown Template

```markdown
## Validator Intake

- Moniker:
- Contact handle:
- Operator address:
- Account address:
- Node ID:
- Public IP or DNS:
- P2P port:
- Gentx filename:
- Gentx SHA256:
- Build commit/tag:
- OS/arch:
- Sentry/validator layout used: yes/no
- Sentry details, if yes:

## Acknowledgement

- I understand this is a testnet-only infrastructure exercise.
- I understand testnet denominations have no monetary value.
- I understand this is not mainnet and not a token sale.
- I will not share account mnemonics, private keys, node keys, validator signing keys, keyrings, SSH keys, or node data directories.
- I can be present during the launch window and first-hour validation.
```

## CSV Header

Use this header if submitting intake as CSV for the coordinator registry:

```csv
validator_id,moniker,contact,operator_address,account_address,node_id,public_host,p2p_port,gentx_filename,gentx_sha256,build_tag,build_commit,os_arch,status,notes
```

## Field Requirements

| Field | Required | Notes |
|---|---|---|
| `moniker` | yes | Must match the gentx validator description. |
| `validator_id` | yes | Coordinator-assigned short ID, for example `validator-01`. |
| `contact` | yes | Support-channel handle or direct contact approved by the coordinator. |
| `operator_address` | yes | `nxrvaloper...` address from the gentx. |
| `account_address` | yes | `nxr...` account used to create the gentx. |
| `node_id` | yes | Output of `nexaraild tendermint show-node-id`. |
| `public_host` | yes | Public IP or DNS peers can dial. |
| `p2p_port` | yes | Default `26656` unless coordinated otherwise. |
| `gentx_filename` | yes | File name only, not a path containing local secrets. |
| `gentx_sha256` | yes | SHA256 of the submitted gentx file. |
| `build_tag` | yes | Use `v0.1.0-rc1-cli-hotfix` unless the coordinator approves another tag. |
| `build_commit` | yes | Commit hash used for the build. |
| `os_arch` | yes | Example: `ubuntu-22.04/amd64`. |
| `status` | yes | `submitted`, `verified`, `rejected`, or `waiting`. |
| `notes` | no | Keep non-secret; do not include private contact notes. |

## Field Collection Commands

```bash
git clone https://github.com/Bookings-cpu/nexarail.git
cd nexarail
git checkout v0.1.0-rc1-cli-hotfix
make build

export NXR_HOME="$HOME/.nexarail-testnet"
export NXR_CHAIN_ID="nexarail-testnet-1"

./build/nexaraild init <moniker> --chain-id "$NXR_CHAIN_ID" --home "$NXR_HOME"
./build/nexaraild tendermint show-node-id --home "$NXR_HOME"
./build/nexaraild keys add <key-name> --home "$NXR_HOME" --keyring-backend test
./build/nexaraild keys show <key-name> -a --home "$NXR_HOME" --keyring-backend test
./build/nexaraild keys show <key-name> --bech val -a --home "$NXR_HOME" --keyring-backend test
./build/nexaraild add-genesis-account <key-name-or-address> 1000000000unxrl \
  --home "$NXR_HOME" \
  --keyring-backend test
./build/nexaraild gentx <key-name> 500000000unxrl \
  --moniker <moniker> \
  --chain-id "$NXR_CHAIN_ID" \
  --commission-rate 0.05 \
  --commission-max-rate 0.20 \
  --commission-max-change-rate 0.01 \
  --min-self-delegation 1 \
  --keyring-backend test \
  --home "$NXR_HOME"

shasum -a 256 "$NXR_HOME/config/gentx/gentx-"*.json
git rev-parse HEAD
```

The `add-genesis-account` command is local gentx preparation only. The coordinator assembles final genesis separately from accepted gentxs.

Submit only the `gentx-*.json` file plus the non-secret intake fields. Do not send mnemonics, private keys, node keys, validator signing keys, keyring files, SSH keys, or node data.
