# NexaRail Developer Write-Flow Examples

> ⚠️ **SAFETY DISCLAIMER — LOCAL DEVNET ONLY**
>
> - **NOT mainnet.** NexaRail mainnet does not exist.
> - **NOT a public testnet.** No public testnet is running.
> - **NO token sale.** Tokens have **zero monetary value**.
> - **Test keys only.** All keys are created with `--keyring-backend test` and are for local development.
> - **Test tokens only.** All amounts are in `unxrl` (1 NXRL = 1,000,000 unxrl) with no real-world value.
> - **All live flags are `false` by default.** Governance proposals are required to enable any fund-transferring behaviour.
> - **Zero production infrastructure.** These commands touch only ephemeral local state.
> - **Do not use these examples against any network that holds real funds.**

---

## Prerequisites

Before running any write-flow examples, ensure the following:

- **RC1 devnet is running** (single-node or five-agent)
- **Binary is available** at `releases/testnet-rc1/binaries/nexaraild-darwin-arm64` (macOS) or `releases/testnet-rc1/binaries/nexaraild-linux-amd64` (Linux) OR built at `build/nexaraild`
- **Keyring backend** is `test`
- **Chain ID** is `nexarail-devnet-1` (single-node) or `nexarail-agent-testnet-1` (five-agent)
- **jq**, **curl**, and **lsof** are installed

### Launch a Fresh Devnet

**Single-node devnet** (recommended for most examples):

```bash
cd /Users/bradleyjohnston/workspace/nexarail
bash scripts/release/launch-rc1-devnet.sh --single-node --clean
```

**Five-agent devnet** (required for governance proposal examples):

```bash
cd /Users/bradleyjohnston/workspace/nexarail
bash scripts/release/launch-rc1-devnet.sh --five-agent --clean
```

### Set Up Convenience Variables

For **single-node devnet**:

```bash
# Adjust binary path if using release binary instead of build
BINARY=./build/nexaraild
HOME_DIR=$HOME/.nexarail-devnet
CHAIN_ID=nexarail-devnet-1
DENOM=unxrl
NODE="tcp://localhost:26657"
KEYRING="test"
GAS="--gas auto --gas-adjustment 1.5 --gas-prices 0.0025${DENOM}"
TX_FEE="${TX_FEE:-10000${DENOM}}"
REST_PORT="1317"

# Tx helper
tx() { $BINARY tx "$@" --chain-id "$CHAIN_ID" --keyring-backend "$KEYRING" --home "$HOME_DIR" $GAS -y; }
# Query helper
q() { $BINARY query "$@" --node "$NODE"; }
```

For **five-agent devnet** (governance examples use bravo):

```bash
BINARY=./build/nexaraild
AGENT_DIR=rehearsals/validator-agents
CHAIN_ID=nexarail-agent-testnet-1
DENOM=unxrl
TX_FEE="10000${DENOM}"
BRAVO_RPC="tcp://127.0.0.1:27667"
BRAVO_API_PORT="1418"

# Tx helper for bravo agent
tx_bravo() {
  $BINARY tx "$@" --chain-id "$CHAIN_ID" --keyring-backend test \
    --home "$AGENT_DIR/bravo" --node "$BRAVO_RPC" --fees "$TX_FEE" \
    --broadcast-mode sync --output json -y
}
```

---

## 1. Account Setup

### Create a Test Key

**Single-node devnet:**

```bash
# The devnet key is created automatically by launch-rc1-devnet.sh
# To add additional keys:
$BINARY keys add alice --keyring-backend test --home "$HOME_DIR"
$BINARY keys add bob   --keyring-backend test --home "$HOME_DIR"

# Show addresses
$BINARY keys show alice -a --keyring-backend test --home "$HOME_DIR"
$BINARY keys show bob   -a --keyring-backend test --home "$HOME_DIR"

# List all keys
$BINARY keys list --keyring-backend test --home "$HOME_DIR"
```

**Five-agent devnet:**

```bash
# Validator agent keys created automatically:
$BINARY keys list --keyring-backend test --home rehearsals/validator-agents/alpha
$BINARY keys list --keyring-backend test --home rehearsals/validator-agents/bravo

# Create a standalone test key on alpha's home (shared home for rehearsal keys)
$BINARY keys add test-buyer --keyring-backend test --home rehearsals/validator-agents/alpha
$BINARY keys add test-seller --keyring-backend test --home rehearsals/validator-agents/alpha
```

### Fund from Genesis Account

The genesis account (`devnet-key`) is automatically funded with `1000000000unxrl`. Distribute to test accounts:

**Single-node devnet:**

```bash
ALICE=$($BINARY keys show alice -a --keyring-backend test --home "$HOME_DIR")
BOB=$($BINARY keys show bob   -a --keyring-backend test --home "$HOME_DIR")

$BINARY tx bank send devnet-key "$ALICE" 50000000unxrl \
  --chain-id "$CHAIN_ID" --keyring-backend test --home "$HOME_DIR" $GAS -y

$BINARY tx bank send devnet-key "$BOB" 50000000unxrl \
  --chain-id "$CHAIN_ID" --keyring-backend test --home "$HOME_DIR" $GAS -y
```

**Five-agent devnet (fund from alpha-key to a rehearsal user):**

```bash
# Create a test key first
$BINARY keys add rehearsal-user --keyring-backend test --home rehearsals/validator-agents/alpha
USER_ADDR=$($BINARY keys show rehearsal-user -a --keyring-backend test --home rehearsals/validator-agents/alpha)

$BINARY tx bank send alpha-key "$USER_ADDR" 50000000unxrl \
  --chain-id "$CHAIN_ID" --keyring-backend test \
  --home rehearsals/validator-agents/alpha \
  --node "$BRAVO_RPC" --fees "$TX_FEE" --broadcast-mode sync --output json -y
```

---

## 2. Bank Send Smoke

Test basic token transfer between accounts.

**Single-node devnet:**

```bash
ALICE=$($BINARY keys show alice -a --keyring-backend test --home "$HOME_DIR")
BOB=$($BINARY keys show bob   -a --keyring-backend test --home "$HOME_DIR")

# Check balances before
$BINARY query bank balances "$ALICE" --node "$NODE"
$BINARY query bank balances "$BOB" --node "$NODE"

# Send 1000unxrl from alice to bob
$BINARY tx bank send alice "$BOB" 1000unxrl \
  --chain-id "$CHAIN_ID" --keyring-backend test --home "$HOME_DIR" $GAS -y

# Wait for inclusion
sleep 2

# Check balances after
$BINARY query bank balances "$ALICE" --node "$NODE"
$BINARY query bank balances "$BOB" --node "$NODE"
# Expected: alice decreased by (1000 + fee), bob increased by 1000
```

**Five-agent devnet:**

```bash
ALPHA_ADDR=$($BINARY keys show alpha-key -a --keyring-backend test --home rehearsals/validator-agents/alpha)
BRAVO_ADDR=$($BINARY keys show bravo-key -a --keyring-backend test --home rehearsals/validator-agents/bravo)

# Send from alpha to bravo
$BINARY tx bank send alpha-key "$BRAVO_ADDR" 1000unxrl \
  --chain-id "$CHAIN_ID" --keyring-backend test \
  --home rehearsals/validator-agents/alpha \
  --node "$BRAVO_RPC" --fees "$TX_FEE" --broadcast-mode sync --output json -y

# Query balances
$BINARY query bank balances "$ALPHA_ADDR" --node "$BRAVO_RPC"
$BINARY query bank balances "$BRAVO_ADDR" --node "$BRAVO_RPC"
```

---

## 3. Merchant Registration

Register a merchant on-chain. This is the prerequisite for most settlement and escrow flows.

**No governance required** — direct CLI transaction.

### Register

**Single-node devnet:**

```bash
DEVNET_ADDR=$($BINARY keys show devnet-key -a --keyring-backend test --home "$HOME_DIR")

$BINARY tx merchant register-merchant "$DEVNET_ADDR" \
  "Devnet Merchant" \
  "A test merchant for development" \
  "https://nexarail.dev" \
  --from devnet-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y
```

**Five-agent devnet:**

```bash
BRAVO_ADDR=$($BINARY keys show bravo-key -a --keyring-backend test --home rehearsals/validator-agents/bravo)

$BINARY tx merchant register-merchant "$BRAVO_ADDR" \
  "Phase10B Merchant" \
  "Phase 10B local product-flow merchant" \
  "https://phase10b.invalid" \
  --from bravo-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home rehearsals/validator-agents/bravo \
  --node "$BRAVO_RPC" --fees "$TX_FEE" --broadcast-mode sync --output json -y
```

### Query

```bash
# By owner address
$BINARY query merchant merchant "$BRAVO_ADDR" --node "$NODE"

# List all
$BINARY query merchant merchants --node "$NODE"

# REST readback (single-node)
curl -s http://127.0.0.1:$REST_PORT/nexarail/merchant/v1/merchants | jq .
```

### Update Profile

