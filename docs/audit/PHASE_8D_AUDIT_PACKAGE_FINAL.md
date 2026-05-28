# Phase 8D — Audit Package Final

**Date:** 2026-05-26
**Phase:** 8D
**Status:** Ready for external review

---

## Repo Overview

| Field | Value |
|---|---|
| Repository | github.com/Bookings-cpu/nexarail |
| Language | Go 1.22+ |
| SDK | Cosmos SDK v0.47.17 |
| Consensus | CometBFT v0.37.18 |
| License | Proprietary |

## Chain Architecture

NexaRail is a sovereign Layer 1 blockchain for controlled testnet evaluation of railway settlement and payments. It uses the standard Cosmos SDK module architecture with 16 standard modules and 6 custom modules. External validator distribution is not yet live.

```
cmd/nexaraild/       — Binary entry point and CLI commands
app/                  — Application wiring, encoding, genesis
x/fees/               — Fee split parameters and invariants
x/merchant/           — Merchant registration and rebates
x/settlement/         — Payment settlement with fee routing
x/escrow/             — Payment escrow custody
x/payout/             — Automated payouts
x/treasury/           — Protocol treasury and spend execution
x/common/             — Shared utilities (REST gateway helpers)
proto/                — Protobuf definitions (hand-written types)
scripts/              — Build, testnet, and hardening scripts
docs/                 — Design, security, audit, testnet docs
rehearsals/           — Docker rehearsal evidence
```

## Custom Module Summary

| Module | Purpose | Live Flag | Store Key | gRPC Service |
|---|---|---|---|---|
| x/fees | Fee split params (60/20/20) | None | fees | nexarail.fees.v1.Query |
| x/merchant | Merchant registration + rebates | None | merchant | nexarail.merchant.v1.Query |
| x/settlement | Payment settlement + fee routing | 3 flags | settlement | nexarail.settlement.v1.Query |
| x/escrow | Payment escrow custody | 1 flag | escrow | nexarail.escrow.v1.Query |
| x/payout | Automated payouts | 1 flag | payout | nexarail.payout.v1.Query |
| x/treasury | Protocol treasury + spend | 1 flag | treasury | nexarail.treasury.v1.Query |

## Live Funds Flags

All 6 flags default to `false`. Enablement requires on-chain governance.

| Module | Flag | Default |
|---|---|---|
| settlement | `live_enabled` | false |
| settlement | `treasury_routing_enabled` | false |
| settlement | `burn_routing_enabled` | false |
| escrow | `live_enabled` | false |
| treasury | `live_enabled` | false |
| payout | `live_enabled` | false |

## Module Accounts and Permissions

| Account | Purpose | Permissions |
|---|---|---|
| `nexarail_escrow` | Escrow custody pool | None |
| `nexarail_treasury` | Treasury fund pool | None |
| `nexarail_fee_router` | Fee routing intermediary | None |
| `nexarail_burner` | Burn routing destination | Burner |

## REST/gRPC/CLI Status

| Interface | Status | Details |
|---|---|---|
| CometBFT RPC | ✅ Operational | Port 26657 |
| gRPC Query | ✅ All 6 services registered | Port 9090 |
| REST Gateway | ✅ 17 endpoints | Port 1317 |
| CLI Queries | ✅ All 6 modules | `nexaraild query <module>` |
| Debug Commands | ✅ 3 commands | debug-p2p-config, debug-live-flags, debug-module-summary |

## Testing Status

| Metric | Value |
|---|---|
| Test packages | 15 |
| Total tests | ~465 |
| Integration tests | 7 |
| Benchmarks | 7 |
| CLI command coverage | 5 tests |
| Live flag coverage | All 6 flags tested |
| Genesis validation | All 6 modules |
| Docker rehearsal | 3 validators, height >20, peers ≥2 |
| Evidence | `rehearsals/testnet-1/docker/evidence/` |

## Known Limitations

1. Types are hand-written Go structs, not protobuf-generated — REST gateway handlers manually wired
2. Rosetta API not functional for custom modules
3. gRPC-Gateway route registration uses manual pattern construction
4. Docker Desktop on macOS unstable for multi-validator P2P (requires Linux hosts)
5. Validator distribution deferred
6. IBC, bridge, stablecoin registry deferred
7. State sync not tested at scale
8. No formal third-party security audit completed

## Deferred Features

- Validator distribution (design complete)
- Stablecoin registry
- Bridge (IBC or custom)
- Fee router / BeginBlock routing
- Advanced treasury features (multi-sig, vesting)

## High-Risk Files (Audit Focus)

| File | Risk | Reason |
|---|---|---|
| `x/settlement/keeper/keeper.go` | High | Live fund routing, multi-bank calls |
| `x/settlement/keeper/msg_server.go` | High | Settlement creation, fee calculation |
| `x/escrow/keeper/keeper.go` | Medium | Custody lifecycle, state transitions |
| `x/treasury/keeper/keeper.go` | Medium | Budget tracking, spend approval |
| `x/payout/keeper/keeper.go` | Medium | Payout execution, batch logic |
| `app/app.go` | High | Module wiring, keeper initialisation |

## Audit Focus Areas

1. **Settlement fee routing**: Three bank transfers per settlement — verify atomicity
2. **Burn mechanics**: Burn share calculation, dust handling, burn enabled flag
3. **Escrow custody**: State transitions, double-release prevention
4. **Treasury spend limits**: Budget enforcement, overspend prevention
5. **Live flag gates**: Confirmation that all 6 flags block live transfers
6. **Governance authority**: Params update gating, authority address verification
7. **Module account isolation**: Cross-module balance leakage prevention

## How to Run Tests

```bash
git clone https://github.com/Bookings-cpu/nexarail.git
cd nexarail
go mod tidy && go mod verify
go build ./...
go vet ./...
go test ./... -count=1
go test ./... -cover
go test ./app -bench=. -benchmem
```

## How to Run Docker Rehearsal

```bash
make build
./scripts/testnet/run-docker-3-validator-rehearsal.sh
./scripts/testnet/query-docker-3-validator-rehearsal.sh
./scripts/testnet/collect-docker-rehearsal-evidence.sh
```

## Evidence Directory

```
rehearsals/testnet-1/docker/evidence/
├── 20260526T095021Z/   — Phase 6J.2 evidence (height 6+, 3 validators)
├── 20260525T222450Z/   — Phase 6L evidence
└── 20260525T222140Z/   — Phase 6K evidence
```
