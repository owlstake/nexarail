# Final Genesis Candidate Report — NexaRail Testnet

**Date:** 2026-05-26
**Status:** ⬜ AWAITING GENTX COLLECTION
**Chain:** nexarail-testnet-1

---

## Candidate Status

| Field | Value |
|---|---|
| Genesis candidate built | ⬜ No — awaiting gentxs |
| Chain ID | `nexarail-testnet-1` |
| Genesis file path | `rehearsals/testnet-1/genesis/genesis.json` (not yet created) |
| Checksum | — |
| Checksum file | `rehearsals/testnet-1/genesis/genesis-checksum.txt` (not yet created) |

## Validator Set

| Metric | Target | Actual |
|---|---|---|
| Minimum validators | 3 | 0 |
| Target validators | 5 | 0 |
| Maximum validators | 7 | 0 |
| Gen_txs in genesis | ≥ 3 | 0 |

## Configuration

| Parameter | Value |
|---|---|
| Chain ID | `nexarail-testnet-1` |
| Denom | `unxrl` |
| Bech32 Prefix | `nxr` |
| Bond Denom | `unxrl` |
| Voting Period | 60s |
| Minimum Gas Price | 0.025unxrl |
| Crisis Fee Denom | `unxrl` |

## Live Flag Status

| Module | Flag | Target | Actual |
|---|---|---|---|
| Settlement | `live_enabled` | false | — |
| Settlement | `treasury_routing_enabled` | false | — |
| Settlement | `burn_routing_enabled` | false | — |
| Escrow | `live_enabled` | false | — |
| Treasury | `live_enabled` | false | — |
| Payout | `live_enabled` | false | — |

All 6 flags must be `false` in the final genesis.

## Module Genesis Status

| Module | Present | Status |
|---|---|---|
| fees | ✅ | In genesis template |
| merchant | ✅ | In genesis template |
| settlement | ✅ | In genesis template |
| escrow | ✅ | In genesis template |
| treasury | ✅ | In genesis template |
| payout | ✅ | In genesis template |

## Assembly Commands (to be run)

```bash
# 1. Receive and validate all gentxs
for gentx in rehearsals/testnet-1/gentx-collection/*.json; do
    ./scripts/testnet/verify-submitted-gentx.sh "$gentx" registry.json
done

# 2. Move verified gentxs to final collection
mkdir -p rehearsals/testnet-1/gentx-collection/final/
cp <verified-gentxs> rehearsals/testnet-1/gentx-collection/final/

# 3. Assemble genesis
./scripts/testnet/assemble-testnet-genesis.sh

# 4. Verify final genesis
./scripts/testnet/check-final-genesis.sh rehearsals/testnet-1/genesis/genesis.json

# 5. Verify live flags
python3 -c "
import json
g = json.load(open('rehearsals/testnet-1/genesis/genesis.json'))
for mod, flag in [('settlement','live_enabled'),('settlement','treasury_routing_enabled'),
                   ('settlement','burn_routing_enabled'),('escrow','live_enabled'),
                   ('treasury','live_enabled'),('payout','live_enabled')]:
    v = g['app_state'][mod]['params'][flag]
    assert v == False, f'{mod}.{flag} = {v} (expected False)'
print('All 6 live flags: false ✅')
"
```

## Validation Output Summary

```
# No genesis candidate built yet
```

## Freeze Status

| Item | Status |
|---|---|
| Code frozen | ✅ No protocol changes since Phase 6J.2 |
| Genesis frozen | ⬜ Awaiting assembly |
| Docs frozen | ⬜ Awaiting final validator data |
| Validator set frozen | ⬜ Awaiting gentxs |

## Coordinator Sign-Off

```
I, ________________, confirm that the genesis file at 
rehearsals/testnet-1/genesis/genesis.json with checksum __________
is the final genesis candidate for nexarail-testnet-1.

All gentxs have been verified. All live flags default to false.
The genesis is ready for launch coordination.

Signed: ________________    Date: ________________
```

## Notes

- This document is the definitive record of the genesis candidate
- The coordinator sign-off must be completed before launch
- Once signed, no changes to genesis without full re-validation
- Archive this report after launch as the genesis audit trail
