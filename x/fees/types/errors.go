package types

import (
	sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"
)

var (
	ErrInvalidShareBps        = sdkerrors.Register(ModuleName, 1, "share basis points must total 10000")
	ErrNegativeShareBps       = sdkerrors.Register(ModuleName, 2, "share basis points must not be negative")
	ErrInvalidTreasuryAccount = sdkerrors.Register(ModuleName, 3, "invalid treasury account address")
	ErrEmptyFeeCollector      = sdkerrors.Register(ModuleName, 4, "fee collector name must not be empty")
	ErrNegativeMinFee         = sdkerrors.Register(ModuleName, 5, "minimum protocol fee must not be negative")
	ErrInvalidAuthority       = sdkerrors.Register(ModuleName, 6, "invalid authority address")
	ErrUnauthorized           = sdkerrors.Register(ModuleName, 7, "unauthorized: message sender is not the module authority")
	ErrInvalidParams          = sdkerrors.Register(ModuleName, 8, "invalid parameters")
	ErrInternal               = sdkerrors.Register(ModuleName, 9, "internal error")
)
