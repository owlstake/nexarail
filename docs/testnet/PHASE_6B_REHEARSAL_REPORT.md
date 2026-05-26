# NexaRail Phase 6B Rehearsal Report

**Document:** docs/testnet/PHASE_6B_REHEARSAL_REPORT.md
**Date:** 2026-05-25
**Rehearsal:** Multi-Validator Testnet (`nexarail-testnet-1`)
**Status:** Partial — documentation and code verification complete; multi-validator launch deferred to dedicated environment

## What Was Run

| Component | Status | Details |
|---|---|---|
| `go mod tidy && go mod verify` | ✅ Pass | All modules verified |
| `go build ./...` | ✅ Pass | Binary: `build/nexaraild` |
| `go vet ./...` | ✅ Pass | No issues |
| `go test ./...` | ✅ Pass | 14 packages, ~332 tests all green |
| `validate-genesis` (source check) | ✅ Pass | Genesis validation in `app/app_test.go` |
| `go test ./app/... -run TestModuleAccount` | ✅ Pass | Module account permissions verified |
| Health check script (source checks) | ✅ Pass | All source-level flag defaults confirmed false |
| ShellCheck scripts | ⚠️ N/A | ShellCheck not available (`brew install shellcheck` needed) |

## What Was Documented

| Document | Status |
|---|---|
| `PHASE_6B_REHEARSAL_PLAN.md` | ✅ Complete |
| `GOVERNANCE_REHEARSAL_RESULTS.md` | ✅ Commands documented |
| `LIVE_FUNDS_REHEARSAL_COMMANDS.md` | ✅ Complete (all flows) |
| `RPC_EXPLORER_REHEARSAL.md` | ✅ Commands documented |
| `rehearsals/testnet-1/` | ✅ Directory structure created |
| `scripts/testnet/run-rehearsal-health-check.sh` | ✅ Created |
| `rehearsals/testnet-1/genesis/README.md` | ✅ Complete |
| `rehearsals/testnet-1/checksums/SHA256SUMS` | ✅ Template created |

## What Was NOT Run

| Item | Reason |
|---|---|
| Multi-validator local launch (3 validators) | Environment constraint: no daemon manager, port allocation, or process supervision available in this session |
| `nexaraild start` with 3 nodes | Requires separate terminal sessions and `--home` directory management |
| Gentx collection (actual) | Requires running validators to produce keys + gentx |
| Governance proposal lifecycle (live) | Requires running multi-validator chain |
| Live fund flow execution (live) | Requires running chain with flags enabled |
| RPC query tests (against running node) | No running node in this environment |
| Explorer deployment | Deferred to infrastructure setup phase |

## Chain ID

| Environment | Chain ID |
|---|---|
| Devnet (local development) | `nexarail-devnet-1` |
| Testnet (public, proposed) | `nexarail-testnet-1` |

Both chain IDs are distinct. Devnet is unchanged.

## Validator Count

| Environment | Validators |
|---|---|
| Devnet | 3 (local) |
| Testnet rehearsal | 3 documented (not launched) |
| Testnet public target | 5-20 |

## Block Height Reached

N/A — multi-validator launch not executed in this session.

## Module Query Results

Source-level verification only:

| Check | Result |
|---|---|
| Settlement params source compiles | ✅ |
| Escrow params source compiles | ✅ |
| Treasury params source compiles | ✅ |
| Payout params source compiles | ✅ |
| Fees params source compiles | ✅ |
| Merchant params source compiles | ✅ |
| All live flags default false in source | ✅ Verified via grep |

## Governance Results

Commands documented for all 6 flag enable/disable cycles. See `GOVERNANCE_REHEARSAL_RESULTS.md`.

## Live Funds Rehearsal Status

Commands documented for all flows:
- Merchant registration ✅
- Escrow create → release ✅
- Treasury account → budget → spend → execute ✅
- Payout create → approve → pay ✅
- Settlement progressive (merchant → treasury → burn) ✅
- All flag disable ✅

See `LIVE_FUNDS_REHEARSAL_COMMANDS.md`.

## Open Issues

| Issue | Severity | Action |
|---|---|---|
| Multi-validator launch not tested | Medium | Run on dedicated test machine or macOS with tmux |
| ShellCheck not available | Low | `brew install shellcheck`, re-run audit |
| RPC/API not tested against live node | Medium | Test after launch |
| Governance authority address needs verification | Low | Confirm governance module address before rehearsal launch |
| Port conflict risk with devnet | Low | `pkill nexaraild` before testnet rehearsal launch |

## Readiness Decision

### Code Readiness: ✅ GREEN
- Build ✅, vet ✅, test ✅ (14 packages, ~332 tests)
- All live flags default false ✅
- Module accounts correctly registered ✅
- Genesis validates ✅

### Documentation Readiness: ✅ GREEN
- Testnet plan, validator onboarding, genesis ceremony ✅
- Faucet, explorer, governance testing ✅
- Bug bounty, runbook ✅
- Audit package, legal package ✅
- Live funds rehearsal commands ✅

### Launch Readiness: 🔜 PENDING
- Multi-validator launch not yet executed
- Governance rehearsal not yet executed against live chain
- Live fund flows not yet tested on testnet chain ID

### Recommendation

**Public validator registration is conditionally safe to begin** — conditional on:
1. Running the multi-validator launch rehearsal on a dedicated machine
2. Verifying at least 3 validators produce blocks on `nexarail-testnet-1`
3. Testing governance flag enablement against the live rehearsal chain
4. Confirming RPC/REST endpoints respond
5. No panics or crash loops observed

The documentation, scripts, and code are ready. The execution environment is the remaining gap — this is expected and will be resolved when Bradley or a team member runs the rehearsal on a suitable machine.
