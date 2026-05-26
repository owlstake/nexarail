package types

import (
	"github.com/cosmos/cosmos-sdk/codec"
	"github.com/cosmos/cosmos-sdk/codec/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/gogoproto/proto"
)

var ModuleCdc = codec.NewLegacyAmino()

func init() {
	RegisterLegacyAminoCodec(ModuleCdc)
	proto.RegisterType((*MsgCreatePayout)(nil), "nexarail.payout.v1.MsgCreatePayout")
	proto.RegisterType((*MsgCreatePayoutResponse)(nil), "nexarail.payout.v1.MsgCreatePayoutResponse")
	proto.RegisterType((*MsgCreateBatchPayout)(nil), "nexarail.payout.v1.MsgCreateBatchPayout")
	proto.RegisterType((*MsgCreateBatchPayoutResponse)(nil), "nexarail.payout.v1.MsgCreateBatchPayoutResponse")
	proto.RegisterType((*MsgApprovePayout)(nil), "nexarail.payout.v1.MsgApprovePayout")
	proto.RegisterType((*MsgMarkPayoutPaid)(nil), "nexarail.payout.v1.MsgMarkPayoutPaid")
	proto.RegisterType((*MsgCancelPayout)(nil), "nexarail.payout.v1.MsgCancelPayout")
	proto.RegisterType((*MsgFailPayout)(nil), "nexarail.payout.v1.MsgFailPayout")
	proto.RegisterType((*MsgUpdateParams)(nil), "nexarail.payout.v1.MsgUpdateParams")
	proto.RegisterType((*Params)(nil), "nexarail.payout.v1.Params")
	proto.RegisterType((*GenesisState)(nil), "nexarail.payout.v1.GenesisState")
}

func RegisterLegacyAminoCodec(cdc *codec.LegacyAmino) {
	cdc.RegisterConcrete(&MsgCreatePayout{}, "nexarail/payout/MsgCreatePayout", nil)
	cdc.RegisterConcrete(&MsgCreateBatchPayout{}, "nexarail/payout/MsgCreateBatchPayout", nil)
	cdc.RegisterConcrete(&MsgApprovePayout{}, "nexarail/payout/MsgApprovePayout", nil)
	cdc.RegisterConcrete(&MsgMarkPayoutPaid{}, "nexarail/payout/MsgMarkPayoutPaid", nil)
	cdc.RegisterConcrete(&MsgCancelPayout{}, "nexarail/payout/MsgCancelPayout", nil)
	cdc.RegisterConcrete(&MsgFailPayout{}, "nexarail/payout/MsgFailPayout", nil)
	cdc.RegisterConcrete(&MsgUpdateParams{}, "nexarail/payout/MsgUpdateParams", nil)
}

func RegisterInterfaces(r types.InterfaceRegistry) {
	r.RegisterImplementations((*sdk.Msg)(nil),
		&MsgCreatePayout{}, &MsgCreateBatchPayout{}, &MsgApprovePayout{},
		&MsgMarkPayoutPaid{}, &MsgCancelPayout{}, &MsgFailPayout{}, &MsgUpdateParams{},
	)
}
