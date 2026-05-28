# Phase 8F — Upgrade Readiness Audit

**Date:** 2026-05-26
**Auditor:** Clove

---

## Upgrade Module Status

| Component | Status | Notes |
|---|---|---|
| Upgrade keeper wired | ✅ | `app.UpgradeKeeper` initialised and registered |
| Store key registered | ✅ | `upgradetypes.StoreKey` in store keys |
| Module in ModuleManager | ✅ | Registered in init/begin/end block orders |
| `SetModuleVersionMap` called | ✅ | Called during `InitChainer` |
| `RegisterUpgradeHandler` | ✅ | Added in Phase 8F (no-op handler for v0.2.0-testnet) |
| Store loader | ⚠️ | Uses default SDK store loader — no custom migration |
| Migration handlers | ⚠️ | No migrations implemented — all modules at version 1 |

## App.go Upgrade Keeper Wiring

```go
// Line 285
app.UpgradeKeeper = upgradekeeper.NewKeeper(
    skipUpgradeHeights, app.keys[upgradetypes.StoreKey],
    appCodec, homePath, app.BaseApp, authority,
)

// Line 481 (InitChainer)
app.UpgradeKeeper.SetModuleVersionMap(ctx, app.mm.GetVersionMap())

// Phase 8F addition
app.registerUpgradeHandlers() // no-op handler for v0.2.0-testnet
```

## Store Loader Status

The app uses the default Cosmos SDK store loader. No custom `UpgradeStoreLoader` is registered. For testnet, this is sufficient — state changes only come through genesis or governance proposals.

## Upgrade Handler Status

| Handler | Registered | Behaviour |
|---|---|---|
| `v0.2.0-testnet` | ✅ | No-op — returns current version map unchanged |
| Future versions | ⚠️ | Not registered — add before governance proposal |

## Module Version Map

| Module | Version | Migration Implemented |
|---|---|---|
| fees | 1 | No |
| merchant | 1 | No |
| settlement | 1 | No |
| escrow | 1 | No |
| payout | 1 | No |
| treasury | 1 | No |
| All standard modules | 1 | No |

All modules at version 1. No migrations needed until version changes.

## Migration Readiness

| Component | Ready? |
|---|---|
| Module version tracking | ✅ `ConsensusVersion()` returns 1 for all modules |
| State export | ✅ `ExportGenesis` implemented for all modules |
| State import | ✅ `InitGenesis` implemented for all modules |
| In-place migration | ⚠️ Not yet implemented |
| Migration tests | ⚠️ Not yet implemented |

## Governance Upgrade Proposal Path

1. Validator submits `MsgSoftwareUpgrade` governance proposal
2. Proposal specifies: plan name, upgrade height, optional binary URL
3. Governance vote (60s voting period on testnet)
4. If passed: upgrade plan stored on-chain
5. At upgrade height: chain halts automatically
6. Validators install new binary
7. Validators restart with new binary
8. Registered upgrade handler executes
9. Chain resumes from halt height

## Testnet Upgrade Process

```
1. Coordinator announces upgrade proposal in communication channel
2. Validators review and discuss
3. Proposal submitted on-chain
4. Validators vote (60s period)
5. If passed: upgrade height set
6. Coordinator releases new binary
7. Validators build/install new binary
8. At upgrade height: chain halts
9. Validators restart with new binary
10. Coordinator confirms chain resumed
```

## Gaps and Risks

| Gap | Risk | Mitigation |
|---|---|---|
| No in-place migration | If module version changes, state must be migrated | Define migration when version changes |
| No migration tests | Migrations could corrupt state | Test migrations before any version bump |
| No custom store loader | Can't upgrade store format | Standard SDK loader is sufficient for current needs |
| No multi-module upgrade tested | Cross-module state consistency during upgrade unverified | Keeper tests cover isolated state — integration needed |
| No rollback tested | Failed upgrade recovery untested | Fresh genesis is the fallback for testnet |

## Verdict

✅ **Upgrade infrastructure is ready for testnet use.** The no-op handler proves the wiring works. Real migrations must be implemented and tested before any module version bump. For the current controlled testnet (all modules at v1), upgrades are safe as long as no state-affecting changes are introduced without corresponding migration code.
