# NexaRail SDK RC1 Release Notes

## Overview

The NexaRail SDK provides developer tools for interacting with the NexaRail Controlled Testnet RC1 (`nexarail-devnet-1`). It consists of two SDK packages — one for Node.js and one for Python — each offering read-only REST queries against a local devnet plus command-string builders that produce `nexaraild` CLI invocation strings.

**⚠️ LOCAL DEVNET ONLY — NOT FOR MAINNET OR PUBLIC TESTNET USE ⚠️**

---

## SDK Packages

| Package | Name | Version | Language |
|---------|------|---------|----------|
| Node.js | `@nexarail/devnet-client` | `0.1.0-dev` | JavaScript (ESM, Node >=18) |
| Python | `nexarail-devnet-client` | `0.1.0.dev` | Python (>=3.9) |

**Compatible with:** NexaRail Controlled Testnet RC1 (`nexarail-devnet-1`)

---

## What's Included

### Node.js SDK (`examples/node-client/`)

**18 exported functions** across two categories:

- **8 read-only query functions** — async/Promise-based, use built-in `fetch`:
  - `get(path)` — raw REST GET
  - `getParams(module)` — query module params
  - `getList(module, resource)` — list resources
  - `getDetail(module, resource, id)` — get one item
  - `getExists(module, resource, id)` — check existence
  - `getFiltered(module, resource, filter, value)` — filter query
  - `treasurySummary()` — treasury summary
  - `nodeStatus(rpcUrl?)` — RPC node status

- **10 command-string builders** — return CLI strings, do NOT execute:
  - `bankSendCmd(from, to, amount, denom, opts?)`
  - `merchantRegisterCmd(owner, name, description, opts?)`
  - `settlementCreateCmd(payer, merchant, amount, reference, opts?)`
  - `escrowCreateCmd(buyer, seller, merchant, amount, reference, opts?)`
  - `escrowDisputeCmd(escrowId, reason, opts?)`
  - `escrowReleaseCmd(escrowId, opts?)`
  - `payoutCreateCmd(merchant, recipient, amount, reference, opts?)`
  - `payoutMarkPaidCmd(payoutId, opts?)`
  - `treasurySpendRequestCmd(accountId, recipient, amount, purpose, opts?)`
  - `productGovCmd(action, opts?)`

**Package:** `package.json` with ESM module type, zero runtime dependencies (uses built-in `fetch` and `process.env`).

**Test coverage:** 10+ tests in `test/client.test.js` covering export existence, return types, forbidden-pattern detection (no private keys, no mnemonics), and command-string format validation. Run with `npm test` or `node test/client.test.js`.

### Python SDK (`examples/python-client/`)

**18 public functions** in snake_case across two categories (plus `api_url()` and `rpc_url()` helpers):

- **8 read-only query functions** — use `urllib.request`, zero dependencies:
  - `get(path)`
  - `get_params(module)`
  - `get_list(module, resource)`
  - `get_detail(module, resource, id_)`
  - `get_exists(module, resource, id_)`
  - `get_filtered(module, resource, filter_name, value)`
  - `treasury_summary()`
  - `node_status()`

- **10 command-string builders** — return CLI strings, do NOT execute:
  - `bank_send_cmd(from_addr, to, amount, denom, ...)`
  - `merchant_register_cmd(owner, name, description, ...)`
  - `settlement_create_cmd(payer, merchant, amount, reference, ...)`
  - `escrow_create_cmd(buyer, seller, merchant, amount, reference, ...)`
  - `escrow_release_cmd(escrow_id, ...)`
  - `escrow_dispute_cmd(escrow_id, reason, ...)`
  - `payout_create_cmd(merchant, recipient, amount, reference, ...)`
  - `payout_mark_paid_cmd(payout_id, ...)`
  - `treasury_spend_request_cmd(account_id, recipient, amount, purpose, ...)`
  - `product_gov_cmd(action, ...)`

**Package:** `pyproject.toml` with setuptools build, requires Python >=3.9, zero runtime dependencies (uses only `json`, `os`, `urllib.request`, `sys`).

**Test coverage:** 5 tests in `test_client.py` covering export existence, command-string return types, forbidden-pattern detection, and default API URL. Run with `python3 test_client.py`.

### REST Examples (`examples/rest/`)

36 endpoints demonstrated across 7 shell scripts (require `curl`, optional `jq`):

| Script | Queries |
|--------|---------|
| `check_live_flags.sh` | Live-enabled flags across all modules |
| `query_merchant.sh` | Merchant params, list, detail |
| `query_settlement.sh` | Settlement params, list, detail, filter |
| `query_escrow.sh` | Escrow params, list, detail, filter, exists |
| `query_treasury.sh` | Treasury params, summary, account, budget, grant, spend |
| `query_payout.sh` | Payout params, list, detail, filter, exists, batch |

