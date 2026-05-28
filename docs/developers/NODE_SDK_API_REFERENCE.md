# NexaRail Node.js SDK — API Reference

**Package:** `@nexarail/devnet-client` (v0.1.0-dev)

**Source:** `examples/node-client/src/client.js`

**Compatible with:** NexaRail Controlled Testnet RC1 (`nexarail-devnet-1`)

---

## Overview

The NexaRail Node.js SDK is a lightweight, zero-dependency client for querying the NexaRail RC1 devnet and building CLI command strings. It uses only Node.js built-in `fetch` (Node >=18) and `process.env` — no `npm install` required for basic script usage.

The SDK provides **18 exported functions**:

- **8 read-only query functions** — async, return `Promise<object>`, call the Cosmos SDK REST API
- **10 command-string builders** — synchronous, return `string`, do NOT execute anything

---

## Quick Start

```js
import { getParams, treasurySummary, nodeStatus } from '@nexarail/devnet-client';

// Query a module's parameters
const params = await getParams('settlement');
console.log('Settlement live_enabled:', params.live_enabled);

// Get treasury summary
const treasury = await treasurySummary();
console.log('Treasury balance:', treasury);

// Check node status
const status = await nodeStatus();
console.log('Block height:', status.sync_info.latest_block_height);
```

---

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `API` | `http://localhost:1317` | Cosmos SDK REST API base URL |
| `RPC` | `http://localhost:26657` | CometBFT RPC endpoint for node status |

Override at runtime:

```bash
API=http://localhost:1317 RPC=http://localhost:26657 node my-script.mjs
```

---

## ⚠️ Safety Warning

```
╔══════════════════════════════════════════════════════════════════════════╗
║  ⚠  LOCAL DEVNET ONLY                                                 ║
║                                                                        ║
║  • NOT for mainnet or any public testnet                               ║
║  • NOT published to npm — local install only                           ║
║  • NOT a token sale or launch tool                                     ║
║  • NO private key or mnemonic handling                                 ║
║  • Command builders return strings — they do NOT execute transactions  ║
╚══════════════════════════════════════════════════════════════════════════╝
```

---

## Read-Only Query Functions

---

### `get`

- **Label:** `(read-only)`
- **Purpose:** Make a raw REST GET request to any path on the devnet API.
- **Signature:** `async function get(path: string): Promise<object>`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `path` | `string` | — | URL path to query (appended to `API` base URL) |

- **Returns:** Parsed JSON response body as a plain object. Returns `{ error: "HTTP {status}" }` on non-2xx responses.
- **Notes:** All other read functions call this internally. You normally won't need it directly.

**Example:**

```js
import { get } from '@nexarail/devnet-client';

const result = await get('/nexarail/settlement/v1/params');
console.log(result);
// { live_enabled: false, treasury_routing_enabled: false, ... }
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `getParams`

- **Label:** `(read-only)`
- **Purpose:** Query the parameters of a NexaRail module, including the `live_enabled` flag.
- **Signature:** `async function getParams(module: string): Promise<object>`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `module` | `string` | — | Module name (e.g. `'settlement'`, `'escrow'`, `'treasury'`, `'payout'`) |

- **Returns:** Module parameters as a JSON object. Contains `live_enabled` and module-specific fields such as `treasury_routing_enabled`, `burn_routing_enabled`, fee parameters, etc.
- **Endpoint:** `GET /nexarail/{module}/v1/params`

**Example:**

```js
import { getParams } from '@nexarail/devnet-client';

const settlementParams = await getParams('settlement');
console.log('Live:', settlementParams.live_enabled);
console.log('Treasury routing:', settlementParams.treasury_routing_enabled);
console.log('Burn routing:', settlementParams.burn_routing_enabled);

// Check all modules
const modules = ['settlement', 'escrow', 'treasury', 'payout'];
for (const mod of modules) {
  const p = await getParams(mod);
  console.log(`${mod}: live=${p.live_enabled}`);
}
// Settlement: live=false
// Escrow: live=false
// Treasury: live=false
// Payout: live=false
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `getList`

