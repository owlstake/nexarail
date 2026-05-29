# External Validator Coordination Workspace

**Network:** `nexarail-testnet-1`
**Status:** intake open, gentx collection pending

This directory is for non-secret validator coordination files used to assemble the controlled external-validator testnet genesis candidate.

## Layout

| Path | Purpose |
|---|---|
| `validator-intake.csv` | Coordinator registry for submitted validator intake records. |
| `intake/` | Optional non-secret intake forms or exported coordinator records. |
| `gentxs/` | Submitted `gentx-*.json` files awaiting validation. |
| `verified/` | Gentxs and validation summaries that passed coordinator checks. |
| `rejected/` | Rejected gentxs and reason files. |
| `peer-info/` | Generated persistent peer strings and per-validator snippets. |

## Safety Rules

Do not place private keys, mnemonics, node keys, validator signing keys, keyring files, SSH keys, node data, or database files in this directory.

Only store public coordination data needed for the controlled testnet launch candidate: moniker, node ID, public host, P2P port, gentx filename/hash, build tag/commit, OS/arch, and non-sensitive status notes.

The controlled external-validator testnet is not launched until final genesis is published and accepted external validators are running from that genesis.
