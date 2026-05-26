# NexaRail Governance Rehearsal Results

**Document:** docs/testnet/GOVERNANCE_REHEARSAL_RESULTS.md
**Date:** 2026-05-25
**Status:** Commands documented — execution pending local multi-validator launch

## Governance Flow Commands

⚠️ **Testnet rehearsal only.** These commands enable live fund flows. Tokens have zero value.

### Prerequisites

- Multi-validator testnet running (`nexarail-testnet-1`)
- Validator keys available with `--keyring-backend test`
- Governance voting period: 300s (5 minutes)

### Flow 1: Enable and Disable Escrow LiveEnabled

```bash
# 1. Query current params
./build/nexaraild query escrow params --node tcp://localhost:26657
# Expected: live_enabled: false

# 2. Submit authority update (custom modules use MsgUpdateParams, not gov proposals)
./build/nexaraild tx escrow update-params --live-enabled true \
    --from val1 --chain-id nexarail-testnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# 3. Verify flag is now true
./build/nexaraild query escrow params --node tcp://localhost:26657
# Expected: live_enabled: true

# 4. Test live escrow (create + release)
# (See LIVE_FUNDS_REHEARSAL_COMMANDS.md)

# 5. Disable flag
./build/nexaraild tx escrow update-params --live-enabled false \
    --from val1 --chain-id nexarail-testnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# 6. Verify disabled
./build/nexaraild query escrow params --node tcp://localhost:26657
# Expected: live_enabled: false
```

### Flow 2: Enable and Disable Treasury LiveEnabled

```bash
./build/nexaraild tx treasury update-params --live-enabled true \
    --from val1 --chain-id nexarail-testnet-1 --keyring-backend test -y
./build/nexaraild query treasury params --node tcp://localhost:26657
# Test treasury spend...
./build/nexaraild tx treasury update-params --live-enabled false \
    --from val1 --chain-id nexarail-testnet-1 --keyring-backend test -y
```

### Flow 3: Enable and Disable Payout LiveEnabled

```bash
./build/nexaraild tx payout update-params --live-enabled true \
    --from val1 --chain-id nexarail-testnet-1 --keyring-backend test -y
./build/nexaraild query payout params --node tcp://localhost:26657
# Test payout...
./build/nexaraild tx payout update-params --live-enabled false \
    --from val1 --chain-id nexarail-testnet-1 --keyring-backend test -y
```

### Flow 4: Settlement Progressive Enablement

```bash
# Step 1: Enable merchant-net only
./build/nexaraild tx settlement update-params --live-enabled true \
    --from val1 --chain-id nexarail-testnet-1 --keyring-backend test -y
# Test merchant transfer...

# Step 2: Enable treasury routing
./build/nexaraild tx settlement update-params --treasury-routing-enabled true \
    --from val1 --chain-id nexarail-testnet-1 --keyring-backend test -y
# Test merchant + treasury...

# Step 3: Enable burn routing
./build/nexaraild tx settlement update-params --burn-routing-enabled true \
    --from val1 --chain-id nexarail-testnet-1 --keyring-backend test -y
# Test merchant + treasury + burn...

# Step 4: Disable all in reverse
./build/nexaraild tx settlement update-params --burn-routing-enabled false \
    --from val1 --chain-id nexarail-testnet-1 --keyring-backend test -y
./build/nexaraild tx settlement update-params --treasury-routing-enabled false \
    --from val1 --chain-id nexarail-testnet-1 --keyring-backend test -y
./build/nexaraild tx settlement update-params --live-enabled false \
    --from val1 --chain-id nexarail-testnet-1 --keyring-backend test -y
```

### Flow 5: Parameter Update via Governance

```bash
# Submit parameter change proposal (for SDK modules with subspaces)
./build/nexaraild tx gov submit-proposal param-change proposal.json \
    --from val1 --chain-id nexarail-testnet-1 --keyring-backend test -y

# Vote
./build/nexaraild tx gov vote 1 yes \
    --from val1 --chain-id nexarail-testnet-1 --keyring-backend test -y
./build/nexaraild tx gov vote 1 yes \
    --from val2 --chain-id nexarail-testnet-1 --keyring-backend test -y

# Query proposal
./build/nexaraild query gov proposal 1 --node tcp://localhost:26657
```

## Results

| Test | Status | Notes |
|---|---|---|
| Escrow LiveEnabled toggle | 🔜 Pending launch | Commands documented |
| Treasury LiveEnabled toggle | 🔜 Pending launch | Commands documented |
| Payout LiveEnabled toggle | 🔜 Pending launch | Commands documented |
| Settlement LiveEnabled toggle | 🔜 Pending launch | Commands documented |
| Settlement TreasuryRouting toggle | 🔜 Pending launch | Commands documented |
| Settlement BurnRouting toggle | 🔜 Pending launch | Commands documented |
| Param change proposal | 🔜 Pending launch | Commands documented |
| Voting with multiple validators | 🔜 Pending launch | Requires 3 validators online |

## Blockers

- Multi-validator local launch not yet executed (requires daemon management beyond current environment)
- `nexaraild` binary available but running 3 validators locally needs port allocation and process supervision
- Governance commands documented and ready for execution when launch occurs

## Note on Authority

Custom modules (settlement, escrow, treasury, payout, fees, merchant) use `MsgUpdateParams` messages with an `authority` field. In the current devnet, the authority is the governance module address. For testnet rehearsal, this is the same — the authority address is set at genesis.

For local testing convenience, the authority could be set to a specific key, but for rehearsal accuracy, it should match the governance module address.
