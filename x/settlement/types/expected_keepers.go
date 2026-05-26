package types

import (
	sdk "github.com/cosmos/cosmos-sdk/types"
	feestypes "github.com/nexarail/chain/x/fees/types"
	merchanttypes "github.com/nexarail/chain/x/merchant/types"
)

// BankKeeper defines the expected bank interface for live settlement transfers.
type BankKeeper interface {
	SendCoins(ctx sdk.Context, fromAddr sdk.AccAddress, toAddr sdk.AccAddress, amt sdk.Coins) error
	SendCoinsFromAccountToModule(ctx sdk.Context, fromAddr sdk.AccAddress, recipientModule string, amt sdk.Coins) error
	BurnCoins(ctx sdk.Context, moduleName string, amt sdk.Coins) error
}

// FeesKeeper defines the expected interface from the x/fees module.
type FeesKeeper interface {
	GetParams(ctx sdk.Context) feestypes.Params
}

// MerchantKeeper defines the expected interface from the x/merchant module.
type MerchantKeeper interface {
	GetMerchant(ctx sdk.Context, owner sdk.AccAddress) (merchanttypes.Merchant, bool)
}