- **Label:** `(read-only)`
- **Purpose:** List all resources of a given type within a module.
- **Signature:** `async function getList(module: string, resource: string): Promise<object>`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `module` | `string` | — | Module name (e.g. `'settlement'`, `'treasury'`) |
| `resource` | `string` | — | Resource name (e.g. `'settlement'`, `'merchant'`, `'escrow'`, `'payout'`) |

- **Returns:** JSON object with a `list` or named array key containing all items. Returns an empty list when no items exist.
- **Endpoint:** `GET /nexarail/{module}/v1/{resource}`

**Example:**

```js
import { getList } from '@nexarail/devnet-client';

// List all merchants
const merchants = await getList('treasury', 'merchant');
const merchantList = merchants.merchant || merchants.list || [];
console.log(`Found ${merchantList.length} merchants`);

// List all settlements
const settlements = await getList('settlement', 'settlement');
const settlementList = settlements.settlement || settlements.list || [];
console.log(`Found ${settlementList.length} settlements`);

// List all escrows
const escrows = await getList('escrow', 'escrow');
const escrowList = escrows.escrow || escrows.list || [];
console.log(`Found ${escrowList.length} escrows`);
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `getDetail`

- **Label:** `(read-only)`
- **Purpose:** Get a single resource item by ID.
- **Signature:** `async function getDetail(module: string, resource: string, id: string): Promise<object>`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `module` | `string` | — | Module name |
| `resource` | `string` | — | Resource name |
| `id` | `string` | — | Unique identifier of the resource item |

- **Returns:** JSON object representing the resource item. Returns `{ error: "HTTP 404" }` or an error object if not found.
- **Endpoint:** `GET /nexarail/{module}/v1/{resource}/{id}`

**Example:**

```js
import { getDetail } from '@nexarail/devnet-client';

// Get merchant by ID (will 404 on empty devnet)
const merch = await getDetail('treasury', 'merchant', 'merchant-1');
if (merch.error) {
  console.log('Merchant not found:', merch.error);
} else {
  console.log('Merchant:', merch);
}

// Get settlement by ID
const settlement = await getDetail('settlement', 'settlement', 'settlement-order-001');
if (!settlement.error) {
  console.log('Settlement:', settlement);
}
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `getExists`

- **Label:** `(read-only)`
- **Purpose:** Check whether a resource item exists by ID.
- **Signature:** `async function getExists(module: string, resource: string, id: string): Promise<object>`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `module` | `string` | — | Module name |
| `resource` | `string` | — | Resource name |
| `id` | `string` | — | Unique identifier to check |

- **Returns:** JSON object. For an existing item, returns the item data. For a non-existent item, returns a response indicating not-found.
- **Endpoint:** `GET /nexarail/{module}/v1/{resource}/exists/{id}`

**Example:**

```js
import { getExists } from '@nexarail/devnet-client';

// Check if an escrow exists
const existing = await getExists('escrow', 'escrow', 'escrow-1');
console.log('Escrow escrow-1 exists:', !existing.error);

const nonExisting = await getExists('escrow', 'escrow', 'nonexistent-id');
console.log('Escrow nonexistent-id exists:', !nonExisting.error);

// Check if a payout exists
const payoutCheck = await getExists('payout', 'payout', 'payout-Q2-001');
console.log('Payout exists:', !payoutCheck.error);
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `getFiltered`

- **Label:** `(read-only)`
- **Purpose:** Query resources filtered by a specific field and value.
- **Signature:** `async function getFiltered(module: string, resource: string, filter: string, value: string): Promise<object>`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `module` | `string` | — | Module name |
| `resource` | `string` | — | Resource name |
| `filter` | `string` | — | Filter field name (e.g. `'status'`, `'owner'`) |
| `value` | `string` | — | Filter value to match |

- **Returns:** JSON object with a `list` or named array key containing matching items. Returns an empty list when no items match.
- **Endpoint:** `GET /nexarail/{module}/v1/{resource}/{filter}/{value}`

**Example:**

```js
import { getFiltered } from '@nexarail/devnet-client';

// Filter settlements by status
const pending = await getFiltered('settlement', 'settlement', 'status', 'pending');
const pendingList = pending.settlement || pending.list || [];
console.log(`Pending settlements: ${pendingList.length}`);

// Filter escrows by owner
const owned = await getFiltered('escrow', 'escrow', 'buyer', 'nxr1buyeraddress');
const ownedList = owned.escrow || owned.list || [];
console.log(`Escrows for buyer: ${ownedList.length}`);

