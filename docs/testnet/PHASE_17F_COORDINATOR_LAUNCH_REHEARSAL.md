# Phase 17F Coordinator Launch Rehearsal

**Date:** 2026-05-30
**Network:** `nexarail-testnet-1`
**Status:** coordinator launch rehearsal complete; launch not live

## Purpose

Rehearse coordinator-side launch operations using the external-validator genesis candidate while NodeSync P2P reachability remains pending. This phase validates the coordinator workflow, local monitoring, and evidence capture without launching the controlled external-validator testnet.

This phase does not call the network mainnet, does not publish final public genesis, and does not claim external decentralisation.

## Candidate Genesis Used

```text
releases/testnet-genesis/nexarail-testnet-1-candidate/genesis.json
```

Candidate SHA256:

```text
4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095
```

The candidate remains marked as an external-validator genesis candidate for review. It is not final public genesis.

## Validator Set Composition

Candidate validator set:

- NodeSync external validator: 1
- coordinator-operated validators: 5
- total validator set count: 6

NodeSync remains included in the candidate genesis and validator set. The coordinator does not have NodeSync signing material and must not request it.

## Rehearsal Limitation

The local rehearsal starts only the five coordinator validator homes. NodeSync is present in the validator set but its external signer is not simulated locally. This validates the coordinator launch path with the candidate genesis, but it is not evidence that NodeSync is online.

NodeSync P2P reachability remains pending:

```text
2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656
```

Latest Phase 17F recheck:

```text
Timestamp UTC: 2026-05-30T01:19:37Z
DNS: nexarail-testnet-peer.nodesync.top -> 178.104.162.88
TCP DNS check: connection refused
TCP IP check: connection refused
Endpoint status: NOT_REACHABLE
```

## Candidate Launch Rehearsal

Command:

```bash
scripts/testnet/run-controlled-testnet-dry-run.sh \
  --genesis releases/testnet-genesis/nexarail-testnet-1-candidate/genesis.json \
  --source-homes rehearsals/coordinator-candidate/runs/20260529T163048Z/homes \
  --expected-validators 6 \
  --min-height 50 \
  --keep-running
```

Result:

- status: PASS
- height verified: 50
- validator set count: 6
- local coordinator validators started: 5
- NodeSync signing key: not used locally and not simulated
- product live flags: false
- REST params: queryable
- `tendermint show-node-id` and `comet show-node-id`: pass
- panic/fatal scan: pass
- evidence: `rehearsals/controlled-testnet/dry-run/evidence/20260530T012624Z-phase17f-live/`

The dry-run harness now calculates its height wait budget after parsing `--min-height`, so higher-height rehearsals do not inherit the default height-20 timeout.

## Launch-Hour Evidence Rehearsal

Command:

```bash
scripts/testnet/collect-launch-hour-evidence.sh \
  --endpoints rehearsals/controlled-testnet/dry-run/evidence/20260530T012624Z-phase17f-live/local-endpoints.csv \
  --duration 600 \
  --sample-interval 60 \
  --expected-validators 6 \
  --chain-id nexarail-testnet-1
```

Evidence path:

```text
rehearsals/controlled-testnet/launch-hour/evidence/20260530T013213Z/
```

Expected evidence files:

- `summary.json`
- `summary.md`
- `samples.tsv`
- `endpoint-health.json`
- `validators-final.json`
- `live-flags-final.json`
- `panic-scan.txt`
- `notes.md`

Result:

- collector status: FAIL, due only to expected validator-count drift from 6 to 5 after the non-simulated NodeSync signer missed the local rehearsal window;
- latest height: 159;
- block progression: 105;
- RPC samples: 55;
- endpoint rows: 5;
- live flags: false across all local REST/API endpoints;
- panic/fatal markers: 0;
- launch status recorded by the collector: NOT_LAUNCHED.

Interpretation: this is a coordinator-side rehearsal limitation, not launch evidence. The early dry-run and readiness monitor confirm the six-validator candidate is queryable, but the full 600-second local-only evidence run cannot keep the external validator active because NodeSync is not signing locally.

## Readiness Monitor Rehearsal

Readiness monitor target:

```text
rehearsals/controlled-testnet/dry-run/evidence/20260530T012624Z-phase17f-live/local-endpoints.csv
```

Expected result:

- status: PASS;
- chain ID matched `nexarail-testnet-1`;
- block progression observed: 9;
- validator count reported 6 during the monitor window;
- coordinator RPC/API endpoints responded;
- `catching_up=false`;
- peer count: 4 per coordinator node;
- product live flags remained false;
- JSON report: `rehearsals/controlled-testnet/dry-run/evidence/20260530T012624Z-phase17f-live/readiness-monitor.json`.

## Freeze Decision

```text
FREEZE_DEFER
```

Reason:

- candidate rehearsal passes locally with five coordinator signers;
- NodeSync remains included in the candidate validator set;
- NodeSync P2P TCP `26656` is still not reachable from the coordinator side;
- launch window and final public genesis sign-off remain pending.

## Launch Status

Controlled external-validator testnet remains **NOT LAUNCHED**. Mainnet remains **NO-GO**. External decentralisation is not claimed. NXRL is not presented as buyable and no monetary value is implied. No token sale is announced or implied. Product live-funds flags remain false by default.

## Next Action

NodeSync should open/listen on TCP `26656` for `nexarail-testnet-peer.nodesync.top`, then the coordinator should re-run the P2P reachability check and final genesis freeze gate.
