# Validator Intake Message Pack

**Network:** `nexarail-testnet-1`
**Status:** controlled testnet preparation; no public network launched

Use these messages for accepted external-validator coordination. Keep every exchange clear: this is controlled testnet only, not mainnet, no token sale, no monetary value, and validators must not send secrets.

## Request Node ID

```text
Please send your validator node ID for nexarail-testnet-1.

Command:
./build/nexaraild tendermint show-node-id --home "$NXR_HOME"

You can also confirm the same value with:
./build/nexaraild comet show-node-id --home "$NXR_HOME"

Send only the node ID, moniker, public host/DNS, P2P port, build tag or commit, and OS/arch. Do not send mnemonics, private keys, node_key.json, priv_validator_key.json, keyring files, SSH keys, or node data.

This is controlled testnet preparation only. It is not mainnet. No token sale is announced or implied. Testnet denominations have no monetary value.
```

## Request Gentx

```text
Please generate and send your gentx for nexarail-testnet-1 after confirming your build tag or commit.

Command:
./build/nexaraild add-genesis-account <key-name-or-address> 1000000000unxrl \
  --home "$NXR_HOME" \
  --keyring-backend test

./build/nexaraild gentx <key-name> 500000000unxrl \
  --moniker <moniker> \
  --chain-id nexarail-testnet-1 \
  --commission-rate 0.05 \
  --commission-max-rate 0.20 \
  --commission-max-change-rate 0.01 \
  --min-self-delegation 1 \
  --keyring-backend test \
  --home "$NXR_HOME"

The `add-genesis-account` command is a local gentx preparation step only. The coordinator assembles final genesis separately from accepted gentxs.

Then send:
- the gentx JSON file only;
- SHA256 of the gentx;
- account address;
- operator address;
- node ID;
- public P2P host and port;
- build tag or commit;
- OS/arch.

Do not send mnemonics, private keys, node keys, validator signing keys, keyring files, SSH keys, or node data.
```

## Request Missing Field

```text
Your validator submission is missing: <field-list>.

Please send the missing public/non-secret field(s) only. Do not send mnemonics, private keys, node keys, validator signing keys, keyring files, SSH keys, or node data.

Final public genesis remains pending until accepted validator records and verified gentxs are complete.
```

## Gentx Accepted

```text
Your gentx has passed coordinator validation for nexarail-testnet-1.

Status: accepted for final-genesis consideration.

This does not mean the public network has launched. Final public genesis, launch window, and peer information remain pending until the accepted gentx set and endpoint inventory are complete.

Controlled testnet only. Not mainnet. No token sale. No monetary value.
```

## Gentx Rejected

```text
Your gentx did not pass validation.

Reason:
<reason>

Please regenerate after correcting the issue and send only the new gentx file plus SHA256. Do not send mnemonics, private keys, node keys, validator signing keys, keyring files, SSH keys, or node data.

The coordinator will not edit your gentx silently.
```

## Endpoint Accepted

```text
Your endpoint details have been recorded for controlled testnet launch preparation.

Recorded fields:
- public P2P address;
- optional RPC/API/gRPC monitoring endpoints if provided.

Please keep RPC/API exposure restricted to trusted access where possible. Final peer strings will be generated after the accepted validator set is complete.
```

## Final Genesis Pending

```text
Final public genesis is still pending.

Current blocker:
<blocker>

Do not start a public node from the internal coordinator candidate. Wait for the coordinator-published final genesis candidate, checksum, peer string, and launch window.
```

## Final Genesis Published

```text
Final public genesis candidate for nexarail-testnet-1 has been published for controlled launch-window preparation.

Before starting:
1. Install the published genesis.json.
2. Verify the SHA256 checksum against SHA256SUMS.
3. Configure the coordinator-provided persistent peers.
4. Confirm your node reports chain ID nexarail-testnet-1.
5. Wait for the confirmed launch-window instruction.

This publication is not a claim that the public network is live. The network is not live until validators start at the confirmed launch window and launch evidence exists.

Controlled testnet only. Not mainnet. No token sale. No monetary value.
```

## Launch Window Pending

```text
Launch window remains pending.

Please keep your node ready, but do not start against any final genesis until the coordinator confirms the launch window and final peer configuration.

Controlled testnet only. Not mainnet. No token sale. No monetary value. Do not send or expose secrets.
```
