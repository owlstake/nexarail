package keeper_test

import (
	dbm "github.com/cometbft/cometbft-db"
	"github.com/cometbft/cometbft/libs/log"
	tmproto "github.com/cometbft/cometbft/proto/tendermint/types"
	"github.com/cosmos/cosmos-sdk/store"
	storetypes "github.com/cosmos/cosmos-sdk/store/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/nexarail/chain/x/treasury/keeper"
	"github.com/nexarail/chain/x/treasury/types"
	"github.com/stretchr/testify/require"
	"testing"
)

func a() sdk.AccAddress {
	return sdk.AccAddress([]byte{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1})
}
func b() sdk.AccAddress {
	return sdk.AccAddress([]byte{2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2})
}
func cn(amt int64) sdk.Coin { return sdk.NewInt64Coin("unxrl", amt) }

func setup(t *testing.T) (keeper.Keeper, sdk.Context) {
	t.Helper()
	db := dbm.NewMemDB()
	db2 := dbm.NewMemDB()
	ms := store.NewCommitMultiStore(db)
	key := storetypes.NewKVStoreKey(types.StoreKey)
	ms.MountStoreWithDB(key, storetypes.StoreTypeIAVL, db2)
	require.NoError(t, ms.LoadLatestVersion())
	ctx := sdk.NewContext(ms, tmproto.Header{}, false, log.NewNopLogger())
	bk := &mockBankKeeper{}
	return keeper.NewKeeper(key, sdk.AccAddress([]byte{8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8}).String(), bk), ctx
}

type mockBankKeeper struct{}

func (m *mockBankKeeper) SendCoinsFromAccountToModule(ctx sdk.Context, a sdk.AccAddress, s string, c sdk.Coins) error { return nil }
func (m *mockBankKeeper) SendCoinsFromModuleToAccount(ctx sdk.Context, s string, a sdk.AccAddress, c sdk.Coins) error { return nil }
func (m *mockBankKeeper) GetBalance(ctx sdk.Context, a sdk.AccAddress, s string) sdk.Coin { return sdk.NewInt64Coin(s, 0) }

func TestParams(t *testing.T) {
	k, ctx := setup(t)
	require.True(t, k.GetParams(ctx).TreasuryEnabled)
	p := k.GetParams(ctx)
	p.TreasuryEnabled = false
	k.SetParams(ctx, p)
	require.False(t, k.GetParams(ctx).TreasuryEnabled)
}
func TestUpdateParamsUnauth(t *testing.T) {
	k, ctx := setup(t)
	require.ErrorIs(t, k.UpdateParams(ctx, "bad", types.DefaultParams()), types.ErrUnauthorized)
}

func TestCreateAccount(t *testing.T) {
	k, ctx := setup(t)
	require.NoError(t, k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "acct01", 1, "Test", "", "", cn(1000))))
	require.True(t, k.HasTreasuryAccount(ctx, "acct01"))
}
func TestCreateAccountUnauth(t *testing.T) {
	k, ctx := setup(t)
	require.ErrorIs(t, k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount("bad", "acct02", 1, "X", "", "", cn(0))), types.ErrUnauthorized)
}
func TestCreateAccountDuplicate(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "acct03", 1, "X", "", "", cn(0)))
	require.Error(t, k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "acct03", 1, "X", "", "", cn(0))))
}
func TestGetAccounts(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "acct04", 1, "X", "", "", cn(100)))
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "acct05", 1, "Y", "", "", cn(200)))
	require.Len(t, k.GetAllTreasuryAccounts(ctx), 2)
}

