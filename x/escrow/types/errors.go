package types

import sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"

var (
	ErrInvalidEscrowID       = sdkerrors.Register(ModuleName, 1, "invalid escrow ID")
	ErrInvalidBuyer          = sdkerrors.Register(ModuleName, 2, "invalid buyer address")
	ErrInvalidSeller         = sdkerrors.Register(ModuleName, 3, "invalid seller address")
	ErrInvalidMerchantID     = sdkerrors.Register(ModuleName, 4, "invalid merchant ID")
	ErrInvalidDenom          = sdkerrors.Register(ModuleName, 5, "invalid asset denom")
	ErrAmountNotPositive     = sdkerrors.Register(ModuleName, 6, "amount must be positive")
	ErrInvalidFee            = sdkerrors.Register(ModuleName, 7, "invalid platform fee or seller amount")
	ErrInvalidStatus         = sdkerrors.Register(ModuleName, 8, "invalid escrow status")
	ErrInvalidDisputeStatus  = sdkerrors.Register(ModuleName, 9, "invalid dispute status")
	ErrEscrowExists          = sdkerrors.Register(ModuleName, 10, "escrow already exists")
	ErrEscrowNotFound        = sdkerrors.Register(ModuleName, 11, "escrow not found")
	ErrEscrowsDisabled       = sdkerrors.Register(ModuleName, 12, "escrows are disabled")
	ErrMerchantNotActive     = sdkerrors.Register(ModuleName, 13, "merchant is not active")
	ErrUnauthorized          = sdkerrors.Register(ModuleName, 14, "unauthorized")
	ErrInvalidTransition     = sdkerrors.Register(ModuleName, 15, "invalid status transition")
	ErrReferenceTooLong      = sdkerrors.Register(ModuleName, 16, "reference too long")
	ErrMemoTooLong           = sdkerrors.Register(ModuleName, 17, "memo too long")
	ErrDisputeReasonTooLong  = sdkerrors.Register(ModuleName, 18, "dispute reason too long")
	ErrResolutionNoteTooLong = sdkerrors.Register(ModuleName, 19, "resolution note too long")
	ErrInvalidExpiry         = sdkerrors.Register(ModuleName, 20, "invalid expiry")
	ErrInvalidParams         = sdkerrors.Register(ModuleName, 21, "invalid parameters")
)
