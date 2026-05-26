package types

import sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"

var (
	ErrInvalidID         = sdkerrors.Register(ModuleName, 1, "invalid ID")
	ErrInvalidCategory   = sdkerrors.Register(ModuleName, 2, "invalid category")
	ErrInvalidRequester  = sdkerrors.Register(ModuleName, 3, "invalid requester")
	ErrInvalidRecipient  = sdkerrors.Register(ModuleName, 4, "invalid recipient")
	ErrInvalidAmount     = sdkerrors.Register(ModuleName, 5, "invalid amount")
	ErrInvalidStatus     = sdkerrors.Register(ModuleName, 6, "invalid status")
	ErrRecordExists      = sdkerrors.Register(ModuleName, 7, "record exists")
	ErrRecordNotFound    = sdkerrors.Register(ModuleName, 8, "record not found")
	ErrTreasuryDisabled  = sdkerrors.Register(ModuleName, 9, "treasury disabled")
	ErrBudgetsDisabled   = sdkerrors.Register(ModuleName, 10, "budgets disabled")
	ErrGrantsDisabled    = sdkerrors.Register(ModuleName, 11, "grants disabled")
	ErrSpendDisabled     = sdkerrors.Register(ModuleName, 12, "spend requests disabled")
	ErrBudgetCapacity    = sdkerrors.Register(ModuleName, 13, "budget capacity exceeded")
	ErrUnauthorized      = sdkerrors.Register(ModuleName, 14, "unauthorized")
	ErrInvalidTransition = sdkerrors.Register(ModuleName, 15, "invalid transition")
	ErrInvalidParams     = sdkerrors.Register(ModuleName, 16, "invalid params")
	ErrAccountNotFound   = sdkerrors.Register(ModuleName, 17, "account not found")
)
