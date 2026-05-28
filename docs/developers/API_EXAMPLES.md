# NexaRail REST API Examples

This document provides `curl` examples for every custom REST readback endpoint registered in `NexaRailApp.RegisterRuntimeReadbackRoutes`.

> **Base URL:** `http://127.0.0.1:1317` (single-node devnet default)
> **All endpoints are GET-only, read-only.** See `docs/api/REST_READBACK_LIMITATIONS.md` for design rationale.

---

## Node Status (CometBFT RPC)

Though not a custom REST endpoint, the RPC status is the primary way to check node health:

```bash
curl -s http://127.0.0.1:26657/status | jq .
```

**Response (truncated):**

```json
{
  "jsonrpc": "2.0",
  "id": -1,
  "result": {
    "node_info": {
      "network": "nexarail-devnet-1",
      "version": "0.37.18"
    },
    "sync_info": {
      "latest_block_height": "42",
      "latest_block_time": "2026-05-27T12:34:56Z"
    },
    "validator_info": {
      "address": "ABC123..."
    }
  }
}
```

**What it means:** The node is running on chain `nexarail-devnet-1` at block height 42.

---

## Module: Fees

### GET /nexarail/fees/v1/params

Returns the current fee module parameters (split proportions, collector config).

```bash
curl -s http://127.0.0.1:1317/nexarail/fees/v1/params | jq .
```

**Response:**

```json
{
  "params": {
    "validator_share_bps": 6000,
    "treasury_share_bps": 2000,
    "burn_share_bps": 2000,
    "fee_collector_name": "fee_collector",
    "treasury_account": "",
    "burn_enabled": false,
    "min_protocol_fee": {
      "denom": "unxrl",
      "amount": "0"
    }
  }
}
```

**What it means:** 60% of fees go to validators, 20% to treasury, 20% burned. Treasury account and burn are disabled.

### GET /nexarail/fees/v1/fee_split

Returns just the three split percentages (shorthand).

```bash
curl -s http://127.0.0.1:1317/nexarail/fees/v1/fee_split | jq .
```

**Response:**

```json
{
  "validator_share_bps": 6000,
  "treasury_share_bps": 2000,
  "burn_share_bps": 2000
}
```

**What it means:** Same data as params but in compact format: validator 60%, treasury 20%, burn 20%.

---

## Module: Merchant

### GET /nexarail/merchant/v1/params

```bash
curl -s http://127.0.0.1:1317/nexarail/merchant/v1/params | jq .
```

**Response:**

```json
{
  "params": {
    "merchant_fee_bps": 100,
    "max_merchants_per_owner": 5
  }
}
```

**What it means:** Merchant registration fee is 1% (100 bps). Each owner can register up to 5 merchants.

### GET /nexarail/merchant/v1/merchants

Lists all registered merchants (empty on fresh devnet).

```bash
curl -s http://127.0.0.1:1317/nexarail/merchant/v1/merchants | jq .
```

**Response (empty):**

```json
{
  "merchants": []
}
```

**Response (with data):**

```json
{
  "merchants": [
    {
      "owner": "nxrl1...",
      "name": "Test Merchant",
      "description": "A test merchant for development",
      "website": "https://example.com",
      "status": 0
    }
  ]
}
```

**What it means:** Lists every registered merchant. Status `0` = active.

### GET /nexarail/merchant/v1/merchant/{owner}

Looks up a single merchant by owner address.

```bash
curl -s "http://127.0.0.1:1317/nexarail/merchant/v1/merchant/nxrl1..." | jq .
```

**Response (found):**

```json
{
  "merchant": {
    "owner": "nxrl1...",
    "name": "Test Merchant",
    "description": "A test merchant",
    "website": "https://example.com",
    "status": 0
  }
}
```

**Response (not found):**

```json
{
  "error": "merchant nxrl1... not found"
}
```

**What it means:** Returns 404 + error message when the specified owner has no registered merchant.

---

## Module: Settlement

### GET /nexarail/settlement/v1/params

```bash
curl -s http://127.0.0.1:1317/nexarail/settlement/v1/params | jq .
```

**Response:**

```json
{
  "params": {
    "live_enabled": false,
    "treasury_routing_enabled": false,
    "burn_routing_enabled": false,
    "max_settlements_per_batch": 100
  }
}
```

**What it means:** All three live flags are `false`. Settlement processing is metadata-only (no fund movement).

### GET /nexarail/settlement/v1/settlements

```bash
curl -s http://127.0.0.1:1317/nexarail/settlement/v1/settlements | jq .
```

**Response (empty):**

```json
{
  "settlements": []
}
```

**Response (with data):**

