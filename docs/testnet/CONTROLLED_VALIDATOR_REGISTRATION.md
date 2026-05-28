# Controlled Validator Registration — NexaRail Testnet

**Status:** ⬜ OPEN (controlled, not permissionless)
**Date:** 2026-05-26
**Phase:** 7A — Registration Launch Pack

## Purpose

NexaRail is preparing controlled external validator onboarding for `nexarail-testnet-1`; launch remains pending until applicants are accepted and gentxs are collected. This is infrastructure testing — not mainnet, not a token sale, not an investment launch. Accepted validators will run nodes, test consensus stability, and exercise governance workflows before any consideration of mainnet readiness.

## ⚠️ Critical Disclaimers

- **This is NOT mainnet.** NexaRail has no public mainnet.
- **This is NOT a token sale.** No ICO, IEO, IDO, or private sale has occurred. NXRL is not offered for purchase.
- **Testnet tokens have ZERO monetary value.** They cannot be exchanged, traded, or transferred for value.
- **This is NOT an investment opportunity.** Participation is for technical testing only. No financial returns are promised or implied.
- **Testnet state may be wiped at any time.** Resets, forks, and chain restarts are expected.
- **Live fund modules are disabled by default.** No real value flows on the testnet.

## Scope

Controlled validator registration for `nexarail-testnet-1` only. Validators will:

- Run full nodes on Linux hosts
- Participate in consensus
- Vote on governance proposals
- Report bugs and performance issues
- Coordinate through designated communication channels

## Eligibility

| Requirement | Detail |
|---|---|
| Infrastructure | Linux host (amd64 or arm64), 4+ vCPU, 8+ GB RAM, 100+ GB SSD |
| Network | Static public IP, ports 26656 (P2P) and 26657 (RPC) open |
| Experience | Prior validator experience preferred (Cosmos, Tendermint, or similar) |
| Commitment | Willing to maintain uptime, respond to incidents, coordinate upgrades |
| Conduct | Agree to testnet code of conduct and security reporting process |

## Hardware Requirements

### Minimum

- CPU: 4 vCPU (amd64 or arm64)
- RAM: 8 GB
- Disk: 100 GB SSD
- Network: 100 Mbps, static public IP

### Recommended

- CPU: 8 vCPU
- RAM: 16 GB
- Disk: 200 GB NVMe
- Network: 1 Gbps

### Platform

- **Linux required** (Ubuntu 22.04+, Debian 12+, or equivalent)
- Docker is supported but production deployments should use native binaries
- **Docker Desktop on macOS is NOT suitable** for validator operation (P2P instability confirmed)

## Chain Configuration

| Parameter | Value |
|---|---|
| Chain ID | `nexarail-testnet-1` |
| Denom | `unxrl` |
| Display Ticker | `NXRL` (1 NXRL = 1,000,000 unxrl) |
| Bech32 Prefix | `nxr` |
| SDK | Cosmos SDK v0.47.17 |
| Consensus | CometBFT v0.37.18 |
| Governance | 60s voting period (testnet) |
| Bond Denom | `unxrl` |
| Min Self-Delegation | 1 unxrl |

## Validator Expectations

### Uptime

- Target: 95%+ uptime for genesis validators
- Validators offline for extended periods may be removed via governance
- No slashing for downtime during controlled testnet phase (slashing parameters are conservative)

### Slashing Risks

- Downtime slashing: 0.01% (testnet parameter — may be adjusted)
- Double-sign slashing: 5%
- Slashing is active but amounts are testnet tokens with no monetary value

### Coordination

- Respond to coordinator communications within 24h
- Participate in scheduled upgrade coordination calls
- Monitor testnet status channels
- Report issues promptly

## Application Process

1. **Review this document** in full
2. **Complete the validator application form**: `docs/testnet/VALIDATOR_APPLICATION_FORM.md`
3. **Submit application** via the designated channel (GitHub issue or form)
4. **Receive acceptance notification** with validator acceptance checklist
5. **Complete acceptance checklist**: `docs/testnet/VALIDATOR_ACCEPTANCE_CHECKLIST.md`
6. **Generate keys and gentx**: Follow `docs/testnet/GENESIS_SUBMISSION_INSTRUCTIONS.md`
7. **Submit gentx** before the deadline
8. **Participate in genesis ceremony** coordination
9. **Launch node** at coordinated time

## Timeline

| Phase | Duration | Description |
|---|---|---|
| Application Open | 7-14 days | Accept validator applications |
| Application Review | 3-5 days | Coordinator reviews and approves |
| Gentx Collection | 5-7 days | Approved validators submit gentxs |
| Genesis Build | 1-2 days | Coordinator builds and publishes genesis |
| Coordinated Launch | T-0 | All validators start simultaneously |

Timeline will be published with specific dates when sufficient applications are received.

## Communication Channels

- Primary: To be announced (Discord/Telegram)
- Technical issues: GitHub Issues
- Security reports: `security@nexarail.network` (or designated contact)
- Coordinator: Direct message to Bradley Johnston / Clove

## Acceptance Criteria

An application is accepted when:

1. All fields in the application form are complete
2. Hardware meets minimum requirements
3. Linux host confirmed
4. Operator has relevant experience or demonstrates technical capability
5. Operator agrees to code of conduct and testnet-only terms
6. Coordinator approves the application

## Rejection Reasons

Applications may be rejected if:

- Hardware does not meet minimum requirements
- Operator intends to run on macOS/Docker Desktop as primary infrastructure
- Operator makes claims about token value or investment returns
- Operator has a history of validator misbehaviour
- Application is incomplete or fraudulent
- Jurisdiction presents unacceptable legal risk

## Post-Launch

After genesis launch, validators:

- Monitor node health and performance
- Vote on governance proposals
- Test module functionality (settlement, escrow, payout, treasury — with live flags disabled)
- Report bugs via GitHub Issues
- Participate in upgrade coordination

## Contact

For questions about controlled validator registration, contact the genesis coordinator through the designated communication channel.
