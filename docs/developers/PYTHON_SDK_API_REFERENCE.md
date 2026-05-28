# NexaRail Python SDK — API Reference

**Package:** `nexarail-devnet-client` (v0.1.0.dev)

**Source:** `examples/python-client/nexarail_client.py`

**Compatible with:** NexaRail Controlled Testnet RC1 (`nexarail-devnet-1`)

---

## Overview

The NexaRail Python SDK is a lightweight, zero-dependency client for querying the NexaRail RC1 devnet and building CLI command strings. It uses only Python standard library modules (`json`, `os`, `urllib.request`, `sys`) — no `pip install` required for basic script usage.

The SDK provides **18 public functions** across two categories (plus `api_url()` and `rpc_url()` URL helpers):

- **8 read-only query functions** — synchronous, return `dict`, call the Cosmos SDK REST API
- **10 command-string builders** — synchronous, return `str`, do NOT execute anything

---

## Quick Start

```python
from nexarail_client import get_params, treasury_summary, node_status

# Query a module's parameters
params = get_params('settlement')
print('Settlement live_enabled:', params.get('live_enabled'))

# Get treasury summary
treasury = treasury_summary()
print('Treasury balance:', treasury)

# Check node status
status = node_status()
print('Block height:', status['sync_info']['latest_block_height'])
```

---

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `API` | `http://localhost:1317` | Cosmos SDK REST API base URL |
| `RPC` | `http://localhost:26657` | CometBFT RPC endpoint for node status |

Override at runtime:

```bash
API=http://localhost:1317 RPC=http://localhost:26657 python3 my_script.py
```

---

## ⚠️ Safety Warning

```
╔══════════════════════════════════════════════════════════════════════════╗
║  ⚠  LOCAL DEVNET ONLY                                                 ║
║                                                                        ║
║  • NOT for mainnet or any public testnet                               ║
║  • NOT published to PyPI — local install only                          ║
║  • NOT a token sale or launch tool                                     ║
║  • NO private key or mnemonic handling                                 ║
║  • Command builders return strings — they do NOT execute transactions  ║
╚══════════════════════════════════════════════════════════════════════════╝
```

---

## URL Helpers

---

### `api_url`

- **Label:** `(helper)`
- **Purpose:** Return the configured Cosmos SDK REST API base URL.
- **Signature:** `def api_url() -> str`
- **Parameters:** None
- **Returns:** String URL. Reads from `API` environment variable, defaults to `http://localhost:1317`.

**Example:**

```python
from nexarail_client import api_url

print('Using API:', api_url())
# Using API: http://localhost:1317
```

---

### `rpc_url`

- **Label:** `(helper)`
- **Purpose:** Return the configured CometBFT RPC URL.
- **Signature:** `def rpc_url() -> str`
- **Parameters:** None
- **Returns:** String URL. Reads from `RPC` environment variable, defaults to `http://localhost:26657`.

**Example:**

```python
from nexarail_client import rpc_url

print('Using RPC:', rpc_url())
# Using RPC: http://localhost:26657
```

---

## Read-Only Query Functions

---

### `get`

- **Label:** `(read-only)`
- **Purpose:** Make a raw REST GET request to any path on the devnet API.
- **Signature:** `def get(path: str) -> dict`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `path` | `str` | — | URL path to query (appended to `api_url()` base) |

- **Returns:** Parsed JSON response body as a `dict`. Returns `{"error": "HTTP {code}"}` on HTTP errors. Returns `{"error": str(e)}` on connection errors.
- **Notes:** All other read functions call this internally. You normally won't need it directly.

**Example:**

```python
from nexarail_client import get

result = get('/nexarail/settlement/v1/params')
print(result)
# {'live_enabled': False, 'treasury_routing_enabled': False, ...}
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `get_params`

- **Label:** `(read-only)`
- **Purpose:** Query the parameters of a NexaRail module, including the `live_enabled` flag.
- **Signature:** `def get_params(module: str) -> dict`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `module` | `str` | — | Module name (e.g. `'settlement'`, `'escrow'`, `'treasury'`, `'payout'`) |

- **Returns:** Module parameters as a `dict`. Contains `live_enabled` and module-specific fields such as `treasury_routing_enabled`, `burn_routing_enabled`, fee parameters, etc.
- **Endpoint:** `GET /nexarail/{module}/v1/params`

**Example:**

```python
from nexarail_client import get_params

