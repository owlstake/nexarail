# Nexarail REST Examples

This directory contains read-only shell scripts that query the Nexarail blockchain REST API endpoints. They require **no private keys** and are safe to run against any Nexarail node.

## Prerequisites

- `curl` — for HTTP requests
- `jq` (optional) — for pretty-printed JSON output; scripts degrade gracefully without it

## Usage

All scripts accept the `API_BASE_URL` environment variable, which defaults to:

```
http://localhost:1317
```

This is the default REST endpoint exposed by the Nexarail RC1 devnet when running locally.

```bash
# Default (local devnet)
./check_live_flags.sh

# Custom endpoint
API_BASE_URL=https://your-node:1317 ./query_merchant.sh
```

## Scripts

| Script | Description |
|--------|-------------|
| `check_live_flags.sh` | Queries all live-enabled flags across modules. All should return `false` on a fresh devnet. |
| `query_merchant.sh` | Merchant module: params, list, and detail lookup. |
| `query_settlement.sh` | Settlement module: params, list, detail (not-found), and filtered queries (empty). |
| `query_escrow.sh` | Escrow module: params, list, detail (not-found), filtered queries (empty), existence check. |
| `query_treasury.sh` | Treasury module: params, summary, and all sub-resources (account, budget, grant, spend) with detail + list. |
| `query_payout.sh` | Payout module: params, list, detail (not-found), filtered queries (empty), existence check, batch operations. |

## Devnet Assumptions

These scripts assume RC1 devnet is running locally with:

- Cosmos SDK REST API at `http://localhost:1317`
- Nexarail modules registered: `merchant`, `settlement`, `escrow`, `treasury`, `payout`
- An empty/unseeded chain state (so filtered queries return empty arrays, and detail lookups by non-existent IDs return not-found)

## Notes

- All scripts handle connection errors gracefully — they print the error and continue to the next query.
- Each query is clearly sectioned with headers for readable output.
- JSON formatting uses `jq` if available, otherwise raw `curl` output is shown.
