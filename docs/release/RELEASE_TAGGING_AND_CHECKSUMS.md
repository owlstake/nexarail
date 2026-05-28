# Release Tagging and Checksums — NexaRail

**Date:** 2026-05-26

---

## ⚠️ Mainnet Warning

**No mainnet is live.** These release procedures are for controlled testnet only. No monetary value accrues to testnet tokens. No token sale has occurred.

---

## Creating a Release Tag

```bash
# Tag the current commit
git tag -a v0.1.0-testnet -m "NexaRail v0.1.0 — Controlled Testnet Release

- Cosmos SDK v0.47.17 + CometBFT v0.37.18
- 6 custom modules: fees, merchant, settlement, escrow, payout, treasury
- All 6 live fund flags default to false
- 17 REST endpoints across 6 modules
- ~465 tests, 15 packages, all passing
- Docker rehearsal: 3 validators, height >20

Status: Controlled testnet preparation. No mainnet. No token sale."

# Push tag
git push origin v0.1.0-testnet
```

## Building Binaries

```bash
# macOS (arm64)
make build
# Binary: build/nexaraild

# Linux (amd64)
GOOS=linux GOARCH=amd64 go build -mod=readonly \
  -ldflags '-X github.com/cosmos/cosmos-sdk/version.Name=nexarail
            -X github.com/cosmos/cosmos-sdk/version.AppName=nexaraild
            -X github.com/cosmos/cosmos-sdk/version.Version=v0.1.0-testnet' \
  -o build/nexaraild-linux-amd64 ./cmd/nexaraild

# Linux (arm64)
GOOS=linux GOARCH=arm64 go build -mod=readonly \
  -ldflags '-X github.com/cosmos/cosmos-sdk/version.Name=nexarail
            -X github.com/cosmos/cosmos-sdk/version.AppName=nexaraild
            -X github.com/cosmos/cosmos-sdk/version.Version=v0.1.0-testnet' \
  -o build/nexaraild-linux-arm64 ./cmd/nexaraild
```

## Generating Checksums

```bash
cd build/

# SHA-256 checksums
sha256sum nexaraild > SHA256SUMS
sha256sum nexaraild-linux-amd64 >> SHA256SUMS
sha256sum nexaraild-linux-arm64 >> SHA256SUMS

cat SHA256SUMS
# Example output:
# abc123...  nexaraild
# def456...  nexaraild-linux-amd64
# ghi789...  nexaraild-linux-arm64
```

## Publishing

1. Push the tag to GitHub
2. Create a GitHub Release from the tag
3. Attach binary files to the release
4. Include SHA256SUMS in the release
5. Link the release in validator communication

## How Validators Verify

### Binary Verification

```bash
# Download the binary and checksum file
wget https://github.com/Bookings-cpu/nexarail/releases/download/v0.1.0-testnet/SHA256SUMS
wget https://github.com/Bookings-cpu/nexarail/releases/download/v0.1.0-testnet/nexaraild-linux-amd64

# Verify checksum
sha256sum -c SHA256SUMS --ignore-missing
# Expected: nexaraild-linux-amd64: OK
```

### Source Verification

```bash
# Clone and checkout tag
git clone https://github.com/Bookings-cpu/nexarail.git
cd nexarail
git checkout v0.1.0-testnet

# Verify tag
git verify-tag v0.1.0-testnet  # if signed

# Build and verify
make build
./build/nexaraild version
# Expected: v0.1.0-testnet

# Run tests
go test ./...
# Expected: all pass
```

## Reproducibility

| Factor | Status |
|---|---|
| Go version | 1.22+ |
| Build flags | `-mod=readonly` ensures dependency reproducibility |
| CGO | Disabled for Linux builds (`CGO_ENABLED=0`) |
| Platform | Binaries built per-architecture |
| Checksums | SHA-256 of final binaries |

## Release Notes Template

```
# NexaRail v0.1.0-testnet — Controlled Testnet Release

## What's New
- 6 custom modules: fees, merchant, settlement, escrow, payout, treasury
- 17 REST endpoints across all custom modules
- Debug commands: debug-p2p-config, debug-live-flags, debug-module-summary
- CLI query commands for all modules

## Verification
- 15 packages, ~465 tests, all passing
- Docker rehearsal: 3 validators, height >20, peers ≥2

## Important
- This is a TESTNET release only. No mainnet is live.
- All live fund flags default to false.
- Testnet tokens have no monetary value.
- No token sale has occurred.

## Validators
- Linux hosts required (no macOS/Docker Desktop)
- See docs/testnet/CONTROLLED_VALIDATOR_REGISTRATION.md
```