settlement_params = get_params('settlement')
print('Live:', settlement_params.get('live_enabled'))
print('Treasury routing:', settlement_params.get('treasury_routing_enabled'))
print('Burn routing:', settlement_params.get('burn_routing_enabled'))

# Check all modules
for mod in ['settlement', 'escrow', 'treasury', 'payout']:
    p = get_params(mod)
    print(f'{mod}: live={p.get("live_enabled")}')
# Settlement: live=False
# Escrow: live=False
# Treasury: live=False
# Payout: live=False
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `get_list`

- **Label:** `(read-only)`
- **Purpose:** List all resources of a given type within a module.
- **Signature:** `def get_list(module: str, resource: str) -> dict`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `module` | `str` | — | Module name (e.g. `'settlement'`, `'treasury'`) |
| `resource` | `str` | — | Resource name (e.g. `'settlement'`, `'merchant'`, `'escrow'`, `'payout'`) |

- **Returns:** `dict` with a `list` or named array key containing all items. Returns an empty list when no items exist.
- **Endpoint:** `GET /nexarail/{module}/v1/{resource}`

**Example:**

```python
from nexarail_client import get_list

# List all merchants
merchants = get_list('treasury', 'merchant')
merchant_list = merchants.get('merchant') or merchants.get('list') or []
print(f'Found {len(merchant_list)} merchants')

# List all settlements
settlements = get_list('settlement', 'settlement')
settlement_list = settlements.get('settlement') or settlements.get('list') or []
print(f'Found {len(settlement_list)} settlements')

# List all escrows
escrows = get_list('escrow', 'escrow')
escrow_list = escrows.get('escrow') or escrows.get('list') or []
print(f'Found {len(escrow_list)} escrows')
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `get_detail`

- **Label:** `(read-only)`
- **Purpose:** Get a single resource item by ID.
- **Signature:** `def get_detail(module: str, resource: str, id_: str) -> dict`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `module` | `str` | — | Module name |
| `resource` | `str` | — | Resource name |
| `id_` | `str` | — | Unique identifier of the resource item |

- **Returns:** `dict` representing the resource item. Returns `{"error": "HTTP 404"}` or an error dict if not found.
- **Endpoint:** `GET /nexarail/{module}/v1/{resource}/{id}`

**Example:**

```python
from nexarail_client import get_detail

# Get merchant by ID (will 404 on empty devnet)
merch = get_detail('treasury', 'merchant', 'merchant-1')
if 'error' in merch:
    print('Merchant not found:', merch['error'])
else:
    print('Merchant:', merch)

# Get settlement by ID
settlement = get_detail('settlement', 'settlement', 'settlement-order-001')
if 'error' not in settlement:
    print('Settlement:', settlement)
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `get_exists`

- **Label:** `(read-only)`
- **Purpose:** Check whether a resource item exists by ID.
- **Signature:** `def get_exists(module: str, resource: str, id_: str) -> dict`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `module` | `str` | — | Module name |
| `resource` | `str` | — | Resource name |
| `id_` | `str` | — | Unique identifier to check |

- **Returns:** `dict`. For an existing item, returns the item data. For a non-existent item, returns a response indicating not-found.
- **Endpoint:** `GET /nexarail/{module}/v1/{resource}/exists/{id}`

**Example:**

```python
from nexarail_client import get_exists

# Check if an escrow exists
existing = get_exists('escrow', 'escrow', 'escrow-1')
print('Escrow escrow-1 exists:', 'error' not in existing)

non_existing = get_exists('escrow', 'escrow', 'nonexistent-id')
print('Escrow nonexistent-id exists:', 'error' not in non_existing)

# Check if a payout exists
payout_check = get_exists('payout', 'payout', 'payout-Q2-001')
print('Payout exists:', 'error' not in payout_check)
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `get_filtered`

- **Label:** `(read-only)`
- **Purpose:** Query resources filtered by a specific field and value.
- **Signature:** `def get_filtered(module: str, resource: str, filter_name: str, value: str) -> dict`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `module` | `str` | — | Module name |
| `resource` | `str` | — | Resource name |
| `filter_name` | `str` | — | Filter field name (e.g. `'status'`, `'owner'`) |
| `value` | `str` | — | Filter value to match |

- **Returns:** `dict` with a `list` or named array key containing matching items. Returns an empty list when no items match.
- **Endpoint:** `GET /nexarail/{module}/v1/{resource}/{filter}/{value}`

**Example:**

```python
from nexarail_client import get_filtered

