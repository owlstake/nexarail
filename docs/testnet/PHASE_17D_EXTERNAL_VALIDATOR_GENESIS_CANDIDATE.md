# Phase 17D External Validator Genesis Candidate

**Date:** 2026-05-30
**Network:** `nexarail-testnet-1`
**Status:** genesis candidate assembled for freeze review; launch not live

## Objective

Assemble and review a controlled testnet genesis candidate that includes the accepted NodeSync gentx plus coordinator-operated validators, then decide whether the final public genesis freeze can proceed.

This phase does not launch the network and does not claim external decentralisation.

## Candidate Composition

Selected composition:

```text
NodeSync + five coordinator-operated validators
```

Reason: one verified external gentx is available, and five coordinator-operated validators keep the candidate network able to make blocks during rehearsal without requiring the external validator signing key locally.

Candidate validator count:

- external validators: 1
- coordinator-operated validators: 5
- total candidate validators: 6

## Accepted External Validator

| validator_id | moniker | operator address | node ID | peer |
|---|---|---|---|---|
| `nodesync` | `NODESYNC` | `nxrvaloper182fzt70uwg5sglwm6upagfr4gvp3sjayyfg9yn` | `2bb62d82b4dbf820fdafd843816f1e72a84ffa8f` | `2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656` |

## Coordinator Validators

Source: `releases/testnet-genesis/coordinator-candidate/internal-validator-intake.csv`

| moniker | operator address | node ID |
|---|---|---|
| `nxrl-controlled-alpha` | `nxrvaloper1zyypnnc8k985ak265cpmdhe25ank55wwpwpq3u` | `4308574615c55106210daa81f0d12c604c8e67b0` |
| `nxrl-controlled-bravo` | `nxrvaloper1xqxh725hzejnwxexav68pyz82zc2w0r525rjcn` | `02215ac46546809893f1686e3e14f6934f7e0a19` |
| `nxrl-controlled-charlie` | `nxrvaloper17dj0xr7casz8lhj2susgnmzefuc044dypg939f` | `b19b13768eddeb36884aa86576e51f6219de69fe` |
| `nxrl-controlled-delta` | `nxrvaloper1wmhevd88gpashlu6kwtn6vcsptxf8pky5cgh9x` | `d4913e6c6f2d5cff64ed0776f3daa16a3ab652a6` |
| `nxrl-controlled-echo` | `nxrvaloper1xpqs6zunhk577t6xzyg47d87k2ltrhwk3fc6p3` | `43a8f930863c90617455d27312c8e51ad278d0d3` |

## Genesis Source

Assembly input:

```text
releases/testnet-genesis/nexarail-testnet-1-candidate/gentxs-input/
```

Input gentxs:

- accepted external gentx: `coordination/validators/verified/gentx-2bb62d82b4dbf820fdafd843816f1e72a84ffa8f.json`
- coordinator gentxs: `rehearsals/coordinator-candidate/runs/20260529T163048Z/gentxs/`

Assembly command:

```bash
scripts/testnet/assemble-controlled-testnet-genesis.sh \
  --gentx-dir releases/testnet-genesis/nexarail-testnet-1-candidate/gentxs-input \
  --chain-id nexarail-testnet-1 \
  --output-dir releases/testnet-genesis/nexarail-testnet-1-candidate
```

Output:

- `releases/testnet-genesis/nexarail-testnet-1-candidate/genesis.json`
- `releases/testnet-genesis/nexarail-testnet-1-candidate/SHA256SUMS`
- `releases/testnet-genesis/nexarail-testnet-1-candidate/manifest.json`
- `releases/testnet-genesis/nexarail-testnet-1-candidate/CANDIDATE_NOTICE.md`

Genesis SHA256:

```text
4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095
```

`validate-genesis` passed during assembly. Product live flags remain false.

## NodeSync In-Genesis Verification

NodeSync is present in `genesis.json` under `app_state.genutil.gen_txs`.

| Check | Result |
|---|---|
| moniker | `NODESYNC` |
| operator address | `nxrvaloper182fzt70uwg5sglwm6upagfr4gvp3sjayyfg9yn` |
| consensus pubkey | `7DSuljV9kAw1JR19FfnK7bzFjY55YfcdpMdEf/X491s=` |
| self-delegation | `500000000unxrl` |
| denom | `unxrl` |
| result | PASS |

## Peer Source

Persistent peers were regenerated from:

```text
coordination/validators/validator-intake.csv
```

Output:

```text
coordination/validators/peer-info/persistent-peers.txt
```

Generated peer:

```text
2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656
```

No NodeSync peer-generation warnings were reported.

## DNS And Port Check

DNS check:

```text
nexarail-testnet-peer.nodesync.top -> 178.104.162.88, 64:ff9b::b268:a258
```

TCP check:

```text
26656: not reachable at check time; connection refused
```

This does not invalidate the assembled genesis candidate, but it keeps the freeze decision deferred until launch readiness is confirmed.

## Candidate Dry-Run

Command:

```bash
scripts/testnet/run-controlled-testnet-dry-run.sh \
  --genesis releases/testnet-genesis/nexarail-testnet-1-candidate/genesis.json \
  --source-homes rehearsals/coordinator-candidate/runs/20260529T163048Z/homes \
  --expected-validators 6
```

Result:

- status: PASS
- height verified: 20
- validator set count: 6
- local coordinator validators started: 5
- NodeSync signing key: not used locally and not simulated
- product live flags: false
- REST params: queryable
- panic/fatal scan: pass
- evidence: `rehearsals/controlled-testnet/dry-run/evidence/20260529T235001Z/`

## Freeze Decision

```text
FREEZE_DEFER
```

Reason:

- genesis candidate validates;
- NodeSync is included in genesis;
- dry-run passes with the five coordinator-operated validators online;
- NodeSync P2P DNS resolves, but TCP 26656 was not reachable at check time;
- final public genesis review is not complete;
- launch time and launch-window sign-off are still pending.

## Limitations

- This candidate is not final public genesis.
- The controlled external-validator testnet is not launched.
- NodeSync must run its own validator at launch time; the coordinator does not have and must not request NodeSync signing material.
- One verified external validator does not establish external decentralisation.
- Additional validator intake remains open.
- Mainnet remains NO-GO.
- Product live-funds flags remain false.

## Launch Status

Controlled external-validator testnet remains **NOT LAUNCHED**. Mainnet remains **NO-GO**. External decentralisation is not claimed. NXRL is not presented as buyable and no monetary value is implied. No token sale is announced or implied.

## Next Action

Confirm NodeSync P2P reachability for `nexarail-testnet-peer.nodesync.top:26656`, complete final genesis review, and keep additional validator intake open before any launch freeze decision changes from `FREEZE_DEFER`.

## Phase 17E Follow-Up

Phase 17E rechecked the endpoint at `2026-05-30T00:37:58Z`:

```text
nexarail-testnet-peer.nodesync.top. 300 IN A 178.104.162.88
nexarail-testnet-peer.nodesync.top:26656 - connection refused
178.104.162.88:26656 - connection refused
```

Candidate genesis integrity still passes, but the freeze decision remains `FREEZE_DEFER`. NodeSync must open or listen on TCP `26656` before the coordinator can move this candidate toward final public genesis freeze.
