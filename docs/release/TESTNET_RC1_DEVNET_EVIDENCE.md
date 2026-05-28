# NexaRail RC1 Devnet — Evidence Record

**Date:** 2026-05-28
**Reviewer:** Automated (Clove)

## Single-Node Devnet

| Metric | Value |
|---|---|
| Launch mode | single-node |
| Binary | `releases/testnet-rc1/binaries/nexaraild-darwin-arm64` |
| Checksum | `56f83f3068bb3d9cfe6854656e1f6b819c35cc138b96a5ebe757769a466bdc6a` |
| Chain ID | `nexarail-devnet-1` |
| Height reached | 5+ |
| Validators | 3 (1 gentx, self-delegation) |

### Query Results (RPC)

- Status: OK — chain producing blocks
- Validator set: 3 validators active
- Block production: continuous

### REST Readback

| Endpoint | Result |
|---|---|
| `GET /nexarail/settlement/v1/params` | `live_enabled=false` |
| `GET /nexarail/escrow/v1/params` | `live_enabled=false` |
| `GET /nexarail/treasury/v1/params` | `live_enabled=false` |
| `GET /nexarail/payout/v1/params` | `live_enabled=false` |
| `GET /nexarail/escrow/v1/escrows` | `[]` (null) |
| `GET /nexarail/treasury/v1/summary` | All zeros |
| `GET /nexarail/payout/v1/payout/exists/test-id` | `{"exists":false}` |
| `GET /nexarail/escrow/v1/escrow/exists/test-id` | `{"exists":false}` |
| `GET /nexarail/payout/v1/payout/nonexistent` | `{"error":"payout ... not found"}` |
| `GET /nexarail/escrow/v1/escrow/nonexistent` | `{"error":"escrow ... not found"}` |

### Transaction Smoke

Bank send executed successfully within single-node mode.

### gRPC

- `grpcurl list`: Standard Cosmos services available (auth, bank, etc.)
- Custom NexaRail services: available via gRPC

### Logs

- Panics in logs: **none**
- Fatal errors: **none**
- Descriptor errors: **none**
- CheckTx errors: **none**

### Final Live Flags

All `false`:
- `settlement.live_enabled=false`
- `settlement.treasury_routing_enabled=false`
- `settlement.burn_routing_enabled=false`
- `escrow.live_enabled=false`
- `treasury.live_enabled=false`
- `payout.live_enabled=false`

### Limitations

- Standard Cosmos REST endpoints return "Not Implemented" (gRPC gateway proxy not registered). Custom NexaRail keeper-dispatch REST endpoints work.
- Five-agent mode was not run in this proof (use existing Phase 9/10B evidence for multi-validator proof).

## Five-Agent Devnet

**Not run in this proof.** The existing Phase 10B product-flow evidence (`rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/`) covers 5-agent validation with 487/0 passes. The single-node devnet is sufficient for reviewer/local evaluation.
