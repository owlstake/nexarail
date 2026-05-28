# Phase 9A — Validator Cohort Formation

**Date:** 2026-05-26 15:23 BST
**Status:** Active — forming first controlled validator cohort
**Chain:** nexarail-testnet-1

---

## Current Status

| Metric | Value |
|---|---|
| Technical readiness | ✅ GO (Phase 8G confirmed) |
| Operational launch | 🔴 NO-GO |
| Applications received | 0 |
| Accepted validators | 0 |
| Gentxs received | 0 |
| Gentxs valid | 0 |
| Genesis candidate | ⬜ Not built |
| Chain codebase | ✅ ~497 tests, 15 packages, all passing |
| Predeployment check | ✅ 23/23 |

## Target Validator Count

| Cohort Size | Viability | Fault Tolerance |
|---|---|---|
| 3 | Minimum | 0 (all must be online) |
| 5 | Preferred | 1 can be offline |
| 7 | Strong | 2 can be offline |
| 10 | Maximum first cohort | 3 can be offline |

## Minimum Viable Cohort: 3 Validators

With 3 validators, consensus requires all 3 to be online (+2/3 of 3 = 3). This is fragile — any validator offline halts the chain. Acceptable for a controlled testnet's first cohort, but the goal is to grow beyond 3 quickly.

## Preferred Validator Profile

| Attribute | Required | Preferred |
|---|---|---|
| Infrastructure | Linux host (4+ vCPU, 8+ GB RAM, 100+ GB SSD) | 8+ vCPU, 16+ GB RAM |
| Networking | Static public IP, ports 26656/26657 open | Redundant connections |
| Experience | 1+ year validator experience | Cosmos SDK specific |
| Communication | Responsive (Discord/Telegram) | Emergency contact available |
| Commitment | Testnet-only understanding explicit | Interest in longer-term participation |
| Diversity | — | Unique geographic region, hosting provider |

## Acceptance Process

1. Application received via GitHub Issue, forum, or direct contact
2. Initial red-flag screen (48h SLA)
3. Technical review against scoring rubric (5-day SLA)
4. Decision: accepted, more info needed, or rejected
5. Accepted validator receives onboarding package
6. Validator completes acceptance checklist
7. Validator generates keys and submits gentx
8. Coordinator verifies gentx (22-point checklist)
9. Gentx included in genesis candidate
10. Launch coordination begins

## Gentx Collection Process

1. Validator initialises node: `nexaraild init <moniker> --chain-id nexarail-testnet-1`
2. Validator generates keys and records node ID
3. Coordinator funds validator account in genesis
4. Validator creates gentx: `nexaraild gentx <key> 500000000unxrl`
5. Validator submits gentx via designated channel
6. Coordinator runs: `scripts/testnet/verify-submitted-gentx.sh <gentx>`
7. If valid: included in genesis draft
8. If invalid: returned with specific reason, re-submission window open
9. All gentxs collected, genesis assembled: `scripts/testnet/assemble-testnet-genesis.sh`
10. Genesis validated: `scripts/testnet/check-final-genesis.sh`

## Daily Tracking

Update each day:
- Applications received today
- Reviews completed
- Validators accepted
- Gentxs received
- Gentxs validated
- Blockers
- Next actions

Track in: `docs/testnet/GENTX_COLLECTION_DAILY_LOG.md`

## GO / NO-GO Criteria

### GO for Genesis Assembly
- [ ] ≥ 3 validators accepted
- [ ] All validators confirmed Linux hosts
- [ ] All gentxs received
- [ ] All gentxs validated (22-point checklist)
- [ ] Genesis assembled and validates
- [ ] Genesis checksum published
- [ ] Launch time coordinated

### GO for Launch
- [ ] All validators acknowledged genesis checksum
- [ ] All validators confirmed binary built
- [ ] All validators in communication channel
- [ ] Peer list distributed
- [ ] Launch time confirmed by all validators
- [ ] Pre-launch freeze checklist complete