# Filter settlements by status
pending = get_filtered('settlement', 'settlement', 'status', 'pending')
pending_list = pending.get('settlement') or pending.get('list') or []
print(f'Pending settlements: {len(pending_list)}')

# Filter escrows by buyer
owned = get_filtered('escrow', 'escrow', 'buyer', 'nxr1buyeraddress')
owned_list = owned.get('escrow') or owned.get('list') or []
print(f'Escrows for buyer: {len(owned_list)}')

# Filter payouts by merchant
payouts = get_filtered('payout', 'payout', 'merchant', 'merchant-1')
payout_list = payouts.get('payout') or payouts.get('list') or []
print(f'Payouts for merchant-1: {len(payout_list)}')
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `treasury_summary`

- **Label:** `(read-only)`
- **Purpose:** Get a summary of the treasury accounts, including balances and funding totals.
- **Signature:** `def treasury_summary() -> dict`
- **Parameters:** None
- **Returns:** `dict` with treasury summary fields such as account balances, total funding, and spending details.
- **Endpoint:** `GET /nexarail/treasury/v1/summary`

**Example:**

```python
from nexarail_client import treasury_summary

summary = treasury_summary()
print('Treasury summary:')
for key, value in summary.items():
    print(f'  {key}: {value}')
# Example output on an empty devnet:
#   total_funding: "0unxrl"
#   total_spent: "0unxrl"
#   account_count: 0
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `node_status`

- **Label:** `(read-only)`
- **Purpose:** Query the CometBFT RPC endpoint for node status, including block height, chain ID, validator info, and sync status.
- **Signature:** `def node_status() -> dict`
- **Parameters:** None
- **Returns:** `dict` `result` object from the CometBFT `/status` endpoint, containing `node_info`, `sync_info`, and `validator_info`.
- **Endpoint:** `GET {rpc_url()}/status`

**Example:**

```python
from nexarail_client import node_status

status = node_status()
print('Chain ID:', status['node_info']['network'])
print('Block height:', status['sync_info']['latest_block_height'])
print('Catching up:', status['sync_info']['catching_up'])
print('Validator:', status['validator_info']['address'])
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

## Command-String Builders

All command builders are synchronous functions that return a formatted CLI command string. **They do not execute the command.** They build strings suitable for copy-paste into a terminal running `nexaraild`.

**Common default values:**

```python
binary='releases/testnet-rc1/binaries/nexaraild-darwin-arm64'
home='~/.nexarail-devnet'
chain_id='nexarail-devnet-1'
keyring='test'
```

---

### `bank_send_cmd`

- **Label:** `(command-builder)`
- **Purpose:** Build a `nexaraild tx bank send` CLI command string.
- **Signature:** `def bank_send_cmd(from_addr: str, to: str, amount: str | int | float, denom: str, binary: str, home: str, chain_id: str, keyring: str) -> str`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `from_addr` | `str` | — | Sender address or key name |
| `to` | `str` | — | Recipient address |
| `amount` | `str \| int \| float` | — | Numeric amount (e.g. `1000000`) |
| `denom` | `str` | `'unxrl'` | Coin denomination |
| `binary` | `str` | `'releases/testnet-rc1/binaries/nexaraild-darwin-arm64'` | Path to the `nexaraild` binary |
| `home` | `str` | `'~/.nexarail-devnet'` | Home directory for chain data |
| `chain_id` | `str` | `'nexarail-devnet-1'` | Chain ID |
| `keyring` | `str` | `'test'` | Keyring backend |

- **Returns:** CLI command string. Does NOT execute.

**Example:**