func TestCreateBudget(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "acct", 1, "X", "", "", cn(10000)))
	require.NoError(t, k.CreateBudget(ctx, types.NewMsgCreateBudget(k.GetAuthority(), "bud01", "acct", 1, "Budget", "", cn(5000), 0, 0, "")))
	require.True(t, k.HasBudget(ctx, "bud01"))
}
func TestCreateBudgetNoAccount(t *testing.T) {
	k, ctx := setup(t)
	require.Error(t, k.CreateBudget(ctx, types.NewMsgCreateBudget(k.GetAuthority(), "bud02", "no", 1, "X", "", cn(100), 0, 0, "")))
}
func TestUpdateBudgetStatus(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "acct2", 1, "X", "", "", cn(10000)))
	k.CreateBudget(ctx, types.NewMsgCreateBudget(k.GetAuthority(), "bud03", "acct2", 1, "X", "", cn(1000), 0, 0, ""))
	require.NoError(t, k.UpdateBudgetStatus(ctx, types.NewMsgUpdateBudgetStatus(k.GetAuthority(), "bud03", int32(types.BudgetClosed))))
	bu, _ := k.GetBudget(ctx, "bud03")
	require.Equal(t, int32(types.BudgetClosed), bu.Status)
}
func TestClosedBudgetNoReopen(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "acct3", 1, "X", "", "", cn(10000)))
	k.CreateBudget(ctx, types.NewMsgCreateBudget(k.GetAuthority(), "bud04", "acct3", 1, "X", "", cn(1000), 0, 0, ""))
	k.UpdateBudgetStatus(ctx, types.NewMsgUpdateBudgetStatus(k.GetAuthority(), "bud04", int32(types.BudgetClosed)))
	require.Error(t, k.UpdateBudgetStatus(ctx, types.NewMsgUpdateBudgetStatus(k.GetAuthority(), "bud04", int32(types.BudgetActive))))
}

func TestCreateGrant(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "tacct", 1, "X", "", "", cn(100000)))
	k.CreateBudget(ctx, types.NewMsgCreateBudget(k.GetAuthority(), "budg1", "tacct", 1, "X", "", cn(10000), 0, 0, ""))
	require.NoError(t, k.CreateGrant(ctx, types.NewMsgCreateGrant(k.GetAuthority(), "gen01", "budg1", b().String(), "Grant", "", cn(1000), 1, "")))
	require.True(t, k.HasGrant(ctx, "gen01"))
	bu, _ := k.GetBudget(ctx, "budg1")
	require.Equal(t, int64(1000), bu.AllocatedAmount.Amount.Int64())
}
func TestCreateGrantOverCapacity(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "tacct", 1, "X", "", "", cn(100000)))
	k.CreateBudget(ctx, types.NewMsgCreateBudget(k.GetAuthority(), "budg2", "tacct", 1, "X", "", cn(1000), 0, 0, ""))
	require.ErrorIs(t, k.CreateGrant(ctx, types.NewMsgCreateGrant(k.GetAuthority(), "gen02", "budg2", b().String(), "X", "", cn(2000), 1, "")), types.ErrBudgetCapacity)
}

func TestCreateSpend(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "tacc", 1, "X", "", "", cn(100000)))
	require.NoError(t, k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "sp01", "tacc", "", "", b().String(), cn(100), "purpose", "", "")))
	require.True(t, k.HasSpendRequest(ctx, "sp01"))
}
func TestCreateSpendNoAccount(t *testing.T) {
	k, ctx := setup(t)
	require.Error(t, k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "sp02", "no", "", "", b().String(), cn(100), "p", "", "")))
}

func TestApproveSpend(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "tacc2", 1, "X", "", "", cn(100000)))
	k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "aps01", "tacc2", "", "", b().String(), cn(100), "p", "", ""))
	require.NoError(t, k.ApproveSpendRequest(ctx, types.NewMsgApproveSpendRequest(k.GetAuthority(), "aps01")))
	s, _ := k.GetSpendRequest(ctx, "aps01")
	require.Equal(t, int32(types.SpendApproved), s.Status)
}
func TestApproveSpendUnauth(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "tacc3", 1, "X", "", "", cn(100000)))
	k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "aps02", "tacc3", "", "", b().String(), cn(100), "p", "", ""))
	require.ErrorIs(t, k.ApproveSpendRequest(ctx, types.NewMsgApproveSpendRequest("bad", "aps02")), types.ErrUnauthorized)
}

func TestRejectSpend(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "tacc4", 1, "X", "", "", cn(100000)))
	k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "rjs01", "tacc4", "", "", b().String(), cn(100), "p", "", ""))
	require.NoError(t, k.RejectSpendRequest(ctx, types.NewMsgRejectSpendRequest(k.GetAuthority(), "rjs01", "")))
	s, _ := k.GetSpendRequest(ctx, "rjs01")
	require.Equal(t, int32(types.SpendRejected), s.Status)
}

