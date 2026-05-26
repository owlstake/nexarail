package types_test

import (
	"testing"

	"github.com/stretchr/testify/require"

	sdk "github.com/cosmos/cosmos-sdk/types"

	"github.com/nexarail/chain/x/merchant/types"
)

func TestDefaultParams(t *testing.T) {
	p := types.DefaultParams()
	require.True(t, p.RegistrationFee.IsEqual(sdk.NewInt64Coin("unxrl", 1000000)))
	require.Equal(t, uint32(3), p.MinNameLength)
	require.Equal(t, uint32(64), p.MaxNameLength)
	require.Equal(t, uint32(256), p.MaxDescriptionLength)
}

func TestParamsValidate(t *testing.T) {
	p := types.DefaultParams()
	require.NoError(t, p.Validate())
}

func TestNegativeRegistrationFee(t *testing.T) {
	p := types.DefaultParams()
	p.RegistrationFee = sdk.Coin{Denom: "unxrl", Amount: sdk.NewInt(-1)}
	err := p.Validate()
	require.Error(t, err)
}

func TestMinNameLengthZero(t *testing.T) {
	p := types.DefaultParams()
	p.MinNameLength = 0
	err := p.Validate()
	require.Error(t, err)
}

func TestMaxNameLessThanMin(t *testing.T) {
	p := types.DefaultParams()
	p.MinNameLength = 10
	p.MaxNameLength = 5
	err := p.Validate()
	require.Error(t, err)
}

func TestNewMerchant(t *testing.T) {
	addr := sdk.AccAddress(make([]byte, 20))
	m := types.NewMerchant(addr, "Acme Rail", "Transport", "https://acme.com", 1, 1)
	require.Equal(t, addr.String(), m.Owner)
	require.Equal(t, "Acme Rail", m.Name)
	require.True(t, m.IsActive())
}

func TestMerchantValidate(t *testing.T) {
	addr := sdk.AccAddress(make([]byte, 20))
	m := types.NewMerchant(addr, "Acme Rail", "Transport", "https://acme.com", 1, 1)
	require.NoError(t, m.Validate())
}

func TestMerchantValidateEmptyName(t *testing.T) {
	addr := sdk.AccAddress(make([]byte, 20))
	m := types.NewMerchant(addr, "   ", "desc", "web", 1, 1)
	err := m.Validate()
	require.Error(t, err)
}

func TestMerchantValidateWithParamsNameTooShort(t *testing.T) {
	addr := sdk.AccAddress(make([]byte, 20))
	m := types.NewMerchant(addr, "AB", "desc", "web", 1, 1)
	err := m.ValidateWithParams(types.DefaultParams())
	require.Error(t, err)
}

func TestMerchantValidateWithParamsNameTooLong(t *testing.T) {
	addr := sdk.AccAddress(make([]byte, 20))
	longName := ""
	for i := 0; i < 65; i++ {
		longName += "A"
	}
	m := types.NewMerchant(addr, longName, "desc", "web", 1, 1)
	err := m.ValidateWithParams(types.DefaultParams())
	require.Error(t, err)
}

func TestMerchantValidateWithParamsDescTooLong(t *testing.T) {
	addr := sdk.AccAddress(make([]byte, 20))
	longDesc := ""
	for i := 0; i < 257; i++ {
		longDesc += "A"
	}
	m := types.NewMerchant(addr, "Acme Rail", longDesc, "web", 1, 1)
	err := m.ValidateWithParams(types.DefaultParams())
	require.Error(t, err)
}

func TestMerchantInvalidOwner(t *testing.T) {
	m := types.Merchant{Owner: "not-an-address", Name: "X"}
	err := m.Validate()
	require.Error(t, err)
}

// --- Enum tests ---

func TestMerchantStatusString(t *testing.T) {
	require.Equal(t, "active", types.MerchantStatusActive.String())
	require.Equal(t, "inactive", types.MerchantStatusInactive.String())
	require.Equal(t, "closed", types.MerchantStatusClosed.String())
}

func TestMerchantStatusFromString(t *testing.T) {
	require.Equal(t, types.MerchantStatusActive, types.MerchantStatusFromString("active"))
	require.Equal(t, types.MerchantStatusInactive, types.MerchantStatusFromString("inactive"))
	require.Equal(t, types.MerchantStatusClosed, types.MerchantStatusFromString("closed"))
}

func TestVerificationStatusString(t *testing.T) {
	require.Equal(t, "unverified", types.VerificationUnverified.String())
	require.Equal(t, "verified", types.VerificationVerified.String())
	require.Equal(t, "rejected", types.VerificationRejected.String())
}

func TestRebateTierString(t *testing.T) {
	require.Equal(t, "none", types.RebateTierNone.String())
	require.Equal(t, "bronze", types.RebateTierBronze.String())
	require.Equal(t, "silver", types.RebateTierSilver.String())
	require.Equal(t, "gold", types.RebateTierGold.String())
	require.Equal(t, "platinum", types.RebateTierPlatinum.String())
}

// --- Msg validation tests ---

func TestMsgUpdateParamsValidate(t *testing.T) {
	p := types.DefaultParams()
	msg := types.NewMsgUpdateParams("nxr1qy0p7z5z5z5z5z5z5z5z5z5z5z5z5z5z5z5z5z5", p)
	err := msg.ValidateBasic()
	require.Error(t, err) // invalid bech32

	// Use a valid address length (not checking bech32 checksum in ValidateBasic, just format)
	addr := sdk.AccAddress([]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20})
	msg2 := types.NewMsgUpdateParams(addr.String(), p)
	require.NoError(t, msg2.ValidateBasic())
}

func TestMsgSetMerchantStatusValidate(t *testing.T) {
	addr := sdk.AccAddress([]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20})
	msg := types.NewMsgSetMerchantStatus(addr.String(), addr.String(), 0)
	require.NoError(t, msg.ValidateBasic())

	msg.Status = 3
	require.Error(t, msg.ValidateBasic())
}

func TestMsgSetVerificationStatusValidate(t *testing.T) {
	addr := sdk.AccAddress([]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20})
	msg := types.NewMsgSetVerificationStatus(addr.String(), addr.String(), 0)
	require.NoError(t, msg.ValidateBasic())

	msg.Status = 3
	require.Error(t, msg.ValidateBasic())
}

func TestMsgSetRebateTierValidate(t *testing.T) {
	addr := sdk.AccAddress([]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20})
	msg := types.NewMsgSetRebateTier(addr.String(), addr.String(), 0)
	require.NoError(t, msg.ValidateBasic())

	msg.Tier = 5
	require.Error(t, msg.ValidateBasic())
}

func TestMerchantIsClosed(t *testing.T) {
	addr := sdk.AccAddress([]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20})
	m := types.NewMerchant(addr, "Test", "desc", "web", 1, 1)
	require.False(t, m.IsClosed())
	m.Status = int32(types.MerchantStatusClosed)
	require.True(t, m.IsClosed())
}
