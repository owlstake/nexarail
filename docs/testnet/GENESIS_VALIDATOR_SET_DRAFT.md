# Genesis Validator Set Draft — NexaRail Testnet

**Chain:** nexarail-testnet-1
**Phase:** 7E — Gentx Collection & Genesis Assembly
**Status:** Draft — populated as validators are accepted

---

## ⚠️ Confidential

This document contains validator contact details and infrastructure information. Do not share publicly. Share only the final genesis file and peer list with accepted validators.

---

## Validator Set

| # | Moniker | Operator | Address | Pubkey | Self-Delegation | Commission | Gentx Received | Gentx Validated | Resubmission Needed | Final Included | Launch Acknowledged | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | — | — | — | — | — | — | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | — |
| 2 | — | — | — | — | — | — | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | — |
| 3 | — | — | — | — | — | — | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | — |
| 4 | — | — | — | — | — | — | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | — |
| 5 | — | — | — | — | — | — | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | — |
| 6 | — | — | — | — | — | — | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | — |
| 7 | — | — | — | — | — | — | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | — |

---

## Gentx Status Key

| Status | Meaning |
|---|---|
| `pending` | Validator accepted, gentx not yet submitted |
| `submitted` | Gentx received, awaiting verification |
| `verified` | Gentx passed all 22 verification checks |
| `rejected` | Gentx failed verification — re-submission needed |
| `included` | Gentx included in genesis build |
| `expired` | Gentx not received by deadline — slot released |

## Commission Parameters

| Validator | Rate | Max Rate | Max Change Rate |
|---|---|---|---|
| — | — | — | — |

## Node IDs

| Moniker | Node ID | Public IP | P2P Port |
|---|---|---|---|
| — | — | — | 26656 |

## Genesis Checksums

| Date | Checksum (SHA-256) | Notes |
|---|---|---|
| — | — | — |

## Peer List

```
# Format: <node-id>@<ip>:26656
# Generated after all gentxs verified
```

---

## Launch Coordination

| Field | Value |
|---|---|
| Launch Date/Time | [TBD] |
| Launch Height | 1 (genesis) |
| Chain ID | nexarail-testnet-1 |
| Genesis Checksum | [TBD] |
| Minimum Gas Price | 0.025unxrl |

## Post-Launch Verification

| Check | Status |
|---|---|
| All validators started at T-0 | ⬜ |
| Block 1 produced within 30s | ⬜ |
| All validators in validator set | ⬜ |
| All validators have ≥ N-1 peers | ⬜ |
| Block time consistent (~5-6s) | ⬜ |
| No panics in first 100 blocks | ⬜ |
| Chain ID confirmed | ⬜ |

## Notes

- This document is the source of truth for the genesis validator set
- Update in real time as validators progress through the intake pipeline
- Gentx files stored at: `rehearsals/testnet-1/gentx-collection/`
- Final genesis published 48+ hours before T-0
- Validators must verify genesis checksum before launch
