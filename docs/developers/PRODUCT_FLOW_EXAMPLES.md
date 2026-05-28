# NexaRail Product Flow Examples

> ⚠️ **These are local/devnet-only examples. NOT for production.**
> Tokens have **zero monetary value**. All amounts in `unxrl` (1 NXRL = 1,000,000 unxrl).

This document demonstrates end-to-end product flows using CLI commands against a running local devnet. Each flow builds on the previous one — run them in order for best results.

---

## Prerequisites Setup

Set up convenience variables and query helpers:

```bash
# Build binary
cd /Users/bradleyjohnston/workspace/nexarail
make build

# Launch devnet (fresh state)
bash scripts/release/launch-rc1-devnet.sh --single-node --clean

# Convenience variables
BINARY=./build/nexaraild
HOME_DIR=$HOME/.nexarail-devnet
CHAIN_ID=nexarail-devnet-1
NODE="tcp://localhost:26657"
KEYRING="test"
GAS="--gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl"

# Query helper
q() { $BINARY query "$@" --node "$NODE"; }

# Tx helper (assumes devnet-key already exists)
tx() { $BINARY tx "$@" --chain-id "$CHAIN_ID" --keyring-backend "$KEYRING" --home "$HOME_DIR" $GAS -y; }

# Get the devnet key address
DEVNET_ADDR=$($BINARY keys show devnet-key -a --keyring-backend test --home $HOME_DIR)

echo "Devnet address: $DEVNET_ADDR"
```

---

## 1. Merchant Onboarding (Register Merchant with Fee)

**What it demonstrates:** Creating a merchant record on-chain. This is the prerequisite for most settlement and escrow flows.

```bash
# Register a merchant
tx merchant register-merchant "$DEVNET_ADDR" \
    "Devnet Merchant" \
    "A test merchant for development" \
    "https://nexarail.dev" \
    --from devnet-key

# Query the merchant back
q merchant merchant "$DEVNET_ADDR"

# List all merchants
q merchant merchants
```

**Expected result:**

```
Owner:       nxrl1...
Name:        Devnet Merchant
Description: A test merchant for development
Website:     https://nexarail.dev
Status:      active
```

**Requires governance?** No — merchant registration is a direct CLI transaction.

---

## 2. Settlement Metadata (Create Settlement Record)

**What it demonstrates:** Creating a settlement record with `live_enabled=false`. Funds stay in the payer's account; the settlement is recorded as metadata only.

```bash
# Create a settlement (metadata only — live flags are off)
tx settlement create "$DEVNET_ADDR" \
    100000unxrl \
    "Test settlement — metadata only" \
    --from devnet-key

# Query the settlement by ID
q settlement settlement 1

# Query all settlements
q settlement settlements
```

**Expected result:**

```json
Settlement 1: completed (metadata only — no fund transfer)
```

**Requires governance?** No — metadata settlement creation does not move funds.

---

## 3. Settlement Live (With Governance Enable/Disable)

**What it demonstrates:** Enabling the settlement `live_enabled` flag via governance, then creating a settlement that actually transfers funds.

This flow requires `product-gov.sh` which is designed for the **five-agent devnet** pattern. For single-node devnet, use the CLI directly.

### Using product-gov.sh (five-agent devnet)

```bash
# View current flags
bash scripts/testnet/product-gov.sh show-live-flags

# Dry-run enable (prints proposal JSON, no mutation)
bash scripts/testnet/product-gov.sh enable-settlement-live

# Actually enable (requires running five-agent devnet)
bash scripts/testnet/product-gov.sh enable-settlement-live --confirm

# Verify
bash scripts/testnet/product-gov.sh show-live-flags
# Expected: settlement.live_enabled = true

# Create a live settlement (funds move)
tx settlement create "$DEVNET_ADDR" \
    100000unxrl \
    "Live settlement — funds transfer" \
    --from devnet-key

# Disable when done
bash scripts/testnet/product-gov.sh disable-settlement-live --confirm
```

### Using Direct CLI (single-node devnet)

> **Note:** Direct `update-params` via CLI requires the module authority privilege (governance module). On a single-node devnet, you can update the genesis file and restart, or use a governance proposal directly.

```bash
# Submit a governance proposal to enable settlement live
tx gov submit-proposal param-change settlement LiveEnabled true \
    --title "Enable Settlement Live" \
    --description "Enable live settlement transfers (devnet only)" \
    --deposit 1000000unxrl \
    --from devnet-key

# Vote yes
tx gov vote 1 yes --from devnet-key

# Wait for voting period (30s on devnet)
sleep 35

# Verify
q settlement params
# Expected: live_enabled: true
```

**Expected result after enable:**
- Settlement `live_enabled` changes from `false` to `true`
- New settlement creates a `SendCoins` bank transfer from payer to merchant
- On disable, all new settlements revert to metadata-only

**Requires governance?** ✅ **Yes** — all live-flag toggles require a governance proposal.

---

