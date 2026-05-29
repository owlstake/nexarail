# Validator Coordination Messages

**Network:** `nexarail-testnet-1`
**Status:** controlled testnet coordination only, not launched

Use these messages for accepted validators. Keep all public wording clear: this is not mainnet, testnet denominations have no monetary value, and no external decentralisation claim is made until external validators are running and evidenced.

## Request Node ID

```text
Please build from the approved source tag and send your node ID.

Commands:
git clone https://github.com/Bookings-cpu/nexarail.git
cd nexarail
git checkout v0.1.0-rc1-cli-hotfix
make build

export NXR_HOME="$HOME/.nexarail-testnet"
export NXR_CHAIN_ID="nexarail-testnet-1"
./build/nexaraild init <moniker> --chain-id "$NXR_CHAIN_ID" --home "$NXR_HOME"
./build/nexaraild tendermint show-node-id --home "$NXR_HOME"

Send only the node ID, moniker, public host/DNS, P2P port, build tag/commit, and OS/arch. Do not send mnemonics, private keys, node_key.json, priv_validator_key.json, keyring files, SSH keys, or node data.
```

## Request Gentx

```text
Please generate your gentx for nexarail-testnet-1.

Command:
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

The add-genesis-account command is a local gentx preparation step only. The coordinator assembles final genesis separately from accepted gentxs.

Then send:
- gentx-*.json
- gentx SHA256
- account address
- operator address
- node ID
- public host and P2P port

This is controlled testnet coordination only. Testnet denominations have no monetary value.
```

## Gentx Accepted

```text
Your gentx passed coordinator validation for nexarail-testnet-1.

Status: accepted for the next final genesis candidate.

Do not restart from a locally modified genesis. Wait for the coordinator-published final genesis, checksum, persistent peer list, and launch window.
```

## Gentx Rejected

```text
Your gentx did not pass coordinator validation.

Reason:
<insert exact validation reason>

Please regenerate after correcting the issue and send only the new gentx file plus SHA256. Do not send mnemonics, private keys, node keys, validator signing keys, keyrings, SSH keys, or node data.
```

## Final Genesis Published

```text
Final genesis candidate for nexarail-testnet-1 is published.

Download:
<insert genesis URL or repository path>

Verify:
shasum -a 256 genesis.json

Expected SHA256:
<insert checksum>

Do not start until the launch window. This is still a controlled testnet candidate, not mainnet.
```

## Launch Window Announced

```text
Launch window for nexarail-testnet-1:
<insert date/time UTC>

Before T-0:
- confirm final genesis checksum;
- confirm persistent_peers is configured;
- confirm P2P port is reachable;
- confirm NTP/chrony is running;
- stay present in the coordination channel.

At T-0, start:
./build/nexaraild start --home "$NXR_HOME" --minimum-gas-prices 0.025unxrl
```

## Post-Launch Status Request

```text
Please send a short status update:

- current height;
- peer count;
- catching_up true/false;
- validator signing status;
- any errors or warnings from logs.

Send sanitised logs only. Do not send secrets, key files, keyrings, node data, or database files.
```