```bash
$BINARY tx merchant update "$BRAVO_ADDR" \
  "Devnet Merchant Updated" \
  "Updated description" \
  "https://nexarail-updated.dev" \
  --from devnet-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y
```

### Expected Query Result

```json
{
  "merchant": {
    "owner": "nxrl1...",
    "name": "Devnet Merchant",
    "description": "A test merchant for development",
    "website": "https://nexarail.dev",
    "status": "STATUS_ACTIVE"
  }
}
```

---

## 4. Settlement Metadata Creation

Creates a settlement record **without** transferring funds (non-live). Funds stay in the payer's account; the settlement is recorded as metadata only.

**No governance required** — every devnet starts with all `live_enabled` flags set to `false`.

### Create Settlement (Metadata Only)

**Single-node devnet:**

```bash
MERCHANT=$($BINARY keys show devnet-key -a --keyring-backend test --home "$HOME_DIR")

$BINARY tx settlement create "$MERCHANT" 100000unxrl \
  --metadata "Test settlement — metadata only" \
  --from devnet-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y
```

**Five-agent devnet:**

```bash
# Alpha pays to bravo's merchant
ALPHA_ADDR=$($BINARY keys show alpha-key -a --keyring-backend test --home rehearsals/validator-agents/alpha)
BRAVO_ADDR=$($BINARY keys show bravo-key -a --keyring-backend test --home rehearsals/validator-agents/bravo)

$BINARY tx settlement create "$BRAVO_ADDR" 1000000unxrl \
  --metadata "phase10b-metadata-only" \
  --from alpha-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home rehearsals/validator-agents/alpha \
  --node "$BRAVO_RPC" --fees "$TX_FEE" --broadcast-mode sync --output json -y
```

### Verify

```bash
# Query settlement by ID
$BINARY query settlement settlement 1 --node "$NODE"

# expected: funds_settled = false (no bank transfer happened)

# List all settlements
$BINARY query settlement settlements --node "$NODE"

# REST readback
curl -s http://127.0.0.1:$REST_PORT/nexarail/settlement/v1/settlement/1 | jq .
```

### Expected Behaviour

| Field | Value | Meaning |
|-------|-------|---------|
| `amount` | `100000` | Settlement amount recorded |
| `funds_settled` | `false` | No funds transferred — metadata only |
| `fee_amount` | fee split | Validator/treasury/burn shares computed but not sent |

---

## 5. Escrow Create / Release / Refund

Full escrow lifecycle with `live_enabled=false` (metadata-only, no fund custody).

**No governance required for metadata-only** — live flag is `false` by default.

### Create Escrow

**Single-node devnet:**

```bash
SELLER=$($BINARY keys show devnet-key -a --keyring-backend test --home "$HOME_DIR")

$BINARY tx escrow create-escrow "escrow-001" "$SELLER" \
  "Devnet Merchant" "unxrl" 10000unxrl \
  --from devnet-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y
```

**Five-agent devnet (exact rehearsal pattern):**

```bash
ALPHA_ADDR=$($BINARY keys show alpha-key -a --keyring-backend test --home rehearsals/validator-agents/alpha)
BRAVO_ADDR=$($BINARY keys show bravo-key -a --keyring-backend test --home rehearsals/validator-agents/bravo)

# Create escrow — alpha is buyer, bravo is seller (merchant)
$BINARY tx escrow create "my-escrow-001" \
  "$BRAVO_ADDR" "my-merchant" "250000$DENOM" \
  --payment-reference "release-ref" \
  --memo "release path" \
  --from alpha-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home rehearsals/validator-agents/alpha \
  --node "$BRAVO_RPC" --fees "$TX_FEE" --broadcast-mode sync --output json -y
```

### Verify (Post-Create)

```bash
$BINARY query escrow escrow my-escrow-001 --node "$NODE"
# Expected: status=funded, funds_custodied=false (metadata only)
```

### Release Escrow

```bash
$BINARY tx escrow release-escrow my-escrow-001 \
  --release-reference "release-ok" \
  --from alpha-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y
```

**Five-agent devnet (rehearsal pattern — release by buyer):**

```bash
$BINARY tx escrow release "my-escrow-001" \
  --release-reference "phase10b-release-ok" \
  --from alpha-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home rehearsals/validator-agents/alpha \
  --node "$BRAVO_RPC" --fees "$TX_FEE" --broadcast-mode sync --output json -y
```

### Verify (Post-Release)

```bash
$BINARY query escrow escrow my-escrow-001 --node "$NODE"
# Expected: status=released, funds_custodied=false
```

