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

	"github.com/nexarail/chain/x/merchant/keeper"
	"github.com/nexarail/chain/x/merchant/types"
)

func setupKeeper(t *testing.T) (keeper.Keeper, sdk.Context) {
	t.Helper()
	db := dbm.NewMemDB()
	db2 := dbm.NewMemDB()
	ms := store.NewCommitMultiStore(db)
	key := storetypes.NewKVStoreKey(types.StoreKey)
	ms.MountStoreWithDB(key, storetypes.StoreTypeIAVL, db2)
	require.NoError(t, ms.LoadLatestVersion())
	ctx := sdk.NewContext(ms, tmproto.Header{}, false, log.NewNopLogger())

	ak := &mockAccountKeeper{}
	bk := &mockBankKeeper{}

	k := keeper.NewKeeper(key, ak, bk, authtypes.NewModuleAddress("gov").String())
	return k, ctx
}

type mockAccountKeeper struct{}

func (m *mockAccountKeeper) HasAccount(ctx sdk.Context, addr sdk.AccAddress) bool { return true }

type mockBankKeeper struct {
	sent []sdk.Coins
}

func (m *mockBankKeeper) SendCoinsFromAccountToModule(ctx sdk.Context, senderAddr sdk.AccAddress, recipientModule string, amt sdk.Coins) error {
	m.sent = append(m.sent, amt)
	return nil
}
func (m *mockBankKeeper) SendCoinsFromModuleToAccount(ctx sdk.Context, senderModule string, recipientAddr sdk.AccAddress, amt sdk.Coins) error {
	return nil
}

func TestRegisterMerchant(t *testing.T) {
	k, ctx := setupKeeper(t)

	owner := sdk.AccAddress(make([]byte, 20))
	msg := types.NewMsgRegisterMerchant(owner, "Acme Rail", "Transport provider", "https://acme.com")
	err := k.RegisterMerchant(ctx, msg)
	require.NoError(t, err)

	m, found := k.GetMerchant(ctx, owner)
	require.True(t, found)
	require.Equal(t, "Acme Rail", m.Name)
	require.True(t, m.IsActive())
}

func TestRegisterMerchantDuplicate(t *testing.T) {
	k, ctx := setupKeeper(t)

	owner := sdk.AccAddress(make([]byte, 20))
	msg := types.NewMsgRegisterMerchant(owner, "Acme", "desc", "web")
	require.NoError(t, k.RegisterMerchant(ctx, msg))

	err := k.RegisterMerchant(ctx, msg)
	require.Error(t, err)
	require.ErrorIs(t, err, types.ErrMerchantAlreadyExists)
}

func TestGetMerchantNotFound(t *testing.T) {
	k, ctx := setupKeeper(t)
	owner := sdk.AccAddress(make([]byte, 20))
	_, found := k.GetMerchant(ctx, owner)
	require.False(t, found)
}

func TestHasMerchant(t *testing.T) {
	k, ctx := setupKeeper(t)

	owner := sdk.AccAddress(make([]byte, 20))
	require.False(t, k.HasMerchant(ctx, owner))

	msg := types.NewMsgRegisterMerchant(owner, "Acme", "desc", "web")
	require.NoError(t, k.RegisterMerchant(ctx, msg))
	require.True(t, k.HasMerchant(ctx, owner))
}

func TestUpdateMerchant(t *testing.T) {
	k, ctx := setupKeeper(t)

	owner := sdk.AccAddress(make([]byte, 20))
	msg1 := types.NewMsgRegisterMerchant(owner, "Acme", "Transport", "https://acme.com")
	require.NoError(t, k.RegisterMerchant(ctx, msg1))

	msg2 := types.NewMsgUpdateMerchant(owner, "Acme Rail", "Updated", "https://new.com")
	require.NoError(t, k.UpdateMerchant(ctx, msg2))

	m, _ := k.GetMerchant(ctx, owner)
	require.Equal(t, "Acme Rail", m.Name)
	require.Equal(t, "Updated", m.Description)
	require.Equal(t, "https://new.com", m.Website)
}

