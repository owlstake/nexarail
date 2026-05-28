# Phase 9W - Agent Testnet Runtime Readiness Report

**Date:** 2026-05-27  
**Chain ID:** `nexarail-agent-testnet-1`  
**Scope:** local validator-agent runtime evidence from Phases 9T, 9U, and 9V  
**Status:** Complete - technical agent-testnet runtime readiness is GO

## Executive Summary

The NexaRail local agent testnet has proven the core runtime behaviours required for continued controlled testnet preparation:

- block production across a 5-agent CometBFT validator set;
- full query/readback across status, validator set, balances, accounts, module params, and live flags;
- runtime bank transaction inclusion;
- governance proposal lifecycle for enabling and disabling a live flag, with final state readback;
- 60-minute clean-spawn soak with stable peer count and validator set;
- persistence-safe restart recovery after the Phase 9V consensus-param store fix.

This is a technical GO for the local agent-testnet runtime path. It is not a public/external testnet launch GO and it is not a mainnet GO.

## Scope

Included:

- Phase 9T clean-spawn readback and governance evidence.
- Phase 9U 60-minute clean-spawn soak and runtime bank-send evidence.
- Phase 9V restart investigation, root-cause fix, restart matrix, and final rebuilt-binary proof.

Excluded:

- Product modules, economics, allocations, token supply changes, and genesis live-flag changes.
- External validator launch or external gentx collection.
- Public RPC/API deployment.
- Mainnet launch.

## Environment

| Item | Value |
|---|---|
| Runtime | Local validator-agent rehearsal |
| Host context | OpenClaw-managed local development machine |
| Binary | `build/nexaraild` |
| Framework | Cosmos SDK v0.47.17 + CometBFT v0.37.18 |
| Agent directory | `rehearsals/validator-agents/` |
| Evidence base | `rehearsals/validator-agents/` |

## Chain ID

The consolidated evidence uses the agent-testnet chain:

```text
nexarail-agent-testnet-1
```

The planned public/external testnet chain ID remains `nexarail-testnet-1` and has not launched.

## Validator Count

Primary runtime evidence uses 5 local agent validators:

- `alpha`
- `bravo`
- `charlie`
- `delta`
- `echo`

The Phase 9V matrix also tested 1-agent and 3-agent restart cases. Agent validators are development-operated test actors and do not prove external validator participation.

## Evidence Sources

| Phase | Evidence |
|---|---|
| Phase 9T clean-spawn governance | `rehearsals/validator-agents/clean-spawn-governance/evidence/20260527T095523Z/` |
| Phase 9T query readback | `rehearsals/validator-agents/query-readback/evidence/20260527T095523Z/` |
| Phase 9U long soak | `rehearsals/validator-agents/long-soak/evidence/20260527T102106Z/` |
| Phase 9V restart investigation | `rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/` |
| Phase 9V final rebuilt-binary proof | `rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/final-code-restart-proof/` |

## Block Production Proof

Phase 9T established a clean 5-agent runtime with validator count `5`, peer count `4`, and latest height above `20`.

Phase 9U then proved sustained block production:

| Metric | Result |
|---|---:|
| Duration | 3602s |
| Start height | 12 |
| Final height | 685 |
| Height delta | 673 |
| Average block time | 5.35s |
| Peer count range | 4-4 |
| Validator set range | 5-5 |
| Panic count during clean soak | 0 |

Phase 9V proved block production after restart, including the post-soak restart case from height `695` to `698` and the final rebuilt-binary proof from height `11` to `14`.

## Query / Readback Proof

Phase 9T clean-spawn readback:

```text
85 pass / 0 fail / 0 skip
```

Phase 9U periodic readback during soak:

```text
425 pass / 0 fail / 0 skip
```

Phase 9V final rebuilt-binary readback after restart:

```text
85 pass / 0 fail / 0 skip
```

The readback set covered status, validator set, bank balances, auth accounts, module parameters for fees, merchant, settlement, escrow, payout, treasury, and all live flags.

## Runtime Transaction Proof

Phase 9U submitted a testnet-only bank send during the clean 60-minute soak:

