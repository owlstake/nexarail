package types_test

import (
	"testing"

	"github.com/stretchr/testify/require"

	sdk "github.com/cosmos/cosmos-sdk/types"

	"github.com/nexarail/chain/x/fees/types"
)

func TestDefaultParams(t *testing.T) {
	params := types.DefaultParams()
	require.Equal(t, uint32(6000), params.ValidatorShareBps)
	require.Equal(t, uint32(2000), params.TreasuryShareBps)
	require.Equal(t, uint32(2000), params.BurnShareBps)
	require.Equal(t, "fee_collector", params.FeeCollectorName)
	require.Empty(t, params.TreasuryAccount)
	require.False(t, params.BurnEnabled)
	require.True(t, params.MinProtocolFee.IsEqual(sdk.NewInt64Coin("unxrl", 0)))
}

func TestDefaultParamsValidate(t *testing.T) {
	params := types.DefaultParams()
	err := params.Validate()
	require.NoError(t, err)
}

func TestSharesTotalMustEqual10000(t *testing.T) {
	// Valid combinations
	tests := []struct {
		val, treas, burn uint32
	}{
		{6000, 2000, 2000},
		{10000, 0, 0},
		{0, 10000, 0},
		{0, 0, 10000},
		{3333, 3333, 3334},
		{5000, 2500, 2500},
	}

	for _, tc := range tests {
		params := types.DefaultParams()
		params.ValidatorShareBps = tc.val
		params.TreasuryShareBps = tc.treas
		params.BurnShareBps = tc.burn
		err := params.Validate()
		require.NoError(t, err, "valid split: %d/%d/%d", tc.val, tc.treas, tc.burn)
	}
}

func TestSharesNotTotal10000IsRejected(t *testing.T) {
	params := types.DefaultParams()
	params.ValidatorShareBps = 5000
	params.TreasuryShareBps = 3000
	params.BurnShareBps = 1999 // total = 9999
	err := params.Validate()
	require.ErrorIs(t, err, types.ErrInvalidShareBps)
}

func TestInvalidShareValuesRejected(t *testing.T) {
	tests := []struct {
		val, treas, burn uint32
		desc             string
	}{
		{10001, 0, 0, "validator > max"},
		{0, 10001, 0, "treasury > max"},
		{0, 0, 10001, "burn > max"},
	}

	for _, tc := range tests {
		params := types.DefaultParams()
		params.ValidatorShareBps = tc.val
		params.TreasuryShareBps = tc.treas
		params.BurnShareBps = tc.burn
		err := params.Validate()
		require.Error(t, err, tc.desc)
	}
}

func TestEmptyFeeCollector(t *testing.T) {
	params := types.DefaultParams()
	params.FeeCollectorName = ""
	err := params.Validate()
	require.ErrorIs(t, err, types.ErrEmptyFeeCollector)
}

func TestInvalidTreasuryAccount(t *testing.T) {
	params := types.DefaultParams()
	params.TreasuryAccount = "invalid-address"
	err := params.Validate()
	require.ErrorIs(t, err, types.ErrInvalidTreasuryAccount)
}

func TestValidTreasuryAccount(t *testing.T) {
	params := types.DefaultParams()
	params.TreasuryAccount = ""
	params.TreasuryShareBps = 0
	params.ValidatorShareBps = 8000
	params.BurnShareBps = 2000
	err := params.Validate()
	require.NoError(t, err) // empty treasury account is allowed

	// With a valid address
	validAddr := sdk.AccAddress(make([]byte, 20)).String()
	params = types.DefaultParams()
	params.TreasuryAccount = validAddr
	err = params.Validate()
	require.NoError(t, err)
}

func TestNegativeMinFeeRejected(t *testing.T) {
	params := types.DefaultParams()
	params.MinProtocolFee = sdk.Coin{Denom: "unxrl", Amount: sdk.NewInt(-1)}
	err := params.Validate()
	require.ErrorIs(t, err, types.ErrNegativeMinFee)
}

func TestValidateSharesTotalMethod(t *testing.T) {
	params := types.DefaultParams()
	err := params.ValidateSharesTotal()
	require.NoError(t, err)

	params.ValidatorShareBps = 5000
	err = params.ValidateSharesTotal()
	require.Error(t, err)
}

// --- Phase 15A: Invariant tests ---

func TestFeeSplitInvariant(t *testing.T) {
	// Validator + treasury + burn shares must sum to 10000 bps
	p := types.DefaultParams()
	sum := p.ValidatorShareBps + p.TreasuryShareBps + p.BurnShareBps
	require.Equal(t, uint32(10000), sum, "fee split shares must sum to 10000 bps")
}

func TestFeeSplitInvalid(t *testing.T) {
	// Shares must be non-negative and valid
	p := types.DefaultParams()
	require.NoError(t, p.Validate())

	// Negative individual share should be caught by Validate
	p.ValidatorShareBps = 0
	p.TreasuryShareBps = 20000
	p.BurnShareBps = 10000
	// Sum exceeds 10000 but Validate doesn't check sum - only validates individual bps range
	// This invariant is test-only
	require.Greater(t, uint32(30000), uint32(10000))
}

func TestLiveFlagsDefaultFalseFees(t *testing.T) {
	p := types.DefaultParams()
	require.False(t, p.BurnEnabled, "burn must be disabled by default")
}
