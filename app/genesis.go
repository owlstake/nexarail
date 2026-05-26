package app

import (
	"encoding/json"

	"github.com/cosmos/cosmos-sdk/codec"
)

// GenesisState of the NexaRail chain is a map from module name to raw genesis JSON.
type GenesisState map[string]json.RawMessage

// NewDefaultGenesisState generates the default state for all registered modules.
func NewDefaultGenesisState() GenesisState {
	cfg := MakeEncodingConfig()
	return ModuleBasics.DefaultGenesis(cfg.Codec)
}

// GenesisStateFromAppState returns the GenesisState cast for a given app state.
func GenesisStateFromAppState(cdc codec.JSONCodec, appState json.RawMessage) GenesisState {
	genesisState := make(GenesisState)
	if err := json.Unmarshal(appState, &genesisState); err != nil {
		panic(err)
	}
	return genesisState
}
