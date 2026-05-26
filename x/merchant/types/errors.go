package types

import sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"

var (
	ErrMerchantAlreadyExists = sdkerrors.Register(ModuleName, 1, "merchant already registered")
	ErrMerchantNotFound      = sdkerrors.Register(ModuleName, 2, "merchant not found")
	ErrNameTooShort          = sdkerrors.Register(ModuleName, 3, "merchant name too short")
	ErrNameTooLong           = sdkerrors.Register(ModuleName, 4, "merchant name too long")
	ErrDescriptionTooLong    = sdkerrors.Register(ModuleName, 5, "merchant description too long")
	ErrInvalidOwner          = sdkerrors.Register(ModuleName, 6, "invalid merchant owner address")
	ErrInsufficientFee       = sdkerrors.Register(ModuleName, 7, "insufficient registration fee")
	ErrUnauthorized          = sdkerrors.Register(ModuleName, 8, "unauthorized: sender is not the merchant owner")
	ErrInvalidParams         = sdkerrors.Register(ModuleName, 9, "invalid parameters")
	ErrMerchantClosed        = sdkerrors.Register(ModuleName, 10, "merchant is closed and cannot be updated")
)
