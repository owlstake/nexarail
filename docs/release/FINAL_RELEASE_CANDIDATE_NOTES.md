# Final Release Candidate Notes — NexaRail Testnet

**Date:** 2026-05-26
**Version:** v0.1.0-testnet (candidate)
**Status:** Technical GO / Operational NO-GO

---

## ⚠️ Critical Disclaimer

**No mainnet is live. No token sale has occurred. Testnet tokens have zero monetary value. This is a controlled testnet release candidate for infrastructure testing only.**

---

## Version

| Field | Value |
|---|---|
| Version | v0.1.0-testnet |
| Branch | main |
| Latest commit | [Current HEAD] |
| SDK | Cosmos SDK v0.47.17 |
| Consensus | CometBFT v0.37.18 |

## Chain Configuration

| Parameter | Value |
|---|---|
| Chain ID | `nexarail-testnet-1` |
| Denom | `unxrl` |
| Ticker | `NXRL` |
| Bech32 Prefix | `nxr` |
| Bond Denom | `unxrl` |
| Voting Period | 60s |

## Binary

| OS | Arch | Name |
|---|---|---|
| Linux | amd64 | `nexaraild-linux-amd64` |
| Linux | arm64 | `nexaraild-linux-arm64` |
| macOS | arm64 | `nexaraild-darwin-arm64` |

## Build Commands

```bash
git clone https://github.com/Bookings-cpu/nexarail.git
cd nexarail
go mod tidy && go mod verify
make build  # macOS
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o build/nexaraild-linux-amd64 ./cmd/nexaraild  # Linux
```

## Checksum

```
sha256sum build/nexaraild-* > build/SHA256SUMS
```

## Live Flags — All False

| Flag | Default |
|---|---|
| settlement.live_enabled | false |
| settlement.treasury_routing_enabled | false |
| settlement.burn_routing_enabled | false |
| escrow.live_enabled | false |
| treasury.live_enabled | false |
| payout.live_enabled | false |

## Test Status

```
15 packages, ~497 tests, all pass ✅
Invariants: 14 pass ✅
Fuzz: 8 pass ✅
Randomized: 6 pass ✅
Failure injection: 6 pass ✅
Predeployment: 23/23 gates pass ✅
```

## Deferred Features

- Validator distribution (design complete)
- Stablecoin registry
- Bridge (IBC or custom)
- Fee router / BeginBlock routing
- IBC module

## Known Limitations

1. REST gateway routes manually wired (not proto-generated)
2. Rosetta API not functional for custom modules
3. macOS Docker Desktop P2P unstable (Linux required)
4. No formal third-party security audit completed
5. No legal review completed
6. State sync not tested at scale
7. In-place store migration not tested

## No-Mainnet / No-Sale Disclaimer

This release candidate is for controlled testnet infrastructure testing only. It does not constitute:
- A mainnet launch
- An offer of tokens for sale
- An investment opportunity
- A promise of future value or returns
- A permissionless network

All testnet tokens (NXRL/unxrl) have zero monetary value and cannot be exchanged or traded.

---

**This document should accompany every release.**
