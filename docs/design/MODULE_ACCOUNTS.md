# NexaRail Module Accounts

## Overview

When live fund movement is enabled, NexaRail requires dedicated module accounts to hold and route protocol funds. These accounts are Cosmos SDK `ModuleAccount` types registered at genesis with specific permissions.

## Module Account Definitions

### 1. `nexarail_escrow`

| Attribute | Value |
|---|---|
| Module | x/escrow |
| Purpose | Hold buyer funds during active escrow |
| Receive | Via `MsgCreateEscrow` (buyer sends coins to this account) |
| Send | Via `MsgReleaseEscrow` (to seller), `MsgRefundEscrow` (to buyer), `MsgResolveDispute` (to seller or buyer) |
| Permissions | None (no minter/burner/staking) — standard receive/send only |
| Blocked from | User-initiated sends (must go through escrow messages) |

**Balance invariant:** `nexarail_escrow.balance == sum(escrow.amount for all escrows with status IN (FUNDED))`

### 2. `nexarail_treasury`

| Attribute | Value |
|---|---|
| Module | x/treasury |
| Purpose | Hold protocol treasury reserves |
| Receive | Via fee routing from `nexarail_fee_router`; from settlements |
| Send | Via `MsgMarkSpendExecuted` (to spend recipient) |
| Permissions | None |
| Blocked from | User-initiated sends |

**Balance invariant:** `nexarail_treasury.balance >= 0` at all times. Spend execution must check balance before sending.

### 3. `nexarail_fee_router` (optional)

| Attribute | Value |
|---|---|
| Module | x/fees |
| Purpose | Temporary holding account for fee splitting |
| Receive | From `fee_collector` (standard Cosmos auth module account) |
| Send | To `nexarail_treasury` (treasury share), burn (burn share), distribution (validator share) |
| Permissions | None |
| Lifecycle | Balance should be zero after each BeginBlock (all fees routed) |

**Alternative:** Route fees directly from `fee_collector` without an intermediate account. This is simpler but may complicate the split logic. The intermediate `nexarail_fee_router` approach is recommended for auditability.

### 4. Burn Handling

NexaRail uses `bank.BurnCoins` for the burn share of protocol fees. No dedicated burn module account is created. The coins are destroyed, reducing total supply.

```go
// During fee routing in BeginBlock
feeCollector := authtypes.NewModuleAddress(authtypes.FeeCollectorName)
burnAmount := totalFees.Mul(burnShareBps).Quo(10000)
bankKeeper.BurnCoins(ctx, authtypes.FeeCollectorName, sdk.Coins{burnAmount})
```

### 5. Payout Funding Source

Payouts may be funded from either:
- `nexarail_treasury` (default for protocol-funded payouts)
- A merchant's own account (for merchant-funded payouts, future)

The spend request record tracks the `AccountId` which maps to the treasury account. For treasury-funded payouts, funds are sent from `nexarail_treasury`. For merchant-funded payouts (future), funds are sent from the merchant's address.

## Permission Matrix

| Account | Can Receive | Can Send | Can Burn | Can Mint | Can Stake |
|---|---|---|---|---|---|
| `nexarail_escrow` | ✓ (MsgCreateEscrow) | ✓ (release/refund/dispute) | ✗ | ✗ | ✗ |
| `nexarail_treasury` | ✓ (fee routing, settlements) | ✓ (spend execution) | ✗ | ✗ | ✗ |
| `nexarail_fee_router` | ✓ (from fee_collector) | ✓ (to treasury/burn/dists) | ✗ | ✗ | ✗ |
| Burn | n/a (uses bank.BurnCoins) | n/a | n/a | n/a | n/a |

## Blocked Address Configuration

In `app/app.go`, add all module account addresses to the `blockedAddrs` map:

```go
blockedAddrs[authtypes.NewModuleAddress("nexarail_escrow").String()] = true
blockedAddrs[authtypes.NewModuleAddress("nexarail_treasury").String()] = true
```

## Governance Authority

The governance module address (`authtypes.NewModuleAddress(govtypes.ModuleName)`) remains the authority for all parameter changes. Live fund movement does not grant the authority direct spending power — all sends must go through module message handlers with status guards.

## Avoiding Unrestricted Admin Drains

- No message type allows sending arbitrary amounts from any module account.
- All sends are bound to specific message types (MsgReleaseEscrow, MsgMarkSpendExecuted, etc.) that verify state before transferring.
- Emergency pause via params (`escrow.live_enabled = false`) stops all transfers.
- Large transfers should require multi-sig governance in future phases.