// Filter payouts by merchant
const payouts = await getFiltered('payout', 'payout', 'merchant', 'merchant-1');
const payoutList = payouts.payout || payouts.list || [];
console.log(`Payouts for merchant-1: ${payoutList.length}`);
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `treasurySummary`

- **Label:** `(read-only)`
- **Purpose:** Get a summary of the treasury accounts, including balances and funding totals.
- **Signature:** `async function treasurySummary(): Promise<object>`
- **Parameters:** None
- **Returns:** JSON object with treasury summary fields such as account balances, total funding, and spending details.
- **Endpoint:** `GET /nexarail/treasury/v1/summary`

**Example:**

```js
import { treasurySummary } from '@nexarail/devnet-client';

const summary = await treasurySummary();
console.log('Treasury summary:');
for (const [key, value] of Object.entries(summary)) {
  console.log(`  ${key}: ${value}`);
}
// Example output on an empty devnet:
//   total_funding: "0unxrl"
//   total_spent: "0unxrl"
//   account_count: 0
//   ...
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `nodeStatus`

- **Label:** `(read-only)`
- **Purpose:** Query the CometBFT RPC endpoint for node status, including block height, chain ID, validator info, and sync status.
- **Signature:** `async function nodeStatus(rpcUrl?: string): Promise<object>`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `rpcUrl` | `string` (optional) | `process.env.RPC \|\| 'http://localhost:26657'` | CometBFT RPC URL override |

- **Returns:** JSON `result` object from the CometBFT `/status` endpoint, containing `node_info`, `sync_info`, and `validator_info`.
- **Endpoint:** `GET {rpcUrl}/status`

**Example:**

```js
import { nodeStatus } from '@nexarail/devnet-client';

// Default (localhost:26657)
const status = await nodeStatus();
console.log('Chain ID:', status.node_info.network);
console.log('Block height:', status.sync_info.latest_block_height);
console.log('Catching up:', status.sync_info.catching_up);
console.log('Validator:', status.validator_info.address);

// Custom RPC URL
const remoteStatus = await nodeStatus('http://192.168.1.50:26657');
console.log('Remote height:', remoteStatus.sync_info.latest_block_height);
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

## Command-String Builders

All command builders are synchronous functions that return a formatted CLI command string. **They do not execute the command.** They build strings suitable for copy-paste into a terminal running `nexaraild`.

**Common `opts` defaults:**

```js
opts = {
  binary:  './build/nexaraild',
  home:    '~/.nexarail-devnet',
  chainId: 'nexarail-devnet-1',
  keyring: 'test'
}
```

---

### `bankSendCmd`

- **Label:** `(command-builder)`
- **Purpose:** Build a `nexaraild tx bank send` CLI command string.
- **Signature:** `function bankSendCmd(from: string, to: string, amount: string | number, denom: string, opts?: object): string`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `from` | `string` | — | Sender address or key name |
| `to` | `string` | — | Recipient address |
| `amount` | `string \| number` | — | Numeric amount (e.g. `1000000`) |
| `denom` | `string` | — | Coin denomination (e.g. `'unxrl'`) |
| `opts.binary` | `string` | `'./build/nexaraild'` | Path to the `nexaraild` binary |
| `opts.home` | `string` | `'~/.nexarail-devnet'` | Home directory for chain data |
| `opts.chainId` | `string` | `'nexarail-devnet-1'` | Chain ID |
| `opts.keyring` | `string` | `'test'` | Keyring backend |

- **Returns:** CLI command string. Does NOT execute.

**Example:**

