# NexaRail RPC & Explorer Rehearsal

**Document:** docs/testnet/RPC_EXPLORER_REHEARSAL.md
**Date:** 2026-05-25
**Status:** Commands documented — execution pending local multi-validator launch

## RPC Endpoint Tests

### Node Status
```bash
curl -s http://localhost:26657/status | jq '{network: .result.node_info.network, height: .result.sync_info.latest_block_height, moniker: .result.node_info.moniker}'
# Expected: network="nexarail-testnet-1", height > 0
```

### Block Query
```bash
curl -s http://localhost:26657/block?height=1 | jq '.result.block.header.chain_id'
# Expected: "nexarail-testnet-1"

curl -s http://localhost:26657/block | jq '.result.block.header.height'
# Expected: latest height (integer)
```

### Net Info (Peers)
```bash
curl -s http://localhost:26657/net_info | jq '.result.n_peers'
# Expected: integer, 0 for single-node, >0 for multi-validator
```

### Validator Set
```bash
curl -s http://localhost:26657/validators | jq '.result.validators | length'
# Expected: ≥ 3
```

### ABCI Query — Module Params
```bash
# Settlement params
curl -s 'http://localhost:26657/abci_query?path="/custom/settlement/params"' | jq -r '.result.response.value' | base64 -d | jq .

# Escrow params
curl -s 'http://localhost:26657/abci_query?path="/custom/escrow/params"' | jq -r '.result.response.value' | base64 -d | jq .
```

## REST Endpoint Tests

### Bank Balances
```bash
ADDR=$(./build/nexaraild keys show val1 -a --keyring-backend test)
curl -s "http://localhost:1317/cosmos/bank/v1beta1/balances/$ADDR" | jq '.balances'
```

### Staking Validators
```bash
curl -s "http://localhost:1317/cosmos/staking/v1beta1/validators?status=BOND_STATUS_BONDED" | jq '.validators | length'
```

### Governance Proposals
```bash
curl -s "http://localhost:1317/cosmos/gov/v1beta1/proposals" | jq '.proposals | length'
```

## gRPC Endpoint Notes

gRPC endpoint at `localhost:9090`. Query via `grpcurl`:

```bash
# List services
grpcurl -plaintext localhost:9090 list

# Query bank balance
grpcurl -plaintext -d '{"address":"nxr1..."}' localhost:9090 cosmos.bank.v1beta1.Query/Balance
```

gRPC-web may need a proxy (e.g., envoy) for browser access.

## Explorer Integration Checklist

If deploying Ping.pub or similar explorer:

- [ ] RPC endpoint reachable from explorer host
- [ ] REST endpoint reachable from explorer host
- [ ] Chain ID registered in explorer config
- [ ] Bech32 prefix (`nxr`) configured
- [ ] Denom (`unxrl`) configured
- [ ] Display denom (`NXRL`) with 6 decimal places
- [ ] Validator set queryable
- [ ] Block queryable
- [ ] Transaction queryable
- [ ] Custom module queries working
