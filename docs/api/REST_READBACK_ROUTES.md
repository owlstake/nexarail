# NexaRail REST Readback Routes

All routes below are **read-only**, **GET-only**, custom HTTP query endpoints registered by `NexaRailApp.RegisterRuntimeReadbackRoutes` in `app/app.go`. They query the **current committed state** via an uncached SDK context — no writes, no tx broadcasting.

---

## Summary Table

| # | Path | Module | Type |
|---|------|--------|------|
| 1 | `GET /nexarail/fees/v1/params` | Fees | params |
| 2 | `GET /nexarail/merchant/v1/params` | Merchant | params |
| 3 | `GET /nexarail/merchant/v1/merchants` | Merchant | list-all |
| 4 | `GET /nexarail/merchant/v1/merchant/{owner}` | Merchant | detail |
| 5 | `GET /nexarail/settlement/v1/params` | Settlement | params |
| 6 | `GET /nexarail/settlement/v1/settlements` | Settlement | list-all |
| 7 | `GET /nexarail/settlement/v1/settlement/{id}` | Settlement | detail |
| 8 | `GET /nexarail/settlement/v1/settlements/by-merchant/{owner}` | Settlement | list-filtered |
| 9 | `GET /nexarail/settlement/v1/settlements/by-payer/{payer}` | Settlement | list-filtered |
| 10 | `GET /nexarail/escrow/v1/params` | Escrow | params |
| 11 | `GET /nexarail/escrow/v1/escrows` | Escrow | list-all |
| 12 | `GET /nexarail/escrow/v1/escrow/{id}` | Escrow | detail |
| 13 | `GET /nexarail/escrow/v1/escrows/by-buyer/{buyer}` | Escrow | list-filtered |
| 14 | `GET /nexarail/escrow/v1/escrows/by-seller/{seller}` | Escrow | list-filtered |
| 15 | `GET /nexarail/escrow/v1/escrows/by-merchant/{merchant}` | Escrow | list-filtered |
| 16 | `GET /nexarail/escrow/v1/escrow/exists/{id}` | Escrow | exists-check |
| 17 | `GET /nexarail/payout/v1/params` | Payout | params |
| 18 | `GET /nexarail/payout/v1/payouts` | Payout | list-all |
| 19 | `GET /nexarail/payout/v1/payout/{id}` | Payout | detail |
| 20 | `GET /nexarail/payout/v1/payout/exists/{id}` | Payout | exists-check |
| 21 | `GET /nexarail/payout/v1/payouts/by-merchant/{merchant}` | Payout | list-filtered |
| 22 | `GET /nexarail/payout/v1/payouts/by-recipient/{recipient}` | Payout | list-filtered |
| 23 | `GET /nexarail/payout/v1/payouts/by-initiator/{initiator}` | Payout | list-filtered |
| 24 | `GET /nexarail/payout/v1/batch-payout/{id}` | Payout | detail |
| 25 | `GET /nexarail/payout/v1/batch-payouts` | Payout | list-all |
| 26 | `GET /nexarail/treasury/v1/params` | Treasury | params |
| 27 | `GET /nexarail/treasury/v1/summary` | Treasury | derived |
| 28 | `GET /nexarail/treasury/v1/spend/{id}` | Treasury | detail |
| 29 | `GET /nexarail/treasury/v1/spends` | Treasury | list-all |
| 30 | `GET /nexarail/treasury/v1/account/{id}` | Treasury | detail |
| 31 | `GET /nexarail/treasury/v1/accounts` | Treasury | list-all |
| 32 | `GET /nexarail/treasury/v1/budget/{id}` | Treasury | detail |
| 33 | `GET /nexarail/treasury/v1/budgets` | Treasury | list-all |
| 34 | `GET /nexarail/treasury/v1/grant/{id}` | Treasury | detail |
| 35 | `GET /nexarail/treasury/v1/grants` | Treasury | list-all |

