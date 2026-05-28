# NexaRail RC1 Devnet — Write-Flow Shell Examples

## ⚠️ CRITICAL SAFETY NOTICE

**ALL SCRIPTS IN THIS DIRECTORY ARE FOR LOCAL DEVNET USE ONLY.**

- ❌ **NOT mainnet** — No mainnet exists. NexaRail is a sovereign Layer 1 blockchain at the controlled testnet stage.
- ❌ **NOT a public testnet** — These scripts target a single-node local devnet or a 5-agent controlled testnet.
- ❌ **Tokens have zero monetary value** — The `unxrl` denomination (`NXRL`) is a devnet-only test token. It has no market value and never will.
- 🔑 **Use test keys only** — Never use production keys, seed phrases, or hardware wallets.
- 🚫 **No token sale** — NexaRail has never conducted a token sale. Any claim otherwise is a scam.

## Overview

These shell scripts demonstrate the six NexaRail product write-flows against a running RC1 devnet:

| Script | Flow | Module |
|---|---|---|
| `bank_send_smoke.sh` | Simple token transfer between dev accounts | `bank` |
| `merchant_register.sh` | Register a merchant with registration fee | `merchant` |
| `settlement_metadata.sh` | Create a settlement record (metadata mode) | `settlement` |
| `escrow_lifecycle.sh` | Create an escrow and release it | `escrow` |
| `treasury_spend.sh` | Create a treasury spend request (metadata) | `treasury` |
| `payout_lifecycle.sh` | Create a payout and mark it paid (metadata) | `payout` |
| `governance_toggle_demo.sh` | Toggle live flags via governance proposal | `gov` |

## Prerequisites

1. **RC1 devnet is running** — Run `releases/testnet-rc1/scripts/launch-rc1-devnet.sh` first.
2. **Binary exists** — The scripts auto-detect `nexaraild-darwin-arm64` (macOS) or `nexaraild-linux-amd64` (Linux).
3. **`jq` is installed** — Used for JSON parsing.
4. **`curl` is available** — Used for devnet liveness checks.

## Dry-Run Mode (Default)

By default, all scripts operate in **dry-run mode**: they print the commands they *would* execute but do not submit any transactions to the chain.

```
$ ./bank_send_smoke.sh
```

This is safe to run at any time, even against a production network (not that one exists).

## Execute Mode

Pass `--execute` to actually submit transactions:

⚠️ **WARNING:** Only run with `--execute` against your local devnet. The scripts use `--keyring-backend test` and will sign and broadcast real transactions.

```
$ ./bank_send_smoke.sh --execute
```

## Overrides

All scripts support these overrides:

| Flag | Default | Description |
|---|---|---|
| `--binary <path>` | Auto-detected | Override the nexaraild binary path |
| `--home <path>` | `~/.nexarail-devnet` | Override the keyring/data home directory |
| `--chain-id <name>` | `nexarail-devnet-1` | Override chain ID |
| `--rpc <url>` | `http://127.0.0.1:26657` | Override Tendermint RPC endpoint |

## Evidence

When run with `--execute`, scripts write evidence to:

```
rehearsals/developer-write-flows/evidence/<timestamp>/
```

Evidence includes submitted commands, tx hashes, and state queries for verification.

## Smoke Test Runner

Run all write-flow scripts in sequence:

```bash
scripts/dev/run-write-flow-examples-smoke.sh
```

Pass `--execute` to actually submit transactions (see warning above).

## Live Flag Defaults

All live flags are `false` on the RC1 devnet:

| Flag | Default | Effect |
|---|---|---|
| `settlement.live_enabled` | `false` | Settlement records only (no fund movement) |
| `settlement.treasury_routing_enabled` | `false` | No treasury fee routing |
| `settlement.burn_routing_enabled` | `false` | No burn routing |
| `escrow.live_enabled` | `false` | Escrow metadata only (no fund custody) |
| `treasury.live_enabled` | `false` | Treasury metadata only (no actual spend) |
| `payout.live_enabled` | `false` | Payout metadata only (no actual transfer) |

## Governance Toggle Warning

The `governance_toggle_demo.sh` script can enable/disable live flags via governance proposal. **Toggling live flags changes devnet behavior** — escrows will move funds, payouts will send tokens, etc. Only toggle if you understand the consequences.
