# Controlled Testnet Status

**Network:** `nexarail-testnet-1`
**Last updated:** 2026-05-30

## Current Status

| Item | Status |
|---|---|
| Controlled external-validator testnet | NOT LAUNCHED |
| Final public genesis | PENDING - review candidate assembled; freeze deferred |
| Internal coordinator candidate | PREPARED - not final public genesis |
| Validator intake registry | OPEN - NodeSync accepted; additional validators pending |
| Validator gentxs | 1 VERIFIED |
| Launch time | PENDING |
| Persistent peers | GENERATED FOR NODESYNC; DNS peer confirmed |
| NodeSync P2P reachability | DEFERRED - real `nexaraild` service starts after final genesis distribution; Phase 17E.1 documents preconditions; Phase 17H freeze gate records TCP 26656 OPEN (NodeSync `nc` listener) as informational only |
| Phase 17E.1 denom audit | PASS - all unxrl; no fix required |
| Phase 17H freeze gate | FREEZE_DEFER - 12 pass / 0 fail / 2 defer (cometbft-handshake + coordinator-signoff pending) |
| Launch sign-off | PENDING - `docs/testnet/CONTROLLED_TESTNET_LAUNCH_SIGNOFF.md` |
| Final launch packet draft | DRAFT - `docs/testnet/CONTROLLED_TESTNET_FINAL_LAUNCH_PACKET_DRAFT.md` |
| NodeSync launch-window instructions | DRAFT - `docs/testnet/NODESYNC_LAUNCH_WINDOW_INSTRUCTIONS.md` |
| Seed or bootnode | PENDING |
| External validator evidence | PENDING |
| Phase 17B intake workflow | READY |
| Phase 18A join readiness package | READY |
| Phase 18B intake execution | OPEN - NodeSync accepted; additional validators pending |
| Phase 18C launch operations pack | READY |
| Phase 17C NodeSync submission | ACCEPTED - DNS peer confirmed |
| Phase 17D genesis candidate review | CANDIDATE ASSEMBLED - freeze deferred |
| Phase 17F coordinator launch rehearsal | PASS - external candidate genesis rehearsed locally |
| Final genesis freeze decision | FREEZE_DEFER |
| Local Phase 17A dry-run | PASS |
| Internal coordinator candidate dry-run | PASS |
| Product live flags | FALSE BY DESIGN |
| Mainnet | NO-GO |

## Current Validator Path

Source-build only:

```bash
git clone https://github.com/Bookings-cpu/nexarail.git
cd nexarail
git checkout v0.1.0-rc1-cli-hotfix
make build
```

Prebuilt hotfix binary upload is not the validator path until release asset permissions are resolved and checksums are published through the GitHub release.

## Phase 17B Intake Status

Current coordination workspace:

- intake registry: `coordination/validators/validator-intake.csv`;
- pending gentxs: `coordination/validators/gentxs/`;
- verified gentxs and validation summaries: `coordination/validators/verified/`;
- rejected gentxs and reason files: `coordination/validators/rejected/`;
- peer output: `coordination/validators/peer-info/`.

Current counts:

- validator metadata records received: 1 (`NODESYNC`);
- accepted validator intake records: 1;
- gentx files received locally: 1;
- gentxs verified: 1;
- gentxs rejected: 0;
- external validator genesis candidate: assembled for freeze review under `releases/testnet-genesis/nexarail-testnet-1-candidate/`.
- final public genesis: not frozen.
- endpoint inventory: NodeSync P2P-only DNS metadata recorded; TCP 26656 not reachable at latest coordinator check; RPC/API/gRPC not provided.
- internal coordinator candidate: assembled from local coordinator validators only.
- submission tracker: NodeSync gentx accepted; DNS peer confirmed.
- final genesis freeze decision: `FREEZE_DEFER`.

## Phase 18A Coordinator Candidate

Phase 18A adds an internal coordinator-controlled candidate so launch artifacts can be rehearsed while external validator intake remains open.

- plan: `docs/testnet/PHASE_18A_INTERNAL_COORDINATOR_TESTNET_CANDIDATE.md`;
- join readiness: `docs/testnet/PUBLIC_JOIN_READINESS_CHECKLIST.md`;
- candidate generator: `scripts/testnet/prepare-coordinator-genesis-candidate.sh`;
- monitoring script: `scripts/testnet/monitor-controlled-testnet-readiness.sh`;
- endpoint inventory template: `coordination/validators/endpoint-inventory.csv`;
- launch-window template: `docs/testnet/CONTROLLED_TESTNET_LAUNCH_WINDOW_TEMPLATE.md`;
- public status draft: `docs/testnet/CONTROLLED_TESTNET_STATUS_UPDATE_DRAFT.md`.

The coordinator candidate is marked `INTERNAL COORDINATOR CANDIDATE — NOT FINAL PUBLIC GENESIS`.

## Phase 18B Intake Execution

Phase 18B executes real validator intake and the final public genesis freeze gate.

- execution plan: `docs/testnet/PHASE_18B_EXTERNAL_VALIDATOR_INTAKE_EXECUTION.md`;
- validator tracker: `coordination/validators/submission-tracker.md`;
- validator messages: `docs/testnet/VALIDATOR_INTAKE_MESSAGE_PACK.md`;
- freeze decision: `docs/testnet/FINAL_GENESIS_FREEZE_DECISION.md`.

