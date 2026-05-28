# NexaRail Network Litepaper

**Version:** 1.0
**Date:** 2026-05-27
**Chain:** NexaRail Network
**Framework:** Cosmos SDK v0.47.17 + CometBFT v0.37.18
**Native Coin:** NXRL (base denom: `unxrl`, 1 NXRL = 1,000,000 unxrl)
**Address prefix:** `nxr`

---

## 1. Status Disclaimer

**Please read carefully.** This litepaper describes a network under active development.

- **Mainnet is not live.** NexaRail has no public mainnet. The network described in this document is in testnet preparation.
- **Controlled testnet preparation.** The current testnet environment (`nexarail-agent-testnet-1`) is a controlled agent testnet. A public testnet (`nexarail-testnet-1`) is planned but not yet launched.
- **Agent runtime readiness has advanced.** The local 5-agent testnet has passed clean-spawn query/readback, governance lifecycle, a 60-minute soak, runtime bank transaction inclusion, a restart matrix, and a full local product-flow rehearsal with 469 checks passing. This is local agent-testnet evidence only.
- **No token sale.** NXRL has not been offered for sale through any mechanism — no ICO, IEO, IDO, private sale, or public sale. There is no way to purchase NXRL. Any claim to the contrary is fraudulent.
- **Testnet tokens have no monetary value.** Tokens on the testnet exist solely for testing purposes. They cannot be exchanged, traded, or transferred for value.
- **Live-funds modules disabled by default.** All modules capable of moving tokens have their `LiveEnabled` flags set to `false` by default. These flags require governance approval to activate, and there is no expectation that they will be enabled on testnet.
- **External validator onboarding is pending.** The current validator set consists of autonomous agent validators operated by the development team. This does not represent external decentralisation.
- **Agent validators do not represent external decentralisation.** The current agent-based validator set is a testing mechanism and should not be interpreted as a decentralised validator cohort.
- **No investment.** Participation in any NexaRail testnet is not an investment. No financial returns are promised, expected, or implied.
- **Legal review pending.** Formal independent legal review has not been completed.
- **External security audit pending.** A formal third-party security audit has not been completed.

---

## 2. Executive Summary

NexaRail is a sovereign Layer 1 blockchain built on the Cosmos SDK and CometBFT consensus engine, designed to serve as payment and settlement infrastructure. It targets a set of real-world financial workflows that remain fragmented, slow, or trust-dependent in existing systems.

The network provides purpose-built modules for merchant payment processing, settlement with programmable fee routing, escrow custody, automated payouts, and treasury management. All fund-moving functionality is gated behind governance-controlled flags that default to disabled — live movement of tokens is not active on any running network.

The native coin is NXRL, with a base denom of `unxrl`. The address prefix is `nxr`.

Development follows a progressive decentralisation path: from the current agent-based testnet, through external validator onboarding, a controlled public testnet, external security and legal review, and — only after all reviews are complete — a mainnet candidate.

As of Phase 10B.1, the local agent-testnet runtime has advanced materially: the 5-agent environment has passed a 60-minute soak, a restart matrix after a consensus-param store restart fix, and a full product-flow rehearsal covering merchant onboarding, settlement, escrow, treasury, payout, safety checks, and final live-flag readback. External validators remain pending, and this evidence does not claim external decentralisation.

---

## 3. Problem Statement

### Fragmented merchant payment infrastructure

Merchants accepting payments across multiple channels face a fragmented landscape of payment processors, settlement timelines, fee structures, and reconciliation requirements. Each channel introduces its own settlement cadence, dispute process, and reporting surface.

### Settlement delays

Payment settlement in traditional and crypto-adjacent systems takes hours to days. Funds remain in transit, earning no yield and creating operational friction for businesses that need predictable cash flow.

### Escrow trust issues

Escrow arrangements typically require a trusted third party to hold and release funds. This introduces counterparty risk, manual oversight, and settlement latency. Programmatic escrow on public infrastructure can eliminate the trust requirement but needs clear enforcement mechanisms.

### Payout and treasury opacity

Automated payouts to multiple recipients (affiliates, partners, contractors, team members) are often managed through bespoke scripts, manual transfers, or third-party payout services — each with its own trust model, fee structure, and audit trail. Treasuries managing protocol funds need transparent controls: budgets, grant milestones, spend approval workflows, and execution audit trails.

### Lack of programmable settlement rails