| Field | Result |
|---|---|
| Amount | `123unxrl` |
| Tx hash | `9F85BD88F936818D6A910BEE640DDAF3B1D437F993519BE2FACCCF3D0E0E52A5` |
| Inclusion code | `0` |
| Result | pass |

Phase 9V also submitted a bank send after the simultaneous all-node direct restart with inclusion code `0`.

## Governance Proof

Phase 9T executed the escrow live-flag governance lifecycle end-to-end:

| Check | Result |
|---|---|
| Enable proposal ID | `1` |
| Enable submit tx | `CBFBBDD5964C7B1D2C9C0BBDE8D9CAA40863F734E3B4BA4C4B08CE22F8840338` |
| `escrow.live_enabled` after enable | `true` |
| Disable proposal ID | `2` |
| Disable submit tx | `46733082097465AD2BEA3B8A7532F18F9B4A5F6CCD44FC798EF508957E53CECC` |
| `escrow.live_enabled` after disable | `false` |
| Governance summary | 49 pass / 0 fail |

Final state after the governance lifecycle returned all live flags to `false`.

## Long Soak Proof

The Phase 9U clean-spawn long soak passed:

- target duration: `3600s`;
- actual duration: `3602s`;
- height delta: `673`;
- query total: `425 pass / 0 fail / 0 skip`;
- peer count range: `4-4`;
- validator set range: `5-5`;
- clean-soak panic count: `0`;
- runtime bank-send inclusion code: `0`.

Phase 9V repeated the long-soak failure shape and verified restart recovery after the fix.

## Restart Matrix Proof

Phase 9V fixed the Phase 9U restart panic root cause: the custom in-memory BaseApp consensus-param store could return nil after process restart. The fix seeds consensus params from genesis/defaults and guarantees non-nil copied params after restart.

| Case | Result |
|---|---|
| Single-validator clean stop/reuse-data restart | pass |
| 3-agent clean stop/reuse-data restart | pass |
| 5-agent clean stop/reuse-data restart | pass |
| 5-agent immediate restart at height 20 | pass |
| 5-agent restart after 60-minute soak | pass, height 695 to 698 |
| One-node restart while four validators continued | pass |
| All-node direct simultaneous restart | pass |
| All-node direct sequential restart | pass |
| Standard single-node direct restart | pass |

All matrix cases resumed block production, preserved the expected validator set, passed query checks, and recorded zero post-fix proposal panics.

## Final Live Flags

Final live-flag readback from the consolidated evidence:

```text
settlement.live_enabled=false
settlement.treasury_routing_enabled=false
settlement.burn_routing_enabled=false
escrow.live_enabled=false
payout.live_enabled=false
treasury.live_enabled=false
```

No genesis live flags were enabled by Phase 9W.

## Known Limitations

- The validator set is made of development-operated local agent validators.
- This does not prove external validator participation or external decentralisation.
- The environment is local and differs from a multi-machine Linux public testnet.
- External validator onboarding and gentx collection remain pending.
- Public RPC/API infrastructure remains pending.
- External security audit remains pending.
- Legal review remains pending.
- Mainnet is not live.
- NXRL is not available to buy and no token sale exists.

## External Validator Status

External validators remain pending. No external gentxs have been collected for the planned public/external testnet launch. The current evidence supports the agent-testnet runtime path only.

## GO / NO-GO Decision

| Area | Decision | Rationale |
|---|---|---|
| Technical agent-testnet runtime readiness | GO | Phases 9T, 9U, and 9V prove block production, readback, tx inclusion, governance, long soak, and restart recovery in the local agent environment. |
| Public/external testnet launch | NO-GO | External validator cohort, gentxs, final genesis candidate, public endpoint plan, and validator communications are not complete. |
| Mainnet | NO-GO | External validators, public testnet, external audit, legal review, and mainnet release process are not complete. |

## Conclusion

Phase 9W consolidates the evidence that the NexaRail local agent testnet runtime is ready for the next controlled-testnet preparation phase. The next phase should move from local agent evidence to external validator and multi-machine rehearsal evidence without changing modules, economics, or live-flag defaults.
