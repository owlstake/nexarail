package types

import (
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestDefaultGenesis(t *testing.T) {
	gs := DefaultGenesis()
	require.NotNil(t, gs)
	require.NotNil(t, gs.Params)
}

func TestDefaultGenesisValidJSON(t *testing.T) {
	gs := DefaultGenesis()
	b, err := json.Marshal(gs)
	require.NoError(t, err)
	require.NotEmpty(t, b)

	var decoded GenesisState
	err = json.Unmarshal(b, &decoded)
	require.NoError(t, err)
}

func TestValidateGenesis_Valid(t *testing.T) {
	gs := DefaultGenesis()
	err := gs.Validate()
	require.NoError(t, err)
}

func TestValidateGenesis_Empty(t *testing.T) {
	gs := GenesisState{}
	err := gs.Validate()
	require.Error(t, err)
}

func TestModuleName(t *testing.T) {
	require.NotEmpty(t, ModuleName)
}
