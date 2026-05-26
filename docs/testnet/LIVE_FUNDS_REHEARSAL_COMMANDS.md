# NexaRail Live Funds Rehearsal Commands

**Document:** docs/testnet/LIVE_FUNDS_REHEARSAL_COMMANDS.md
**Date:** 2026-05-25
**Status:** Commands documented — execution pending local multi-validator launch

⚠️ **Testnet rehearsal only.** All amounts in `unxrl` (zero monetary value). Commands assume live flags have been enabled (see `GOVERNANCE_REHEARSAL_RESULTS.md`). Use tiny amounts for testing.

## Prerequisites

```bash
# Variables
CHAIN_ID="nexarail-testnet-1"
KEYRING="test"
GAS="--gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl"
NODE="tcp://localhost:26657"

# Query helper
q() { ./build/nexaraild query "$@" --node "$NODE"; }
tx() { ./build/nexaraild tx "$@" --chain-id "$CHAIN_ID" --keyring-backend "$KEYRING" $GAS -y; }
```

## 1. Register Merchant

```bash
tx merchant register-merchant $(./build/nexaraild keys show val2 -a --keyring-backend test) \
    "Test Merchant" "unxrl" --from val1
q merchant get-merchant $(./build/nexaraild keys show val2 -a --keyring-backend test)
```

## 2. Live Escrow

### Enable Flag
```bash
tx escrow update-params --live-enabled true --from val1
q escrow params
# Expected: live_enabled: true
```

### Create Escrow
```bash
SELLER=$(./build/nexaraild keys show val2 -a --keyring-backend test)

tx escrow create-escrow e2e-escrow-001 "$SELLER" "Test Merchant" "unxrl" 10000unxrl \
    --from val1
q escrow get-escrow e2e-escrow-001
# Expected: status: funded, funds_custodied: true
```

### Release Escrow
```bash
tx escrow release-escrow e2e-escrow-001 --from val1
q escrow get-escrow e2e-escrow-001
# Expected: status: released, funds_custodied: false
q bank balances "$SELLER"
# Expected: increased by ~10000 unxrl
```

### Disable Flag
```bash
tx escrow update-params --live-enabled false --from val1
```

## 3. Live Treasury Spend

### Enable Flag
```bash
tx treasury update-params --live-enabled true --from val1
```

### Create Treasury Account + Budget + Spend
```bash
# Create account
tx treasury create-account e2e-acct 0 "Rehearsal Account" "Test" "" 0unxrl --from val1

# Create budget  
tx treasury create-budget e2e-budget e2e-acct 0 "Test Budget" "" 1000000unxrl \
    0 9999999999 "" --from val1

# Create spend request
RECIPIENT=$(./build/nexaraild keys show val2 -a --keyring-backend test)
tx treasury request-spend e2e-spend-001 e2e-acct e2e-budget "" \
    "$RECIPIENT" 5000unxrl "Rehearsal spend" --from val1

# Approve
tx treasury approve-spend e2e-spend-001 --from val1

# Execute (live)
tx treasury execute-spend e2e-spend-001 --from val1

# Verify
q treasury get-spend e2e-spend-001
# Expected: status: executed, funds_executed: true
q bank balances "$RECIPIENT"
# Expected: increased by 5000 unxrl
```

### Disable Flag
```bash
tx treasury update-params --live-enabled false --from val1
```

## 4. Live Payout

### Enable Flag
```bash
tx payout update-params --live-enabled true --from val1
```

### Create + Approve + Pay
```bash
RECIPIENT=$(./build/nexaraild keys show val2 -a --keyring-backend test)

tx payout create-payout e2e-payout-001 "$RECIPIENT" 2500unxrl "Rehearsal payout" --from val1
tx payout approve-payout e2e-payout-001 --from val1
tx payout mark-paid e2e-payout-001 --from val1

q payout get-payout e2e-payout-001
# Expected: status: paid, funds_paid: true
```

### Disable Flag
```bash
tx payout update-params --live-enabled false --from val1
```

## 5. Live Settlement — Progressive

### Register Merchant (if not done)
```bash
MERCHANT_ADDR=$(./build/nexaraild keys show val2 -a --keyring-backend test)
tx merchant register-merchant "$MERCHANT_ADDR" "Settle Merchant" "unxrl" --from val1
```

### Stage 1: Merchant-Net Only
```bash
tx settlement update-params --live-enabled true --from val1
q settlement params
# Expected: live_enabled: true, treasury_routing_enabled: false, burn_routing_enabled: false

PAYER=$(./build/nexaraild keys show val1 -a --keyring-backend test)
tx settlement create "$MERCHANT_ADDR" 100000unxrl "Rehearsal payment" --from val1

q settlement get 1
# Expected: status: completed, funds_settled: true, treasury_routed: false
```

### Stage 2: Merchant + Treasury
```bash
tx settlement update-params --treasury-routing-enabled true --from val1

tx settlement create "$MERCHANT_ADDR" 100000unxrl "Payment with treasury" --from val1

q settlement get 2
# Expected: status: completed, funds_settled: true, treasury_routed: true
```

### Stage 3: Merchant + Treasury + Burn
```bash
tx settlement update-params --burn-routing-enabled true --from val1

tx settlement create "$MERCHANT_ADDR" 100000unxrl "Payment with burn" --from val1

q settlement get 3
# Expected: status: completed, funds_settled: true, burn_routed: true
# Total supply should have decreased by burn share (~180 unxrl per 100000 settlement)
q bank total
```

### Disable All
```bash
tx settlement update-params --burn-routing-enabled false --from val1
tx settlement update-params --treasury-routing-enabled false --from val1
tx settlement update-params --live-enabled false --from val1
q settlement params
# Expected: all live flags false
```

## Amount Reference

All test amounts are tiny (`unxrl` = 0.000001 NXRL):
- 100,000 unxrl = 0.1 NXRL
- 10,000 unxrl = 0.01 NXRL
- 5,000 unxrl = 0.005 NXRL
- 1,000,000 unxrl = 1 NXRL

These amounts are sufficient for testing fee calculations without exhausting test accounts.
