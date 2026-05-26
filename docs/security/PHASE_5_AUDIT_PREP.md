# NexaRail Phase 5 — Audit Preparation

**Date:** 2026-05-25
**Purpose:** Consolidate all live-fund transfer paths, module accounts, invariants, and audit questions for external security review.

## 1. All Live Transfer Paths

### 1.1 x/escrow — Escrow Custody

| Operation | Transfer | Bank Method | Status Guard |
|---|---|---|---|
| CreateEscrow | buyer → nexarail_escrow | SendCoinsFromAccountToModule | LiveEnabled=true, escrow status must transition to FUNDED |
| ReleaseEscrow | nexarail_escrow → seller | SendCoinsFromModuleToAccount | Status=FUNDED/DISPUTED. Sets FundsCustodied=false. |
| RefundEscrow | nexarail_escrow → buyer | SendCoinsFromModuleToAccount | Status=FUNDED/DISPUTED. Sets FundsCustodied=false. |
| CancelEscrow | nexarail_escrow → buyer | SendCoinsFromModuleToAccount | Status=CREATED (not yet funded). Sets FundsCustodied=false. |
| ResolveDispute (BuyerWins) | nexarail_escrow → buyer | SendCoinsFromModuleToAccount | Status=DISPUTED. |
| ResolveDispute (SellerWins/Settled) | nexarail_escrow → seller | SendCoinsFromModuleToAccount | Status=DISPUTED. |

**Invariants:** `ActiveCustodiedEscrowTotals`, `ValidateCustodyInvariant` — terminal escrows (RELEASED/REFUNDED/CANCELLED) must have FundsCustodied=false.

### 1.2 x/treasury — Spend Execution

| Operation | Transfer | Bank Method | Status Guard |
|---|---|---|---|
| MarkSpendExecuted | nexarail_treasury → recipient | SendCoinsFromModuleToAccount | Status=APPROVED. Sets FundsExecuted=true. |

**Invariants:** `ActiveExecutedSpendTotals`, `ValidateSpendInvariant` — FundsExecuted=true requires status=SpendExecuted. Double-execution prevented by status guard.

### 1.3 x/payout — Payout Execution

| Operation | Transfer | Bank Method | Status Guard |
|---|---|---|---|
| MarkPayoutPaid | nexarail_treasury → recipient | SendCoinsFromModuleToAccount | Status=APPROVED, FundsPaid=false. Sets FundsPaid=true. |

**Invariants:** `ActivePaidPayoutTotals`, `ValidatePayoutFundsInvariant` — FundsPaid=true requires status=PayoutPaid. Double-pay prevented by status + FundsPaid guard.

### 1.4 x/settlement — Fee Routing (Progressive)

| Flags Enabled | Transfer 1 | Transfer 2 | Transfer 3 | Transfer 4 |
|---|---|---|---|---|
| LiveEnabled only | payer → merchant (SendCoins) | — | — | — |
| + TreasuryRouting | + payer → treasury (SendCoinsFromAccountToModule) | — | — | — |
| + BurnRouting | + payer → burner (SendCoinsFromAccountToModule) | BurnCoins(nexarail_burner) | — | — |

**Invariants:** `ActiveSettledTotals`, `ValidateSettlementFundsInvariant` — FundsSettled=true requires status=Completed. BurnExecuted=true requires FundsSettled=true and positive burn share.

## 2. Module Accounts and Permissions

| Account Name | Permission | Purpose | Blocked? |
|---|---|---|---|
| nexarail_escrow | nil | Holds buyer funds during escrow | ✅ |
| nexarail_treasury | nil | Protocol treasury reserves | ✅ |
| nexarail_fee_router | nil | **Unused** — deferred fee routing account | ✅ |
| nexarail_burner | {authtypes.Burner} | Receives burn share, immediately burned | ✅ |
| fee_collector (SDK) | nil | Standard Cosmos gas fee collection. NOT used by settlement. | ✅ |
| distribution (SDK) | nil | Validator reward distribution. NOT used by settlement. | ✅ |

All NexaRail-native module accounts are blocked from direct user sends via the `blockedAddrs` loop in `app.go`.

## 3. Bank Keeper Methods Used

| Method | Used By | Purpose |
|---|---|---|
| `SendCoins` | x/settlement | payer → merchant (account-to-account) |
| `SendCoinsFromAccountToModule` | x/escrow, x/settlement | user → module account (escrow custody, treasury routing, burn routing) |
| `SendCoinsFromModuleToAccount` | x/escrow, x/treasury, x/payout | module account → user (escrow release/refund, spend/payout execution) |
| `BurnCoins` | x/settlement | burn share from burner module (supply reduction) |
| `GetBalance` | x/escrow | Verify module account balance (invariant helpers) |

## 4. Status Guards and Failure Handling

### Universal Pattern

```
All bank transfers happen BEFORE state mutation.
If any transfer fails → return error → SDK transaction rolls back entirely.
State (settlement record, status change) only committed after all transfers succeed.
```

### Per-Module Guards

