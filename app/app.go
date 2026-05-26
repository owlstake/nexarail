package app

import (
	"encoding/json"
	"io"
	"os"
	"path/filepath"

	dbm "github.com/cometbft/cometbft-db"
	abci "github.com/cometbft/cometbft/abci/types"
	tmproto "github.com/cometbft/cometbft/proto/tendermint/types"
	"github.com/cometbft/cometbft/libs/log"
	gogogrpc "github.com/cosmos/gogoproto/grpc"

	"github.com/cosmos/cosmos-sdk/baseapp"
	"github.com/cosmos/cosmos-sdk/client"
	nodeservice "github.com/cosmos/cosmos-sdk/client/grpc/node"
	"github.com/cosmos/cosmos-sdk/codec"
	"github.com/cosmos/cosmos-sdk/codec/types"
	"github.com/cosmos/cosmos-sdk/server/api"
	"github.com/cosmos/cosmos-sdk/server/config"
	servertypes "github.com/cosmos/cosmos-sdk/server/types"
	"github.com/cosmos/cosmos-sdk/snapshots"
	storetypes "github.com/cosmos/cosmos-sdk/store/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/module"
	"github.com/cosmos/cosmos-sdk/version"
	"github.com/cosmos/cosmos-sdk/x/auth"
	"github.com/cosmos/cosmos-sdk/x/auth/ante"
	authkeeper "github.com/cosmos/cosmos-sdk/x/auth/keeper"
	authtx "github.com/cosmos/cosmos-sdk/x/auth/tx"
	authtypes "github.com/cosmos/cosmos-sdk/x/auth/types"
	"github.com/cosmos/cosmos-sdk/x/auth/vesting"
	vestingtypes "github.com/cosmos/cosmos-sdk/x/auth/vesting/types"
	"github.com/cosmos/cosmos-sdk/x/authz"
	authzkeeper "github.com/cosmos/cosmos-sdk/x/authz/keeper"
	authzmodule "github.com/cosmos/cosmos-sdk/x/authz/module"
	"github.com/cosmos/cosmos-sdk/x/bank"
	bankkeeper "github.com/cosmos/cosmos-sdk/x/bank/keeper"
	banktypes "github.com/cosmos/cosmos-sdk/x/bank/types"
	"github.com/cosmos/cosmos-sdk/x/capability"
	capabilitykeeper "github.com/cosmos/cosmos-sdk/x/capability/keeper"
	capabilitytypes "github.com/cosmos/cosmos-sdk/x/capability/types"
	"github.com/cosmos/cosmos-sdk/x/crisis"
	crisiskeeper "github.com/cosmos/cosmos-sdk/x/crisis/keeper"
	crisistypes "github.com/cosmos/cosmos-sdk/x/crisis/types"
	distr "github.com/cosmos/cosmos-sdk/x/distribution"
	distrkeeper "github.com/cosmos/cosmos-sdk/x/distribution/keeper"
	distrtypes "github.com/cosmos/cosmos-sdk/x/distribution/types"
	"github.com/cosmos/cosmos-sdk/x/evidence"
	evidencekeeper "github.com/cosmos/cosmos-sdk/x/evidence/keeper"
	evidencetypes "github.com/cosmos/cosmos-sdk/x/evidence/types"
	"github.com/cosmos/cosmos-sdk/x/feegrant"
	feegrantkeeper "github.com/cosmos/cosmos-sdk/x/feegrant/keeper"
	feegrantmodule "github.com/cosmos/cosmos-sdk/x/feegrant/module"
	"github.com/cosmos/cosmos-sdk/x/genutil"
	genutiltypes "github.com/cosmos/cosmos-sdk/x/genutil/types"
	"github.com/cosmos/cosmos-sdk/x/gov"
	govkeeper "github.com/cosmos/cosmos-sdk/x/gov/keeper"
	govtypes "github.com/cosmos/cosmos-sdk/x/gov/types"
	govv1 "github.com/cosmos/cosmos-sdk/x/gov/types/v1"
	"github.com/cosmos/cosmos-sdk/x/mint"
	mintkeeper "github.com/cosmos/cosmos-sdk/x/mint/keeper"
	minttypes "github.com/cosmos/cosmos-sdk/x/mint/types"
	"github.com/cosmos/cosmos-sdk/x/params"
	paramskeeper "github.com/cosmos/cosmos-sdk/x/params/keeper"
	paramstypes "github.com/cosmos/cosmos-sdk/x/params/types"
	"github.com/cosmos/cosmos-sdk/x/slashing"
	slashingkeeper "github.com/cosmos/cosmos-sdk/x/slashing/keeper"
	slashingtypes "github.com/cosmos/cosmos-sdk/x/slashing/types"
	"github.com/cosmos/cosmos-sdk/x/staking"
	stakingkeeper "github.com/cosmos/cosmos-sdk/x/staking/keeper"
	stakingtypes "github.com/cosmos/cosmos-sdk/x/staking/types"
	"github.com/cosmos/cosmos-sdk/x/upgrade"
	upgradekeeper "github.com/cosmos/cosmos-sdk/x/upgrade/keeper"
	upgradetypes "github.com/cosmos/cosmos-sdk/x/upgrade/types"

	feessdk "github.com/nexarail/chain/x/fees"
	feeskeeper "github.com/nexarail/chain/x/fees/keeper"
	feestypes "github.com/nexarail/chain/x/fees/types"

	merchantsdk "github.com/nexarail/chain/x/merchant"
	merchantkeeper "github.com/nexarail/chain/x/merchant/keeper"
	merchanttypes "github.com/nexarail/chain/x/merchant/types"

	settlementsdk "github.com/nexarail/chain/x/settlement"
	settlementkeeper "github.com/nexarail/chain/x/settlement/keeper"
	settlementtypes "github.com/nexarail/chain/x/settlement/types"

	escrowsdk "github.com/nexarail/chain/x/escrow"
	escrowkeeper "github.com/nexarail/chain/x/escrow/keeper"
	escrowtypes "github.com/nexarail/chain/x/escrow/types"

	payoutsdk "github.com/nexarail/chain/x/payout"
	payoutkeeper "github.com/nexarail/chain/x/payout/keeper"
	payouttypes "github.com/nexarail/chain/x/payout/types"

	treasurysdk "github.com/nexarail/chain/x/treasury"
	treasurykeeper "github.com/nexarail/chain/x/treasury/keeper"
	treasurytypes "github.com/nexarail/chain/x/treasury/types"
)

