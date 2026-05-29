# Final Genesis Freeze Decision

**Date:** 2026-05-29
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
| Endpoint records received | 1 P2P-only record; peer host pending confirmation |
| Persistent peers | GENERATED - PENDING DNS/IP CONFIRMATION |
| Final public genesis candidate | NOT ASSEMBLED |
| Launch status | NOT LAUNCHED |

## Persistent Peers Status

Generated persistent peer entry using the earlier DNS endpoint:

```text
2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656
```

The gentx memo uses:

```text
2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@178.104.162.88:26656
```

Final persistent peer publication is pending confirmation from NodeSync on whether to use DNS or IP.

## Endpoint Status

`coordination/validators/endpoint-inventory.csv` records NodeSync P2P-only metadata. RPC, API, and gRPC endpoints have not been provided. Peer host status is `PENDING_CONFIRMATION`.

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

Final public genesis is not frozen because only one external gentx is verified, the final peer host is pending DNS/IP confirmation, and coordinator launch criteria have not been met.

## Next Required Action

Ask NodeSync whether final persistent peers should use `nexarail-testnet-peer.nodesync.top:26656` or `178.104.162.88:26656`, then re-run the freeze gate after peer confirmation and coordinator launch criteria are satisfied.

## Safety Boundary

Controlled external-validator testnet preparation continues. No public network has launched. Mainnet remains NO-GO. External decentralisation is not claimed. NXRL is not presented as buyable and no monetary value is implied. No token sale is announced or implied. Product live-funds flags remain false by default.