### Refund Escrow

Create a separate escrow for a refund scenario:

```bash
# Create
$BINARY tx escrow create "my-escrow-refund" \
  "$BRAVO_ADDR" "my-merchant" "150000unxrl" \
  --payment-reference "refund-ref" --memo "refund path" \
  --from alpha-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y

# Refund (seller initiates refund)
$BINARY tx escrow refund "my-escrow-refund" \
  --refund-reference "refund-ok" \
  --from "$SELLER_KEY" --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y
```

### Cancel Escrow

```bash
# Cancel is initiated by the buyer
$BINARY tx escrow cancel "my-escrow-cancel" \
  --memo "cancelling this escrow" \
  --from alpha-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y
```

### Rejection Safety — Double Release

```bash
# Attempting to release an already-released escrow should fail
$BINARY tx escrow release "my-escrow-001" \
  --release-reference "double-release" \
  --from alpha-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y
# Expected: transaction rejected (escrow already released)
```

---

## 6. Escrow Live (With Governance Enable)

Toggling `escrow.live_enabled` to `true` requires a governance proposal. Once enabled, escrow create actually custodies funds in the module account, and release sends them to the seller.

### Enable via product-gov.sh (Five-Agent Devnet)

```bash
# Dry-run (prints proposal JSON, no mutation)
bash scripts/testnet/product-gov.sh enable-escrow-live

# Submit for real
bash scripts/testnet/product-gov.sh enable-escrow-live --confirm

# Verify
curl -s http://127.0.0.1:$BRAVO_API_PORT/nexarail/escrow/v1/params | jq '.params.live_enabled'
```

### Create Live Escrow

```bash
# Now funds are custodied in the module account
$BINARY tx escrow create "live-escrow-001" "$BRAVO_ADDR" \
  "my-merchant" "unxrl" 10000unxrl \
  --from alpha-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y

# Verify funds moved to escrow module
$BINARY query bank balances "$ESCROW_MODULE_ADDR" --node "$NODE"
$BINARY query escrow escrow live-escrow-001 --node "$NODE"
# Expected: funds_custodied=true
```

### Release Live

```bash
# Release sends funds to seller
$BINARY tx escrow release live-escrow-001 \
  --release-reference "live-release" \
  --from alpha-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y

# Verify seller received funds
$BINARY query bank balances "$BRAVO_ADDR" --node "$NODE"
# Expected: increased by ~10000 unxrl
```

### Disable

```bash
bash scripts/testnet/product-gov.sh disable-escrow-live --confirm
```

---

## 7. Payout Create / Approve / Mark-Paid

Payout lifecycle with `live_enabled=false` (metadata-only, no fund transfer).

**No governance required for metadata-only** — `live_enabled` defaults to `false`.

### Create Payout

**Single-node devnet:**

```bash
RECIPIENT=$($BINARY keys show devnet-key -a --keyring-backend test --home "$HOME_DIR")

$BINARY tx payout create-payout "payout-001" "$RECIPIENT" \
  2500unxrl "Developer reward" \
  --from devnet-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y
```

**Five-agent devnet (exact rehearsal pattern):**

```bash
PAYOUT_RECIPIENT=$($BINARY keys show phase10b-payout-recipient -a \
  --keyring-backend test --home rehearsals/validator-agents/alpha 2>/dev/null || \
  $BINARY keys add phase10b-payout-recipient --keyring-backend test \
    --home rehearsals/validator-agents/alpha -a)

$BINARY tx payout create "phase10b-payout" "phase10b-merchant" \
  "$PAYOUT_RECIPIENT" 1000unxrl 1 \
  --payout-reference "phase10b-payout" --memo "local rehearsal" \
  --from alpha-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home rehearsals/validator-agents/alpha \
  --node "$BRAVO_RPC" --fees "$TX_FEE" --broadcast-mode sync --output json -y
```

### Query

```bash
$BINARY query payout payout payout-001 --node "$NODE"
# Expected: status=pending, funds_paid=false

# List all
$BINARY query payout payouts --node "$NODE"

# REST details
curl -s http://127.0.0.1:$REST_PORT/nexarail/payout/v1/payout/payout-001 | jq .
```

### Approve Payout

```bash
$BINARY tx payout approve-payout payout-001 \
  --from devnet-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y
```

### Mark as Paid (Metadata Only)

```bash
$BINARY tx payout mark-paid payout-001 \
  --from devnet-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y

# Verify
$BINARY query payout payout payout-001 --node "$NODE"
# Expected: status=paid, funds_paid=false (no bank transfer for metadata-only)
```

