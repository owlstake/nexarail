package types_test

import (
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/nexarail/chain/x/settlement/types"
)

func TestDefaultGenesis(t *testing.T) {
	gs := types.DefaultGenesis()
	require.NotNil(t, gs)
	require.NoError(t, gs.Validate())
	require.Empty(t, gs.Settlements)
}

func TestGenesisWithSettlements(t *testing.T) {
	s := types.NewSettlement(1, addr1().String(), addr1().String(), "merchant-1", addr1().String(),
		coin(1000), coin(10), coin(6), coin(2), coin(2), coin(0),
		0, "ref-1", "", "test", 100,
	)
	gs := types.NewGenesisState(types.DefaultParams(), []types.Settlement{s})
	require.NoError(t, gs.Validate())
}

func TestGenesisInvalidParams(t *testing.T) {
	p := types.DefaultParams()
	p.FeeRateBps = 10001
	gs := types.NewGenesisState(p, nil)
	err := gs.Validate()
	require.Error(t, err)
}

func TestGenesisInvalidSettlement(t *testing.T) {
	s := types.Settlement{Id: 1, Payer: "bad-address", Amount: coin(100)}
	gs := types.NewGenesisState(types.DefaultParams(), []types.Settlement{s})
	err := gs.Validate()
	require.Error(t, err)
}