General-purpose blockchains can support payment logic through smart contracts, but the programming overhead, gas costs, and contract security risks create barriers for merchant-focused payment infrastructure. A purpose-built chain with native payment modules can expose these capabilities through deterministic, auditable, governance-controlled module logic rather than general-purpose contract code.

---

## 4. Vision

NexaRail aims to become a **payment and settlement infrastructure chain** — a sovereign L1 where payment flows, escrow arrangements, payout schedules, and treasury controls are first-class protocol primitives rather than application-layer afterthoughts.

The design targets:

- **Merchant-aware blockchain.** Native modules for merchant registration, fee parameters, settlement routing, and rebate structures, exposed through Cosmos SDK keeper APIs and governance-controlled parameters.
- **Governance-controlled live funds.** All fund-moving capabilities are gated behind on-chain governance flags. No single party can authorise token movement without passing a governance proposal.
- **Transparent treasury and payout flows.** Treasury module accounts, budget allocations, grant milestones, and spend execution are all on-chain operations with full audit trails. Payouts are deterministic and governance-authorised.
- **Validator-secured network.** Consensus and block production are secured by a CometBFT validator set. The target model moves from current agent validators to an external validator cohort, then to a permissioned public set, and ultimately toward progressive decentralisation.

NexaRail does not aim to compete with general-purpose smart contract platforms. It targets a narrower vertical: payment and settlement infrastructure where protocol-level guarantees — deterministic fee splits, governance-gated fund movement, module-level auditability — matter more than general programmability.

---

## 5. Network Overview

| Parameter | Value |
|---|---|
| **Chain** | NexaRail Network |
| **Framework** | Cosmos SDK v0.47.17 + CometBFT v0.37.18 |
| **Coin / Ticker** | NXRL |
| **Base denom** | `unxrl` |
| **Display precision** | 1 NXRL = 1,000,000 unxrl |
| **Address prefix** | `nxr` |
| **Binary** | `nexaraild` |
| **Language** | Go 1.22+ |
| **Testnet chain ID (agent)** | `nexarail-agent-testnet-1` |
| **Testnet chain ID (planned)** | `nexarail-testnet-1` |
| **Devnet chain ID** | `nexarail-devnet-1` |

### Networking

- CometBFT RPC: port 26657 (default)
- Cosmos SDK REST API: port 1317 (default)
- gRPC: port 9090 (default)
- P2P: port 26656 (default)

### Standard SDK Modules

All standard Cosmos SDK v0.47.17 modules are wired: `auth`, `bank`, `staking`, `slashing`, `gov`, `distribution`, `mint`, `params`, `crisis`, `upgrade`, `evidence`, `feegrant`, `authz`, `capability`, `vesting`, `genutil`.

### Custom NexaRail Modules

Six purpose-built modules: `x/fees`, `x/merchant`, `x/settlement`, `x/escrow`, `x/payout`, `x/treasury`.

---

## 6. Core Modules

### x/fees

**Purpose:** Defines and manages fee split parameters for the network. Default fee split is 60/20/20 (validator rewards / treasury reserve / burn). The module stores fee parameters as governance-controlled KV state.

**Current status:** Implemented. Metadata-only — no coin routing. Parameter changes require a `MsgUpdateParams` governance proposal.

**Live funds enabled by default:** No (policy parameters only — no fund movement capability in this module).

---

### x/merchant

**Purpose:** Merchant registration and rebate tier management. Merchants register on-chain with profile metadata, category, and rebate tier. The module tracks merchant status, fee rebate eligibility, and registration parameters.

**Current status:** Implemented. Full lifecycle (register, update, deactivate, reactivate) with governance-controlled parameters for registration deposit and rebate tiers.

**Live funds enabled by default:** N/A (registration metadata only — no fund movement).

---

### x/settlement

**Purpose:** Payment settlement with programmable fee routing. Records settlement metadata, calculates fee splits, manages settlement status transitions (pending, confirmed, failed). Supports three routing flags: `LiveEnabled` (merchant-net transfers), `TreasuryRoutingEnabled` (treasury share), `BurnRoutingEnabled` (burn share).

**Current status:** Implemented. All three routing flags exist and default to `false`. Live transfer tests passing.

**Live funds enabled by default:** No. Three separate governance flags are all `false`:
- `LiveEnabled` — default `false`
- `TreasuryRoutingEnabled` — default `false`
- `BurnRoutingEnabled` — default `false`

---

### x/escrow

**Purpose:** Payment escrow custody lifecycle. Supports creation, funding, release, refund, and dispute resolution. Funds move through the escrow module account only when `LiveEnabled` is `true`.

