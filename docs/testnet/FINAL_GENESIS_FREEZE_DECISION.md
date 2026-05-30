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
| Endpoint records received | 1 P2P-only DNS record, not reachable on TCP 26656 |
| Persistent peers | GENERATED |
| External validator genesis candidate | ASSEMBLED FOR REVIEW |
| Coordinator launch rehearsal with external candidate | PASS TO HEIGHT 50 |
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

Phase 17E reachability check:

```text
Timestamp UTC: 2026-05-30T00:37:58Z
DNS: nexarail-testnet-peer.nodesync.top. 300 IN A 178.104.162.88
TCP DNS check: connection refused on nexarail-testnet-peer.nodesync.top:26656
TCP IP check: connection refused on 178.104.162.88:26656
Endpoint status: NOT_REACHABLE
```

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

Phase 17F coordinator launch rehearsal:

- command used the external-validator candidate genesis with five coordinator signer homes;
- expected validator count: 6;
- height verified: 50;
- NodeSync included in the validator set but not locally simulated;
- product live flags: false;
- panic/fatal scan: pass;
- evidence: `rehearsals/controlled-testnet/dry-run/evidence/20260530T012624Z-phase17f-live/`.

The 600-second launch-hour evidence rehearsal wrote complete samples under `rehearsals/controlled-testnet/launch-hour/evidence/20260530T013213Z/` and returned `FAIL` because the local-only run cannot keep the non-simulated NodeSync validator in the active set for the full window. Block progression continued to height 159, live flags remained false, and panic/fatal markers were zero. This reinforces `FREEZE_DEFER`; it is not public launch evidence.

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

Final public genesis is not frozen because NodeSync P2P TCP reachability is still not confirmed: TCP 26656 returned connection refused for both the DNS host and direct IP at the Phase 17F recheck. The launch window is not confirmed and coordinator launch criteria have not been fully signed off.

## Next Required Action

Ask NodeSync to open/listen on TCP 26656 for `nexarail-testnet-peer.nodesync.top`, confirm reachability from the coordinator side, keep additional validator intake open, and re-run the freeze gate after coordinator launch criteria are satisfied.

## Safety Boundary

Controlled external-validator testnet preparation continues. No public network has launched. Mainnet remains NO-GO. External decentralisation is not claimed. NXRL is not presented as buyable and no monetary value is implied. No token sale is announced or implied. Product live-funds flags remain false by default.
