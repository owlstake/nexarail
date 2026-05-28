# NexaRail v0.1.1-rc2 Draft Release Notes

**Status:** Draft only. Do not publish until RC2 readiness returns `RC2_GO`.

## Safety Status

NexaRail `v0.1.1-rc2` would remain a controlled local evaluation release candidate.

- Not mainnet
- Not a public testnet
- No token sale
- Devnet/testnet tokens have zero monetary value
- External validators remain pending
- Live flags remain false by default
- SDK packages are not published to npm or PyPI
- Local load results are not production throughput

## What Changed Since RC1

This draft RC2 would package post-RC1 hardening currently present on `main`:

- product module validation hardening
- governance-authority and product-toggle safety review
- params-event and error-message improvements
- expanded state-transition and invariant tests
- bounded fuzz tests and runtime invariant framework
- five-agent local validator-agent validation
- full product-flow replay evidence
- governance vote reliability fix
- restart recovery and soak validation
- local load simulation and throughput profiling
- local trend/resource profiling harness
- updated evidence and reviewer docs

## Validation Fixes

Post-RC1 validation work tightened message validation across settlement, escrow, merchant, payout, treasury, and fees surfaces. Params-event and error-message coverage were improved to make failures clearer and easier to audit.

## Governance Vote Reliability Fix

Phase 16A.7 addressed the transient Phase 16A.6 vote failure by:
- routing each validator vote through that validator's own RPC endpoint
- adding retry behavior
- refreshing sequence handling

The proposal affected by the transient vote failure still passed. A targeted replay after this fix remains recommended before tagging RC2.

## Fuzz and Invariant Tests

Phase 15A added bounded fuzz and invariant coverage for product modules and runtime invariant checks. Phase 14D expanded deterministic state-transition and invariant tests.

## Local Load Simulation Evidence

Phase 16C local five-agent load evidence:

| Run | Result |
|---|---|
| Smoke | 45 / 45 tx included, 208 / 208 queries |
| 10-minute | 220 / 220 tx included, 2330 / 2330 queries |
| Heavier | 876 / 876 tx included, 9020 / 9020 queries |

Phase 16D local trend evidence:

| Level | Result |
|---|---|
| L1 | 224 / 224 tx included, 2600 / 2600 queries |
| L2 | 448 / 448 tx included, 5030 / 5030 queries |
| L3 | 515 / 515 tx included, 7300 / 7300 queries |
| L4 | Interrupted during Phase 16E handoff; not canonical |

These are local five-agent devnet observations only.

## Known Limitations

- Public/external testnet remains NO-GO
- Mainnet remains NO-GO
- External validator rehearsal remains pending
- Canonical one-hour soak rerun remains required before RC2 tag
- Targeted governance/product-flow replay after Phase 16A.7 remains required before RC2 tag
- SDK packages remain local-only
- No wallet/private-key integration in SDKs
- Governance UX remains script-heavy
- Load results are local single-machine observations

## Proposed Assets

If RC2 proceeds:
- `nexaraild-darwin-arm64`
- `nexaraild-linux-amd64`
- `SHA256SUMS`
- release manifest
- reviewer handoff docs

## Release Decision

Current recommendation: **prepare RC2, defer tag/release** until the remaining soak and targeted governance replay gates are complete.
