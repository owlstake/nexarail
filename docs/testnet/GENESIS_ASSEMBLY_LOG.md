# Genesis Assembly Log — NexaRail Testnet

**Chain:** nexarail-testnet-1
**Phase:** 7F — Gentx Collection & Final Candidate
**Status:** ⬜ Awaiting gentx collection — scripts tested and ready

---

## Genesis Summary

| Field | Value |
|---|---|
| Chain ID | `nexarail-testnet-1` |
| Denom | `unxrl` |
| Bech32 Prefix | `nxr` |
| Base Genesis Commit | Main branch, current HEAD |
| Gentx Collection Path | `rehearsals/testnet-1/gentx-collection/` |
| Final Genesis Path | `rehearsals/testnet-1/genesis/genesis.json` |
| Checksum File | `rehearsals/testnet-1/genesis/genesis-checksum.txt` |

---

## Validator Counts

| Metric | Count |
|---|---|
| Accepted validators | 0 |
| Gentxs received | 0 |
| Gentxs verified | 0 |
| Gentxs rejected | 0 |
| Validators in final genesis | 0 |

---

## Gentx Inclusion Log

| # | File | Moniker | Operator Address | Pubkey (first 16) | Self-Delegation | Verified | Included |
|---|---|---|---|---|---|---|---|
| 1 | — | — | — | — | — | ⬜ | ⬜ |
| 2 | — | — | — | — | — | ⬜ | ⬜ |
| 3 | — | — | — | — | — | ⬜ | ⬜ |

---

## Assembly Commands

```bash
# 1. Start from clean base genesis
./build/nexaraild init coordinator --chain-id nexarail-testnet-1

# 2. Add validator accounts
./build/nexaraild add-genesis-account <addr1> 1000000000000unxrl
./build/nexaraild add-genesis-account <addr2> 1000000000000unxrl
# ... for each validator

# 3. Copy all verified gentxs
cp rehearsals/testnet-1/gentx-collection/final/*.json ~/.nexarail/config/gentx/

# 4. Collect gentxs
./build/nexaraild collect-gentxs

# 5. Set parameters
TMP=$(mktemp)
jq '.app_state.staking.params.bond_denom = "unxrl" |
    .app_state.gov.voting_params.voting_period = "60s" |
    .app_state.crisis.constant_fee.denom = "unxrl"' \
    ~/.nexarail/config/genesis.json > "$TMP" && mv "$TMP" ~/.nexarail/config/genesis.json

# 6. Validate
./build/nexaraild validate-genesis

# 7. Count gentxs
python3 -c "
import json
g = json.load(open('$HOME/.nexarail/config/genesis.json'))
print(f'gen_txs: {len(g[\"app_state\"][\"genutil\"][\"gen_txs\"])}')
"

# 8. Copy to final location
mkdir -p rehearsals/testnet-1/genesis/
cp ~/.nexarail/config/genesis.json rehearsals/testnet-1/genesis/genesis.json

# 9. Generate checksum
sha256sum rehearsals/testnet-1/genesis/genesis.json > rehearsals/testnet-1/genesis/genesis-checksum.txt
cat rehearsals/testnet-1/genesis/genesis-checksum.txt
```

---

## Assembly Log

| Step | Command | Timestamp | Result | Notes |
|---|---|---|---|---|
| 1 | `nexaraild init coordinator` | — | — | — |
| 2 | `add-genesis-account` ×N | — | — | — |
| 3 | Copy gentxs | — | — | — |
| 4 | `collect-gentxs` | — | — | — |
| 5 | Set params (bond, voting, crisis) | — | — | — |
| 6 | `validate-genesis` | — | — | — |
| 7 | Count gentxs | — | — | — |
| 8 | Copy to final location | — | — | — |
| 9 | Generate checksum | — | — | — |

---

## Final Genesis Checksums

| Date | Checksum (SHA-256) | Validator Count | Notes |
|---|---|---|---|
| — | — | — | — |

---

## Genesis Published To Validators

| Validator | Moniker | Date Published | Acknowledged | Notes |
|---|---|---|---|---|
| — | — | — | ⬜ | — |

---

## Genesis Account Allocations

| Address | Purpose | Amount (unxrl) |
|---|---|---|
| — | Validator self-delegation | 1,000,000,000,000 |
| — | Faucet | 100,000,000,000,000 |
| — | Coordinator / core | 500,000,000,000,000 |

---

## Coordinator Signature

I, [Coordinator Name], confirm that the genesis file published at `rehearsals/testnet-1/genesis/genesis.json` with checksum `[checksum]` is the final genesis for `nexarail-testnet-1`.

**Signed:** ________________  
**Date:** ________________

---

## Notes

- This document is the definitive record of genesis assembly
- Every step must be logged with timestamp and result
- Archive after launch for audit trail
