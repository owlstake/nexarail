# Performance Baselines — NexaRail

**Date:** 2026-05-26
**Phase:** 8C

---

## Benchmarks

Run with:
```bash
go test ./app -bench=. -benchmem -count=3
```

### Current Baselines

| Benchmark | Operation | Notes |
|---|---|---|
| BenchmarkFeeSplitCalculation | Fee split read (3 uint32) | Simple params read — should be ~ns/op |
| BenchmarkSettlementParamsRead | Settlement params read | Includes nested struct — should be ~ns/op |
| BenchmarkEscrowParamsRead | Escrow params read | Simple params read |
| BenchmarkTreasuryParamsRead | Treasury params read | Params with nested fields |
| BenchmarkPayoutParamsRead | Payout params read | Simple params read |
| BenchmarkMerchantParamsRead | Merchant params read | Params with sdk.Coin field |
| BenchmarkAllParamsRead | All 6 params reads | Full params sweep |

### Expected Performance Characteristics

| Operation | Expected Scale | Reason |
|---|---|---|
| Params reads | < 1 μs | In-memory KV store via IAVL |
| Params writes | < 10 μs | IAVL tree update + disk write |
| Fee split calculation | < 100 ns | Pure arithmetic on uint32 |
| Listing 100 items | < 1 ms | IAVL range scan with protobuf decode |
| Index lookup | < 100 μs | Prefix scan on KV store |

### What We're NOT Benchmarking Yet

- Transaction throughput (requires multi-node consensus)
- Block production time (requires running chain)
- P2P message latency (requires networked validators)
- IAVL tree compaction (requires sustained state growth)
- gRPC endpoint latency (requires running server)

These are deferred to network-level testing during controlled testnet operations.

## How to Collect Baselines

```bash
# Run benchmarks
go test ./app -bench=. -benchmem -count=3 | tee benchmarks.txt

# Or via the suite script
./scripts/testnet/run-hardening-suite.sh
```
