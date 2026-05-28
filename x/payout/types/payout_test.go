package types_test

import (
	"strings"
	"testing"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/stretchr/testify/require"

	"github.com/nexarail/chain/x/payout/types"
)

func a1() sdk.AccAddress {
	return sdk.AccAddress([]byte{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1})
}
func a2() sdk.AccAddress {
	return sdk.AccAddress([]byte{2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2})
}
func cn(amt int64) sdk.Coin { return sdk.NewInt64Coin("unxrl", amt) }

func validPayout() types.Payout {
	return types.NewPayout("payout-1", "", "merchant-1", a1().String(), a2().String(), "unxrl", cn(1000), 1, "ref", "memo", 100)
}

func TestDefaultParams(t *testing.T) {
	p := types.DefaultParams()
	require.True(t, p.PayoutsEnabled)
	require.True(t, p.BatchPayoutsEnabled)
	require.True(t, p.ApprovalRequired)
	require.False(t, p.LiveEnabled, "live transfers must be disabled by default")
	require.NoError(t, p.Validate())
}

func TestParamsLiveEnabledToggleValid(t *testing.T) {
	p := types.DefaultParams()
	p.LiveEnabled = true
	require.NoError(t, p.Validate())
}

func TestFundsPaidRequiresPaidStatus(t *testing.T) {
	p := validPayout()
	p.Status = int32(types.PayoutApproved)
	p.FundsPaid = true
	require.Error(t, p.ValidateWithParams(types.DefaultParams()))

	p.Status = int32(types.PayoutPaid)
	require.NoError(t, p.ValidateWithParams(types.DefaultParams()))
}

func TestParamsInvalid(t *testing.T) {
	p := types.DefaultParams()
	p.MaxReferenceLength = 0
	require.Error(t, p.Validate())
	p = types.DefaultParams()
	p.MinPayoutAmount = sdk.Coin{Denom: "unxrl", Amount: sdk.NewInt(-1)}
	require.Error(t, p.Validate())
}

func TestDefaultGenesis(t *testing.T) {
	require.NoError(t, types.DefaultGenesis().Validate())
}

func TestGenesisDuplicatePayout(t *testing.T) {
	p := validPayout()
	gs := types.NewGenesisState(types.DefaultParams(), []types.Payout{p, p}, nil)
	require.Error(t, gs.Validate())
}

func TestGenesisDuplicateBatch(t *testing.T) {
	b := types.NewBatchPayout("batch-1", "m", a1().String(), []string{"p1"}, cn(100), cn(0), cn(100), "ref", "", 100)
	gs := types.NewGenesisState(types.DefaultParams(), nil, []types.BatchPayout{b, b})
	require.Error(t, gs.Validate())
}

func TestValidPayout(t *testing.T) {
	require.NoError(t, validPayout().ValidateWithParams(types.DefaultParams()))
}

func TestPayoutIDTooShort(t *testing.T) {
	p := validPayout()
	p.PayoutId = "ab"
	require.Error(t, p.ValidateWithParams(types.DefaultParams()))
}

func TestPayoutIDInvalidChars(t *testing.T) {
	p := validPayout()
	p.PayoutId = "Bad Payout!"
	require.Error(t, p.ValidateWithParams(types.DefaultParams()))
}

func TestInitiatorEqualsRecipient(t *testing.T) {
	p := validPayout()
	p.RecipientAddress = p.InitiatorAddress
	require.Error(t, p.ValidateWithParams(types.DefaultParams()))
}

func TestEmptyMerchant(t *testing.T) {
	p := validPayout()
	p.MerchantId = ""
	require.Error(t, p.ValidateWithParams(types.DefaultParams()))
}

func TestZeroAmount(t *testing.T) {
	p := validPayout()
	p.Amount = cn(0)
	require.Error(t, p.ValidateWithParams(types.DefaultParams()))
}

func TestFeeExceedsAmount(t *testing.T) {
	p := validPayout()
	p.FeeAmount = cn(2000)
	require.Error(t, p.ValidateWithParams(types.DefaultParams()))
}

func TestInvalidStatus(t *testing.T) {
	p := validPayout()
	p.Status = 99
	require.Error(t, p.ValidateWithParams(types.DefaultParams()))
}

func TestInvalidPayoutType(t *testing.T) {
	p := validPayout()
	p.PayoutType = 99
	require.Error(t, p.ValidateWithParams(types.DefaultParams()))
}

func TestReferenceTooLong(t *testing.T) {
	p := validPayout()
	p.PayoutReference = strings.Repeat("x", 200)
	require.Error(t, p.ValidateWithParams(types.DefaultParams()))
}

