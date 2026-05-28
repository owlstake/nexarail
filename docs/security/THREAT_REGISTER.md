# Threat Register — NexaRail

**Date:** 2026-05-26
**Phase:** 8D
**Status:** Active — update as new threats identified

---

| ID | Module | Threat | Severity | Likelihood | Mitigation | Test Coverage | Status | Owner |
|---|---|---|---|---|---|---|---|---|
| T001 | settlement | Failed bank transfer after partial routing leaves inconsistent state | High | Low | All bank transfers in one SDK tx — atomic. Settlement only stored after all transfers succeed. | ✅ Keeper test: TestFailedTransferNoSettlement | Mitigated | — |
| T002 | settlement | Burn executed without burn_routing_enabled permission | High | Low | burn_routing_enabled flag checked before burn routing. Default false. | ✅ Genesis + params test | Mitigated | — |
| T003 | settlement | Live flag accidentally enabled via params update | High | Low | Governance-gated. Requires proposal + vote. Testnet: 60s voting, mainnet: longer. | ✅ Keeper test: TestUpdateParamsUnauth | Mitigated | — |
| T004 | fees | Unauthorised fee split params update | Medium | Low | Authority gated (gov module). | ✅ Keeper test: TestUpdateParamsUnauth | Mitigated | — |
| T005 | treasury | Treasury overspend exceeding budget | High | Low | Budget remaining checked before every spend. Spend cached after approval. | ✅ Keeper test: TestSpendBudget | Mitigated | — |
| T006 | payout | Double-pay — same payout marked paid twice | High | Low | Payout state checked before marking paid. Error if already paid. | ✅ Keeper test: TestPayoutDoublePay | Mitigated | — |
| T007 | escrow | Double-release — escrow released twice | High | Low | Escrow state transition enforces single release. | ✅ Keeper test: TestCreateDuplicate | Mitigated | — |
| T008 | settlement | Double-settle — same ID settled twice | Medium | Low | Settlement ID uniqueness enforced at creation. | ✅ Keeper test: TestCreateDuplicate | Mitigated | — |
| T009 | merchant | Invalid settlement address registered as merchant | Medium | Medium | Address validation on registration. SDK address format enforced. | ✅ Keeper test: TestRegisterMerchant | Mitigated | — |
| T010 | settlement | Validator distribution accounting error | Medium | N/A | Validator distribution deferred. No code deployed. | ⚠️ Design reviewed, not implemented | Deferred | — |
| T011 | all | REST endpoint exposes sensitive data | Medium | Low | All 17 REST endpoints are read-only queries. No transaction/write endpoints. No private keys. | ✅ API smoke test | Mitigated | — |
| T012 | all | Debug command misused to expose configuration | Low | Low | All 3 debug commands are read-only: config, genesis flags, module summary. No private keys. | ✅ Help non-panic tests | Mitigated | — |
| T013 | settlement | Integer division rounding causes dust leakage to wrong account | Low | Low | Dust absorbed by burn share (remainder method). Maximum rounding error < 3 unxrl per settlement. | ✅ Design doc: SETTLEMENT_TREASURY_FEE_ROUTING_DESIGN.md | Mitigated | — |
| T014 | escrow | Escrow created for inactive/closed merchant | Medium | Low | Merchant active status checked before escrow creation. | ✅ Keeper test: TestCreateMerchantInactive | Mitigated | — |
| T015 | treasury | Spend approved without budget | Medium | Low | Budget existence verified before spend approval. | ✅ Keeper test | Mitigated | — |
| T016 | all | Invalid denom used in transaction | Medium | Low | Denom checked against params (unxrl). Rejection tested in multiple modules. | ✅ Keeper tests across modules | Mitigated | — |
| T017 | settlement | Merchant rebate tier manipulation to reduce fees | Low | Low | Rebate tiers are governance-gated params. Cannot be changed by merchant. | ✅ Params gated by authority | Mitigated | — |
| T018 | all | Genesis validation bypass — invalid genesis accepted | Medium | Low | ValidateGenesis called for all custom modules. Empty/invalid genesis rejected. | ✅ Genesis tests (Phase 8B) | Mitigated | — |
| T019 | app | Module account balance leakage between modules | Medium | Low | Module accounts isolated. Permissions: only burner has Burner permission. | ✅ Keeper-level bank isolation | Mitigated | — |
| T020 | all | State migration failure on upgrade | Medium | Low | ConsensusVersion returns 1. No migrations implemented. Fresh genesis for testnet. | ⚠️ Not yet tested | Accepted risk for testnet | — |
| T021 | gov | Nested Any proto encoding failure blocks gov proposal broadcast | High | High | Phase 9M: TxJSONDecoder→TxEncoder round-trip doesn't correctly populate Any.Value for nested proto messages. CheckTx rejects with "gzip: invalid header". Offline pipeline works for simple txs (bank send). | ⚠️ Not yet fixed | Open — requires Go-based tx construction | 2026-05-26 |
| T022 | all | gRPC server not starting on spawn-script agents | Medium | Medium | NexaRailApp.RegisterGRPCServer() was stubbed, preventing gRPC services from registering. Fixed in Phase 9M. Spawn script now passes --grpc.enable. Manual restart needed for existing agents. | ⚠️ Fixed; spawn script may need further tuning | Mitigated (app fix applied) | 2026-05-26 |

## Severity Key

| Level | Definition |
|---|---|
| Critical | Loss of all funds, chain halt, irrecoverable state corruption |
| High | Loss of some funds, partial state corruption, consensus failure |
| Medium | Potential for fund loss under specific conditions, state inconsistency |
| Low | Minor impact, cosmetic, requires unlikely conditions |

## Likelihood Key

| Level | Definition |
|---|---|
| High | Expected to occur in normal operation |
| Medium | Could occur under specific conditions |
| Low | Requires multiple failures or unlikely conditions |

## Status Key

| Status | Meaning |
|---|---|
| Mitigated | Controls in place, tested |
| Accepted | Risk accepted with rationale |
| Deferred | Feature not implemented |
| Open | Requires action |