---

## Module: Fees

### `GET /nexarail/fees/v1/params`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/fees/v1/params` |
| **Module** | Fees |
| **Description** | Returns the current on-chain fees module parameters (fee rates, collectors, etc.). No path or query parameters. |
| **Response key** | `params` |
| **Read-only** | Yes |
| **Empty state** | Always populated — params exist as long as the chain has been initialised. |
| **Not found** | N/A — always returns the keeper's params. |

---

## Module: Merchant

### `GET /nexarail/merchant/v1/params`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/merchant/v1/params` |
| **Module** | Merchant |
| **Description** | Returns the current on-chain merchant module parameters. |
| **Response key** | `params` |
| **Read-only** | Yes |
| **Empty state** | Always populated. |
| **Not found** | N/A. |

### `GET /nexarail/merchant/v1/merchants`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/merchant/v1/merchants` |
| **Module** | Merchant |
| **Description** | Returns all registered merchants on the chain. |
| **Response key** | `merchants` (array) |
| **Read-only** | Yes |
| **Empty state** | Returns `{"merchants": []}` — an empty array, never an error. |
| **Not found** | N/A — always returns a (possibly empty) array. |

### `GET /nexarail/merchant/v1/merchant/{owner}`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/merchant/v1/merchant/{owner}` |
| **Path param** | `owner` — Bech32-encoded address of the merchant owner |
| **Module** | Merchant |
| **Description** | Returns a single merchant identified by its owner address. |
| **Response key** | `merchant` |
| **Read-only** | Yes |
| **Empty state** | N/A — returns 404 when not found. |
| **Not found** | Returns HTTP 404 with error message `merchant {owner} not found`. Also rejects empty or malformed bech32 addresses with `invalid merchant owner address`. |

---

## Module: Settlement

### `GET /nexarail/settlement/v1/params`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/settlement/v1/params` |
| **Module** | Settlement |
| **Description** | Returns the current on-chain settlement module parameters. |
| **Response key** | `params` |
| **Read-only** | Yes |
| **Empty state** | Always populated. |
| **Not found** | N/A. |

### `GET /nexarail/settlement/v1/settlements`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/settlement/v1/settlements` |
| **Module** | Settlement |
| **Description** | Returns all settlements recorded on the chain. |
| **Response key** | `settlements` (array) |
| **Read-only** | Yes |
| **Empty state** | Returns `{"settlements": []}`. |
| **Not found** | N/A. |

### `GET /nexarail/settlement/v1/settlement/{id}`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/settlement/v1/settlement/{id}` |
| **Path param** | `id` — unsigned 64-bit integer |
| **Module** | Settlement |
| **Description** | Returns a single settlement by its numeric ID. |
| **Response key** | `settlement` |
| **Read-only** | Yes |
| **Empty state** | N/A — returns 404 |
| **Not found** | Returns HTTP 404 with error `settlement {id} not found`. Non-numeric `id` values return a parse error: `settlement id: ...`. |

### `GET /nexarail/settlement/v1/settlements/by-merchant/{owner}`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/settlement/v1/settlements/by-merchant/{owner}` |
| **Path param** | `owner` — merchant owner address (string) |
| **Module** | Settlement |
| **Description** | Returns all settlements associated with a given merchant owner address. |
| **Response key** | `settlements` (array) |
| **Read-only** | Yes |
| **Empty state** | Returns `{"settlements": []}`. |
| **Not found** | N/A — returns empty array if no settlements match. |

### `GET /nexarail/settlement/v1/settlements/by-payer/{payer}`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/settlement/v1/settlements/by-payer/{payer}` |
| **Path param** | `payer` — payer address (string) |
| **Module** | Settlement |
| **Description** | Returns all settlements where the given address is the payer. |
| **Response key** | `settlements` (array) |
| **Read-only** | Yes |
| **Empty state** | Returns `{"settlements": []}`. |
| **Not found** | N/A. |

