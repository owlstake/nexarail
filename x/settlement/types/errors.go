package types

import sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"

var (
	ErrSettlementNotFound      = sdkerrors.Register(ModuleName, 1, "settlement not found")
	ErrInvalidPayer            = sdkerrors.Register(ModuleName, 2, "invalid payer address")
	ErrInvalidMerchant         = sdkerrors.Register(ModuleName, 3, "invalid merchant address")
	ErrAmountNotPositive       = sdkerrors.Register(ModuleName, 4, "amount must be positive")
	ErrMerchantNotActive       = sdkerrors.Register(ModuleName, 5, "merchant is not active")
	ErrUnauthorized            = sdkerrors.Register(ModuleName, 6, "unauthorized sender")
	ErrInvalidParams           = sdkerrors.Register(ModuleName, 7, "invalid parameters")
	ErrInvalidStatusTransition = sdkerrors.Register(ModuleName, 8, "invalid status transition")
	ErrInvalidStatus           = sdkerrors.Register(ModuleName, 9, "invalid settlement status")
	ErrSettlementsDisabled     = sdkerrors.Register(ModuleName, 10, "settlements are disabled")
)
