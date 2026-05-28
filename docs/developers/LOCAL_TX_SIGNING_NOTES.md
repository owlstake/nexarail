# NexaRail Local Transaction Signing Notes

> ⚠️ **LOCAL DEVNET ONLY — NOT PRODUCTION SIGNING INFRASTRUCTURE**
>
> This document describes transaction signing on a local NexaRail devnet.
> - All keys are test keys (`--keyring-backend test`).
> - All tokens are test tokens with **zero monetary value**.
> - **No mainnet** exists. **No public testnet** exists.
> - **No private keys are shared or printed.** Keys live in the filesystem home directory.
> - **Do not use these patterns against any network holding real funds.**
> - **This is not a wallet, not a custodial solution, and not production-ready.**

---

## 1. Online Signing Path (Default)

The simplest approach. The CLI node connection queries the account number and sequence automatically.

```bash
# Example: bank send with online signing
$BINARY tx bank send alice "$BOB" 1000unxrl \
  --chain-id nexarail-devnet-1 \
  --keyring-backend test \
  --home "$HOME_DIR" \
  --node tcp://localhost:26657 \
  --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl \
  -y
```

**What happens under the hood:**

1. The CLI connects to the node at `--node`
2. It queries the `alice` account to get `account_number` and `sequence`
3. It builds the transaction
4. It signs using the key from `--keyring-backend test` at `--home`
5. It broadcasts the signed transaction to the node
6. The node returns the tx hash and initial check result

**When to use:** Most development scenarios. Simple, automatic, reliable.

---

## 2. Offline Signing Path (`--offline`)

Requires manual `--account-number` and `--sequence` values. Use when the signing environment cannot reach the node.

```bash
# Step 1: Query the account state first (from a node-connected machine)
$BINARY query auth account nxrl1abc... --node tcp://localhost:26657 --output json
```

Expected response (truncated):

```json
{
  "@type": "/cosmos.auth.v1beta1.BaseAccount",
  "address": "nxrl1abc...",
  "pub_key": null,
  "account_number": "42",
  "sequence": "5"
}
```

```bash
# Step 2: Build the unsigned transaction
$BINARY tx bank send alice "$BOB" 1000unxrl \
  --chain-id nexarail-devnet-1 \
  --keyring-backend test \
  --home "$HOME_DIR" \
  --fees 10000unxrl \
  --generate-only \
  --output json \
  > unsigned_tx.json

# Step 3: Sign offline
$BINARY tx sign unsigned_tx.json \
  --offline \
  --account-number 42 \
  --sequence 5 \
  --from alice \
  --keyring-backend test \
  --home "$HOME_DIR" \
  --chain-id nexarail-devnet-1 \
  > signed_tx.json

# Step 4: Broadcast the signed transaction
$BINARY tx broadcast signed_tx.json \
  --node tcp://localhost:26657 \
  --output json
```

### When to Use Offline Signing

- **Orchestrated multi-step flows** where you need fine-grained control over signing order
- **Governance proposal submission in scripts** (the rehearsal script uses this pattern — see `submit_gov_messages` in `scripts/testnet/run-product-flow-rehearsal.sh`)
- **Disconnected signing environments** where the signer cannot reach the node

---

## 3. Account Number / Sequence Caution

> **Sequence mismatch is the #1 cause of `account sequence mismatch` errors.**

```
account sequence mismatch, expected 3, got 2
```

### Why This Happens

Every transaction increments the signing account's `sequence` field by 1. The sequence is a replay-protection counter:

- The **node's** sequence reflects the number of transactions already committed from this account
- The **signer's** sequence may lag if a prior transaction was broadcast but not yet committed

### Online Mode

The CLI queries the node's current sequence automatically. But if you send two transactions back-to-back:

```bash
# Transaction 1: sequence acquired = 5, committed → sequence becomes 6 on-chain
$BINARY tx bank send alice "$BOB" 1000unxrl ... --broadcast-mode sync -y

# Transaction 2 (sent immediately): sequence queried = 5 (stale!), should be 6
# This fails with "account sequence mismatch, expected 6, got 5"
$BINARY tx bank send alice "$CHARLIE" 500unxrl ... --broadcast-mode sync -y
```

**Fix:** Wait for the first transaction to be committed before sending the second, or use `--broadcast-mode block` (deprecated in newer CometBFT):

```bash
# Wait for inclusion
sleep 5

# Optionally verify the tx was committed
$BINARY query tx "$TX_HASH" --node "$NODE"
```

### Offline Mode

You must track the sequence manually. Each transaction, even a failed one, increments the sequence on-chain.

| Scenario | Sequence Behaviour |
|----------|-------------------|
| Tx A succeeds | sequence_increments by 1 |
| Tx A fails at CheckTx | sequence NOT incremented |
| Tx A fails at DeliverTx | sequence INCREMENTED (tx was included) |

**Tip:** After any broadcast, always re-query the account state to get the current sequence before signing the next offline transaction:

```bash
# After each broadcast, refresh:
$BINARY query auth account "$ADDRESS" --node "$NODE" --output json | \
  jq '{account_number: .account.base_account.account_number, sequence: .account.base_account.sequence}'
```

---

## 4. Signing Modes Overview

| Mode | Flag | Account Number | Sequence | Use Case |
|------|------|----------------|----------|----------|
| **Online** (default) | _(none)_ | Auto-queried | Auto-queried | Most dev work, simple scripts |
| **Offline** | `--offline` | Manual (`--account-number`) | Manual (`--sequence`) | Disconnected signers, orchestrated flows |
| **Generate-only** | `--generate-only` | Not signed | Not signed | Building unsigned JSON for later signing |
| **Broadcast-only** | _(via `tx broadcast`)_ | Already signed | Already signed | Submitting a pre-signed transaction |

### Typical Pipeline

```
tx build ... --generate-only   →  unsigned_tx.json
tx sign unsigned.json [--offline]  →  signed_tx.json
tx broadcast signed_tx.json    →  commit result
```

### Broadcast Modes

| Mode | Flag | Behaviour |
|------|------|-----------|
| **Sync** | `--broadcast-mode sync` | Returns after CheckTx. Tx may not be committed yet. |
| **Async** | `--broadcast-mode async` | Returns immediately after tx is in mempool. No check result. |
| **Block** | `--broadcast-mode block` | (Deprecated in CometBFT v0.38+) Waits for tx to be included in a block. |

The rehearsal script uses `--broadcast-mode sync` and then polls for inclusion via `wait_for_tx()` (a loop that queries `{rpc}/tx?hash=0x{HASH}` every 2 seconds for up to 60 seconds).

---

## 5. Keyring: `test` Backend

The devnet uses `--keyring-backend test`, which stores keys unencrypted in the filesystem.

```bash
# Keys are stored at:
#   Single-node: ~/.nexarail-devnet/keyring-test/
#   Five-agent:  rehearsals/validator-agents/{agent}/keyring-test/

# List keys
$BINARY keys list --keyring-backend test --home "$HOME_DIR"

# Show a key's address
$BINARY keys show devnet-key -a --keyring-backend test --home "$HOME_DIR"

# Export a private key (JSON format — public key info only, NOT seed phrase)
$BINARY keys export devnet-key --keyring-backend test --home "$HOME_DIR"

# Export a mnemonic seed phrase (❗this reveals the private key — be careful)
$BINARY keys mnemonic --keyring-backend test 2>/dev/null
```

### ⚠️ IMPORTANT: Private Key Handling

- **Private keys are never printed or shared by any NexaRail command.** The `--keyring-backend test` stores the encrypted (or unencrypted for `test` mode) key file in the home directory.
- The key file is accessible only to the user who created it (filesystem permissions).
- **Do not copy or distribute keyring files** between machines or users — these are local test keys only.
- On production (when it exists), the keyring backend should be `os` (macOS Keychain) or `file` (password-protected).

### Recovering a Key from Mnemonic

```bash
$BINARY keys add recovered-key \
  --recover \
  --keyring-backend test \
  --home "$HOME_DIR"
# You will be prompted to enter the 24-word mnemonic seed phrase
```

---

## 6. Governance Proposal Signing

Governance proposals in NexaRail follow the offline signing pattern because a `--generate-only` step is required to build the proposal JSON, followed by signing with the `--offline` flag.

### Full Governance Signing Pipeline

From the rehearsal script's `submit_gov_messages` function:

```bash
# Example: Set settlement params via governance (pseudocode of actual flow)

# 1. Query the submitter account for account_number and sequence
$BINARY query auth account "$SUBMITTER_ADDR" --node "$RPC" --output json

# 2. Generate unsigned proposal
$BINARY tx gov submit-proposal proposal.json \
  --from bravo-key --keyring-backend test --home "$AGENT_DIR/bravo" \
  --chain-id nexarail-agent-testnet-1 --node "$RPC" \
  --generate-only --fees 10000unxrl \
  > unsigned_proposal.json

# 3. Sign offline (must use the account_number and sequence from step 1)
$BINARY tx sign unsigned_proposal.json \
  --offline --account-number 42 --sequence 5 \
  --from bravo-key --keyring-backend test --home "$AGENT_DIR/bravo" \
  --chain-id nexarail-agent-testnet-1 \
  > signed_proposal.json

# 4. Encode for CometBFT RPC broadcast
$BINARY tx encode signed_proposal.json | tr -d '\n' > signed.b64

# 5. Broadcast via CometBFT RPC
curl -s "http://127.0.0.1:27667/" \
  -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"broadcast_tx_sync\",\"params\":{\"tx\":\"$(cat signed.b64)\"},\"id\":1}"
```

### Why Broadcast via CometBFT RPC Instead of CLI?

The `$BINARY tx broadcast` CLI command uses the gRPC endpoint, which requires gRPC to be enabled. The CometBFT RPC broadcast (`broadcast_tx_sync`) works on a different port and is more reliable for scripted governance flows.

### Governance Sequence Tracking

