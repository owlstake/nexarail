# Controlled Testnet Validator Runbook

**Network:** `nexarail-testnet-1`
**Status:** launch candidate preparation

## 0. Current Boundary

The controlled external-validator testnet is not launched. External validator intake remains open, external gentxs are pending, and final public genesis is not published.

Phase 18A adds an internal coordinator candidate for rehearsal only:

```bash
scripts/testnet/prepare-coordinator-genesis-candidate.sh
set -a
. releases/testnet-genesis/coordinator-candidate/dry-run.env
set +a
scripts/testnet/run-controlled-testnet-dry-run.sh
```

The generated candidate must remain marked `INTERNAL COORDINATOR CANDIDATE — NOT FINAL PUBLIC GENESIS`.

## 1. Build From Source

```bash
git clone https://github.com/Bookings-cpu/nexarail.git
cd nexarail
git checkout v0.1.0-rc1-cli-hotfix
make build
./build/nexaraild version
```

## 2. Initialise Node Home

```bash
export NXR_HOME="$HOME/.nexarail-testnet"
export NXR_CHAIN_ID="nexarail-testnet-1"

./build/nexaraild init <moniker> --chain-id "$NXR_CHAIN_ID" --home "$NXR_HOME"
```

## 3. Create Or Recover Validator Account

```bash
./build/nexaraild keys add <key-name> --home "$NXR_HOME" --keyring-backend test
./build/nexaraild keys show <key-name> -a --home "$NXR_HOME" --keyring-backend test
./build/nexaraild keys show <key-name> --bech val -a --home "$NXR_HOME" --keyring-backend test
```

Back up the mnemonic offline. Do not send it to the coordinator.

## 4. Record Node Identifiers

```bash
./build/nexaraild tendermint show-node-id --home "$NXR_HOME"
./build/nexaraild comet show-node-id --home "$NXR_HOME"
./build/nexaraild tendermint show-validator --home "$NXR_HOME"
```

The `tendermint` and `comet` node ID commands should print the same 40-character node ID.

## 5. Create Gentx

Create gentx only after the coordinator confirms the chain ID, build tag, and genesis-account funding amount.

Add the validator account to the local gentx-preparation genesis:

```bash
./build/nexaraild add-genesis-account <key-name-or-address> 1000000000unxrl \
  --home "$NXR_HOME" \
  --keyring-backend test
```

This does not publish final genesis. It only prepares the validator's local genesis state so `gentx` can be generated.

```bash
./build/nexaraild gentx <key-name> 500000000unxrl \
  --moniker <moniker> \
  --chain-id "$NXR_CHAIN_ID" \
  --commission-rate 0.05 \
  --commission-max-rate 0.20 \
  --commission-max-change-rate 0.01 \
  --min-self-delegation 1 \
  --keyring-backend test \
  --home "$NXR_HOME"
```

Record the gentx hash:

```bash
shasum -a 256 "$NXR_HOME/config/gentx/gentx-"*.json
```

Submit only:

```text
$NXR_HOME/config/gentx/gentx-*.json
```

Never submit account mnemonics, private keys, node keys, validator signing keys, keyrings, SSH keys, or node data directories.

Coordinator intake registry path: `coordination/validators/validator-intake.csv`.

## 6. Install Final Genesis

After the coordinator publishes final genesis:

```bash
mkdir -p "$NXR_HOME/config"
cp genesis.json "$NXR_HOME/config/genesis.json"
shasum -a 256 "$NXR_HOME/config/genesis.json"
./build/nexaraild validate-genesis --home "$NXR_HOME"
```

The checksum must match the coordinator-published `SHA256SUMS`.

## 7. Configure Persistent Peers

Set the coordinator-provided peer string in `$NXR_HOME/config/config.toml`:

```toml
persistent_peers = "<nodeid@host:port,nodeid@host:port>"
```

For sentry layouts, apply only the coordinator-approved validator/sentry topology.

## 8. Configure Minimum Gas

Set in `$NXR_HOME/config/app.toml`:

```toml
minimum-gas-prices = "0.025unxrl"
```

## 9. Firewall

Open inbound P2P only unless the coordinator explicitly asks for more:

```bash
sudo ufw allow 26656/tcp
sudo ufw deny 26657/tcp
sudo ufw deny 1317/tcp
```

If you expose RPC/API for monitoring, restrict it to trusted IPs.

## 10. Start At Launch Window

```bash
./build/nexaraild start \
  --home "$NXR_HOME" \
  --minimum-gas-prices 0.025unxrl
```

## 11. Optional systemd Unit

Use only after paths are adjusted for your host:

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

## 12. Check Status

```bash
curl -s http://127.0.0.1:26657/status | jq .
curl -s http://127.0.0.1:26657/net_info | jq '.result.n_peers'
curl -s http://127.0.0.1:26657/validators | jq '.result.validators | length'
```

For coordinator launch-window monitoring, prepare an endpoint inventory and run:

```bash
scripts/testnet/monitor-controlled-testnet-readiness.sh \
  --rpc-file coordination/validators/endpoint-inventory.csv \
  --expected-chain-id nexarail-testnet-1 \
  --expected-validator-count <count> \
  --sample-duration 300 \
  --sample-interval 10
```

The monitor can also take comma-separated RPC endpoints with `--rpc-endpoints`. Add REST/API endpoints with `--api-endpoints` or `--api-file` when available.

For first-hour evidence capture, run:

```bash
scripts/testnet/collect-launch-hour-evidence.sh \
  --endpoints coordination/validators/endpoint-inventory.csv \
  --duration 3600 \
  --sample-interval 60 \
  --chain-id nexarail-testnet-1 \
  --expected-validators <count>
```

Incident response and launch-day command references:

- `docs/testnet/CONTROLLED_TESTNET_INCIDENT_RESPONSE.md`
- `docs/testnet/CONTROLLED_TESTNET_LAUNCH_DAY_COMMANDS.md`
- `docs/testnet/VALIDATOR_SUPPORT_TRIAGE_TEMPLATE.md`

## 13. Check Validator Signing

```bash
curl -s http://127.0.0.1:26657/status | jq '.result.validator_info'
```

Report missed signatures or unexpected validator-set output immediately.

## 14. Query Live Flags

If API is enabled locally:

```bash
curl -s http://127.0.0.1:1317/nexarail/settlement/v1/params | jq '.params.live_enabled'
curl -s http://127.0.0.1:1317/nexarail/escrow/v1/params | jq '.params.live_enabled'
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/params | jq '.params.live_enabled'
curl -s http://127.0.0.1:1317/nexarail/payout/v1/params | jq '.params.live_enabled'
```

Expected: `false`.

## 15. Submit Issues And Logs Safely

Send only sanitised logs. Remove IPs if requested by your organisation, and never include secrets, key files, keyring data, mnemonics, or validator signing keys.