const (
	AccountAddressPrefix = "nxr"
	Name                 = "nexarail"

	// Module account names for Phase 5B live fund infrastructure
	NexaRailEscrowModuleAccount    = "nexarail_escrow"
	NexaRailTreasuryModuleAccount  = "nexarail_treasury"
	NexaRailFeeRouterModuleAccount = "nexarail_fee_router"
	NexaRailBurnerModuleAccount    = "nexarail_burner"
)

var DefaultNodeHome = filepath.Join(os.Getenv("HOME"), ".nexarail")

var ModuleBasics = module.NewBasicManager(
	auth.AppModuleBasic{},
	genutil.AppModuleBasic{},
	bank.AppModuleBasic{},
	capability.AppModuleBasic{},
	staking.AppModuleBasic{},
	mint.AppModuleBasic{},
	distr.AppModuleBasic{},
	gov.NewAppModuleBasic(nil),
	params.AppModuleBasic{},
	crisis.AppModuleBasic{},
	slashing.AppModuleBasic{},
	vesting.AppModuleBasic{},
	feegrantmodule.AppModuleBasic{},
	authzmodule.AppModuleBasic{},
	evidence.AppModuleBasic{},
	upgrade.AppModuleBasic{},
	feessdk.AppModuleBasic{},
	merchantsdk.AppModuleBasic{},
	settlementsdk.AppModuleBasic{}, escrowsdk.AppModuleBasic{}, treasurysdk.AppModuleBasic{}, payoutsdk.AppModuleBasic{},
)

var _ servertypes.Application = (*NexaRailApp)(nil)