### Payout Live (With Governance Enable)

```bash
# Enable payout live
bash scripts/testnet/product-gov.sh enable-payout-live --confirm

# Create, approve, mark-paid (now funds move)
$BINARY tx payout create "live-payout" "merchant" "$RECIPIENT" 3000unxrl 1 \
  --from alpha-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y

$BINARY tx payout approve live-payout \
  --from alpha-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y

# Mark-paid via governance (authority action)
bash scripts/testnet/product-gov.sh mark-payout-paid live-payout --confirm

# Verify recipient received funds
$BINARY query bank balances "$RECIPIENT" --node "$NODE"

# Disable when done
bash scripts/testnet/product-gov.sh disable-payout-live --confirm
```

---

## 8. Treasury Account / Budget / Spend Flow

Full treasury pipeline — create an account, create a budget, request a spend on that budget, approve, and execute.

**No governance required** for treasury account/budget/spend operations themselves (direct CLI). Governance is only needed to toggle `treasury.live_enabled`.

### Treasury Funding Prerequisite

The treasury module account must have a balance before live spend execution can transfer funds out.

**Five-agent devnet (automated):** The rehearsal script handles this:

```bash
# Fund treasury through a settlement with treasury routing enabled
bash scripts/testnet/product-gov.sh enable-settlement-live --confirm
bash scripts/testnet/product-gov.sh enable-settlement-treasury-routing --confirm

# Register a merchant first
$BINARY tx merchant register-merchant "$BRAVO_ADDR" "Funding Merchant" \
  "Treasury funding prereq" "https://funding.invalid" \
  --from bravo-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home rehearsals/validator-agents/bravo \
  --node "$BRAVO_RPC" --fees "$TX_FEE" --broadcast-mode sync --output json -y

# Create a settlement that routes treasury share to the module
$BINARY tx settlement create "$BRAVO_ADDR" 1000000unxrl \
  --metadata "treasury funding" \
  --from alpha-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home rehearsals/validator-agents/alpha \
  --node "$BRAVO_RPC" --fees "$TX_FEE" --broadcast-mode sync --output json -y

# Verify treasury module has funds
$BINARY query bank balances "$TREASURY_MODULE_ADDR" --node "$BRAVO_RPC"
```

### Create Treasury Account

**Five-agent devnet (exact rehearsal pattern — governance authority action):**

```bash
# This uses MsgCreateTreasuryAccount via governance authority
# Create the proposal JSON first
GOV_ADDR="nxr10d07y265gmmuvt4z0w9aw880jnsr700js8jz70"

cat > treasury-account-proposal.json <<EOF
{
  "title": "Devnet: Create Treasury Account",
  "summary": "Create a test treasury account (devnet only, zero-value tokens)",
  "messages": [
    {
      "@type": "/nexarail.treasury.v1.MsgCreateTreasuryAccount",
      "authority": "$GOV_ADDR",
      "account_id": "devnet-acct",
      "category": 1,
      "name": "Devnet Treasury Account",
      "description": "Local devnet test account",
      "metadata_uri": "",
      "nominal_balance": { "denom": "unxrl", "amount": "4000" }
    }
  ],
  "metadata": "",
  "deposit": "1000000unxrl",
  "expedited": false
}
EOF

$BINARY tx gov submit-proposal treasury-account-proposal.json \
  --from bravo-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home rehearsals/validator-agents/bravo \
  --node "$BRAVO_RPC" --fees "$TX_FEE" --broadcast-mode sync --output json -y
```

For a simpler single-node example, use the direct CLI:

```bash
$BINARY tx treasury create-account "acct-001" 0 \
  "Dev Account" "Dev test" "" 0unxrl \
  --from devnet-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y
```

### Create Budget

```bash
$BINARY tx treasury create-budget "bgt-001" "acct-001" 0 \
  "Q2 Dev Budget" "" 1000000unxrl 0 9999999999 "" \
  --from devnet-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y
```

### Request a Spend

```bash
RECIPIENT=$($BINARY keys show devnet-key -a --keyring-backend test --home "$HOME_DIR")

$BINARY tx treasury request-spend "spend-001" "acct-001" "bgt-001" "" \
  "$RECIPIENT" 5000unxrl "Developer tools" \
  --from devnet-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y
```

**Five-agent devnet (rehearsal pattern — with budget-id and reference):**

