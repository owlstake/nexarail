# Phase 9U - Long Soak and Persistence-Safe Restart Plan

**Date:** 2026-05-27  
**Chain:** `nexarail-agent-testnet-1`  
**Scope:** local 5-agent validator rehearsal only  
**Status:** Executed - results in `docs/testnet/PHASE_9U_LONG_SOAK_RESULTS.md`

## Purpose

Phase 9U proves whether the local 5-agent validator rehearsal can run beyond a short smoke test and whether restarting from existing agent data is safe enough to support for rehearsals.

This phase is limited to runtime stability, query readback, transaction liveness, restart behavior, and evidence collection. It does not add product modules, change economics, enable live flags by default, launch mainnet, make NXRL available to buy, or claim external decentralisation from local agent validators.

## Clean-Spawn Baseline From Phase 9T

Phase 9T completed a clean-spawn baseline with:

- 5 local validator agents started from wiped data.
- Runtime proof at height `21`.
- Alpha peer count `4`.
- Validator set count `5`.
- Query readback `85 pass / 0 fail / 0 skip`.
- Governance proof `49 pass / 0 fail`.
- Escrow live flag enabled by proposal `1` and disabled by proposal `2`.
- Final live flags all false.
- Evidence: `rehearsals/validator-agents/clean-spawn-governance/evidence/20260527T095523Z/`.

## Soak Duration Targets

- Minimum: `1h`.
- Preferred: `6h`.
- Strong: `24h`.

For Phase 9U, the local OpenClaw execution window is expected to support the minimum `1h` soak. If a longer run is not practical in the current environment, the limitation must be recorded in the results and evidence.

## Restart Test Plan

1. Stop any running validator agents.
2. Start a fresh clean-spawn run with `scripts/testnet/spawn-validator-agents.sh --clean`.
3. Run `scripts/testnet/run-agent-soak-test.sh --duration 60m`.
4. Capture the soak summary with `scripts/testnet/agent-soak-summary.sh`.
5. Submit at least one runtime bank-send transaction during or after the soak.
6. Stop all agents cleanly.
7. Restart with `scripts/testnet/spawn-validator-agents.sh --reuse-data`.
8. Confirm block production resumes from the existing chain data.
9. Confirm queries still work.
10. Confirm validator set remains `5`.

## Success Criteria

- The 5 local validator agents remain reachable for the full soak.
- Block height increases throughout the soak.
- Average block time remains consistent with the local CometBFT runtime.
- Peer counts remain stable enough for consensus; alpha should retain 4 peers under normal conditions.
- Validator set remains 5.
- Periodic status, validator set, bank, custom module params, and live flag queries return without failure.
- At least one bank-send transaction is accepted and included after extended runtime.
- No panics are found in agent logs.
- Restart with `--reuse-data` either succeeds and is documented as usable for rehearsals, or fails in a clearly documented way that preserves clean-spawn as the supported rehearsal mode.

## Failure Criteria

- Any agent exits unexpectedly and does not recover.
- Block production stalls.
- Validator set drops below 5.
- Query readback fails for status, validator set, bank balances, custom module params, or live flags.
- A bank-send transaction cannot be broadcast or included after extended runtime.
- A panic appears in agent logs.
- Reuse-data restart corrupts evidence or cannot be classified safely.

## External Decentralisation Disclaimer

The 5-agent testnet is a local rehearsal with agent-controlled validators. It does not prove external validator participation, independent validator operations, public decentralisation, mainnet readiness, token availability, or market value. External validator launch remains pending until real validator operators are onboarded, gentxs are collected, and the launch process is completed.
