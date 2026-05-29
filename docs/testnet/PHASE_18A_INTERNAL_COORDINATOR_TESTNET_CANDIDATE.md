# Phase 18A Internal Coordinator Testnet Candidate

**Date:** 2026-05-29
**Network:** `nexarail-testnet-1`
**Status:** internal coordinator candidate preparation

## Purpose

Prepare a coordinator-controlled testnet candidate and public join-readiness package while external validator intake remains open and external gentxs are still pending.

This phase keeps the project moving without fabricating external validator participation or waiting for external gentxs before completing useful readiness work.

## What This Is

- An internal coordinator-controlled testnet candidate.
- A local-only genesis candidate assembled from internal coordinator validators.
- A rehearsal artifact for validating genesis assembly, peer generation, monitoring, runbook readiness, and launch-window coordination.
- A readiness package for accepted external validators once external gentxs are submitted and verified.

## What This Is Not

- Not mainnet.
- Not a public testnet launch.
- Not final public genesis.
- Not evidence of external decentralisation.
- Not proof that independent external validators are running.
- Not a token sale, exchange listing, investment offer, or claim of monetary value.

## Coordinator-Controlled Status

The coordinator candidate is controlled by local/internal coordinator validators only. It may be used for dry-runs, monitoring rehearsal, launch-window preparation, and public join documentation review.

It must remain clearly marked:

```text
INTERNAL COORDINATOR CANDIDATE — NOT FINAL PUBLIC GENESIS
```

## External Validator Intake

External validator intake remains open. The registry currently has zero submitted external validator records and zero submitted external gentxs.

Accepted external validators should continue using the source-build path and documented gentx submission process. Final public genesis remains pending until verified external gentxs exist.

## Chain ID

```text
nexarail-testnet-1
```

## Genesis Process

1. Build `nexaraild` from source if `build/nexaraild` is missing.
2. Create local/internal coordinator validator homes under ignored rehearsal storage.
3. Generate local coordinator gentxs only.
4. Verify each local gentx with `scripts/testnet/verify-controlled-testnet-gentx.sh`.
5. Assemble the candidate with `scripts/testnet/assemble-controlled-testnet-genesis.sh`.
6. Confirm all product live flags remain false.
7. Validate genesis.
8. Write candidate output to `releases/testnet-genesis/coordinator-candidate/`.
9. Compute and publish the candidate SHA256 only as an internal coordinator candidate checksum.

## Peer Process

1. Generate an internal coordinator intake file from local node IDs and local P2P ports.
2. Generate persistent peers with `scripts/testnet/generate-persistent-peers.sh`.
3. Keep the coordinator candidate peer list separate from final public peer output.
4. Replace the candidate peer list only after verified external endpoint inventory exists.

## Monitoring Process

Use `scripts/testnet/monitor-controlled-testnet-readiness.sh` for future launch-window monitoring. The monitor samples RPC and optional REST/API endpoints, checks chain ID, height progression, catching-up status, peer count, validator count, REST/API health, live flags, and endpoint health notes.

## Launch Readiness Gates

- Source build works from the selected tag or commit.
- CLI node ID helper commands work.
- Gentx command is documented.
- Intake form and registry exist.
- Gentx verifier exists.
- Genesis assembler exists.
- Persistent peers generator exists.
- Runbook exists.
- Status document exists.
- Endpoint inventory template exists.
- Monitoring script exists.
- Support process and launch-window communication channel are defined.
- Final public genesis is pending until verified external gentxs exist.
- Launch time is pending.
- Product live flags remain false.

## Disclaimer

This is not mainnet. No public network has launched from this candidate. No external decentralisation is claimed. NXRL is not presented as buyable and has no implied monetary value in this context. No token sale is announced or implied.
