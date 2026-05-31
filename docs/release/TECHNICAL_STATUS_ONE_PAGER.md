# NexaRail Technical Status One-Pager

## Release Status
- RC1 is public at tag `v0.1.0-rc1`
- Validator CLI hotfix source tag is public at `v0.1.0-rc1-cli-hotfix`
- Post-RC1 hardening is complete enough for RC2 preparation
- RC2 is under evaluation; tag/release is deferred pending canonical soak and targeted governance replay evidence
- Controlled external-validator testnet launch is **PENDING / NOT LIVE**: final controlled-testnet genesis has been published; coordinator-operated nodes have rehearsed locally only; external-validator block-signing is pending NodeSync remote service start
- Mainnet remains NO-GO; external decentralisation is not claimed until external-validator block-signing is evidenced
- External validators remain pending beyond NodeSync
- Phase 18A internal coordinator candidate and public join-readiness package are prepared
- Phase 18B intake execution is open; final controlled-testnet genesis is published and approved for validator distribution (Phase 17I.0); network-launch decision is deferred until external-validator handshake evidence exists
- Phase 18C coordinator launch operations and incident response pack are prepared
- Phase 17C NodeSync gentx is verified and accepted; DNS peer is confirmed and the memo IP difference is noted
- Phase 17D external-validator genesis candidate is now frozen as the final controlled-testnet genesis at `releases/testnet-genesis/nexarail-testnet-1/` (sha256 `4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095`)
- Phase 17E reachability check confirmed NodeSync DNS resolves but TCP 26656 was refused; Phase 17E.1 clarified the real `nexaraild` service starts after final genesis distribution
- Phase 17F coordinator launch rehearsal with the external candidate genesis passed locally to height 50; the pre-launch local 600-second evidence run exposed the expected local limitation from NodeSync not signing
- Phase 17E.1 candidate genesis denom audit: PASS — `staking.params.bond_denom = unxrl`, all linked denom fields are `unxrl`, no suspicious denom strings; NodeSync's `bond_denom` flag did not reproduce; candidate SHA256 unchanged
- Phase 17H freeze gate `scripts/testnet/check-final-genesis-freeze-gate.sh` reported `PASS=12 FAIL=0 DEFER=1` (only DEFER is live CometBFT handshake) and coordinator authorised genesis publication at `2026-05-30T12:03:32Z`
- Phase 17I.0 (Final Controlled-Testnet Genesis Publication) — final artifacts committed to `releases/testnet-genesis/nexarail-testnet-1/`; raw GitHub links recorded in `docs/testnet/PHASE_17I0_FINAL_GENESIS_PUBLICATION.md`; launch-sign-off `Status: APPROVED_FOR_GENESIS_PUBLICATION`
- Coordinator-operated nodes (local rehearsal): 5 nodes running against final genesis; chain id `nexarail-testnet-1`, height advancing on coordinator machines only; validator set 6, peers 4 (NodeSync slot empty pending remote service start); product live flags false
- NodeSync launch-window packet sent at `coordination/outreach/2026-05-30-nodesync-launch-window.md`
- Launch-hour evidence collector running (local-only rehearsal) at `rehearsals/controlled-testnet/launch-hour/evidence/20260530T121242Z/` (60-min duration, 60-second sampling)

## Architecture
- Cosmos SDK v0.47.x
- CometBFT consensus (single-node devnet)
- 7 custom modules + auth/bank/staking/gov
- REST API gateway on port 1317
- RPC on port 26657

## Modules
| Module | Purpose | live_enabled |
|---|---|---|
| settlement | Record payment metadata | false |
| escrow | Escrow lifecycle management | false |
| merchant | Merchant profile registry | false |
| payout | Payout processing | false |
| treasury | Treasury account management | false |
| fees | Protocol fee distribution | false |
| governance | Product toggle proposals | — |

## RC1 Status
- Build: Go 1.26+, Darwin ARM64 + Linux AMD64
- Binary SHA256: Verified
- Genesis: Preconfigured for single-node
- Denom: unxrl (test token, zero monetary value)
- Voting period: 30 seconds (devnet)
- All live flags: false