Each governance proposal submission increments the submitter's sequence by 1. If voting or submission happen from the same account, sequence tracking must be precise:

```bash
# Track sequences for a multi-proposal session
SEQUENCE=5  # initial sequence from query
for proposal_id in 1 2 3; do
  # Sign with current sequence
  $BINARY tx sign unsigned_${proposal_id}.json \
    --offline --account-number 42 --sequence "$SEQUENCE" \
    --from bravo-key --keyring-backend test --home "$AGENT_DIR/bravo" \
    --chain-id nexarail-agent-testnet-1 \
    > signed_${proposal_id}.json
  # ... broadcast ...
  SEQUENCE=$((SEQUENCE + 1))  # increment locally
done
```

---

## 7. Why This Is Local/Devnet Only

| Aspect | Devnet (Local) | Mainnet (Future) |
|--------|----------------|-------------------|
| Keyring | `test` (unencrypted filesystem) | `os` (OS keychain) or `file` (password) |
| Keys | Generated for testing | Derived from secure seed phrases |
| Tokens | `unxrl` with zero value | Real NXRL with market value |
| Network | Single machine, `localhost` | Distributed validator set |
| RPC | Open, no auth | Authenticated and rate-limited |
| Signing infrastructure | CLI only | CLI + SDK + hardware wallets |
| Sequence tracking | Manual or auto (simple) | Nonce management (critical) |

**Do not use `--keyring-backend test` with any account that holds real funds.** The `test` backend stores keys in plaintext and is suitable only for local development.

---

## 8. Common Signing Errors

### `account sequence mismatch`

**Error text:** `account sequence mismatch, expected 3, got 2`

**Cause:** The signer's sequence counter is stale.

**Fix:**

```bash
# Re-query the account to get the correct sequence
$BINARY query auth account "$ADDRESS" --node "$NODE" --output json | \
  jq '{sequence: .account.base_account.sequence}'

# Resign with the correct sequence
$BINARY tx sign unsigned_tx.json \
  --offline --account-number 42 --sequence "$CORRECT_SEQUENCE" \
  ... \
  > resigned_tx.json
```

### `key not found`

**Error text:** `key "alice" not found`

**Cause:** The key doesn't exist at the specified `--home` path.

**Fix:**

```bash
# List available keys
$BINARY keys list --keyring-backend test --home "$HOME_DIR"

# Create the key if missing
$BINARY keys add alice --keyring-backend test --home "$HOME_DIR"
```

### `signing key does not match the from address`

**Error text:** `signing key "alice" does not match the from address "nxrl1..."`

**Cause:** The `--from` key name does not resolve to the address in the generated transaction (usually a `--generate-only` mismatch).

**Fix:** Ensure `--from` matches the address that was used when creating the unsigned transaction.

### `no keyring backend specified`

**Error text:** `No keyring backend specified`

**Cause:** `--keyring-backend` was omitted or the default backend type is not `test`.

**Fix:** Always include `--keyring-backend test` on devnet.

---

## 9. Quick Reference

```bash
# ── Query Account ──
$BINARY query auth account "$ADDR" --node "$NODE" --output json | \
  jq '.account.base_account | {address, account_number, sequence}'

# ── Online Sign ──
$BINARY tx bank send "$FROM" "$TO" "$AMOUNT" \
  --chain-id "$CHAIN_ID" --keyring-backend test --home "$HOME_DIR" \
  --node "$NODE" --gas auto --gas-adjustment 1.5 --gas-prices 0.0025unxrl -y

# ── Offline Sign ──
$BINARY tx bank send "$FROM" "$TO" "$AMOUNT" \
  --chain-id "$CHAIN_ID" --fees 10000unxrl \
  --generate-only > unsigned.json

$BINARY tx sign unsigned.json \
  --offline --account-number 42 --sequence 5 \
  --from "$FROM" --keyring-backend test --home "$HOME_DIR" \
  --chain-id "$CHAIN_ID" > signed.json

$BINARY tx broadcast signed.json --node "$NODE"

# ── Governance Offline ──
$BINARY tx gov submit-proposal proposal.json \
  --from bravo-key --keyring-backend test --home "$AGENT_DIR/bravo" \
  --chain-id "$CHAIN_ID" --node "$RPC" --generate-only --fees 10000unxrl \
  > unsigned_proposal.json

$BINARY tx sign unsigned_proposal.json \
  --offline --account-number 42 --sequence 5 \
  --from bravo-key --keyring-backend test --home "$AGENT_DIR/bravo" \
  --chain-id "$CHAIN_ID" > signed_proposal.json

$BINARY tx broadcast signed_proposal.json --node "$RPC"
```

---

## Reference

- Full online signing example: `docs/developers/WRITE_FLOW_EXAMPLES.md`
- Offline signing in rehearsal script: `scripts/testnet/run-product-flow-rehearsal.sh` (function `submit_gov_messages`)
- Governance flag toggles: `scripts/testnet/product-gov.sh`
- Cosmos SDK account documentation: https://docs.cosmos.network/main/user/run-node/txs
