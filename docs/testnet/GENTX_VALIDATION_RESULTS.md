# Gentx Validation Results — NexaRail Testnet

**Chain:** nexarail-testnet-1
**Phase:** 7D — Gentx Coordination
**Status:** Populated as gentxs are verified

---

## Validation Summary

| Metric | Count |
|---|---|
| Gentxs received | 0 |
| Gentxs verified | 0 |
| Gentxs rejected | 0 |
| Gentxs pending verification | 0 |
| Resubmissions requested | 0 |
| Included in genesis | 0 |

---

## Individual Gentx Results

| Validator | Moniker | Received | Verified | Result | Issues | Resubmitted | Final Status |
|---|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — | — |

---

## Verification Checklist Per Gentx

For each gentx, the 22-point checklist from `GENESIS_GENTX_REVIEW_CHECKLIST.md` is completed.

| # | Check | Expected | Pass? |
|---|---|---|---|
| **Identity** | | | |
| 1 | Moniker present and non-empty | Moniker field populated | ☐ |
| 2 | Moniker not duplicated | Unique among all accepted validators | ☐ |
| 3 | Validator operator address present | `validator_address` field populated | ☐ |
| 4 | Operator address format correct | Starts with `nxrvaloper` | ☐ |
| 5 | Operator address matches application | Same as applicant registered address | ☐ |
| **Consensus** | | | |
| 6 | Consensus pubkey present | `pubkey` field populated with `@type` | ☐ |
| 7 | Consensus pubkey not duplicated | Unique among all accepted validators | ☐ |
| 8 | Pubkey type is ed25519 | `@type: /cosmos.crypto.ed25519.PubKey` | ☐ |
| **Delegation** | | | |
| 9 | Self-delegation denom correct | `unxrl` | ☐ |
| 10 | Self-delegation amount sufficient | ≥ 500,000,000 unxrl | ☐ |
| 11 | Self-delegation amount matches application | Matches declared amount (or higher) | ☐ |
| **Chain** | | | |
| 12 | Chain ID correct | `nexarail-testnet-1` | ☐ |
| 13 | Account has genesis allocation | Address present in genesis accounts | ☐ |
| 14 | Account balance ≥ self-delegation | Balance sufficient to cover delegation | ☐ |
| **Commission** | | | |
| 15 | Commission rate within range | 0.00 – 0.20 (rate ≤ max-rate) | ☐ |
| 16 | Max commission rate within range | 0.00 – 0.20 | ☐ |
| 17 | Max change rate within range | 0.00 – 0.10 | ☐ |
| 18 | Commission params match application | Consistent with declared values | ☐ |
| **Signature** | | | |
| 19 | Gentx signature valid | JSON parses without error | ☐ |
| 20 | Gentx is a valid protobuf message | `@type` = `/cosmos.staking.v1beta1.MsgCreateValidator` | ☐ |
| **Genesis Integration** | | | |
| 21 | Genesis validates after including this gentx | `nexaraild validate-genesis` passes | ☐ |
| 22 | No duplicate gentx for same operator | Only one gentx per validator | ☐ |

---

## Verification Commands Log

```
# Run these for each gentx and record results below:

# Check gentx contents
python3 -c "import json; g=json.load(open('gentx.json')); ..."

# Validate genesis with all gentxs
./build/nexaraild collect-gentxs
./build/nexaraild validate-genesis

# Count gentxs in genesis
python3 -c "import json; g=json.load(open('genesis.json')); print(len(g['app_state']['genutil']['gen_txs']))"
```

### Command Log

| Date | Command | Result |
|---|---|---|
| — | — | — |

---

## Rejected Gentx Resolution

| Validator | Reason | Resolution | Outcome |
|---|---|---|---|
| — | — | — | — |

---

## Final Genesis Build Verification

| Check | Result |
|---|---|
| All accepted validators have verified gentxs | ⬜ |
| `collect-gentxs` completed without error | ⬜ |
| `validate-genesis` passes | ⬜ |
| gentx count matches accepted validator count | ⬜ |
| Genesis checksum generated | ⬜ |
| Checksum published to validators | ⬜ |

---

## Notes

- This document is the audit trail for gentx verification
- Record every verification step — not just pass/fail
- If a gentx is rejected, document the exact reason and resolution
- Archive this document after genesis launch