---

## Module: Escrow

### `GET /nexarail/escrow/v1/params`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/escrow/v1/params` |
| **Module** | Escrow |
| **Description** | Returns the current on-chain escrow module parameters. |
| **Response key** | `params` |
| **Read-only** | Yes |
| **Empty state** | Always populated. |
| **Not found** | N/A. |

### `GET /nexarail/escrow/v1/escrows`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/escrow/v1/escrows` |
| **Module** | Escrow |
| **Description** | Returns all escrows recorded on the chain. |
| **Response key** | `escrows` (array) |
| **Read-only** | Yes |
| **Empty state** | Returns `{"escrows": []}`. |
| **Not found** | N/A. |

### `GET /nexarail/escrow/v1/escrow/{id}`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/escrow/v1/escrow/{id}` |
| **Path param** | `id` — escrow identifier (string) |
| **Module** | Escrow |
| **Description** | Returns a single escrow by its ID. |
| **Response key** | `escrow` |
| **Read-only** | Yes |
| **Empty state** | N/A — returns 404 |
| **Not found** | Returns HTTP 404 with error `escrow {id} not found`. Also rejects empty `id` with `escrow id required`. |

### `GET /nexarail/escrow/v1/escrows/by-buyer/{buyer}`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/escrow/v1/escrows/by-buyer/{buyer}` |
| **Path param** | `buyer` — buyer address (string) |
| **Module** | Escrow |
| **Description** | Returns all escrows where the given address is the buyer. |
| **Response key** | `escrows` (array) |
| **Read-only** | Yes |
| **Empty state** | Returns `{"escrows": []}`. |
| **Not found** | N/A. |

### `GET /nexarail/escrow/v1/escrows/by-seller/{seller}`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/escrow/v1/escrows/by-seller/{seller}` |
| **Path param** | `seller` — seller address (string) |
| **Module** | Escrow |
| **Description** | Returns all escrows where the given address is the seller. |
| **Response key** | `escrows` (array) |
| **Read-only** | Yes |
| **Empty state** | Returns `{"escrows": []}`. |
| **Not found** | N/A. |

### `GET /nexarail/escrow/v1/escrows/by-merchant/{merchant}`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/escrow/v1/escrows/by-merchant/{merchant}` |
| **Path param** | `merchant` — merchant ID (string) |
| **Module** | Escrow |
| **Description** | Returns all escrows associated with a given merchant ID. |
| **Response key** | `escrows` (array) |
| **Read-only** | Yes |
| **Empty state** | Returns `{"escrows": []}`. |
| **Not found** | N/A. |

### `GET /nexarail/escrow/v1/escrow/exists/{id}`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/escrow/v1/escrow/exists/{id}` |
| **Path param** | `id` — escrow identifier (string) |
| **Module** | Escrow |
| **Description** | Convenience endpoint returning whether an escrow with the given ID exists in state. Does **not** return the escrow data itself — only a boolean. |
| **Response key** | `exists` (boolean) |
| **Read-only** | Yes |
| **Empty state** | Returns `{"exists": false}` when no escrow with that ID exists (never 404). |
| **Not found** | Never returns a 404 — always `{"exists": false}` for absent IDs. Rejects empty `id` with `escrow id required`. |

---

## Module: Payout

### `GET /nexarail/payout/v1/params`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/payout/v1/params` |
| **Module** | Payout |
| **Description** | Returns the current on-chain payout module parameters. |
| **Response key** | `params` |
| **Read-only** | Yes |
| **Empty state** | Always populated. |
| **Not found** | N/A. |

### `GET /nexarail/payout/v1/payouts`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/payout/v1/payouts` |
| **Module** | Payout |
| **Description** | Returns all individual payout records on the chain. |
| **Response key** | `payouts` (array) |
| **Read-only** | Yes |
| **Empty state** | Returns `{"payouts": []}`. |
| **Not found** | N/A. |

