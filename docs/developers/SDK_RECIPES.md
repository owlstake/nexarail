# NexaRail SDK — Practical Recipes

**Compatible with:** NexaRail Controlled Testnet RC1 (`nexarail-devnet-1`)

This document provides end-to-end code recipes using the NexaRail Node.js and Python SDKs. Every recipe includes working code for both SDKs and example output.

**⚠️ LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS ⚠️**

---

## Table of Contents

1. [Check All Live Flags](#recipe-1-check-all-live-flags)
2. [Query Treasury Summary](#recipe-2-query-treasury-summary)
3. [Query Merchant List](#recipe-3-query-merchant-list)
4. [Query Settlement List](#recipe-4-query-settlement-list)
5. [Query Escrow Exists / Detail](#recipe-5-query-escrow-exists--detail)
6. [Query Payout Exists / Detail](#recipe-6-query-payout-exists--detail)
7. [Build a Merchant-Register Command](#recipe-7-build-a-merchant-register-command)
8. [Build a Settlement-Create Command](#recipe-8-build-a-settlement-create-command)
9. [Build a Product-Gov Toggle Command](#recipe-9-build-a-product-gov-toggle-command)
10. [Run Local Demo Then Query State](#recipe-10-run-local-demo-then-query-state)

---

## Recipe 1: Check All Live Flags

**Purpose:** Query each NexaRail product module's parameters and display the `live_enabled` flag status. On a fresh devnet, all live flags should return `false`.

### Node.js

```js
import { getParams } from '@nexarail/devnet-client';

const modules = ['settlement', 'escrow', 'treasury', 'payout'];

for (const mod of modules) {
  const params = await getParams(mod);
  const live = params.live_enabled;
  console.log(`${mod.padEnd(12)} live_enabled: ${live}`);
}

// Also check node status for context
import { nodeStatus } from '@nexarail/devnet-client';
const status = await nodeStatus();
console.log(`\nNode chain: ${status.node_info.network}`);
console.log(`Block height: ${status.sync_info.latest_block_height}`);
```

### Python

```python
from nexarail_client import get_params, node_status

modules = ['settlement', 'escrow', 'treasury', 'payout']

for mod in modules:
    params = get_params(mod)
    live = params.get('live_enabled')
    print(f'{mod:<12} live_enabled: {live}')

# Also check node status for context
status = node_status()
print(f'\nNode chain: {status["node_info"]["network"]}')
print(f'Block height: {status["sync_info"]["latest_block_height"]}')
```

### Expected Output

```
settlement    live_enabled: False
escrow        live_enabled: False
treasury      live_enabled: False
payout        live_enabled: False

Node chain: nexarail-devnet-1
Block height: 1234
```

**Devnet warning:** LOCAL DEVNET ONLY — Live flags indicate whether the module is active. A `false` value on devnet is expected.

---

## Recipe 2: Query Treasury Summary

**Purpose:** Get the treasury account summary and display key fields such as total funding, total spent, and account count.

### Node.js

```js
import { treasurySummary } from '@nexarail/devnet-client';

const summary = await treasurySummary();
console.log('=== Treasury Summary ===');
for (const [key, value] of Object.entries(summary)) {
  console.log(`  ${key}: ${value}`);
}
```

### Python

```python
from nexarail_client import treasury_summary

summary = treasury_summary()
print('=== Treasury Summary ===')
for key, value in summary.items():
    print(f'  {key}: {value}')
```

### Expected Output

```
=== Treasury Summary ===
  total_funding: 0unxrl
  total_spent: 0unxrl
  account_count: 0
  ...
```

**Devnet warning:** LOCAL DEVNET ONLY — Treasury data reflects local devnet state only.

---

## Recipe 3: Query Merchant List

**Purpose:** List all registered merchants from the treasury module. On a fresh devnet, the list will be empty.

### Node.js

```js
import { getList } from '@nexarail/devnet-client';

const merchants = await getList('treasury', 'merchant');
const items = merchants.merchant || merchants.list || [];
console.log(`Merchant count: ${items.length}`);

if (items.length > 0) {
  items.forEach((m, i) => {
    console.log(`  [${i}] ${m.name || m.id || JSON.stringify(m).slice(0, 100)}`);
  });
} else {
  console.log('  (empty — no merchants registered yet)');
}
```

### Python

```python
from nexarail_client import get_list

merchants = get_list('treasury', 'merchant')
items = merchants.get('merchant') or merchants.get('list') or []
print(f'Merchant count: {len(items)}')

if items:
    for i, m in enumerate(items):
        name = m.get('name') or m.get('id') or str(m)[:100]
        print(f'  [{i}] {name}')
else:
    print('  (empty — no merchants registered yet)')
```

### Expected Output

```
Merchant count: 0
  (empty — no merchants registered yet)
```

**Devnet warning:** LOCAL DEVNET ONLY — Merchants must be registered via `nexaraild tx merchant register` before they appear in this list.

---

## Recipe 4: Query Settlement List

**Purpose:** List all settlements from the settlement module. On a fresh devnet, the list will be empty.

### Node.js

```js
import { getList } from '@nexarail/devnet-client';

const settlements = await getList('settlement', 'settlement');
const items = settlements.settlement || settlements.list || [];
console.log(`Settlement count: ${items.length}`);

if (items.length > 0) {
  items.forEach((s, i) => {
    console.log(`  [${i}] ${JSON.stringify(s).slice(0, 150)}`);
  });
} else {
  console.log('  (empty - no settlements created yet)');
}
```

### Python

```python
from nexarail_client import get_list

settlements = get_list('settlement', 'settlement')
items = settlements.get('settlement') or settlements.get('list') or []
print(f'Settlement count: {len(items)}')

if items:
    for i, s in enumerate(items):
        print(f'  [{i}] {str(s)[:150]}')
else:
    print('  (empty — no settlements created yet)')
```

### Expected Output

```
Settlement count: 0
  (empty - no settlements created yet)
```

**Devnet warning:** LOCAL DEVNET ONLY — Settlements must be created via `nexaraild tx settlement create` before they appear in this list.

---

## Recipe 5: Query Escrow Exists / Detail

**Purpose:** First check if an escrow exists using `getExists`, then fetch its full detail. Demonstrates error handling for non-existent resources.

### Node.js

```js
import { getExists, getDetail } from '@nexarail/devnet-client';

const escrowId = 'escrow-order-001';

// Check existence
const exists = await getExists('escrow', 'escrow', escrowId);
const found = !exists.error;

console.log(`Escrow "${escrowId}" exists: ${found}`);

if (found) {
  // Get full detail
  const detail = await getDetail('escrow', 'escrow', escrowId);
  console.log('Escrow detail:', JSON.stringify(detail, null, 2));
} else {
  console.log('  (no detail available — escrow not created)');
}
```

### Python

```python
from nexarail_client import get_exists, get_detail

escrow_id = 'escrow-order-001'

# Check existence
exists = get_exists('escrow', 'escrow', escrow_id)
found = 'error' not in exists

print(f'Escrow "{escrow_id}" exists: {found}')

if found:
    # Get full detail
    detail = get_detail('escrow', 'escrow', escrow_id)
    print('Escrow detail:')
    print(detail)
else:
    print('  (no detail available — escrow not created)')
```

### Expected Output

```
Escrow "escrow-order-001" exists: False
  (no detail available — escrow not created)
```

With an existing escrow, detail would look like:

```
Escrow "escrow-order-001" exists: True
Escrow detail:
{
  "escrow": {
    "id": "escrow-order-001",
    "buyer": "nxr1buyeraddress",
    "seller": "nxr1selleraddress",
    "merchant": "merchant-1",
    "amount": "2000000unxrl",
    "payment_reference": "Invoice ABC - 30-day net",
    "status": "ACTIVE"
  }
}
```

**Devnet warning:** LOCAL DEVNET ONLY — Escrows must be created via `nexaraild tx escrow create` before existence checks return `true`.

---

## Recipe 6: Query Payout Exists / Detail

**Purpose:** Check if a payout exists using `getExists`, then fetch its full detail.

### Node.js

```js
import { getExists, getDetail } from '@nexarail/devnet-client';

const payoutId = 'payout-Q2-001';

// Check existence
const exists = await getExists('payout', 'payout', payoutId);
const found = !exists.error;

console.log(`Payout "${payoutId}" exists: ${found}`);

if (found) {
  const detail = await getDetail('payout', 'payout', payoutId);
  console.log('Payout detail:', JSON.stringify(detail, null, 2));
} else {
  console.log('  (no detail available — payout not created)');
}
```

### Python

```python
from nexarail_client import get_exists, get_detail

payout_id = 'payout-Q2-001'

# Check existence
exists = get_exists('payout', 'payout', payout_id)
found = 'error' not in exists

print(f'Payout "{payout_id}" exists: {found}')

if found:
    detail = get_detail('payout', 'payout', payout_id)
    print('Payout detail:')
    import json
    print(json.dumps(detail, indent=2))
else:
    print('  (no detail available — payout not created)')
```

### Expected Output

```
Payout "payout-Q2-001" exists: False
  (no detail available — payout not created)
```

With an existing payout, detail would look like:

```
Payout "payout-Q2-001" exists: True
Payout detail:
{
  "payout": {
    "id": "payout-Q2-001",
    "merchant": "merchant-1",
    "recipient": "nxr1recipientaddress",
    "amount": "500000unxrl",
    "payout_reference": "Commission payout Q2 2026",
    "payout_type": 0,
    "status": "PENDING"
  }
}
```

**Devnet warning:** LOCAL DEVNET ONLY — Payouts must be created via `nexaraild tx payout create` before they appear in this list.

---

## Recipe 7: Build a Merchant-Register Command

**Purpose:** Use the SDK's command-string builder to generate a `nexaraild tx merchant register` CLI command. The resulting string can be copied to a terminal with a running devnet.

### Node.js

```js
import { merchantRegisterCmd } from '@nexarail/devnet-client';

const cmd = merchantRegisterCmd(
  'merchant-owner-key',
  'Acme Rail Logistics',
  'Premium rail logistics provider for the NexaRail ecosystem',
  { website: 'https://acme.example.com' }
);

console.log('=== Merchant Register Command ===');
console.log(cmd);
console.log('\nCopy this command to your devnet terminal and execute it.');
```

### Python

```python
from nexarail_client import merchant_register_cmd

cmd = merchant_register_cmd(
    'merchant-owner-key',
    'Acme Rail Logistics',
    'Premium rail logistics provider for the NexaRail ecosystem',
    website='https://acme.example.com'
)

print('=== Merchant Register Command ===')
print(cmd)
print('\nCopy this command to your devnet terminal and execute it.')
```

### Expected Output

```
=== Merchant Register Command ===
./build/nexaraild tx merchant register "Acme Rail Logistics" "Premium rail logistics provider for the NexaRail ecosystem" "https://acme.example.com" --from merchant-owner-key --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

Copy this command to your devnet terminal and execute it.
```

(Python output differs slightly in the binary path — uses `releases/testnet-rc1/binaries/nexaraild-darwin-arm64` by default.)

**Devnet warning:** LOCAL DEVNET ONLY — Do not run this command against mainnet or any public testnet.

---

## Recipe 8: Build a Settlement-Create Command

**Purpose:** Use the SDK's command-string builder to generate a `nexaraild tx settlement create` CLI command.

### Node.js

```js
import { settlementCreateCmd } from '@nexarail/devnet-client';

const cmd = settlementCreateCmd(
  'payer-key',
  'nxr1merchantaddress',
  1000000,
  'Order #12345 - Freight services'
);

console.log('=== Settlement Create Command ===');
console.log(cmd);
console.log('\nCopy this command to your devnet terminal and execute it.');
```

### Python

```python
from nexarail_client import settlement_create_cmd

cmd = settlement_create_cmd(
    'payer-key',
    'nxr1merchantaddress',
    1000000,
    'Order #12345 - Freight services'
)

print('=== Settlement Create Command ===')
print(cmd)
print('\nCopy this command to your devnet terminal and execute it.')
```

### Expected Output

```
=== Settlement Create Command ===
./build/nexaraild tx settlement create nxr1merchantaddress 1000000unxrl --metadata "Order #12345 - Freight services" --from payer-key --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

Copy this command to your devnet terminal and execute it.
```

**Devnet warning:** LOCAL DEVNET ONLY — Do not run this command against mainnet or any public testnet.

---

## Recipe 9: Build a Product-Gov Toggle Command

**Purpose:** Build a complete governance proposal workflow using the SDK's `productGovCmd` / `product_gov_cmd`. Generate submit-proposal, deposit, and vote commands to toggle a module's `live_enabled` flag.

### Node.js

```js
import { productGovCmd } from '@nexarail/devnet-client';

console.log('=== Governance Toggle Workflow ===\n');

// Step 1: Submit a proposal to enable the escrow module
console.log('# Step 1: Submit proposal');
const submitCmd = productGovCmd('submit-proposal', {
  from: 'gov-proposer',
  proposalFile: './proposals/enable_escrow_live.json'
});
console.log(submitCmd);
console.log();

// Step 2: Deposit to the proposal
console.log('# Step 2: Deposit');
const depositCmd = productGovCmd('deposit', {
  from: 'gov-proposer',
  proposalId: '1',
  deposit: '10000000unxrl'
});
console.log(depositCmd);
console.log();

// Step 3: Vote on the proposal
console.log('# Step 3: Vote yes');
const voteCmd = productGovCmd('vote', {
  from: 'validator-key',
  proposalId: '1',
  voteOption: 'yes'
});
console.log(voteCmd);
console.log();

console.log('Execute these commands in order on your devnet terminal.');
```

### Python

```python
from nexarail_client import product_gov_cmd

print('=== Governance Toggle Workflow ===\n')

# Step 1: Submit a proposal to enable the escrow module
print('# Step 1: Submit proposal')
submit_cmd = product_gov_cmd(
    'submit-proposal',
    from_addr='gov-proposer',
    proposal_file='./proposals/enable_escrow_live.json'
)
print(submit_cmd)
print()

# Step 2: Deposit to the proposal
print('# Step 2: Deposit')
deposit_cmd = product_gov_cmd(
    'deposit',
    from_addr='gov-proposer',
    proposal_id='1',
    deposit='10000000unxrl'
)
print(deposit_cmd)
print()

# Step 3: Vote on the proposal
print('# Step 3: Vote yes')
vote_cmd = product_gov_cmd(
    'vote',
    from_addr='validator-key',
    proposal_id='1',
    vote_option='yes'
)
print(vote_cmd)
print()

print('Execute these commands in order on your devnet terminal.')
```

### Expected Output

```
=== Governance Toggle Workflow ===

# Step 1: Submit proposal
./build/nexaraild tx gov submit-proposal ./proposals/enable_escrow_live.json --from gov-proposer --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

# Step 2: Deposit
./build/nexaraild tx gov deposit 1 10000000unxrl --from gov-proposer --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

# Step 3: Vote yes
./build/nexaraild tx gov vote 1 yes --from validator-key --chain-id nexarail-devnet-1 --home ~/.nexarail-devnet --keyring-backend test --yes

Execute these commands in order on your devnet terminal.
```

**Devnet warning:** LOCAL DEVNET ONLY — Governance actions on a real network would require real tokens and have real consequences.

---

## Recipe 10: Run Local Demo Then Query State

**Purpose:** Full end-to-end flow: after launching the devnet and running some write-flow scripts, query the chain state to see the results.

This recipe assumes you have:
1. Started the RC1 devnet (listening on `localhost:1317` and `localhost:26657`)
2. Run some write-flow examples from `examples/write-flows/` (e.g., `merchant_register.sh`, `settlement_metadata.sh`, `escrow_lifecycle.sh`)

### Node.js

```js
import { nodeStatus, treasurySummary, getList, getParams } from '@nexarail/devnet-client';

async function demoQuery() {
  console.log('=== Post-Demo State Query ===\n');

  // 1. Node status
  console.log('--- Node Status ---');
  const status = await nodeStatus();
  console.log(`  Chain:        ${status.node_info.network}`);
  console.log(`  Height:       ${status.sync_info.latest_block_height}`);
  console.log(`  Catching up:  ${status.sync_info.catching_up}`);
  console.log();

  // 2. Treasury summary
  console.log('--- Treasury Summary ---');
  const treasury = await treasurySummary();
  for (const [k, v] of Object.entries(treasury)) {
    console.log(`  ${k}: ${v}`);
  }
  console.log();

  // 3. Merchant list
  console.log('--- Merchants ---');
  const merchants = await getList('treasury', 'merchant');
  const mItems = merchants.merchant || merchants.list || [];
  console.log(`  Count: ${mItems.length}`);
  mItems.forEach((m, i) => {
    console.log(`  [${i}] ${JSON.stringify(m).slice(0, 200)}`);
  });
  console.log();

  // 4. Settlement list
  console.log('--- Settlements ---');
  const settlements = await getList('settlement', 'settlement');
  const sItems = settlements.settlement || settlements.list || [];
  console.log(`  Count: ${sItems.length}`);
  sItems.forEach((s, i) => {
    console.log(`  [${i}] ${JSON.stringify(s).slice(0, 200)}`);
  });
  console.log();

  // 5. Live flags (should be false unless governance toggled them)
  console.log('--- Live Flags ---');
  for (const mod of ['settlement', 'escrow', 'treasury', 'payout']) {
    const params = await getParams(mod);
    console.log(`  ${mod.padEnd(12)} live_enabled: ${params.live_enabled}`);
  }
}

demoQuery().catch(console.error);
```

### Python

```python
from nexarail_client import node_status, treasury_summary, get_list, get_params

def demo_query():
    print('=== Post-Demo State Query ===\n')

    # 1. Node status
    print('--- Node Status ---')
    status = node_status()
    print(f'  Chain:        {status["node_info"]["network"]}')
    print(f'  Height:       {status["sync_info"]["latest_block_height"]}')
    print(f'  Catching up:  {status["sync_info"]["catching_up"]}')
    print()

    # 2. Treasury summary
    print('--- Treasury Summary ---')
    treasury = treasury_summary()
    for k, v in treasury.items():
        print(f'  {k}: {v}')
    print()

    # 3. Merchant list
    print('--- Merchants ---')
    merchants = get_list('treasury', 'merchant')
    m_items = merchants.get('merchant') or merchants.get('list') or []
    print(f'  Count: {len(m_items)}')
    for i, m in enumerate(m_items):
        print(f'  [{i}] {str(m)[:200]}')
    print()

    # 4. Settlement list
    print('--- Settlements ---')
    settlements = get_list('settlement', 'settlement')
    s_items = settlements.get('settlement') or settlements.get('list') or []
    print(f'  Count: {len(s_items)}')
    for i, s in enumerate(s_items):
        print(f'  [{i}] {str(s)[:200]}')
    print()

    # 5. Live flags (should be false unless governance toggled them)
    print('--- Live Flags ---')
    for mod in ['settlement', 'escrow', 'treasury', 'payout']:
        params = get_params(mod)
        print(f'  {mod:<12} live_enabled: {params.get("live_enabled")}')

demo_query()
```

### Expected Output (after running write-flow examples)

```
=== Post-Demo State Query ===

--- Node Status ---
  Chain:        nexarail-devnet-1
  Height:       5621
  Catching up:  false

--- Treasury Summary ---
  total_funding: 5000000unxrl
  total_spent: 1000000unxrl
  account_count: 2
  ...

--- Merchants ---
  Count: 1
  [0] {"id": "merchant-1", "name": "Acme Rail Logistics", "owner": "nxr1owneraddress", ...}

--- Settlements ---
  Count: 1
  [0] {"id": "settlement-1", "payer": "nxr1payeraddress", "merchant": "nxr1merchantaddress", "amount": "1000000unxrl", ...}

--- Live Flags ---
  settlement    live_enabled: false
  escrow        live_enabled: false
  treasury      live_enabled: false
  payout        live_enabled: false
```

**Devnet warning:** LOCAL DEVNET ONLY — This recipe assumes a configured and running RC1 devnet on localhost. All data is ephemeral and local to your machine.

---

## Quick Reference: REST Endpoints

For reference, the recipes above use the following REST API endpoints:

| Recipe | Endpoint |
|--------|----------|
| 1 — Live flags | `GET /nexarail/{module}/v1/params` |
| 2 — Treasury summary | `GET /nexarail/treasury/v1/summary` |
| 3 — Merchant list | `GET /nexarail/treasury/v1/merchant` |
| 4 — Settlement list | `GET /nexarail/settlement/v1/settlement` |
| 5 — Escrow exists | `GET /nexarail/escrow/v1/escrow/exists/{id}` |
| 5 — Escrow detail | `GET /nexarail/escrow/v1/escrow/{id}` |
| 6 — Payout exists | `GET /nexarail/payout/v1/payout/exists/{id}` |
| 6 — Payout detail | `GET /nexarail/payout/v1/payout/{id}` |
| 10 — Node status | `GET {rpc}/status` |

---

## Final Warning

```
╔══════════════════════════════════════════════════════════════════════════╗
║  ⚠  LOCAL DEVNET ONLY                                                 ║
║                                                                        ║
║  All recipes in this document are designed for the NexaRail RC1        ║
║  Controlled Testnet running on localhost.                              ║
║                                                                        ║
║  • NOT for mainnet or any public testnet                               ║
║  • NOT a token sale or launch tool                                     ║
║  • NO real financial transactions                                      ║
║  • Command builders return strings — they do NOT execute               ║
╚══════════════════════════════════════════════════════════════════════════╝
```