```js
import { bankSendCmd } from '@nexarail/devnet-client';

const cmd = bankSendCmd(
  'my-key',
  'nxr1recipientaddress',
  1000000,
  'unxrl'
);
console.log(cmd);
// ./build/nexaraild tx bank send my-key nxr1recipientaddress 1000000unxrl --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

// With custom binary and home
const customCmd = bankSendCmd(
  'validator-key',
  'nxr1partner',
  500000,
  'unxrl',
  { binary: './build/nexaraild', home: '~/.nexarail-custom', chainId: 'nexarail-custom-1', keyring: 'os' }
);
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `merchantRegisterCmd`

- **Label:** `(command-builder)`
- **Purpose:** Build a `nexaraild tx merchant register` CLI command string.
- **Signature:** `function merchantRegisterCmd(owner: string, name: string, description: string, opts?: object): string`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `owner` | `string` | — | Owner address or key name (used as `--from`) |
| `name` | `string` | — | Merchant name (quoted in the command) |
| `description` | `string` | — | Merchant description (quoted) |
| `opts.website` | `string` | `''` | Optional website URL (quoted, empty string if none) |
| `opts.binary` | `string` | `'./build/nexaraild'` | Path to the `nexaraild` binary |
| `opts.home` | `string` | `'~/.nexarail-devnet'` | Home directory |
| `opts.chainId` | `string` | `'nexarail-devnet-1'` | Chain ID |
| `opts.keyring` | `string` | `'test'` | Keyring backend |

- **Returns:** CLI command string. Does NOT execute.

**Example:**

```js
import { merchantRegisterCmd } from '@nexarail/devnet-client';

// Full registration with website
const cmd = merchantRegisterCmd(
  'merchant-owner-key',
  'Acme Rail Logistics',
  'Premium rail logistics provider for the NexaRail ecosystem',
  { website: 'https://acme.example.com' }
);
console.log(cmd);
// ./build/nexaraild tx merchant register "Acme Rail Logistics" "Premium rail logistics provider..." "https://acme.example.com" --from merchant-owner-key --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

// Minimal registration
const minimal = merchantRegisterCmd('my-key', 'Quick Haul', 'Express freight services');
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `settlementCreateCmd`

- **Label:** `(command-builder)`
- **Purpose:** Build a `nexaraild tx settlement create` CLI command string.
- **Signature:** `function settlementCreateCmd(payer: string, merchant: string, amount: string | number, reference: string, opts?: object): string`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `payer` | `string` | — | Payer address or key name (used as `--from`) |
| `merchant` | `string` | — | Merchant owner address |
| `amount` | `string \| number` | — | Numeric settlement amount |
| `reference` | `string` | — | Settlement reference or metadata (quoted) |
| `opts.denom` | `string` | `'unxrl'` | Coin denomination |
| `opts.binary` | `string` | `'./build/nexaraild'` | Path to the `nexaraild` binary |
| `opts.home` | `string` | `'~/.nexarail-devnet'` | Home directory |
| `opts.chainId` | `string` | `'nexarail-devnet-1'` | Chain ID |
| `opts.keyring` | `string` | `'test'` | Keyring backend |

- **Returns:** CLI command string. Does NOT execute.

**Example:**

```js
import { settlementCreateCmd } from '@nexarail/devnet-client';

const cmd = settlementCreateCmd(
  'payer-key',
  'nxr1merchantaddress',
  1000000,
  'Order #12345 - Freight services'
);
console.log(cmd);
// ./build/nexaraild tx settlement create nxr1merchantaddress 1000000unxrl --metadata "Order #12345 - Freight services" --from payer-key --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

// Alternative denom
const altCmd = settlementCreateCmd(
  'payer-key',
  'nxr1merchantaddress',
  '5000000',
  'Invoice INV-2026-05',
  { denom: 'unxrl', chainId: 'nexarail-testnet-1' }
);
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `escrowCreateCmd`

- **Label:** `(command-builder)`
- **Purpose:** Build a `nexaraild tx escrow create` CLI command string.
- **Signature:** `function escrowCreateCmd(buyer: string, seller: string, merchant: string, amount: string | number, reference: string, opts?: object): string`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `buyer` | `string` | — | Buyer address or key name (used as `--from`) |
| `seller` | `string` | — | Seller address |
| `merchant` | `string` | — | Merchant ID or address |
| `amount` | `string \| number` | — | Numeric escrow amount |
| `reference` | `string` | — | Payment reference (quoted, passed as `--payment-reference`) |
| `opts.denom` | `string` | `'unxrl'` | Coin denomination |
| `opts.escrowId` | `string` | `'escrow-1'` | Custom escrow identifier |
| `opts.binary` | `string` | `'./build/nexaraild'` | Path to the `nexaraild` binary |
| `opts.home` | `string` | `'~/.nexarail-devnet'` | Home directory |
| `opts.chainId` | `string` | `'nexarail-devnet-1'` | Chain ID |
| `opts.keyring` | `string` | `'test'` | Keyring backend |

- **Returns:** CLI command string. Does NOT execute.

**Example:**

```js
import { escrowCreateCmd } from '@nexarail/devnet-client';

