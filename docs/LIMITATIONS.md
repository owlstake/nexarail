# NexaRail v1 Limitations

This document lists all known limitations of the current NexaRail devnet (Phase 3/4). These are design choices, not bugs. Each limitation is a candidate for future phases.

## Metadata-Only Modules

The following modules record state and lifecycle events but do NOT move coins or hold funds.

**Phase 5B note (2026-05-25):** Module account infrastructure (`nexarail_escrow`, `nexarail_treasury`, `nexarail_fee_router`) is registered at genesis with nil permissions. These accounts are blocked from user sends but no live fund movement is active yet.

**Phase 5C/5D/5E note (2026-05-25):** Live fund movement now exists in `x/escrow` (custody), `x/treasury` (spend execution), and `x/payout` (payout transfers), each behind a per-module `live_enabled` governance parameter that defaults to **false**. With defaults unchanged, all business modules behave as metadata-only.

**Phase 5F.6 update (2026-05-25):** `x/settlement` now supports burn-share routing behind `BurnRoutingEnabled` (default false). When all three flags are enabled, burn share is routed via `nexarail_burner` + `bank.BurnCoins`, permanently reducing NXRL supply. Validator share remains metadata-only.

| Module | Limitation |
|---|---|
| x/settlement | Live merchant-net transfer behind `live_enabled`; treasury-share routing behind `treasury_routing_enabled`; burn-share routing via `nexarail_burner` + `bank.BurnCoins` behind `burn_routing_enabled` (all default false). Validator share remains metadata-only. |
| x/escrow | Live custody available behind `live_enabled` (default false). With the default, escrow is metadata-only and no module account locks coins. |
| x/payout | Payout records track payment instructions and approvals. Live payout transfers from `nexarail_treasury` are available behind `live_enabled` (default false). With the default, mark-paid only records status and moves no funds. Live **batch** payout execution is not implemented (per-payout only). |
| x/treasury | Live spend execution available behind `live_enabled` (default false). With the default, treasury is metadata-only and nominal balances do not move funds. |

## No Live Custody

- No module account holds user funds in escrow.
- No treasury vault stores protocol reserves.
- No payout module disburses coins.
- All coin movement is handled by the standard Cosmos `bank` module for standard transfers.

## No Live Fee Routing

- `x/fees` defines fee split parameters (60% validators, 20% treasury, 20% burn) but does NOT intercept or route actual transaction fees.
- Fee routing requires modification of the `FeeCollector` module account and integration with the bank module for coin splitting.

## No Stablecoin Registry

- The devnet uses a single native denomination (`unxrl`).
- No multi-asset or stablecoin support exists.
- All settlement amounts use `unxrl` denom.

## No Bridge

- No IBC integration.
- No cross-chain bridge.
- No wrapped assets.

## No Mainnet

- Chain ID: `nexarail-devnet-1` (development only)
- No mainnet deployment configuration
- No validator diversity requirements
- No production-grade key management
- No hardware security module integration

## No Audit

- No third-party security audit has been performed.
- No formal verification of the custom module code.
- No economic audit of the fee model.

## No Legal Approval

- No regulatory review.
- No legal opinion on the token classification.
- No compliance framework for merchant KYC/AML.

## Operational Limitations

- Devnet runs on a single machine with 3 local validators.
- No geographic distribution of validators.
- No sentry node architecture.
- No monitoring or alerting infrastructure.
- No backup or disaster recovery procedures.

## Known Technical Limitations

- Custom module types use manual proto registrations (no protobuf code generation).
- gRPC service descriptors are hand-coded (not generated from `.proto` files).
- No Cosmovisor upgrade handler registered.
- No IBC module wired.
- No CosmWasm or EVM support.

## Deferred (No Implementation Timeline)

| Feature | Reason |
|---|---|
| Validator share distribution (60% of net fee) | Requires Cosmos SDK x/distribution specialist review. Design in `docs/design/VALIDATOR_DISTRIBUTION_DESIGN.md`. |
| Fee router (nexarail_fee_router) | Module account registered but unused. Deferred until BeginBlock fee routing is implemented. |
| BeginBlock fee routing | Inter-block settlement fee routing from fee_collector to distribution/treasury/burn not implemented. |
| Automated refunds for live settlements | Live-settled records blocked from status changes. Refunds require manual off-chain coordination. |
| Multi-denom settlements | Single denom (unxrl) only. |
| Batch payout live execution | Per-payout only. Batch execution is metadata-only. |
| Stablecoin registry | New module. Not designed. |
| Bridge / IBC | New module. Not designed. |

## Not Yet Ready

- Public mainnet (requires testnet, audits, legal review)
- External security audit (pre-mainnet requirement)
- Legal/regulatory review (pre-mainnet requirement)

## Plan for Resolution

| Limitation | Status |
|---|---|
| Live escrow custody | ✅ Phase 5C (gated behind LiveEnabled=false) |
| Live treasury transfers | ✅ Phase 5D (gated behind LiveEnabled=false) |
| Live payout transfers | ✅ Phase 5E (gated behind LiveEnabled=false) |
| Live settlement merchant transfer | ✅ Phase 5F.2 (gated behind LiveEnabled=false) |
| Live settlement treasury routing | ✅ Phase 5F.4 (gated behind TreasuryRoutingEnabled=false) |
| Live settlement burn routing | ✅ Phase 5F.6 (gated behind BurnRoutingEnabled=false) |
| Validator distribution | ⏸️ Deferred (Phase 5F.7 design complete) |
| Fee router / BeginBlock routing | ⏸️ Deferred (no design) |
| Stablecoin registry | ⏸️ Future |
| Bridge / IBC | ⏸️ Future |
| Public testnet | 🔜 Phase 6 |
| External audit | 🔜 Pre-mainnet |
| Mainnet launch | 🔜 Post-audit |