### `GET /nexarail/payout/v1/payout/{id}`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/payout/v1/payout/{id}` |
| **Path param** | `id` — payout identifier (string) |
| **Module** | Payout |
| **Description** | Returns a single payout record by its ID. |
| **Response key** | `payout` |
| **Read-only** | Yes |
| **Empty state** | N/A — returns 404 |
| **Not found** | Returns HTTP 404 with error `payout {id} not found`. Rejects empty `id` with `payout id required`. |

### `GET /nexarail/payout/v1/payout/exists/{id}`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/payout/v1/payout/exists/{id}` |
| **Path param** | `id` — payout identifier (string) |
| **Module** | Payout |
| **Description** | Convenience endpoint returning whether a payout with the given ID exists in state. Returns a boolean, not the payout data. Compare with `GET /payout/{id}` which returns 404 when absent. |
| **Response key** | `exists` (boolean) |
| **Read-only** | Yes |
| **Empty state** | Returns `{"exists": false}` when no payout with that ID exists (never 404). |
| **Not found** | Never returns a 404 — always `{"exists": false}` for absent IDs. Rejects empty `id` with `payout id required`. |

### `GET /nexarail/payout/v1/payouts/by-merchant/{merchant}`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/payout/v1/payouts/by-merchant/{merchant}` |
| **Path param** | `merchant` — merchant ID (string) |
| **Module** | Payout |
| **Description** | Returns all payouts associated with a given merchant. |
| **Response key** | `payouts` (array) |
| **Read-only** | Yes |
| **Empty state** | Returns `{"payouts": []}`. |
| **Not found** | N/A. |

### `GET /nexarail/payout/v1/payouts/by-recipient/{recipient}`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/payout/v1/payouts/by-recipient/{recipient}` |
| **Path param** | `recipient` — recipient address (string) |
| **Module** | Payout |
| **Description** | Returns all payouts where the given address is the recipient. |
| **Response key** | `payouts` (array) |
| **Read-only** | Yes |
| **Empty state** | Returns `{"payouts": []}`. |
| **Not found** | N/A. |

### `GET /nexarail/payout/v1/payouts/by-initiator/{initiator}`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/payout/v1/payouts/by-initiator/{initiator}` |
| **Path param** | `initiator` — initiator address (string) |
| **Module** | Payout |
| **Description** | Returns all payouts initiated by the given address. |
| **Response key** | `payouts` (array) |
| **Read-only** | Yes |
| **Empty state** | Returns `{"payouts": []}`. |
| **Not found** | N/A. |

### `GET /nexarail/payout/v1/batch-payout/{id}`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/payout/v1/batch-payout/{id}` |
| **Path param** | `id` — batch payout identifier (string) |
| **Module** | Payout |
| **Description** | Returns a single batch-payout record by its ID. |
| **Response key** | `batch_payout` |
| **Read-only** | Yes |
| **Empty state** | N/A — returns 404 |
| **Not found** | Returns HTTP 404 with error `batch payout {id} not found`. Rejects empty `id` with `batch payout id required`. |

### `GET /nexarail/payout/v1/batch-payouts`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/payout/v1/batch-payouts` |
| **Module** | Payout |
| **Description** | Returns all batch-payout records on the chain. |
| **Response key** | `batch_payouts` (array) |
| **Read-only** | Yes |
| **Empty state** | Returns `{"batch_payouts": []}`. |
| **Not found** | N/A. |

---

## Module: Treasury

### `GET /nexarail/treasury/v1/params`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/treasury/v1/params` |
| **Module** | Treasury |
| **Description** | Returns the current on-chain treasury module parameters. |
| **Response key** | `params` |
| **Read-only** | Yes |
| **Empty state** | Always populated. |
| **Not found** | N/A. |

