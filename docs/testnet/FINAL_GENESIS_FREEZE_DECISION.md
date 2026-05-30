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
| External validator genesis candidate | ASSEMBLED FOR REVIEW |
| Final public genesis candidate | NOT FROZEN |
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

Phase 17D assembled a controlled external-validator genesis candidate for review only:

```text
releases/testnet-genesis/nexarail-testnet-1-candidate/genesis.json
```

Candidate details:

- composition: NodeSync plus five coordinator-operated validators;
- validator count: 6;
- genesis SHA256: `4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095`;
- NodeSync in-genesis verification: pass;
- dry-run result: pass to height 20 with validator set count 6;
- candidate marker: `EXTERNAL VALIDATOR GENESIS CANDIDATE - NOT FINAL PUBLIC GENESIS`;
- launch status: not launched.

The Phase 18A internal coordinator candidate remains available for coordinator rehearsal only:

```text
releases/testnet-genesis/coordinator-candidate/genesis.json
```

It is marked `INTERNAL COORDINATOR CANDIDATE — NOT FINAL PUBLIC GENESIS` and must not be published as final public genesis.

No final public genesis has been frozen or published for `releases/testnet-genesis/nexarail-testnet-1/`.

## Freeze Decision

```text
FREEZE_DEFER
```

## Reason

Final public genesis is not frozen because NodeSync P2P TCP reachability was not confirmed at check time, the final public genesis review is not complete, the launch window is not confirmed, and coordinator launch criteria have not been fully signed off.

## Next Required Action

Confirm NodeSync P2P reachability, complete final genesis review, keep additional validator intake open, and re-run the freeze gate after coordinator launch criteria are satisfied.

## Safety Boundary

Controlled external-validator testnet preparation continues. No public network has launched. Mainnet remains NO-GO. External decentralisation is not claimed. NXRL is not presented as buyable and no monetary value is implied. No token sale is announced or implied. Product live-funds flags remain false by default.