type NexaRailApp struct {
	*baseapp.BaseApp

	legacyAmino       *codec.LegacyAmino
	appCodec          codec.Codec
	txConfig          client.TxConfig
	interfaceRegistry types.InterfaceRegistry

	keys    map[string]*storetypes.KVStoreKey
	tkeys   map[string]*storetypes.TransientStoreKey
	memKeys map[string]*storetypes.MemoryStoreKey

	AccountKeeper    authkeeper.AccountKeeper
	BankKeeper       bankkeeper.Keeper
	CapabilityKeeper *capabilitykeeper.Keeper
	StakingKeeper    *stakingkeeper.Keeper
	SlashingKeeper   slashingkeeper.Keeper
	MintKeeper       mintkeeper.Keeper
	DistrKeeper      distrkeeper.Keeper
	GovKeeper        *govkeeper.Keeper
	CrisisKeeper     *crisiskeeper.Keeper
	ParamsKeeper     paramskeeper.Keeper
	UpgradeKeeper    *upgradekeeper.Keeper
	EvidenceKeeper   evidencekeeper.Keeper
	FeeGrantKeeper   feegrantkeeper.Keeper
	AuthzKeeper      authzkeeper.Keeper
	FeesKeeper       feeskeeper.Keeper
	MerchantKeeper   merchantkeeper.Keeper
	SettlementKeeper settlementkeeper.Keeper
	EscrowKeeper     escrowkeeper.Keeper
	PayoutKeeper     payoutkeeper.Keeper
	TreasuryKeeper   treasurykeeper.Keeper

	mm *module.Manager
	sm *module.SimulationManager
}