Current decision: `FREEZE_DEFER` because one external gentx is verified, but the coordinator has not frozen final public genesis.

## Phase 17C First External Submission

NodeSync submitted public validator metadata and a P2P endpoint:

```text
2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656
```

The gentx SHA256 matches and the controlled gentx verifier passes. The generated peer entry uses the confirmed DNS endpoint. The gentx memo uses IP `178.104.162.88`, which is retained as a noted difference.

## Phase 17D External Validator Genesis Candidate

Phase 17D assembled a controlled testnet genesis candidate for review only:

- composition: NodeSync plus five coordinator-operated validators;
- validator count: 6;
- genesis path: `releases/testnet-genesis/nexarail-testnet-1-candidate/genesis.json`;
- genesis SHA256: `4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095`;
- NodeSync in-genesis verification: pass;
- local candidate dry-run: pass to height 20 with validator set count 6 and five coordinator signers online;
- DNS check: `nexarail-testnet-peer.nodesync.top` resolves to `178.104.162.88`;
- TCP 26656 check: connection refused at check time;
- freeze decision: `FREEZE_DEFER`.

The candidate is marked as not final public genesis and does not change launch status.

## Phase 17E NodeSync Reachability

Phase 17E rechecked NodeSync P2P reachability:

- timestamp UTC: `2026-05-30T00:37:58Z`;
- DNS: `nexarail-testnet-peer.nodesync.top. 300 IN A 178.104.162.88`;
- TCP DNS check: connection refused on `nexarail-testnet-peer.nodesync.top:26656`;
- TCP IP check: connection refused on `178.104.162.88:26656`;
- endpoint status: `NOT_REACHABLE`;
- freeze decision: `FREEZE_DEFER`;
- final public genesis folder: not created.

Candidate genesis integrity still passes: SHA256 matches, `validate-genesis` passes, NodeSync remains in genesis, product live flags remain false, and no secret material pattern was found in candidate artifacts.

## Phase 17F Coordinator Launch Rehearsal

Phase 17F rehearsed coordinator-side launch operations using the external-validator genesis candidate:

- candidate genesis: `releases/testnet-genesis/nexarail-testnet-1-candidate/genesis.json`;
- candidate SHA256: `4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095`;
- validator set count: 6;
- local coordinator signers started: 5;
- NodeSync: included in validator set, not simulated locally;
- dry-run result: pass to height 50;
- 600-second launch-hour evidence rehearsal: completed with expected validator-count failure after NodeSync was not locally signing;
- readiness monitor: pass during the local monitor window;
- product live flags: false;
- REST params: queryable;
- evidence: `rehearsals/controlled-testnet/dry-run/evidence/20260530T012624Z-phase17f-live/`.

NodeSync reachability was rechecked at `2026-05-30T01:19:37Z`; DNS resolved to `178.104.162.88`, but TCP `26656` still returned connection refused. Freeze remains `FREEZE_DEFER`, and the controlled external-validator testnet remains not launched.

## Phase 18C Launch Operations

Phase 18C adds coordinator-side launch rehearsal and incident response readiness while validator intake remains open.

- incident response: `docs/testnet/CONTROLLED_TESTNET_INCIDENT_RESPONSE.md`;
- launch-day commands: `docs/testnet/CONTROLLED_TESTNET_LAUNCH_DAY_COMMANDS.md`;
- launch-hour evidence script: `scripts/testnet/collect-launch-hour-evidence.sh`;
- genesis publication checklist: `docs/testnet/GENESIS_PUBLICATION_CHECKLIST.md`;
- support triage template: `docs/testnet/VALIDATOR_SUPPORT_TRIAGE_TEMPLATE.md`;
- launch readiness dashboard: `docs/testnet/CONTROLLED_TESTNET_LAUNCH_READINESS_DASHBOARD.md`.

The launch operations pack does not change launch status. The controlled external-validator testnet remains not launched.

## Local Dry-Run Evidence

The launch tooling path passed a local five-validator dry-run:

- height verified: 20;
- validator set count: 5;
- genesis SHA256: `5fc2ad8a76cfee850e33ddf8f94f403b101657f27de6f0c8885021e8b2c74d90`;
- product live flags: false;
- `tendermint show-node-id` and `comet show-node-id`: pass.

See `docs/testnet/PHASE_17A_CONTROLLED_TESTNET_DRY_RUN_RESULTS.md`.

The Phase 18A coordinator candidate also passed a local five-validator dry-run from the generated candidate:

- height verified: 20;
- validator set count: 5;
- genesis SHA256: `b02d00bf63386e44cd46b6ac83f26f072da3f389b50838f7c62c72f2639d9648`;
- product live flags: false;
- REST params queryable;
- readiness monitor: pass against five local RPC/API endpoints;
- panic/fatal log scan: pass;
- `tendermint show-node-id` and `comet show-node-id`: pass.

## Status Rules

- Do not describe the controlled testnet as launched until final genesis is published and accepted external validators are running.
- Do not describe external decentralisation as achieved until external validator operation is evidenced.
- Do not describe NXRL as buyable or having monetary value.
- Keep product live-funds flags false unless a separately reviewed governance process changes them.