func TestMemoTooLong(t *testing.T) {
	p := validPayout()
	p.Memo = strings.Repeat("x", 300)
	require.Error(t, p.ValidateWithParams(types.DefaultParams()))
}

func TestPayoutStatusStrings(t *testing.T) {
	require.Equal(t, "created", types.PayoutCreated.String())
	require.Equal(t, "paid", types.PayoutPaid.String())
}

func TestPayoutTypeStrings(t *testing.T) {
	require.Equal(t, "creator", types.PayoutTypeCreator.String())
	require.Equal(t, "refund", types.PayoutTypeRefund.String())
}

func TestBatchStatusStrings(t *testing.T) {
	require.Equal(t, "created", types.BatchCreated.String())
	require.Equal(t, "paid", types.BatchPaid.String())
}

func TestValidBatch(t *testing.T) {
	b := types.NewBatchPayout("batch-1", "merchant-1", a1().String(), []string{"p1", "p2"}, cn(200), cn(10), cn(190), "ref", "", 100)
	require.NoError(t, b.ValidateWithParams(types.DefaultParams()))
}

func TestBatchEmptyPayouts(t *testing.T) {
	b := types.NewBatchPayout("batch-1", "m", a1().String(), []string{}, cn(0), cn(0), cn(0), "", "", 100)
	require.Error(t, b.ValidateWithParams(types.DefaultParams()))
}

func TestBatchDuplicatePayoutIDs(t *testing.T) {
	b := types.NewBatchPayout("batch-1", "m", a1().String(), []string{"p1", "p1"}, cn(0), cn(0), cn(0), "", "", 100)
	require.Error(t, b.ValidateWithParams(types.DefaultParams()))
}

func TestBatchTooLarge(t *testing.T) {
	ids := make([]string, 101)
	for i := range ids {
		ids[i] = "p" + string(rune('a'+i%26)) + string(rune('0'+i/26))
	}
	// use shorter IDs
	ids2 := make([]string, 101)
	for i := 0; i < 101; i++ {
		ids2[i] = "pp"
	}
	b := types.NewBatchPayout("batch-1", "m", a1().String(), ids2, cn(0), cn(0), cn(0), "", "", 100)
	require.Error(t, b.ValidateWithParams(types.DefaultParams()))
}

func TestMsgs(t *testing.T) {
	require.NoError(t, types.NewMsgCreatePayout(a1().String(), "p1", "m", a2().String(), "unxrl", cn(100), 1, "ref", "memo").ValidateBasic())
	require.NoError(t, types.NewMsgApprovePayout(a1().String(), "p1").ValidateBasic())
	require.NoError(t, types.NewMsgMarkPayoutPaid(a1().String(), "p1", "ext", "").ValidateBasic())
	require.NoError(t, types.NewMsgCancelPayout(a1().String(), "p1", "").ValidateBasic())
	require.NoError(t, types.NewMsgFailPayout(a1().String(), "p1", "reason").ValidateBasic())
	require.NoError(t, types.NewMsgUpdateParams(a1().String(), types.DefaultParams()).ValidateBasic())
}

// --- Phase 14C ValidateBasic regression tests ---

func TestMsgUpdateParamsValidates(t *testing.T) {
	// Valid params must pass
	msg := types.NewMsgUpdateParams(a1().String(), types.DefaultParams())
	require.NoError(t, msg.ValidateBasic())

	// Empty authority must fail
	msgEmpty := types.NewMsgUpdateParams("", types.DefaultParams())
	require.Error(t, msgEmpty.ValidateBasic())

	// Invalid authority must fail
	msgBad := types.NewMsgUpdateParams("invalid", types.DefaultParams())
	require.Error(t, msgBad.ValidateBasic())
}

func TestMsgUpdateParamsInvalidParams(t *testing.T) {
	// Zero max reference length should fail Params.Validate()
	p := types.DefaultParams()
	p.MaxReferenceLength = 0
	msg := types.NewMsgUpdateParams(a1().String(), p)
	require.Error(t, msg.ValidateBasic())

	// Zero max batch size should fail
	p = types.DefaultParams()
	p.MaxBatchSize = 0
	msg = types.NewMsgUpdateParams(a1().String(), p)
	require.Error(t, msg.ValidateBasic())

	// Negative min payout should fail
	p = types.DefaultParams()
	p.MinPayoutAmount = sdk.Coin{Denom: "unxrl", Amount: sdk.NewInt(-1)}
	msg = types.NewMsgUpdateParams(a1().String(), p)
	require.Error(t, msg.ValidateBasic())
}