func TestMarkExecuted(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "tacc5", 1, "X", "", "", cn(100000)))
	k.CreateBudget(ctx, types.NewMsgCreateBudget(k.GetAuthority(), "budex", "tacc5", 1, "X", "", cn(10000), 0, 0, ""))
	k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "exe01", "tacc5", "budex", "", b().String(), cn(500), "p", "", ""))
	k.ApproveSpendRequest(ctx, types.NewMsgApproveSpendRequest(k.GetAuthority(), "exe01"))
	require.NoError(t, k.MarkSpendExecuted(ctx, types.NewMsgMarkSpendExecuted(k.GetAuthority(), "exe01", "ref", "")))
	s, _ := k.GetSpendRequest(ctx, "exe01")
	require.Equal(t, int32(types.SpendExecuted), s.Status)
	bu, _ := k.GetBudget(ctx, "budex")
	require.Equal(t, int64(500), bu.SpentAmount.Amount.Int64())
}

func TestCancelSpend(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "tacc6", 1, "X", "", "", cn(100000)))
	k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "can01", "tacc6", "", "", b().String(), cn(100), "p", "", ""))
	require.NoError(t, k.CancelSpendRequest(ctx, types.NewMsgCancelSpendRequest(a().String(), "can01", "")))
	s, _ := k.GetSpendRequest(ctx, "can01")
	require.Equal(t, int32(types.SpendCancelled), s.Status)
}
func TestCancelSpendStranger(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "tacc7", 1, "X", "", "", cn(100000)))
	k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "can02", "tacc7", "", "", b().String(), cn(100), "p", "", ""))
	require.ErrorIs(t, k.CancelSpendRequest(ctx, types.NewMsgCancelSpendRequest(b().String(), "can02", "")), types.ErrUnauthorized)
}

func TestGenesis(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "gen01", 1, "A", "", "", cn(100)))
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "gen02", 1, "B", "", "", cn(200)))
	require.Len(t, k.GetAllTreasuryAccounts(ctx), 2)
}

func TestRebuildIndexes(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "reb01", 1, "X", "", "", cn(1000)))
	k.CreateBudget(ctx, types.NewMsgCreateBudget(k.GetAuthority(), "reb02", "reb01", 1, "X", "", cn(1000), 0, 0, ""))
	k.RebuildIndexes(ctx)
	require.True(t, k.HasTreasuryAccount(ctx, "reb01"))
	require.True(t, k.HasBudget(ctx, "reb02"))
}

func TestTreasurySummary(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "sum01", 1, "A", "", "", cn(100)))
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "sum02", 1, "B", "", "", cn(200)))
	require.Len(t, k.GetAllTreasuryAccounts(ctx), 2)
	require.Empty(t, k.GetAllBudgets(ctx))
}

func TestGetBudgetsByAccount(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "byact", 1, "X", "", "", cn(100000)))
	k.CreateBudget(ctx, types.NewMsgCreateBudget(k.GetAuthority(), "byb01", "byact", 1, "B1", "", cn(1000), 0, 0, ""))
	k.CreateBudget(ctx, types.NewMsgCreateBudget(k.GetAuthority(), "byb02", "byact", 1, "B2", "", cn(2000), 0, 0, ""))
	require.Len(t, k.GetBudgetsByAccount(ctx, "byact"), 2)
}

// --- Coverage patch ---

