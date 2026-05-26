package types_test

import (
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/nexarail/chain/x/escrow/types"
	"github.com/stretchr/testify/require"
	"testing"
)

func a1() sdk.AccAddress {
	return sdk.AccAddress([]byte{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1})
}
func a2() sdk.AccAddress {
	return sdk.AccAddress([]byte{2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2})
}
func c(amt int64) sdk.Coin { return sdk.NewInt64Coin("unxrl", amt) }

func validEscrow() types.Escrow {
	return types.NewEscrow("test-escrow-1", a1().String(), a2().String(), "merchant-1", "unxrl", c(1000), "ref-1", "memo", 100, 200)
}

func TestDefaultParams(t *testing.T) {
	p := types.DefaultParams()
	require.True(t, p.EscrowsEnabled)
	require.Equal(t, uint32(120), p.MaxReferenceLength)
	require.Equal(t, uint32(280), p.MaxMemoLength)
	require.NoError(t, p.Validate())
}

func TestParamsInvalidMaxRefZero(t *testing.T) {
	p := types.DefaultParams()
	p.MaxReferenceLength = 0
	require.Error(t, p.Validate())
}

func TestParamsInvalidMinAmount(t *testing.T) {
	p := types.DefaultParams()
	p.MinEscrowAmount = sdk.Coin{Denom: "unxrl", Amount: sdk.NewInt(-1)}
	require.Error(t, p.Validate())
}

func TestDefaultGenesis(t *testing.T) {
	gs := types.DefaultGenesis()
	require.NoError(t, gs.Validate())
	require.Empty(t, gs.Escrows)
}

func TestGenesisDuplicateRejected(t *testing.T) {
	e := validEscrow()
	gs := types.NewGenesisState(types.DefaultParams(), []types.Escrow{e, e})
	require.Error(t, gs.Validate())
}

func TestGenesisInvalidEscrow(t *testing.T) {
	e := validEscrow()
	e.EscrowId = ""
	gs := types.NewGenesisState(types.DefaultParams(), []types.Escrow{e})
	require.Error(t, gs.Validate())
}

func TestValidEscrow(t *testing.T) {
	require.NoError(t, validEscrow().Validate())
}

func TestEscrowIDTooShort(t *testing.T) {
	e := validEscrow()
	e.EscrowId = "ab"
	require.Error(t, e.Validate())
}

func TestEscrowIDInvalidChars(t *testing.T) {
	e := validEscrow()
	e.EscrowId = "Test Escrow!"
	require.Error(t, e.Validate())
}

func TestBuyerEqualsSeller(t *testing.T) {
	e := validEscrow()
	e.SellerAddress = e.BuyerAddress
	require.Error(t, e.Validate())
}

func TestEmptyMerchantID(t *testing.T) {
	e := validEscrow()
	e.MerchantId = ""
	require.Error(t, e.Validate())
}

func TestZeroAmount(t *testing.T) {
	e := validEscrow()
	e.Amount = c(0)
	require.Error(t, e.Validate())
}

func TestNegativePlatformFee(t *testing.T) {
	e := validEscrow()
	e.PlatformFee = sdk.Coin{Denom: "unxrl", Amount: sdk.NewInt(-1)}
	require.Error(t, e.Validate())
}

func TestFeeExceedsAmount(t *testing.T) {
	e := validEscrow()
	e.PlatformFee = c(2000)
	require.Error(t, e.Validate())
}

func TestInvalidStatus(t *testing.T) {
	e := validEscrow()
	e.Status = 99
	require.Error(t, e.Validate())
}

func TestInvalidDisputeStatus(t *testing.T) {
	e := validEscrow()
	e.DisputeStatus = 99
	require.Error(t, e.Validate())
}

func TestReferenceTooLong(t *testing.T) {
	e := validEscrow()
	e.PaymentReference = string(make([]byte, 200))
	require.Error(t, e.Validate())
}

func TestMemoTooLong(t *testing.T) {
	e := validEscrow()
	e.Memo = string(make([]byte, 300))
	require.Error(t, e.Validate())
}

func TestExpiryMustBeAfterCreated(t *testing.T) {
	e := validEscrow()
	e.ExpiresAt = 50
	e.CreatedAt = 100
	require.Error(t, e.Validate())
}

func TestEscrowStatusStrings(t *testing.T) {
	require.Equal(t, "created", types.EscrowCreated.String())
	require.Equal(t, "disputed", types.EscrowDisputed.String())
	require.Equal(t, "released", types.EscrowReleased.String())
}

func TestDisputeStatusStrings(t *testing.T) {
	require.Equal(t, "open", types.DisputeOpen.String())
	require.Equal(t, "buyer_wins", types.DisputeBuyerWins.String())
}

func TestMsgs(t *testing.T) {
	require.NoError(t, types.NewMsgCreateEscrow(a1().String(), "escrow-1", a2().String(), "m", "unxrl", c(100), "", "", 0).ValidateBasic())
	require.NoError(t, types.NewMsgReleaseEscrow(a1().String(), "e1", "r", "").ValidateBasic())
	require.NoError(t, types.NewMsgRefundEscrow(a2().String(), "e1", "r", "").ValidateBasic())
	require.NoError(t, types.NewMsgOpenDispute(a1().String(), "e1", "reason").ValidateBasic())
	require.NoError(t, types.NewMsgCancelEscrow(a1().String(), "e1", "").ValidateBasic())
	require.NoError(t, types.NewMsgUpdateParams(a1().String(), types.DefaultParams()).ValidateBasic())
	// ResolveDispute must have valid resolution status
	require.Error(t, types.NewMsgResolveDispute(a1().String(), "e1", 1, "note").ValidateBasic())
	require.NoError(t, types.NewMsgResolveDispute(a1().String(), "e1", 3, "note").ValidateBasic())
}
