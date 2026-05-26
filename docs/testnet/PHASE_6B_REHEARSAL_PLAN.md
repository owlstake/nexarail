# NexaRail Phase 6B — Multi-Validator Testnet Rehearsal Plan

**Document:** docs/testnet/PHASE_6B_REHEARSAL_PLAN.md
**Date:** 2026-05-25
**Status:** Rehearsal plan — local execution

## Objectives

1. Validate the genesis ceremony process end-to-end locally
2. Launch 3+ validators with `nexarail-testnet-1` chain ID
3. Verify blocks are produced, RPC/API respond
4. Confirm all live flags default false at genesis
5. Test governance proposal lifecycle
6. Document live fund flow commands for later testnet execution
7. Identify any blockers before public validator registration

## Non-Goals

- Public validator participation
- Public RPC endpoints
- Real network conditions (latency, partition)
- Performance benchmarking
- Token value or economics
- Mainnet preparation

## Simulated Validators

| Validator | Moniker | Self-Bond |
|---|---|---|
| val1 | Rehearsal Validator 1 | 1,000,000 unxrl |
| val2 | Rehearsal Validator 2 | 1,000,000 unxrl |
| val3 | Rehearsal Validator 3 | 1,000,000 unxrl |

## Rehearsal Configuration

| Parameter | Value |
|---|---|
| Chain ID | `nexarail-testnet-1` |
| Denom | `unxrl` |
| Bech32 prefix | `nxr` |
| Validators | 3 |
| Min gas price | 0.0025unxrl |
| Governance voting period | 300s (5 min) |
| Live flags | All default false |

## Exact Commands

### Pre-Launch

```bash
# Build
cd ~/workspace/nexarail && make build

# Init template
./build/nexaraild init rehearsal --chain-id nexarail-testnet-1

# Add accounts
./build/nexaraild add-genesis-account nxr1core... 500000000000000unxrl
./build/nexaraild add-genesis-account nxr1faucet... 100000000000000unxrl

# Create validator keys
./build/nexaraild keys add val1 --keyring-backend test
./build/nexaraild keys add val2 --keyring-backend test
./build/nexaraild keys add val3 --keyring-backend test

# Create gentx
./build/nexaraild gentx val1 1000000unxrl --chain-id nexarail-testnet-1 \
    --moniker "Rehearsal Validator 1" --commission-rate 0.05 \
    --commission-max-rate 0.20 --commission-max-change-rate 0.01 \
    --min-self-delegation 1 --keyring-backend test
# Repeat for val2, val3

# Collect gentx
./build/nexaraild collect-gentx

# Validate
./build/nexaraild validate-genesis

# Checksum
sha256sum ~/.nexarail/config/genesis.json
```

### Launch

```bash
./build/nexaraild start
```

### Post-Launch Verification

```bash
# Status
curl -s http://localhost:26657/status | jq '.result.node_info.network'  # "nexarail-testnet-1"
curl -s http://localhost:26657/status | jq '.result.sync_info.latest_block_height'

# Module params (all live flags should be false)
curl -s http://localhost:26657/abci_query?path=\"/custom/settlement/params\" | jq
```

## Expected Outputs

| Check | Expected |
|---|---|
| `validate-genesis` | Exit 0, no errors |
| Chain ID | `nexarail-testnet-1` |
| Block production | Height > 1 within 30s |
| Validator count | ≥ 3 in genesis |
| Live flags | All false |
| RPC status | HTTP 200, JSON response |
| REST API | HTTP 200 on `/cosmos/bank/v1beta1/balances/...` |

## Success Criteria

- [ ] 3 validators start and produce blocks
- [ ] Chain ID confirmed as `nexarail-testnet-1`
- [ ] Genesis validates without errors
- [ ] All 6 live flags default false (verified via params query)
- [ ] RPC endpoint responds
- [ ] No panics on startup
- [ ] Governance module loaded
- [ ] Custom modules in genesis

## Rollback / Reset

If the rehearsal fails:
1. Stop all validators
2. Delete `~/.nexarail/`
3. `./build/nexaraild init rehearsal --chain-id nexarail-testnet-1`
4. Repeat from Pre-Launch

## Known Risks

| Risk | Mitigation |
|---|---|
| Port conflicts (26656, 26657, 1317, 9090) | Kill existing devnet first: `pkill nexaraild` |
| Single machine can't run 3 validators simultaneously | Document as blocker — multi-machine test needed |
| Devnet data directory conflict | Use separate `--home` directories per validator |
| `nexaraild start` requires root or `--home` | Use `--home /tmp/nexarail-val1` etc. |

## Sign-Off Checklist

- [ ] Genesis validated
- [ ] Gentx collected
- [ ] Checksums generated
- [ ] Launch attempted
- [ ] Blocks produced (height > 1)
- [ ] RPC verified
- [ ] Module params queried
- [ ] Live flags confirmed false
- [ ] Governance commands documented
- [ ] Live fund commands documented
- [ ] Issues logged
- [ ] Readiness recommendation issued
