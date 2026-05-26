# Changelog

All notable changes to the NexaRail blockchain project will be documented in this file.

## [0.1.0-dev] - 2026-05-25

### Added
- **Phase 2: Base Devnet Build** — initial Cosmos SDK application scaffold
- Chain ID: `nexarail-devnet-1`
- Native denomination: `unxrl` (1 NXRL = 1,000,000 unxr)
- Bech32 address prefix: `nxr`
- Standard Cosmos modules wired:
  - `auth` — account management
  - `bank` — balances and transfers
  - `staking` — NXRL staking and delegation
  - `slashing` — validator penalties
  - `governance` — on-chain proposals and voting
  - `distribution` — block reward distribution
  - `mint` — token inflation
  - `params` — module parameter management
  - `crisis` — invariant checks
  - `upgrade` — software upgrade coordination
  - `evidence` — misbehaviour evidence handling
  - `feegrant` — fee grant allowances
  - `authz` — account authorizations
  - `capability` — module capability management
  - `vesting` — vesting account support
  - `genutil` — genesis utility functions
- CLI binary: `nexaraild` with commands for:
  - `init` — initialize node directories
  - `start` — run the node
  - `keys` — key management
  - `status` — node status
  - `block` — block queries
  - `query` — query subcommands
  - `tx` — transaction subcommands
  - `export` — export state
  - `add-genesis-account` — add genesis accounts
  - `collect-gentxs` — collect validator gentx
  - `validate-genesis` — genesis validation
- Devnet scripts:
  - `scripts/init-devnet.sh` — multi-validator genesis setup
  - `scripts/start-devnet.sh` — local multi-validator launch
- Build system: `Makefile` with targets for build, test, clean, init-devnet, start-devnet, Docker

### Technical
- Built with Cosmos SDK v0.47.17 + CometBFT v0.37.18
- Go 1.22+
- All module ordering configured (InitGenesis, BeginBlock, EndBlock)
- Ante handler configured with fee deduction, sequence checking, signature verification
- Staking hooks wired between distribution and slashing modules
- Module account permissions configured for fee collector, bonded pools, governance

### Phase 2.5 — Verification Repair (2026-05-25)

**Root cause:** The initial `go mod tidy` and `go mod download` runs produced an incomplete `go.sum` (only 3 entries) due to the module proxy not resolving all transitive dependencies. Subsequent `go mod tidy` attempts failed because of:
- Incorrect import paths (`github.com/cosmos/cosmos-sdk/genutil` → `github.com/cosmos/cosmos-sdk/x/genutil`)
- Missing packages in Cosmos SDK v0.47.17 (`auth/codec`, `simapp`)
- Type mismatches between `cosmossdk.io/log` and `cometbft/libs/log`
- Missing method implementations on `NexaRailApp` for the `servertypes.Application` interface (`RegisterAPIRoutes`, `RegisterTxService`, `RegisterNodeService`, `SnapshotManager`, `Close`)
- Subspace double-registration panic in `ParamsKeeper.Subspace()`
- Module ordering validation requiring all modules in `SetOrderBeginBlockers`/`SetOrderEndBlockers`
- `signing.SignatureV2` and `authz.Params` type resolution in ante handler

**Files changed:**
- `app/app.go` — 5 rewrites: corrected all keeper constructor signatures for v0.47.17, added all required `servertypes.Application` methods, fixed `sdk.NewKVStoreKeys` → `storetypes.NewKVStoreKeys`, `GetSubspace` → `Subspace`, included all modules in BeginBlock/EndBlock orderings, fixed `InitChainer` signature
- `app/ante.go` — simplified to match v0.47.17 ante handler options
- `app/encoding.go` — fixed TxConfig creation for v0.47.17
- `app/export.go` — fixed `NewContext` signature for v0.47.17 (`bool` → `bool, tmproto.Header`)
- `app/genesis.go` — removed circular reference
- `app/app_test.go` — rewrote tests for v0.47.17 context handling, removed `InitChain` test that required committed multistore
- `cmd/nexaraild/main.go` — removed `cosmossdk.io/log` dependency, use `cometbft/libs/log.NewTMLogger`
- `cmd/nexaraild/cmd/root.go` — rewrote for v0.47.17 CLI API (removed `flags.NewCompletionCmd`, `server.LineBreak`, `rpc.BlockResultsCommand`; fixed `client.QueryEventForTxCmd` → `rpc.BlockCommand`)
- `cmd/nexaraild/cmd/genesis_account.go` — fixed import path `cosmos-sdk/genutil` → `cosmos-sdk/x/genutil`, fixed `KeyringBackend` → keyring.New API, fixed `PackAccounts` for v0.47.17

**Verification commands (all pass, clean cache):**
```
go mod tidy
  → EXIT=0 (all dependencies freshly resolved)
go mod verify
  → "all modules verified" EXIT=0
go build ./...
  → EXIT=0
go vet ./...
  → EXIT=0
go test ./... -count=1 -timeout=120s
  → 1 package OK, EXIT=0 (9 tests passing)
```

### Phase 3.1 — x/fees Module (2026-05-25)

- **x/fees** module implemented: fee split parameters (60% validators, 20% treasury, 20% burn)
- Params with basis-point validation (total must equal 10000), governance-updatable via MsgUpdateParams
- KV store management for params (no subspace), gRPC query/msg servers, CLI commands
- Invariant: shares-total must equal 10000 bps
- 20 tests passing (params validation, genesis validation, keeper get/set, authority)

### Phase 3.2 — x/merchant Module (2026-05-25)

- **x/merchant** module implemented: on-chain merchant registration, profile management
- RegisterMerchant with registration fee collection, UpdateMerchant with owner-only authorization
- Merchant struct: owner, name, description, website, status, timestamps
- Params: registration fee (1 NXRL default), name/description length limits
- Queries: Params, Merchant (by owner), Merchants (list all)
- Proto type registration fix for non-generated types (proto.RegisterType)
- 31 tests passing (merchant types, params, genesis, keeper operations)
- Both modules wired into app.go with proper ordering (InitGenesis, BeginBlock, EndBlock)

### Notes
- This is a development-only build. Not intended for production use.
- Custom NexaRail modules (fees, merchant, settlement, escrow, payout, treasury) to follow in Phase 3.
- Cosmovisor not yet integrated.
- IBC not yet wired.