```json
{
  "settlements": [
    {
      "id": "1",
      "merchant_owner": "nxrl1...",
      "payer": "nxrl1...",
      "amount": {
        "denom": "unxrl",
        "amount": "100000"
      },
      "description": "Test payment",
      "status": "completed"
    }
  ]
}
```

**What it means:** Lists all settlement records. Status values: `pending`, `completed`, `failed`.

### GET /nexarail/settlement/v1/settlement/{id}

Looks up a settlement by numeric ID.

```bash
curl -s http://127.0.0.1:1317/nexarail/settlement/v1/settlement/1 | jq .
```

**Response:**

```json
{
  "settlement": {
    "id": "1",
    "merchant_owner": "nxrl1...",
    "payer": "nxrl1...",
    "amount": {
      "denom": "unxrl",
      "amount": "100000"
    },
    "description": "Test payment",
    "status": "completed"
  }
}
```

**Response (not found, e.g. ID 999):**

```json
{
  "error": "settlement 999 not found"
}
```

**What it means:** Returns the settlement record or a 404 error.

### GET /nexarail/settlement/v1/settlements/by-merchant/{owner}

```bash
curl -s "http://127.0.0.1:1317/nexarail/settlement/v1/settlements/by-merchant/nxrl1..." | jq .
```

**Response:**

```json
{
  "settlements": []
}
```

**What it means:** Returns all settlements for a given merchant owner. Empty array means none found (not an error).

### GET /nexarail/settlement/v1/settlements/by-payer/{payer}

```bash
curl -s "http://127.0.0.1:1317/nexarail/settlement/v1/settlements/by-payer/nxrl1..." | jq .
```

**Response:**

```json
{
  "settlements": []
}
```

**What it means:** Returns all settlements paid by a given address.

---

## Module: Escrow

### GET /nexarail/escrow/v1/params

```bash
curl -s http://127.0.0.1:1317/nexarail/escrow/v1/params | jq .
```

**Response:**

```json
{
  "params": {
    "live_enabled": false,
    "escrow_timeout_blocks": 10000,
    "min_escrow_amount": {
      "denom": "unxrl",
      "amount": "1000"
    }
  }
}
```

**What it means:** `live_enabled=false` means escrow operations are metadata-only. No funds move in or out of the escrow module account.

### GET /nexarail/escrow/v1/escrows

```bash
curl -s http://127.0.0.1:1317/nexarail/escrow/v1/escrows | jq .
```

**Response (empty):**

```json
{
  "escrows": []
}
```

**Response (with data):**

```json
{
  "escrows": [
    {
      "id": "escrow-001",
      "buyer": "nxrl1...",
      "seller": "nxrl1...",
      "merchant_id": "Test Merchant",
      "denom": "unxrl",
      "amount": {
        "denom": "unxrl",
        "amount": "10000"
      },
      "status": "funded",
      "funds_custodied": true
    }
  ]
}
```

**What it means:** Lists all escrow records. Statuses: `pending`, `funded`, `released`, `refunded`, `cancelled`.

### GET /nexarail/escrow/v1/escrow/{id}

```bash
curl -s http://127.0.0.1:1317/nexarail/escrow/v1/escrow/escrow-001 | jq .
```

**Response:**

```json
{
  "escrow": {
    "id": "escrow-001",
    "buyer": "nxrl1...",
    "seller": "nxrl1...",
    "merchant_id": "Test Merchant",
    "denom": "unxrl",
    "amount": {
      "denom": "unxrl",
      "amount": "10000"
    },
    "status": "funded",
    "funds_custodied": true
  }
}
```

**Response (not found):**

```json
{
  "error": "escrow nonexistent not found"
}
```

### GET /nexarail/escrow/v1/escrows/by-buyer/{buyer}

```bash
curl -s "http://127.0.0.1:1317/nexarail/escrow/v1/escrows/by-buyer/nxrl1..." | jq .
```

### GET /nexarail/escrow/v1/escrows/by-seller/{seller}

```bash
curl -s "http://127.0.0.1:1317/nexarail/escrow/v1/escrows/by-seller/nxrl1..." | jq .
```

### GET /nexarail/escrow/v1/escrows/by-merchant/{merchant}

```bash
curl -s "http://127.0.0.1:1317/nexarail/escrow/v1/escrows/by-merchant/my-merchant" | jq .
```

All filtered list endpoints return `{"escrows": [...]}` — empty array when no matches.

### GET /nexarail/escrow/v1/escrow/exists/{id}

Convenience check — returns boolean, never 404.

```bash
curl -s http://127.0.0.1:1317/nexarail/escrow/v1/escrow/exists/escrow-001 | jq .
```

**Response (exists):**

```json
{
  "exists": true
}
```

**Response (not found):**

```json
{
  "exists": false
}
```

**What it means:** Returns `true`/`false` without the overhead of fetching the full escrow record.

---

## Module: Payout

