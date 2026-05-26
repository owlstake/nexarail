# Validator Gentx Status Board — NexaRail Testnet

**Chain:** nexarail-testnet-1
**Phase:** 7F — Gentx Collection
**Status:** ⬜ Awaiting accepted validators

---

## Status Board

| ID | Moniker | Operator Address | Gentx Received | Gentx Valid | Issues Found | Resubmission Needed | Final Included | Launch Ack'd | Notes |
|---|---|---|---|---|---|---|---|---|---|
| — | — | — | ⬜ | ⬜ | — | ⬜ | ⬜ | ⬜ | No accepted validators yet |

---

## Status Legend

| Symbol | Meaning |
|---|---|
| ⬜ | Not yet / pending |
| ✅ | Complete / passed |
| ❌ | Failed / rejected |
| 🔄 | Resubmission in progress |
| ⚠️ | Issue found — under review |

## Gentx Validation Checklist Per Validator

For each validator with a received gentx, the following checks are performed:

| Check | Validator 1 | Validator 2 | Validator 3 | Validator 4 | Validator 5 |
|---|---|---|---|---|---|
| JSON valid | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Chain ID = nexarail-testnet-1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Denom = unxrl | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Self-delegation ≥ 500M | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Operator address format | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Pubkey present + ed25519 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Moniker unique | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Pubkey unique | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Commission rate ≤ max | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Commission ranges valid | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Genesis account exists | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Genesis validates | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

## Summary Statistics

| Metric | Count |
|---|---|
| Total accepted validators | 0 |
| Gentxs received | 0 |
| Gentxs valid | 0 |
| Gentxs rejected | 0 |
| Resubmissions pending | 0 |
| Included in genesis candidate | 0 |
| Launch acknowledged | 0 |

## Issue Log

| Date | Validator | Issue | Severity | Resolution | Status |
|---|---|---|---|---|---|
| — | — | — | — | — | — |

## Launch Readiness

| Validator | Environment Ready | Genesis Verified | Peer List Received | Launch Time Ack'd | Ready for T-0 |
|---|---|---|---|---|---|
| — | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

## Notes

- This board is the single source of truth for gentx collection status
- Updated in real time as gentxs are received and validated
- Coordinator uses this board during launch coordination
- Archive after launch for audit trail
