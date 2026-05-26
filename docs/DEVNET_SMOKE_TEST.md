# NexaRail Devnet Smoke Test

## Quick Start

```bash
cd ~/workspace/nexarail
make build
make init-devnet
make start-devnet
```

Wait ~10 seconds for blocks to start producing, then run:

```bash
bash scripts/smoke-test.sh
```

## Manual Verification

### Node Status
```bash
curl http://127.0.0.1:26657/status | jq '.result.node_info.network'
# Expected: "nexarail-devnet-1"
```

### Block Production
```bash
curl http://127.0.0.1:26657/status | jq '.result.sync_info.latest_block_height'
# Expected: incrementing block height
```

### Query Module Trees
```bash
nexaraild query fees --help
nexaraild query merchant --help
nexaraild query settlement --help
nexaraild query escrow --help
nexaraild query payout --help
nexaraild query treasury --help
```

### TX Module Trees
```bash
nexaraild tx fees --help
nexaraild tx merchant --help
nexaraild tx settlement --help
nexaraild tx escrow --help
nexaraild tx payout --help
nexaraild tx treasury --help
```

## Known Devnet Behaviors

- All custom modules use `nxr` Bech32 prefix addresses
- All amounts use `unxrl` denomination
- Genesis accounts are pre-funded with devnet tokens
- No real money movement occurs — all custom modules are metadata-only in v1

## Smoke Test Exit Codes

- 0: All checks passed
- 1: One or more checks failed (check console output)