## 4. Escrow Create/Release/Refund (Escrow Lifecycle)

**What it demonstrates:** The full escrow lifecycle — create (lock funds), release (pay seller), and refund (return to buyer).

### Metadata-Only (Live Flag Off)

```bash
# Create an escrow (metadata only)
SELLER="$DEVNET_ADDR"
tx escrow create-escrow "escrow-001" "$SELLER" \
    "Devnet Merchant" "unxrl" 10000unxrl \
    --from devnet-key

# Query the escrow
q escrow escrow escrow-001
# Expected: status=funded, funds_custodied=false (metadata only)

# Release (metadata update only)
tx escrow release-escrow escrow-001 --from devnet-key

# Query post-release
q escrow escrow escrow-001
# Expected: status=released

# Create another for a refund test
tx escrow create-escrow "escrow-002" "$SELLER" \
    "Devnet Merchant" "unxrl" 5000unxrl \
    --from devnet-key

# Refund
tx escrow refund-escrow escrow-002 --from devnet-key
q escrow escrow escrow-002
# Expected: status=refunded
```

### Live (With Live Flag Enabled)

```bash
# First enable escrow live via governance
# (on five-agent: product-gov.sh enable-escrow-live --confirm)

# Create escrow — funds now move to module account
tx escrow create-escrow "live-escrow-001" "$SELLER" \
    "Devnet Merchant" "unxrl" 10000unxrl \
    --from devnet-key

q escrow escrow live-escrow-001
# Expected: status=funded, funds_custodied=true

# Release — funds sent to seller
tx escrow release-escrow live-escrow-001 --from devnet-key

q escrow escrow live-escrow-001
# Expected: status=released, funds_custodied=false

# Verify seller received funds
q bank balances "$SELLER"
# Expected: increased by ~10000 unxrl

# Disable when done
# product-gov.sh disable-escrow-live --confirm
```

**Requires governance?** ✅ **Yes** — toggling `escrow.live_enabled` requires a governance proposal.

---

## 5. Treasury Spend (Account, Budget, Spend Approval, Execution)

**What it demonstrates:** The full treasury spend pipeline — create an account, create a budget under it, request a spend, approve, and execute.

### Metadata-Only (Live Flag Off)

```bash
# Create a treasury account
tx treasury create-account "acct-001" 0 \
    "Development Account" "Dev" "" 0unxrl \
    --from devnet-key

# Create a budget
tx treasury create-budget "bgt-001" "acct-001" 0 \
    "Q2 Dev Budget" "" 1000000unxrl 0 9999999999 "" \
    --from devnet-key

# Request a spend
RECIPIENT="$DEVNET_ADDR"
tx treasury request-spend "spend-001" "acct-001" "bgt-001" "" \
    "$RECIPIENT" 5000unxrl "Developer tools" \
    --from devnet-key

# Approve the spend
tx treasury approve-spend spend-001 --from devnet-key

# Execute (metadata only — no funds move)
tx treasury execute-spend spend-001 --from devnet-key

# Verify
q treasury spend spend-001
# Expected: status=executed, funds_executed=false (metadata only)

# Check treasury summary
q treasury summary
# Expected: total_accounts=1, total_spend_requests=1
```

### Live (With Live Flag Enabled)

```bash
# Enable treasury live via governance
# (on five-agent: product-gov.sh enable-treasury-live --confirm)

# Create another spend request (live)
tx treasury request-spend "spend-002" "acct-001" "bgt-001" "" \
    "$RECIPIENT" 5000unxrl "Live test spend" \
    --from devnet-key

tx treasury approve-spend spend-002 --from devnet-key
tx treasury execute-spend spend-002 --from devnet-key

q treasury spend spend-002
# Expected: status=executed, funds_executed=true

# Verify recipient received funds
q bank balances "$RECIPIENT"
# Expected: increased by 5000 unxrl

# Disable when done
# product-gov.sh disable-treasury-live --confirm
```

**Requires governance?** ✅ **Yes** — toggling `treasury.live_enabled` requires a governance proposal. Treasury authority actions (approve-spend, create-account) do NOT require governance (they use direct CLI).

---

## 6. Payout Mark-Paid (Create Payout, Mark as Paid)

**What it demonstrates:** Creating a payout record and marking it as paid.

### Metadata-Only (Live Flag Off)

```bash
# Create a payout
RECIPIENT="$DEVNET_ADDR"
tx payout create-payout "payout-001" "$RECIPIENT" \
    2500unxrl "Developer reward" \
    --from devnet-key

# Query the payout
q payout payout payout-001
# Expected: status=pending

# Approve
tx payout approve-payout payout-001 --from devnet-key

# Mark as paid (metadata only)
tx payout mark-paid payout-001 --from devnet-key

# Verify
q payout payout payout-001
# Expected: status=paid, funds_paid=false (metadata only)

# Check list
q payout payouts
```

### Live (With Live Flag Enabled)

