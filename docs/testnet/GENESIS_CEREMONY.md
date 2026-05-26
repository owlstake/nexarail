# NexaRail Testnet Genesis Ceremony

**Document:** docs/testnet/GENESIS_CEREMONY.md
**Version:** 1.0
**Date:** 2026-05-25
**Testnet Chain ID:** nexarail-testnet-1
**Devnet Chain ID:** nexarail-devnet-1 (unchanged)

## Chain ID

- **Testnet:** `nexarail-testnet-1` (proposed)
- **Devnet:** `nexarail-devnet-1` (local development only)
- **Subsequent testnets:** `nexarail-testnet-2`, `nexarail-testnet-3`, etc.

Chain IDs are scoped: `nexarail-{environment}-{sequence}`.

## Validator Registration Window

| Phase | Duration | Description |
|---|---|---|
| Announcement | 72 hours before | Genesis ceremony announced on Discord + GitHub |
| Registration | 48-hour window | Validators submit gentx PRs |
| Review | 24 hours | Core team reviews gentx validity |
| Genesis publication | After review | Final genesis.json + checksum published |
| Launch | Coordinated time | T-0 announced 24 hours in advance |

## Genesis Allocation Rules

### Devnet (local only)

```
"app_state": {
  "bank": {
    "balances": [
      {"address": "nxr1validator...",  "coins": "1000000000000000unxrl"},
      {"address": "nxr1user1...",      "coins": "1000000000000unxrl"},
      {"address": "nxr1user2...",      "coins": "1000000000000unxrl"}
    ]
  }
}
```

### Testnet (public)

```
"app_state": {
  "bank": {
    "balances": [
      {"address": "nxr1core1...",     "coins": "500000000000000unxrl"},  // Core team
      {"address": "nxr1faucet...",    "coins": "100000000000000unxrl"},  // Faucet
      {"address": "nxr1validator1...","coins": "1000000unxrl"},           // Gentx self-bond
      ...                                                                 // One entry per validator
    ]
  }
}
```

Rules:
- Core team accounts receive genesis allocation for faucet funding and initial staking
- Validator self-bond: exactly the amount declared in gentx
- No premine for external parties
- No airdrop
- No token sale allocation
- All genesis tokens are testnet-only with zero monetary value

## Gentx Collection Process

### Step 1: Core team publishes genesis template

```bash
# Core team creates template genesis
./build/nexaraild init template --chain-id nexarail-testnet-1
# Modify template: set params, fund core accounts, etc.
# Publish: template-genesis.json + checksum
```

### Step 2: Validators submit gentx

```bash
# Each validator:
./build/nexaraild init <moniker> --chain-id nexarail-testnet-1
cp template-genesis.json ~/.nexarail/config/genesis.json
./build/nexaraild keys add <keyname> --keyring-backend file
# Wait for faucet to fund the validator address
./build/nexaraild gentx <keyname> 1000000unxrl \
    --chain-id nexarail-testnet-1 \
    --moniker "<moniker>" \
    --commission-rate 0.05 \
    --commission-max-rate 0.20 \
    --commission-max-change-rate 0.01 \
    --min-self-delegation 1 \
    --keyring-backend file

# Submit PR to nexarail repo:
# File: gentx/<moniker>.json
```

### Step 3: Core team collects and validates

```bash
# Collect all gentx files
mkdir -p gentx-collected
cp ../path/to/gentx/*.json gentx-collected/

# Validate each gentx
for f in gentx-collected/*.json; do
    ./build/nexaraild gentx validate --gentx "$f" --chain-id nexarail-testnet-1 || echo "INVALID: $f"
done

# Add to genesis
./build/nexaraild collect-gentx --gentx-dir gentx-collected
```

## Genesis Verification

After genesis is finalised:

```bash
# Verify genesis is valid
./build/nexaraild validate-genesis

# Generate checksum
sha256sum ~/.nexarail/config/genesis.json
# Publish checksum on GitHub + Discord
```

Every validator should independently verify:
1. Genesis checksum matches published value
2. Their gentx is included
3. Chain ID is correct (`nexarail-testnet-1`)
4. `validate-genesis` passes

## Launch Time Coordination

| Step | Time | Action |
|---|---|---|
| T-24h | 24 hours before | Launch time announced, genesis published |
| T-1h | 1 hour before | Validators confirm readiness in Discord |
| T-10m | 10 minutes before | Final checks, peer list published |
| T-0 | Launch | All validators start simultaneously |
| T+5m | 5 minutes after | Confirm block production, check consensus |
| T+30m | 30 minutes after | Faucet activated, public endpoints live |

## Rollback / Reset Plan

If genesis fails (consensus not reached, critical bug discovered):

1. Announce reset in Discord + GitHub
2. Increment chain ID (e.g., `nexarail-testnet-2`)
3. New genesis ceremony (72-hour window)
4. Previous chain state is discarded
5. Validators re-submit gentx

Resets are expected during early testnet phases. No state migration between testnet versions.
