# NexaRail RC1 Local Devnet Dashboard

A lightweight, read-only, single-page dashboard for the NexaRail RC1 devnet.

## Purpose

This dashboard provides a local web UI to inspect the state of a **local NexaRail devnet** running on your machine. It is strictly for development and debugging during the RC1 release cycle.

## Quick Start

```bash
# Serve the dashboard
cd /Users/bradleyjohnston/workspace/nexarail/examples/dashboard
python3 -m http.server 8088
```

Open [http://localhost:8088](http://localhost:8088) in your browser.

The dashboard expects the NexaRail API (REST) and RPC endpoints to be accessible at:

| Service    | Default URL                |
|------------|----------------------------|
| REST API   | `http://localhost:1317`    |
| RPC        | `http://localhost:26657`   |

You can override the REST API URL in the dashboard UI if your devnet uses a different port.

## What It Shows

- **Node Status** — Sync info, block height, node ID
- **Live Flags** — Whether settlement, escrow, treasury, and payout live modes are enabled (all `false` on fresh devnet)
- **Module Parameters** — Cosmos SDK module params (nexarail, bank, staking, etc.)
- **Treasury Summary** — Active accounts, budgets, grants, spend requests
- **Merchant / Settlement / Escrow / Payout Lists** — Registered entities with details

## Warnings

⚠️ **This is NOT a public blockchain explorer.**
⚠️ **This is NOT connected to mainnet.**
⚠️ **This is for local devnet use only.**

- No wallet integration
- No transaction signing
- No private keys
- No token sales or price data
- No real funds, no economic value

All live-mode flags are **disabled by default**. This dashboard is a read-only diagnostic tool.

## Dependencies

Zero. No frameworks, no build step, no npm packages. Vanilla HTML/JS/CSS served over `python3 -m http.server`.

## Files

| File          | Purpose                           |
|---------------|-----------------------------------|
| `index.html`  | Main page structure               |
| `styles.css`  | Dark-themed, responsive styling   |
| `app.js`      | Dashboard logic and API queries   |
| `README.md`   | This file                         |
