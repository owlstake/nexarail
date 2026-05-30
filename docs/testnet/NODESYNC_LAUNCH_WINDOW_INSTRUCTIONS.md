# NodeSync Launch-Window Instructions — DRAFT

> **DRAFT — do not start your node early.** Wait for the coordinator launch-window message that names the final genesis SHA256 and the persistent peer string. Starting against the candidate genesis is not the same as launching the network.

**Network:** `nexarail-testnet-1`
**Document:** `docs/testnet/NODESYNC_LAUNCH_WINDOW_INSTRUCTIONS.md`
**Audience:** NodeSync operator
**Status:** DRAFT

The controlled external-validator testnet is **NOT LAUNCHED**. There is no mainnet. NXRL has no monetary value, is not buyable, and is not for sale. Product live-funds flags remain false by default. Anything below is preparatory; the coordinator will send a separate launch-window message that authorises start.

## What To Wait For

The coordinator will send a single launch-window message containing:

- final genesis SHA256;
- a download link to the final `genesis.json`;
- the final persistent-peer string (NodeSync + coordinator peers);
- the exact UTC launch time.

Do not start `nexaraild start` against any earlier draft. The candidate file is for review only.

## Pre-Launch Steps (Safe Now)

These steps do not start the chain. They prepare the node home and verify your environment.

```bash
# Pin the source tag the coordinator confirmed in this packet
cd /path/to/nexarail
git fetch --tags
git checkout <COORDINATOR_TAG>   # e.g. v0.1.0-rc1-cli-hotfix
make build

# Initialise your testnet home (do this once)
export NXR_CHAIN_ID="nexarail-testnet-1"
export NXR_HOME="$HOME/.nexarail-testnet"
build/nexaraild init NODESYNC --chain-id "$NXR_CHAIN_ID" --home "$NXR_HOME"

# Keep your validator key safe. Never share priv_validator_key.json,
# node_key.json, mnemonics, or keyring backups.
```

> WARNING: `priv_validator_key.json`, `node_key.json`, mnemonics, and seed phrases are private. Do not send them to the coordinator or any third party. Do not commit them to git. Do not paste them into chat.

## Launch-Window Steps (Only After Coordinator Message)

1. Verify the final genesis SHA256 matches the launch-window message:

   ```bash
   sha256sum /path/to/downloaded/genesis.json
   ```

   If it does not match, **stop** and reply to the coordinator. Do not start.

2. Place the final genesis in the node config:

   ```bash
   cp /path/to/downloaded/genesis.json "$NXR_HOME/config/genesis.json"
   build/nexaraild --home "$NXR_HOME" validate-genesis "$NXR_HOME/config/genesis.json"
   ```

3. Configure CometBFT P2P in `$NXR_HOME/config/config.toml`:

   - `p2p.laddr = "tcp://0.0.0.0:26656"`
   - `p2p.external_address = "nexarail-testnet-peer.nodesync.top:26656"`
   - `p2p.persistent_peers = "<EXACT_STRING_FROM_LAUNCH_MESSAGE>"`
   - `p2p.pex = true`
   - `p2p.seed_mode = false`

4. Confirm your `node_id` matches the value in the gentx memo:

   ```bash
   build/nexaraild --home "$NXR_HOME" tendermint show-node-id
   # expected: 2bb62d82b4dbf820fdafd843816f1e72a84ffa8f
   ```

   If it does not match, **stop** and reply to the coordinator.

5. At the launch-window UTC time, start the service:

   ```bash
   build/nexaraild start \
     --home "$NXR_HOME" \
     --minimum-gas-prices 0unxrl \
     --rpc.laddr tcp://127.0.0.1:26657 \
     --p2p.laddr tcp://0.0.0.0:26656
   ```

## Send The Following Status Output

Within 5 minutes of starting, send these outputs to the coordinator:

```bash
# 1. Peer status (we need NodeSync to be the right node ID and peer count > 0)
curl -s http://127.0.0.1:26657/status   | jq '.result.node_info.id, .result.sync_info'

# 2. Connected peers
curl -s http://127.0.0.1:26657/net_info | jq '.result.n_peers, [.result.peers[].node_info.id]'

# 3. Last 50 log lines (redact any local paths if sensitive)
journalctl -u nexaraild -n 50 --no-pager 2>/dev/null || tail -n 50 /var/log/nexaraild.log
```

## Do Not Start Early

Do not start `nexaraild start` before the coordinator confirms the launch window. Starting early against the candidate genesis is not a launch and will not be treated as one. A `nc` listener on TCP 26656 is also not a launch — it does not perform a CometBFT handshake.

## Safety Boundary

The controlled external-validator testnet is not mainnet. External decentralisation is not claimed. NXRL has no monetary value, is not buyable, and is not announced for sale. Product live-funds flags remain false by default. Private keys, mnemonics, and seed phrases must stay on the operator side only.
