package fees

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
	"github.com/nexarail/chain/x/fees/client/cli"
	"github.com/nexarail/chain/x/fees/keeper"
	"github.com/nexarail/chain/x/fees/types"
)

var (
	_ module.AppModule      = AppModule{}
	_ module.AppModuleBasic = AppModuleBasic{}
)

// ---------------------------------------------------------------------------
// AppModuleBasic
// ---------------------------------------------------------------------------

// AppModuleBasic implements the module.AppModuleBasic interface.
type AppModuleBasic struct{}

// Name returns the module name.
func (AppModuleBasic) Name() string { return types.ModuleName }

// RegisterLegacyAminoCodec registers amino codec.
func (AppModuleBasic) RegisterLegacyAminoCodec(cdc *codec.LegacyAmino) {
	types.RegisterLegacyAminoCodec(cdc)
}

// RegisterInterfaces registers the module interface types.
func (AppModuleBasic) RegisterInterfaces(registry cdctypes.InterfaceRegistry) {
	types.RegisterInterfaces(registry)
}

// DefaultGenesis returns the default genesis state.
func (AppModuleBasic) DefaultGenesis(cdc codec.JSONCodec) json.RawMessage {
	bz, err := json.Marshal(types.DefaultGenesis())
	if err != nil {
		panic(err)
	}
	return bz
}

// ValidateGenesis validates the genesis state.
func (AppModuleBasic) ValidateGenesis(cdc codec.JSONCodec, _ client.TxEncodingConfig, bz json.RawMessage) error {
	var data types.GenesisState
	if err := json.Unmarshal(bz, &data); err != nil {
		return fmt.Errorf("failed to unmarshal fees genesis: %w", err)
	}
	return data.Validate()
}

// RegisterRESTRoutes registers REST routes (none in v1).
func (AppModuleBasic) RegisterRESTRoutes(clientCtx client.Context, rtr *mux.Router) {}

// RegisterGRPCGatewayRoutes registers gRPC gateway routes for the fees module.
func (AppModuleBasic) RegisterGRPCGatewayRoutes(clientCtx client.Context, mux *runtime.ServeMux) {
	common.RegisterQueryRoute(mux, "GET", "/nexarail/fees/v1/params", func() (interface{}, error) {
		qc := types.NewQueryClient(clientCtx)
		return qc.Params(context.Background(), &types.QueryParamsRequest{})
	})
	common.RegisterQueryRoute(mux, "GET", "/nexarail/fees/v1/fee_split", func() (interface{}, error) {
		qc := types.NewQueryClient(clientCtx)
		return qc.FeeSplit(context.Background(), &types.QueryFeeSplitRequest{})
	})
}

// GetTxCmd returns the transaction CLI commands.
func (AppModuleBasic) GetTxCmd() *cobra.Command {
	return cli.GetTxCmd()
}

// GetQueryCmd returns the query CLI commands.
func (AppModuleBasic) GetQueryCmd() *cobra.Command {
	return cli.GetQueryCmd()
}

// ---------------------------------------------------------------------------
// AppModule
// ---------------------------------------------------------------------------

// AppModule implements the module.AppModule interface.
type AppModule struct {
	AppModuleBasic
	keeper keeper.Keeper
}

// NewAppModule creates a new AppModule.
func NewAppModule(keeper keeper.Keeper) AppModule {
	return AppModule{
		AppModuleBasic: AppModuleBasic{},
		keeper:         keeper,
	}
}

// RegisterInvariants registers module invariants.
func (am AppModule) RegisterInvariants(ir sdk.InvariantRegistry) {
	RegisterInvariants(ir, am.keeper)
}

// RegisterServices registers module services.
func (am AppModule) RegisterServices(cfg module.Configurator) {
	keeper.RegisterMsgServer(cfg.MsgServer(), keeper.NewMsgServerImpl(am.keeper))
	keeper.RegisterQueryServer(cfg.QueryServer(), keeper.NewQueryServerImpl(am.keeper))
}

// InitGenesis initializes the genesis state.
func (am AppModule) InitGenesis(ctx sdk.Context, cdc codec.JSONCodec, data json.RawMessage) []abci.ValidatorUpdate {
	var genesisState types.GenesisState
	if err := json.Unmarshal(data, &genesisState); err != nil {
		panic(fmt.Errorf("failed to unmarshal fees genesis: %w", err))
	}

	if err := am.keeper.SetParams(ctx, genesisState.Params); err != nil {
		panic(fmt.Errorf("failed to set fees genesis params: %w", err))
	}

	return []abci.ValidatorUpdate{}
}

// ExportGenesis exports the genesis state.
func (am AppModule) ExportGenesis(ctx sdk.Context, cdc codec.JSONCodec) json.RawMessage {
	params := am.keeper.GetParams(ctx)
	bz, err := json.Marshal(&types.GenesisState{Params: params})
	if err != nil {
		panic(err)
	}
	return bz
}

// ConsensusVersion implements AppModule.
func (AppModule) ConsensusVersion() uint64 { return 1 }

// BeginBlock processes begin block (no-op for v1).
func (am AppModule) BeginBlock(ctx sdk.Context, req abci.RequestBeginBlock) {}

// EndBlock processes end block (no-op for v1).
func (am AppModule) EndBlock(ctx sdk.Context, req abci.RequestEndBlock) []abci.ValidatorUpdate {
	return []abci.ValidatorUpdate{}
}

// ---------------------------------------------------------------------------
// Invariants
// ---------------------------------------------------------------------------

// RegisterInvariants registers the fees module invariants.
func RegisterInvariants(ir sdk.InvariantRegistry, k keeper.Keeper) {
	ir.RegisterRoute(types.ModuleName, "shares-total",
		SharesTotalInvariant(k))
}

// SharesTotalInvariant checks that the fee split shares total exactly 10000 bps.
func SharesTotalInvariant(k keeper.Keeper) sdk.Invariant {
	return func(ctx sdk.Context) (string, bool) {
		params := k.GetParams(ctx)
		total := params.ValidatorShareBps + params.TreasuryShareBps + params.BurnShareBps
		broken := total != types.BasisPointsMax
		return sdk.FormatInvariant(
			types.ModuleName, "shares-total",
			fmt.Sprintf("Fee split shares total %d, expected %d", total, types.BasisPointsMax),
		), broken
	}
}