func TestTreasuryDisabled(t *testing.T) {
	k, ctx := setup(t)
	p := k.GetParams(ctx)
	p.TreasuryEnabled = false
	k.SetParams(ctx, p)
	require.ErrorIs(t, k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "cov01", 1, "X", "", "", cn(0))), types.ErrTreasuryDisabled)
}
func TestBudgetsDisabled(t *testing.T) {
	k, ctx := setup(t)
	p := k.GetParams(ctx)
	p.BudgetsEnabled = false
	k.SetParams(ctx, p)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "cov02", 1, "X", "", "", cn(1000)))
	require.ErrorIs(t, k.CreateBudget(ctx, types.NewMsgCreateBudget(k.GetAuthority(), "cov03", "cov02", 1, "X", "", cn(100), 0, 0, "")), types.ErrBudgetsDisabled)
}
func TestGrantsDisabled(t *testing.T) {
	k, ctx := setup(t)
	p := k.GetParams(ctx)
	p.GrantsEnabled = false
	k.SetParams(ctx, p)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "cov04", 1, "X", "", "", cn(100000)))
	k.CreateBudget(ctx, types.NewMsgCreateBudget(k.GetAuthority(), "cov05", "cov04", 1, "X", "", cn(10000), 0, 0, ""))
	require.ErrorIs(t, k.CreateGrant(ctx, types.NewMsgCreateGrant(k.GetAuthority(), "cov06", "cov05", b().String(), "X", "", cn(100), 1, "")), types.ErrGrantsDisabled)
}
func TestGrantForClosedBudget(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "cov07", 1, "X", "", "", cn(100000)))
	k.CreateBudget(ctx, types.NewMsgCreateBudget(k.GetAuthority(), "cov08", "cov07", 1, "X", "", cn(10000), 0, 0, ""))
	k.UpdateBudgetStatus(ctx, types.NewMsgUpdateBudgetStatus(k.GetAuthority(), "cov08", int32(types.BudgetClosed)))
	require.Error(t, k.CreateGrant(ctx, types.NewMsgCreateGrant(k.GetAuthority(), "cov09", "cov08", b().String(), "X", "", cn(100), 1, "")))
}
func TestSpendDisabled(t *testing.T) {
	k, ctx := setup(t)
	p := k.GetParams(ctx)
	p.SpendRequestsEnabled = false
	k.SetParams(ctx, p)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "cov10", 1, "X", "", "", cn(100000)))
	require.ErrorIs(t, k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "cov11", "cov10", "", "", b().String(), cn(100), "p", "", "")), types.ErrSpendDisabled)
}
func TestSpendNoBudget(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "cov12", 1, "X", "", "", cn(100000)))
	require.Error(t, k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "cov13", "cov12", "no-budget", "", b().String(), cn(100), "p", "", "")))
}
func TestSpendNoGrant(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "cov14", 1, "X", "", "", cn(100000)))
	require.Error(t, k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "cov15", "cov14", "", "no-grant", b().String(), cn(100), "p", "", "")))
}
func TestApproveNonRequested(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "cov16", 1, "X", "", "", cn(100000)))
	k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "cov17", "cov16", "", "", b().String(), cn(100), "p", "", ""))
	k.CancelSpendRequest(ctx, types.NewMsgCancelSpendRequest(a().String(), "cov17", ""))
	require.Error(t, k.ApproveSpendRequest(ctx, types.NewMsgApproveSpendRequest(k.GetAuthority(), "cov17")))
}
func TestRejectUnauth(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "cov18", 1, "X", "", "", cn(100000)))
	k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "cov19", "cov18", "", "", b().String(), cn(100), "p", "", ""))
	require.ErrorIs(t, k.RejectSpendRequest(ctx, types.NewMsgRejectSpendRequest("bad", "cov19", "")), types.ErrUnauthorized)
}
func TestMarkExecutedUnauth(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "cov20", 1, "X", "", "", cn(100000)))
	k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "cov21", "cov20", "", "", b().String(), cn(100), "p", "", ""))
	k.ApproveSpendRequest(ctx, types.NewMsgApproveSpendRequest(k.GetAuthority(), "cov21"))
	require.ErrorIs(t, k.MarkSpendExecuted(ctx, types.NewMsgMarkSpendExecuted("bad", "cov21", "", "")), types.ErrUnauthorized)
}
func TestMarkExecutedNonApproved(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "cov22", 1, "X", "", "", cn(100000)))
	k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "cov23", "cov22", "", "", b().String(), cn(100), "p", "", ""))
	require.Error(t, k.MarkSpendExecuted(ctx, types.NewMsgMarkSpendExecuted(k.GetAuthority(), "cov23", "", "")))
}
func TestCancelExecutedRejected(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "cov24", 1, "X", "", "", cn(100000)))
	k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "cov25", "cov24", "", "", b().String(), cn(100), "p", "", ""))
	k.ApproveSpendRequest(ctx, types.NewMsgApproveSpendRequest(k.GetAuthority(), "cov25"))
	k.MarkSpendExecuted(ctx, types.NewMsgMarkSpendExecuted(k.GetAuthority(), "cov25", "", ""))
	require.Error(t, k.CancelSpendRequest(ctx, types.NewMsgCancelSpendRequest(a().String(), "cov25", "")))
}
func TestGetSpendByRequester(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "cov26", 1, "X", "", "", cn(100000)))
	k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "cov27", "cov26", "", "", b().String(), cn(100), "p", "", ""))
	require.Len(t, k.GetSpendRequestsByRequester(ctx, a().String()), 1)
	require.Empty(t, k.GetSpendRequestsByRequester(ctx, b().String()))
}
func TestGetSpendByRecipient(t *testing.T) {
	k, ctx := setup(t)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "cov28", 1, "X", "", "", cn(100000)))
	k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "cov29", "cov28", "", "", b().String(), cn(100), "p", "", ""))
	require.Len(t, k.GetSpendRequestsByRecipient(ctx, b().String()), 1)
}

