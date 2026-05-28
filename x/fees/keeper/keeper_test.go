package keeper_test

import (
	"testing"

	dbm "github.com/cometbft/cometbft-db"
	"github.com/cometbft/cometbft/libs/log"
	tmproto "github.com/cometbft/cometbft/proto/tendermint/types"
	"github.com/stretchr/testify/require"

	"github.com/cosmos/cosmos-sdk/store"
	storetypes "github.com/cosmos/cosmos-sdk/store/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	authtypes "github.com/cosmos/cosmos-sdk/x/auth/types"

	"github.com/nexarail/chain/x/fees/keeper"
	"github.com/nexarail/chain/x/fees/types"
)

func setupKeeper(t *testing.T) (keeper.Keeper, sdk.Context) {
	t.Helper()

	db := dbm.NewMemDB()
	db2 := dbm.NewMemDB()
	ms := store.NewCommitMultiStore(db)
	keyFees := storetypes.NewKVStoreKey(types.StoreKey)
	ms.MountStoreWithDB(keyFees, storetypes.StoreTypeIAVL, db2)
	err := ms.LoadLatestVersion()
	require.NoError(t, err)

	ctx := sdk.NewContext(ms, tmproto.Header{}, false, log.NewNopLogger())

	ak := &mockAccountKeeper{}
	bk := &mockBankKeeper{}

	k := keeper.NewKeeper(
		keyFees,
		ak,
		bk,
		authtypes.NewModuleAddress("gov").String(),
	)

	return k, ctx
}

type mockAccountKeeper struct{}

func (m *mockAccountKeeper) GetModuleAddress(name string) sdk.AccAddress {
	return authtypes.NewModuleAddress(name)
}
func (m *mockAccountKeeper) GetModuleAccount(ctx sdk.Context, name string) authtypes.ModuleAccountI {
	return nil
}

type mockBankKeeper struct{}

func (m *mockBankKeeper) SendCoinsFromModuleToAccount(ctx sdk.Context, senderModule string, recipientAddr sdk.AccAddress, amt sdk.Coins) error {
	return nil
}
func (m *mockBankKeeper) SendCoinsFromModuleToModule(ctx sdk.Context, senderModule, recipientModule string, amt sdk.Coins) error {
	return nil
}
func (m *mockBankKeeper) BurnCoins(ctx sdk.Context, moduleName string, amt sdk.Coins) error {
	return nil
}
func (m *mockBankKeeper) GetBalance(ctx sdk.Context, addr sdk.AccAddress, denom string) sdk.Coin {
	return sdk.NewInt64Coin("unxrl", 0)
}
func (m *mockBankKeeper) GetAllBalances(ctx sdk.Context, addr sdk.AccAddress) sdk.Coins {
	return sdk.Coins{}
}

func TestKeeperGetSetParams(t *testing.T) {
	k, ctx := setupKeeper(t)

	params := k.GetParams(ctx)
	require.Equal(t, types.DefaultParams(), params)

	newParams := types.DefaultParams()
	newParams.ValidatorShareBps = 7000
	newParams.TreasuryShareBps = 1500
	newParams.BurnShareBps = 1500
	err := k.SetParams(ctx, newParams)
	require.NoError(t, err)

	params = k.GetParams(ctx)
	require.Equal(t, newParams.ValidatorShareBps, params.ValidatorShareBps)
	require.Equal(t, newParams.TreasuryShareBps, params.TreasuryShareBps)
	require.Equal(t, newParams.BurnShareBps, params.BurnShareBps)
}

func TestKeeperParamsInvalidRejected(t *testing.T) {
	k, ctx := setupKeeper(t)

	badParams := types.DefaultParams()
	badParams.ValidatorShareBps = 0
	badParams.TreasuryShareBps = 0
	badParams.BurnShareBps = 0
	err := k.SetParams(ctx, badParams)
	require.Error(t, err)
}

func TestKeeperGetFeeSplit(t *testing.T) {
	k, ctx := setupKeeper(t)

	valBps, treasBps, burnBps := k.GetFeeSplit(ctx)
	require.Equal(t, uint32(6000), valBps)
	require.Equal(t, uint32(2000), treasBps)
	require.Equal(t, uint32(2000), burnBps)
}

func TestKeeperSetThenGetFeeSplit(t *testing.T) {
	k, ctx := setupKeeper(t)

	newParams := types.DefaultParams()
	newParams.ValidatorShareBps = 8000
	newParams.TreasuryShareBps = 1000
	newParams.BurnShareBps = 1000
	err := k.SetParams(ctx, newParams)
	require.NoError(t, err)

	valBps, treasBps, burnBps := k.GetFeeSplit(ctx)
	require.Equal(t, uint32(8000), valBps)
	require.Equal(t, uint32(1000), treasBps)
	require.Equal(t, uint32(1000), burnBps)
}

func TestGetDefaultGenesis(t *testing.T) {
	k, ctx := setupKeeper(t)
	_ = ctx
	gs := k.GetDefaultGenesis()
	require.NotNil(t, gs)
	err := gs.Validate()
	require.NoError(t, err)
}

func TestKeeperAuthority(t *testing.T) {
	k, ctx := setupKeeper(t)
	_ = ctx
	auth := k.GetAuthority()
	require.NotEmpty(t, auth)
}

// Phase 8B: Query edge-case tests

func TestQueryParams_Phase8B(t *testing.T) {
	k, ctx := setupKeeper(t)
	params := types.DefaultParams()
	k.SetParams(ctx, params)

	qs := keeper.NewQueryServerImpl(k)
	resp, err := qs.Params(sdk.WrapSDKContext(ctx), &types.QueryParamsRequest{})
	require.NoError(t, err)
	require.NotNil(t, resp)
}

// =============================================================================
// Phase 8E: Stress Tests — Invariants, Fuzz, Randomized, Failure Injection
// =============================================================================

func TestInvariant_SharesSumTo10000Bps(t *testing.T) {
	k, ctx := setupKeeper(t)
	params := types.DefaultParams()
	k.SetParams(ctx, params)

	v, tr, b := k.GetFeeSplit(ctx)
	require.Equal(t, uint32(10000), v+tr+b, "invariant broken: fee shares must sum to 10000 bps")
}

func TestFailure_FeeSplitInvalidRejected(t *testing.T) {
	k, ctx := setupKeeper(t)
	params := types.DefaultParams()
	params.ValidatorShareBps = 0
	params.TreasuryShareBps = 0
	params.BurnShareBps = 0
	err := k.SetParams(ctx, params)
	require.Error(t, err, "SetParams should reject zero-total shares")
	require.Contains(t, err.Error(), "10000")
}
