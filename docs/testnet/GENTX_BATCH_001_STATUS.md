# Gentx Batch 001 — Status

**Date:** 2026-05-26
**Chain:** nexarail-testnet-1
**Status:** Awaiting accepted validators

---

## Batch Summary

| Metric | Count |
|---|---|
| Accepted validators | 0 |
| Gentxs received | 0 |
| Gentxs valid | 0 |
| Gentxs rejected | 0 |
| Resubmissions needed | 0 |
| Included in genesis | 0 |
| Genesis checksum | — |

## Validator Gentx Status

| # | Moniker | App ID | Gentx Received | Valid | Issues | Resubmission | Files Included | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | — | — | ⬜ | ⬜ | — | ⬜ | ⬜ | Awaiting accepted validators |
| 2 | — | — | ⬜ | ⬜ | — | ⬜ | ⬜ | |
| 3 | — | — | ⬜ | ⬜ | — | ⬜ | ⬜ | |
| 4 | — | — | ⬜ | ⬜ | — | ⬜ | ⬜ | |
| 5 | — | — | ⬜ | ⬜ | — | ⬜ | ⬜ | |

## Verification Per Gentx

When gentxs arrive, each is verified using `scripts/testnet/verify-submitted-gentx.sh`:

| Check | Gentx-1 | Gentx-2 | Gentx-3 | Gentx-4 | Gentx-5 |
|---|---|---|---|---|---|
| JSON valid | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Chain ID = nexarail-testnet-1 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Denom = unxrl | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Self-delegation ≥ 500M | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Operator address format | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Pubkey present + ed25519 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Moniker unique | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Pubkey unique | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Commission ranges valid | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Genesis validates | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

## Genesis Checksum

| Date | Checksum | Validator Count |
|---|---|---|
| — | — | — |

## Next Actions

1. Accept validators (awaiting applications)
2. Send onboarding package to accepted validators
3. Open gentx submission window
4. Verify each gentx on arrival
5. Assemble genesis when all gentxs verified
6. Publish checksum
7. Coordinate launch
