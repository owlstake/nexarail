# NexaRail Demo App Plan

A blueprint for a lightweight read-only dashboard that visualises the NexaRail devnet state.

---

## Overview

**Purpose:** A local-only read-only dashboard for developers to inspect NexaRail chain state without needing `curl` or CLI commands.

**Scope:** Querying only — no transaction submission, no wallet integration, no authentication.

**Target audience:** Developers who want a visual overview of the devnet's product flows.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Browser / CLI                       │
│  (HTML+JS or terminal curses)                        │
└──────────┬──────────────────────────────────────────┘
           │ HTTP (JSON)
           ▼
┌─────────────────────────────────────────────────────┐
│              Node.js / Python Backend                │
│  ┌──────────────────────────────────────────────┐    │
│  │  Proxy Layer — passes requests to chain REST  │    │
│  │  Caches block height for dedup                │    │
│  │  Running on localhost:3000 (or similar)       │    │
│  └──────────────────────────────────────────────┘    │
└──────────┬──────────────────────────────────────────┘
           │ HTTP (cURL to chain REST)
           ▼
┌─────────────────────────────────────────────────────┐
│           NexaRail Devnet (localhost:1317)           │
│  ┌──────────────────────────────────────────────┐    │
│  │  RegisterRuntimeReadbackRoutes (35 endpoints) │    │
│  └──────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

### Technology Options

| Layer | Option A | Option B |
|-------|----------|----------|
| Backend | Node.js (Express) | Python (Flask/FastAPI) |
| Frontend | HTML + vanilla JS + Tailwind CSS | CLI with rich/click (Python) |
| HTTP client | `fetch` in browser → Express proxy | `requests` → Flask proxy |
| JSON formatting | `jq`-style pretty print | `rich.json` |

**Recommendation:** Node.js backend (Express) + HTML + vanilla JS. No build step. Single-file executable.

---

## Sections

### 1. Local Devnet Status Panel

**What it shows:**
- Chain ID (e.g. `nexarail-devnet-1`)
- Latest block height (auto-refreshes every 10s)
- Node moniker
- Number of validators
- Node sync status
- Bank total supply

**REST endpoints called:**
- `GET http://127.0.0.1:26657/status` — CometBFT RPC status
- `GET http://127.0.0.1:26657/validators` — Validator set
- `GET http://127.0.0.1:1317/cosmos/bank/v1beta1/supply` — Total supply

**Reference files:**
- `scripts/release/query-rc1-devnet.sh` — Example status queries
- `scripts/testnet/check-node-health.sh` — Node health check pattern

### 2. Live Flag Display (All 6 Flags)

**What it shows:**
A table or card grid showing each of the 6 live flags and their current state (`true`/`false`):

| Module | Flag | Status |
|--------|------|--------|
| Settlement | `live_enabled` | ❌ false / ✅ true |
| Settlement | `treasury_routing_enabled` | ❌ false / ✅ true |
| Settlement | `burn_routing_enabled` | ❌ false / ✅ true |
| Escrow | `live_enabled` | ❌ false / ✅ true |
| Treasury | `live_enabled` | ❌ false / ✅ true |
| Payout | `live_enabled` | ❌ false / ✅ true |

**REST endpoints called:**
- `GET /nexarail/settlement/v1/params` — 3 flags
- `GET /nexarail/escrow/v1/params` — 1 flag
- `GET /nexarail/treasury/v1/params` — 1 flag
- `GET /nexarail/payout/v1/params` — 1 flag

**Reference files:**
- `docs/design/LIVE_FLAGS_MATRIX.md` — Full flag reference
- `scripts/testnet/product-gov.sh` (`show_live_flags` function) — Example query pattern
- `docs/developers/API_EXAMPLES.md` — Live flags check section

### 3. Merchant List View

**What it shows:**
- Total count of registered merchants
- Table: Name, Owner Address, Status, Website
- Click a row to see merchant details

**REST endpoints called:**
- `GET /nexarail/merchant/v1/merchants` — List all merchants
- `GET /nexarail/merchant/v1/merchant/{owner}` — Individual merchant detail