func NewNexaRailApp(
	logger log.Logger,
	db dbm.DB,
	traceStore io.Writer,
	loadLatest bool,
	skipUpgradeHeights map[int64]bool,
	homePath string,
	invCheckPeriod uint,
	encodingConfig EncodingConfig,
	appOpts servertypes.AppOptions,
	baseAppOptions ...func(*baseapp.BaseApp),
) *NexaRailApp {
	appCodec := encodingConfig.Codec
	legacyAmino := encodingConfig.Amino
	interfaceRegistry := encodingConfig.InterfaceRegistry
	txConfig := encodingConfig.TxConfig

	SetBech32Prefix()

	bApp := baseapp.NewBaseApp(Name, logger, db, txConfig.TxDecoder(), baseAppOptions...)
	bApp.SetCommitMultiStoreTracer(traceStore)
	bApp.SetVersion(version.Version)
	bApp.SetInterfaceRegistry(interfaceRegistry)
	bApp.SetTxEncoder(txConfig.TxEncoder())

	// Set up a simple in-memory ParamStore for consensus params.
	// In production, use x/consensus keeper. For devnet/testnet,
	// an in-memory store is sufficient.
	bApp.SetParamStore(&paramStore{})

	app := &NexaRailApp{
		BaseApp:           bApp,
		legacyAmino:       legacyAmino,
		appCodec:          appCodec,
		txConfig:          txConfig,
		interfaceRegistry: interfaceRegistry,
	}

	// Store keys
	app.keys = sdk.NewKVStoreKeys(
		authtypes.StoreKey, banktypes.StoreKey, stakingtypes.StoreKey,
		minttypes.StoreKey, distrtypes.StoreKey, slashingtypes.StoreKey,
		govtypes.StoreKey, paramstypes.StoreKey, upgradetypes.StoreKey,
		evidencetypes.StoreKey, capabilitytypes.StoreKey, feegrant.StoreKey,
		authz.ModuleName, crisistypes.StoreKey, feestypes.StoreKey,
		merchanttypes.StoreKey, settlementtypes.StoreKey, payouttypes.StoreKey, escrowtypes.StoreKey,
		treasurytypes.StoreKey,
	)
	app.tkeys = sdk.NewTransientStoreKeys(paramstypes.TStoreKey)
	app.memKeys = sdk.NewMemoryStoreKeys(capabilitytypes.MemStoreKey)

	maccPerms := map[string][]string{
		authtypes.FeeCollectorName:     nil,
		distrtypes.ModuleName:          nil,
		minttypes.ModuleName:           {authtypes.Minter},
		stakingtypes.BondedPoolName:    {authtypes.Burner, authtypes.Staking},
		stakingtypes.NotBondedPoolName: {authtypes.Burner, authtypes.Staking},
		govtypes.ModuleName:            {authtypes.Burner},
		crisistypes.ModuleName:         nil,
		NexaRailEscrowModuleAccount:    nil,
		NexaRailTreasuryModuleAccount:  nil,
		NexaRailFeeRouterModuleAccount: nil,
		NexaRailBurnerModuleAccount:    {authtypes.Burner},
	}

	blockedAddrs := make(map[string]bool)
	for acc := range maccPerms {
		blockedAddrs[authtypes.NewModuleAddress(acc).String()] = true
	}
	authority := authtypes.NewModuleAddress(govtypes.ModuleName).String()

	// Keepers
	app.AccountKeeper = authkeeper.NewAccountKeeper(
		appCodec, app.keys[authtypes.StoreKey],
		authtypes.ProtoBaseAccount, maccPerms,
		AccountAddressPrefix, authority,
	)
	app.BankKeeper = bankkeeper.NewBaseKeeper(
		appCodec, app.keys[banktypes.StoreKey],
		app.AccountKeeper, blockedAddrs, authority,
	)
	app.CapabilityKeeper = capabilitykeeper.NewKeeper(
		appCodec, app.keys[capabilitytypes.StoreKey],
		app.memKeys[capabilitytypes.MemStoreKey],
	)
	app.StakingKeeper = stakingkeeper.NewKeeper(
		appCodec, app.keys[stakingtypes.StoreKey],
		app.AccountKeeper, app.BankKeeper, authority,
	)
	app.MintKeeper = mintkeeper.NewKeeper(
		appCodec, app.keys[minttypes.StoreKey],
		app.StakingKeeper, app.AccountKeeper, app.BankKeeper,
		authtypes.FeeCollectorName, authority,
	)
	app.DistrKeeper = distrkeeper.NewKeeper(
		appCodec, app.keys[distrtypes.StoreKey],
		app.AccountKeeper, app.BankKeeper, app.StakingKeeper,
		authtypes.FeeCollectorName, authority,
	)
	app.SlashingKeeper = slashingkeeper.NewKeeper(
		appCodec, legacyAmino, app.keys[slashingtypes.StoreKey],
		app.StakingKeeper, authority,
	)
	app.CrisisKeeper = crisiskeeper.NewKeeper(
		appCodec, app.keys[crisistypes.StoreKey],
		invCheckPeriod, app.BankKeeper,
		authtypes.FeeCollectorName, authority,
	)
	app.UpgradeKeeper = upgradekeeper.NewKeeper(
		skipUpgradeHeights, app.keys[upgradetypes.StoreKey],
		appCodec, homePath, app.BaseApp, authority,
	)
	app.FeeGrantKeeper = feegrantkeeper.NewKeeper(
		appCodec, app.keys[feegrant.StoreKey], app.AccountKeeper,
	)
	app.AuthzKeeper = authzkeeper.NewKeeper(
		app.keys[authz.ModuleName], appCodec,
		app.MsgServiceRouter(), app.AccountKeeper,
	)
	evidenceKeeper := evidencekeeper.NewKeeper(
		appCodec, app.keys[evidencetypes.StoreKey],
		app.StakingKeeper, app.SlashingKeeper,
	)
	app.EvidenceKeeper = *evidenceKeeper

	govConfig := govtypes.DefaultConfig()
	app.GovKeeper = govkeeper.NewKeeper(
		appCodec, app.keys[govtypes.StoreKey],
		app.AccountKeeper, app.BankKeeper, app.StakingKeeper,
		app.MsgServiceRouter(), govConfig, authority,
	)
	app.ParamsKeeper = initParamsKeeper(
		appCodec, legacyAmino,
		app.keys[paramstypes.StoreKey], app.tkeys[paramstypes.TStoreKey],
	)

	// Fees keeper
	app.FeesKeeper = feeskeeper.NewKeeper(
		app.keys[feestypes.StoreKey],
		app.AccountKeeper,
		app.BankKeeper,
		authority,
	)

	// Merchant keeper
	app.MerchantKeeper = merchantkeeper.NewKeeper(
		app.keys[merchanttypes.StoreKey],
		app.AccountKeeper,
		app.BankKeeper,
		authority,
	)

	// Settlement keeper
	app.SettlementKeeper = settlementkeeper.NewKeeper(
		app.keys[settlementtypes.StoreKey],
		authority,
		app.MerchantKeeper,
		app.FeesKeeper,
		app.BankKeeper,
	)

	// Escrow keeper
	app.EscrowKeeper = escrowkeeper.NewKeeper(
		app.keys[escrowtypes.StoreKey],
		authority,
		app.MerchantKeeper,
		app.BankKeeper,
	)

	// Payout keeper
	app.PayoutKeeper = payoutkeeper.NewKeeper(
		app.keys[payouttypes.StoreKey],
		authority,
		app.MerchantKeeper,
		app.BankKeeper,
	)

	// Treasury keeper
	app.TreasuryKeeper = treasurykeeper.NewKeeper(
		app.keys[treasurytypes.StoreKey],
		authority,
		app.BankKeeper,
	)

	// Register staking hooks
	app.StakingKeeper.SetHooks(
		stakingtypes.NewMultiStakingHooks(
			app.DistrKeeper.Hooks(),
			app.SlashingKeeper.Hooks(),
		),
	)

	// Subspaces for legacy modules (already registered in initParamsKeeper)
	authSubspace, _ := app.ParamsKeeper.GetSubspace(authtypes.ModuleName)
	bankSubspace, _ := app.ParamsKeeper.GetSubspace(banktypes.ModuleName)
	stakingSubspace, _ := app.ParamsKeeper.GetSubspace(stakingtypes.ModuleName)
	mintSubspace, _ := app.ParamsKeeper.GetSubspace(minttypes.ModuleName)
	distrSubspace, _ := app.ParamsKeeper.GetSubspace(distrtypes.ModuleName)
	slashingSubspace, _ := app.ParamsKeeper.GetSubspace(slashingtypes.ModuleName)
	govSubspace, _ := app.ParamsKeeper.GetSubspace(govtypes.ModuleName)
	crisisSubspace, _ := app.ParamsKeeper.GetSubspace(crisistypes.ModuleName)

	// Module manager
	app.mm = module.NewManager(
		genutil.NewAppModule(app.AccountKeeper, app.StakingKeeper, app.BaseApp.DeliverTx, encodingConfig.TxConfig),
		auth.NewAppModule(appCodec, app.AccountKeeper, nil, authSubspace),
		vesting.NewAppModule(app.AccountKeeper, app.BankKeeper),
		bank.NewAppModule(appCodec, app.BankKeeper, app.AccountKeeper, bankSubspace),
		capability.NewAppModule(appCodec, *app.CapabilityKeeper, false),
		crisis.NewAppModule(app.CrisisKeeper, false, crisisSubspace),
		feegrantmodule.NewAppModule(appCodec, app.AccountKeeper, app.BankKeeper, app.FeeGrantKeeper, app.interfaceRegistry),
		gov.NewAppModule(appCodec, app.GovKeeper, app.AccountKeeper, app.BankKeeper, govSubspace),
		mint.NewAppModule(appCodec, app.MintKeeper, app.AccountKeeper, nil, mintSubspace),
		slashing.NewAppModule(appCodec, app.SlashingKeeper, app.AccountKeeper, app.BankKeeper, app.StakingKeeper, slashingSubspace),
		distr.NewAppModule(appCodec, app.DistrKeeper, app.AccountKeeper, app.BankKeeper, app.StakingKeeper, distrSubspace),
		staking.NewAppModule(appCodec, app.StakingKeeper, app.AccountKeeper, app.BankKeeper, stakingSubspace),
		upgrade.NewAppModule(app.UpgradeKeeper),
		evidence.NewAppModule(app.EvidenceKeeper),
		params.NewAppModule(app.ParamsKeeper),
		authzmodule.NewAppModule(appCodec, app.AuthzKeeper, app.AccountKeeper, app.BankKeeper, app.interfaceRegistry),
		feessdk.NewAppModule(app.FeesKeeper),
		merchantsdk.NewAppModule(app.MerchantKeeper),
		settlementsdk.NewAppModule(app.SettlementKeeper), escrowsdk.NewAppModule(app.EscrowKeeper), treasurysdk.NewAppModule(app.TreasuryKeeper), payoutsdk.NewAppModule(app.PayoutKeeper),
	)

	app.mm.SetOrderInitGenesis(
		capabilitytypes.ModuleName, authtypes.ModuleName, vestingtypes.ModuleName,
		banktypes.ModuleName, distrtypes.ModuleName, stakingtypes.ModuleName,
		slashingtypes.ModuleName, govtypes.ModuleName, minttypes.ModuleName,
		crisistypes.ModuleName, genutiltypes.ModuleName, evidencetypes.ModuleName,
		feegrant.ModuleName, authz.ModuleName, paramstypes.ModuleName, upgradetypes.ModuleName,
		feestypes.ModuleName, merchanttypes.ModuleName, settlementtypes.ModuleName, escrowtypes.ModuleName, treasurytypes.ModuleName, payouttypes.ModuleName,
	)
	app.mm.SetOrderBeginBlockers(
		upgradetypes.ModuleName, capabilitytypes.ModuleName,
		minttypes.ModuleName, distrtypes.ModuleName,
		slashingtypes.ModuleName, evidencetypes.ModuleName, stakingtypes.ModuleName,
		authtypes.ModuleName, authz.ModuleName, banktypes.ModuleName,
		crisistypes.ModuleName, feegrant.ModuleName, genutiltypes.ModuleName,
		govtypes.ModuleName, paramstypes.ModuleName, vestingtypes.ModuleName,
		feestypes.ModuleName, merchanttypes.ModuleName, settlementtypes.ModuleName, escrowtypes.ModuleName, treasurytypes.ModuleName, payouttypes.ModuleName,
	)
	app.mm.SetOrderEndBlockers(
		crisistypes.ModuleName, govtypes.ModuleName, stakingtypes.ModuleName,
		authtypes.ModuleName, authz.ModuleName, banktypes.ModuleName,
		capabilitytypes.ModuleName, distrtypes.ModuleName, evidencetypes.ModuleName,
		feegrant.ModuleName, genutiltypes.ModuleName, minttypes.ModuleName,
		paramstypes.ModuleName, slashingtypes.ModuleName, upgradetypes.ModuleName,
		vestingtypes.ModuleName, feestypes.ModuleName, merchanttypes.ModuleName, settlementtypes.ModuleName, escrowtypes.ModuleName, treasurytypes.ModuleName, payouttypes.ModuleName,
	)

	configurator := module.NewConfigurator(app.appCodec, app.MsgServiceRouter(), app.GRPCQueryRouter())
	app.mm.RegisterServices(configurator)

	// Ante handler
	anteHandler, err := ante.NewAnteHandler(ante.HandlerOptions{
		AccountKeeper:   app.AccountKeeper,
		BankKeeper:      app.BankKeeper,
		SignModeHandler: encodingConfig.TxConfig.SignModeHandler(),
		FeegrantKeeper:  app.FeeGrantKeeper,
		SigGasConsumer:  ante.DefaultSigVerificationGasConsumer,
	})
	if err != nil {
		panic(err)
	}
	app.SetAnteHandler(anteHandler)

	app.MountKVStores(app.keys)
	app.MountTransientStores(app.tkeys)
	app.MountMemoryStores(app.memKeys)

	app.SetInitChainer(app.InitChainer)
	app.SetBeginBlocker(app.BeginBlocker)
	app.SetEndBlocker(app.EndBlocker)

	if loadLatest {
		if err := app.LoadLatestVersion(); err != nil {
			panic(err)
		}
	}

	// Simulation manager (minimal for devnet)
	app.sm = module.NewSimulationManager()
	app.sm.RegisterStoreDecoders()

	return app
}

