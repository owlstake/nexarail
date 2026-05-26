# NexaRail Testnet Bug Bounty — Draft

**Document:** docs/testnet/BUG_BOUNTY_DRAFT.md
**Version:** 1.0-draft
**Date:** 2026-05-25
**Status:** Draft framework — requires legal review before publication

## Scope

The NexaRail testnet bug bounty covers:

| In Scope | Out of Scope |
|---|---|
| `nexaraild` binary (Cosmos SDK + CometBFT) | Social engineering attacks |
| Custom modules: fees, merchant, settlement, escrow, payout, treasury | Physical security |
| Live fund flows (escrow, treasury, payout, settlement) | Third-party infrastructure (GitHub, Discord, hosting) |
| Governance module integration | Denial of service (rate limiting is not in scope) |
| State machine invariants | Cosmos SDK / CometBFT upstream bugs (report to those projects) |
| Genesis and state export/import | Front-end / explorer bugs (unless they affect chain state) |
| Transaction validation and fee handling | Testnet-only economic attacks (no real value) |

## Severity Levels

| Severity | Definition | Example |
|---|---|---|
| Critical | Chain halt, consensus failure, irreversible fund loss | Double-spend via state machine bug, BurnCoins draining arbitrary accounts |
| High | Unauthorised fund movement, invariant violation, governance bypass | Unauthorised escrow release, treasury drain without spend approval |
| Medium | Incorrect fee calculation, flag bypass, state inconsistency | Settlement stored without bank transfer, LiveEnabled bypass |
| Low | Cosmetic bugs, misleading events, documentation errors | Event attribute missing, off-by-one in query pagination |

## Testnet Rewards

Testnet bug bounties are **recognition-based**. No monetary rewards are guaranteed. Contributions are acknowledged in:
- GitHub release notes
- Testnet participant leaderboard
- Priority consideration for mainnet validator set (future)

Monetary bounties may be considered post-audit and pre-mainnet. This document will be updated if a paid bounty programme is launched.

## Responsible Disclosure

1. **Do not exploit** the bug on the public testnet (use local devnet for verification)
2. Report via GitHub Security Advisory: `Security > Report a vulnerability`
3. Or email: `security@nexarail.network` (TBD)
4. Include: description, steps to reproduce, impact, suggested fix
5. Allow 90 days for remediation before public disclosure
6. Core team will acknowledge within 72 hours

## Prohibited Behaviour

- Exploiting bugs on the public testnet for any purpose other than verification
- Accessing other validators' keys or infrastructure
- Social engineering core team or validators
- Public disclosure before remediation window (90 days)
- Testing on mainnet (mainnet does not exist)

## Safe Harbour

*This section requires legal review.*

NexaRail will not pursue legal action against security researchers who:
- Act in good faith
- Follow responsible disclosure
- Do not cause harm to the testnet or other participants
- Do not access or exfiltrate private data
