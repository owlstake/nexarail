# Phase 17C First External Gentx Verification

**Date:** 2026-05-29
**Network:** `nexarail-testnet-1`
**Status:** blocked pending NodeSync gentx JSON file content

## NodeSync Submission Summary

| Field | Value |
|---|---|
| validator_id | `nodesync` |
| moniker | `NODESYNC` |
| contact | `info@nodesync.top` |
| operator address | `nxrvaloper182fzt70uwg5sglwm6upagfr4gvp3sjayyfg9yn` |
| account address | `nxr182fzt70uwg5sglwm6upagfr4gvp3sjay33wx28` |
| node ID | `2bb62d82b4dbf820fdafd843816f1e72a84ffa8f` |
| public host | `nexarail-testnet-peer.nodesync.top` |
| P2P port | `26656` |
| OS/arch | `Ubuntu 24.04.4 LTS` |
| build tag | `v0.1.0-rc1-cli-hotfix` |
| gentx filename | `gentx-2bb62d82b4dbf820fdafd843816f1e72a84ffa8f.json` |
| claimed gentx SHA256 | `fbf829ef28330323d6850f89b7219f2d43a47e98ecce91ba16e46aef94566601` |

## SHA256 Result

SHA256 was not verified because the gentx JSON file content is not present in the local workspace.

Expected local path:

```text
coordination/validators/gentxs/gentx-2bb62d82b4dbf820fdafd843816f1e72a84ffa8f.json
```

## Gentx Verification Result

Gentx verification was not run because the gentx JSON file is missing locally. The coordinator must not recreate, infer, or edit the validator gentx.

## Acceptance Result

```text
PENDING_GENTX_FILE
```

NodeSync metadata and P2P endpoint are recorded in the tracker and endpoint inventory. The validator intake registry is not updated with an accepted row until the gentx file content is received and its SHA256 matches the submitted hash.

## Persistent Peer Entry

The reported P2P endpoint is:

```text
2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656
```

Final persistent peers are still not generated from accepted intake records because the gentx has not been verified.

## Documentation Bug Fixed

Validator documentation now includes the required local gentx-preparation step before `gentx`:

```bash
./build/nexaraild add-genesis-account <key-name-or-address> 1000000000unxrl \
  --home "$NXR_HOME" \
  --keyring-backend test
```

This is local preparation only. Final coordinator genesis is assembled separately from accepted gentxs. Validators must not send private keys, mnemonics, node keys, validator signing keys, keyring files, SSH keys, or node data.

## Genesis Candidate Status

No preliminary external genesis candidate was assembled. The first external gentx cannot be verified until the original gentx JSON file content is available.

Final public genesis remains not assembled and the freeze decision remains `FREEZE_DEFER`.

## Launch Status

Controlled external-validator testnet remains **NOT LAUNCHED**. Mainnet remains **NO-GO**. External decentralisation is not claimed. NXRL is not presented as buyable and no monetary value is implied. No token sale is announced or implied. Product live-funds flags remain false by default.

## Next Action

Request that NodeSync resend or upload the exact gentx JSON file:

```text
gentx-2bb62d82b4dbf820fdafd843816f1e72a84ffa8f.json
```

After receipt, verify:

```bash
shasum -a 256 coordination/validators/gentxs/gentx-2bb62d82b4dbf820fdafd843816f1e72a84ffa8f.json
scripts/testnet/validate-validator-intake.sh
scripts/testnet/verify-controlled-testnet-gentx.sh coordination/validators/gentxs/gentx-2bb62d82b4dbf820fdafd843816f1e72a84ffa8f.json
```
