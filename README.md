# NexaRail Network

A sovereign Layer 1 blockchain for controlled testnet evaluation of railway settlement and payments — built with Cosmos SDK v0.47.17 and CometBFT v0.37.18. External validator distribution is not yet live.

**⚠️ Status: Controlled validator registration OPEN. Technical readiness: GO. No mainnet. No token sale. Testnet tokens have zero monetary value.**

---

## Run the Local Demo

```bash
scripts/dev/run-local-demo.sh --serve-dashboard --keep-running
```

One command: verify package → launch devnet → run smoke tests → open dashboard.

| Option | Effect |
|---|---|
| `--serve-dashboard` | Open local dashboard at http://localhost:8088 |
| `--keep-running` | Leave devnet running after demo |
| `--skip-smoke` | Skip smoke tests (faster) |

[Full demo guide →](docs/developers/LOCAL_DEMO_GUIDE.md)

**⚠️ LOCAL DEVNET ONLY — NOT MAINNET — No token sale.**

---

## Controlled Testnet RC1

| Item | Detail |
|---|---|
| Packaging | **Complete** — RC1 release assets packaged and verified |
| Local devnet | **Ready** — single-node and 5-agent modes available |
| Public launch | **NO** — This is NOT a public launch |
| Mainnet | **NO** — This is NOT mainnet |
| Validator onboarding | Pending — gentx collection and genesis assembly remain open |
| Live flags | **Disabled by default** — all 6 live flags are `false` in genesis |
| Product-flow suite | **487 pass / 0 fail** — full coverage validated |
| REST parity | **36/36 (100%)** — REST readback parity confirmed |
| Launch status | `NOT_LIVE` — controlled testnet preparation only |

### Quick Links

| Link | Description |
|---|---|
| [Local Demo Guide](docs/developers/LOCAL_DEMO_GUIDE.md) | One-command demo walkthrough |
| [RC1 Reviewer README](docs/release/RC1_REVIEWER_README.md) | Primary entry point for reviewers |
| [RC1 Quickstart](docs/release/RC1_QUICKSTART.md) | Command-first devnet guide |
| [RC1 Evidence Summary](docs/release/RC1_EVIDENCE_SUMMARY.md) | All evidence at a glance |
| [RC1 Review Checklist](docs/release/RC1_REVIEW_CHECKLIST.md) | Reviewer verification checklist |
| [RC1 Release Notes](docs/release/TESTNET_RC1_RELEASE_NOTES.md) | Full release notes |
| [RC1 Devnet Launch Guide](docs/release/TESTNET_RC1_DEVNET_LAUNCH_GUIDE.md) | Step-by-step devnet setup |
| [Litepaper](docs/NEXARAIL_LITEPAPER.md) | Project overview |
| [REST API Docs](docs/api/REST_READBACK_ROUTES.md) | All REST readback endpoints |
| [Evidence Manifest](docs/release/TESTNET_RC1_EVIDENCE_MANIFEST.md) | Evidence index |
| [Known Limitations](docs/release/TESTNET_RC1_KNOWN_LIMITATIONS.md) | Current limitations |

---

## Developer Resources

| Resource | Description |
|---|---|
| [Developer Quickstart](docs/developers/DEVELOPER_QUICKSTART.md) | Get started building against the devnet |
| [API Examples](docs/developers/API_EXAMPLES.md) | Curl examples for all REST endpoints |
| [Product Flow Examples](docs/developers/PRODUCT_FLOW_EXAMPLES.md) | Complete merchant/settlement/escrow/treasury/payout flows |
| [Demo App Plan](docs/developers/DEMO_APP_PLAN.md) | Future lightweight dashboard plan |
| [REST Examples](examples/rest/) | Read-only REST example scripts (bash + curl) |
| [Node.js Client](examples/node-client/) | Lightweight Node.js client (no dependencies) |
| [Python Client](examples/python-client/) | Lightweight Python client (stdlib only) |
| [Local Dashboard](examples/dashboard/) | Read-only local devnet dashboard (static HTML/JS/CSS) |
| [SDK Package Preparation](docs/developers/SDK_PACKAGE_PREPARATION.md) | Local SDK packaging status — Node `@nexarail/devnet-client@0.1.0-dev`, Python `nexarail-devnet-client==0.1.0.dev` (local install only, no npm/PyPI publishing) |
| [Regression Matrix](docs/developers/DEMO_REGRESSION_MATRIX.md) | CI regression checks and expected pass counts |
| [CI Checks](docs/release/RC1_CI_CHECKS.md) | When to run each check and expected outputs |

### End-to-End Developer Demo

Run the complete local devnet workflow from launch to inspect to SDK to dashboard:

```bash
scripts/dev/run-end-to-end-demo.sh
```

See [Scenario Doc](docs/developers/END_TO_END_DEMO_SCENARIO.md) and [Summary](docs/developers/END_TO_END_DEMO_SUMMARY.md) for details.

### Developer Onboarding Bundle

Get all developer assets in one archive:

```bash
scripts/dev/prepare-developer-bundle.sh
```

The bundle includes docs, SDK archives, examples, scripts, and manifests.
Archive is saved to `releases/developer-bundles/`.

See [Onboarding Checklist](docs/developers/ONBOARDING_CHECKLIST.md) and [Contributing Guide](CONTRIBUTING.md) to get started.

See [Contributor Testing Guide](docs/developers/CONTRIBUTOR_TESTING_GUIDE.md) for expected check results.

### Developer Portal

Browse the documentation as a static website:

```bash
# Build the portal
bash scripts/dev/build-developer-portal.sh

# Serve locally on port 8090
bash scripts/dev/serve-developer-portal.sh
```

Portal source: `docs/portal/index.html`
Build output: `site/developer-portal/index.html`

### SDK Documentation

| Resource | Description |
|---|---|
| [SDK RC1 Release Notes](docs/developers/SDK_RC1_RELEASE_NOTES.md) | Release notes for the SDK RC1 — changes, installation, usage |
| [Node.js SDK API Reference](docs/developers/NODE_SDK_API_REFERENCE.md) | Comprehensive API reference for the Node.js devnet client |
| [Python SDK API Reference](docs/developers/PYTHON_SDK_API_REFERENCE.md) | Comprehensive API reference for the Python devnet client |
| [SDK Recipes](docs/developers/SDK_RECIPES.md) | Common SDK usage patterns and recipes |
| [Local Package Archive](releases/sdk-local/) | Local SDK tarballs for offline/dev use — NOT published to npm or PyPI |

### Run Regression Checks

```bash
# Fast (no devnet needed):
scripts/dev/run-nexarail-regression-matrix.sh --fast

# Full (with devnet):
scripts/dev/run-nexarail-regression-matrix.sh --full --with-devnet
```

---

**Runtime note:** Local 5-agent runtime readiness is proven; external validator onboarding and multi-machine/Linux rehearsal remain open/pending; public testnet launch is not yet live.

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

### Project Documentation

| Document | Description |
|---|---|
| `docs/NEXARAIL_LITEPAPER.md` | Full public litepaper — problem, vision, modules, safety model, roadmap, limitations |
| `docs/NEXARAIL_LITEPAPER_SUMMARY.md` | One-page summary of the litepaper |

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
