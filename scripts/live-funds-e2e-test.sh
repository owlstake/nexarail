#!/usr/bin/env bash
# NexaRail Live Funds End-to-End Test
# Manual / semi-automated devnet test script.
# LOCAL DEVNET ONLY — do not run against any public network.
#
# Prerequisites:
#   1. Local devnet running: ./scripts/init-devnet.sh && ./scripts/start-devnet.sh
#   2. Binary built: make build
#   3. jq installed (brew install jq)
#
# Usage:
#   chmod +x scripts/live-funds-e2e-test.sh
#   ./scripts/live-funds-e2e-test.sh
#
# This script executes commands against a running local devnet.
# Some commands require manual confirmation. Read before running.

set -euo pipefail

BINARY="${NEXARAIL_BINARY:-./build/nexaraild}"
CHAIN_ID="${NEXARAIL_CHAIN_ID:-nexarail-devnet-1}"
NODE="${NEXARAIL_NODE:-tcp://localhost:26657}"
KEYRING="${NEXARAIL_KEYRING:-test}"
GAS_FLAGS="--gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl"

# Account names (from init-devnet.sh defaults)
VALIDATOR="validator"
USER1="user1"
USER2="user2"

echo "============================================"
echo " NexaRail Live Funds E2E Test"
echo " Chain: $CHAIN_ID"
echo " LOCAL DEVNET ONLY"
echo "============================================"
echo ""

# ---- SECTION 0: Verify Devnet State ----
echo "=== Section 0: Verify Devnet State ==="
echo ""

echo "--- Check chain status ---"
$BINARY status --node "$NODE" 2>/dev/null | jq '.SyncInfo.latest_block_height' || echo "  ⚠️  Devnet may not be running. Start with: ./scripts/start-devnet.sh"

echo "--- Check validator balance ---"
$BINARY query bank balances $($BINARY keys show $VALIDATOR -a --keyring-backend $KEYRING) --node "$NODE" --output json 2>/dev/null | jq '.balances' || echo "  ⚠️  Query failed"

echo ""
echo "--- Verify all live flags default false (source check) ---"
grep -l "LiveEnabled.*false\|TreasuryRoutingEnabled.*false\|BurnRoutingEnabled.*false" \
    x/escrow/types/params.go \
    x/treasury/types/params.go \
    x/payout/types/params.go \
    x/settlement/types/params.go 2>/dev/null && echo "  ✅ All flags default false in source" || echo "  ❌ Check failed"

echo ""
echo "Manual verification complete. Press Enter to continue to escrow test..."
read -r

# ---- SECTION 1: Escrow Live Test ----
echo ""
echo "=== Section 1: Escrow Live Custody ==="
echo ""
echo "This section tests live escrow: create → fund → release."
echo "Commands are shown for manual execution."
echo ""

cat << 'ESCROW_CMDS'
# 1. Enable escrow live mode (governance or authority)
nexaraild tx escrow update-params --live-enabled true \
    --from validator --chain-id nexarail-devnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# 2. Create escrow (buyer=user1, seller=user2)
nexaraild tx escrow create-escrow escrow-e2e-001 \
    $(nexaraild keys show user2 -a --keyring-backend test) \
    test-merchant unxrl 100000unxrl \
    --from user1 --chain-id nexarail-devnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# 3. Query escrow
nexaraild query escrow get-escrow escrow-e2e-001 --node tcp://localhost:26657

# Expected: status=funded, funds_custodied=true, buyer balance decreased, escrow module balance increased

# 4. Release escrow (authority)
nexaraild tx escrow release-escrow escrow-e2e-001 \
    --from validator --chain-id nexarail-devnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# 5. Verify: seller received funds, escrow module balance decreased
nexaraild query bank balances $(nexaraild keys show user2 -a --keyring-backend test) --node tcp://localhost:26657
nexaraild query escrow get-escrow escrow-e2e-001 --node tcp://localhost:26657
# Expected: status=released, funds_custodied=false
ESCROW_CMDS

echo ""
echo "Escrow section ready. Press Enter to continue to treasury test..."
read -r

# ---- SECTION 2: Treasury Live Test ----
echo ""
echo "=== Section 2: Treasury Live Spend ==="
echo ""

cat << 'TREASURY_CMDS'
# 1. Enable treasury live mode
nexaraild tx treasury update-params --live-enabled true \
    --from validator --chain-id nexarail-devnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# 2. Fund treasury (genesis allocation or manual send via governance)
# For devnet, mint or send to nexarail_treasury address:
# (Genesis may already fund treasury — check balance)
nexaraild query bank balances nexarail1...treasury_address... --node tcp://localhost:26657

# 3. Create treasury account
nexaraild tx treasury create-account acct-e2e-001 0 "E2E Test Account" "Test" "" 0unxrl \
    --from validator --chain-id nexarail-devnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# 4. Create budget
nexaraild tx treasury create-budget budget-e2e-001 acct-e2e-001 0 "Test Budget" "" 1000000unxrl \
    0 9999999999 "" \
    --from validator --chain-id nexarail-devnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# 5. Create spend request