### Write-Flow Examples (`examples/write-flows/`)

7 end-to-end shell scripts demonstrating multi-step workflows (requires running `nexaraild` CLI):

| Script | Description |
|--------|-------------|
| `bank_send_smoke.sh` | Bank send operations |
| `merchant_register.sh` | Merchant registration flow |
| `settlement_metadata.sh` | Settlement with metadata |
| `escrow_lifecycle.sh` | Full escrow lifecycle (create → release / dispute) |
| `payout_lifecycle.sh` | Payout creation and mark-paid |
| `treasury_spend.sh` | Treasury spend request flow |
| `governance_toggle_demo.sh` | Governance toggle of live flags |

### Dashboard (`examples/dashboard/`)

A browser-based dashboard (`index.html`, `styles.css`, `app.js`) for visual exploration of devnet state. Opens in any browser — no build step required.

---

## Security

- **Read-only by design:** The SDK performs only REST GET queries. It never holds, generates, or transmits private keys, mnemonics, or wallet secrets.
- **No wallet integration:** The SDK does not integrate with wallets, signing backends, or key management systems.
- **Command builders are string-only:** All `*Cmd` and `*_cmd` functions return plain CLI strings. They do not execute commands, spawn processes, or make network calls.
- **No private key leakage:** Automated tests verify that no export name or function parameter references private keys or mnemonics.

---

## Installation

### Node.js SDK

```bash
# Navigate to the SDK directory
cd examples/node-client

# Local install from source (recommended for development)
npm install

# Symlink for system-wide availability (optional)
npm link
```

Verify installation:

```bash
npm run check
# Expected output: OK: exports: get, getParams, getList, getDetail, ...
```

### Python SDK

```bash
# Navigate to the SDK directory
cd examples/python-client

# Editable install from local source
pip install -e .
```

Verify installation:

```bash
python3 -c "import nexarail_client; print(dir(nexarail_client))"
```

### REST Examples (no install required)

```bash
cd examples/rest
chmod +x *.sh
./check_live_flags.sh
```

---

## Quick Start

### Node.js

```js
import { getParams } from '@nexarail/devnet-client';

const params = await getParams('settlement');
console.log('Live enabled:', params.live_enabled);
```

### Python

```python
from nexarail_client import get_params

params = get_params('settlement')
print('Live enabled:', params.get('live_enabled'))
```

---

## Limitations

| Limitation | Details |
|-------------|---------|
| **No mainnet support** | The SDK is designed and tested exclusively against the RC1 devnet. It is not tested against mainnet or any public test network. |
| **No public testnet support** | While the REST API patterns may work against other deployments, `nodeStatus()` defaults to `localhost:26657` and all paths assume the `/nexarail/{module}/v1/` routing scheme of the RC1 devnet. |
| **No transaction execution** | The SDK does not sign, broadcast, or execute transactions. Use the command-string builders to generate `nexaraild` CLI commands, then run them separately. |
| **No wallet integration** | The SDK has no key management, address derivation, or signing capabilities. |
| **No npm/PyPI publication** | These packages are **NOT published** to either npm registry or PyPI. They are distributed as local source in the `examples/` directory. |
| **Local devnet only** | All defaults (`localhost:1317`, `localhost:26657`, `~/.nexarail-devnet`) are hardcoded for local development. Override via environment variables for other deployments. |

---

## Devnet Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `API` | `http://localhost:1317` | Cosmos SDK REST API endpoint |
| `RPC` | `http://localhost:26657` | CometBFT RPC endpoint |

---

## Version History

| Version | Date | Notes |
|---------|------|-------|
| `0.1.0-dev` | 2026-05-28 | Initial RC1 release. 18 functions per SDK, 36 REST endpoints, 7 write-flow examples, browser dashboard. |

---

## License

UNLICENSED — Internal developer tool. Not for redistribution.

---

## Final Warning

```
╔══════════════════════════════════════════════════════════════════════════╗
║  ⚠  LOCAL DEVNET ONLY                                                 ║
║                                                                        ║
║  This SDK is designed for the NexaRail Controlled Testnet RC1          ║
║  running on localhost.                                                 ║
║                                                                        ║
║  • NOT for mainnet                                                     ║
║  • NOT for any public testnet                                          ║
║  • NOT published to npm or PyPI                                        ║
║  • NOT a token launch tool                                             ║
║  • NO private key handling                                             ║
║  • NO transaction execution                                            ║
╚══════════════════════════════════════════════════════════════════════════╝
```