| Module | Guard | Prevents |
|---|---|---|
| x/escrow | Status transitions (CREATED→FUNDED→RELEASED/REFUNDED) | Invalid state transitions |
| x/escrow | FundsCustodied flag | Double-release, double-refund |
| x/treasury | Status=APPROVED required for execution | Unapproved spends |
| x/treasury | FundsExecuted flag | Double-execution |
| x/payout | Status=APPROVED + FundsPaid=false | Double-pay, pay unapproved |
| x/settlement | FundsSettled=true blocks status changes | Accidental unfund of live settlement |
| x/settlement | BurnExecuted validation (FundsSettled + Completed + positive burn) | Inconsistent burn state |

## 5. Invariant Helpers

| Helper | Module | Checks |
|---|---|---|
| `ActiveCustodiedEscrowTotals(ctx)` | x/escrow | Sum of all custodied escrow amounts |
| `ValidateCustodyInvariant(ctx)` | x/escrow | Terminal escrows must have FundsCustodied=false |
| `ActiveExecutedSpendTotals(ctx)` | x/treasury | Sum of all executed spend amounts |
| `ValidateSpendInvariant(ctx)` | x/treasury | FundsExecuted=true requires SpendExecuted status |
| `ActivePaidPayoutTotals(ctx)` | x/payout | Sum of all paid payout amounts |
| `ValidatePayoutFundsInvariant(ctx)` | x/payout | FundsPaid=true requires PayoutPaid status |
| `ActiveSettledTotals(ctx)` | x/settlement | Sum of all live-settled merchant net amounts |
| `ValidateSettlementFundsInvariant(ctx)` | x/settlement | FundsSettled + BurnExecuted consistency against status |

## 6. Audit Questions by Module

### x/escrow
- [ ] Can an escrow be released twice? (FundsCustodied guard)
- [ ] Can an escrow be refunded after release? (Status transition check)
- [ ] Can a dispute be resolved to a state other than RELEASED/REFUNDED? (ResolveDispute logic)
- [ ] What happens if the escrow module account has no balance at release time? (Transfer fails, rolls back)
- [ ] Can an expired escrow be released by a non-authority? (Authority-only check)

### x/treasury
- [ ] Can a spend be executed without approval? (Status=APPROVED guard)
- [ ] Can a spend be executed twice? (FundsExecuted + status guard)
- [ ] Can the authority be bypassed? (Authority string comparison on every op)
- [ ] What happens if treasury module account is empty? (Transfer fails, rolls back)

### x/payout
- [ ] Can a payout be paid twice? (FundsPaid + status guard)
- [ ] Can an unapproved payout be paid? (Status=APPROVED guard)
- [ ] Can batch payouts be executed live? (No — per-payout only, documented limitation)
- [ ] Is the treasury the only funding source? (Yes — single source)

### x/settlement
- [ ] Can settlement funds be transferred before merchant validation? (Validation happens first)
- [ ] Can treasury share be routed without merchant transfer? (Requires LiveEnabled=true)
- [ ] Can burn happen without treasury routing? (Requires TreasuryRoutingEnabled=true)
- [ ] Is supply conserved after burn? (BurnCoins updates bank supply)
- [ ] Can a live-settled record be unfunded? (FundsSettled=true blocks status changes)
- [ ] Is fee calculation deterministic? (Yes — integer arithmetic, same KV snapshot)
- [ ] Can rounding dust accumulate incorrectly? (Burn share absorbs remainder — documented)

### Cross-Module
- [ ] Can module accounts receive direct user sends? (blockedAddrs enforcement)
- [ ] Are all SendCoinsFromModuleToAccount calls authorised? (Status guards in keeper methods)
- [ ] Are all bank transfers atomic with state changes? (Transfer before state, SDK atomicity)
- [ ] Can governance enable live modes without adequate testing? (Separate flags, default false)

## 7. High-Risk Areas

| Area | Risk | Mitigation |
|---|---|---|
| Burn (bank.BurnCoins) | Irreversible supply reduction | Triple-gated flags. Burner permission restricted. |
| Escrow dispute resolution | Authority could misroute funds | BuyerWins/SellerWins/Settled/Rejected outcomes are explicit. |
| Treasury authority | Single address controls all spends | Governance module address is the authority. Multi-sig at chain level. |
| Live flag enablement | Governance could enable prematurely | All flags default false. Separate per-module. Voting period required. |
| Validator distribution | Not implemented — no risk | Deferred until specialist review. |

## 8. Required External Reviews

| Review | Scope | Priority |
|---|---|---|
| Smart contract / module security audit | All bank.SendCoins call sites, status guards, invariant logic | Critical (pre-mainnet) |
| Economic / tokenomics review | Fee split proportions (60/20/20), burn rate, treasury accumulation | High (pre-mainnet) |
| Cosmos SDK distribution integration review | Validator share routing design (Phase 5F.7) | High (before Phase 5F.8) |
| Governance process review | Flag enablement proposals, emergency pause mechanisms | Medium (pre-testnet) |
| Legal / regulatory review | Token classification, fee model, burn supply reduction | High (pre-mainnet) |