```python
from nexarail_client import bank_send_cmd

cmd = bank_send_cmd('my-key', 'nxr1recipientaddress', 1000000, 'unxrl')
print(cmd)
# releases/testnet-rc1/binaries/nexaraild-darwin-arm64 tx bank send my-key nxr1recipientaddress 1000000unxrl --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

# Custom binary and home
custom_cmd = bank_send_cmd(
    'validator-key', 'nxr1partner', 500000, 'unxrl',
    binary='./build/nexaraild', home='~/.nexarail-testnet', chain_id='nexarail-testnet-1'
)
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `merchant_register_cmd`

- **Label:** `(command-builder)`
- **Purpose:** Build a `nexaraild tx merchant register` CLI command string.
- **Signature:** `def merchant_register_cmd(owner: str, name: str, description: str, website: str, binary: str, home: str, chain_id: str, keyring: str) -> str`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `owner` | `str` | — | Owner address or key name (used as `--from`) |
| `name` | `str` | — | Merchant name |
| `description` | `str` | — | Merchant description |
| `website` | `str` | `''` | Optional website URL |
| `binary` | `str` | `'releases/testnet-rc1/binaries/nexaraild-darwin-arm64'` | Path to the `nexaraild` binary |
| `home` | `str` | `'~/.nexarail-devnet'` | Home directory |
| `chain_id` | `str` | `'nexarail-devnet-1'` | Chain ID |
| `keyring` | `str` | `'test'` | Keyring backend |

- **Returns:** CLI command string. Does NOT execute.

**Example:**

```python
from nexarail_client import merchant_register_cmd

# Full registration with website
cmd = merchant_register_cmd(
    'merchant-owner-key',
    'Acme Rail Logistics',
    'Premium rail logistics provider',
    website='https://acme.example.com'
)
print(cmd)
# releases/testnet-rc1/binaries/nexaraild-darwin-arm64 tx merchant register "Acme Rail Logistics" "Premium rail logistics provider" "https://acme.example.com" --from merchant-owner-key --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

# Minimal registration
minimal = merchant_register_cmd('my-key', 'Quick Haul', 'Express freight services')
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `settlement_create_cmd`

- **Label:** `(command-builder)`
- **Purpose:** Build a `nexaraild tx settlement create` CLI command string.
- **Signature:** `def settlement_create_cmd(payer: str, merchant: str, amount: str | int | float, reference: str, denom: str, binary: str, home: str, chain_id: str, keyring: str) -> str`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `payer` | `str` | — | Payer address or key name (used as `--from`) |
| `merchant` | `str` | — | Merchant owner address |
| `amount` | `str \| int \| float` | — | Numeric settlement amount |
| `reference` | `str` | — | Settlement reference or metadata |
| `denom` | `str` | `'unxrl'` | Coin denomination |
| `binary` | `str` | `'releases/testnet-rc1/binaries/nexaraild-darwin-arm64'` | Path to the `nexaraild` binary |
| `home` | `str` | `'~/.nexarail-devnet'` | Home directory |
| `chain_id` | `str` | `'nexarail-devnet-1'` | Chain ID |
| `keyring` | `str` | `'test'` | Keyring backend |

- **Returns:** CLI command string. Does NOT execute.

**Example:**

```python
from nexarail_client import settlement_create_cmd

cmd = settlement_create_cmd(
    'payer-key', 'nxr1merchantaddress', 1000000, 'Order #12345 - Freight services'
)
print(cmd)
# releases/testnet-rc1/binaries/nexaraild-darwin-arm64 tx settlement create nxr1merchantaddress 1000000unxrl --metadata "Order #12345 - Freight services" --from payer-key --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `escrow_create_cmd`

- **Label:** `(command-builder)`
- **Purpose:** Build a `nexaraild tx escrow create` CLI command string.
- **Signature:** `def escrow_create_cmd(buyer: str, seller: str, merchant: str, amount: str | int | float, reference: str, escrow_id: str, denom: str, binary: str, home: str, chain_id: str, keyring: str) -> str`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `buyer` | `str` | — | Buyer address or key name (used as `--from`) |
| `seller` | `str` | — | Seller address |
| `merchant` | `str` | — | Merchant ID or address |
| `amount` | `str \| int \| float` | — | Numeric escrow amount |
| `reference` | `str` | — | Payment reference (passed as `--payment-reference`) |
| `escrow_id` | `str` | `'escrow-1'` | Custom escrow identifier |
| `denom` | `str` | `'unxrl'` | Coin denomination |
| `binary` | `str` | `'releases/testnet-rc1/binaries/nexaraild-darwin-arm64'` | Path to the `nexaraild` binary |
| `home` | `str` | `'~/.nexarail-devnet'` | Home directory |
| `chain_id` | `str` | `'nexarail-devnet-1'` | Chain ID |
| `keyring` | `str` | `'test'` | Keyring backend |

- **Returns:** CLI command string. Does NOT execute.

**Example:**

```python
from nexarail_client import escrow_create_cmd

