# NexaRail RC1 — Reviewer Handoff

## Repository
- URL: `https://github.com/Bookings-cpu/nexarail`
- Branch: `main`
- Tag: `v0.1.0-rc1`
- Latest commit: `b6737e5e562a5d52cf1e07d6879ff0718d538b9c`

## What NexaRail Is
NexaRail is a Cosmos SDK-based application chain with built-in business logic modules for settlement, escrow, merchant management, payout processing, treasury management, and fee collection. This RC1 release provides a controlled local development environment for evaluation purposes.

## Current Status
- **RC1**: Released for controlled local evaluation
- **Mainnet**: NO-GO
- **Public testnet**: NO-GO
- **External validators**: PENDING
- **Token sale**: NO
- **SDK publishing (npm/PyPI)**: NOT PUBLISHED

## What Is Proven
- Local single-node devnet launches and reaches consensus
- All 7 product modules compile, deploy, and respond to queries
- All product modules report `live_enabled: false` by default
- 36 REST endpoints respond with structured data
- Node.js and Python SDK clients read treasury, merchants, settlements, escrows, payouts, and fees
- Write-flow scripts build correct CLI command strings
- Static dashboard renders devnet state
- Regression matrix: 9 fast checks pass
- SDK package checks: 24 pass
- Portal checks: 6 pass

## What Is Not Proven
- Multi-validator consensus
- Public testnet operation
- Token economics at scale
- External validator coordination
- Mainnet readiness

## How to Clone
```bash
git clone https://github.com/Bookings-cpu/nexarail.git
cd nexarail
git checkout v0.1.0-rc1
```

## How to Download RC1 Binaries
Download from the [GitHub Release page](https://github.com/Bookings-cpu/nexarail/releases/tag/v0.1.0-rc1):
- `nexaraild-linux-amd64`
- `nexaraild-darwin-arm64`
- `SHA256SUMS`

Place binaries at `releases/testnet-rc1/binaries/` before running scripts.

## How to Verify Checksums
```bash
cd releases/testnet-rc1
shasum -a 256 -c checksums/SHA256SUMS
```

If binaries are in `binaries/` dir:
```bash
cd releases/testnet-rc1/binaries
shasum -a 256 nexaraild-darwin-arm64 nexaraild-linux-amd64
```

## How to Run Local Demo
```bash
# Verify RC1 package (requires binaries)
bash scripts/release/verify-testnet-rc1.sh

# Fast checks (no binaries needed)
bash scripts/dev/run-nexarail-regression-matrix.sh --fast

# Full local demo (requires binaries + devnet)
bash scripts/dev/run-local-demo.sh
```

## How to Run Fast Regression (No Binaries Required)
```bash
bash scripts/dev/run-nexarail-regression-matrix.sh --fast
```
Expected: 9 PASS / 0 FAIL

## How to Inspect Developer Portal
```bash
bash scripts/dev/build-developer-portal.sh
bash scripts/dev/check-developer-portal.sh
# Open site/developer-portal/index.html in a browser
```

## Evidence Locations
| Check | Evidence |
|---|---|
| Fast regression | `rehearsals/regression-matrix/evidence/<timestamp>/` |
| RC1 verification | `rehearsals/rc1-devnet/evidence/<timestamp>/` |
| SDK packaging | `releases/sdk-local/` |
| Developer bundle | `releases/developer-bundles/` |

## Known Limitations
See [Known Limitations Index](KNOWN_LIMITATIONS_INDEX.md) for full list.

Key limitations:
- Single-node devnet only
- No wallet integration in SDKs
- No private key handling in SDKs
- REST gateway is read-only
- Governance UX is script-heavy
- Burn routing requires explicit evidence collection

## Safety Disclaimer
```
╔══════════════════════════════════════════════════════════════════╗
║  LOCAL DEVNET ONLY — NOT MAINNET                               ║
║  This RC1 release is for controlled local evaluation only.      ║
║  No real funds, no token sale, no investment.                   ║
║  Do not use with any production network.                        ║
╚══════════════════════════════════════════════════════════════════╝
```
