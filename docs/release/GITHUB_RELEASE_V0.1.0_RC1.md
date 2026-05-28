# NexaRail v0.1.0-rc1 — Controlled Testnet Release Candidate

## ⚠️ Status Disclaimer
**This is NOT a mainnet launch.**
**This is NOT a public testnet launch.**
**No token sale exists or has existed.**
**Testnet/devnet tokens have zero monetary value.**
**External validators are pending — all validation is local.**
**All live flags default to false.**

## What Is Included
- Local single-node devnet binary (nexaraild) for Darwin ARM64 and Linux AMD64
- Genesis configuration for nexarail-devnet-1
- RC1 release verification script (37/37 checks)
- Developer documentation, quickstart, and API references
- Node.js and Python SDK clients (local install only, NOT on npm/PyPI)
- REST API examples (36 endpoints, 7 scripts)
- Write-flow example scripts (7 dry-run-safe)
- Static developer dashboard
- Static developer portal (19-section browsable site)
- Fast regression matrix (9 checks)
- SDK package checks (24 pass)
- End-to-end developer demo (10 checks pass)
- Developer onboarding bundle and contributor documentation

## What Is NOT Included
- Public testnet
- Mainnet
- External validator setup
- npm or PyPI packages
- Docker images
- Token sale or token distribution
- Wallet integration
- Security audit report

## Assets to Upload
| File | Description |
|---|---|
| `nexaraild-darwin-arm64` | Darwin ARM64 binary |
| `nexaraild-linux-amd64` | Linux AMD64 binary |
| `SHA256SUMS` | Binary checksums |
| `nexarail-developer-bundle-<timestamp>.tar.gz` | Developer bundle |

## Install and Verify
```bash
# 1. Download binaries and SHA256SUMS from this release
# 2. Place in releases/testnet-rc1/binaries/
# 3. Verify checksums
cd releases/testnet-rc1/binaries
shasum -a 256 -c ../checksums/SHA256SUMS

# 4. Verify RC1 package
bash scripts/release/verify-testnet-rc1.sh

# 5. Launch devnet
bash scripts/release/launch-rc1-devnet.sh --single-node --clean
```

## Safety Notes
- This is a LOCAL DEVNET ONLY release — NOT for mainnet
- Testnet tokens (unxrl) have zero monetary value
- No investment, returns, profit, or APY
- External decentralisation has not been achieved
- No independent validators — all validation is local
- SDK packages are NOT published to npm or PyPI
