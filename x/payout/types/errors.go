package types

import sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"

var (
	ErrInvalidPayoutID      = sdkerrors.Register(ModuleName, 1, "invalid payout ID")
	ErrInvalidInitiator     = sdkerrors.Register(ModuleName, 2, "invalid initiator")
	ErrInvalidRecipient     = sdkerrors.Register(ModuleName, 3, "invalid recipient")
	ErrInvalidMerchantID    = sdkerrors.Register(ModuleName, 4, "invalid merchant ID")
	ErrInvalidDenom         = sdkerrors.Register(ModuleName, 5, "invalid denom")
	ErrAmountNotPositive    = sdkerrors.Register(ModuleName, 6, "amount not positive")
	ErrInvalidFee           = sdkerrors.Register(ModuleName, 7, "invalid fee/net")
	ErrInvalidStatus        = sdkerrors.Register(ModuleName, 8, "invalid status")
	ErrInvalidPayoutType    = sdkerrors.Register(ModuleName, 9, "invalid payout type")
	ErrPayoutExists         = sdkerrors.Register(ModuleName, 10, "payout exists")
	ErrPayoutNotFound       = sdkerrors.Register(ModuleName, 11, "payout not found")
	ErrPayoutsDisabled      = sdkerrors.Register(ModuleName, 12, "payouts disabled")
	ErrBatchDisabled        = sdkerrors.Register(ModuleName, 13, "batch payouts disabled")
	ErrMerchantNotActive    = sdkerrors.Register(ModuleName, 14, "merchant not active")
	ErrUnauthorized         = sdkerrors.Register(ModuleName, 15, "unauthorized")
	ErrInvalidTransition    = sdkerrors.Register(ModuleName, 16, "invalid transition")
	ErrReferenceTooLong     = sdkerrors.Register(ModuleName, 17, "ref too long")
	ErrMemoTooLong          = sdkerrors.Register(ModuleName, 18, "memo too long")
	ErrFailureReasonTooLong = sdkerrors.Register(ModuleName, 19, "failure reason too long")
	ErrInvalidParams        = sdkerrors.Register(ModuleName, 20, "invalid params")
	ErrBatchNotFound        = sdkerrors.Register(ModuleName, 21, "batch not found")
	ErrAlreadyPaid          = sdkerrors.Register(ModuleName, 22, "payout funds already paid")
	ErrLiveTransferFailed   = sdkerrors.Register(ModuleName, 23, "live payout transfer failed")
)
