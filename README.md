# NexaRail Network

A sovereign Layer 1 blockchain for decentralised railway settlement and payments — built with Cosmos SDK v0.47.17 and CometBFT v0.37.18.

**⚠️ Status: Controlled validator registration OPEN. No mainnet. No token sale. Testnet tokens have zero monetary value.**

**🔗 [Apply to run a validator →](docs/testnet/VALIDATOR_APPLICATION_FORM.md)**

---

## Quick Start

### Prerequisites
- Go 1.22+
- Make

### Build
```bash
make build
# Binary: build/nexaraild
```

### Local Devnet
```bash
make init-devnet   # Create 3-validator devnet under ~/.nexarail/
make start-devnet  # Launch validators
```

Devnet endpoints:
- RPC: `http://127.0.0.1:26657`
- REST: `http://127.0.0.1:1317`
- gRPC: `127.0.0.1:9090`

## Chain Configuration

| Parameter | Value |
|---|---|
| Chain ID (devnet) | `nexarail-devnet-1` |
| Chain ID (testnet) | `nexarail-testnet-1` (proposed) |
| Coin Denom | `unxrl` |
| Display Ticker | `NXRL` (1 NXRL = 1,000,000 unxrl) |
| Bech32 Prefix | `nxr` |

## Modules

### Standard Cosmos SDK Modules
auth, bank, staking, slashing, gov, distribution, mint, params, crisis, upgrade, evidence, feegrant, authz, capability, vesting, genutil

### Custom NexaRail Modules

| Module | Purpose | Live Funds? |
|---|---|---|
| x/fees | Fee split parameters (60/20/20 bps) | Policy only |
| x/merchant | Merchant registration + rebate tiers | N/A |
| x/settlement | Payment settlement + fee routing | Behind 3 flags |
| x/escrow | Payment escrow custody | Behind 1 flag |
| x/payout | Automated payouts | Behind 1 flag |
| x/treasury | Protocol treasury + spend execution | Behind 1 flag |

### Live Funds

All live fund flows are implemented but **disabled by default** behind governance-gated flags:

| Module | Flag | Default |
|---|---|---|
| x/escrow | `LiveEnabled` | false |
| x/treasury | `LiveEnabled` | false |
| x/payout | `LiveEnabled` | false |
| x/settlement | `LiveEnabled` | false |
| x/settlement | `TreasuryRoutingEnabled` | false |
| x/settlement | `BurnRoutingEnabled` | false |

See `docs/design/LIVE_FLAGS_MATRIX.md` and `docs/PHASE_5_LIVE_FUNDS_STATUS.md`.

### Deferred
- Validator distribution (design complete — see `docs/design/VALIDATOR_DISTRIBUTION_DESIGN.md`)
- Fee router / BeginBlock routing
- Stablecoin registry
- Bridge (IBC or custom)

## Verification

```bash
go mod tidy && go mod verify
go build ./...
go vet ./...
go test ./...    # ~332 tests, 14 packages, all pass
```

### Validator Registration (Phase 7A–7B)

| Document | Description |
|---|---|
| `docs/testnet/CONTROLLED_VALIDATOR_REGISTRATION.md` | Registration overview, requirements, process |
| `docs/testnet/VALIDATOR_APPLICATION_FORM.md` | Application form for validators |
| `docs/testnet/VALIDATOR_ACCEPTANCE_CHECKLIST.md` | Pre-launch checklist for accepted validators |
| `docs/testnet/GENESIS_SUBMISSION_INSTRUCTIONS.md` | Gentx creation and submission guide |
| `docs/testnet/VALIDATOR_COMMUNICATIONS_PLAN.md` | Communication channels and protocols |
| `docs/testnet/GENESIS_COORDINATOR_RUNBOOK.md` | Internal coordinator operational guide |
| `docs/testnet/VALIDATOR_INTAKE_PIPELINE.md` | Application intake pipeline and SLAs |
| `docs/testnet/VALIDATOR_SCORING_RUBRIC.md` | 7-category technical review scoring |
| `docs/testnet/VALIDATOR_EMAIL_TEMPLATES.md` | Standardised email templates |
| `docs/testnet/DISCORD_TELEGRAM_MODERATION_GUIDE.md` | Community moderation rules |
| `docs/testnet/GENESIS_GENTX_REVIEW_CHECKLIST.md` | 22-point gentx verification |
| `docs/testnet/CONTROLLED_REGISTRATION_ANNOUNCEMENT_FINAL.md` | Public announcement (ready to publish) |
| `docs/testnet/FAQ.md` | Frequently asked questions |
| `docs/testnet/VALIDATOR_REGISTRATION_TRACKER_TEMPLATE.csv` | Intake tracking spreadsheet |

### General

## ⚠️ Disclaimers

- **Testnet only.** NexaRail has no public mainnet.
- **No token sale.** NXRL has not been offered for sale. No ICO/IEO/IDO has occurred.
- **No monetary value.** Testnet tokens have zero value and cannot be exchanged.
- **No investment.** Participation is for technical testing only. No returns are promised.
- **Resets possible.** Testnet state may be wiped at any time.
- **Legal review pending.** See `docs/legal/LEGAL_REVIEW_PACKAGE.md`.

## License

Proprietary — NexaRail Protocol
