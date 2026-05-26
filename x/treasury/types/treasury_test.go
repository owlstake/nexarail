package types_test

import (
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/nexarail/chain/x/treasury/types"
	"github.com/stretchr/testify/require"
	"testing"
)

func a1() sdk.AccAddress {
	return sdk.AccAddress([]byte{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1})
}
func a2() sdk.AccAddress {
	return sdk.AccAddress([]byte{2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2})
}
func cn(amt int64) sdk.Coin { return sdk.NewInt64Coin("unxrl", amt) }

func TestDefaultParams(t *testing.T) {
	p := types.DefaultParams()
	require.True(t, p.TreasuryEnabled)
	require.NoError(t, p.Validate())
}
func TestParamsInvalid(t *testing.T) {
	p := types.DefaultParams()
	p.MaxNameLength = 0
	require.Error(t, p.Validate())
	p = types.DefaultParams()
	p.MinSpendAmount = sdk.Coin{Denom: "unxrl", Amount: sdk.NewInt(-1)}
	require.Error(t, p.Validate())
}
func TestDefaultGenesis(t *testing.T) { require.NoError(t, types.DefaultGenesis().Validate()) }
func TestGenesisDuplicateAccount(t *testing.T) {
	a := types.NewTreasuryAccount("acct-1", 1, "Test", "", "", cn(1000), 100)
	gs := types.GenesisState{Params: types.DefaultParams(), Accounts: []types.TreasuryAccount{a, a}}
	require.Error(t, gs.Validate())
}

func TestValidAccount(t *testing.T) {
	a := types.NewTreasuryAccount("acct-1", 1, "Protocol", "Main", "", cn(1000), 100)
	require.NoError(t, a.ValidateWithParams(types.DefaultParams()))
}
func TestAccountInvalidID(t *testing.T) {
	a := types.NewTreasuryAccount("ab", 1, "X", "", "", cn(0), 0)
	require.Error(t, a.ValidateWithParams(types.DefaultParams()))
}
func TestAccountInvalidCategory(t *testing.T) {
	a := types.NewTreasuryAccount("acct-1", 99, "X", "", "", cn(0), 0)
	require.Error(t, a.ValidateWithParams(types.DefaultParams()))
}
func TestAccountNegativeBalance(t *testing.T) {
	a := types.NewTreasuryAccount("acct-1", 1, "X", "", "", sdk.Coin{Denom: "unxrl", Amount: sdk.NewInt(-1)}, 0)
	require.Error(t, a.ValidateWithParams(types.DefaultParams()))
}

func TestValidBudget(t *testing.T) {
	b := types.NewBudget("budget-1", "acct-1", 1, "Budget", "Desc", cn(10000), 0, 0, "", 100)
	require.NoError(t, b.ValidateWithParams(types.DefaultParams()))
}
func TestBudgetInvalidID(t *testing.T) {
	b := types.NewBudget("ab", "a", 1, "X", "", cn(0), 0, 0, "", 0)
	require.Error(t, b.ValidateWithParams(types.DefaultParams()))
}
func TestBudgetAllocExceedsTotal(t *testing.T) {
	b := types.NewBudget("budget-1", "a", 1, "X", "", cn(100), 0, 0, "", 100)
	b.AllocatedAmount = cn(200)
	require.Error(t, b.ValidateWithParams(types.DefaultParams()))
}

func TestValidGrant(t *testing.T) {
	g := types.NewGrant("grant-1", "budget-1", a2().String(), "Grant", "Desc", cn(500), 3, "", 100)
	require.NoError(t, g.ValidateWithParams(types.DefaultParams()))
}
func TestGrantInvalidRecipient(t *testing.T) {
	g := types.NewGrant("grant-1", "b", "bad", "X", "", cn(100), 0, "", 0)
	require.Error(t, g.ValidateWithParams(types.DefaultParams()))
}

func TestValidSpend(t *testing.T) {
	s := types.NewSpendRequest("spend-1", "acct-1", "", "", a1().String(), a2().String(), cn(100), "Purpose", "", "", 100)
	require.NoError(t, s.ValidateWithParams(types.DefaultParams()))
}
func TestSpendInvalidID(t *testing.T) {
	s := types.NewSpendRequest("ab", "a", "", "", a1().String(), a2().String(), cn(0), "", "", "", 0)
	require.Error(t, s.ValidateWithParams(types.DefaultParams()))
}
func TestSpendZeroAmount(t *testing.T) {
	s := types.NewSpendRequest("spend-1", "a", "", "", a1().String(), a2().String(), cn(0), "", "", "", 0)
	require.Error(t, s.ValidateWithParams(types.DefaultParams()))
}

func TestEnums(t *testing.T) {
	require.Equal(t, "protocol", types.CategoryProtocol.String())
	require.Equal(t, "active", types.BudgetActive.String())
	require.Equal(t, "active", types.GrantActive.String())
	require.Equal(t, "executed", types.SpendExecuted.String())
}

func TestMsgs(t *testing.T) {
	require.NoError(t, types.NewMsgCreateTreasuryAccount(a1().String(), "a1", 1, "X", "", "", cn(0)).ValidateBasic())
	require.NoError(t, types.NewMsgCreateBudget(a1().String(), "b1", "a1", 1, "X", "", cn(100), 0, 0, "").ValidateBasic())
	require.NoError(t, types.NewMsgUpdateBudgetStatus(a1().String(), "b1", 2).ValidateBasic())
	require.NoError(t, types.NewMsgCreateGrant(a1().String(), "g1", "b1", a2().String(), "X", "", cn(100), 1, "").ValidateBasic())
	require.NoError(t, types.NewMsgUpdateGrantStatus(a1().String(), "g1", 4).ValidateBasic())
	require.NoError(t, types.NewMsgCreateSpendRequest(a1().String(), "s1", "a1", "", "", a2().String(), cn(100), "P", "", "").ValidateBasic())
	require.NoError(t, types.NewMsgApproveSpendRequest(a1().String(), "s1").ValidateBasic())
	require.NoError(t, types.NewMsgRejectSpendRequest(a1().String(), "s1", "").ValidateBasic())
	require.NoError(t, types.NewMsgMarkSpendExecuted(a1().String(), "s1", "", "").ValidateBasic())
	require.NoError(t, types.NewMsgCancelSpendRequest(a1().String(), "s1", "").ValidateBasic())
}
