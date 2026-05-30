# Phase 17C.1 NodeSync Submission Local Evidence Recheck

**Date:** 2026-05-30
**Network:** `nexarail-testnet-1`
**Status:** NodeSync gentx found locally, hash matched, accepted

## Purpose

Recheck coordinator-side evidence before sending any validator-facing resend request. This recheck verifies whether the NodeSync gentx exists locally, whether it appears to have arrived as an attachment or downloaded file, and whether intake tooling handles it correctly.

## Search Locations Checked

Repo-local search from `/Users/bradleyjohnston/workspace/nexarail` checked:

- exact filename `gentx-2bb62d82b4dbf820fdafd843816f1e72a84ffa8f.json`;
- all `gentx-*.json`;
- case-insensitive `*nodesync*`;
- case-insensitive `*my_info*`;
- node ID `2bb62d82b4dbf820fdafd843816f1e72a84ffa8f`;
- SHA256 `fbf829ef28330323d6850f89b7219f2d43a47e98ecce91ba16e46aef94566601`;
- `NODESYNC`;
- `nexarail-testnet-peer.nodesync.top`.

Local user-folder search checked:

- `/Users/bradleyjohnston/Downloads`;
- `/Users/bradleyjohnston/Desktop`;
- `/Users/bradleyjohnston/Documents`;
- `/Users/bradleyjohnston/Library/Messages`;
- `/Users/bradleyjohnston/Library/Containers`;
- `/Users/bradleyjohnston/Library/Group Containers`;
- `/Users/bradleyjohnston/.openclaw`.

Some protected macOS paths under `Library/Messages`, `Library/Containers`, and `Library/Group Containers` returned permission-denied results. The searchable locations were still checked, and the gentx evidence was found in Downloads.

## Local Evidence Found

The exact gentx filename exists in the project workspace:

```text
coordination/validators/gentxs/gentx-2bb62d82b4dbf820fdafd843816f1e72a84ffa8f.json
coordination/validators/verified/gentx-2bb62d82b4dbf820fdafd843816f1e72a84ffa8f.json
```

A likely downloaded attachment copy was found under a renamed filename:

```text
/Users/bradleyjohnston/Downloads/e18ba0d1bf1915e8ec4cf5c01471b046.json
```

The downloaded file is byte-identical to the canonical project gentx copy.

## SHA256 Result

```text
fbf829ef28330323d6850f89b7219f2d43a47e98ecce91ba16e46aef94566601  /Users/bradleyjohnston/Downloads/e18ba0d1bf1915e8ec4cf5c01471b046.json
fbf829ef28330323d6850f89b7219f2d43a47e98ecce91ba16e46aef94566601  coordination/validators/gentxs/gentx-2bb62d82b4dbf820fdafd843816f1e72a84ffa8f.json
```

Result: **MATCH**.

## Gentx Content Check

The downloaded/canonical gentx contains:

- message type: `/cosmos.staking.v1beta1.MsgCreateValidator`;
- moniker: `NODESYNC`;
- delegator: `nxr182fzt70uwg5sglwm6upagfr4gvp3sjay33wx28`;
- validator: `nxrvaloper182fzt70uwg5sglwm6upagfr4gvp3sjayyfg9yn`;
- memo: `2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@178.104.162.88:26656`.

The coordinator-confirmed persistent peer uses DNS:

```text
2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656
```

The memo IP is retained as a noted difference for operator awareness.

## Validation Result

Direct gentx verifier:

- result: PASS;
- pass count: 11;
- fail count: 0;
- warning count: 1;
- warning: chain ID is not embedded in the gentx JSON; `collect-gentxs` validates the signature against the genesis chain ID.

Intake validator:

- status: PASS;
- submitted validators: 1;
- verified gentxs: 1;
- rejected gentxs: 0.

## Intake Status

NodeSync is recorded in:

```text
coordination/validators/validator-intake.csv
```

Status:

```text
accepted
```

The verified gentx is copied to:

```text
coordination/validators/verified/gentx-2bb62d82b4dbf820fdafd843816f1e72a84ffa8f.json
```

## Persistent Peer Status

Persistent peers were regenerated from the accepted intake record:

```text
2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656
```

Peer generation status: **READY**.

Warnings: none.

## Resend Decision

NodeSync does **not** need to resend the gentx. The original content was found locally under a renamed Downloads filename and matches the expected SHA256.

## Genesis And Launch Status

Phase 17D subsequently assembled a review-only external-validator genesis candidate under:

```text
releases/testnet-genesis/nexarail-testnet-1-candidate/genesis.json
```

The candidate includes NodeSync plus five coordinator-operated validators, validates, and passed a local dry-run to height 20 with validator set count 6. It is not final public genesis.

Final public genesis remains not frozen. The freeze decision remains `FREEZE_DEFER` because NodeSync P2P TCP reachability was not confirmed at check time, final public genesis review is not complete, and coordinator launch criteria have not been fully signed off.

Controlled external-validator testnet remains **NOT LAUNCHED**. Mainnet remains **NO-GO**. External decentralisation is not claimed. NXRL is not presented as buyable and no monetary value is implied. No token sale is announced or implied. Product live-funds flags remain false by default.
