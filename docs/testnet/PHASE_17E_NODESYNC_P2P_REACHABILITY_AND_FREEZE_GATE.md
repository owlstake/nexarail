# Phase 17E NodeSync P2P Reachability And Freeze Gate

**Date:** 2026-05-30
**Network:** `nexarail-testnet-1`
**Status:** `FREEZE_DEFER`

## Objective

Confirm whether the accepted NodeSync P2P endpoint is reachable, rerun the final genesis freeze gate checks, and decide whether the candidate can move toward final public genesis freeze.

This phase does not launch the network.

## Reachability Evidence

Timestamp UTC:

```text
2026-05-30T00:37:58Z
```

DNS command:

```bash
dig +short nexarail-testnet-peer.nodesync.top
dig +nocmd nexarail-testnet-peer.nodesync.top A +noall +answer
```

DNS result:

```text
nexarail-testnet-peer.nodesync.top. 300 IN A 178.104.162.88
```

DNS TTL:

```text
300 seconds
```

TCP commands:

```bash
nc -vz nexarail-testnet-peer.nodesync.top 26656
nc -vz 178.104.162.88 26656
```

TCP result:

```text
nexarail-testnet-peer.nodesync.top:26656 - connection refused
178.104.162.88:26656 - connection refused
```

Endpoint status:

```text
NOT_REACHABLE
```

### Phase 17E.1 NodeSync Clarification

NodeSync confirmed after this check that the real `nexaraild` service had not been started on the VPS yet. This is expected before final genesis distribution. NodeSync then started a temporary `nc` listener on TCP 26656 to demonstrate the VPS is reachable on the wire. A `nc` listener is not evidence of CometBFT P2P readiness. See `docs/testnet/PHASE_17E1_GENESIS_DENOM_AUDIT_AND_P2P_PRECONDITIONS.md` for the full preconditions that must be satisfied before the freeze gate can advance to `FREEZE_GO`.

## NodeSync Peer Entry

Persistent peer:

```text
2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656
```

The peer entry remains structurally valid and points to the confirmed DNS host. The endpoint is not launch-ready until TCP 26656 accepts inbound connections from the coordinator side.

## Candidate Genesis Check

Candidate genesis path:

```text
releases/testnet-genesis/nexarail-testnet-1-candidate/genesis.json
```

Expected and observed SHA256:

```text
4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095
```

Checks rerun:

- SHA256 matches `SHA256SUMS`;
- `validate-genesis` passes;
- NodeSync remains in genesis;
- NodeSync operator address is `nxrvaloper182fzt70uwg5sglwm6upagfr4gvp3sjayyfg9yn`;
- NodeSync consensus pubkey is present: `7DSuljV9kAw1JR19FfnK7bzFjY55YfcdpMdEf/X491s=`;
- NodeSync self-delegation remains `500000000unxrl`;
- product live flags remain false;
- no private material pattern was found in the candidate release artifacts;
- persistent peers include the NodeSync DNS entry.

## Freeze Decision

```text
FREEZE_DEFER
```

Reason:

- candidate genesis is valid;
- NodeSync is included in genesis;
- persistent peer generation is correct;
- NodeSync P2P endpoint is not reachable on TCP 26656;
- launch time and final coordinator sign-off remain pending.

No final public genesis folder was created for this phase. The review candidate remains under:

```text
releases/testnet-genesis/nexarail-testnet-1-candidate/
```

## Required Validator Action

NodeSync should ensure its node is listening publicly on TCP `26656` for:

```text
nexarail-testnet-peer.nodesync.top:26656
```

NodeSync should also confirm any firewall, cloud security group, NAT, and CometBFT `p2p.laddr` or external-address configuration required for inbound P2P.

## Launch Status

Controlled external-validator testnet remains **NOT LAUNCHED**. Mainnet remains **NO-GO**. External decentralisation is not claimed. NXRL is not presented as buyable and no monetary value is implied. No token sale is announced or implied. Product live-funds flags remain false by default.
