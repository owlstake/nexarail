package types

import (
	sdk "github.com/cosmos/cosmos-sdk/types"
)

// AccountKeeper defines the expected account keeper interface.
type AccountKeeper interface {
	HasAccount(ctx sdk.Context, addr sdk.AccAddress) bool
}

// BankKeeper defines the expected bank keeper interface.
type BankKeeper interface {
	SendCoinsFromAccountToModule(ctx sdk.Context, senderAddr sdk.AccAddress, recipientModule string, amt sdk.Coins) error
	SendCoinsFromModuleToAccount(ctx sdk.Context, senderModule string, recipientAddr sdk.AccAddress, amt sdk.Coins) error
}

// FeesKeeper defines the expected fees keeper interface (minimal).
type FeesKeeper interface {
	GetParams(ctx sdk.Context) interface{}
}