// Custom escrow ID
const cmd = escrowCreateCmd(
  'buyer-key',
  'nxr1selleraddress',
  'merchant-1',
  2000000,
  'Invoice ABC - 30-day net',
  { escrowId: 'escrow-order-001' }
);
console.log(cmd);
// ./build/nexaraild tx escrow create escrow-order-001 nxr1selleraddress merchant-1 2000000unxrl --payment-reference "Invoice ABC - 30-day net" --from buyer-key --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

// With defaults
const defaultCmd = escrowCreateCmd('buyer-key', 'nxr1seller', 'merchant-1', 1000000, 'Payment ref');
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `escrowDisputeCmd`

- **Label:** `(command-builder)`
- **Purpose:** Build a `nexaraild tx escrow dispute` CLI command string.
- **Signature:** `function escrowDisputeCmd(escrowId: string, reason: string, opts?: object): string`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `escrowId` | `string` | — | Escrow ID to dispute |
| `reason` | `string` | — | Dispute reason text (quoted in the command) |
| `opts.from` | `string` | `'buyer'` | Signer address or key name (`--from`) |
| `opts.binary` | `string` | `'./build/nexaraild'` | Path to the `nexaraild` binary |
| `opts.home` | `string` | `'~/.nexarail-devnet'` | Home directory |
| `opts.chainId` | `string` | `'nexarail-devnet-1'` | Chain ID |
| `opts.keyring` | `string` | `'test'` | Keyring backend |

- **Returns:** CLI command string. Does NOT execute.

**Example:**

```js
import { escrowDisputeCmd } from '@nexarail/devnet-client';

const cmd = escrowDisputeCmd(
  'escrow-order-001',
  'Goods not delivered within agreed timeframe',
  { from: 'buyer-key' }
);
console.log(cmd);
// ./build/nexaraild tx escrow dispute escrow-order-001 "Goods not delivered within agreed timeframe" --from buyer-key --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `escrowReleaseCmd`

- **Label:** `(command-builder)`
- **Purpose:** Build a `nexaraild tx escrow release` CLI command string.
- **Signature:** `function escrowReleaseCmd(escrowId: string, opts?: object): string`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `escrowId` | `string` | — | Escrow ID to release |
| `opts.from` | `string` | `'buyer'` | Signer address or key name (`--from`) |
| `opts.reference` | `string` | `''` | Optional release reference (passed as `--release-reference` if provided) |
| `opts.binary` | `string` | `'./build/nexaraild'` | Path to the `nexaraild` binary |
| `opts.home` | `string` | `'~/.nexarail-devnet'` | Home directory |
| `opts.chainId` | `string` | `'nexarail-devnet-1'` | Chain ID |
| `opts.keyring` | `string` | `'test'` | Keyring backend |

- **Returns:** CLI command string. Does NOT execute.

**Example:**

```js
import { escrowReleaseCmd } from '@nexarail/devnet-client';

// Release with reference
const cmd = escrowReleaseCmd('escrow-order-001', {
  from: 'buyer-key',
  reference: 'Goods received and verified'
});
console.log(cmd);
// ./build/nexaraild tx escrow release escrow-order-001 --release-reference "Goods received and verified" --from buyer-key --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

// Release without reference (authority)
const authorityCmd = escrowReleaseCmd('escrow-order-001', {
  from: 'authority-key',
  reference: 'Dispute resolved'
});
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `payoutCreateCmd`

- **Label:** `(command-builder)`
- **Purpose:** Build a `nexaraild tx payout create` CLI command string.
- **Signature:** `function payoutCreateCmd(merchant: string, recipient: string, amount: string | number, reference: string, opts?: object): string`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `merchant` | `string` | — | Merchant ID |
| `recipient` | `string` | — | Recipient address |
| `amount` | `string \| number` | — | Numeric payout amount |
| `reference` | `string` | — | Payout reference (quoted, passed as `--payout-reference`) |
| `opts.denom` | `string` | `'unxrl'` | Coin denomination |
| `opts.payoutId` | `string` | `'payout-1'` | Custom payout identifier |
| `opts.payoutType` | `number` | `0` | Payout type enum value |
| `opts.from` | `string` | `'merchant'` | Signer address or key name (`--from`) |
| `opts.binary` | `string` | `'./build/nexaraild'` | Path to the `nexaraild` binary |
| `opts.home` | `string` | `'~/.nexarail-devnet'` | Home directory |
| `opts.chainId` | `string` | `'nexarail-devnet-1'` | Chain ID |
| `opts.keyring` | `string` | `'test'` | Keyring backend |