```bash
$BINARY tx treasury create-spend \
  "phase10b-spend" "phase10b-acct" "$TREASURY_RECIPIENT_ADDR" \
  "1000unxrl" "phase10b-ops-spend" \
  --budget-id "phase10b-budget" --reference "phase10b-spend-request" \
  --memo "local rehearsal" \
  --from alpha-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home rehearsals/validator-agents/alpha \
  --node "$BRAVO_RPC" --fees "$TX_FEE" --broadcast-mode sync --output json -y
```

### Approve Spend (Authority Action via Governance Proposal)

For the treasury module, approval and execution of spend requests are authority actions requiring a governance proposal:

```bash
cat > approve-execute-spend.json <<EOF
{
  "title": "Devnet: Approve & Execute Spend",
  "summary": "Approve and execute treasury spend (devnet only)",
  "messages": [
    {
      "@type": "/nexarail.treasury.v1.MsgApproveSpendRequest",
      "authority": "$GOV_ADDR",
      "spend_id": "spend-001"
    },
    {
      "@type": "/nexarail.treasury.v1.MsgMarkSpendExecuted",
      "authority": "$GOV_ADDR",
      "spend_id": "spend-001",
      "reference": "executed-ref",
      "memo": "local devnet"
    }
  ],
  "metadata": "",
  "deposit": "1000000unxrl",
  "expedited": false
}
EOF

$BINARY tx gov submit-proposal approve-execute-spend.json \
  --from bravo-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home rehearsals/validator-agents/bravo \
  --node "$BRAVO_RPC" --fees "$TX_FEE" --broadcast-mode sync --output json -y
```

> **Important:** On a fresh five-agent devnet, submit from `bravo-key` and all 5 agents must vote yes.

### Query Treasury State

```bash
# Spend request
$BINARY query treasury spend spend-001 --node "$NODE"

# Treasury summary
$BINARY query treasury summary --node "$NODE"

# All accounts
curl -s http://127.0.0.1:$REST_PORT/nexarail/treasury/v1/accounts | jq .

# REST query by ID
curl -s http://127.0.0.1:$REST_PORT/nexarail/treasury/v1/spend/spend-001 | jq .
```

---

## 9. Governance Flag Toggle (Using product-gov.sh)

All live-funds toggles require a governance proposal. The `product-gov.sh` script automates this for the five-agent devnet.

### Quick Reference

```bash
# View current live flags
bash scripts/testnet/product-gov.sh show-live-flags

# ── Settlement ───────────────────────────────────────
bash scripts/testnet/product-gov.sh enable-settlement-live [--confirm]
bash scripts/testnet/product-gov.sh disable-settlement-live [--confirm]
bash scripts/testnet/product-gov.sh enable-settlement-treasury-routing [--confirm]
bash scripts/testnet/product-gov.sh disable-settlement-treasury-routing [--confirm]
bash scripts/testnet/product-gov.sh enable-settlement-burn-routing [--confirm]
bash scripts/testnet/product-gov.sh disable-settlement-burn-routing [--confirm]

# ── Escrow ───────────────────────────────────────────
bash scripts/testnet/product-gov.sh enable-escrow-live [--confirm]
bash scripts/testnet/product-gov.sh disable-escrow-live [--confirm]

# ── Treasury ─────────────────────────────────────────
bash scripts/testnet/product-gov.sh enable-treasury-live [--confirm]
bash scripts/testnet/product-gov.sh disable-treasury-live [--confirm]

# ── Payout ───────────────────────────────────────────
bash scripts/testnet/product-gov.sh enable-payout-live [--confirm]
bash scripts/testnet/product-gov.sh disable-payout-live [--confirm]
```

### What --confirm Does

1. Reads the current on-chain params via REST API
2. Preserves all existing parameter values (only toggles the target flag)
3. Generates a signed governance proposal (`MsgUpdateParams`)
4. Broadcasts via CometBFT RPC
5. All 5 validator agents vote Yes
6. Waits for the proposal to pass (30s voting period on devnet)
7. Writes evidence to `rehearsals/validator-agents/product-flows/gov-toggles/`

### Safety Rules (Enforced by product-gov.sh)

| Toggle | Prerequisite |
|--------|-------------|
| `enable-settlement-treasury-routing` | `settlement.live_enabled` must be `true` |
| `enable-settlement-burn-routing` | `settlement.live_enabled` + `treasury_routing_enabled` must be `true` |

### Manual Governance Proposal Path (Single-Node Devnet)

If not using the five-agent devnet, submit governance proposals manually:

```bash
# 1. Create a param change proposal
#    (Mnemonic: using MsgUpdateParams for the settlement module)
cat > enable-settlement-live.json <<EOF
{
  "title": "Enable Settlement Live Transfers",
  "summary": "Enable live settlement fund transfers (devnet only, zero-value tokens)",
  "messages": [
    {
      "@type": "/nexarail.settlement.v1.MsgUpdateParams",
      "authority": "nxr110d07y265gmmuvt4z0w9aw880jnsr700js8jz70",
      "params": {
        "enabled": true,
        "live_enabled": true,
        "treasury_routing_enabled": false,
        "burn_routing_enabled": false,
        "fee_rate_bps": 100,
        "rebate_tiers": [0, 500, 1000, 1500, 2000]
      }
    }
  ],
  "metadata": "",
  "deposit": "1000000unxrl",
  "expedited": false
}
EOF

# 2. Submit the proposal
$BINARY tx gov submit-proposal enable-settlement-live.json \
  --from devnet-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y

# 3. Vote yes (find the proposal ID first)
$BINARY query gov proposals --node "$NODE"
# Note the proposal ID (e.g., 1)
$BINARY tx gov vote 1 yes \
  --from devnet-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y

# 4. Wait for voting period to end (30s on devnet)
sleep 35

# 5. Verify the flag changed
$BINARY query settlement params --node "$NODE"
# Expected: live_enabled: true

# 6. Verify via REST
curl -s http://127.0.0.1:$REST_PORT/nexarail/settlement/v1/params | jq '.params.live_enabled'
```

### Offline Signing Path (--generate-only + --offline)

When the node cannot query account state (e.g., for orchestrated multi-step flows):

```bash
# 1. Query account number and sequence
$BINARY query auth account "$BRAVO_ADDR" --node "$BRAVO_RPC" --output json
# Note the account_number and sequence values

# 2. Generate the unsigned tx
$BINARY tx gov submit-proposal enable-escrow-live.json \
  --from bravo-key --keyring-backend test \
  --home rehearsals/validator-agents/bravo \
  --chain-id "$CHAIN_ID" --node "$BRAVO_RPC" \
  --generate-only --fees "$TX_FEE" \
  > unsigned.json

# 3. Sign offline (must provide --account-number and --sequence)
$BINARY tx sign unsigned.json \
  --offline --account-number 42 --sequence 5 \
  --from bravo-key --keyring-backend test \
  --home rehearsals/validator-agents/bravo \
  --chain-id "$CHAIN_ID" \
  > signed.json

# 4. Encode and broadcast via CometBFT RPC
$BINARY tx encode signed.json | tr -d '\n' > signed.b64
curl -s http://127.0.0.1:27667/ \
  -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"broadcast_tx_sync\",\"params\":{\"tx\":\"$(cat signed.b64)\"},\"id\":1}"
```

---

## 10. Cleanup

### Stop the Devnet

**Single-node:**

```bash
bash scripts/release/stop-rc1-devnet.sh
```

For aggressive process kill:

```bash
bash scripts/release/stop-rc1-devnet.sh --force
```

**Five-agent:**

```bash
bash scripts/testnet/stop-validator-agents.sh
bash scripts/testnet/stop-validator-agents.sh --force
```

### Remove Home Directory

```bash
# Single-node devnet state
rm -rf ~/.nexarail-devnet

# Five-agent devnet state
rm -rf rehearsals/rc1-devnet
rm -rf rehearsals/validator-agents
```

The `--clean` flag on `launch-rc1-devnet.sh` does this automatically.

---

## 11. Troubleshooting

### Account Sequence Mismatch

```
account sequence mismatch, expected 3, got 2
```

**Cause:** A prior transaction was broadcast but not confirmed before the next one was submitted. The signing node's sequence counter in the keyring hasn't caught up with on-chain state.

**Fix:**

```bash
# Option 1: Wait for pending tx to confirm, then retry
sleep 5

# Option 2: Query the current on-chain sequence
$BINARY query auth account "$ADDRESS" --node "$NODE" --output json | jq '.account.sequence // .account.base_account.sequence'

# Option 3: Manually increment sequence with --sequence flag (offline mode)
$BINARY tx bank send ... --offline --account-number 42 --sequence 5
```

### Gas Estimation Failure

```
gas estimate: out of gas
```

**Fix:** Increase the gas adjustment or set a manual gas limit:

```bash
GAS="--gas auto --gas-adjustment 2.0 --gas-prices 0.0025unxrl"
# Or
GAS="--gas 300000"
```

### Insufficient Funds

```
insufficient funds
```

**Fix:** Check the account balance and fund if needed:

```bash
$BINARY query bank balances "$ADDRESS" --node "$NODE"
$BINARY tx bank send devnet-key "$ADDRESS" 10000000unxrl \
  --from devnet-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home "$HOME_DIR" $GAS -y
```

**Five-agent devnet:**

```bash
$BINARY query bank balances "$BRAVO_ADDR" --node "$BRAVO_RPC"
$BINARY tx bank send alpha-key "$BRAVO_ADDR" 10000000unxrl \
  --from alpha-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home rehearsals/validator-agents/alpha \
  --node "$BRAVO_RPC" --fees "$TX_FEE" --broadcast-mode sync --output json -y
```

### Governance Proposal Deposit

```
proposal deposit: minimum deposit of 1000000unxrl not met
```

**Fix:** Ensure the submitter account has sufficient funds for both the deposit and transaction fees:

```bash
# Check balance
$BINARY query bank balances "$BRAVO_ADDR" --node "$BRAVO_RPC"

# If insufficient, fund from a wealthy account
$BINARY tx bank send alpha-key "$BRAVO_ADDR" 50000000unxrl \
  --from alpha-key --chain-id "$CHAIN_ID" \
  --keyring-backend test --home rehearsals/validator-agents/alpha \
  --node "$BRAVO_RPC" --fees "$TX_FEE" --broadcast-mode sync --output json -y
```

### Governance Proposal Fails (No-Vote)

```
proposal status: PROPOSAL_STATUS_FAILED
```

**Fix:** All 5 agents must vote yes for the proposal to pass on the devnet. Ensure all agents vote:

```bash
for agent in alpha bravo charlie delta echo; do
  $BINARY tx gov vote "$PROPOSAL_ID" yes \
    --from "${agent}-key" --keyring-backend test \
    --home "rehearsals/validator-agents/$agent" \
    --chain-id "$CHAIN_ID" --node "$BRAVO_RPC" \
    --fees "2000unxrl" --broadcast-mode sync --output json -y
  sleep 1
done
```

### Transaction Not Found

```
tx (HASH) not found by CometBFT tx query
```

**Cause:** Transaction broadcast timed out before the next block was produced. The tx may still be in the mempool.

**Fix:** Wait for more blocks and retry the query:

```bash
sleep 10
curl -s "http://127.0.0.1:26657/tx?hash=0x$TX_HASH" | jq .
```

If still not found, the transaction was likely rejected at CheckTx. Check the mempool:

```bash
curl -s http://127.0.0.1:26657/unconfirmed_txs | jq '.result.n_txs'
```

### REST API Returns Empty or Error

**Fix:** Ensure the node is running and the REST API is enabled:

```bash
# Check node status
curl -s http://127.0.0.1:26657/status | jq '.result.sync_info.latest_block_height'

# Check REST API is listening
curl -s http://127.0.0.1:1317/nexarail/merchant/v1/params | jq .

# Common issue: REST port differs on five-agent (bravo API = 1418, not 1317)
curl -s http://127.0.0.1:1418/nexarail/merchant/v1/params | jq .
```

---

## Flow Dependency Map

```
account setup
      │
      ├── bank send (smoke test)
      │
      ├── merchant registration ──────────────────────────────┐
      │            │                                          │
      │            ├── settlement (metadata) ◄── live_enabled ─┼──► settlement (live transfer)
      │            │                    │    treasury_routing ─┤──► + treasury share
      │            │                    │    burn_routing ─────┤──► + burn to supply
      │            │                    │                      │
      │            ├── escrow (metadata) ◄── live_enabled ─────┤──► escrow (fund custody/release)
      │            │                                           │
      │            └── treasury account + budget ──────────────┤
      │                           │                            │
      │                           └── treasury spend ──────────┤
      │                           (metadata) ◄── live_enabled ─┘──► treasury spend (fund transfer)
      │
      └── payout (metadata) ◄── live_enabled ──► payout (fund transfer)
```

---

## Reference

| Resource | Location |
|----------|----------|
| Full automated rehearsal | `scripts/testnet/run-product-flow-rehearsal.sh` |
| Governance flag helper | `scripts/testnet/product-gov.sh` |
| API smoke test | `scripts/testnet/api-smoke-test.sh` |
| CLI E2E smoke test | `scripts/testnet/cli-e2e-smoke-test.sh` |
| Devnet launcher | `scripts/release/launch-rc1-devnet.sh` |
| REST API examples | `docs/developers/API_EXAMPLES.md` |
| Developer quickstart | `docs/developers/DEVELOPER_QUICKSTART.md` |
| Product flow examples | `docs/developers/PRODUCT_FLOW_EXAMPLES.md` |
