package types_test

import (
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/nexarail/chain/x/fees/types"
)

func TestDefaultGenesis(t *testing.T) {
	gs := types.DefaultGenesis()
	require.NotNil(t, gs)
	err := gs.Validate()
	require.NoError(t, err)
}

func TestGenesisWithDefaultParams(t *testing.T) {
	gs := types.NewGenesisState(types.DefaultParams())
	err := gs.Validate()
	require.NoError(t, err)
}

func TestInvalidGenesis(t *testing.T) {
	params := types.DefaultParams()
	params.FeeCollectorName = ""
	gs := types.NewGenesisState(params)
	err := gs.Validate()
	require.Error(t, err)
	require.Contains(t, err.Error(), "fees genesis params")

	// Also test invalid shares
	params2 := types.DefaultParams()
	params2.ValidatorShareBps = 9999
	gs2 := types.NewGenesisState(params2)
	err = gs2.Validate()
	require.Error(t, err)
}
