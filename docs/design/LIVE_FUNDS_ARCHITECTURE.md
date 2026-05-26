# NexaRail Live Fund Movement Architecture

**Version:** 1.0
**Date:** 2026-05-25
**Status:** Design — not implemented

## 1. Current State (v1)

All six custom modules are metadata-only:

| Module | Current Behaviour |
|---|---|
| x/fees | Defines fee split params (60/20/20 bps). No routing. |
| x/merchant | Registers merchant profiles. No payment flow. |
| x/settlement | Records settlement metadata. Calculates fee splits in-memory. Status transitions only. No coin movement. |
| x/escrow | Records escrow lifecycle. No custody. No fund locking. |
| x/payout | Records payout instructions. Approval/cancellation lifecycle only. No disbursement. |
| x/treasury | Records treasury accounts, budgets, grants, spend requests. Nominal balances are metadata. No coin movement. |

## 2. Target State (v2 Live Transfers)

| Module | Target Behaviour |
|---|---|
| x/fees | Same params. Additionally: fee collector routes fees to treasury, burn, validators. |
| x/escrow | Buyer locks funds in escrow module account. Release sends to seller. Refund returns to buyer. |
| x/settlement | Payer sends gross amount. Protocol splits fee. Merchant receives net. |
| x/payout | Authority marks payout executed. Funds move from treasury (or merchant) to recipient. |
| x/treasury | Module account holds protocol reserves. Budgets allocate. Grants commit. Spend execution transfers. |
| Burn | Burn share sent to dead address or burned via bank.BurnCoins. |

## 3. Module Accounts Required

| Account Name | Module | Purpose | Permissions |
|---|---|---|---|
| `escrow` | x/escrow | Holds buyer funds during escrow | Receive only via MsgCreateEscrow; send only via MsgReleaseEscrow/MsgRefundEscrow |
| `treasury` | x/treasury | Protocol treasury reserves | Receive from fee routing, settlements; send via MsgMarkSpendExecuted |
| `fee_collector` | SDK x/auth | Standard Cosmos fee collection | Existing SDK behaviour (unchanged) |
| `fee_router` | x/fees | Temporary holding for fee splitting | Receive from fee_collector; split to treasury, burn, validators |
| `burn` | x/fees or x/bank | Burn destination | Receive only; permanently locked (or use bank.BurnCoins) |

**Account naming pattern:**
- `nexarail_escrow` — escrow custody
- `nexarail_treasury` — treasury reserves
- `nexarail_fee_router` — fee splitting intermediary
- Use `bank.BurnCoins` for burn rather than a dedicated account

## 4. Blocked Addresses

All module account addresses must be added to blocked recipients in the bank module to prevent users from sending directly to module accounts outside approved message paths.

## 5. Supply Invariants

- Total supply = user balances + module account balances + burned amount
- Escrow balance = sum of all funded, unreleased escrow amounts
- Treasury balance ≥ sum of all approved, unexecuted spend request amounts
- Fee router balance should be zero after each BeginBlock (all fees routed)
- Burn share reduces total supply (verified by supply invariant)

## 6. Flow Diagrams

### A. Settlement Flow

```
Payer --[gross amount]→ fee_collector
  → fee_router splits:
    → validator share (60%): sent to distribution module for validator rewards
    → treasury share (20%): sent to nexarail_treasury module account  
    → burn share (20%): bank.BurnCoins
  → merchant net: sent to merchant owner address
```

### B. Escrow Flow

```
CREATE:
  Buyer --[amount]→ nexarail_escrow (module account)
  Escrow record created with status FUNDED

RELEASE:
  nexarail_escrow → Seller (full amount minus platform fee)
  Escrow status → RELEASED

REFUND:
  nexarail_escrow → Buyer (full amount)
  Escrow status → REFUNDED

DISPUTE → BUYER_WINS:
  nexarail_escrow → Buyer
  Escrow status → REFUNDED

DISPUTE → SELLER_WINS:
  nexarail_escrow → Seller
  Escrow status → RELEASED
```

### C. Payout Flow

```
Treasury-funded:
  nexarail_treasury → Recipient
  Spend request status → EXECUTED
  Budget spent_amount incremented

Merchant-funded (future):
  Merchant account → Recipient
  Spend request records source
```

### D. Treasury Flow

```
Fee routing deposits → nexarail_treasury (automatic per block)
Spend execution:
  nexarail_treasury → Recipient
  Budget.spent_amount += amount
  Grant.completed_milestones++ (if linked)
```

### E. Burn Flow

```
From fee routing: burn share → bank.BurnCoins("nexarail_fee_router", burnAmount)
Supply reduced by burnAmount
```

## 7. Risk Analysis

| Risk | Severity | Mitigation |
|---|---|---|
| Double execution of payouts/spends | High | Status guard (only APPROVED→EXECUTED), idempotency key |
| Incorrect fee split due to rounding | Medium | Always use integer arithmetic, audit dust handling |
| Stuck funds in escrow after dispute | Medium | Authority resolution path always progresses to RELEASED or REFUNDED |
| Module account balance drift | High | BeginBlock/EndBlock invariant checks |
| Authority compromises treasury | High | Multi-sig governance for large spends; spending limits per time period |
| Replayed transactions | Low | Cosmos SDK sequence numbers prevent replay |
| Denom mismatch in cross-module transfers | Medium | Validate denom at each transfer point |

## 8. Migration Plan (v1 → v2)

1. **Phase 5B**: Add module accounts to genesis, add blocked addresses. No business logic changes. Existing metadata-only flows continue.
2. **Phase 5C-5F**: Implement live flows one module at a time, starting with escrow (simplest balance invariant).
3. **Phase 5G**: Burn handling and distribution integration.
4. **Phase 5H**: Test, audit, simulation.
5. **Governance proposal**: Enable live transfers via params (`escrow.live_enabled`, `settlement.live_enabled`, etc.)

Each phase can be independently tested and reverted.

## 9. Audit Checklist

- [ ] All module account balances sum correctly
- [ ] No unauthorised sends from module accounts
- [ ] All send paths check status guards
- [ ] Double-execution prevented
- [ ] Burn accounting matches fee params
- [ ] Supply invariant maintained after each transfer
- [ ] Failed transfers roll back state changes
- [ ] Genesis migration produces correct module account balances
- [ ] All existing metadata-only paths still work after live upgrade
