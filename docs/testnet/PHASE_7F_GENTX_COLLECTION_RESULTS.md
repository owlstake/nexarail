# Phase 7F — Gentx Collection Results

**Date:** 2026-05-26
**Status:** ⬜ AWAITING ACCEPTED VALIDATORS
**Chain:** nexarail-testnet-1

---

## Collection Window

| Parameter | Value |
|---|---|
| Window status | ⬜ NOT YET OPENED |
| Window opened | — |
| Submission deadline | TBD — 7-14 days after first acceptance |
| Late submission policy | Not accepted |
| Resubmission window | Before deadline only |

## Validator Summary

| Metric | Count |
|---|---|
| Accepted validators | 0 |
| Gentxs received | 0 |
| Gentxs valid | 0 |
| Gentxs rejected | 0 |
| Resubmissions requested | 0 |
| Resubmissions received | 0 |
| Validators missing gentx at deadline | 0 |
| Final included in genesis candidate | 0 |

## Individual Validator Status

| # | App ID | Moniker | Gentx Received | Valid | Issues | Resubmission | Final | Notes |
|---|---|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — | — | No accepted validators yet |

## Gentx Validation Summary

| Check Category | Pass Rate |
|---|---|
| JSON validity | — |
| Chain ID = nexarail-testnet-1 | — |
| Denom = unxrl | — |
| Self-delegation ≥ 500M | — |
| Operator address format | — |
| Consensus pubkey present | — |
| Pubkey type ed25519 | — |
| Moniker unique | — |
| Pubkey unique | — |
| Commission ranges | — |
| Genesis validates with gentx | — |

## Validation Commands Log

```
# No gentxs received yet — validation pending
```

## Open Issues

| # | Issue | Severity | Status |
|---|---|---|---|
| 1 | No validator applications received | Blocking | ⬜ |

## Missing Validators

No validators have reached the gentx submission stage.

## Next Steps

1. Complete validator outreach (Phase 7C)
2. Receive and review applications (Phase 7D)
3. Accept qualified validators
4. Open gentx submission window
5. Receive and validate gentxs
6. Assemble genesis candidate
7. Proceed through pre-launch freeze

## Notes

- This document will be updated in real time as gentxs are received
- Validation results use `scripts/testnet/verify-submitted-gentx.sh`
- Genesis assembly uses `scripts/testnet/assemble-testnet-genesis.sh`
- Final verification uses `scripts/testnet/check-final-genesis.sh`
- The entire pipeline is scripted and tested — waiting for validators