# Custom escrow ID
cmd = escrow_create_cmd(
    'buyer-key', 'nxr1selleraddress', 'merchant-1', 2000000,
    'Invoice ABC - 30-day net', escrow_id='escrow-order-001'
)
print(cmd)
# releases/testnet-rc1/binaries/nexaraild-darwin-arm64 tx escrow create escrow-order-001 nxr1selleraddress merchant-1 2000000unxrl --payment-reference "Invoice ABC - 30-day net" --from buyer-key --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

# With defaults
default_cmd = escrow_create_cmd('buyer-key', 'nxr1seller', 'merchant-1', 1000000, 'Payment ref')
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `escrow_release_cmd`

- **Label:** `(command-builder)`
- **Purpose:** Build a `nexaraild tx escrow release` CLI command string.
- **Signature:** `def escrow_release_cmd(escrow_id: str, from_addr: str, reference: str, binary: str, home: str, chain_id: str, keyring: str) -> str`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `escrow_id` | `str` | — | Escrow ID to release |
| `from_addr` | `str` | `'buyer'` | Signer address or key name (`--from`) |
| `reference` | `str` | `''` | Optional release reference (passed as `--release-reference` if non-empty) |
| `binary` | `str` | `'releases/testnet-rc1/binaries/nexaraild-darwin-arm64'` | Path to the `nexaraild` binary |
| `home` | `str` | `'~/.nexarail-devnet'` | Home directory |
| `chain_id` | `str` | `'nexarail-devnet-1'` | Chain ID |
| `keyring` | `str` | `'test'` | Keyring backend |

- **Returns:** CLI command string. Does NOT execute.

**Example:**

```python
from nexarail_client import escrow_release_cmd

# Release with reference
cmd = escrow_release_cmd(
    'escrow-order-001',
    from_addr='buyer-key',
    reference='Goods received and verified'
)
print(cmd)
# releases/testnet-rc1/binaries/nexaraild-darwin-arm64 tx escrow release escrow-order-001 --release-reference "Goods received and verified" --from buyer-key --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

# Release as authority without reference
auth_cmd = escrow_release_cmd('escrow-order-001', from_addr='authority-key')
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `escrow_dispute_cmd`

- **Label:** `(command-builder)`
- **Purpose:** Build a `nexaraild tx escrow dispute` CLI command string.
- **Signature:** `def escrow_dispute_cmd(escrow_id: str, reason: str, from_addr: str, binary: str, home: str, chain_id: str, keyring: str) -> str`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `escrow_id` | `str` | — | Escrow ID to dispute |
| `reason` | `str` | — | Dispute reason text |
| `from_addr` | `str` | `'buyer'` | Signer address or key name (`--from`) |
| `binary` | `str` | `'releases/testnet-rc1/binaries/nexaraild-darwin-arm64'` | Path to the `nexaraild` binary |
| `home` | `str` | `'~/.nexarail-devnet'` | Home directory |
| `chain_id` | `str` | `'nexarail-devnet-1'` | Chain ID |
| `keyring` | `str` | `'test'` | Keyring backend |

- **Returns:** CLI command string. Does NOT execute.

**Example:**

```python
from nexarail_client import escrow_dispute_cmd

cmd = escrow_dispute_cmd(
    'escrow-order-001',
    'Goods not delivered within agreed timeframe',
    from_addr='buyer-key'
)
print(cmd)
# releases/testnet-rc1/binaries/nexaraild-darwin-arm64 tx escrow dispute escrow-order-001 "Goods not delivered within agreed timeframe" --from buyer-key --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `payout_create_cmd`

- **Label:** `(command-builder)`
- **Purpose:** Build a `nexaraild tx payout create` CLI command string.
- **Signature:** `def payout_create_cmd(merchant: str, recipient: str, amount: str | int | float, reference: str, payout_id: str, payout_type: int, denom: str, from_addr: str, binary: str, home: str, chain_id: str, keyring: str) -> str`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `merchant` | `str` | — | Merchant ID |
| `recipient` | `str` | — | Recipient address |
| `amount` | `str \| int \| float` | — | Numeric payout amount |
| `reference` | `str` | — | Payout reference (passed as `--payout-reference`) |
| `payout_id` | `str` | `'payout-1'` | Custom payout identifier |
| `payout_type` | `int` | `0` | Payout type enum value |
| `denom` | `str` | `'unxrl'` | Coin denomination |
| `from_addr` | `str` | `'merchant'` | Signer address or key name (`--from`) |
| `binary` | `str` | `'releases/testnet-rc1/binaries/nexaraild-darwin-arm64'` | Path to the `nexaraild` binary |
| `home` | `str` | `'~/.nexarail-devnet'` | Home directory |
| `chain_id` | `str` | `'nexarail-devnet-1'` | Chain ID |
| `keyring` | `str` | `'test'` | Keyring backend |

