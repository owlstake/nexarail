# CLI E2E Testing — NexaRail

**Date:** 2026-05-26
**Phase:** 8A

---

## Smoke Test Script

`scripts/testnet/cli-e2e-smoke-test.sh`

Tests CLI query commands against a live node:

| Category | Tests |
|---|---|
| Pre-flight | Binary exists, RPC reachable |
| RPC Status | Height > 0, chain ID |
| Module Params | fees, merchant, settlement, escrow, payout, treasury |
| Bank | bank total query |
| Key Ops | add, show, list with test keyring |
| Debug | debug-p2p-config, debug-live-flags, debug-module-summary |

## How to Run

```bash
# Against a running local node:
./scripts/testnet/cli-e2e-smoke-test.sh

# Custom binary and endpoints:
BINARY=./build/nexaraild RPC=http://127.0.0.1:26657 GRPC=127.0.0.1:9090 \
  ./scripts/testnet/cli-e2e-smoke-test.sh
```

## Expected Output (all passing)

```
╔══════════════════════════════════════════╗
║  NexaRail CLI E2E Smoke Test            ║
╚══════════════════════════════════════════╝

--- Pre-flight ---
  ✅ Binary exists
  ✅ RPC reachable

--- RPC Status ---
  Height: 65  Chain: nexarail-testnet-1
  ✅ RPC status returns height > 0

--- Module Params Queries ---
  ✅ query fees params
  ✅ query merchant params
  ✅ query settlement params
  ✅ query escrow params
  ✅ query payout params
  ✅ query treasury params

--- Key Operations ---
  ✅ keys add
  ✅ keys show returns address
  ✅ keys list shows key

--- Debug Commands ---
  ✅ debug-p2p-config
  ✅ debug live-flags
  ✅ debug module-summary

╔══════════════════════════════════════════╗
║  Results: 15 passed, 0 failed           ║
╚══════════════════════════════════════════╝
```

## Known Limitations

1. Module param queries require gRPC client reachable on port 9090 — may fail if gRPC port is blocked/conflicted
2. Module param queries use `--grpc-addr` and `--grpc-insecure` flags — needs a running node with gRPC enabled
3. Key operations use `--keyring-backend test` — testnet/devnet only
4. Debug commands read genesis from `--home` directory — no running node required

## Test Coverage

| Module | CLI Query | Smoke Test |
|---|---|---|
| fees | params, fee-split | ✅ params |
| merchant | params, merchant, merchants | ✅ params |
| settlement | params, settlement, list, by-merchant, by-payer | ✅ params |
| escrow | params, escrow, list, by-buyer, by-seller, by-merchant, exists | ✅ params |
| payout | params, payout, list, by-merchant, by-recipient, by-initiator, batch, batches, exists | ✅ params |
| treasury | params, account, accounts, budget, budgets, grant, grants, spend, spends, summary | ✅ params |