// ABCI methods
func (app *NexaRailApp) Name() string { return app.BaseApp.Name() }

func (app *NexaRailApp) BeginBlocker(ctx sdk.Context, req abci.RequestBeginBlock) abci.ResponseBeginBlock {
	return app.mm.BeginBlock(ctx, req)
}

func (app *NexaRailApp) EndBlocker(ctx sdk.Context, req abci.RequestEndBlock) abci.ResponseEndBlock {
	return app.mm.EndBlock(ctx, req)
}

func (app *NexaRailApp) InitChainer(ctx sdk.Context, req abci.RequestInitChain) abci.ResponseInitChain {
	var genesisState GenesisState
	if err := json.Unmarshal(req.AppStateBytes, &genesisState); err != nil {
		panic(err)
	}
	app.UpgradeKeeper.SetModuleVersionMap(ctx, app.mm.GetVersionMap())
	return app.mm.InitGenesis(ctx, app.appCodec, genesisState)
}

// Utility methods
func (app *NexaRailApp) LoadHeight(height int64) error {
	return app.LoadVersion(height)
}

func (app *NexaRailApp) ModuleAccountAddrs() map[string]bool {
	modAccAddrs := make(map[string]bool)
	for acc := range GetMaccPerms() {
		modAccAddrs[authtypes.NewModuleAddress(acc).String()] = true
	}
	return modAccAddrs
}