- **Returns:** CLI command string. Does NOT execute.

**Example:**

```python
from nexarail_client import payout_create_cmd

cmd = payout_create_cmd(
    'merchant-1', 'nxr1recipientaddress', 500000,
    'Commission payout Q2 2026',
    payout_id='payout-Q2-001', payout_type=0, from_addr='merchant-key'
)
print(cmd)
# releases/testnet-rc1/binaries/nexaraild-darwin-arm64 tx payout create payout-Q2-001 merchant-1 nxr1recipientaddress 500000unxrl 0 --payout-reference "Commission payout Q2 2026" --from merchant-key --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

# Revenue share with custom type
rev_cmd = payout_create_cmd(
    'merchant-1', 'nxr1partner', '750000',
    'Revenue share - May 2026',
    payout_id='rev-share-001', payout_type=1, from_addr='merchant-key'
)
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `payout_mark_paid_cmd`

- **Label:** `(command-builder)`
- **Purpose:** Build a `nexaraild tx payout mark-paid` CLI command string.
- **Signature:** `def payout_mark_paid_cmd(payout_id: str, ext_ref: str, from_addr: str, binary: str, home: str, chain_id: str, keyring: str) -> str`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `payout_id` | `str` | — | Payout ID to mark as paid |
| `ext_ref` | `str` | `'offchain-ref'` | External reference (e.g. ACH transaction ID) |
| `from_addr` | `str` | `'authority'` | Signer address or key name (`--from`) |
| `binary` | `str` | `'releases/testnet-rc1/binaries/nexaraild-darwin-arm64'` | Path to the `nexaraild` binary |
| `home` | `str` | `'~/.nexarail-devnet'` | Home directory |
| `chain_id` | `str` | `'nexarail-devnet-1'` | Chain ID |
| `keyring` | `str` | `'test'` | Keyring backend |

- **Returns:** CLI command string. Does NOT execute.

**Example:**

```python
from nexarail_client import payout_mark_paid_cmd

cmd = payout_mark_paid_cmd(
    'payout-Q2-001', ext_ref='ACH-txn-98765', from_addr='authority-key'
)
print(cmd)
# releases/testnet-rc1/binaries/nexaraild-darwin-arm64 tx payout mark-paid payout-Q2-001 ACH-txn-98765 --from authority-key --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `treasury_spend_request_cmd`

- **Label:** `(command-builder)`
- **Purpose:** Build a `nexaraild tx treasury create-spend` CLI command string.
- **Signature:** `def treasury_spend_request_cmd(account_id: str, recipient: str, amount: str | int | float, purpose: str, request_id: str, denom: str, from_addr: str, binary: str, home: str, chain_id: str, keyring: str) -> str`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `account_id` | `str` | — | Treasury account ID (e.g. `'operations-fund'`, `'community-pool'`) |
| `recipient` | `str` | — | Recipient address |
| `amount` | `str \| int \| float` | — | Numeric spend amount |
| `purpose` | `str` | — | Spend purpose description |
| `request_id` | `str` | `'spend-1'` | Custom spend request identifier |
| `denom` | `str` | `'unxrl'` | Coin denomination |
| `from_addr` | `str` | `'treasury-manager'` | Signer address or key name (`--from`) |
| `binary` | `str` | `'releases/testnet-rc1/binaries/nexaraild-darwin-arm64'` | Path to the `nexaraild` binary |
| `home` | `str` | `'~/.nexarail-devnet'` | Home directory |
| `chain_id` | `str` | `'nexarail-devnet-1'` | Chain ID |
| `keyring` | `str` | `'test'` | Keyring backend |

- **Returns:** CLI command string. Does NOT execute.

**Example:**

