# Phase 17I.0 — Final Controlled-Testnet Genesis Publication

**Date:** 2026-05-30
**Network:** `nexarail-testnet-1`
**Status:** PUBLISHED (final controlled-testnet genesis artifacts committed and pushed to `origin/main`)

> **Not mainnet. Not a token sale. NXRL has no monetary value. External decentralisation is not claimed until external-validator block-signing is observed. Product live-funds flags remain `false` by default.**

## 1. Final Genesis Artifact

| Field | Value |
|---|---|
| Final folder | `releases/testnet-genesis/nexarail-testnet-1/` |
| Genesis path | `releases/testnet-genesis/nexarail-testnet-1/genesis.json` |
| Genesis SHA256 | `4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095` |
| Chain ID | `nexarail-testnet-1` |
| Denom | `unxrl` |
| Validator count | 6 (NodeSync + 5 coordinator-operated) |
| Source tag | `v0.1.0-rc1-cli-hotfix` (build commit `3d0d434`) |
| Frozen UTC | `2026-05-30T12:03:32Z` |
| Approved by | Bradley Johnston (coordinator) |
| Mainnet | NO-GO |

## 2. Raw GitHub Download Links (after push to `origin/main`)

- Genesis: `https://raw.githubusercontent.com/Bookings-cpu/nexarail/main/releases/testnet-genesis/nexarail-testnet-1/genesis.json`
- SHA256SUMS: `https://raw.githubusercontent.com/Bookings-cpu/nexarail/main/releases/testnet-genesis/nexarail-testnet-1/SHA256SUMS`
- Manifest: `https://raw.githubusercontent.com/Bookings-cpu/nexarail/main/releases/testnet-genesis/nexarail-testnet-1/manifest.json`
- Persistent peers: `https://raw.githubusercontent.com/Bookings-cpu/nexarail/main/releases/testnet-genesis/nexarail-testnet-1/persistent-peers.txt`

Verification command for downstream validators:

```bash
curl -fLO https://raw.githubusercontent.com/Bookings-cpu/nexarail/main/releases/testnet-genesis/nexarail-testnet-1/genesis.json
shasum -a 256 genesis.json
# expect: 4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095
```

## 3. Persistent Peer

```
2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656
```

Coordinator-operated validator peers are appended at each coordinator startup; they are not committed to the public peer list.

## 4. Included Validators (from `genutil.gen_txs`)

- NodeSync (`2bb62d82b4dbf820fdafd843816f1e72a84ffa8f`) — external operator
- ALPHA, BRAVO, CHARLIE, DELTA, ECHO — coordinator-operated rolling-start validators

## 5. Static Freeze Gate Result

Last `scripts/testnet/check-final-genesis-freeze-gate.sh` run against the candidate path:

- `PASS=12  FAIL=1  DEFER=1`
- `Decision: FREEZE_BLOCKED` — expected post-publication state, because `final-genesis-not-published` now trips (the final folder is populated). All hard integrity checks (`candidate-sha256`, `validate-genesis`, `denom-audit`, `live-flags-false`, `nodesync-gentx-accepted`, `nodesync-in-genesis`, `nodesync-persistent-peer`, `nodesync-host-resolves`, `no-secret-material`, `required-docs`, `coordinator-signoff`) pass.
- Remaining `DEFER`: `cometbft-handshake` — pending NodeSync remote `nexaraild` start at the launch window.
- Evidence: `rehearsals/controlled-testnet/freeze-gate/evidence/20260530T122037Z/`

Static integrity of the published final artifact also verifies independently:

- `shasum -a 256 -c releases/testnet-genesis/nexarail-testnet-1/SHA256SUMS` → `genesis.json: OK`
- `scripts/testnet/check-genesis-denoms.sh --genesis releases/testnet-genesis/nexarail-testnet-1/genesis.json --expected-denom unxrl` → `PASS=7 FAIL=0 WARN=1` (non-blocking empty `bank.denom_metadata`)

## 6. Launch Status

- Controlled external-validator testnet: **NOT LIVE** publicly. Coordinator-operated validators are running locally under `rehearsals/controlled-testnet/launch-hour/evidence/20260530T121242Z/` against this final genesis as a rolling start.
- Public testnet declared LIVE: only after NodeSync starts the real remote `nexaraild` service, the coordinator records a real CometBFT handshake (NodeSync `node_id` in `/net_info`), and at least one block signed by NodeSync is captured.
- Mainnet: **NO-GO**.
- Token sale: **none announced or implied**.
- External decentralisation: **not claimed**.

## 7. Next Required Step

1. Coordinator sends NodeSync the validator launch packet using the raw links above (template in §10 of this doc and the validator copy-paste block in the assistant turn that performed the publication).
2. NodeSync verifies the final genesis SHA, configures `p2p.persistent_peers`, `p2p.laddr`, `p2p.external_address`, and starts `nexaraild` at the published launch-window UTC.
3. Coordinator records the real CometBFT handshake and the first NodeSync-signed block into `rehearsals/controlled-testnet/p2p-launch/evidence/<TIMESTAMP>/`.
4. `docs/testnet/CONTROLLED_TESTNET_STATUS.md` advances the external-validator block-signing line from PENDING to PASS only after step 3.

## 8. Safety Disclaimer

This is a controlled external-validator testnet. It is not mainnet. NXRL has no monetary value, is not for sale, and is not buyable. No investment, profit, APY, returns, or value claim is made. Private keys, mnemonics, and seed phrases must never be shared. Product live-funds flags remain `false` by default. External decentralisation is only claimed once external-validator block-signing is observed and evidenced.