func (app *NexaRailApp) LegacyAmino() *codec.LegacyAmino              { return app.legacyAmino }
func (app *NexaRailApp) AppCodec() codec.Codec                        { return app.appCodec }
func (app *NexaRailApp) InterfaceRegistry() types.InterfaceRegistry   { return app.interfaceRegistry }
func (app *NexaRailApp) TxConfig() client.TxConfig                    { return app.txConfig }
func (app *NexaRailApp) SimulationManager() *module.SimulationManager { return app.sm }

// servertypes.Application interface
func (app *NexaRailApp) RegisterAPIRoutes(apiSvr *api.Server, apiConfig config.APIConfig) {
	ModuleBasics.RegisterGRPCGatewayRoutes(apiSvr.ClientCtx, apiSvr.GRPCGatewayRouter)
}

func (app *NexaRailApp) RegisterTxService(clientCtx client.Context) {
	authtx.RegisterTxService(app.BaseApp.GRPCQueryRouter(), clientCtx, app.BaseApp.Simulate, app.interfaceRegistry)
}

func (app *NexaRailApp) RegisterTendermintService(clientCtx client.Context) {
	// handled by tendermint service
}

func (app *NexaRailApp) RegisterNodeService(clientCtx client.Context) {
	nodeservice.RegisterNodeService(clientCtx, app.GRPCQueryRouter())
}