func TestUpdateMerchantNotFound(t *testing.T) {
	k, ctx := setupKeeper(t)

	owner := sdk.AccAddress(make([]byte, 20))
	msg := types.NewMsgUpdateMerchant(owner, "X", "", "")
	err := k.UpdateMerchant(ctx, msg)
	require.Error(t, err)
	require.ErrorIs(t, err, types.ErrMerchantNotFound)
}

func TestGetAllMerchants(t *testing.T) {
	k, ctx := setupKeeper(t)

	require.Empty(t, k.GetAllMerchants(ctx))

	addr1 := sdk.AccAddress{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20}
	addr2 := sdk.AccAddress{2, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20}

	msg1 := types.NewMsgRegisterMerchant(addr1, "Acme", "d1", "w1")
	msg2 := types.NewMsgRegisterMerchant(addr2, "Beta", "d2", "w2")
	require.NoError(t, k.RegisterMerchant(ctx, msg1))
	require.NoError(t, k.RegisterMerchant(ctx, msg2))

	merchants := k.GetAllMerchants(ctx)
	require.Len(t, merchants, 2)
}

func TestGetParams(t *testing.T) {
	k, ctx := setupKeeper(t)
	p := k.GetParams(ctx)
	require.Equal(t, types.DefaultParams(), p)
}

func TestSetParams(t *testing.T) {
	k, ctx := setupKeeper(t)

	newP := types.DefaultParams()
	newP.MinNameLength = 5
	require.NoError(t, k.SetParams(ctx, newP))

	p := k.GetParams(ctx)
	require.Equal(t, uint32(5), p.MinNameLength)
}

func TestSetInvalidParams(t *testing.T) {
	k, ctx := setupKeeper(t)

	badParams := types.DefaultParams()
	badParams.MinNameLength = 0
	err := k.SetParams(ctx, badParams)
	require.Error(t, err)
}

func TestKeeperAuthority(t *testing.T) {
	k, _ := setupKeeper(t)
	require.NotEmpty(t, k.GetAuthority())
}

// --- Authority-gated operations ---

func TestSetMerchantStatus(t *testing.T) {
	k, ctx := setupKeeper(t)
	owner := sdk.AccAddress([]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20})

	msg := types.NewMsgRegisterMerchant(owner, "Acme", "desc", "web")
	require.NoError(t, k.RegisterMerchant(ctx, msg))

	auth := k.GetAuthority()

	// Set to inactive
	require.NoError(t, k.SetMerchantStatus(ctx, auth, owner.String(), int32(types.MerchantStatusInactive)))
	m, _ := k.GetMerchant(ctx, owner)
	require.Equal(t, int32(types.MerchantStatusInactive), m.Status)

	// Set to closed
	require.NoError(t, k.SetMerchantStatus(ctx, auth, owner.String(), int32(types.MerchantStatusClosed)))
	m, _ = k.GetMerchant(ctx, owner)
	require.True(t, m.IsClosed())
}

func TestSetMerchantStatusUnauthorized(t *testing.T) {
	k, ctx := setupKeeper(t)
	owner := sdk.AccAddress([]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20})

	msg := types.NewMsgRegisterMerchant(owner, "Acme", "desc", "web")
	require.NoError(t, k.RegisterMerchant(ctx, msg))

	err := k.SetMerchantStatus(ctx, "not-authority", owner.String(), 0)
	require.Error(t, err)
	require.ErrorIs(t, err, types.ErrUnauthorized)
}

func TestSetVerificationStatus(t *testing.T) {
	k, ctx := setupKeeper(t)
	owner := sdk.AccAddress([]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20})

	msg := types.NewMsgRegisterMerchant(owner, "Acme", "desc", "web")
	require.NoError(t, k.RegisterMerchant(ctx, msg))

	auth := k.GetAuthority()

	require.NoError(t, k.SetVerificationStatus(ctx, auth, owner.String(), int32(types.VerificationVerified)))
	m, _ := k.GetMerchant(ctx, owner)
	require.Equal(t, int32(types.VerificationVerified), m.VerificationStatus)

	require.NoError(t, k.SetVerificationStatus(ctx, auth, owner.String(), int32(types.VerificationRejected)))
	m, _ = k.GetMerchant(ctx, owner)
	require.Equal(t, int32(types.VerificationRejected), m.VerificationStatus)
}

