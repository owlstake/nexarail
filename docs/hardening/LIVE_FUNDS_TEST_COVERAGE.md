# Live Funds Test Coverage — NexaRail

**Date:** 2026-05-26
**Phase:** 8B

---

## Live Flag Coverage

| Flag | Default | Genesis Test | App Test | Keeper Test |
|---|---|---|---|---|
| settlement.live_enabled | false | ✅ | ✅ | ✅ |
| settlement.treasury_routing_enabled | false | ✅ | ✅ | ✅ |
| settlement.burn_routing_enabled | false | ✅ | ✅ | ✅ |
| escrow.live_enabled | false | ✅ | ✅ | ✅ |
| treasury.live_enabled | false | ✅ | ✅ | ✅ |
| payout.live_enabled | false | ✅ | ✅ | ✅ |

## Invariant Coverage

| Invariant | Tested | Package |
|---|---|---|
| Fee split shares sum to 10000 bps | ✅ | x/fees/keeper |
| Escrow terminal state custody = false | ✅ | x/escrow/keeper |
| Escrow module balance matches escrowed funds | ✅ | x/escrow/keeper |
| Settlement FundsSettled → BurnExecuted | ✅ | x/settlement/keeper |
| Treasury module balance matches account balances | ⚠️ | Not directly tested |

## Safety Test Coverage

| Scenario | Tested | Notes |
|---|---|---|
| Live mode disabled prevents transfers | ✅ | All keeper tests use LiveEnabled=false |
| Failed transfer leaves no state mutation | ✅ | Tested in settlement keeper |
| Metadata-only operations don't touch bank | ✅ | Tested in escrow keeper |
| Burn routing disabled by default | ✅ | Verified in genesis + app tests |
| Treasury routing disabled by default | ✅ | Verified in genesis + app tests |

## Phase 8B Additions

| Test | Package | What it verifies |
|---|---|---|
| TestAllLiveFlagsDefaultFalse | app | All 6 flags = false in default genesis |
| TestModuleAccountBurnerPermission | app | Burner permission only for burner account |
| TestCustomModuleKeepersPresent | app | All 6 keepers initialised |
| TestDefaultGenesis_* (×15) | escrow/payout/treasury types | Genesis creation, validation, JSON |
| TestQueryParams_Phase8B (×5) | keeper tests | Query server returns params correctly |
| TestQueryEscrow_NotFound | escrow/keeper | Not-found returns error |
| TestQueryEscrowExists_NotFound | escrow/keeper | Exists returns false for unknown |
| TestQueryEscrows_EmptyState | escrow/keeper | Empty list on fresh state |

**Total new live fund / safety tests: 28**
