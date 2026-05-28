# Phase 9V - Persistence-Safe Restart Investigation Plan

**Date:** 2026-05-27  
**Chain:** `nexarail-agent-testnet-1`  
**Scope:** local validator-agent restart behavior only  
**Status:** Investigation plan

## Purpose

Phase 9V investigates the Phase 9U `--reuse-data` restart failure and determines whether it is:

- local agent script or environment specific;
- CometBFT/application restart configuration related;
- BaseApp proposal handling related;
- safe to classify as unsupported for local rehearsals only; or
- a blocker for persistent testnet launch.

This phase does not add product modules, change economics, enable live flags by default, claim mainnet launch, claim NXRL availability, or claim external decentralisation from local agent validators.

## Phase 9U Restart Symptoms

Phase 9U completed a 1-hour clean-spawn soak successfully:

- Duration: `3602s`
- Start height: `12`
- Final height: `685`
- Height delta: `673`
- Average block time: `5.35s`
- Peer range: `4-4`
- Validator set range: `5-5`
- Query result: `425 pass / 0 fail / 0 skip`
- Runtime bank-send tx: `9F85BD88F936818D6A910BEE640DDAF3B1D437F993519BE2FACCCF3D0E0E52A5`
- Clean-soak panics: `0`

The reuse-data restart failed after the clean soak:

- agents restarted;
- post-restart queries passed `85 / 0`;
- peer count was `4`;
- validator set count was `5`;
- block production did not advance beyond height `695`;
- recovered `PrepareProposal` and `ProcessProposal` nil-pointer panics appeared at height `696`.

Phase 9U evidence:

```text
rehearsals/validator-agents/long-soak/evidence/20260527T102106Z/
```

## Hypotheses

| ID | Hypothesis | Test Signal |
|---|---|---|
| A | Local agent wrapper starts nodes differently on reuse-data restart | Direct `nexaraild start --home ...` restart works while wrapper restart fails |
| B | Rosetta or gRPC-web restarts with different config | `app.toml` or CLI flags differ after reuse-data restart |
| C | BaseApp consensus params are nil after process restart | Panic occurs in proposal handling with no custom proposal handler, and fixing BaseApp param store restores block production |
| D | Custom `PrepareProposal` / `ProcessProposal` handler is unsafe | Code search finds custom handler and matrix isolates handler behavior |
| E | Ante handler or tx decoder is nil after restart | Panic correlates with tx proposal processing and direct restart also fails |
| F | Module manager or keeper wiring is nil after restart | Queries fail or module params become unavailable after restart |
| G | Reuse-data is safe only in standard direct node mode | Direct restart passes, wrapper reuse remains unsupported |
| H | Persistent restart is a real runtime blocker | Wrapper and direct restart both fail after minimal clean stop/restart |

## Test Matrix

| Case | Scenario | Required Evidence |
|---|---|---|
| A | Single-validator clean start, clean stop, reuse-data restart | block advance, query result, panic scan |
| B | 3-agent clean start, clean stop, reuse-data restart | block advance, query result, panic scan, peer count, validator set |
| C | 5-agent clean start, clean stop, reuse-data restart | block advance, query result, panic scan, peer count, validator set |
| D | 5-agent immediate restart at height 20 | height before/after, query result, panic scan |
| E | 5-agent restart after soak | soak evidence, restart height, post-restart block advance, query result |
| F | Restart one node only while the other 4 continue | network continuity, restarted node catch-up, query result |
| G | Restart all 5 nodes simultaneously by direct start | direct-start proof, block advance, query result, post-restart bank tx |
| H | Restart all 5 nodes sequentially | per-node restart proof, final block advance, query result |
| Direct | Single-node standard direct restart with no agent wrapper start path | direct start, clean SIGTERM stop, direct restart, block advance |

## Success Criteria

The restart issue is considered fixed if:

- block production advances after restart;
- query readback works after restart;
- validator set remains stable;
- no `PrepareProposal` or `ProcessProposal` nil-pointer panics recur;
- a runtime bank tx is included after restart in at least one 5-agent fixed path;
- the direct restart path works.

## Failure Criteria

The issue remains unresolved if:

- block production stalls after restart;
- proposal nil-pointer panics recur;
- validator set drops unexpectedly;
- queries fail after restart;
- Rosetta/gRPC-web config differs between clean start and restart without explanation;
- direct node restart fails under standard conditions.

## Risk Classification

| Classification | Meaning |
|---|---|
| Fixed | Local agent reuse-data and direct restart both produce blocks after restart |
| Wrapper-specific | Direct restart works but wrapper reuse-data remains unsafe |
| Local rehearsal unsupported | Local agent reuse-data remains unsafe and must not be used for proof runs |
| Production-like restart deferred | More evidence is required on Linux/Docker/direct-node persistent deployment |
| Persistent launch blocker | Standard direct restart fails after minimal clean stop/restart |

## Disclaimer

The local validator-agent testnet is a single-machine rehearsal. It does not prove external validator participation, independent validator operations, mainnet launch, NXRL availability, or external decentralisation.
