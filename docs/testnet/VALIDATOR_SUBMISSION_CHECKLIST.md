# Validator Submission Checklist

**Network:** `nexarail-testnet-1`
**Status:** external-validator intake open, gentx collection pending

Submit this checklist with your non-secret validator intake record and `gentx-*.json` file.

## Build And Identity

- [ ] Built from tag `v0.1.0-rc1-cli-hotfix` or a coordinator-approved later commit.
- [ ] Recorded build commit with `git rev-parse HEAD`.
- [ ] Recorded OS/arch, for example `ubuntu-22.04/amd64`.
- [ ] Initialised with chain ID `nexarail-testnet-1`.
- [ ] Recorded node ID from `./build/nexaraild tendermint show-node-id --home "$NXR_HOME"`.
- [ ] Confirmed `./build/nexaraild comet show-node-id --home "$NXR_HOME"` returns the same node ID.

## Addresses And Gentx

- [ ] Recorded account address from `keys show <key-name> -a`.
- [ ] Recorded operator address from `keys show <key-name> --bech val -a`.
- [ ] Added the account to the local gentx-preparation genesis:
  `./build/nexaraild add-genesis-account <key-name-or-address> 1000000000unxrl --home "$NXR_HOME" --keyring-backend test`.
- [ ] Created gentx with amount `500000000unxrl`.
- [ ] Included moniker, chain ID, commission rate, commission max rate, commission max change rate, min self delegation, keyring backend, and home in the gentx command.
- [ ] Recorded gentx filename.
- [ ] Recorded gentx SHA256 with `shasum -a 256 "$NXR_HOME/config/gentx/gentx-"*.json`.

The `add-genesis-account` command is only for local gentx preparation. The coordinator assembles final genesis separately from accepted gentxs.

## Network Readiness

- [ ] Provided public host or DNS.
- [ ] Provided P2P port, default `26656`.
- [ ] Confirmed inbound P2P port is open.
- [ ] Confirmed RPC/API are not publicly exposed unless the coordinator explicitly approves it.
- [ ] Confirmed NTP/chrony is running.
- [ ] Confirmed hardware baseline: 4 vCPU, 8 GB RAM, 100 GB SSD minimum.
- [ ] Confirmed stable network and operator availability during launch window.

## Safety Acknowledgement

- [ ] I understand this is controlled testnet infrastructure only.
- [ ] I understand this is not mainnet.
- [ ] I understand testnet denominations have no monetary value.
- [ ] I understand this is not a token sale or investment activity.
- [ ] I will not send mnemonics, private keys, `priv_validator_key.json`, `node_key.json`, keyring files, SSH keys, or node data.

## Submit

Send only:

- completed non-secret intake fields;
- `gentx-*.json`;
- gentx SHA256.

Coordinator validation command:

```bash
scripts/testnet/validate-validator-intake.sh
```