## Post-RC1 Hardening
- Phase 14B/14C validation, governance safety, params-event, and error-message hardening completed
- Phase 14D state-transition and invariant tests expanded
- Phase 15A bounded fuzz tests and runtime invariant framework added
- Phase 16A five-agent local runtime validation completed
- Phase 16A.7 governance vote reliability hardened with per-agent RPC voting and retry/sequence refresh
- Phase 16F validator CLI hotfix exposes `tendermint`, `comet`, and `cometbft` helper command groups
- Phase 17A local controlled-testnet dry-run passed with five local validators through height 20
- Phase 17B validator intake workflow is ready; external submissions are pending
- Phase 18A internal coordinator candidate rehearses genesis, peers, monitoring, and launch artifacts while external gentxs remain pending
- Phase 18B tracker, message pack, intake execution doc, and freeze decision are prepared with zero submitted external gentxs
- Phase 18C adds launch-day commands, first-hour evidence capture, incident response, support triage, genesis publication checklist, and readiness dashboard
- Phase 17C records and accepts the first external validator gentx from NodeSync, fixes the required local `add-genesis-account` gentx-preparation step in validator docs, and confirms the DNS peer for persistent peers
- Phase 17D assembles a six-validator review candidate, verifies NodeSync in genesis, and dry-runs the candidate to height 20 without simulating the external validator signing key
- Phase 17E reruns the freeze gate; candidate integrity passes, but NodeSync P2P TCP 26656 returns connection refused
- Phase 17F rehearses coordinator launch operations using the six-validator candidate genesis, reaches height 50 with five coordinator signers, runs launch-hour evidence capture and readiness monitoring locally, records the expected validator-count drift after NodeSync does not sign locally, and keeps launch freeze deferred until NodeSync P2P reachability is confirmed

## Product-Flow Evidence
- Full product-flow suite: 487 pass / 0 fail
- Semantic assertions: 36 pass / 0 fail
- Governance proposals: 22 executed
- Burn supply delta: -2000 unxrl verified
- Event evidence: Collected and indexed

## Local Agent Load Evidence
- Five-agent 120s smoke: 45 / 45 tx included, 208 / 208 queries passed
- Five-agent 10-minute profile: 220 / 220 tx included, 2330 / 2330 queries passed
- Five-agent heavier profile: 876 / 876 tx included, 9020 / 9020 queries passed
- Phase 16D L1: 224 / 224 tx included, 2600 / 2600 queries passed
- Phase 16D L2: 448 / 448 tx included, 5030 / 5030 queries passed
- Phase 16D L3: 515 / 515 tx included, 7300 / 7300 queries passed
- Peer count stable at 4 per node; validator set stable at 5
- Final live flags remained false; no panic, unrecovered CheckTx, descriptor, unknownproto, or gzip errors observed

## Developer Tooling
- Node.js SDK: 18 functions (8 read, 10 command builders)
- Python SDK: 18 functions (8 read, 10 command builders)
- REST examples: 7 scripts covering 36 endpoints
- Write-flow examples: 7 dry-run-safe scripts
- Static dashboard: HTML/JS/CSS, read-only
- Developer portal: 19-section static site

## Regression Status
- Fast regression: 9/9 pass
- SDK package check: 24/24 pass
- Portal check: 6/6 pass
- Dashboard check: 21/21 pass
- Local demo script check: 36/36 pass
- Predeployment code gates: 23/23 pass
- RC1 verification: 37/37 pass
- Phase 16C local load simulation: pass
- Phase 17A controlled-testnet dry-run: pass
- Phase 17B intake validation: waiting for external submissions
- Phase 18A coordinator candidate dry-run: pass, five internal coordinator validators, height 20, live flags false
- Phase 18B/17C intake validation: NodeSync accepted, one verified gentx, DNS peer confirmed
- Phase 17D external-validator genesis candidate: pass, six-validator genesis, height 20 dry-run, live flags false, freeze deferred
- Phase 17E reachability gate: DNS resolves, TCP 26656 connection refused, candidate integrity checks pass, freeze deferred
- Phase 17F coordinator launch rehearsal: dry-run pass, six-validator candidate genesis, height 50, readiness monitor pass, 600-second launch-hour evidence completed with expected validator-count failure from non-simulated NodeSync signer, live flags false, freeze deferred
- Phase 18C launch-hour evidence dry-run: waiting-state capture passes with empty endpoint inventory
- RC2 readiness: under evaluation; expected recommendation is defer until canonical soak and targeted governance replay gates are complete

## Remaining NO-GO Items
- Controlled external-validator testnet launch remains pending NodeSync P2P TCP reachability, launch criteria, final genesis freeze, and launch evidence
- Final public genesis and launch time remain pending
- Final genesis freeze gate remains deferred even with one verified external gentx because final launch criteria are not fully signed off
- Mainnet launch
- External validator activation
- SDK publishing (npm/PyPI)
- Token economics at production scale
- Wallet/private-key integration
