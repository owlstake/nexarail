# Final Genesis Freeze Decision

**Date:** 2026-05-29
**Network:** `nexarail-testnet-1`
**Status:** FREEZE_DEFER

## Intake Counts

| Item | Count / Status |
|---|---|
| Validator metadata records received | 1 |
| Accepted validator intake records | 0 |
| Gentx files received locally | 0 |
| Gentxs accepted | 0 |
| Gentxs rejected | 0 |
| Endpoint records received | 1 P2P-only metadata record |
| Persistent peers | WAITING |
| Final public genesis candidate | NOT ASSEMBLED |
| Launch status | NOT LAUNCHED |

## Persistent Peers Status

NodeSync reported this P2P endpoint:

```text
2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656
```

The final persistent peer string is still waiting because the gentx JSON file is not present locally and the validator has not been accepted into the verified intake set.

## Endpoint Status

`coordination/validators/endpoint-inventory.csv` records NodeSync P2P-only metadata. RPC, API, and gRPC endpoints have not been provided.

## Genesis Candidate Status

The Phase 18A internal coordinator candidate remains available for coordinator rehearsal only:

```text
releases/testnet-genesis/coordinator-candidate/genesis.json
```

It is marked `INTERNAL COORDINATOR CANDIDATE — NOT FINAL PUBLIC GENESIS` and must not be published as final public genesis.

No final public genesis candidate has been assembled for `releases/testnet-genesis/nexarail-testnet-1/`.

## Freeze Decision

```text
FREEZE_DEFER
```

## Reason

Final public genesis cannot be frozen because verified external gentx count is zero. NodeSync metadata has been received, but the original gentx JSON file content is not present locally, so SHA256 and gentx verification cannot be completed.

## Next Required Action

Request the exact NodeSync gentx JSON file, verify the submitted SHA256, run the controlled gentx verifier, update the accepted intake registry only if verification passes, regenerate persistent peers, then re-run the freeze gate.

## Safety Boundary

Controlled external-validator testnet preparation continues. No public network has launched. Mainnet remains NO-GO. External decentralisation is not claimed. NXRL is not presented as buyable and no monetary value is implied. No token sale is announced or implied. Product live-funds flags remain false by default.
