# Phase 17B Validator Intake And Genesis Candidate

**Date:** 2026-05-29
**Network:** `nexarail-testnet-1`
**Status:** intake workspace ready, awaiting external submissions

## Objective

Move from launch-candidate preparation to real external-validator coordination by collecting non-secret intake records, validating submitted gentxs, generating persistent peers, and assembling a final controlled-testnet genesis candidate only after verified gentxs exist.

## Current Counts

| Item | Count / Status |
|---|---|
| Validator intake records submitted | 0 |
| Gentxs submitted | 0 |
| Gentxs verified | 0 |
| Gentxs rejected | 0 |
| Genesis candidate | Not assembled; waiting for verified gentxs |
| Persistent peers | Waiting for complete intake records |
| Launch status | NOT LAUNCHED |

## Coordination Workspace

| Path | Purpose |
|---|---|
| `coordination/validators/validator-intake.csv` | Intake registry header, currently empty. |
| `coordination/validators/gentxs/` | Submitted gentxs awaiting validation. |
| `coordination/validators/verified/` | Verified gentxs and intake validation summaries. |
| `coordination/validators/rejected/` | Rejected gentxs and reason files. |
| `coordination/validators/peer-info/` | Persistent peer output. |

The workspace must not contain private keys, mnemonics, node keys, validator signing keys, keyring files, SSH keys, node data, or database files.

## Validation Commands

```bash
scripts/testnet/validate-validator-intake.sh
scripts/testnet/generate-persistent-peers.sh \
  --input coordination/validators/validator-intake.csv \
  --output coordination/validators/peer-info
```

If verified gentxs are present, assemble a final genesis candidate with:

```bash
scripts/testnet/assemble-controlled-testnet-genesis.sh \
  --gentx-dir coordination/validators/verified \
  --chain-id nexarail-testnet-1 \
  --output-dir releases/testnet-genesis/nexarail-testnet-1
```

Do not assemble or publish a final genesis candidate while verified gentx count is zero.

## Missing Items

- Accepted external-validator intake records.
- Submitted `gentx-*.json` files.
- Verified gentx set.
- Persistent peer list from complete node IDs and public hosts.
- Final genesis candidate checksum.
- Launch window.
- First-block, first-10-block, first-100-block, and first-hour external evidence.

## Current Decision

The controlled external-validator testnet remains **not launched**. Phase 17B is ready for real intake and gentx submissions, but final genesis publication and launch coordination are blocked until validated external gentxs exist.

## Next Steps

1. Send accepted validators `docs/testnet/EXTERNAL_VALIDATOR_ACTION_PACK.md` and `docs/testnet/VALIDATOR_SUBMISSION_CHECKLIST.md`.
2. Collect non-secret intake fields into `coordination/validators/validator-intake.csv`.
3. Store submitted gentxs in `coordination/validators/gentxs/`.
4. Run `scripts/testnet/validate-validator-intake.sh`.
5. Generate persistent peers after complete node ID and host records exist.
6. Assemble final genesis candidate only after gentxs are verified.
