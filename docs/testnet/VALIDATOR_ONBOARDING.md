# NexaRail Testnet Validator Onboarding

**Document:** docs/testnet/VALIDATOR_ONBOARDING.md
**Version:** 1.0
**Date:** 2026-05-25
**Testnet Chain ID:** nexarail-testnet-1 (proposed)
**Devnet Chain ID:** nexarail-devnet-1 (local only)

## Hardware Requirements

| Resource | Minimum | Recommended |
|---|---|---|
| CPU | 2 vCPU | 4 vCPU |
| RAM | 4 GB | 8 GB |
| Storage | 100 GB SSD | 200 GB SSD (NVMe) |
| Network | 10 Mbps | 100 Mbps |
| OS | Ubuntu 22.04 LTS | Ubuntu 24.04 LTS |

macOS (Apple Silicon) is supported for local devnet and testnet validation but not recommended for production-grade validators.

## OS Setup (Ubuntu)

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install build dependencies
sudo apt install -y build-essential git curl jq make gcc

# Install Go 1.22+
wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
source ~/.bashrc
go version  # should show go1.22.x
```

## Build from Source

```bash
git clone https://github.com/Bookings-cpu/nexarail.git
cd nexarail
git checkout main   # or the testnet release tag
make build
# Binary at: build/nexaraild
```

Verify:
```bash
./build/nexaraild version
./build/nexaraild version --long | grep -E "commit|version|cosmos_sdk"
```

## Binary Checksum (recommended)

```bash
sha256sum build/nexaraild > nexaraild.sha256
# Compare with published checksum in release notes
```

## Key Creation

```bash
# Create validator key
./build/nexaraild keys add <your-validator-key-name> --keyring-backend file

# Record the address:
./build/nexaraild keys show <your-validator-key-name> -a --keyring-backend file
# Example output: nxr1abc123...
```

**Back up your mnemonic phrase securely.** No recovery without it.

## Validator Creation (after genesis)

```bash
# Initialize node
./build/nexaraild init <your-moniker> --chain-id nexarail-testnet-1

# Replace genesis.json with published testnet genesis
curl -o ~/.nexarail/config/genesis.json https://testnet.nexarail.network/genesis.json

# Verify genesis hash
sha256sum ~/.nexarail/config/genesis.json
# Compare with published checksum

# Create validator
./build/nexaraild tx staking create-validator \
    --amount 1000000unxrl \
    --commission-max-change-rate 0.01 \
    --commission-max-rate 0.20 \
    --commission-rate 0.05 \
    --min-self-delegation 1 \
    --pubkey $(./build/nexaraild tendermint show-validator) \
    --moniker "<your-moniker>" \
    --from <your-validator-key-name> \
    --chain-id nexarail-testnet-1 \
    --keyring-backend file \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl \
    -y
```

## Gentx Process (pre-launch only)

During the genesis ceremony window (announced on Discord/GitHub):

```bash
./build/nexaraild init <your-moniker> --chain-id nexarail-testnet-1
# Replace genesis with ceremony genesis template
./build/nexaraild keys add <your-validator-key-name> --keyring-backend file
# Fund your address via testnet faucet (pre-launch distribution)
./build/nexaraild gentx <your-validator-key-name> 1000000unxrl \
    --chain-id nexarail-testnet-1 \
    --moniker "<your-moniker>" \
    --commission-rate 0.05 \
    --commission-max-rate 0.20 \
    --commission-max-change-rate 0.01 \
    --min-self-delegation 1 \
    --keyring-backend file
# Submit gentx JSON to the core team via GitHub PR
```

## Peer Configuration

Add persistent peers in `~/.nexarail/config/config.toml`:

```toml
persistent_peers = "nodeid1@ip1:26656,nodeid2@ip2:26656"
```

Seed nodes provided by core team at launch.

## Sentry Node Recommendation

For production-grade validators, run a sentry architecture:
- **Sentry node**: Public-facing, connects to peers
- **Validator node**: Private, connects only to your sentry(s)

```
Internet → Sentry Node (public IP) → Validator Node (private IP, no inbound)
```

Configure in `config.toml`:
```toml
# Sentry node
pex = true
persistent_peers = "<public peers>"
private_peer_ids = "<your validator node id>"

# Validator node
pex = false
persistent_peers = "<your sentry node id>"
```

## Monitoring

Minimum monitoring:
- **Prometheus + Grafana**: Enable in `config.toml` (`prometheus = true`)
- **Node exporter**: System metrics
- **Alert rules**: Disk usage > 80%, missed blocks > 5, peer count < 2

Sample Prometheus config:
```yaml
scrape_configs:
  - job_name: 'nexarail'
    scrape_interval: 15s
    static_configs:
      - targets: ['localhost:26660']
```

## Backup

Critical files to back up:
```bash
~/.nexarail/config/priv_validator_key.json   # validator signing key
~/.nexarail/config/node_key.json             # node identity key
~/.nexarail/keyring-file/                    # keyring (if using file backend)
```

**Never share `priv_validator_key.json`. Loss = unable to sign blocks. Theft = double-sign risk.**

## Upgrade Process

For software upgrades:
1. Monitor Discord/GitHub for upgrade announcements
2. Stop `nexaraild` gracefully before upgrade height
3. `git pull` or download new release
4. `make build`
5. Verify binary checksum
6. Restart `nexaraild`

For on-chain governance upgrades:
- Vote on `SoftwareUpgradeProposal` through `nexaraild tx gov vote`

## Slashing Risks

| Offence | Penalty |
|---|---|
| Double-sign (equivocation) | 5% of stake slashed, validator jailed permanently |
| Downtime (missed blocks) | 0.01% slashed, jailed until unjail tx |
| Governance non-participation | No slashing, but lose voting power weighting |

**Prevent double-signing:**
- Never run two validators with the same `priv_validator_key.json`
- Wait for node to fully stop before restarting
- Use `priv_validator_laddr` with sentry architecture

## Testnet Code of Conduct

1. This is a testnet — no real value. Tokens have no monetary worth.
2. Do not exploit testnet bugs for personal gain. Report them.
3. Do not attack other validators (DDoS, spam, social engineering).
4. Participate in governance: vote on proposals.
5. Communicate: join Discord, respond to coordination requests.
6. Follow reset announcements. Testnet may be torn down at any time.
7. No mainnet claims. Do not represent testnet participation as mainnet validation.

## Support

- Discord: (link TBD)
- GitHub Issues: https://github.com/Bookings-cpu/nexarail/issues
- Documentation: https://github.com/Bookings-cpu/nexarail/tree/main/docs