**Reference files:**
- `docs/developers/PRODUCT_FLOW_EXAMPLES.md` — Merchant onboarding flow
- `x/merchant/types/merchant.go` — Merchant struct definition

### 4. Settlement List View

**What it shows:**
- Total count of settlements
- Table: ID, Merchant Owner, Payer, Amount, Status
- Summary of settlement amounts
- Filter by merchant owner or payer (client-side)

**REST endpoints called:**
- `GET /nexarail/settlement/v1/settlements` — List all settlements
- `GET /nexarail/settlement/v1/settlement/{id}` — Individual settlement detail
- `GET /nexarail/settlement/v1/settlements/by-merchant/{owner}` — Filtered list
- `GET /nexarail/settlement/v1/settlements/by-payer/{payer}` — Filtered list

**Reference files:**
- `docs/developers/API_EXAMPLES.md` — Settlement endpoints
- `x/settlement/types/settlement.go` — Settlement struct definition

### 5. Escrow List/Detail View

**What it shows:**
- Total count of escrows
- Table: ID, Buyer, Seller, Merchant, Amount, Status, Custodied
- Detail panel: full escrow record including timestamps
- Filter by buyer, seller, or merchant

**REST endpoints called:**
- `GET /nexarail/escrow/v1/escrows` — List all escrows
- `GET /nexarail/escrow/v1/escrow/{id}` — Individual escrow detail
- `GET /nexarail/escrow/v1/escrows/by-buyer/{buyer}` — Filtered
- `GET /nexarail/escrow/v1/escrows/by-seller/{seller}` — Filtered
- `GET /nexarail/escrow/v1/escrows/by-merchant/{merchant}` — Filtered
- `GET /nexarail/escrow/v1/escrow/exists/{id}` — Exists check

**Reference files:**
- `docs/developers/PRODUCT_FLOW_EXAMPLES.md` — Escrow lifecycle flow
- `x/escrow/types/escrow.go` — Escrow struct definition

### 6. Payout List/Detail View

**What it shows:**
- Total count of individual payouts and batch payouts
- Table: ID, Recipient, Amount, Status, Initiator
- Batch payout table: ID, payout count, total amount, status
- Filter by merchant, recipient, or initiator

**REST endpoints called:**
- `GET /nexarail/payout/v1/payouts` — List all payouts
- `GET /nexarail/payout/v1/payout/{id}` — Individual payout detail
- `GET /nexarail/payout/v1/payout/exists/{id}` — Exists check
- `GET /nexarail/payout/v1/payouts/by-merchant/{merchant}` — Filtered
- `GET /nexarail/payout/v1/payouts/by-recipient/{recipient}` — Filtered
- `GET /nexarail/payout/v1/payouts/by-initiator/{initiator}` — Filtered
- `GET /nexarail/payout/v1/batch-payouts` — List all batch payouts
- `GET /nexarail/payout/v1/batch-payout/{id}` — Individual batch payout detail

**Reference files:**
- `docs/developers/PRODUCT_FLOW_EXAMPLES.md` — Payout flow
- `x/payout/types/payout.go` — Payout struct definition
- `x/payout/types/batch.go` — Batch payout struct definition

### 7. Treasury Summary, Accounts, Budgets, Grants, Spends

**What it shows:**
- Summary card: total accounts, budgets, grants, spend requests
- Accounts table: ID, Owner, Name, Balance
- Budgets table: ID, Account, Total, Spent, Remaining
- Grants table: ID, Recipient, Amount, Status
- Spends table: ID, Account, Budget, Recipient, Amount, Status
- Click through from account → its budgets

**REST endpoints called:**
- `GET /nexarail/treasury/v1/summary` — Counts of all sub-collections
- `GET /nexarail/treasury/v1/accounts` — All treasury accounts
- `GET /nexarail/treasury/v1/account/{id}` — Single account detail
- `GET /nexarail/treasury/v1/budgets` — All budgets
- `GET /nexarail/treasury/v1/budget/{id}` — Single budget detail
- `GET /nexarail/treasury/v1/grants` — All grants
- `GET /nexarail/treasury/v1/grant/{id}` — Single grant detail
- `GET /nexarail/treasury/v1/spends` — All spend requests
- `GET /nexarail/treasury/v1/spend/{id}` — Single spend request detail