**Current status:** Implemented. Metadata-only lifecycle always available. Live custody logic implemented and tested but gated behind `LiveEnabled` flag.

**Live funds enabled by default:** No — `LiveEnabled` defaults to `false`.

---

### x/payout

**Purpose:** Automated payout execution. Records payout instructions, supports approval workflows, manages payout status transitions.

**Current status:** Implemented. Metadata-only lifecycle always available. Live disbursement logic implemented and tested but gated behind `LiveEnabled` flag.

**Live funds enabled by default:** No — `LiveEnabled` defaults to `false`.

---

### x/treasury

**Purpose:** Protocol treasury management. Manages treasury accounts, budget allocations, grant milestones, and spend request workflows. Supports budget tracking, milestone completion tracking, and spend execution.

**Current status:** Implemented. Metadata-only lifecycle always available. Live spend execution implemented and tested but gated behind `LiveEnabled` flag.

**Live funds enabled by default:** No — `LiveEnabled` defaults to `false`.

---

## 7. Live Funds Safety Model

The live funds safety model is designed to prevent accidental or premature fund movement on any running network.

### Default state: all flags false

Every module capable of moving tokens has a `LiveEnabled` (or equivalent) boolean flag that defaults to `false`. When `false`, the module operates in metadata-only mode: it records lifecycle state transitions, keeps audit logs, enforces business rules, but never initiates bank sends, module account transfers, or burn operations.

### Governance-controlled enablement

Each flag can only be changed through an on-chain governance proposal (`MsgUpdateParams`) with a voting period, deposit, and quorum. No single key or authority can enable live fund movement.

### Flag inventory

| Module | Flag | Default | Effect when `true` |
|---|---|---|---|
| x/escrow | `LiveEnabled` | `false` | Escrow custody: buyer funds locked in escrow module account; release sends to seller; refund returns to buyer |
| x/treasury | `LiveEnabled` | `false` | Spend execution: treasury module account transfers to recipients |
| x/payout | `LiveEnabled` | `false` | Payout execution: treasury-to-recipient transfers |
| x/settlement | `LiveEnabled` | `false` | Merchant-net transfer: payer sends coins to merchant |
| x/settlement | `TreasuryRoutingEnabled` | `false` | Treasury share routing to module account (depends on `LiveEnabled`) |
| x/settlement | `BurnRoutingEnabled` | `false` | Burn share: supply reduction via `BurnCoins` (depends on `LiveEnabled` and `TreasuryRoutingEnabled`) |

### Module accounts

The following module accounts would participate in live fund movement when enabled:

- **`escrow`** — holds buyer funds during escrow lifecycle
- **`treasury`** — holds protocol treasury reserves
- **`fee_collector`** — standard Cosmos SDK fee collection
- **`fee_router`** — temporary holding during fee splitting (if implemented)
- **Burn** — implemented via `bank.BurnCoins` (supply reduction)

All module account addresses are added to the bank module's blocked recipients list to prevent direct deposits outside approved message paths.

### No live funds by default

To be explicit: **no live funds can move on any NexaRail network without a governance proposal passing first.** Testnet tokens have no monetary value. Mainnet does not exist. Live fund flags are disabled by default.

---

## 8. Validator and Consensus Model

### Consensus engine

NexaRail uses CometBFT v0.37.18 (a fork of Tendermint) for Byzantine Fault Tolerant consensus. Block production requires >2/3 validator voting power to sign each block. The validator set is defined in genesis and managed through staking and governance.

### Current validator set: autonomous agent testnet

The current running network (`nexarail-agent-testnet-1`) uses autonomous agent validators operated by the development team. These agents have:
- Produced blocks with multi-validator consensus
- Passed full query/readback across status, validators, balances, accounts, module params, and live flags
- Executed bank transfers with inclusion code `0`
- Executed governance proposals with final state readback
- Completed a 60-minute local soak with stable peers and validator set
- Passed a restart matrix covering clean stop/restart, one-node restart, all-node restart, and post-soak restart recovery
- Maintained peer connectivity

**Important:** The agent validator set does not represent external decentralisation. It is a testing mechanism.

### External validator onboarding: pending

External validator onboarding (Phase B of the development roadmap) is designed but not yet executed. The process involves:
1. Controlled application and review
2. Gentx collection and validation
3. Genesis assembly and signing ceremony
4. Coordinated launch

### Target validator cohort

| Cohort | Size | Status |
|---|---|---|
| Current (agent) | 5 agents | Running |
| External (target) | 3 minimum, 5 preferred, 7 strong | Pending |
| Public testnet | TBD | Planned |

