package treasury

import (
	"encoding/json"
	abci "github.com/cometbft/cometbft/abci/types"
	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/codec"
	cdctypes "github.com/cosmos/cosmos-sdk/codec/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/module"
	"github.com/gorilla/mux"
	"github.com/grpc-ecosystem/grpc-gateway/runtime"
	"github.com/nexarail/chain/x/treasury/client/cli"
	"github.com/nexarail/chain/x/treasury/keeper"
	"github.com/nexarail/chain/x/treasury/types"
	"github.com/spf13/cobra"
)

var _ module.AppModule = AppModule{}
var _ module.AppModuleBasic = AppModuleBasic{}

type AppModuleBasic struct{}

func (AppModuleBasic) Name() string { return types.ModuleName }
func (AppModuleBasic) RegisterLegacyAminoCodec(cdc *codec.LegacyAmino) {
	types.RegisterLegacyAminoCodec(cdc)
}
func (AppModuleBasic) RegisterInterfaces(r cdctypes.InterfaceRegistry) { types.RegisterInterfaces(r) }
func (AppModuleBasic) DefaultGenesis(cdc codec.JSONCodec) json.RawMessage {
	bz, _ := json.Marshal(types.DefaultGenesis())
	return bz
}
func (AppModuleBasic) ValidateGenesis(cdc codec.JSONCodec, _ client.TxEncodingConfig, bz json.RawMessage) error {
	var gs types.GenesisState
	if err := json.Unmarshal(bz, &gs); err != nil {
		return err
	}
	return gs.Validate()
}
func (AppModuleBasic) RegisterRESTRoutes(_ client.Context, _ *mux.Router)              {}
func (AppModuleBasic) RegisterGRPCGatewayRoutes(_ client.Context, _ *runtime.ServeMux) {}
func (AppModuleBasic) GetTxCmd() *cobra.Command                                        { return cli.GetTxCmd() }
func (AppModuleBasic) GetQueryCmd() *cobra.Command                                     { return cli.GetQueryCmd() }

type AppModule struct {
	AppModuleBasic
	keeper keeper.Keeper
}

func NewAppModule(k keeper.Keeper) AppModule                    { return AppModule{AppModuleBasic{}, k} }
func (am AppModule) RegisterInvariants(_ sdk.InvariantRegistry) {}
func (am AppModule) RegisterServices(cfg module.Configurator) {
	keeper.RegisterMsgServer(cfg.MsgServer(), keeper.NewMsgServerImpl(am.keeper))
	keeper.RegisterQueryServer(cfg.QueryServer(), keeper.NewQueryServerImpl(am.keeper))
}
func (am AppModule) InitGenesis(ctx sdk.Context, cdc codec.JSONCodec, data json.RawMessage) []abci.ValidatorUpdate {
	var gs types.GenesisState
	if err := json.Unmarshal(data, &gs); err != nil {
		panic(err)
	}
	am.keeper.SetParams(ctx, gs.Params)
	for _, a := range gs.Accounts {
		am.keeper.SetTreasuryAccount(ctx, a)
	}
	for _, b := range gs.Budgets {
		am.keeper.SetBudget(ctx, b)
	}
	for _, g := range gs.Grants {
		am.keeper.SetGrant(ctx, g)
	}
	for _, s := range gs.SpendRequests {
		am.keeper.SetSpendRequest(ctx, s)
	}
	am.keeper.RebuildIndexes(ctx)
	return nil
}
func (am AppModule) ExportGenesis(ctx sdk.Context, cdc codec.JSONCodec) json.RawMessage {
	bz, _ := json.Marshal(&types.GenesisState{Params: am.keeper.GetParams(ctx), Accounts: am.keeper.GetAllTreasuryAccounts(ctx), Budgets: am.keeper.GetAllBudgets(ctx), Grants: am.keeper.GetAllGrants(ctx), SpendRequests: am.keeper.GetAllSpendRequests(ctx)})
	return bz
}
func (AppModule) ConsensusVersion() uint64                                  { return 1 }
func (am AppModule) BeginBlock(ctx sdk.Context, req abci.RequestBeginBlock) {}
func (am AppModule) EndBlock(ctx sdk.Context, req abci.RequestEndBlock) []abci.ValidatorUpdate {
	return nil
}