**Reference files:**
- `docs/developers/PRODUCT_FLOW_EXAMPLES.md` — Treasury spend flow
- `x/treasury/types/treasury.go` — Treasury account struct
- `x/treasury/types/budget.go` — Budget struct
- `x/treasury/types/grant.go` — Grant struct
- `x/treasury/types/spend.go` — Spend request struct

### 8. Product-Flow Evidence Links

**What it shows:**
- Quick links to the developer docs for each product flow
- Shows which live flags need to be enabled for each flow
- Links to the actual test evidence in `rehearsals/`

**Reference documents:**
- `docs/developers/DEVELOPER_QUICKSTART.md`
- `docs/developers/API_EXAMPLES.md`
- `docs/developers/PRODUCT_FLOW_EXAMPLES.md`
- `docs/testnet/LIVE_FUNDS_REHEARSAL_COMMANDS.md`
- `docs/testnet/PRODUCT_FLOW_EVIDENCE_INDEX.md`

---

## Implementation Notes

### Backend Proxy (Node.js/Express)

```javascript
// Conceptual backend — 30 lines
const express = require('express');
const app = express();
const CHAIN_REST = 'http://127.0.0.1:1317';
const CHAIN_RPC  = 'http://127.0.0.1:26657';

// Proxy: just forward to chain, add CORS
app.get('/api/*', async (req, res) => {
  const path = req.params[0];
  const base = path.startsWith('rpc/') ? CHAIN_RPC : CHAIN_REST;
  const url = `${base}/${path.replace(/^rpc\//, '')}`;
  const chainResp = await fetch(url);
  const data = await chainResp.json();
  res.json(data);
});

app.use(express.static('public'));
app.listen(3000, () => console.log('Dashboard on http://localhost:3000'));
```

### Frontend (HTML + Vanilla JS)

- Single `index.html` file with inline CSS/JS
- Uses `fetch('/api/nexarail/...')` to call the proxy
- Updates status every 10s via `setInterval`
- All sections are collapsible `<details>` panels

### Security

- **No authentication** — devnet only, localhost
- **No CORS issues** — browser same-origin to the proxy
- **No state mutation** — read-only queries only
- **No wallet integration** — no signing, no private keys

### What NOT to Build

- ❌ No write endpoints (no POST, no tx broadcasting)
- ❌ No authentication/authorisation
- ❌ No WebSocket/subscription (polling is fine for devnet)
- ❌ No database/storage (all data is live from chain)
- ❌ No Docker/deployment config (runs from source)
- ❌ No live-fee flows (fee split is displayed but not interactive)
- ❌ No form inputs that mutate chain state

---

## Estimated Effort

| Component | Lines of Code | Estimated Time |
|-----------|--------------|---------------|
| Backend proxy (Express) | ~50 | 1 hour |
| Status panel + live flags | ~100 | 1 hour |
| Merchant view | ~80 | 30 min |
| Settlement view | ~100 | 1 hour |
| Escrow view | ~120 | 1 hour |
| Payout view | ~150 | 1.5 hours |
| Treasury view | ~200 | 2 hours |
| Evidence links + nav | ~50 | 30 min |
| **Total** | **~850** | **~8 hours** |

---

## Quick Start Implementation Guide

1. Create `backend/` directory with `package.json` and `server.js`
2. Implement the proxy route (`GET /api/*`)
3. Create `public/index.html` with collapsible section for each module
4. For each section, write a JS function that `fetch`es the relevant endpoints and renders tables
5. Add a 10-second auto-refresh timer on the status panel
6. Test against a running single-node devnet

The entire app can be a single `index.html` + one `server.js` with no external dependencies beyond `express` and `node-fetch`.