```bash
# Enable payout live via governance
# (on five-agent: product-gov.sh enable-payout-live --confirm)

# Create, approve, and mark-paid (live)
tx payout create-payout "live-payout-001" "$RECIPIENT" \
    3000unxrl "Live payout test" \
    --from devnet-key

tx payout approve-payout live-payout-001 --from devnet-key
tx payout mark-paid live-payout-001 --from devnet-key

q payout payout live-payout-001
# Expected: status=paid, funds_paid=true

# Verify recipient received funds
q bank balances "$RECIPIENT"
# Expected: increased by 3000 unxrl

# Disable when done
# product-gov.sh disable-payout-live --confirm
```

**Requires governance?** ✅ **Yes** — toggling `payout.live_enabled` requires a governance proposal.

---

## 7. Governance Live-Flag Enable/Disable (Through product-gov.sh)

**What it demonstrates:** Using the `product-gov.sh` harness to toggle all 6 live flags via governance proposals.

### Available Commands

```bash
# View all flags
bash scripts/testnet/product-gov.sh show-live-flags

# Toggle escrow live
bash scripts/testnet/product-gov.sh enable-escrow-live --confirm
bash scripts/testnet/product-gov.sh disable-escrow-live --confirm

# Toggle settlement live + routing flags
bash scripts/testnet/product-gov.sh enable-settlement-live --confirm
bash scripts/testnet/product-gov.sh disable-settlement-live --confirm
bash scripts/testnet/product-gov.sh enable-settlement-treasury-routing --confirm
bash scripts/testnet/product-gov.sh disable-settlement-treasury-routing --confirm
bash scripts/testnet/product-gov.sh enable-settlement-burn-routing --confirm
bash scripts/testnet/product-gov.sh disable-settlement-burn-routing --confirm

# Toggle treasury live
bash scripts/testnet/product-gov.sh enable-treasury-live --confirm
bash scripts/testnet/product-gov.sh disable-treasury-live --confirm

# Toggle payout live
bash scripts/testnet/product-gov.sh enable-payout-live --confirm
bash scripts/testnet/product-gov.sh disable-payout-live --confirm
```

### What Happens

Each `--confirm` command:

1. Reads the current on-chain params via the REST API
2. Preserves all existing parameter values (only toggles the target flag)
3. Generates a signed governance proposal (`MsgUpdateParams`)
4. Broadcasts via CometBFT RPC
5. All 5 agents vote Yes
6. Waits for the proposal to pass (30s voting period)
7. Writes evidence to `rehearsals/validator-agents/product-flows/gov-toggles/`

### Safety Rules (Enforced by product-gov.sh)

| Operation | Prerequisite |
|-----------|-------------|
| Enable settlement-treasury-routing | settlement.live_enabled must be `true` |
| Enable settlement-burn-routing | settlement.live_enabled + treasury_routing must be `true` |

### Dry-Run Mode

Without `--confirm`, the script prints the proposal JSON and exits with no state mutation:

```bash
bash scripts/testnet/product-gov.sh enable-escrow-live
```

---

## Flow Dependency Map

```
merchant registration
      │
      ├── settlement (metadata) ◄── live_enabled ──► settlement (live transfer)
      │                              treasury_routing ──► + treasury share
      │                              burn_routing ──► + burn share
      │
      ├── escrow (metadata) ◄── live_enabled ──► escrow (fund custody/release)
      │
      ├── treasury account + budget
      │         │
      │         └── treasury spend (metadata) ◄── live_enabled ──► treasury spend (fund transfer)
      │
      └── payout (metadata) ◄── live_enabled ──► payout (fund transfer)
```

---

## Key Points

| Flow | Requires Governance? | Notes |
|------|---------------------|-------|
| Register merchant | No | Direct CLI tx |
| Create settlement (metadata) | No | Direct CLI tx |
| Toggle settlement live flags | ✅ Yes | Through product-gov.sh or manual governance proposal |
| Create escrow (metadata) | No | Direct CLI tx |
| Toggle escrow live flag | ✅ Yes | Through product-gov.sh |
| Create treasury account/budget/spend | No | Direct CLI tx |
| Approve treasury spend | No | Authority action (direct CLI) |
| Toggle treasury live flag | ✅ Yes | Through product-gov.sh |
| Create/approve payout | No | Direct CLI tx |
| Toggle payout live flag | ✅ Yes | Through product-gov.sh |

## Additional Scripts

For automated smoke testing of all flows, see:

- `scripts/testnet/api-smoke-test.sh` — REST/RPC/gRPC endpoint coverage
- `scripts/testnet/cli-e2e-smoke-test.sh` — CLI command smoke test
- `scripts/live-flags-smoke-test.sh` — Live flag specific checks
- `scripts/live-funds-e2e-test.sh` — End-to-end live fund transfer test
- `scripts/testnet/run-product-flow-rehearsal.sh` — Full product flow rehearsal

Documentation reference: `docs/testnet/LIVE_FUNDS_REHEARSAL_COMMANDS.md`
