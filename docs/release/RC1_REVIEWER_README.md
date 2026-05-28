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

## Developer Resources

| Resource | Description |
|---|---|
| [Developer Quickstart](../developers/DEVELOPER_QUICKSTART.md) | Building against the devnet |
| [API Examples](../developers/API_EXAMPLES.md) | Curl examples for all REST endpoints |
| [Product Flow Examples](../developers/PRODUCT_FLOW_EXAMPLES.md) | Full product flows with commands |
| [REST Examples (scripts)](../../examples/rest/) | Read-only example scripts (bash + curl) |
| [Node.js Client](../../examples/node-client/) | Lightweight Node.js client (no deps) |
| [Python Client](../../examples/python-client/) | Lightweight Python client (stdlib only) |
| [Local Dashboard](../../examples/dashboard/) | Read-only local devnet dashboard (static HTML/JS/CSS) |
| [SDK Package Preparation](../developers/SDK_PACKAGE_PREPARATION.md) | Local SDK packaging status — Node + Python, `0.1.0-dev`, local install only, no publishing |

## End-to-End Local Demo

Run a complete walkthrough that launches a local devnet, queries via REST/SDK, runs write-flow dry-runs, and inspects the dashboard:

```bash
scripts/dev/run-end-to-end-demo.sh
```

Evidence is saved to `rehearsals/end-to-end-demo/evidence/<timestamp>/`.

## Developer Portal

Browse the NexaRail documentation as a static website:

```bash
# Build
bash scripts/dev/build-developer-portal.sh

# Serve on port 8090
bash scripts/dev/serve-developer-portal.sh
```

## Developer Onboarding Bundle

Download all developer assets in one archive:

```bash
scripts/dev/prepare-developer-bundle.sh
```

The bundle includes: RC1 docs, SDK archives, examples, scripts, manifests, and contributor guides.

See [Contributing Guide](../../CONTRIBUTING.md) and [Onboarding Checklist](../developers/ONBOARDING_CHECKLIST.md).

## SDK Documentation

SDK documentation for local developer integration:

| Resource | Description |
|---|---|
| [SDK RC1 Release Notes](../developers/SDK_RC1_RELEASE_NOTES.md) | Release notes covering changes, installation, and usage |
| [Node.js SDK API Reference](../developers/NODE_SDK_API_REFERENCE.md) | Full API reference for `@nexarail/devnet-client` |
| [Python SDK API Reference](../developers/PYTHON_SDK_API_REFERENCE.md) | Full API reference for `nexarail-devnet-client` |
| [SDK Recipes](../developers/SDK_RECIPES.md) | Common usage patterns and integration examples |
| [Local Package Archive](../../releases/sdk-local/) | Local SDK tarballs — **NOT** published to npm or PyPI |

## Quick Regression Checks

Run these to confirm the package is intact:

```bash
# Fast checks (no devnet needed):
scripts/dev/run-nexarail-regression-matrix.sh --fast

# Full checks (with devnet):
scripts/dev/run-nexarail-regression-matrix.sh --full --with-devnet
```

See [Regression Matrix](../developers/DEMO_REGRESSION_MATRIX.md) for expected pass counts.

## Contact / Support

_Genesis coordinator contact: [placeholder — insert contact details here]_

For technical issues during review, please refer to the evidence manifest and quickstart guide first.
