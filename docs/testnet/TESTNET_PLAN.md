# NexaRail Public Testnet Plan

**Document:** docs/testnet/TESTNET_PLAN.md
**Version:** 1.0
**Date:** 2026-05-25
**Status:** Draft — testnet not yet live

## Purpose

The NexaRail public testnet (`nexarail-testnet-1`) is a controlled environment for:
- Validating the Cosmos SDK v0.47.17 + CometBFT v0.37.18 integration
- Testing live fund flows (escrow, treasury, payout, settlement fee routing)
- Exercising governance proposals for flag enablement
- Onboarding external validators
- Gathering performance and stability data
- Identifying bugs before mainnet consideration

## Scope

### In Scope
- Multi-validator consensus (target 5-20 validators)
- All six custom modules (fees, merchant, settlement, escrow, payout, treasury)
- Live fund flows behind governance-gated flags
- Governance proposal lifecycle testing
- Faucet distribution
- Block explorer
- Public RPC / REST / gRPC endpoints
- Validator onboarding and gentx collection
- Bug reporting and triage

### Non-Goals
- Mainnet launch or mainnet-equivalent security
- Token sales, airdrops, or economic value
- Stablecoin or bridge modules
- Validator distribution (deferred)
- Fee router / BeginBlock routing (deferred)
- Performance benchmarking at scale
- Legal or regulatory approval
- Investment or profit guarantees

## Timeline

| Phase | Duration | Description |
|---|---|---|
| Pre-launch | 1-2 weeks | Genesis ceremony, validator onboarding, gentx collection |
| Launch | 1 day | Genesis publication, coordinated start |
| Stability | 2-4 weeks | Monitoring, bug fixes, validator coordination |
| Feature testing | 4-8 weeks | Progressive live flag enablement via governance |
| Teardown | 1 week | State export, lessons learned, mainnet prep |

## Participant Types

| Role | Description |
|---|---|
| Core validators | NexaRail team. Operate 2-3 initial validators. |
| Community validators | External operators. Target 5-15. |
| Developers | Test dApp integration, query APIs, submit transactions. |
| Testers | Exercise features, report bugs, test edge cases. |
| Observers | Monitor chain health, governance, documentation quality. |

## Validator Requirements

See `VALIDATOR_ONBOARDING.md` for detailed requirements.

Minimum for community validators:
- 2+ vCPU, 4 GB RAM, 100 GB SSD
- Ubuntu 22.04 or macOS 14+
- Static IP or reliable DNS
- `nexaraild` binary built from source
- Validator key created and gentx submitted during ceremony window

## Faucet Plan

See `FAUCET_PLAN.md`.

Initial allocation: testnet-only unxrl distributed via web faucet and Discord bot to validator and developer accounts. Rate-limited to prevent abuse. No economic value.

## Explorer Plan

See `EXPLORER_AND_RPC.md`.

Options: self-hosted block explorer (Ping.pub, Big Dipper, or custom) or lightweight API dashboard. Public RPC, REST, and gRPC endpoints provided by core validators.

## RPC / API Plan

See `EXPLORER_AND_RPC.md`.

At minimum:
- RPC: `https://rpc.testnet.nexarail.network` (core team)
- REST: `https://rest.testnet.nexarail.network`
- gRPC: `https://grpc.testnet.nexarail.network`
- Community validators encouraged to provide additional endpoints

## Governance Test Plan

See `GOVERNANCE_TESTING.md`.

Progressive enablement of live flags via governance proposals:
1. Enable settlement `LiveEnabled` → test merchant transfers
2. Enable escrow `LiveEnabled` → test custody
3. Enable settlement `TreasuryRoutingEnabled` → test treasury accumulation
4. Enable treasury `LiveEnabled` → test spend execution
5. Enable payout `LiveEnabled` → test payout execution
6. Enable settlement `BurnRoutingEnabled` → test supply reduction

All enablements followed by disablement proposals to test rollback.

## Live Funds Flag Testing Plan

| Order | Flag | Module | Test Focus |
|---|---|---|---|
| 1 | `LiveEnabled` | x/settlement | Merchant-net transfers |
| 2 | `LiveEnabled` | x/escrow | Escrow custody lifecycle |
| 3 | `TreasuryRoutingEnabled` | x/settlement | Treasury fee accumulation |
| 4 | `LiveEnabled` | x/treasury | Spend execution from treasury |
| 5 | `LiveEnabled` | x/payout | Payout execution |
| 6 | `BurnRoutingEnabled` | x/settlement | Supply reduction verification |

## Bug Reporting Process

See `BUG_BOUNTY_DRAFT.md`.

- GitHub Issues with bug report template
- Security vulnerabilities → responsible disclosure (security@ or GitHub Security Advisory)
- Testnet-only: no monetary bounties unless separately announced
- Severity: Critical / High / Medium / Low

## Reset Policy

The testnet may be reset at any time for:
- Critical bug fixes requiring state migration
- Genesis parameter changes
- Software upgrades requiring fresh state

Reset procedure:
1. Announce reset 48 hours in advance (Discord / GitHub)
2. Export state if meaningful
3. New genesis published
4. Validators re-sync or re-initialise
5. Old chain ID retired; new chain ID used (nexarail-testnet-2, -3, etc.)

## Testnet Success Criteria

- [ ] 5+ external validators joined and produced blocks
- [ ] All 6 custom modules exercised via governance
- [ ] All live fund flows tested end-to-end
- [ ] No critical consensus bugs discovered
- [ ] Governance proposals passed and executed
- [ ] Faucet distributed testnet tokens without abuse
- [ ] Block explorer functional
- [ ] RPC/REST/gRPC endpoints stable
- [ ] Validator onboarding documentation validated by external participants
- [ ] Bug reports triaged and addressed
- [ ] Lessons learned documented for mainnet preparation
