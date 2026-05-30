# Controlled Testnet Final Launch Packet — DRAFT

> **DRAFT — NOT FINAL — DO NOT START UNTIL SIGNOFF**
>
> This packet is preparatory. Do not start `nexaraild` against this packet until `docs/testnet/CONTROLLED_TESTNET_LAUNCH_SIGNOFF.md` is marked `APPROVED` and `scripts/testnet/check-final-genesis-freeze-gate.sh` returns `FREEZE_GO`.

**Network:** `nexarail-testnet-1`
**Document:** `docs/testnet/CONTROLLED_TESTNET_FINAL_LAUNCH_PACKET_DRAFT.md`
**Status:** DRAFT
**Launch status:** NOT LAUNCHED
**Mainnet:** NO-GO

## Source / Tag / Commit

| Field | Value |
|---|---|
| Source repo | `https://github.com/Bookings-cpu/nexarail.git` |
| Tag | `v0.1.0-rc1-cli-hotfix` (or later reviewed source tag — TBD) |
| Commit at draft time | `c5b00a6` |
| Build instructions | `git clone … && cd nexarail && git checkout <tag> && make build` |
| Resulting binary | `build/nexaraild` |
| Min Go version | 1.22 |

## Final Genesis Candidate

| Field | Value |
|---|---|
| Candidate path | `releases/testnet-genesis/nexarail-testnet-1-candidate/genesis.json` |
| Candidate SHA256 | `4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095` |
| Manifest | `releases/testnet-genesis/nexarail-testnet-1-candidate/manifest.json` |
| Final publish target | `releases/testnet-genesis/nexarail-testnet-1/` (DO NOT publish until `FREEZE_GO`) |
| Denom | `unxrl` |
| Validator count | 6 (NodeSync + 5 coordinator-operated) |
| Chain ID | `nexarail-testnet-1` |

## Persistent Peer String

```text
2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656
```

Coordinator peers will be appended at launch window once coordinator node IDs are confirmed against the launch-window homes.

## Start Commands (Coordinator)

> Run only after `FREEZE_GO`.

```bash
export NXR_CHAIN_ID="nexarail-testnet-1"
export NXR_HOME="$HOME/.nexarail-launch"
export NXR_BINARY="$(pwd)/build/nexaraild"
export NXR_GENESIS_FINAL="releases/testnet-genesis/$NXR_CHAIN_ID/genesis.json"

$NXR_BINARY init "$MONIKER" --chain-id "$NXR_CHAIN_ID" --home "$NXR_HOME"
cp "$NXR_GENESIS_FINAL" "$NXR_HOME/config/genesis.json"

# Sanity
sha256sum "$NXR_HOME/config/genesis.json"
$NXR_BINARY --home "$NXR_HOME" validate-genesis "$NXR_HOME/config/genesis.json"

# Persistent peers (from the launch-window peer string)
sed -i.bak 's|^persistent_peers = .*|persistent_peers = "<PEER_STRING_AT_LAUNCH>"|' "$NXR_HOME/config/config.toml"

# Start
$NXR_BINARY start \
  --home "$NXR_HOME" \
  --minimum-gas-prices 0unxrl \
  --rpc.laddr tcp://127.0.0.1:26657 \
  --p2p.laddr tcp://0.0.0.0:26656
```

## Status Checks

```bash
# Block height + sync state
curl -s http://127.0.0.1:26657/status | jq '.result.sync_info'

# Validator set count
curl -s 'http://127.0.0.1:26657/validators?height=1&per_page=100' | jq '.result.total'

# Peer count + NodeSync presence
curl -s http://127.0.0.1:26657/net_info | jq '.result.n_peers, [.result.peers[].node_info.id]'

# Live funds flags via REST
curl -s http://127.0.0.1:1317/nexarail/escrow/v1/params    | jq
curl -s http://127.0.0.1:1317/nexarail/payout/v1/params    | jq
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/params  | jq
curl -s http://127.0.0.1:1317/nexarail/settlement/v1/params | jq
```

## Monitoring Commands

```bash
# First-hour evidence
scripts/testnet/collect-launch-hour-evidence.sh \
  --endpoints rehearsals/controlled-testnet/launch-hour/evidence/<TS>/endpoints.csv

# Readiness monitor (height + validator count + live flags)
scripts/testnet/monitor-controlled-testnet-readiness.sh

# Re-run the freeze gate post-launch as a continuous sanity check
scripts/testnet/check-final-genesis-freeze-gate.sh \
  --genesis releases/testnet-genesis/nexarail-testnet-1/genesis.json \
  --expected-sha256 <FINAL_SHA256> \
  --peer 2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656 \
  --probe-rpc http://127.0.0.1:26657
```

## Rollback Conditions

Halt the launch and follow `docs/testnet/CONTROLLED_TESTNET_INCIDENT_RESPONSE.md` if any of the following occur during the first hour:

- height does not advance for > 60 seconds after `n_peers >= 1`;
- validator set count drops below the minimum quorum (`6 → 3` is below safety floor);
- any panic/fatal marker in `nexaraild` logs;
- any product live-funds flag observed as `true` in REST params;
- NodeSync drops from `/validators` and cannot rejoin within the rollback window;
- evidence of double-signing or any consensus fork.

## Safety Disclaimer

The controlled external-validator testnet is **NOT LAUNCHED** in this draft state and remains **NOT a mainnet** at any point. External decentralisation is not claimed. NXRL has no monetary value, is not buyable, and is not announced for sale. Product live-funds flags remain false by default. This packet is for coordinator preparation only; nothing here authorises a public launch by itself.
