# NexaRail REST Readback — Limitations

This document describes the limitations and scope constraints of the NexaRail custom REST endpoints registered in `NexaRailApp.RegisterRuntimeReadbackRoutes`.

---

## 1. Tx Broadcast / Write Operations Not Covered

The custom REST readback endpoints are **strictly read-only** (GET-only). There are **no custom POST/PUT/DELETE endpoints** for:

- Creating merchants
- Posting settlements
- Creating or releasing escrows
- Initiating or processing payouts
- Submitting treasury spend requests, grants, or budget allocations

**To perform any of the above writes**, use the generic Cosmos SDK transaction broadcasting flow:

1. Build and sign a `cosmos.tx.v1beta1.Tx` containing the appropriate NexaRail `Msg*` message.
2. Broadcast via the standard `POST /cosmos/tx/v1beta1/txs` endpoint.
3. The NexaRail module message handlers will process the state transition on delivery.

> **The custom REST layer is a readback convenience, not a full API surface.**

---

## 2. Readback-Only Scope

All endpoints documented in `REST_READBACK_ROUTES.md` perform **state reads only**:

- They query an **uncached SDK context** constructed from the latest committed block header (`app.BaseApp.NewUncachedContext(false, tmproto.Header{})`).
- No state writes occur.
- No mempool or pending-tx inspection is performed.
- The responses reflect the last committed block, not the current block being executed.

**Use case:** Dashboard UIs, monitoring tools, and CLI scripts that need fast, JSON-serialised state access without a gRPC dependency.

---

## 3. gRPC Remains Source of Truth

If a discrepancy arises between a REST readback response and the equivalent gRPC query (`QueryClient`), the **gRPC response should be treated as authoritative**.

Reasons:

| Concern | Detail |
|---------|--------|
| **Consistency** | gRPC is the primary query interface consumed by the Cosmos SDK and IBC. |
| **Testing coverage** | gRPC endpoints have higher test coverage in keeper tests. |
| **Code generation** | gRPC service definitions (`QueryServer` interfaces) are code-generated from `proto` files and serve as the canonical schema. |
| **Serialisation** | REST endpoints use JSON serialisation in-app (via `json.Marshal` on keeper return values); gRPC uses protobuf binary encoding with rigorous type checking. |

---

## 4. Controlled-Testnet Status

The NexaRail chain is currently a **controlled testnet**. There is **no mainnet** deployment.

Implications:

- All data is ephemeral and may be reset without notice.
- The REST readback endpoints are **not rate-limited** and **not authenticated** — they rely on network-layer access control (private RPC endpoint, firewall, etc.).
- There are **no SLAs or uptime guarantees** for the REST servers.
- Do not rely on these endpoints for production financial or legal use.

---

## 5. Payout Exists Endpoint Is a Convenience Wrapper

`GET /nexarail/payout/v1/payout/exists/{id}` returns `{"exists": true}` or `{"exists": false}` without ever returning a 4xx or 5xx status for a missing record.

Functionally, the callers could achieve the same result by:

1. Calling `GET /nexarail/payout/v1/payout/{id}` 
2. Treating a **404 response** as `exists=false` and a **200 response** as `exists=true`

The dedicated `exists` endpoint exists to:
- Avoid parse/bandwidth overhead of deserialising a full payout object.
- Signal intent explicitly in the URL path.
- Distinguish "record absent" from "transient server error" without exception-handling logic.

> **For consistency:** `GET /nexarail/escrow/v1/escrow/exists/{id}` follows the same pattern.

---

## 6. Escrow Exists Endpoint Is a Convenience Wrapper

Same design as the payout `exists` endpoint above.

`GET /nexarail/escrow/v1/escrow/exists/{id}` returns a boolean only, and the detail endpoint `GET /nexarail/escrow/v1/escrow/{id}` can serve the same purpose by 404-checking.

> See section 5 for the full rationale — the design is identical.

---

## 7. No Pagination

All list endpoints (`.../merchants`, `.../settlements`, `.../escrows`, `.../payouts`, `.../batch-payouts`, `.../spends`, `.../accounts`, `.../budgets`, `.../grants`) return the **full set** of records from the keeper's in-memory / store iteration.

There is **no pagination, no limit, no offset parameter**.

Implications:
- On a large testnet with thousands of records, response payloads can become large.
- Clients should not assume the response fits in a single HTTP response without truncation.
- If the chain has very high record counts, query latency will increase linearly.

---

## 8. No Caching

Every request rebuilds a fresh SDK `Context` and reads directly from the KV store. There is no:

- In-memory response cache
- ETag / If-None-Match support
- CDN or reverse-proxy layer in the default deployment

Clients that poll frequently should implement their own client-side caching / deduplication (e.g. store the last-known block height and skip re-querying if the height hasn't changed).

---

## 9. No gRPC-Web Proxy Layer

These REST endpoints are served directly by the Cosmos SDK `runtime.ServeMux` alongside the standard Cosmos REST handlers. There is **no gRPC-Web gateway** in front of them.

If you require a protobuf-native or browser-friendly gRPC experience, use a separate gRPC-Web proxy (e.g. `grpcweb` or Envoy) pointed at the chain's gRPC port.

---

## Summary of Design Decisions

| Decision | Reason |
|----------|--------|
| GET-only | Narrow scope — readback convenience, not full API |
| No POST/PUT/DELETE | Use generic Cosmos `POST /cosmos/tx/v1beta1/txs` |
| JSON from keeper values | Simplicity — no proto marshalling in the REST handler |
| Uncacheable context | Always sees latest committed state |
| gRPC < REST for truth | gRPC is the canonical SDK query interface |
| Exists endpoints separate | Convenience — avoid 404 handling for simple checks |
| No pagination | Acceptable for controlled testnet scale |
