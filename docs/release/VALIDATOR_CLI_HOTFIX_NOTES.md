# Validator CLI Hotfix Notes - `v0.1.0-rc1-cli-hotfix`

**Date:** 2026-05-29
**Scope:** Validator CLI usability only. No protocol, economics, genesis, or live-flag changes.
**Audience:** Operators evaluating NexaRail testnet RC1, candidate external validators, reviewers.

## Issue

An external validator reported that against the `v0.1.0-rc1` release binary:

```text
$ ./nexaraild tendermint show-node-id
Error: unknown command "tendermint" for "nexaraild"
```

The `tendermint` / `comet` / `cometbft` helper command group (Cosmos SDK / CometBFT `server.AddCommands`-style helpers) was not registered on the root command. Validators rely on `tendermint show-node-id` to publish their node identity for peer coordination, so this blocked external validator onboarding.

This applies to both shipped RC1 binaries:

- `releases/testnet-rc1/binaries/nexaraild-darwin-arm64`
- `releases/testnet-rc1/binaries/nexaraild-linux-amd64`

Reproduction:

```bash
./releases/testnet-rc1/binaries/nexaraild-darwin-arm64 tendermint show-node-id
# Error: unknown command "tendermint" for "nexaraild"
```

## Fix

`cmd/nexaraild/cmd/root.go` now wires a `tendermintCommand()` group onto the root command. The group is implemented in `cmd/nexaraild/cmd/tendermint.go` and registers the standard Cosmos SDK v0.47.17 helpers plus the CometBFT reset commands, with `comet` and `cometbft` declared as cobra aliases so all three spellings work.

Sub-commands now exposed:

| Command | Alias paths |
|---|---|
| `nexaraild tendermint show-node-id` | `nexaraild comet show-node-id`, `nexaraild cometbft show-node-id` |
| `nexaraild tendermint show-validator` | `nexaraild comet show-validator`, `nexaraild cometbft show-validator` |
| `nexaraild tendermint show-address` | `nexaraild comet show-address`, `nexaraild cometbft show-address` |
| `nexaraild tendermint version` | `nexaraild comet version`, `nexaraild cometbft version` |
| `nexaraild tendermint unsafe-reset-all` | `nexaraild comet unsafe-reset-all`, `nexaraild cometbft unsafe-reset-all` |
| `nexaraild tendermint reset-state` | `nexaraild comet reset-state`, `nexaraild cometbft reset-state` |
| `nexaraild tendermint bootstrap-state` | `nexaraild comet bootstrap-state`, `nexaraild cometbft bootstrap-state` |

Existing root commands (`init`, `start`, `keys`, `tx`, `query`, `gentx`, `collect-gentxs`, `add-genesis-account`, `export`, `status`, `validator`, `block`, plus the NexaRail product CLI groups for `fees`, `merchant`, `settlement`, `escrow`, `treasury`, `payout`) are unchanged.

## Tests Added

`cmd/nexaraild/cmd/tendermint_test.go` adds five CLI tests:

- `TestRootHasValidatorCommands` - locks in the validator-facing command surface (`tendermint`/`comet`/`cometbft`, `start`, `init`, `keys`, `query`, `tx`, `add-genesis-account`, `gentx`, `collect-gentxs`, `export`, `status`).
- `TestTendermintGroupHasNodeID` - asserts the `tendermint` group exposes `show-node-id`, `show-validator`, `show-address`, `version`, `bootstrap-state`.
- `TestTendermintHelpDoesNotPanic` - runs `tendermint --help` and asserts the output mentions `show-node-id`.
- `TestProductModuleCommandsRemainRegistered` - asserts existing product query/tx command groups (`fees`, `merchant`, `settlement`, `escrow`, `treasury`, `payout`) remain registered.
- `TestShowNodeIDReturnsHex` - initialises a fresh node home in a temp dir, runs `tendermint show-node-id` and `comet show-node-id`, and asserts both return the same 40-char lowercase hex node ID. This is the exact flow external validators run.

Run:

```bash
go test ./cmd/nexaraild/cmd/... -run 'TestRootHasValidatorCommands|TestProductModuleCommandsRemainRegistered|TestTendermintGroupHasNodeID|TestTendermintHelpDoesNotPanic|TestShowNodeIDReturnsHex' -count=1 -v
```

Expected: 5 passed.

## Patched Binaries

Location: `releases/github/v0.1.0-rc1-hotfix-cli/`

| File | SHA256 |
|---|---|
| `nexaraild-darwin-arm64` | `a4bb92a437a07f9b9266792f32b3e282993834bdcc537775bf429e2e64be12ff` |
| `nexaraild-linux-amd64` | `0ffe09b1523a0ee8a860bbd19a402fb08809fa9eac99e9db5b51d8c00e3965a0` |

Source base: `74f63c6c69a8397f7f9c0a9abc0fb68fc76e1dcd` plus the validator CLI hotfix commit.
Build flag: `-ldflags "-X main.Version=0.1.0-rc1-cli-hotfix"`.

Verify locally:

```bash
cd releases/github/v0.1.0-rc1-hotfix-cli
shasum -a 256 -c SHA256SUMS
```

## Validator Instructions

```bash
cd releases/github/v0.1.0-rc1-hotfix-cli
shasum -a 256 -c SHA256SUMS

# Initialise a fresh node home (replace <moniker> and <home>).
./nexaraild-darwin-arm64 init <moniker> --chain-id nexarail-devnet-1 --home <home>

# Read node ID.
./nexaraild-darwin-arm64 tendermint show-node-id --home <home>

# Either alias works:
./nexaraild-darwin-arm64 comet show-node-id --home <home>
./nexaraild-darwin-arm64 cometbft show-node-id --home <home>
```

Linux validators: use `nexaraild-linux-amd64` with the same flags.

Source-build alternative (Go 1.22+):

```bash
git clone https://github.com/Bookings-cpu/nexarail.git
cd nexarail
git checkout <hotfix-tag-or-commit>
make build
./build/nexaraild tendermint show-node-id
```

## Troubleshooting

| Symptom | Cause | Resolution |
|---|---|---|
| `Error: unknown command "tendermint" for "nexaraild"` | RC1 (`v0.1.0-rc1`) binary | Use the hotfix binary or rebuild from the validator CLI hotfix commit/tag or later. |
| `Error: open <home>/config/node_key.json: no such file or directory` | Node home not initialised | Run `nexaraild init <moniker> --chain-id nexarail-devnet-1 --home <home>` first. |
| `comet` and `tendermint` print different output | Different binaries or stale home | They are aliases of the same command in this build; if output differs the wrong binary is on PATH. |

## No Changes To

- Protocol logic, message types, or store keys.
- Economic parameters or fee/treasury/burn splits.
- Genesis file structure or default genesis values.
- Live flags - all `live_enabled` defaults remain `false`.
- Validator set, staking, or governance parameters.
- npm or PyPI publishing status - neither package is published.
- Network state - there is no mainnet, no live testnet, and no external validator cohort.

## Safety Disclaimers

- This binary is for controlled local evaluation only. There is no live public mainnet or external testnet.
- NXRL remains an evaluation denomination only. There is no public distribution, market, exchange venue, or financial offer.
- Participation in evaluation is infrastructure testing only.
- This hotfix does not alter validator distribution status. Accepted external operators remain pending until a coordinated launch is authorised.
- Never share private keys, mnemonics, seed phrases, `priv_validator_key.json`, or `node_key.json` with the coordinator or in support channels.

## Release Route Decision

Recommendation: **A - publish as `v0.1.0-rc1-cli-hotfix` GitHub pre-release** so blocked validator onboarding unblocks immediately. RC2 should still land separately once the canonical one-hour soak rerun and post-fix governance/product-flow replay are complete (see `docs/release/KNOWN_LIMITATIONS_INDEX.md`).

If RC2 is imminent (within the next 24h), roll the same `tendermintCommand()` wiring forward into RC2 and skip the pre-release tag, but only after verifying the RC2 candidate binary itself exposes `tendermint show-node-id`.

Tagging is deferred until reviewer sign-off; binaries are reproducible from the hotfix source state so the tag can be applied when authorised.
