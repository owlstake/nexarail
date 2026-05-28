# NexaRail RC1 — Reviewer README

## Purpose

This package is a **self-contained release candidate** for technical reviewers evaluating NexaRail's controlled testnet readiness. It bundles everything required to inspect, verify, and run a single-node devnet instance of the NexaRail blockchain.

## Current Status

**RC1 packaging complete** — controlled testnet preparation phase.  
This is a pre-release artifact for internal review only.

## What RC1 Contains

| Component | Location |
|---|---|
| Binaries (linux/amd64) | `releases/testnet-rc1/binaries/nexaraild-linux-amd64` |
| Binaries (darwin/arm64) | `releases/testnet-rc1/binaries/nexaraild-darwin-arm64` |
| SHA256 checksums | `releases/testnet-rc1/checksums/SHA256SUMS` |
| Documentation | `docs/` |
| Scripts | `scripts/release/`, `scripts/testnet/` |
| Evidence manifest | `docs/release/TESTNET_RC1_EVIDENCE_MANIFEST.md` |
| Devnet launch scripts | `scripts/release/launch-rc1-devnet.sh` |

## How to Verify Checksums

Download the RC1 package, then run:

```bash
shasum -a 256 -c releases/testnet-rc1/checksums/SHA256SUMS
```

All lines should report **OK**.

## How to Run Single-Node Devnet

```bash
bash scripts/release/launch-rc1-devnet.sh --single-node --clean
```

This starts a single NexaRail node producing blocks locally.

## Where to Find Key Documents

| Document | Path |
|---|---|
| Evidence manifest | `docs/release/TESTNET_RC1_EVIDENCE_MANIFEST.md` |
| Litepaper | `docs/NEXARAIL_LITEPAPER.md` |
| REST API documentation | `docs/api/REST_READBACK_ROUTES.md` |
| Evidence summary | `docs/release/RC1_EVIDENCE_SUMMARY.md` |
| Quickstart guide | `docs/release/RC1_QUICKSTART.md` |
| Review checklist | `docs/release/RC1_REVIEW_CHECKLIST.md` |

## What NOT to Assume

- ❌ This is **NOT** a public testnet
- ❌ This is **NOT** mainnet
- ❌ There is **NO token sale**
- ❌ External validators are **NOT** onboarded
- ❌ Live flags are **ALL false** by default
- ❌ Tokens have **zero monetary value** — they are test tokens for protocol verification only

## Current NO-GO Items

- **Public testnet:** ❌ NO-GO
- **Mainnet:** ❌ NO-GO

## Contact / Support

_Genesis coordinator contact: [placeholder — insert contact details here]_

For technical issues during review, please refer to the evidence manifest and quickstart guide first.
