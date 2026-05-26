package app

import (
	"encoding/json"
	"log"

	tmproto "github.com/cometbft/cometbft/proto/tendermint/types"

	servertypes "github.com/cosmos/cosmos-sdk/server/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	staking "github.com/cosmos/cosmos-sdk/x/staking"
)

// ExportAppStateAndValidators exports the state of the application for a restart.
func (app *NexaRailApp) ExportAppStateAndValidators(
	forZeroHeight bool,
	jailAllowedAddrs []string,
	modulesToExport []string,
) (servertypes.ExportedApp, error) {
	ctx := app.NewContext(false, tmproto.Header{})

	genState := app.mm.ExportGenesis(ctx, app.appCodec)
	appState, err := json.MarshalIndent(genState, "", "  ")
	if err != nil {
		return servertypes.ExportedApp{}, err
	}

	validators, err := staking.WriteValidators(ctx, app.StakingKeeper)
	if err != nil {
		return servertypes.ExportedApp{}, err
	}

	return servertypes.ExportedApp{
		AppState:        appState,
		Validators:      validators,
		Height:          ctx.BlockHeight(),
		ConsensusParams: app.BaseApp.GetConsensusParams(ctx),
	}, nil
}

// prepForZeroHeightGenesis prepares the application for a zero-height genesis.
func (app *NexaRailApp) prepForZeroHeightGenesis(ctx sdk.Context, jailAllowedAddrs []string) {
	log.Println("prepForZeroHeightGenesis: not implemented for devnet")
}
