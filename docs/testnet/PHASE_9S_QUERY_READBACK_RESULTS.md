# Phase 9S — Query Readback Results

**Date:** 2026-05-26 22:40 BST
**Chain:** nexarail-agent-testnet-1
**Status:** Superseded by Phase 9T clean-spawn proof; live readback operational under fresh data conditions

---

## Root Cause

The IAVL version mismatch was caused by **stale LevelDB data from previous testnet runs**. When agents were restarted without wiping `data/`, the `rootmulti.Store`'s `lastCommitInfo` preserved commit version counters from prior runs. The IAVL store's internal version counter (`s/latest`) would be far ahead of the actual block height, causing `CacheMultiStoreWithVersion(height)` to fail because the IAVL tree requested version N but the data on disk was committed at version N+delta.

**Secondary factor:** During node catch-up after restart, the `commitStores` replay protection (`last.Version >= version`) skips `store.Commit()` for already-committed versions, but the rootmulti metadata advances. This can create a gap between the metadata version and the IAVL tree's actual saved versions.

## Store Inspector Results

All 20 stores present and functional at all inspected heights (1, 5, 10, 50, 80, 94, 97):
- acc, authz, bank, capability, crisis, distribution, escrow, evidence
- feegrant, fees, gov, merchant, mint, params, payout, settlement
- slashing, staking, treasury, upgrade

`CacheMultiStoreWithVersion(N)` passes offline for all N.

## Fix Applied

1. **Spawn script fix:** `scripts/testnet/spawn-validator-agents.sh` now properly sets gov params (min_deposit denom, voting_period, quorum)
2. **Data hygiene:** Agent data must not be reused accidentally. `scripts/testnet/spawn-validator-agents.sh --clean` wipes each agent `data/`, `config/`, and `.nexarail/` path, regenerates genesis/gentxs, and refuses stale data unless `--reuse-data` is explicitly passed.
3. **Rosetta/gRPC-web disabled** in agent configs to prevent crashes.
4. **Live readback route fix:** Phase 9T added clean-spawn live query proof and app-level params readback routes backed by current keeper state.

## Single-Node Test

Created `tools/storeinspector/main.go` — inspects any agent home and reports:
- rootmulti latest version
- CacheMultiStoreWithVersion result for each height
- CommitInfo availability per height
- All store names and commit IDs

## Query Results (offline)

| Height | CacheMultiStoreWithVersion | CommitInfo |
|---|---|---|
| 1 | ✅ OK | version=1, 20 stores |
| 5 | ✅ OK | version=5, 20 stores |
| 10 | ✅ OK | version=10, 20 stores |
| 50 | ✅ OK | version=50, 20 stores |
| 80 | ✅ OK | version=80, 20 stores |
| 94 | ✅ OK | version=94, 20 stores |

## Live Query Issue

Live queries fail during node catch-up after restart because the running `BaseApp.CreateQueryContext` uses the live `CommitMultiStore` whose internal IAVL tree state may differ from the committed on-disk state. After a clean start with fresh data directories, the first run produces correct IAVL versions (version == block height). Restarting without wiping data causes version drift.

## Phase 9T Clean-Spawn Rerun

Phase 9T reran a fresh 5-agent runtime from clean data and confirmed the fix/workaround:

- Validator set count: 5
- Alpha peer count: 4
- Readback height: 21
- Query readback: 85 pass, 0 fail, 0 skip
- Bank balance query: passed
- Auth account query: passed
- Custom params query: passed for all 6 custom modules
- Initial live flags: all false
- Governance final-state query: captured after enable and disable

Evidence: `rehearsals/validator-agents/clean-spawn-governance/evidence/20260527T095523Z/`

## Remaining Blockers

| Blocker | Status |
|---|---|
| Live query during node sync | ✅ Operational under clean-spawn conditions |
| Custom module params readback | ✅ Operational through app-level keeper-backed params routes |
| Agent crash after ~10 min | ⚠️ Rosetta disabled, stability improved |
| External validator launch | ❌ Remains pending |

## Verification

```
go build ./...:  ✅
go vet ./...:    ✅
go test ./...:   ✅ all pass
```

## Conclusion

Phase 9S is **complete — root cause identified and workaround established**. Phase 9T confirms live query readback is now operational under clean-spawn conditions. External validator launch remains pending; the local agent runtime is rehearsal evidence only.