### Decentralisation note

Progressive decentralisation is the stated path, but no external validators have been onboarded as of this writing. The current network is development-operated. External validation does not yet exist. Claims about the network being "decentralised" would be inaccurate.

---

## 9. Governance

### Governance framework

NexaRail uses the standard Cosmos SDK `gov` module (v1 proposal pathway) for on-chain governance. Governance is the sole authority for:

- Parameter changes via `MsgUpdateParams` for each custom module
- Enabling/disabling live fund flags
- Software upgrade proposals
- Text proposals (non-binding signalling)

### Current status

Governance transactions (submit proposal, deposit, vote, pass) have been executed at the transaction and event level on the agent testnet. The full governance lifecycle works end-to-end.

Phase 9T validated the escrow live-flag lifecycle with state readback: proposal `1` enabled `escrow.live_enabled`, proposal `2` disabled it, and final live flags returned to `false`. Broader public/external testnet validation remains pending until external validators and gentxs exist.

### Governance and live flags

Live fund flags cannot be changed by any entity other than governance. There is no backdoor, no admin key, and no emergency override that bypasses governance for parameter changes. (Emergency stop or circuit breaker mechanisms, if implemented in future, would be separate from the governance model.)

---

## 10. Current Technical Status

### Module implementation

- **Six custom modules** in production-ready state:
  - `x/fees`, `x/merchant`, `x/settlement`, `x/escrow`, `x/payout`, `x/treasury`
- Each module has: keeper, MsgServer, QueryServer, CLI, proto definitions, and app wiring
- **Sixteen standard Cosmos SDK modules** wired and functional

### API surfaces

- REST API (Cosmos SDK LCD)
- gRPC (Cosmos SDK gRPC server)
- CometBFT RPC
- CLI (`nexaraild` binary)

### Tests

- Approximately 500+ tests across all custom module packages and app integration tests
- Tests include: unit tests, keeper tests, integration/app tests, invariant tests, fuzz tests (where applicable)
- All tests pass on `go test ./...`

### Agent testnet

- 5-agent validator set producing blocks
- Full local query/readback passed: Phase 9T `85 pass / 0 fail / 0 skip`
- 60-minute local soak passed: Phase 9U `3602s`, height `12` to `685`, query total `425 pass / 0 fail / 0 skip`
- Bank transaction confirmed with inclusion code `0`
- Governance lifecycle executed with final state readback
- Restart matrix passed after Phase 9V consensus-param store fix, including a post-60-minute-soak restart from height `695` to `698`
- Peer connectivity maintained

### Tooling

- `nexaraild` binary — full node and CLI
- Devnet initialisation (`make init-devnet`, `make start-devnet`)
- Docker rehearsal environment
- Genesis coordination tooling (gentx collection, validation, genesis assembly)
- Governance transaction builder (`tools/govtxbuilder`)
- Store inspector (`tools/storeinspector`)

### Limitations to be clear about

- **Not externally decentralised.** Validator set is development-operated agents.
- **Not audited.** No formal third-party security audit.
- **Not legally reviewed.** No formal independent legal review.
- **Public/external testnet state validation pending.** Local agent query/readback evidence has passed; external-validator and public-endpoint validation are still pending.
- **No bridge or stablecoin registry.** These are deferred.
- **No token sale.** NXRL has not been offered for sale.

---

## 11. Roadmap

### Phase A: Controlled agent testnet hardening (current phase)

- Autonomous agent validators producing blocks
- Module integration validation
- Governance lifecycle validation
- State query and readback hardening
- Invariant and stress testing
- This litepaper

### Phase B: External validator cohort

- Controlled validator application process (design complete — `docs/testnet/`)
- Gentx collection and validation
- Genesis assembly and coordinator runbook
- External validator launch
- Agent validators phased out or reduced

### Phase C: Controlled public testnet

- Public RPC, REST, and gRPC endpoints
- Faucet for testnet tokens
- Public block explorer
- Discord/Telegram support channels
- Bug bounty programme
- Documentation and onboarding guides

### Phase D: External security and legal review

- Third-party security audit by a recognised blockchain security firm
- Independent legal review covering token status, regulatory classification, and jurisdictional risk
- Findings remediation and re-audit

### Phase E: Mainnet candidate (only after all reviews)

- Only after Phases A–D are complete
- Only after security audit findings are resolved
- Only after legal review confirms an acceptable risk profile
- No mainnet launch date has been set. No commitment to mainnet has been made.