- **Returns:** CLI command string. Does NOT execute.

**Example:**

```js
import { payoutCreateCmd } from '@nexarail/devnet-client';

const cmd = payoutCreateCmd(
  'merchant-1',
  'nxr1recipientaddress',
  500000,
  'Commission payout Q2 2026',
  { payoutId: 'payout-Q2-001', payoutType: 0, from: 'merchant-key' }
);
console.log(cmd);
// ./build/nexaraild tx payout create payout-Q2-001 merchant-1 nxr1recipientaddress 500000unxrl 0 --payout-reference "Commission payout Q2 2026" --from merchant-key --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

// Revenue share with custom type
const revCmd = payoutCreateCmd(
  'merchant-1',
  'nxr1partner',
  '750000',
  'Revenue share - May 2026',
  { payoutId: 'rev-share-001', payoutType: 1, from: 'merchant-key' }
);
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `payoutMarkPaidCmd`

- **Label:** `(command-builder)`
- **Purpose:** Build a `nexaraild tx payout mark-paid` CLI command string.
- **Signature:** `function payoutMarkPaidCmd(payoutId: string, opts?: object): string`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `payoutId` | `string` | — | Payout ID to mark as paid |
| `opts.extRef` | `string` | `'offchain-ref'` | External reference (e.g. ACH transaction ID) |
| `opts.from` | `string` | `'authority'` | Signer address or key name (`--from`) |
| `opts.binary` | `string` | `'./build/nexaraild'` | Path to the `nexaraild` binary |
| `opts.home` | `string` | `'~/.nexarail-devnet'` | Home directory |
| `opts.chainId` | `string` | `'nexarail-devnet-1'` | Chain ID |
| `opts.keyring` | `string` | `'test'` | Keyring backend |

- **Returns:** CLI command string. Does NOT execute.

**Example:**

```js
import { payoutMarkPaidCmd } from '@nexarail/devnet-client';

const cmd = payoutMarkPaidCmd('payout-Q2-001', {
  extRef: 'ACH-txn-98765',
  from: 'authority-key'
});
console.log(cmd);
// ./build/nexaraild tx payout mark-paid payout-Q2-001 ACH-txn-98765 --from authority-key --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `treasurySpendRequestCmd`

- **Label:** `(command-builder)`
- **Purpose:** Build a `nexaraild tx treasury create-spend` CLI command string.
- **Signature:** `function treasurySpendRequestCmd(accountId: string, recipient: string, amount: string | number, purpose: string, opts?: object): string`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `accountId` | `string` | — | Treasury account ID (e.g. `'operations-fund'`, `'community-pool'`) |
| `recipient` | `string` | — | Recipient address |
| `amount` | `string \| number` | — | Numeric spend amount |
| `purpose` | `string` | — | Spend purpose description (quoted in the command) |
| `opts.denom` | `string` | `'unxrl'` | Coin denomination |
| `opts.requestId` | `string` | `'spend-1'` | Custom spend request identifier |
| `opts.from` | `string` | `'treasury-manager'` | Signer address or key name (`--from`) |
| `opts.binary` | `string` | `'./build/nexaraild'` | Path to the `nexaraild` binary |
| `opts.home` | `string` | `'~/.nexarail-devnet'` | Home directory |
| `opts.chainId` | `string` | `'nexarail-devnet-1'` | Chain ID |
| `opts.keyring` | `string` | `'test'` | Keyring backend |

- **Returns:** CLI command string. Does NOT execute.

**Example:**

