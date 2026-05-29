# Validator Acceptance Checklist — NexaRail Testnet

**Chain:** nexarail-testnet-1
**Phase:** Post-Approval Pre-Launch
**To be completed by:** Accepted validator operator

---

Complete each item before submitting your gentx. Check the box when done.

## Environment

| # | Task | Done |
|---|---|---|
| 1.1 | Linux host provisioned (Ubuntu 22.04+ / Debian 12+ / equivalent) | ☐ |
| 1.2 | CPU ≥ 4 vCPU confirmed | ☐ |
| 1.3 | RAM ≥ 8 GB confirmed | ☐ |
| 1.4 | Disk ≥ 100 GB SSD confirmed | ☐ |
| 1.5 | Static public IP assigned | ☐ |
| 1.6 | Port 26656 (P2P) open and reachable | ☐ |
| 1.7 | Port 26657 (RPC) open (optional but recommended) | ☐ |
| 1.8 | Time synchronised (NTP configured) | ☐ |
| 1.9 | Firewall rules configured | ☐ |

## Build & Binary

| # | Task | Done |
|---|---|---|
| 2.1 | Go 1.22+ installed | ☐ |
| 2.2 | Repository cloned: `github.com/Bookings-cpu/nexarail` | ☐ |
| 2.3 | `make build` succeeds | ☐ |
| 2.4 | `go test ./...` all pass | ☐ |
| 2.5 | `nexaraild version` returns correctly | ☐ |

## Keys & Initialisation

| # | Task | Done |
|---|---|---|
| 3.1 | `nexaraild init <moniker> --chain-id nexarail-testnet-1` complete | ☐ |
| 3.2 | Validator key generated | ☐ |
| 3.3 | Node key generated | ☐ |
| 3.4 | Private keys backed up securely | ☐ |
| 3.5 | Node ID recorded: `nexaraild tendermint show-node-id` | ☐ |
| 3.6 | Validator pubkey recorded: `nexaraild tendermint show-validator` | ☐ |
| 3.7 | Account key added: `nexaraild keys add <name>` | ☐ |
| 3.8 | Account address recorded | ☐ |
| 3.9 | Mnemonic stored offline, securely | ☐ |

## Genesis Configuration

| # | Task | Done |
|---|---|---|
| 4.1 | `config.toml` persistent_peers set to coordinator-provided value | ☐ |
| 4.2 | `config.toml` pex = true | ☐ |
| 4.3 | `config.toml` addr_book_strict = false | ☐ |
| 4.4 | `config.toml` p2p.laddr = "tcp://0.0.0.0:26656" | ☐ |
| 4.5 | `config.toml` rpc.laddr = "tcp://0.0.0.0:26657" (or restricted) | ☐ |
| 4.6 | `app.toml` minimum-gas-prices set | ☐ |
| 4.7 | Genesis file obtained from coordinator | ☐ |
| 4.8 | Genesis checksum verified against published value | ☐ |

## Gentx

| # | Task | Done |
|---|---|---|
| 5.1 | Local gentx-preparation account added with `nexaraild add-genesis-account <key-name-or-address> 1000000000unxrl --keyring-backend test` | ☐ |
| 5.2 | `nexaraild gentx <key-name> 500000000unxrl --chain-id nexarail-testnet-1` succeeds | ☐ |
| 5.3 | Gentx file located at `<home>/config/gentx/gentx-*.json` | ☐ |
| 5.4 | Gentx submitted to coordinator (do NOT include private keys) | ☐ |

`add-genesis-account` is local gentx preparation only. The coordinator assembles final genesis separately from accepted gentxs.

## Understanding

| # | Statement | Confirmed |
|---|---|---|
| 6.1 | I understand testnet state may be wiped at any time | ☐ |
| 6.2 | I understand testnet tokens have zero monetary value | ☐ |
| 6.3 | I understand this is NOT a token sale or investment | ☐ |
| 6.4 | I understand live fund modules are disabled by default | ☐ |
| 6.5 | I understand I must maintain reasonable uptime | ☐ |
| 6.6 | I understand the security reporting process | ☐ |
| 6.7 | I understand coordinator may reset the chain without notice | ☐ |
| 6.8 | I understand double-signing carries a 5% slash penalty | ☐ |

## Contact Confirmation

| # | Task | Done |
|---|---|---|
| 7.1 | I am in the testnet communication channel | ☐ |
| 7.2 | I have provided emergency contact information to the coordinator | ☐ |
| 7.3 | I will monitor the communication channel during and after launch | ☐ |

---

## Coordinator Verification

| # | Task | Done |
|---|---|---|
| C.1 | All items confirmed by validator | ☐ |
| C.2 | Gentx received and verified | ☐ |
| C.3 | Gentx validates against genesis | ☐ |
| C.4 | Genesis checksum published | ☐ |
| C.5 | Validator added to launch coordination list | ☐ |
