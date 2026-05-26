# Genesis Validation Report — NexaRail Testnet

**Chain:** nexarail-testnet-1
**Phase:** 7F — Gentx Collection & Final Candidate
**Status:** ⬜ Awaiting gentx collection — scripts tested and ready

---

## Validation Summary

| Metric | Count |
|---|---|
| Gentxs received | 0 |
| Gentxs passed | 0 |
| Gentxs rejected | 0 |
| Resubmissions | 0 |
| Included in genesis | 0 |

---

## Per-Gentx Validation

| # | Moniker | App ID | Operator Address | Pubkey | Delegation | Denom | Chain ID | Duplicates | Result | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | — | — | — | — | — | — | — | — | — | — |

---

## Validation Details

### Gentx #1: [Moniker]

| Check | Expected | Actual | Pass? |
|---|---|---|---|
| JSON validity | Valid JSON | — | ☐ |
| Chain ID | `nexarail-testnet-1` | — | ☐ |
| Denom | `unxrl` | — | ☐ |
| Self-delegation amount | ≥ 500,000,000 | — | ☐ |
| Operator address format | Starts with `nxrvaloper` | — | ☐ |
| Consensus pubkey present | `pubkey.key` populated | — | ☐ |
| Pubkey type | ed25519 | — | ☐ |
| Moniker unique | Not duplicated | — | ☐ |
| Pubkey unique | Not duplicated | — | ☐ |
| Commission rate ≤ max | rate ≤ max_rate | — | ☐ |
| Commission rate in range | 0.00 – 0.20 | — | ☐ |
| Max rate in range | 0.00 – 0.20 | — | ☐ |
| Max change rate in range | 0.00 – 0.10 | — | ☐ |
| Genesis account exists | Address in genesis | — | ☐ |
| Genesis validates | `validate-genesis` passes | — | ☐ |

**Result:** ☐ Pass / ☐ Fail

---

## Duplicate Checks

### Duplicate Monikers

```
(Should be empty — run moniker duplicate scan)
```

### Duplicate Pubkeys

```
(Should be empty — run pubkey duplicate scan)
```

---

## Genesis Integrity Checks

| Check | Expected | Actual | Pass? |
|---|---|---|---|
| Chain ID | `nexarail-testnet-1` | — | ☐ |
| Bond denom | `unxrl` | — | ☐ |
| Voting period | 60s | — | ☐ |
| Crisis denom | `unxrl` | — | ☐ |
| gen_txs count | = accepted validator count | — | ☐ |
| All live flags false | 6 flags = false | — | ☐ |
| Genesis validates | `validate-genesis` passes | — | ☐ |
| Checksum generated | SHA-256 | — | ☐ |

## Live Flags Verification

| Module | Flag | Default | Actual | Pass? |
|---|---|---|---|---|
| Settlement | `live_enabled` | false | — | ☐ |
| Settlement | `treasury_routing_enabled` | false | — | ☐ |
| Settlement | `burn_routing_enabled` | false | — | ☐ |
| Escrow | `live_enabled` | false | — | ☐ |
| Treasury | `live_enabled` | false | — | ☐ |
| Payout | `live_enabled` | false | — | ☐ |

## Module Presence Check

| Module | Present in genesis? |
|---|---|
| fees | — |
| merchant | — |
| settlement | — |
| escrow | — |
| treasury | — |
| payout | — |

## Genesis Checksum

| Date | Checksum (SHA-256) |
|---|---|
| — | — |

## Coordinator Verification

I, [Coordinator Name], confirm that all gentxs listed above have been reviewed and validated according to the 22-point gentx verification checklist. The genesis file assembled from these gentxs has been validated and its checksum published.

**Signed:** ________________
**Date:** ________________

---

## Notes

- This report is the audit trail for all gentx validations
- Archive after genesis launch
- Any gentx not listed here was not included in the genesis