### `GET /nexarail/treasury/v1/summary`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/treasury/v1/summary` |
| **Module** | Treasury |
| **Description** | Returns a computed summary of the treasury state: total counts of accounts, budgets, grants, and spend requests. This is a **derived** endpoint — it iterates all collections in the keeper. |
| **Response key** | Composed of: `total_accounts`, `total_budgets`, `total_grants`, `total_spend_requests` (all integers) |
| **Read-only** | Yes |
| **Empty state** | Returns all zeroes: `{"total_accounts":0,"total_budgets":0,"total_grants":0,"total_spend_requests":0}`. |
| **Not found** | N/A — always returns a response. |

### `GET /nexarail/treasury/v1/spend/{id}`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/treasury/v1/spend/{id}` |
| **Path param** | `id` — spend request identifier (string) |
| **Module** | Treasury |
| **Description** | Returns a single spend request by its ID. |
| **Response key** | `spend_request` |
| **Read-only** | Yes |
| **Empty state** | N/A — returns 404 |
| **Not found** | Returns HTTP 404 with error `spend request {id} not found`. Rejects empty `id` with `spend id required`. |

### `GET /nexarail/treasury/v1/spends`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/treasury/v1/spends` |
| **Module** | Treasury |
| **Description** | Returns all spend requests on the chain. |
| **Response key** | `spend_requests` (array) |
| **Read-only** | Yes |
| **Empty state** | Returns `{"spend_requests": []}`. |
| **Not found** | N/A. |

### `GET /nexarail/treasury/v1/account/{id}`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/treasury/v1/account/{id}` |
| **Path param** | `id` — treasury account identifier (string) |
| **Module** | Treasury |
| **Description** | Returns a single treasury account by its ID. |
| **Response key** | `treasury_account` |
| **Read-only** | Yes |
| **Empty state** | N/A — returns 404 |
| **Not found** | Returns HTTP 404 with error `treasury account {id} not found`. Rejects empty `id` with `account id required`. |

### `GET /nexarail/treasury/v1/accounts`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/treasury/v1/accounts` |
| **Module** | Treasury |
| **Description** | Returns all treasury accounts on the chain. |
| **Response key** | `treasury_accounts` (array) |
| **Read-only** | Yes |
| **Empty state** | Returns `{"treasury_accounts": []}`. |
| **Not found** | N/A. |

### `GET /nexarail/treasury/v1/budget/{id}`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/treasury/v1/budget/{id}` |
| **Path param** | `id` — budget identifier (string) |
| **Module** | Treasury |
| **Description** | Returns a single budget by its ID. |
| **Response key** | `budget` |
| **Read-only** | Yes |
| **Empty state** | N/A — returns 404 |
| **Not found** | Returns HTTP 404 with error `budget {id} not found`. Rejects empty `id` with `budget id required`. |

### `GET /nexarail/treasury/v1/budgets`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/treasury/v1/budgets` |
| **Module** | Treasury |
| **Description** | Returns all budgets on the chain. |
| **Response key** | `budgets` (array) |
| **Read-only** | Yes |
| **Empty state** | Returns `{"budgets": []}`. |
| **Not found** | N/A. |

### `GET /nexarail/treasury/v1/grant/{id}`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/treasury/v1/grant/{id}` |
| **Path param** | `id` — grant identifier (string) |
| **Module** | Treasury |
| **Description** | Returns a single grant by its ID. |
| **Response key** | `grant` |
| **Read-only** | Yes |
| **Empty state** | N/A — returns 404 |
| **Not found** | Returns HTTP 404 with error `grant {id} not found`. Rejects empty `id` with `grant id required`. |

### `GET /nexarail/treasury/v1/grants`

| Field | Value |
|-------|-------|
| **Method** | GET |
| **Path** | `/nexarail/treasury/v1/grants` |
| **Module** | Treasury |
| **Description** | Returns all grants on the chain. |
| **Response key** | `grants` (array) |
| **Read-only** | Yes |
| **Empty state** | Returns `{"grants": []}`. |
| **Not found** | N/A. |
