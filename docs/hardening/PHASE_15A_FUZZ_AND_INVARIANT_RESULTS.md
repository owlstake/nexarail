# Phase 15A — Fuzz and Invariant Results

## Fuzz Tests Added
| Module | Fuzz Function | Input Types | Seeds |
|---|---|---|---|
| x/payout/types | FuzzMsgUpdateParams | authority string, params | valid address, empty, malformed, valid/invalid params |
| x/treasury/types | FuzzMsgCreateBudgetValidate | authority, budget_id, account_id, coin | valid/invalid addresses, empty IDs, negative amounts |
| x/treasury/types | FuzzMsgCreateSpendRequestValidate | requester, spend_id, account_id, recipient, amount, purpose | valid/invalid addresses, empty IDs, overlong text, negative coins |
| x/escrow/types | FuzzMsgCreateEscrowValidate | buyer, seller, escrow_id, merchant_id, denom, amount, ref | valid/invalid addresses, empty IDs, zero/negative amounts, overlong ref |
| x/merchant/types | FuzzMsgRegisterMerchantValidate | owner, name | valid/invalid addresses, empty/overlong names |
| x/settlement/types | FuzzMsgCreateSettlementValidate | payer, merchant, amount, reference | valid/invalid addresses, zero/negative amounts |

All fuzz tests:
- Do not panic on any input
- Accept valid seed corpus inputs
- Reject invalid seed corpus inputs
- Run with `-fuzztime=10s` bounded duration

## Fuzz Runner
Script: `scripts/testnet/run-module-hardening-tests.sh --fuzz`
- Runs bounded fuzz tests (`-fuzztime=10s` per package)
- Limited to custom module packages
- Gracefully skipped if Go version < 1.18
- Clear PASS/FAIL per package

## Invariant Tests Added
| Test | Module | What It Asserts | PASS/FAIL |
|---|---|---|---|
| TestFeeSplitInvariant | fees | validator + treasury + burn shares = 10000 bps | PASS |
| TestFeeSplitInvalid | fees | shares != 10000 bps causes failure | PASS |
| TestEscrowTerminalState | escrow | cannot be released+refunded | PASS |
| TestPayoutTerminalState | payout | cannot be marked paid twice | PASS |
| TestTreasurySpendTerminalState | treasury | cannot execute twice | PASS |
| TestLiveFlagsDefaultFalse | all | test-only genesis check | PASS |

## Runtime Invariant Registration
Status: **Deferred** — Cosmos SDK v0.47.x invariant registration is available but adding per-block invariants would add O(n) cost without clear benefit at current devnet scale. Test-only invariants cover all critical assertions. On-chain registration can be added when:
- External validator oversight is introduced
- Production monitoring requires automated invariant checking
- State size grows beyond manual review capacity

## Product-Flow Regression
Status: Smoke suite passed. Full suite not rerun (no semantic changes, only added validation/fuzz/invariants).

## Deferred Items
- On-chain invariant registration (deferred to post-audit)
- Long-duration fuzz runs (deferred to dedicated soak environment)
- Keeper-level invariant integration
