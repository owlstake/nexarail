package types_test

import (
	"testing"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/stretchr/testify/require"

	"github.com/nexarail/chain/x/settlement/types"
)

func addr1() sdk.AccAddress {
	return sdk.AccAddress([]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20})
}
func addr2() sdk.AccAddress {
	return sdk.AccAddress([]byte{3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3})
}
func coin(amt int64) sdk.Coin { return sdk.NewInt64Coin("unxrl", amt) }

func newTestSettlement(id uint64) types.Settlement {
	return types.NewSettlement(id, addr1().String(), addr1().String(), "merchant-1", addr1().String(),
		coin(1000), coin(10), coin(6), coin(2), coin(2), coin(0),
		0, "ref-1", "", "test", 100,
	)
}

func TestSettlementValidate(t *testing.T) {
	s := newTestSettlement(1)
	require.NoError(t, s.Validate())
	require.Equal(t, int32(types.SettlementPending), s.Status)
}

func TestSettlementInvalidPayer(t *testing.T) {
	s := newTestSettlement(1)
	s.Payer = "bad"
	require.Error(t, s.Validate())
}

func TestSettlementInvalidMerchant(t *testing.T) {
	s := newTestSettlement(1)
	s.MerchantOwner = "bad"
	require.Error(t, s.Validate())
}

func TestSettlementEmptyMerchantId(t *testing.T) {
	s := newTestSettlement(1)
	s.MerchantId = ""
	require.Error(t, s.Validate())
}

func TestSettlementZeroAmount(t *testing.T) {
	s := newTestSettlement(1)
	s.Amount = coin(0)
	require.Error(t, s.Validate())
}

func TestSettlementNegativeFee(t *testing.T) {
	s := newTestSettlement(1)
	s.FeeAmount = sdk.Coin{Denom: "unxrl", Amount: sdk.NewInt(-10)}
	require.Error(t, s.Validate())
}

func TestSettlementInvalidStatus(t *testing.T) {
	s := newTestSettlement(1)
	s.Status = 5
	require.Error(t, s.Validate())
}

func TestSettlementIsPending(t *testing.T) {
	s := newTestSettlement(1)
	require.True(t, s.IsPending())
	require.False(t, s.IsTerminal())
}

func TestSettlementIsTerminal(t *testing.T) {
	s := newTestSettlement(1)
	s.Status = int32(types.SettlementCancelled)
	require.True(t, s.IsTerminal())
	s.Status = int32(types.SettlementFailed)
	require.True(t, s.IsTerminal())
	s.Status = int32(types.SettlementRefunded)
	require.True(t, s.IsTerminal())
}

// --- Msg validation ---

func TestMsgCreateSettlementValidate(t *testing.T) {
	msg := types.NewMsgCreateSettlement(addr1().String(), addr2().String(), coin(1000), "test")
	require.NoError(t, msg.ValidateBasic())
}

func TestMsgCreateSettlementInvalidPayer(t *testing.T) {
	msg := types.NewMsgCreateSettlement("bad", addr2().String(), coin(1000), "")
	require.Error(t, msg.ValidateBasic())
}

func TestMsgCreateSettlementInvalidMerchant(t *testing.T) {
	msg := types.NewMsgCreateSettlement(addr1().String(), "bad", coin(1000), "")
	require.Error(t, msg.ValidateBasic())
}

func TestMsgCreateSettlementZeroAmount(t *testing.T) {
	msg := types.NewMsgCreateSettlement(addr1().String(), addr2().String(), coin(0), "")
	require.Error(t, msg.ValidateBasic())
}

func TestMsgUpdateSettlementStatusValidate(t *testing.T) {
	msg := types.NewMsgUpdateSettlementStatus(addr1().String(), 1, 1)
	require.NoError(t, msg.ValidateBasic())
}

func TestMsgUpdateSettlementStatusInvalidAuthority(t *testing.T) {
	msg := types.NewMsgUpdateSettlementStatus("bad", 1, 1)
	require.Error(t, msg.ValidateBasic())
}

func TestMsgUpdateSettlementStatusInvalidStatus(t *testing.T) {
	msg := types.NewMsgUpdateSettlementStatus(addr1().String(), 1, 5)
	require.Error(t, msg.ValidateBasic())
}

func TestMsgUpdateParamsValidate(t *testing.T) {
	msg := types.NewMsgUpdateParams(addr1().String(), types.DefaultParams())
	require.NoError(t, msg.ValidateBasic())
}

func TestMsgUpdateParamsInvalidAuthority(t *testing.T) {
	msg := types.NewMsgUpdateParams("bad", types.DefaultParams())
	require.Error(t, msg.ValidateBasic())
}
