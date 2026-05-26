# NexaRail Testnet Explorer & RPC Plan

**Document:** docs/testnet/EXPLORER_AND_RPC.md
**Version:** 1.0
**Date:** 2026-05-25

## Explorer Options

| Option | Type | Effort | Recommended |
|---|---|---|---|
| Ping.pub | Self-hosted web explorer | Low | ✅ |
| Big Dipper | Self-hosted full explorer | Medium | ✅ |
| Cosmos Directory | Public listing | Low | Optional |
| Custom dashboard | Lightweight API + HTML | Medium | Future |

### Recommended: Ping.pub (Initial)

```bash
# Self-host Ping.pub explorer pointed at testnet RPC
# Deploy via Docker or static build
# Configure with RPC + REST endpoints
```

URL: `https://explorer.testnet.nexarail.network` (TBD)

### Custom Dashboard (Future)

Lightweight API-driven dashboard showing:
- Block height, block time
- Validator set and voting power
- Transaction volume
- Live flag status per module
- Treasury balance
- Burn total

## RPC Endpoints

| Endpoint | URL (proposed) | Protocol |
|---|---|---|
| Tendermint RPC | `https://rpc.testnet.nexarail.network` | JSON-RPC over HTTP/WS |
| Cosmos REST | `https://rest.testnet.nexarail.network` | REST / LCD |
| gRPC | `https://grpc.testnet.nexarail.network` | gRPC-web |

Core team provides the initial endpoints. Community validators encouraged to provide additional endpoints for redundancy.

### RPC Configuration (config.toml)

```toml
[rpc]
laddr = "tcp://0.0.0.0:26657"
cors_allowed_origins = ["*"]
max_body_bytes = 1000000
max_header_bytes = 1048576

[api]
enable = true
address = "tcp://0.0.0.0:1317"
```

### gRPC Configuration (app.toml)

```toml
[grpc]
enable = true
address = "0.0.0.0:9090"
```

## Indexing Plan

Enable transaction indexing for explorer:

```toml
[tx_index]
indexer = "kv"
```

Events to index (in addition to defaults):
```
settlement_created
settlement_status_updated
escrow_created
escrow_funded
escrow_released
treasury_spend_executed
payout_paid
```

## Public Endpoint Rate Limits

| Endpoint | Rate Limit |
|---|---|
| RPC (all methods) | 100 req/s per IP |
| REST | 50 req/s per IP |
| gRPC | 50 req/s per IP |
| WebSocket | 5 connections per IP |

Implement via Nginx reverse proxy or Cloudflare.

## Monitoring

Endpoints monitored for:
- Uptime (target: 95%+)
- Response latency (target: < 2s p95)
- Error rate (target: < 1%)

Monitoring via UptimeRobot, Grafana, or custom health check.

## Uptime Expectations

Testnet endpoints are best-effort. No SLA. Validators may restart nodes for upgrades. Core team endpoints aim for 95% uptime during active testnet phases.
