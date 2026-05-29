# Phase 17C First External Gentx Verification

**Date:** 2026-05-29
**Network:** `nexarail-testnet-1`
**Status:** NodeSync gentx accepted; DNS peer confirmed

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
| gentx memo host | `178.104.162.88` |
| P2P port | `26656` |
| OS/arch | `Ubuntu 24.04.4 LTS` |
| build tag | `v0.1.0-rc1-cli-hotfix` |
| gentx filename | `gentx-2bb62d82b4dbf820fdafd843816f1e72a84ffa8f.json` |
| claimed gentx SHA256 | `fbf829ef28330323d6850f89b7219f2d43a47e98ecce91ba16e46aef94566601` |

## SHA256 Result

The canonical gentx copy is saved at:

```text
coordination/validators/gentxs/gentx-2bb62d82b4dbf820fdafd843816f1e72a84ffa8f.json
```

Saved-file SHA256:

```text
fbf829ef28330323d6850f89b7219f2d43a47e98ecce91ba16e46aef94566601
```

Result: **MATCH**.

See `docs/testnet/PHASE_17C1_NODESYNC_SUBMISSION_RECHECK.md` for the local evidence recheck that found the downloaded attachment copy under a renamed filename and confirmed byte-for-byte equality with the canonical gentx.

## Gentx Verification Result

`scripts/testnet/verify-controlled-testnet-gentx.sh` passed:

- valid JSON;
- moniker `NODESYNC`;
- self-delegation `500000000unxrl`;
- operator address present;
- delegator address present;
- consensus pubkey present and ed25519;
- no private key material patterns;
- no product live-flag changes.

The verifier emitted one warning: chain ID is not embedded in the gentx JSON, so `collect-gentxs` validates the signature against the genesis chain ID.

## Acceptance Result

```text
ACCEPTED
```

NodeSync has been added to `coordination/validators/validator-intake.csv`. The verified gentx is copied to `coordination/validators/verified/`.

## Persistent Peer Entry

Generated peer entry using the confirmed DNS endpoint:

```text
2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656
```

The gentx memo contains a direct IP:

```text
2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@178.104.162.88:26656
```

The generated peer uses confirmed DNS `nexarail-testnet-peer.nodesync.top:26656`. The memo IP is retained as a noted difference for operator awareness.

## Documentation Bug Fixed

Validator documentation now includes the required local gentx-preparation step before `gentx`:

```bash
./build/nexaraild add-genesis-account <key-name-or-address> 1000000000unxrl \
  --home "$NXR_HOME" \
  --keyring-backend test
```

This is local preparation only. Final coordinator genesis is assembled separately from accepted gentxs. Validators must not send private keys, mnemonics, node keys, validator signing keys, keyring files, SSH keys, or node data.

## Genesis Candidate Status

No preliminary or final public genesis candidate was assembled in this step. One external gentx is now verified, but final public genesis remains deferred pending coordinator launch criteria.

Freeze decision remains `FREEZE_DEFER`.

## Launch Status

Controlled external-validator testnet remains **NOT LAUNCHED**. Mainnet remains **NO-GO**. External decentralisation is not claimed. NXRL is not presented as buyable and no monetary value is implied. No token sale is announced or implied. Product live-funds flags remain false by default.

## Next Action

Continue validator intake and re-run the final genesis freeze gate when coordinator launch criteria are satisfied. Current confirmed persistent peer:

```text
2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656
```