func TestSetVerificationStatusUnauthorized(t *testing.T) {
	k, ctx := setupKeeper(t)
	owner := sdk.AccAddress([]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20})

	msg := types.NewMsgRegisterMerchant(owner, "Acme", "desc", "web")
	require.NoError(t, k.RegisterMerchant(ctx, msg))

	err := k.SetVerificationStatus(ctx, "not-authority", owner.String(), 0)
	require.Error(t, err)
	require.ErrorIs(t, err, types.ErrUnauthorized)
}

func TestSetRebateTier(t *testing.T) {
	k, ctx := setupKeeper(t)
	owner := sdk.AccAddress([]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20})

	msg := types.NewMsgRegisterMerchant(owner, "Acme", "desc", "web")
	require.NoError(t, k.RegisterMerchant(ctx, msg))

	auth := k.GetAuthority()

	require.NoError(t, k.SetRebateTier(ctx, auth, owner.String(), int32(types.RebateTierGold)))
	m, _ := k.GetMerchant(ctx, owner)
	require.Equal(t, int32(types.RebateTierGold), m.RebateTier)

	require.NoError(t, k.SetRebateTier(ctx, auth, owner.String(), int32(types.RebateTierPlatinum)))
	m, _ = k.GetMerchant(ctx, owner)
	require.Equal(t, int32(types.RebateTierPlatinum), m.RebateTier)
}

func TestSetRebateTierUnauthorized(t *testing.T) {
	k, ctx := setupKeeper(t)
	owner := sdk.AccAddress([]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20})

	msg := types.NewMsgRegisterMerchant(owner, "Acme", "desc", "web")
	require.NoError(t, k.RegisterMerchant(ctx, msg))

	err := k.SetRebateTier(ctx, "not-authority", owner.String(), 0)
	require.Error(t, err)
	require.ErrorIs(t, err, types.ErrUnauthorized)
}

func TestUpdateParams(t *testing.T) {
	k, ctx := setupKeeper(t)
	auth := k.GetAuthority()

	newParams := types.DefaultParams()
	newParams.MinNameLength = 5
	require.NoError(t, k.UpdateParams(ctx, auth, newParams))

	p := k.GetParams(ctx)
	require.Equal(t, uint32(5), p.MinNameLength)
}

func TestUpdateParamsUnauthorized(t *testing.T) {
	k, ctx := setupKeeper(t)

	err := k.UpdateParams(ctx, "not-authority", types.DefaultParams())
	require.Error(t, err)
	require.ErrorIs(t, err, types.ErrUnauthorized)
}

func TestClosedMerchantUpdateRejected(t *testing.T) {
	k, ctx := setupKeeper(t)
	owner := sdk.AccAddress([]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20})

	msg := types.NewMsgRegisterMerchant(owner, "Acme", "desc", "web")
	require.NoError(t, k.RegisterMerchant(ctx, msg))

	auth := k.GetAuthority()
	require.NoError(t, k.SetMerchantStatus(ctx, auth, owner.String(), int32(types.MerchantStatusClosed)))

	updateMsg := types.NewMsgUpdateMerchant(owner, "New Name", "", "")
	err := k.UpdateMerchant(ctx, updateMsg)
	require.Error(t, err)
	require.ErrorIs(t, err, types.ErrMerchantClosed)
}

func TestInitGenesisOwnerIndexRebuild(t *testing.T) {
	k, ctx := setupKeeper(t)

	addr1 := sdk.AccAddress([]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20})
	addr2 := sdk.AccAddress([]byte{2, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20})

	m1 := types.NewMerchant(addr1, "A", "d1", "w1", 1, 1)
	m2 := types.NewMerchant(addr2, "B", "d2", "w2", 1, 1)

	require.NoError(t, k.SetMerchant(ctx, m1))
	require.NoError(t, k.SetMerchant(ctx, m2))

	// Verify both are queryable by owner key
	found1, ok1 := k.GetMerchant(ctx, addr1)
	require.True(t, ok1)
	require.Equal(t, "A", found1.Name)

	found2, ok2 := k.GetMerchant(ctx, addr2)
	require.True(t, ok2)
	require.Equal(t, "B", found2.Name)

	// GetAll should return both
	all := k.GetAllMerchants(ctx)
	require.Len(t, all, 2)
}
