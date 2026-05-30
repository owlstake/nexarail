# Controlled Testnet Launch-Day Commands

**Network:** `nexarail-testnet-1`
**Status:** coordinator command sheet; no public network launched

Set common variables:

```bash
export NXR_CHAIN_ID="nexarail-testnet-1"
export NXR_HOME="$HOME/.nexarail-testnet"
export NXR_BINARY="./build/nexaraild"
export NXR_GENESIS="releases/testnet-genesis/nexarail-testnet-1/genesis.json"
export NXR_SHA256SUMS="releases/testnet-genesis/nexarail-testnet-1/SHA256SUMS"
export NXR_CANDIDATE_GENESIS="releases/testnet-genesis/nexarail-testnet-1-candidate/genesis.json"
export NXR_RPC="http://127.0.0.1:26657"
export NXR_API="http://127.0.0.1:1317"
```

## Verify Binary And Tag

```bash
git status --short
git describe --tags --always --dirty
"$NXR_BINARY" version
```

Expected validator source path remains `v0.1.0-rc1-cli-hotfix` or a later reviewed source tag.

## Verify Genesis Checksum

```bash
shasum -a 256 "$NXR_GENESIS"
cat "$NXR_SHA256SUMS"
"$NXR_BINARY" validate-genesis --home "$NXR_HOME"
```

Do not use the internal coordinator candidate as final public genesis.

For rehearsal only, the external-validator candidate genesis is:

```bash
shasum -a 256 "$NXR_CANDIDATE_GENESIS"
```

Do not publish the candidate as final public genesis unless the freeze decision is `FREEZE_GO`.

## Verify Persistent Peers

```bash
cat coordination/validators/peer-info/persistent-peers.txt
grep '^persistent_peers' "$NXR_HOME/config/config.toml"
```

NodeSync P2P reachability recheck:

```bash
dig +short nexarail-testnet-peer.nodesync.top
nc -vz nexarail-testnet-peer.nodesync.top 26656
nc -vz 178.104.162.88 26656
```

Freeze remains deferred while TCP `26656` is not reachable.

## Show Node ID

```bash
"$NXR_BINARY" tendermint show-node-id --home "$NXR_HOME"
"$NXR_BINARY" comet show-node-id --home "$NXR_HOME"
```

Both commands should return the same 40-character node ID.

## Monitor Block Height

```bash
curl -s "$NXR_RPC/status" | jq '.result.sync_info.latest_block_height'
watch -n 5 "curl -s $NXR_RPC/status | jq '.result.sync_info.latest_block_height, .result.sync_info.catching_up'"
```

## Monitor Validator Set

```bash
curl -s "$NXR_RPC/validators" | jq '.result.validators | length'
curl -s "$NXR_RPC/validators" | jq '.result.validators[] | {address, voting_power}'
```

## Monitor Peers

```bash
curl -s "$NXR_RPC/net_info" | jq '.result.n_peers'
curl -s "$NXR_RPC/net_info" | jq '.result.peers[]?.node_info.moniker'
```

## Query Live Flags

```bash
curl -s "$NXR_API/nexarail/settlement/v1/params" | jq '.params'
curl -s "$NXR_API/nexarail/escrow/v1/params" | jq '.params.live_enabled'
curl -s "$NXR_API/nexarail/treasury/v1/params" | jq '.params.live_enabled'
curl -s "$NXR_API/nexarail/payout/v1/params" | jq '.params.live_enabled'
```

Expected: all product live flags remain `false`.

## Query REST/API Params

```bash
curl -s "$NXR_API/cosmos/base/tendermint/v1beta1/node_info" | jq .
curl -s "$NXR_API/cosmos/staking/v1beta1/params" | jq .
curl -s "$NXR_API/cosmos/gov/v1/params/voting" | jq .
```

## Collect Logs

```bash
mkdir -p rehearsals/controlled-testnet/launch-hour/logs
cp "$NXR_HOME/logs/"*.log rehearsals/controlled-testnet/launch-hour/logs/ 2>/dev/null || true
grep -RniE 'panic|fatal|unrecoverable|segmentation fault' rehearsals/controlled-testnet/launch-hour/logs || true
```

Only collect sanitized logs. Do not copy keyrings, node data, database files, `node_key.json`, or `priv_validator_key.json`.

## Run Readiness Monitor

```bash
scripts/testnet/monitor-controlled-testnet-readiness.sh \
  --rpc-file coordination/validators/endpoint-inventory.csv \
  --api-file coordination/validators/endpoint-inventory.csv \
  --expected-chain-id "$NXR_CHAIN_ID" \
  --expected-validator-count <accepted-validator-count> \
  --sample-duration 300 \
  --sample-interval 10
```

For local coordinator rehearsal evidence, use a local-only endpoint CSV under `rehearsals/controlled-testnet/dry-run/evidence/`. Do not write local rehearsal RPC/API rows into the public validator endpoint inventory.

## Collect First-Hour Evidence

```bash
scripts/testnet/collect-launch-hour-evidence.sh \
  --endpoints coordination/validators/endpoint-inventory.csv \
  --duration 3600 \
  --sample-interval 60 \
  --chain-id "$NXR_CHAIN_ID" \
  --expected-validators <accepted-validator-count>
```

## Stop Or Restart Internal Node

```bash
pkill -f 'nexaraild start.*nexarail-testnet' || true
"$NXR_BINARY" start --home "$NXR_HOME" --minimum-gas-prices 0.025unxrl
```

Use only for local/internal rehearsal unless the coordinator has approved validator action.

## Confirm Safety Wording

Before any status update:

```bash
rg -n -i 'mainnet live|buy NXRL|token sale|investment|guaranteed|profit|APY|returns|listing|external decentralisation|independent validators' README.md docs
```

Allowed hits must be denials, warnings, checklist literals, or safety boundaries. Public testnet is not live until final genesis is published and external validators are actually running.
