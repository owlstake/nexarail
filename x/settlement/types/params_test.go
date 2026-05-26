package types_test

import (
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/nexarail/chain/x/settlement/types"
)

func TestDefaultParams(t *testing.T) {
	p := types.DefaultParams()
	require.Equal(t, uint32(100), p.FeeRateBps)
	require.Len(t, p.RebateTiers, 5)
	require.Equal(t, uint32(0), p.RebateTiers[0])
	require.Equal(t, uint32(500), p.RebateTiers[1])
	require.Equal(t, uint32(2000), p.RebateTiers[4])
}

func TestParamsValidate(t *testing.T) {
	p := types.DefaultParams()
	require.NoError(t, p.Validate())
}

func TestFeeRateBpsExceedsMax(t *testing.T) {
	p := types.DefaultParams()
	p.FeeRateBps = 10001
	err := p.Validate()
	require.Error(t, err)
}

func TestRebateTiersWrongCount(t *testing.T) {
	p := types.DefaultParams()
	p.RebateTiers = []uint32{0, 100}
	err := p.Validate()
	require.Error(t, err)
}

func TestRebateTierExceedsMax(t *testing.T) {
	p := types.DefaultParams()
	p.RebateTiers[0] = 10001
	err := p.Validate()
	require.Error(t, err)
}

func TestGetRebateBps(t *testing.T) {
	p := types.DefaultParams()
	require.Equal(t, uint32(0), p.GetRebateBps(0))
	require.Equal(t, uint32(500), p.GetRebateBps(1))
	require.Equal(t, uint32(1500), p.GetRebateBps(3))
	require.Equal(t, uint32(0), p.GetRebateBps(-1))
	require.Equal(t, uint32(0), p.GetRebateBps(99))
}

func TestSettlementStatusString(t *testing.T) {
	require.Equal(t, "pending", types.SettlementPending.String())
	require.Equal(t, "completed", types.SettlementCompleted.String())
	require.Equal(t, "failed", types.SettlementFailed.String())
	require.Equal(t, "refunded", types.SettlementRefunded.String())
}