```js
import { treasurySpendRequestCmd } from '@nexarail/devnet-client';

const cmd = treasurySpendRequestCmd(
  'operations-fund',
  'nxr1vendoraddress',
  2500000,
  'Infrastructure maintenance grant',
  { requestId: 'spend-grant-001', from: 'treasury-manager' }
);
console.log(cmd);
// ./build/nexaraild tx treasury create-spend spend-grant-001 operations-fund nxr1vendoraddress 2500000unxrl "Infrastructure maintenance grant" --from treasury-manager --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

// Community pool spend
const communityCmd = treasurySpendRequestCmd(
  'community-pool',
  'nxr1community-member',
  '10000000',
  'Community development initiative',
  { requestId: 'spend-community-01', from: 'council-key' }
);
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

### `productGovCmd`

- **Label:** `(command-builder)`
- **Purpose:** Build a `nexaraild tx gov` CLI command string for NexaRail product governance actions (submit proposals, deposit, vote). Handles three action types: `'submit-proposal'`, `'deposit'`, and `'vote'`.
- **Signature:** `function productGovCmd(action: string, opts?: object): string`
- **Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `action` | `string` | — | Governance action: `'submit-proposal'`, `'deposit'`, or `'vote'` |
| `opts.from` | `string` | `'gov-proposer'` | Signer address or key name (`--from`) |
| `opts.proposalFile` | `string` | `'proposal.json'` | Path to proposal JSON file (used with `submit-proposal`) |
| `opts.proposalId` | `string` | `'1'` | Proposal ID (used with `deposit` and `vote`) |
| `opts.deposit` | `string` | `'10000000unxrl'` | Deposit amount with denomination (used with `deposit`) |
| `opts.voteOption` | `string` | `'yes'` | Vote option: `'yes'`, `'no'`, `'abstain'`, `'no_with_veto'` (used with `vote`) |
| `opts.binary` | `string` | `'./build/nexaraild'` | Path to the `nexaraild` binary |
| `opts.home` | `string` | `'~/.nexarail-devnet'` | Home directory |
| `opts.chainId` | `string` | `'nexarail-devnet-1'` | Chain ID |
| `opts.keyring` | `string` | `'test'` | Keyring backend |

- **Returns:** CLI command string. Does NOT execute.

**Example:**

```js
import { productGovCmd } from '@nexarail/devnet-client';

// Submit a governance proposal
const proposalCmd = productGovCmd('submit-proposal', {
  from: 'gov-proposer',
  proposalFile: './proposals/update_fee_params.json'
});
console.log(proposalCmd);
// ./build/nexaraild tx gov submit-proposal ./proposals/update_fee_params.json --from gov-proposer --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

// Deposit to a proposal
const depositCmd = productGovCmd('deposit', {
  from: 'gov-proposer',
  proposalId: '1',
  deposit: '10000000unxrl'
});
console.log(depositCmd);
// ./build/nexaraild tx gov deposit 1 10000000unxrl --from gov-proposer --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

// Vote on a proposal
const voteCmd = productGovCmd('vote', {
  from: 'validator-key',
  proposalId: '1',
  voteOption: 'yes'
});
console.log(voteCmd);
// ./build/nexaraild tx gov vote 1 yes --from validator-key --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes
```

**Devnet warning:** LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.

---

## Export Summary

| # | Function | Type | Category |
|---|----------|------|----------|
| 1 | `get` | async | Read-only |
| 2 | `getParams` | async | Read-only |
| 3 | `getList` | async | Read-only |
| 4 | `getDetail` | async | Read-only |
| 5 | `getExists` | async | Read-only |
| 6 | `getFiltered` | async | Read-only |
| 7 | `treasurySummary` | async | Read-only |
| 8 | `nodeStatus` | async | Read-only |
| 9 | `bankSendCmd` | sync | Command-builder |
| 10 | `merchantRegisterCmd` | sync | Command-builder |
| 11 | `settlementCreateCmd` | sync | Command-builder |
| 12 | `escrowCreateCmd` | sync | Command-builder |
| 13 | `escrowDisputeCmd` | sync | Command-builder |
| 14 | `escrowReleaseCmd` | sync | Command-builder |
| 15 | `payoutCreateCmd` | sync | Command-builder |
| 16 | `payoutMarkPaidCmd` | sync | Command-builder |
| 17 | `treasurySpendRequestCmd` | sync | Command-builder |
| 18 | `productGovCmd` | sync | Command-builder |
