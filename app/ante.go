package app

import (
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/x/auth/ante"
	"github.com/cosmos/cosmos-sdk/x/auth/signing"
	bankkeeper "github.com/cosmos/cosmos-sdk/x/bank/keeper"
)

// NewAnteHandler returns an AnteHandler that checks and increments sequence
// numbers, checks signatures, and deducts fees.
func NewAnteHandler(
	ak ante.AccountKeeper,
	bk bankkeeper.Keeper,
	sk signing.SignModeHandler,
	fk ante.FeegrantKeeper,
) sdk.AnteHandler {
	handler, err := ante.NewAnteHandler(
		ante.HandlerOptions{
			AccountKeeper:   ak,
			BankKeeper:      bk,
			SignModeHandler: sk,
			FeegrantKeeper:  fk,
			SigGasConsumer:  ante.DefaultSigVerificationGasConsumer,
		},
	)
	if err != nil {
		panic(err)
	}
	return handler
}
