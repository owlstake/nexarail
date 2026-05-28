# Phase 9V - Persistence-Safe Restart Investigation Results

**Date:** 2026-05-27  
**Chain:** `nexarail-agent-testnet-1`  
**Scope:** local validator-agent restart investigation  
**Status:** Complete - restart-safe fix validated

## Evidence

```text
rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/
```

Phase 9U failure reference:

```text
rehearsals/validator-agents/long-soak/evidence/20260527T102106Z/
```

## Root Cause

Best diagnosis: the Phase 9U restart failure was caused by NexaRail's custom in-memory BaseApp consensus-param store returning nil after process restart.

Clean-spawn worked because `InitChain` populated the in-memory store. A reuse-data process restart rebuilds the app object and calls `LoadLatestVersion`, but does not call `InitChain`. BaseApp default `PrepareProposal` and `ProcessProposal` handlers then read consensus params from a store that could return `nil, nil`, causing recovered nil-pointer panics at the first post-restart height.

Phase 9V code inspection found no custom `SetPrepareProposal` or `SetProcessProposal` handler. BaseApp defaults are used.

## Fix

The fix keeps the existing module set, economics, genesis live flags, and business logic unchanged.

Files modified:

- `app/app.go`
- `app/app_test.go`
- `scripts/testnet/spawn-validator-agents.sh`
- `scripts/testnet/stop-validator-agents.sh`
- `scripts/testnet/restart-agent-matrix.sh`
- `docs/testnet/PHASE_9V_RESTART_INVESTIGATION_PLAN.md`
- `docs/testnet/PHASE_9V_RESTART_PANIC_ANALYSIS.md`
- `docs/testnet/PHASE_9V_RESTART_RESULTS.md`
- `docs/testnet/AGENT_TESTNET_DATA_POLICY.md`
- `docs/testnet/VALIDATOR_AGENT_REHEARSAL_RESULTS.md`
- `docs/testnet/LAUNCH_GO_NO_GO_REVIEW.md`
- `docs/audit/AUDIT_PACKAGE_INDEX.md`

Runtime fix:

- seed the BaseApp consensus-param store from `config/genesis.json` during app construction;
- fall back to CometBFT defaults if genesis params are unavailable;
- ensure `Get` always returns non-nil consensus params;
- copy consensus params on `Get` and `Set`;
- add tests covering restart-construction non-nil params and copy isolation.

Script fix:

- add `--agent-count` support to `spawn-validator-agents.sh` for 1, 3, and 5-agent matrix cases;
- add `restart-agent-matrix.sh`;
- make `stop-validator-agents.sh` return success when no agents are running.

## Restart Matrix

| Case | Result | Block Production | Queries | Panics | Peer Range | Validator Set |
|---|---|---|---|---|---|---|
| A - single-validator clean stop/reuse-data restart | Pass | resumed | pass | none | 0-0 | 1-1 |
| B - 3-agent clean stop/reuse-data restart | Pass | resumed | pass | none | 2-2 | 3-3 |
| C - 5-agent clean stop/reuse-data restart | Pass | resumed | pass | none | 4-4 | 5-5 |
| D - 5-agent immediate restart at height 20 | Pass | resumed | pass | none | 4-4 | 5-5 |
| E - 5-agent restart after 60m soak | Pass | resumed | pass | none | 4-4 | 5-5 |
| F - one-node restart while four continue | Pass | network continued; restarted node caught up | pass | none | 4-4 | 5-5 |
| G - all 5 direct simultaneous restart | Pass | resumed | pass | none | 4-4 | 5-5 |
| H - all 5 direct sequential restart | Pass | resumed | pass | none | 4-4 | 5-5 |
| Standard direct single-node restart | Pass | resumed | pass | none | 0-0 | 1-1 |

Full matrix:

```text
rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/matrix-results.tsv
```

## Long-Soak Restart Case

Case E repeated the Phase 9U failure shape with a 60-minute soak before reuse-data restart.

Soak result:

| Metric | Result |
|---|---:|
| Target duration | 3600s |
| Actual duration | 3602s |
| Start height | 20 |
| Final height | 693 |
| Height delta | 673 |
| Average block time | 5.35s |
| Peer count range | 4-4 |
| Validator set range | 5-5 |
| Query totals | 425 pass / 0 fail / 0 skip |
| Panic count | 0 |

Restart result:

| Check | Result |
|---|---|
| Restart height | 695 |
| Final sampled height | 698 |
| Block production after restart | Pass |
| Post-restart query checks | 27 pass / 0 fail |
| Peer range after restart | 4-4 |
| Validator set after restart | 5-5 |
| Panic scan after restart | 0 |

The Phase 9U height-696 proposal panic did not recur.

## Final Rebuilt-Binary Proof

After adding the final param-store copy test and stop-script hygiene patch, the binary was rebuilt and a focused 5-agent reuse-data restart proof was run.

| Check | Result |
|---|---|
| Restart height | 11 |
| Final sampled height | 14 |
| Block production after restart | Pass |
| Full query readback | 85 pass / 0 fail / 0 skip |
| Panic scan | 0 |

Evidence:

```text
rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/final-code-restart-proof/
```

## Bank Transaction After Restart

A bank send was submitted after the simultaneous all-node direct restart.

| Field | Result |
|---|---|
| Tx hash | `9F85BD88F936818D6A910BEE640DDAF3B1D437F993519BE2FACCCF3D0E0E52A5` |
| Inclusion code | `0` |
| Result | pass |

## Final Live Flags

Final rebuilt-binary readback:

```text
settlement.live_enabled=false
settlement.treasury_routing_enabled=false
settlement.burn_routing_enabled=false
escrow.live_enabled=false
payout.live_enabled=false
treasury.live_enabled=false
```

## Verification

Verification evidence:

```text
rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/verification/
```

Result:

- `go mod tidy`: pass
- `go mod verify`: pass
- `go build ./...`: pass
- `go vet ./...`: pass
- `go test ./...`: pass
- `scripts/testnet/predeployment-check.sh`: pass

## Safety Wording Audit

Safety audit evidence:

```text
rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/safety-wording-audit/
```

Terms audited: `decentralised`, `independent validators`, `external validators`, `mainnet live`, `buy NXRL`, `token sale`, `investment`, `guaranteed`, `profit`, `APY`, `returns`, `price`, `listing`.

Result: pass after manual review. Remaining matches are negative, qualified, roadmap-only, technical, prohibited-language examples, or audit-term literals. No positive claim was found that mainnet is live, NXRL can be bought, a token sale exists, investment/return/profit/APY is available, or external decentralisation has been achieved.

## Classification

Persistence-safe restart is fixed for the local validator-agent rehearsal path tested in Phase 9V.

Supported after Phase 9V:

- clean-spawn rehearsal mode;
- explicit reuse-data restart testing;
- direct single-node restart;
- one-node restart while the local network continues;
- simultaneous and sequential all-node local restarts.

Still pending before external launch:

- Linux or production-like supervised node rehearsal;
- external validator onboarding;
- gentx collection from accepted external validators;
- final genesis assembly.

## Conclusion

Phase 9V is complete.

The Phase 9U reuse-data restart failure was an app runtime restart bug in the BaseApp consensus-param store, not a tokenomics, product-module, live-flag, or external-validator issue. The restart path now resumes block production after clean stops and reuse-data starts in the local agent matrix.

The local agent testnet is stable for continued development. External validator launch remains pending, and the local agent matrix does not prove external validator participation, mainnet launch, NXRL availability, or external decentralisation.
