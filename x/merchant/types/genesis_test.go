package types_test

import (
	"testing"

	"github.com/stretchr/testify/require"

	sdk "github.com/cosmos/cosmos-sdk/types"

	"github.com/nexarail/chain/x/merchant/types"
)

func TestDefaultGenesis(t *testing.T) {
	gs := types.DefaultGenesis()
	require.NotNil(t, gs)
	require.NoError(t, gs.Validate())
	require.Empty(t, gs.Merchants)
}

func TestGenesisWithMerchants(t *testing.T) {
	addr1 := sdk.AccAddress([]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20})
	addr2 := sdk.AccAddress([]byte{2, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20})
	m1 := types.NewMerchant(addr1, "Acme", "desc", "web", 1, 1)
	m2 := types.NewMerchant(addr2, "Beta", "desc", "web", 1, 1)
	gs := types.NewGenesisState(types.DefaultParams(), []types.Merchant{m1, m2})
	require.NoError(t, gs.Validate())
}

func TestGenesisDuplicateMerchant(t *testing.T) {
	addr := sdk.AccAddress([]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20})
	m1 := types.NewMerchant(addr, "Acme", "desc", "web", 1, 1)
	m2 := types.NewMerchant(addr, "Acme Corp", "desc2", "web2", 1, 1)
	gs := types.NewGenesisState(types.DefaultParams(), []types.Merchant{m1, m2})
	err := gs.Validate()
	require.Error(t, err)
	require.Contains(t, err.Error(), "duplicate merchant")
}

func TestGenesisInvalidMerchant(t *testing.T) {
	addr := sdk.AccAddress(make([]byte, 20))
	m := types.NewMerchant(addr, "", "desc", "web", 1, 1)
	gs := types.NewGenesisState(types.DefaultParams(), []types.Merchant{m})
	err := gs.Validate()
	require.Error(t, err)
}
