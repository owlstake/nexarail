# Gentx Submission Window — NexaRail Testnet

**Chain:** nexarail-testnet-1
**Phase:** 7D — Gentx Coordination
**Status:** Window open when first validator is accepted

---

## Gentx Submission Window

| Parameter | Value |
|---|---|
| Window opens | Upon first validator acceptance |
| Window duration | 7-14 days (coordinator discretion) |
| Deadline | [Date/Time UTC — set by coordinator] |
| Late submissions | Not accepted — validator excluded from genesis |
| Extensions | At coordinator discretion for technical issues only |

## Window Timeline

```
Day 0      First validator accepted
Day 0-1    Acceptance notifications sent
Day 1-3    Validators build binary, generate keys
Day 3-7    Gentx submissions received
Day 5      Gentx reminder (Template E) to non-submitters
Day 7      Gentx deadline (recommended minimum)
Day 7-9    Gentx verification (22-point checklist)
Day 9-10   Request resubmissions if needed
Day 10-12  Final genesis build
Day 12-14  Genesis checksum published, peer list distributed
Day 14+    Coordinated launch at T-0
```

## Gentx Requirements

Each accepted validator must submit:

| Item | Requirement |
|---|---|
| File format | Valid JSON gentx file |
| Moniker | Matching application moniker |
| Chain ID | `nexarail-testnet-1` |
| Self-delegation | ≥ 500,000,000 unxrl |
| Denom | `unxrl` |
| Commission rate | 0.00 – 0.20 |
| Commission max rate | 0.00 – 0.20 |
| Commission max change rate | 0.00 – 0.10 |
| Signature | Valid cryptographic signature |
| Submission channel | As specified by coordinator |

## Submission Instructions

See `docs/testnet/GENESIS_SUBMISSION_INSTRUCTIONS.md` for the complete step-by-step guide.

Quick reference:
```bash
nexaraild init <moniker> --chain-id nexarail-testnet-1
nexaraild keys add <key-name>
# Wait for coordinator to fund your account
nexaraild gentx <key-name> 500000000unxrl \
  --chain-id nexarail-testnet-1 \
  --commission-rate 0.05 \
  --commission-max-rate 0.20 \
  --commission-max-change-rate 0.01
```

## Verification Process

All gentxs are verified against the 22-point checklist in `GENESIS_GENTX_REVIEW_CHECKLIST.md`.

| Check Category | Items |
|---|---|
| Identity | Moniker present, not duplicated, operator address valid |
| Consensus | Pubkey present, type ed25519, not duplicated |
| Delegation | Denom = unxrl, amount ≥ 500M, account funded |
| Chain | Chain ID = nexarail-testnet-1, account in genesis |
| Commission | Rate ≤ max-rate, within ranges |
| Signature | Valid, genesis validates after inclusion |

## Common Issues

| Issue | Resolution |
|---|---|
| Wrong chain ID | Regenerate gentx with correct `--chain-id` |
| Account not funded | Contact coordinator for genesis allocation |
| Insufficient self-delegation | Increase amount to ≥ 500,000,000 unxrl |
| Duplicate moniker | Choose a unique moniker |
| Gentx file corrupted | Regenerate from clean state |
| Commission rate > max | Reduce commission rate or increase max rate |

## Late or Missing Submissions

| Situation | Action |
|---|---|
| No gentx by deadline | Validator excluded from genesis |
| Validator requests extension (technical issue) | Coordinator may grant up to 48 hours |
| Validator requests extension (non-technical) | Declined — deadline is firm |
| Validator withdraws before deadline | Slot may be offered to waitlisted applicant |
| Gentx rejected after deadline | Validator excluded — no re-submission window |

## Coordinator Actions During Window

- [ ] Monitor gentx submissions daily
- [ ] Verify each gentx within 3 days of receipt
- [ ] Send reminder (Template E) 48 hours before deadline
- [ ] Request re-submissions for rejected gentxs (before deadline only)
- [ ] Track all submissions in `GENESIS_VALIDATOR_SET_DRAFT.md`
- [ ] After deadline: begin genesis build

## Post-Deadline

After the submission window closes:

1. All verified gentxs collected in `rehearsals/testnet-1/gentx-collection/`
2. Genesis built using `collect-gentxs`
3. Genesis validated
4. Checksum generated and published
5. Peer list compiled from accepted validators' node IDs
6. Launch time announced
7. Launch coordination begins (Template F)

## Emergency Gentx Reset

If a critical issue is found with the genesis after the deadline but before launch:

1. Coordinator declares emergency reset
2. New gentx window opens (3-5 days)
3. All validators must re-submit gentxs
4. New genesis built and published
5. New launch time announced

Resets are exceptional. Do not use lightly.
