# Phase 9V - Restart Panic Analysis

**Date:** 2026-05-27  
**Source evidence:** `rehearsals/validator-agents/long-soak/evidence/20260527T102106Z/restart-reuse-data/`  
**Scope:** Phase 9U reuse-data restart failure

## Summary

The Phase 9U reuse-data restart failure was not a query failure. After restart, all five agents responded to readback and returned `85 pass / 0 fail`, but consensus could not commit height `696`.

Every validator-agent log contained recovered `ProcessProposal` nil-pointer panics at height `696`. Each agent also logged recovered `PrepareProposal` nil-pointer panics when selected as proposer in later rounds. Consensus then timed out repeatedly at `RoundStepPrecommitWait`.

The full Go stack trace was not emitted by the current logger output. The available evidence is the complete panic context captured in the agent logs and restart panic scans.

## Affected Agents

| Agent | ProcessProposal panics | PrepareProposal panics | Precommit wait timeouts | Affected height |
|---|---:|---:|---:|---:|
| alpha | 25 | 5 | 24 | 696 |
| bravo | 25 | 5 | 24 | 696 |
| charlie | 25 | 5 | 24 | 696 |
| delta | 25 | 5 | 24 | 696 |
| echo | 25 | 5 | 24 | 696 |

All five nodes were affected. This was not isolated to a single proposer. Proposer responsibility rotated by round, and the node selected as proposer logged `PrepareProposal` before the network rejected/stalled in `ProcessProposal`.

## Panic Pattern

Representative Phase 9U restart lines:

```text
ERR panic recovered in ProcessProposal hash=7C1962B93391D9E48BCC1E46A610961D73F009C3A82CEDBAB45E5FA6B4B82E22 height=696 module=server panic="runtime error: invalid memory address or nil pointer dereference"
INF Timed out dur=1000 height=696 module=consensus round=0 step=RoundStepPrecommitWait
ERR panic recovered in PrepareProposal height=696 module=server panic="runtime error: invalid memory address or nil pointer dereference"
ERR panic recovered in ProcessProposal hash=C9944CE6097F77E36EB09643535654DD10148063F620AF2736E2ED55EE5AB0AC height=696 module=server panic="runtime error: invalid memory address or nil pointer dereference"
```

The repeated hash sequence across agents indicates every node was processing the same proposal rounds at the same stalled height.

## Consensus Context

Observed behavior:

- restart reached existing committed height `695`;
- APIs and RPC status remained reachable;
- validator set remained `5`;
- peer count remained `4`;
- first post-restart consensus height was `696`;
- `ProcessProposal` panicked on every node;
- `PrepareProposal` panicked on the active proposer;
- consensus repeatedly timed out at `RoundStepPrecommitWait`.

This points at an application-level ABCI proposal path dependency being nil after process restart, not at P2P connectivity, validator-set loss, or REST query routing.

## Code Inspection

Phase 9V code inspection found:

- NexaRail does not register custom `SetPrepareProposal` or `SetProcessProposal` handlers.
- BaseApp default proposal handlers are being used.
- Rosetta is disabled in agent `app.toml`.
- gRPC-web is disabled in agent `app.toml`.
- The relevant custom code is the BaseApp consensus parameter store wiring:

```go
bApp.SetParamStore(...)
```

Before Phase 9V, this store was an in-memory `paramStore` whose `Get` method returned `nil, nil` when `ps.cp == nil`. `InitChain` populated it on a fresh chain, but a process restart rebuilds this in-memory object before the application calls `LoadLatestVersion`. On a reuse-data restart there is no new `InitChain`, so BaseApp proposal handling can receive nil consensus params.

## Diagnosis

Best diagnosis:

```text
BaseApp proposal handling was reading nil consensus params after process restart because NexaRail's custom in-memory consensus-param store was not seeded on reuse-data startup.
```

This explains why:

- clean-spawn runs worked: `InitChain` calls `Set` and populated the in-memory store;
- query readback still worked: module keepers and REST routes were available;
- restart stalled at the first new height: proposal handlers needed consensus params for height `696`;
- all nodes were affected: every restarted process had a fresh nil in-memory store;
- Rosetta/gRPC-web were not the direct cause: they remained disabled and the panic occurred in proposal handling.

## Phase 9V Fix Target

The minimal fix is to make the BaseApp param store restart-safe:

- seed consensus params from `config/genesis.json` at app construction;
- fall back to CometBFT defaults if genesis params are unavailable;
- make `Get` always return non-nil params;
- copy params on `Get` and `Set` to avoid accidental aliasing;
- keep business logic, modules, economics, genesis defaults, and live flags unchanged.

Post-fix restart behavior is validated in `docs/testnet/PHASE_9V_RESTART_RESULTS.md`.