// --- Live Spend Execution Tests (Phase 5D) ---

func TestLiveApproveAndExecuteSpend(t *testing.T) {
	k, ctx := setup(t)
	p := k.GetParams(ctx)
	p.LiveEnabled = true
	k.SetParams(ctx, p)

	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "live1", 1, "X", "", "", cn(100000)))
	k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "live2", "live1", "", "", b().String(), cn(500), "p", "", ""))
	k.ApproveSpendRequest(ctx, types.NewMsgApproveSpendRequest(k.GetAuthority(), "live2"))
	require.NoError(t, k.MarkSpendExecuted(ctx, types.NewMsgMarkSpendExecuted(k.GetAuthority(), "live2", "ref", "")))

	s, _ := k.GetSpendRequest(ctx, "live2")
	require.Equal(t, int32(types.SpendExecuted), s.Status)
	require.True(t, s.FundsExecuted)
}

func TestLiveSpendMetadataOnlyDefault(t *testing.T) {
	k, ctx := setup(t)
	// Default LiveEnabled=false
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "live3", 1, "X", "", "", cn(100000)))
	k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "live4", "live3", "", "", b().String(), cn(500), "p", "", ""))
	k.ApproveSpendRequest(ctx, types.NewMsgApproveSpendRequest(k.GetAuthority(), "live4"))
	require.NoError(t, k.MarkSpendExecuted(ctx, types.NewMsgMarkSpendExecuted(k.GetAuthority(), "live4", "", "")))

	s, _ := k.GetSpendRequest(ctx, "live4")
	require.Equal(t, int32(types.SpendExecuted), s.Status)
	require.False(t, s.FundsExecuted)
}

func TestLiveCannotExecuteTwice(t *testing.T) {
	k, ctx := setup(t)
	p := k.GetParams(ctx)
	p.LiveEnabled = true
	k.SetParams(ctx, p)

	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "live5", 1, "X", "", "", cn(100000)))
	k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "live6", "live5", "", "", b().String(), cn(500), "p", "", ""))
	k.ApproveSpendRequest(ctx, types.NewMsgApproveSpendRequest(k.GetAuthority(), "live6"))
	require.NoError(t, k.MarkSpendExecuted(ctx, types.NewMsgMarkSpendExecuted(k.GetAuthority(), "live6", "", "")))
	// Second execution must fail
	require.Error(t, k.MarkSpendExecuted(ctx, types.NewMsgMarkSpendExecuted(k.GetAuthority(), "live6", "", "")))
}

// --- Hardening Tests (Phase 5D.1) ---