---

## 12. Limitations

This section is a consolidated list of limitations that apply to NexaRail in its current state.

1. **Not mainnet.** NexaRail has no public mainnet. All references to the network refer to testnet or devnet environments.
2. **Not externally decentralised.** The validator set is currently development-operated agents. External validators have not been onboarded.
3. **No external audit.** A formal third-party security audit has not been completed. Internal threat models and audit preparation packages exist but are not a substitute for external review.
4. **No token sale.** NXRL has not been offered for sale through any mechanism. There is no way to purchase NXRL. Testnet tokens have zero monetary value.
5. **Validator distribution deferred.** A validator distribution design exists but has not been implemented. Current staking follows standard Cosmos SDK staking with a single delegator on each validator.
6. **Bridge and stablecoin registry deferred.** IBC integration and stablecoin registry are on the deferred list. The network currently operates as an isolated sovereign chain.
7. **Live funds disabled by default.** All live fund movement flags default to `false`. No funds move without governance approval.
8. **Legal review pending.** Formal independent legal review has not been completed.
9. **Roadmap is provisional.** All phases, dates, and targets are subject to change. No timeline commitments are made.

---

## 13. Security and Audit Posture

### Threat register

A comprehensive threat register exists at `docs/security/THREAT_REGISTER.md` covering:

- Module-level threats for each custom module
- Cross-module fund flow threats
- Governance attack vectors
- Validator compromise scenarios
- Network-level threats (eclipse, sybil, DDoS)

Additional threat models exist for specific subsystems: settlement live transfers (`docs/security/SETTLEMENT_LIVE_THREAT_MODEL.md`), treasury/fee routing (`docs/security/SETTLEMENT_TREASURY_FEE_THREAT_MODEL.md`), burn routing (`docs/security/SETTLEMENT_BURN_THREAT_MODEL.md`), and validator distribution (`docs/security/VALIDATOR_DISTRIBUTION_THREAT_MODEL.md`).

### Audit package

An audit preparation package is available at `docs/audit/` containing:

- Audit package index (`AUDIT_PACKAGE_INDEX.md`)
- Final audit package (`PHASE_8D_AUDIT_PACKAGE_FINAL.md`)
- Audit-specific security review (`PHASE_8D_SECURITY_REVIEW.md`)
- Live funds audit preparation (`PHASE_5_AUDIT_PREP.md`)
- Phase 3 threat review (`PHASE_3_THREAT_REVIEW.md`)

### Predeployment checks

Predeployment release checklists exist at `docs/release/` covering:

- Controlled testnet release checklist (`CONTROLLED_TESTNET_RELEASE_CHECKLIST.md`)
- Pre-launch sign-off process (`PRE_LAUNCH_SIGN_OFF.md`)
- Pre-launch freeze checklist (`docs/testnet/PRE_LAUNCH_FREEZE_CHECKLIST.md`)

### Release and change-control

A formal change-control policy exists at `docs/release/CHANGE_CONTROL_POLICY.md`, with a release process runbook (`docs/release/RELEASE_PROCESS_RUNBOOK.md`), release tagging and checksums guide (`docs/release/RELEASE_TAGGING_AND_CHECKSUMS.md`), and reproducible build notes (`docs/release/REPRODUCIBLE_BUILD_NOTES.md`).

### External audit still required

None of the above replaces a formal third-party security audit. An external audit by a recognised blockchain security firm is required before any consideration of mainnet. Current documentation supports that future audit — it does not substitute for it.

---

## 14. Conclusion

NexaRail is a Cosmos SDK sovereign L1 being built for payment and settlement infrastructure. The network has six purpose-built modules for merchant payments, settlement, escrow, payouts, and treasury management, all behind governance-controlled live-funds flags that default to disabled.

The current state is an agent testnet with approximately 500+ passing tests, multi-validator block production, validated query/readback, a 60-minute local soak, runtime tx inclusion, restart recovery, validated governance workflows, and a local full product-flow rehearsal that passed 469 checks. External validator onboarding, public testnet, security audit, and legal review are all ahead.

**The honest summary:** advanced technical readiness for a testnet-stage project. Not mainnet. Not externally decentralised. Not a token sale. Not an investment. Live funds are disabled. If you are a technical validator operator or ecosystem reviewer, the infrastructure is available for evaluation. If you are looking for a token to buy, an investment opportunity, or a live mainnet, this is not that.

---

**NexaRail Network — Payment Infrastructure L1. In development.**