### GET /nexarail/payout/v1/params

```bash
curl -s http://127.0.0.1:1317/nexarail/payout/v1/params | jq .
```

**Response:**

```json
{
  "params": {
    "live_enabled": false,
    "payout_timeout_blocks": 10000,
    "min_payout_amount": {
      "denom": "unxrl",
      "amount": "1000"
    }
  }
}
```

**What it means:** `live_enabled=false` means marking a payout as "paid" is metadata-only — no funds are transferred.

### GET /nexarail/payout/v1/payouts

```bash
curl -s http://127.0.0.1:1317/nexarail/payout/v1/payouts | jq .
```

**Response (empty):**

```json
{
  "payouts": []
}
```

**Response (with data):**

```json
{
  "payouts": [
    {
      "id": "payout-001",
      "recipient": "nxrl1...",
      "amount": {
        "denom": "unxrl",
        "amount": "2500"
      },
      "status": "pending",
      "description": "Test payout"
    }
  ]
}
```

**What it means:** Lists all individual payout records. Statuses: `pending`, `approved`, `paid`, `rejected`.

### GET /nexarail/payout/v1/payout/{id}

```bash
curl -s http://127.0.0.1:1317/nexarail/payout/v1/payout/payout-001 | jq .
```

**Response (found):**

```json
{
  "payout": {
    "id": "payout-001",
    "recipient": "nxrl1...",
    "amount": {
      "denom": "unxrl",
      "amount": "2500"
    },
    "status": "pending",
    "description": "Test payout"
  }
}
```

**Response (not found):**

```json
{
  "error": "payout nonexistent not found"
}
```

### GET /nexarail/payout/v1/payout/exists/{id}

```bash
curl -s http://127.0.0.1:1317/nexarail/payout/v1/payout/exists/payout-001 | jq .
```

**Response:**

```json
{
  "exists": true
}
```

### GET /nexarail/payout/v1/payouts/by-merchant/{merchant}

```bash
curl -s "http://127.0.0.1:1317/nexarail/payout/v1/payouts/by-merchant/my-merchant" | jq .
```

### GET /nexarail/payout/v1/payouts/by-recipient/{recipient}

```bash
curl -s "http://127.0.0.1:1317/nexarail/payout/v1/payouts/by-recipient/nxrl1..." | jq .
```

### GET /nexarail/payout/v1/payouts/by-initiator/{initiator}

```bash
curl -s "http://127.0.0.1:1317/nexarail/payout/v1/payouts/by-initiator/nxrl1..." | jq .
```

All filtered list endpoints return `{"payouts": [...]}` — empty array when no matches.

### GET /nexarail/payout/v1/batch-payout/{id}

```bash
curl -s http://127.0.0.1:1317/nexarail/payout/v1/batch-payout/batch-001 | jq .
```

**Response (found):**

```json
{
  "batch_payout": {
    "id": "batch-001",
    "initiator": "nxrl1...",
    "payout_ids": ["payout-001", "payout-002"],
    "total_amount": {
      "denom": "unxrl",
      "amount": "5000"
    },
    "status": "pending"
  }
}
```

**Response (not found):**

```json
{
  "error": "batch payout nonexistent not found"
}
```

### GET /nexarail/payout/v1/batch-payouts

```bash
curl -s http://127.0.0.1:1317/nexarail/payout/v1/batch-payouts | jq .
```

**Response:**

```json
{
  "batch_payouts": []
}
```

**What it means:** Lists all batch-payout records.

---

## Module: Treasury

### GET /nexarail/treasury/v1/params

```bash
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/params | jq .
```

**Response:**

```json
{
  "params": {
    "live_enabled": false,
    "max_spend_amount": {
      "denom": "unxrl",
      "amount": "1000000000"
    }
  }
}
```

**What it means:** `live_enabled=false` means treasury spend execution is metadata-only. `max_spend_amount` limits individual spend amounts.

### GET /nexarail/treasury/v1/summary

Derived endpoint — returns totals for all treasury sub-collections.

```bash
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/summary | jq .
```

**Response (empty):**

```json
{
  "total_accounts": 0,
  "total_budgets": 0,
  "total_grants": 0,
  "total_spend_requests": 0
}
```

**Response (with data):**

```json
{
  "total_accounts": 2,
  "total_budgets": 3,
  "total_grants": 1,
  "total_spend_requests": 5
}
```

**What it means:** Quick overview of the treasury state. Each count is computed by iterating the keeper's store.

### GET /nexarail/treasury/v1/account/{id}

```bash
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/account/acct-001 | jq .
```

**Response (found):**

```json
{
  "treasury_account": {
    "id": "acct-001",
    "owner": "nxrl1...",
    "name": "Operations Account",
    "description": "Main ops treasury",
    "balance": {
      "denom": "unxrl",
      "amount": "5000000"
    }
  }
}
```

