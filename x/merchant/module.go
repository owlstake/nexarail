package merchant

import (
	"context"
	"encoding/json"
	"fmt"
	abci "github.com/cometbft/cometbft/abci/types"
	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/codec"
	cdctypes "github.com/cosmos/cosmos-sdk/codec/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/module"
	"github.com/gorilla/mux"
	"github.com/grpc-ecosystem/grpc-gateway/runtime"
	"github.com/spf13/cobra"
	"github.com/nexarail/chain/x/common"
	"github.com/nexarail/chain/x/merchant/client/cli"
	"github.com/nexarail/chain/x/merchant/keeper"
	"github.com/nexarail/chain/x/merchant/types"
)

var (
	_ module.AppModule      = AppModule{}
	_ module.AppModuleBasic = AppModuleBasic{}
)

// --- AppModuleBasic ---

type AppModuleBasic struct{}

func (AppModuleBasic) Name() string { return types.ModuleName }

func (AppModuleBasic) RegisterLegacyAminoCodec(cdc *codec.LegacyAmino) {
	types.RegisterLegacyAminoCodec(cdc)
}

func (AppModuleBasic) RegisterInterfaces(registry cdctypes.InterfaceRegistry) {
	types.RegisterInterfaces(registry)
}

func (AppModuleBasic) DefaultGenesis(cdc codec.JSONCodec) json.RawMessage {
	bz, err := json.Marshal(types.DefaultGenesis())
	if err != nil {
		panic(err)
	}
	return bz
}

func (AppModuleBasic) ValidateGenesis(cdc codec.JSONCodec, _ client.TxEncodingConfig, bz json.RawMessage) error {
	var data types.GenesisState
	if err := json.Unmarshal(bz, &data); err != nil {
		return fmt.Errorf("merchant genesis unmarshal: %w", err)
	}
	return data.Validate()
}

func (AppModuleBasic) RegisterRESTRoutes(_ client.Context, _ *mux.Router)              {}
func (AppModuleBasic) RegisterGRPCGatewayRoutes(clientCtx client.Context, mux *runtime.ServeMux) {
	common.RegisterQueryRoute(mux, "GET", "/nexarail/merchant/v1/params", func() (interface{}, error) {
		qc := types.NewQueryClient(clientCtx)
		return qc.Params(context.Background(), &types.QueryParamsRequest{})
	})
	common.RegisterQueryRoute(mux, "GET", "/nexarail/merchant/v1/merchants", func() (interface{}, error) {
		qc := types.NewQueryClient(clientCtx)
		return qc.Merchants(context.Background(), &types.QueryMerchantsRequest{})
	})
}

func (AppModuleBasic) GetTxCmd() *cobra.Command {
	return cli.GetTxCmd()
}

func (AppModuleBasic) GetQueryCmd() *cobra.Command {
	return cli.GetQueryCmd()
}

// --- AppModule ---

type AppModule struct {
	AppModuleBasic
	keeper keeper.Keeper
}

func NewAppModule(k keeper.Keeper) AppModule {
	return AppModule{AppModuleBasic: AppModuleBasic{}, keeper: k}
}

func (am AppModule) RegisterInvariants(ir sdk.InvariantRegistry) {
	// No invariants for v1
}

func (am AppModule) RegisterServices(cfg module.Configurator) {
	keeper.RegisterMsgServer(cfg.MsgServer(), keeper.NewMsgServerImpl(am.keeper))
	keeper.RegisterQueryServer(cfg.QueryServer(), keeper.NewQueryServerImpl(am.keeper))
}

func (am AppModule) InitGenesis(ctx sdk.Context, cdc codec.JSONCodec, data json.RawMessage) []abci.ValidatorUpdate {
	var gs types.GenesisState
	if err := json.Unmarshal(data, &gs); err != nil {
		panic(fmt.Errorf("merchant genesis unmarshal: %w", err))
	}
	if err := am.keeper.SetParams(ctx, gs.Params); err != nil {
		panic(fmt.Errorf("merchant genesis params: %w", err))
	}
	for _, m := range gs.Merchants {
		if err := am.keeper.SetMerchant(ctx, m); err != nil {
			panic(fmt.Errorf("merchant genesis record %s: %w", m.Owner, err))
		}
	}
	return []abci.ValidatorUpdate{}
}

func (am AppModule) ExportGenesis(ctx sdk.Context, cdc codec.JSONCodec) json.RawMessage {
	params := am.keeper.GetParams(ctx)
	merchants := am.keeper.GetAllMerchants(ctx)
	bz, err := json.Marshal(&types.GenesisState{Params: params, Merchants: merchants})
	if err != nil {
		panic(err)
	}
	return bz
}

func (AppModule) ConsensusVersion() uint64                                  { return 1 }
func (am AppModule) BeginBlock(ctx sdk.Context, req abci.RequestBeginBlock) {}
func (am AppModule) EndBlock(ctx sdk.Context, req abci.RequestEndBlock) []abci.ValidatorUpdate {
	return []abci.ValidatorUpdate{}
}
