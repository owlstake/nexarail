# Phase 10B.2 Governance UX Plan

**Date:** 2026-05-28  
**Scope:** Operator UX plan for governance-controlled product actions  
**Boundary:** Planning only. No product modules, economics, live defaults, or launch claims changed.

## Current Workflow

Phase 10B product-flow rehearsal proves authority-controlled actions through governance proposal JSON plus validator votes:

- live-flag enable/disable for settlement, escrow, treasury, and payout;
- merchant status changes;
- settlement treasury/burn routing flags;
- treasury account and budget creation;
- treasury spend approval/execution;
- payout mark-paid;
- final live-flag restoration.

The harness currently performs the hard parts:

- creates proposal JSON;
- generates and signs offline txs;
- broadcasts through CometBFT;
- collects validator votes;
- waits for proposal final state;
- reads back state/balances;
- restores live flags false.

This is reliable for local rehearsal but too script-heavy for a human operator.

## Proposal JSON Templates

Template families now used by the harness:

| Template family | Product action | Current path |
|---|---|---|
| Settlement params | live, treasury routing, burn routing, restore false | `settlement_params_msg` in `scripts/testnet/run-product-flow-rehearsal.sh` |
| Escrow params | escrow live enable/disable | `escrow_params_msg` |
| Treasury params | treasury live enable/disable | `treasury_params_msg` |
| Payout params | payout live enable/disable | `payout_params_msg` |
| Merchant authority | set merchant inactive/active | inline `MsgSetMerchantStatus` proposal JSON |
| Treasury authority | create account, create budget, approve/execute spend | inline treasury proposal JSON |
| Payout authority | mark payout paid | inline `MsgMarkPayoutPaid` proposal JSON |

## Signing And Sequencing Assumptions

- Local rehearsal uses test keyrings under validator-agent homes.
- Proposal submission is generated and signed offline with the current proposer account number and sequence.
- Validator votes are submitted serially and waited through CometBFT tx inclusion.
- Proposal success is accepted only after final status is `PROPOSAL_STATUS_PASSED`.
- Product effects are verified through state/balance readback after proposal pass.

## Desired Operator Commands

Future CLI wrappers should preserve governance control while removing brittle manual JSON editing:

| Desired command | Purpose |
|---|---|
| `nexaraild tx product-gov settlement-live [true|false]` | Build/submit settlement live flag proposal |
| `nexaraild tx product-gov settlement-routing --treasury --burn` | Build/submit routing flag proposal |
| `nexaraild tx product-gov escrow-live [true|false]` | Build/submit escrow live flag proposal |
| `nexaraild tx product-gov treasury-live [true|false]` | Build/submit treasury live flag proposal |
| `nexaraild tx product-gov payout-live [true|false]` | Build/submit payout live flag proposal |
| `nexaraild tx product-gov merchant-status OWNER active|inactive` | Build/submit merchant status proposal |
| `nexaraild tx product-gov treasury-account ...` | Build/submit treasury account proposal |
| `nexaraild tx product-gov treasury-budget ...` | Build/submit treasury budget proposal |
| `nexaraild tx product-gov execute-spend SPEND_ID` | Build/submit spend approval/execution proposal |
| `nexaraild tx product-gov mark-payout-paid PAYOUT_ID REF` | Build/submit payout paid proposal |

## Risks

- Wrappers must not bypass governance authority.
- Wrappers must not change live defaults.
- Wrappers must not hide proposal deposits, voting periods, or final status checks.
- Wrappers must preserve offline signing paths for production-grade operator use.
- Wrappers must make testnet-only/no-mainnet context clear in generated summaries.

## Phase 10B.2 Decision

Do not add risky shortcuts in this phase. The immediate hardening is evidence indexing: `governance-product-evidence.json` and `governance-product-evidence.md` now connect proposal IDs, submit txs, vote txs, final status, expected state changes, and state/balance readback.

## Verification Evidence

- Final all-suite evidence: `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/`.
- Governance index result: proposal count `22`, all final states `PROPOSAL_STATUS_PASSED`.
- Proof model: indirect proof via proposal pass plus state/balance readback.
- Final live flags: all false after restoration proposals.

## Recommended Future Work

Build a small, test-covered `product-gov` CLI helper layer after REST/query parity work. It should generate valid proposal JSON, optionally submit/vote in local testnet mode, and always print the exact proposal ID, expected state change, and readback command.
