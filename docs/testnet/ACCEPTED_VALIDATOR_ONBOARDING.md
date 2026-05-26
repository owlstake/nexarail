# Accepted Validator Onboarding — NexaRail Testnet

**Chain:** nexarail-testnet-1
**Phase:** 7D — Post-Acceptance Onboarding
**Audience:** Accepted validators

---

## Welcome

You've been accepted as a genesis validator for the NexaRail controlled testnet. This document covers everything you need to know and do between acceptance and launch.

## ⚠️ Critical Reminders

- **Testnet only.** No mainnet is live. No launch date has been set.
- **No monetary value.** NXRL testnet tokens cannot be exchanged or traded.
- **No token sale.** NXRL has not been offered for sale.
- **No investment.** Participation is for technical testing only.
- **Linux required.** Your validator must run on a Linux host.
- **State may be wiped.** Testnet state can be reset at any time.
- **Live funds are disabled.** All 6 live fund flags default to `false`.

## Chain Details

| Parameter | Value |
|---|---|
| Chain ID | `nexarail-testnet-1` |
| Denom | `unxrl` |
| Display Ticker | `NXRL` (1 NXRL = 1,000,000 unxrl) |
| Bech32 Prefix | `nxr` |
| Minimum Gas Price | 0.025unxrl |
| Minimum Self-Delegation | 500,000,000 unxrl |

## Your Onboarding Checklist

Work through these items in order. Check each when complete.

### Step 1: Environment

- [ ] Linux host provisioned (4+ vCPU, 8+ GB RAM, 100+ GB SSD)
- [ ] Static public IP assigned
- [ ] Port 26656 (P2P) open
- [ ] Port 26657 (RPC) open (recommended)
- [ ] NTP configured (time synchronisation critical)
- [ ] Firewall rules configured

### Step 2: Build

- [ ] Go 1.22+ installed
- [ ] Repository cloned: `github.com/Bookings-cpu/nexarail`
- [ ] `make build` succeeds
- [ ] `go test ./...` all pass
- [ ] `nexaraild version` returns correctly

### Step 3: Initialise

- [ ] `nexaraild init <moniker> --chain-id nexarail-testnet-1`
- [ ] Validator key generated at `~/.nexarail/config/priv_validator_key.json`
- [ ] Node key generated at `~/.nexarail/config/node_key.json`
- [ ] Record node ID: `nexaraild tendermint show-node-id`
- [ ] Record validator pubkey: `nexaraild tendermint show-validator`

### Step 4: Keys

- [ ] Account key created: `nexaraild keys add <key-name>`
- [ ] Account address recorded
- [ ] Mnemonic stored offline, securely (paper recommended)
- [ ] Private keys backed up (NOT shared with anyone)

### Step 5: Configure

- [ ] `config.toml` persistent_peers set (coordinator will provide)
- [ ] `config.toml` pex = true
- [ ] `config.toml` addr_book_strict = false
- [ ] `config.toml` p2p.laddr = "tcp://0.0.0.0:26656"
- [ ] `config.toml` rpc.laddr = "tcp://0.0.0.0:26657" (or restricted)
- [ ] `app.toml` minimum-gas-prices = "0.025unxrl"

### Step 6: Genesis

- [ ] Genesis file received from coordinator
- [ ] Genesis checksum verified against published value
- [ ] Genesis placed at `~/.nexarail/config/genesis.json`

### Step 7: Gentx

- [ ] Account funded by coordinator (check balance)
- [ ] Gentx created: `nexaraild gentx <key-name> 500000000unxrl --chain-id nexarail-testnet-1 --commission-rate X --commission-max-rate Y --commission-max-change-rate Z`
- [ ] Gentx file located at `~/.nexarail/config/gentx/gentx-*.json`
- [ ] Gentx submitted to coordinator

### Step 8: Join Community

- [ ] Joined testnet communication channel
- [ ] Introduced yourself to other validators
- [ ] Emergency contact provided to coordinator
- [ ] Monitoring dashboards (if any) shared with coordinator

### Step 9: Pre-Launch

- [ ] Received launch time from coordinator
- [ ] Received final peer list
- [ ] Verified genesis checksum matches published value
- [ ] Binary ready, config confirmed, ports open
- [ ] Confirmed readiness with coordinator (T-2 hours)

### Step 10: Launch

- [ ] At T-0: `nexaraild start --minimum-gas-prices 0.025unxrl`
- [ ] Monitor logs for first blocks
- [ ] Verify blocks are being produced
- [ ] Verify you appear in validator set
- [ ] Verify peer count

## What to Expect at Launch

1. T-0: All validators start simultaneously
2. T+5s: Block 1 proposed and committed
3. T+30s: All validators in validator set
4. T+5min: Block production stable at ~5-6s intervals
5. T+1h: Coordinator confirms network healthy

## Post-Launch

- Monitor your validator continuously for the first 24 hours
- Report any issues in the communication channel
- Participate in governance proposals
- Respond to coordinator communications within 24 hours
- Expect periodic updates and coordination calls

## Troubleshooting

| Issue | Check |
|---|---|
| Can't connect to peers | Verify persistent_peers format: `<node-id>@<ip>:26656` |
| Block height stuck | Verify all validators started at same time |
| "wrong chain ID" error | Verify `--chain-id nexarail-testnet-1` in config and gentx |
| "account not found" | Contact coordinator — account not funded in genesis |
| Binary panics on start | Check Go version (1.22+), rebuild with `make build` |
| Firewall blocking P2P | Verify port 26656 is open to all peers |

## Contact

- **Technical issues:** Testnet communication channel
- **Gentx questions:** Reply to your acceptance message
- **Urgent issues:** Direct message to coordinator
- **Security issues:** Security contact (not public channel)

## Thank You

Your participation helps validate the NexaRail protocol. This is infrastructure testing — your work contributes to the technical readiness of the network, not to any financial outcome.
