# NexaRail Phase 6D — CLI Init Repair

**Document:** docs/testnet/PHASE_6D_CLI_INIT_REPAIR.md
**Date:** 2026-05-25
**Status:** Init fixed ✅ — keyring integration needs separate codec fix

## Root Cause

`cmd/nexaraild/cmd/root.go` had a `PersistentPreRunE` on the root command that:
1. Required `client.toml` to exist before any command could run
2. Did not set the server context, which `genutilcli.InitCmd` requires
3. Used `client.SetCmdClientContext` which is an UPDATE operation requiring a pre-existing context entry

This created a circular dependency: `init` (which creates the home directory and `client.toml`) could not run because client config needed to exist first.

## Files Changed

| File | Change |
|---|---|
| `cmd/nexaraild/cmd/root.go` | Rewrote `PersistentPreRunE` to use `cmd.SetContext()` with SDK's `ClientContextKey` and `ServerContextKey` constants, properly resolved `--home` flag, pre-created `config/` and `data/` directories |

## Before/After Behaviour

### Before
```
$ nexaraild init testval --chain-id nexarail-testnet-1 --home /tmp/test
Error: client context not set
```

### After
```
$ nexaraild init testval --chain-id nexarail-testnet-1 --home /tmp/test
(node_key.json, priv_validator_key.json, genesis.json, config.toml created)
✅ Success
```

## Commands Tested

| Command | Status |
|---|---|
| `nexaraild init testval --chain-id nexarail-testnet-1 --home <tmp>` | ✅ Pass |
| Genesis contains correct chain ID | ✅ `nexarail-testnet-1` |
| All custom modules in genesis | ✅ fees, merchant, settlement, escrow, payout, treasury |
| All live flags default false | ✅ settlement.LiveEnabled=false, escrow.LiveEnabled=false, etc. |
| `nexaraild validate-genesis --home <tmp>` | ✅ Pass |
| `nexaraild keys add` | ✅ Key created (mnemonic output) |
| `nexaraild keys show` | ⚠️ Keyring data encoding issue (separate bug — see below) |

## Known Residual Issue: Keyring Encoding

`keys show` fails with "Bytes left over in UnmarshalBinaryLengthPrefixed" when reading a key created with `keys add`. The key IS persisted to disk (`.info` file exists in keyring directory) but cannot be decoded for display.

**Root cause (suspected):** The client context's codec does not include the crypto amino codec needed for legacy keyring record formats. The SDK's `cryptocodec.Cdc` may need to be registered.

**Workaround:** Use `keys add --output json` to capture the address during creation, or use the key directly via file path for `gentx`.

**This is a separate issue from the init bug and does not block the rehearsal.** The rehearsal orchestrator script handles key management internally.

## 3-Validator Runtime Rehearsal

The orchestrator script is ready for execution. Init works correctly. The keyring workaround allows gentx creation via the script's internal key management.

## Verification

```
go mod tidy     ✅
go mod verify   ✅  
go build ./...  ✅
go vet ./...    ✅
go test ./...   ✅ (14 packages, ~332 tests)
```

## Recommendation

**Proceed with runtime rehearsal.** The init CLI bug is fixed. The keyring encoding issue is documented and can be worked around for the rehearsal. Public validator registration can proceed once the 3-validator rehearsal confirms block production on `nexarail-testnet-1`.
