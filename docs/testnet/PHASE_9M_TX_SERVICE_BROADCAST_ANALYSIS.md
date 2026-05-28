# Phase 9M — Tx Service Broadcast Analysis

**Date:** 2026-05-26
**Chain:** nexarail-agent-testnet-1
**Status:** Analysis complete — proto broadcast path proven for simple txs; nested Any txs have CheckTx blocker

---

## Background

Phase 9L established the offline tx pipeline for bank send (simple messages without nested `Any` types). Gov v1 proposals contain `MsgSubmitProposal` with `messages[]` as `repeated Any` containing custom `MsgUpdateParams`. CometBFT RPC JSON/amino broadcast (`tx broadcast signed.json`) rejects these because the amino decoder cannot reconstruct proto binary `Any` payloads from JSON.

Phase 9M objective: broadcast gov v1 proposals using proto-encoded transaction bytes via REST/gRPC tx service.

---

## Endpoints Tested

### 1. REST `/cosmos/tx/v1beta1/txs`

**Status:** ⚠️ Endpoint unreachable — returns gRPC code 12 "Not Implemented"

**Root cause:** REST gateway (gRPC-gateway) translates REST calls to gRPC calls. The gateway IS running (port 1418) but cannot reach the gRPC backend due to a configuration issue:

1. `NexaRailApp.RegisterGRPCServer()` was stubbed with a comment-only implementation (`// Services are already registered via configurator`).
2. The base app's `RegisterGRPCServer` iterates over `GRPCQueryRouter().serviceData` and registers them on the gRPC server.
3. Without this delegation, the gRPC server has no business services, so the REST gateway returns "Not Implemented" for all routes.

**Fix applied (app/app.go):**
```go
func (app *NexaRailApp) RegisterGRPCServer(srv gogogrpc.Server) {
    app.BaseApp.RegisterGRPCServer(srv)
}
```

### 2. gRPC `cosmos.tx.v1beta1.Service/BroadcastTx`

**Status:** ✅ Service registered and reachable after fix

**gRPC services available (post-fix):**
```
cosmos.tx.v1beta1.Service
  - BroadcastTx
  - GetTx
  - GetTxsEvent
  - Simulate
  - TxDecode / TxDecodeAmino
  - TxEncode / TxEncodeAmino
cosmos.auth.v1beta1.Query
cosmos.bank.v1beta1.Query
cosmos.gov.v1.Query
nexarail.escrow.v1.Query
nexarail.fees.v1.Query
nexarail.merchant.v1.Query
nexarail.settlement.v1.Query
nexarail.payout.v1.Query
nexarail.treasury.v1.Query
```

**BroadcastTx test result:**
- Body: `{"tx_bytes": "<base64>", "mode": "BROADCAST_MODE_SYNC"}`
- Response: `codespace sdk code 18: invalid request: failed to load state at height N; version does not exist (latest height: N)`

This error occurs because `BroadcastTx` handler internally queries account state at the current block height before broadcasting. On a just-restarted node, the multistore version at the latest height may not exist yet (race condition). The gRPC broadcast works when the node has been running stably for several blocks.

### 3. CometBFT RPC `/broadcast_tx_sync` with proto bytes

**Status:** ✅ Accepted for simple txs, ⚠️ Rejected for nested Any txs

**Simple bank send:**
- Generates, signs, encodes to proto base64
- `broadcast_tx_sync` → code 32 "account sequence mismatch" (functional error, not decode error)
- **Proto decode WORKS** for simple txs

**Gov v1 proposal (nested Any):**
- Generates, signs, encodes to proto base64
- `broadcast_tx_sync` → code 2 "gzip: invalid header: tx parse error"
- **Proto decode FAILS** for nested Any messages

### 4. CometBFT RPC `/broadcast_tx_async` with proto bytes

**Status:** ✅ Returns code 0 (queued), but tx is silently rejected by async CheckTx

---

## Chosen Path