**Response (not found):**

```json
{
  "error": "treasury account nonexistent not found"
}
```

### GET /nexarail/treasury/v1/accounts

```bash
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/accounts | jq .
```

**Response:**

```json
{
  "treasury_accounts": []
}
```

Response key is `treasury_accounts` (note: plural, not `accounts`).

### GET /nexarail/treasury/v1/budget/{id}

```bash
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/budget/bgt-001 | jq .
```

**Response (found):**

```json
{
  "budget": {
    "id": "bgt-001",
    "account_id": "acct-001",
    "name": "Q2 Budget",
    "total_amount": {
      "denom": "unxrl",
      "amount": "10000000"
    },
    "spent": {
      "denom": "unxrl",
      "amount": "2500000"
    },
    "remaining": {
      "denom": "unxrl",
      "amount": "7500000"
    }
  }
}
```

**Response (not found):**

```json
{
  "error": "budget nonexistent not found"
}
```

### GET /nexarail/treasury/v1/budgets

```bash
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/budgets | jq .
```

### GET /nexarail/treasury/v1/grant/{id}

```bash
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/grant/grnt-001 | jq .
```

**Response (found):**

```json
{
  "grant": {
    "id": "grnt-001",
    "account_id": "acct-001",
    "recipient": "nxrl1...",
    "amount": {
      "denom": "unxrl",
      "amount": "500000"
    },
    "description": "Community grant",
    "status": "active"
  }
}
```

**Response (not found):**

```json
{
  "error": "grant nonexistent not found"
}
```

### GET /nexarail/treasury/v1/grants

```bash
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/grants | jq .
```

### GET /nexarail/treasury/v1/spend/{id}

```bash
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/spend/spend-001 | jq .
```

**Response (found):**

```json
{
  "spend_request": {
    "id": "spend-001",
    "account_id": "acct-001",
    "budget_id": "bgt-001",
    "recipient": "nxrl1...",
    "amount": {
      "denom": "unxrl",
      "amount": "5000"
    },
    "description": "Ops expense",
    "status": "pending"
  }
}
```

**Response (not found):**

```json
{
  "error": "spend request nonexistent not found"
}
```

Statuses: `pending`, `approved`, `executed`, `rejected`.

### GET /nexarail/treasury/v1/spends

```bash
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/spends | jq .
```

**Response (empty):**

```json
{
  "spend_requests": []
}
```

Note: Response key is `spend_requests` (not `spends`), matching the keeper method name.

---

## Live Flags Check Across All 4 Modules

Quick one-liner to check all 6 live flags:

```bash
echo "=== Settlement ==="
curl -s http://127.0.0.1:1317/nexarail/settlement/v1/params | jq '{live: .params.live_enabled, treasury_routing: .params.treasury_routing_enabled, burn_routing: .params.burn_routing_enabled}'

echo "=== Escrow ==="
curl -s http://127.0.0.1:1317/nexarail/escrow/v1/params | jq '{live: .params.live_enabled}'

echo "=== Treasury ==="
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/params | jq '{live: .params.live_enabled}'

echo "=== Payout ==="
curl -s http://127.0.0.1:1317/nexarail/payout/v1/params | jq '{live: .params.live_enabled}'
```

**Expected output on fresh devnet:**

```json
{
  "live": false,
  "treasury_routing": false,
  "burn_routing": false
}
{
  "live": false
}
{
  "live": false
}
{
  "live": false
}
```

For a scripted check, use the `api-smoke-test.sh` script or `product-gov.sh show-live-flags`.

---

## Summary

| Module | Endpoints | Response Key |
|--------|-----------|-------------|
| Fees | params, fee_split | `params`, (direct) |
| Merchant | params, merchants, merchant/{owner} | `params`, `merchants`, `merchant` |
| Settlement | params, settlements, settlement/{id}, by-merchant/{o}, by-payer/{p} | `params`, `settlements`, `settlement` |
| Escrow | params, escrows, escrow/{id}, by-buyer/{b}, by-seller/{s}, by-merchant/{m}, exists/{id} | `params`, `escrows`, `escrow`, `exists` |
| Payout | params, payouts, payout/{id}, exists/{id}, by-merchant/{m}, by-recipient/{r}, by-initiator/{i}, batch-payout/{id}, batch-payouts | `params`, `payouts`, `payout`, `exists`, `batch_payout`, `batch_payouts` |
| Treasury | params, summary, account/{id}, accounts, budget/{id}, budgets, grant/{id}, grants, spend/{id}, spends | `params`, (direct), `treasury_account`, `treasury_accounts`, `budget`, `budgets`, `grant`, `grants`, `spend_request`, `spend_requests` |

**Total: 35 endpoints across 6 modules.**