func (app *NexaRailApp) RegisterGRPCServer(srv gogogrpc.Server) {
	// Services are already registered via configurator
}

func (app *NexaRailApp) CommitMultiStore() storetypes.CommitMultiStore {
	return app.BaseApp.CommitMultiStore()
}

func (app *NexaRailApp) SnapshotManager() *snapshots.Manager {
	return nil
}

func (app *NexaRailApp) Close() error {
	return nil
}

func GetMaccPerms() map[string][]string {
	return map[string][]string{
		authtypes.FeeCollectorName:     nil,
		distrtypes.ModuleName:          nil,
		minttypes.ModuleName:           {authtypes.Minter},
		stakingtypes.BondedPoolName:    {authtypes.Burner, authtypes.Staking},
		stakingtypes.NotBondedPoolName: {authtypes.Burner, authtypes.Staking},
		govtypes.ModuleName:            {authtypes.Burner},
		crisistypes.ModuleName:         nil,
		NexaRailEscrowModuleAccount:    nil,
		NexaRailTreasuryModuleAccount:  nil,
		NexaRailFeeRouterModuleAccount: nil,
		NexaRailBurnerModuleAccount:    {authtypes.Burner},
	}
}

func initParamsKeeper(
	appCodec codec.BinaryCodec,
	legacyAmino *codec.LegacyAmino,
	key, tkey storetypes.StoreKey,
) paramskeeper.Keeper {
	paramsKeeper := paramskeeper.NewKeeper(appCodec, legacyAmino, key, tkey)
	paramsKeeper.Subspace(baseapp.Paramspace)
	paramsKeeper.Subspace(authtypes.ModuleName)
	paramsKeeper.Subspace(banktypes.ModuleName)
	paramsKeeper.Subspace(stakingtypes.ModuleName)
	paramsKeeper.Subspace(minttypes.ModuleName)
	paramsKeeper.Subspace(distrtypes.ModuleName)
	paramsKeeper.Subspace(slashingtypes.ModuleName)
	paramsKeeper.Subspace(govtypes.ModuleName).WithKeyTable(govv1.ParamKeyTable())
	paramsKeeper.Subspace(crisistypes.ModuleName)
	return paramsKeeper
}

func SetBech32Prefix() {
	cfg := sdk.GetConfig()
	cfg.SetBech32PrefixForAccount(AccountAddressPrefix, AccountAddressPrefix+"pub")
	cfg.SetBech32PrefixForValidator(AccountAddressPrefix+"valoper", AccountAddressPrefix+"valoperpub")
	cfg.SetBech32PrefixForConsensusNode(AccountAddressPrefix+"valcons", AccountAddressPrefix+"valconspub")
	cfg.SetCoinType(118)
	cfg.SetPurpose(44)
}

// paramStore is a minimal in-memory ParamStore for consensus parameters.
// In production, replace with x/consensus keeper.
type paramStore struct {
	cp *tmproto.ConsensusParams
}

func (ps *paramStore) Get(_ sdk.Context) (*tmproto.ConsensusParams, error) {
	if ps.cp == nil {
		return nil, nil
	}
	return ps.cp, nil
}

func (ps *paramStore) Has(_ sdk.Context) bool {
	return ps.cp != nil
}

func (ps *paramStore) Set(_ sdk.Context, cp *tmproto.ConsensusParams) {
	ps.cp = cp
}
