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
	proto.RegisterType((*MsgCreateEscrow)(nil), "nexarail.escrow.v1.MsgCreateEscrow")
	proto.RegisterType((*MsgCreateEscrowResponse)(nil), "nexarail.escrow.v1.MsgCreateEscrowResponse")
	proto.RegisterType((*MsgReleaseEscrow)(nil), "nexarail.escrow.v1.MsgReleaseEscrow")
	proto.RegisterType((*MsgReleaseEscrowResponse)(nil), "nexarail.escrow.v1.MsgReleaseEscrowResponse")
	proto.RegisterType((*MsgRefundEscrow)(nil), "nexarail.escrow.v1.MsgRefundEscrow")
	proto.RegisterType((*MsgRefundEscrowResponse)(nil), "nexarail.escrow.v1.MsgRefundEscrowResponse")
	proto.RegisterType((*MsgOpenDispute)(nil), "nexarail.escrow.v1.MsgOpenDispute")
	proto.RegisterType((*MsgOpenDisputeResponse)(nil), "nexarail.escrow.v1.MsgOpenDisputeResponse")
	proto.RegisterType((*MsgResolveDispute)(nil), "nexarail.escrow.v1.MsgResolveDispute")
	proto.RegisterType((*MsgResolveDisputeResponse)(nil), "nexarail.escrow.v1.MsgResolveDisputeResponse")
	proto.RegisterType((*MsgCancelEscrow)(nil), "nexarail.escrow.v1.MsgCancelEscrow")
	proto.RegisterType((*MsgCancelEscrowResponse)(nil), "nexarail.escrow.v1.MsgCancelEscrowResponse")
	proto.RegisterType((*MsgUpdateParams)(nil), "nexarail.escrow.v1.MsgUpdateParams")
	proto.RegisterType((*MsgUpdateParamsResponse)(nil), "nexarail.escrow.v1.MsgUpdateParamsResponse")
	proto.RegisterType((*Params)(nil), "nexarail.escrow.v1.Params")
	proto.RegisterType((*GenesisState)(nil), "nexarail.escrow.v1.GenesisState")
}

func RegisterLegacyAminoCodec(cdc *codec.LegacyAmino) {
	cdc.RegisterConcrete(&MsgCreateEscrow{}, "nexarail/escrow/MsgCreateEscrow", nil)
	cdc.RegisterConcrete(&MsgReleaseEscrow{}, "nexarail/escrow/MsgReleaseEscrow", nil)
	cdc.RegisterConcrete(&MsgRefundEscrow{}, "nexarail/escrow/MsgRefundEscrow", nil)
	cdc.RegisterConcrete(&MsgOpenDispute{}, "nexarail/escrow/MsgOpenDispute", nil)
	cdc.RegisterConcrete(&MsgResolveDispute{}, "nexarail/escrow/MsgResolveDispute", nil)
	cdc.RegisterConcrete(&MsgCancelEscrow{}, "nexarail/escrow/MsgCancelEscrow", nil)
	cdc.RegisterConcrete(&MsgUpdateParams{}, "nexarail/escrow/MsgUpdateParams", nil)
}

func RegisterInterfaces(registry types.InterfaceRegistry) {
	registry.RegisterImplementations((*sdk.Msg)(nil),
		&MsgCreateEscrow{}, &MsgReleaseEscrow{}, &MsgRefundEscrow{}, &MsgOpenDispute{},
		&MsgResolveDispute{}, &MsgCancelEscrow{}, &MsgUpdateParams{},
	)
}
