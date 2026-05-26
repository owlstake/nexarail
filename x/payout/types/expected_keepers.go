package types

import (
	sdk "github.com/cosmos/cosmos-sdk/types"
	merchanttypes "github.com/nexarail/chain/x/merchant/types"
)

// MerchantKeeper defines the expected interface from x/merchant.
type MerchantKeeper interface {
	GetMerchant(ctx sdk.Context, owner sdk.AccAddress) (merchanttypes.Merchant, bool)
}

// BankKeeper defines the expected bank keeper interface. Used only for live
// payout transfers (params.LiveEnabled=true); metadata-only payouts never call it.
type BankKeeper interface {
	SendCoinsFromModuleToAccount(ctx sdk.Context, senderModule string, recipientAddr sdk.AccAddress, amt sdk.Coins) error
	GetBalance(ctx sdk.Context, addr sdk.AccAddress, denom string) sdk.Coin
}