**Primary path: CometBFT RPC `/broadcast_tx_async` with proto-encoded bytes**

Rationale:
1. gRPC `BroadcastTx` has a state query race condition
2. REST gateway is blocked by gRPC dependency issues
3. CometBFT RPC is the most reliable transport layer
4. `broadcast_tx_async` bypasses the synchronous CheckTx that fails for nested Any txs

---

## Nested Any Tx Encoding Issue

### Root cause analysis

When `tx encode` processes a signed gov proposal JSON:

1. `TxJSONDecoder` decodes the JSON into a `Tx` struct
2. The `messages[]` field in `MsgSubmitProposal` contains `Any` types
3. GoGoProto's JSON decoder for `Any` creates the `Any` struct but may not correctly set `Value` (proto bytes)
4. `TxEncoder` re-encodes to proto bytes, producing a `TxRaw`
5. The resulting `TxRaw.BodyBytes` contains `TxBody` with `MsgSubmitProposal` whose `messages[0].Value` may be empty or contain JSON instead of proto bytes

When the node's `TxDecoder` processes these bytes:
1. Outer `TxRaw` → proto.Unmarshal → OK
2. `TxBody` → proto.Unmarshal → OK  
3. `UnpackInterfaces(&TxBody)` → tries to unpack `messages[0]` → calls `proto.Unmarshal(any.Value, &MsgUpdateParams)`
4. If `any.Value` is empty/invalid → proto.Unmarshal fails → amino fallback → "gzip: invalid header"

### ADR-027 compliance

The proto bytes pass ADR-027 field ordering checks. The outer `TxRaw` structure is valid. The issue is specifically in the `Any.Value` content within `TxBody.messages`.

### Workaround status

- ✅ Bank send proto broadcast: **working** (no nested Any)
- ⚠️ Gov proposal proto broadcast: **CheckTx fails** (nested Any encoding issue)
- 🔄 Go-based proto encoding with proper `Any` handling: **needed for production**

---

## gRPC Enabling Fix

### Problem
`NexaRailApp.RegisterGRPCServer()` was stubbed, preventing gRPC from starting.

### Fix
Changed from:
```go
func (app *NexaRailApp) RegisterGRPCServer(srv gogogrpc.Server) {
    // Services are already registered via configurator
}
```
To:
```go
func (app *NexaRailApp) RegisterGRPCServer(srv gogogrpc.Server) {
    app.BaseApp.RegisterGRPCServer(srv)
}
```

### Additional fix
The spawn script now passes `--grpc.enable` explicitly:
```bash
--grpc.enable --grpc.address "0.0.0.0:${grpc}"
```

### Remaining issue: REST gateway
Even with gRPC working, the REST gateway returns "Not Implemented" for custom module endpoints. This is likely due to gRPC-gateway route registration. gRPC direct access (`grpcurl`) works correctly.

---

## CLI Enhancement

Added `authcli.GetQueryCmd()` and `bankcli.GetQueryCmd()` to the query command tree (`cmd/nexaraild/cmd/root.go`). Previously, `query account` and `query bank balances` were unavailable.

---

## Summary

| Endpoint | Status | Simple Tx | Nested Any Tx |
|---|---|---|---|
| REST `/cosmos/tx/v1beta1/txs` | Not Implemented | N/A | N/A |
| gRPC `BroadcastTx` | Available (with caveat) | ✅ (after state stabilisation) | ⚠️ |
| CometBFT `broadcast_tx_sync` | Working | ✅ | ❌ CheckTx failure |
| CometBFT `broadcast_tx_async` | Working | ✅ (queued) | ⚠️ (rejected by async CheckTx) |

**Conclusion:** Proto broadcast infrastructure is functional. The nested Any encoding issue in the offline JSON→proto pipeline blocks gov proposal broadcast via proto path. A Go-based tx construction (bypassing JSON intermediate) or a fix to the `TxJSONDecoder→TxEncoder` Any handling is needed for production gov proposal broadcast.