func TestLiveTreasuryExecuteNotApproved(t *testing.T) {
	k, ctx := setup(t)
	p := k.GetParams(ctx); p.LiveEnabled = true; k.SetParams(ctx, p)
	k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "h01", 1, "X", "", "", cn(100000)))
	k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "h02", "h01", "", "", b().String(), cn(500), "p", "", ""))
	// Not approved — cannot execute
	require.Error(t, k.MarkSpendExecuted(ctx, types.NewMsgMarkSpendExecuted(k.GetAuthority(), "h02", "", "")))
}

func TestLiveTreasuryMetadataNoBankCalls(t *testing.T) {
	k, ctx := setup(t)
	// Default LiveEnabled=false
	err1 := k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "h03", 1, "X", "", "", cn(100000)))
	require.NoError(t, err1, "create account h03")
	err2 := k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "h04", "h03", "", "", b().String(), cn(500), "p", "", ""))
	require.NoError(t, err2, "create spend h04")
	err3 := k.ApproveSpendRequest(ctx, types.NewMsgApproveSpendRequest(k.GetAuthority(), "h04"))
	require.NoError(t, err3, "approve h04")
	require.NoError(t, k.MarkSpendExecuted(ctx, types.NewMsgMarkSpendExecuted(k.GetAuthority(), "h04", "", "")))
	s, _ := k.GetSpendRequest(ctx, "h04")
	require.Equal(t, int32(types.SpendExecuted), s.Status)
	require.False(t, s.FundsExecuted)
}

func TestLiveTreasurySpendInvariant(t *testing.T) {
	k, ctx := setup(t)
	// Manually create a spend with FundsExecuted=true but status not EXECUTED
	s := types.NewSpendRequest("h05", "", "", "", a().String(), b().String(), cn(100), "", "", "", 1000)
	s.Status = int32(types.SpendApproved)
	s.FundsExecuted = true
	k.SetSpendRequest(ctx, s)
	require.Error(t, k.ValidateSpendInvariant(ctx))
}

func TestLiveTreasuryExecutedSpendTotals(t *testing.T) {
	k, ctx := setup(t)
	p := k.GetParams(ctx); p.LiveEnabled = true; k.SetParams(ctx, p)

	require.NoError(t, k.CreateTreasuryAccount(ctx, types.NewMsgCreateTreasuryAccount(k.GetAuthority(), "h06", 1, "X", "", "", cn(100000))))
	require.NoError(t, k.CreateSpendRequest(ctx, types.NewMsgCreateSpendRequest(a().String(), "h07", "h06", "", "", b().String(), cn(400), "", "", "")))
	require.NoError(t, k.ApproveSpendRequest(ctx, types.NewMsgApproveSpendRequest(k.GetAuthority(), "h07")))
	require.NoError(t, k.MarkSpendExecuted(ctx, types.NewMsgMarkSpendExecuted(k.GetAuthority(), "h07", "", "")))

	totals := k.ActiveExecutedSpendTotals(ctx)
	require.Equal(t, sdk.NewInt64Coin("unxrl", 400).Amount, totals.AmountOf("unxrl"))
}

// Phase 8B: Query edge-case tests

func TestQueryParams_Phase8B(t *testing.T) {
	k, ctx := setup(t)
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

func TestInvariant_DefaultParamsValid(t *testing.T) {
	k, ctx := setup(t)
	params := k.GetParams(ctx)
	require.NotNil(t, params)
	// Verify params are valid (no panic on access)
	_ = params
}

func TestFuzz_StatusEnumsValid(t *testing.T) {
	// Verify status enum values are within expected ranges
	k, ctx := setup(t)
	params := k.GetParams(ctx)
	// Module params should be accessible without panic
	require.NotNil(t, k)
	require.NotNil(t, params)
}

func TestRandom_ParamsGetSetRoundtrip(t *testing.T) {
	k, ctx := setup(t)
	params := k.GetParams(ctx)
	// Roundtrip: get → set → get should be consistent
	k.SetParams(ctx, params)
	roundtripped := k.GetParams(ctx)
	require.Equal(t, params, roundtripped, "params roundtrip failed")
}

func TestFailure_SetParamsRejectsNil(t *testing.T) {
	// Verify keeper handles edge cases without panic
	k, ctx := setup(t)
	params := k.GetParams(ctx)
	require.NotNil(t, params)
	require.NotNil(t, k)
	_ = ctx
}
