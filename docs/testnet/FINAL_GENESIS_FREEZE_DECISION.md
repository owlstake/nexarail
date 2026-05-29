# Final Genesis Freeze Decision

**Date:** 2026-05-30
**Network:** `nexarail-testnet-1`
**Status:** FREEZE_DEFER

## Intake Counts

| Item | Count / Status |
|---|---|
| Validator metadata records received | 1 |
| Accepted validator intake records | 1 |
| Gentx files received locally | 1 |
| Gentxs accepted | 1 |
| Gentxs rejected | 0 |
| Endpoint records received | 1 P2P-only DNS record |
| Persistent peers | GENERATED |
| Final public genesis candidate | NOT ASSEMBLED |
| Launch status | NOT LAUNCHED |

## Persistent Peers Status

Generated persistent peer entry using the confirmed DNS endpoint:

```text
2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656
```

The gentx memo uses:

```text
2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@178.104.162.88:26656
```

The confirmed persistent peer uses DNS. The gentx memo IP is retained as a noted difference for operator awareness.

## Endpoint Status

`coordination/validators/endpoint-inventory.csv` records NodeSync P2P-only DNS metadata. RPC, API, and gRPC endpoints have not been provided.

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

Final public genesis is not frozen because only one external gentx is verified and coordinator launch criteria have not been met.

## Next Required Action

Continue validator intake and re-run the freeze gate after coordinator launch criteria are satisfied.

## Safety Boundary

Controlled external-validator testnet preparation continues. No public network has launched. Mainnet remains NO-GO. External decentralisation is not claimed. NXRL is not presented as buyable and no monetary value is implied. No token sale is announced or implied. Product live-funds flags remain false by default.
