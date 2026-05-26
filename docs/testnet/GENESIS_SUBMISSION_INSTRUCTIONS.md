# Genesis Submission Instructions — NexaRail Testnet

**Chain:** nexarail-testnet-1
**Phase:** Gentx Collection
**Audience:** Accepted validators only

---

## Overview

After your validator application is accepted, you must generate keys, create a signed genesis transaction (gentx), and submit it to the genesis coordinator. This document covers the complete process.

## ⚠️ Security Warning

- **NEVER share your private keys, mnemonics, or passwords with anyone** — including the coordinator
- **The gentx file does NOT contain your private key** — it is safe to share
- **The gentx file DOES contain your validator public key, node ID, and self-delegation amount** — this information becomes part of the public genesis
- **Verify all commands before executing** — typo-squatting attacks exist in blockchain tooling

## Prerequisites

Before starting, confirm:

- [ ] Validator application accepted by coordinator
- [ ] Linux host provisioned and configured
- [ ] Go 1.22+ installed
- [ ] `nexaraild` binary built from source
- [ ] Validator keys generated and backed up
- [ ] Node ID recorded
- [ ] Account funded with testnet tokens (coordinator will provide)

## Step 1: Build the Binary

```bash
git clone https://github.com/Bookings-cpu/nexarail.git
cd nexarail
git checkout main
make build
# Binary: build/nexaraild

# Verify
./build/nexaraild version
```

## Step 2: Initialise Validator

```bash
./build/nexaraild init <your-moniker> --chain-id nexarail-testnet-1
```

Replace `<your-moniker>` with the moniker you provided in your application.

This creates:
- `~/.nexarail/config/config.toml` — node configuration
- `~/.nexarail/config/app.toml` — application configuration
- `~/.nexarail/config/node_key.json` — P2P identity
- `~/.nexarail/config/priv_validator_key.json` — consensus key

## Step 3: Record Your Node ID

```bash
./build/nexaraild tendermint show-node-id
```

Output example: `a1b2c3d4e5f6789012345678901234567890abcdef`

**Save this.** You will need it for the coordinator to configure persistent peers.

## Step 4: Record Your Validator Public Key

```bash
./build/nexaraild tendermint show-validator
```

Output example:
```json
{"@type":"/cosmos.crypto.ed25519.PubKey","key":"..."}
```

**Save this.** It will appear in the genesis file.

## Step 5: Create Your Validator Account Key

```bash
./build/nexaraild keys add <key-name>
```

Replace `<key-name>` with a name for your account key (e.g., `validator`).

**IMPORTANT:**
- Write down the mnemonic phrase (24 words)
- Store it offline, on paper, in a secure location
- Do NOT store it digitally or share it with anyone
- This key controls your validator's self-delegation

Record your account address:
```bash
./build/nexaraild keys show <key-name> -a
```

Output example: `nxr1abc123def456...`

Send this address to the coordinator to receive testnet tokens for your self-delegation.

## Step 6: Wait for Genesis File

The coordinator will provide:
- The genesis file
- Genesis checksum
- Persistent peer list

Verify the genesis checksum:
```bash
sha256sum ~/.nexarail/config/genesis.json
```

Compare against the published checksum. If they don't match, contact the coordinator immediately.

## Step 7: Create the Gentx

Once your account has been funded (coordinator will confirm):

```bash
./build/nexaraild gentx <key-name> 500000000unxrl \
  --chain-id nexarail-testnet-1 \
  --commission-rate 0.05 \
  --commission-max-rate 0.20 \
  --commission-max-change-rate 0.01 \
  --min-self-delegation 1
```

Parameters:
- `<key-name>`: The key you created in Step 5
- `500000000unxrl`: Self-delegation amount (500 NXRL equivalent)
- `--commission-rate`: Your initial commission (0.05 = 5%)
- `--commission-max-rate`: Maximum commission you will ever set (0.20 = 20%)
- `--commission-max-change-rate`: Maximum daily commission change (0.01 = 1%)
- `--min-self-delegation`: Minimum self-delegation (1 unxrl)

**Note:** These values are for the testnet only. Mainnet parameters will be determined separately.

### Verify the Gentx

```bash
ls ~/.nexarail/config/gentx/
# Should show: gentx-<hash>.json
```

## Step 8: Submit the Gentx

Submit ONLY the gentx file (`~/.nexarail/config/gentx/gentx-*.json`) to the coordinator.

**Do NOT submit:**
- `priv_validator_key.json` — your private validator key
- `node_key.json` — your private node key
- Your mnemonic phrase
- Your account private key
- Any other private material

## Step 9: Wait for Launch

After submitting your gentx:

1. The coordinator will verify all gentxs
2. The final genesis will be built and published
3. A launch time will be announced
4. At T-0, start your node:
   ```bash
   ./build/nexaraild start
   # Or with specific options:
   ./build/nexaraild start --minimum-gas-prices 0.025unxrl
   ```

## Deadline

Gentx submission deadline will be announced by the coordinator. Late submissions will not be included in the genesis.

## Troubleshooting

### "account not found in genesis"

Your account hasn't been funded. Contact the coordinator to receive testnet tokens.

### "insufficient funds"

You don't have enough testnet tokens for the self-delegation. Request additional tokens from the coordinator.

### "chain-id mismatch"

You're using the wrong chain ID. Verify: `--chain-id nexarail-testnet-1`

### "key not found"

Your key name doesn't match. Check: `./build/nexaraild keys list`

### "gentx already exists"

You've already created a gentx. Delete the old one or use a different home directory:
```bash
rm ~/.nexarail/config/gentx/gentx-*.json
```

## Contact

For questions about gentx submission, contact the genesis coordinator through the testnet communication channel.