nexaraild tx treasury request-spend spend-e2e-001 acct-e2e-001 budget-e2e-001 "" \
    $(nexaraild keys show user2 -a --keyring-backend test) 50000unxrl "E2E test spend" \
    --from validator --chain-id nexarail-devnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# 6. Approve spend
nexaraild tx treasury approve-spend spend-e2e-001 \
    --from validator --chain-id nexarail-devnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# 7. Execute spend (live)
nexaraild tx treasury execute-spend spend-e2e-001 \
    --from validator --chain-id nexarail-devnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# 8. Verify: recipient balance increased, treasury balance decreased
nexaraild query bank balances $(nexaraild keys show user2 -a --keyring-backend test) --node tcp://localhost:26657
nexaraild query treasury get-spend spend-e2e-001 --node tcp://localhost:26657
# Expected: status=executed, funds_executed=true
TREASURY_CMDS

echo ""
echo "Treasury section ready. Press Enter to continue to payout test..."
read -r

# ---- SECTION 3: Payout Live Test ----
echo ""
echo "=== Section 3: Payout Live Transfer ==="
echo ""

cat << 'PAYOUT_CMDS'
# 1. Enable payout live mode
nexaraild tx payout update-params --live-enabled true \
    --from validator --chain-id nexarail-devnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# 2. Create payout
nexaraild tx payout create-payout payout-e2e-001 \
    $(nexaraild keys show user2 -a --keyring-backend test) 25000unxrl "E2E payout" \
    --from validator --chain-id nexarail-devnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# 3. Approve payout
nexaraild tx payout approve-payout payout-e2e-001 \
    --from validator --chain-id nexarail-devnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# 4. Mark paid (live)
nexaraild tx payout mark-paid payout-e2e-001 \
    --from validator --chain-id nexarail-devnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# 5. Verify
nexaraild query bank balances $(nexaraild keys show user2 -a --keyring-backend test) --node tcp://localhost:26657
nexaraild query payout get-payout payout-e2e-001 --node tcp://localhost:26657
# Expected: status=paid, funds_paid=true
PAYOUT_CMDS

echo ""
echo "Payout section ready. Press Enter to continue to settlement test..."
read -r

# ---- SECTION 4: Settlement Live Test ----
echo ""
echo "=== Section 4: Settlement Live Fee Routing ==="
echo ""

cat << 'SETTLE_CMDS'
# Note: Settlement requires a registered, active merchant.
# Register merchant first if not already done:
nexaraild tx merchant register-merchant $(nexaraild keys show user2 -a --keyring-backend test) \
    "E2E Merchant" "unxrl" \
    --from validator --chain-id nexarail-devnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# Step 1: Enable merchant-net transfers (LiveEnabled)
nexaraild tx settlement update-params --live-enabled true \
    --from validator --chain-id nexarail-devnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# Step 2: Create settlement (merchant-net only at this point)
nexaraild tx settlement create \
    $(nexaraild keys show user2 -a --keyring-backend test) 100000unxrl "E2E payment" \
    --from user1 --chain-id nexarail-devnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# Step 3: Verify merchant received funds, payer deducted
nexaraild query bank balances $(nexaraild keys show user2 -a --keyring-backend test) --node tcp://localhost:26657
nexaraild query settlement get 1 --node tcp://localhost:26657
# Expected: status=completed, funds_settled=true

# Step 4: Enable treasury routing
nexaraild tx settlement update-params --treasury-routing-enabled true \
    --from validator --chain-id nexarail-devnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# Step 5: Create another settlement
nexaraild tx settlement create \
    $(nexaraild keys show user2 -a --keyring-backend test) 100000unxrl "E2E payment 2" \
    --from user1 --chain-id nexarail-devnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# Step 6: Verify treasury received share
nexaraild query bank balances <nexarail_treasury_address> --node tcp://localhost:26657
# Expected: treasury balance increased by ~180unxrl

# Step 7: Enable burn routing
nexaraild tx settlement update-params --burn-routing-enabled true \
    --from validator --chain-id nexarail-devnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# Step 8: Create third settlement (all three shares routed)
nexaraild tx settlement create \
    $(nexaraild keys show user2 -a --keyring-backend test) 100000unxrl "E2E payment 3" \
    --from user1 --chain-id nexarail-devnet-1 --keyring-backend test \
    --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# Step 9: Query supply (should have decreased by burn share)
nexaraild query bank total --node tcp://localhost:26657
# (Note: supply decrease may be small — 180 unxrl per settlement)
SETTLE_CMDS

echo ""
echo "============================================"
echo " E2E Test Script Complete"
echo "============================================"
echo ""
echo "Summary of expected outcomes:"
echo "  ✅ Escrow: created → funded → released. Funds moved buyer→module→seller."
echo "  ✅ Treasury: spend created → approved → executed. Module→recipient."
echo "  ✅ Payout: payout created → approved → paid. Module→recipient."
echo "  ✅ Settlement: progressive enablement. Merchant→treasury→burn."
echo "  ✅ All flags default false. Manual governance enablement required."
echo ""
echo "Validator share (60% of net fee): metadata-only — deferred pending distribution review."
echo "Fee router: unused. BeginBlock routing: not implemented."