```python
from nexarail_client import treasury_spend_request_cmd

cmd = treasury_spend_request_cmd(
    'operations-fund', 'nxr1vendoraddress', 2500000,
    'Infrastructure maintenance grant',
    request_id='spend-grant-001', from_addr='treasury-manager'
)
print(cmd)
# releases/testnet-rc1/binaries/nexaraild-darwin-arm64 tx treasury create-spend spend-grant-001 operations-fund nxr1vendoraddress 2500000unxrl "Infrastructure maintenance grant" --from treasury-manager --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

# Community pool spend
community_cmd = treasury_spend_request_cmd(
    'community-pool', 'nxr1community-member', '10000000',
    'Community development initiative',
    request_id='spend-community-01', from_addr='council-key'
)
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `product_gov_cmd`

- **Label:** `(command-builder)`
- **Purpose:** Build a `nexaraild tx gov` CLI command string for NexaRail product governance actions (submit proposals, deposit, vote). Handles three action types: `'submit-proposal'`, `'deposit'`, and `'vote'`.
- **Signature:** `def product_gov_cmd(action: str, from_addr: str, proposal_file: str, proposal_id: str, deposit: str, vote_option: str, binary: str, home: str, chain_id: str, keyring: str) -> str`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `action` | `str` | — | Governance action: `'submit-proposal'`, `'deposit'`, or `'vote'` |
| `from_addr` | `str` | `'gov-proposer'` | Signer address or key name (`--from`) |
| `proposal_file` | `str` | `'proposal.json'` | Path to proposal JSON file (used with `submit-proposal`) |
| `proposal_id` | `str` | `'1'` | Proposal ID (used with `deposit` and `vote`) |
| `deposit` | `str` | `'10000000unxrl'` | Deposit amount with denomination (used with `deposit`) |
| `vote_option` | `str` | `'yes'` | Vote option: `'yes'`, `'no'`, `'abstain'`, `'no_with_veto'` (used with `vote`) |
| `binary` | `str` | `'releases/testnet-rc1/binaries/nexaraild-darwin-arm64'` | Path to the `nexaraild` binary |
| `home` | `str` | `'~/.nexarail-devnet'` | Home directory |
| `chain_id` | `str` | `'nexarail-devnet-1'` | Chain ID |
| `keyring` | `str` | `'test'` | Keyring backend |

- **Returns:** CLI command string. Does NOT execute.

**Example:**

```python
from nexarail_client import product_gov_cmd

# Submit a governance proposal
proposal_cmd = product_gov_cmd(
    'submit-proposal',
    from_addr='gov-proposer',
    proposal_file='./proposals/update_fee_params.json'
)
print(proposal_cmd)
# releases/testnet-rc1/binaries/nexaraild-darwin-arm64 tx gov submit-proposal ./proposals/update_fee_params.json --from gov-proposer --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

# Deposit to a proposal
deposit_cmd = product_gov_cmd(
    'deposit', from_addr='gov-proposer', proposal_id='1', deposit='10000000unxrl'
)
print(deposit_cmd)
# releases/testnet-rc1/binaries/nexaraild-darwin-arm64 tx gov deposit 1 10000000unxrl --from gov-proposer --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

# Vote on a proposal
vote_cmd = product_gov_cmd(
    'vote', from_addr='validator-key', proposal_id='1', vote_option='yes'
)
print(vote_cmd)
# releases/testnet-rc1/binaries/nexaraild-darwin-arm64 tx gov vote 1 yes --from validator-key --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

## Export Summary

| # | Function | Type | Category |
|---|----------|------|----------|
| 1 | `get` | sync | Read-only |
| 2 | `get_params` | sync | Read-only |
| 3 | `get_list` | sync | Read-only |
| 4 | `get_detail` | sync | Read-only |
| 5 | `get_exists` | sync | Read-only |
| 6 | `get_filtered` | sync | Read-only |
| 7 | `treasury_summary` | sync | Read-only |
| 8 | `node_status` | sync | Read-only |
| 9 | `bank_send_cmd` | sync | Command-builder |
| 10 | `merchant_register_cmd` | sync | Command-builder |
| 11 | `settlement_create_cmd` | sync | Command-builder |
| 12 | `escrow_create_cmd` | sync | Command-builder |
| 13 | `escrow_release_cmd` | sync | Command-builder |
| 14 | `escrow_dispute_cmd` | sync | Command-builder |
| 15 | `payout_create_cmd` | sync | Command-builder |
| 16 | `payout_mark_paid_cmd` | sync | Command-builder |
| 17 | `treasury_spend_request_cmd` | sync | Command-builder |
| 18 | `product_gov_cmd` | sync | Command-builder |

---

*Note: The Python SDK also exports `api_url()` and `rpc_url()` helper functions for reading endpoint configuration.*
