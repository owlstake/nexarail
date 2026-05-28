# API Smoke Testing — NexaRail

**Date:** 2026-05-26
**Phase:** 8A

---

## Smoke Test Script

`scripts/testnet/api-smoke-test.sh`

Tests RPC, REST, and gRPC endpoints against a live node:

| Category | Tests |
|---|---|
| CometBFT RPC | /status, /net_info, /validators |
| REST (Standard Cosmos) | /cosmos/base/tendermint/v1beta1/node_info, /cosmos/bank/v1beta1/params |
| REST (Custom Modules) | /nexarail/{module}/v1/params (all 6 modules) |
| REST (List Queries) | /nexarail/{module}/v1/{module}s (merchant, settlement, escrow, payout) |
| REST (Treasury) | /nexarail/treasury/v1/summary |
| gRPC Reflection | Service discovery via grpcurl (all 6 modules) |
| Live Flags | Verify all 6 flags = false via REST |

## How to Run

```bash
# Against a running local node with REST API enabled:
./scripts/testnet/api-smoke-test.sh

# Custom endpoints:
RPC=http://127.0.0.1:26657 REST=http://127.0.0.1:1317 GRPC=127.0.0.1:9090 \
  ./scripts/testnet/api-smoke-test.sh
```

## REST Endpoints (Phase 8A)

| Module | Endpoint | Status |
|---|---|---|
| Fees | `GET /nexarail/fees/v1/params` | ✅ Implemented |
| Fees | `GET /nexarail/fees/v1/fee_split` | ✅ Implemented |
| Merchant | `GET /nexarail/merchant/v1/params` | ✅ Implemented |
| Merchant | `GET /nexarail/merchant/v1/merchants` | ✅ Implemented |
| Merchant | `GET /nexarail/merchant/v1/merchant/{owner}` | ✅ Implemented |
| Settlement | `GET /nexarail/settlement/v1/params` | ✅ Implemented |
| Settlement | `GET /nexarail/settlement/v1/settlements` | ✅ Implemented |
| Settlement | `GET /nexarail/settlement/v1/settlement/{id}` | ✅ Implemented |
| Escrow | `GET /nexarail/escrow/v1/params` | ✅ Implemented |
| Escrow | `GET /nexarail/escrow/v1/escrows` | ✅ Implemented |
| Escrow | `GET /nexarail/escrow/v1/escrow/{id}` | ✅ Implemented |
| Payout | `GET /nexarail/payout/v1/params` | ✅ Implemented |
| Payout | `GET /nexarail/payout/v1/payouts` | ✅ Implemented |
| Payout | `GET /nexarail/payout/v1/payout/{id}` | ✅ Implemented |
| Treasury | `GET /nexarail/treasury/v1/params` | ✅ Implemented |
| Treasury | `GET /nexarail/treasury/v1/accounts` | ✅ Implemented |
| Treasury | `GET /nexarail/treasury/v1/summary` | ✅ Implemented |

**Total: 17 new REST endpoints across 6 modules.**

## gRPC Services

| Service | Status |
|---|---|
| `nexarail.fees.v1.Query` | ✅ Registered |
| `nexarail.merchant.v1.Query` | ✅ Registered |
| `nexarail.settlement.v1.Query` | ✅ Registered |
| `nexarail.escrow.v1.Query` | ✅ Registered |
| `nexarail.payout.v1.Query` | ✅ Registered |
| `nexarail.treasury.v1.Query` | ✅ Registered |

## Preconditions

- Node must be running with gRPC on port 9090
- REST API must be enabled in `app.toml` (`[api] enable = true`)
- `grpcurl` required for gRPC reflection tests (install: `brew install grpcurl`)
- Port 9090 must not be shadowed by SSH tunnels (known macOS issue)
