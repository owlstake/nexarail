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

	proto.RegisterType((*MsgUpdateParams)(nil), "nexarail.fees.v1.MsgUpdateParams")
	proto.RegisterType((*MsgUpdateParamsResponse)(nil), "nexarail.fees.v1.MsgUpdateParamsResponse")
	proto.RegisterType((*Params)(nil), "nexarail.fees.v1.Params")
	proto.RegisterType((*GenesisState)(nil), "nexarail.fees.v1.GenesisState")
	proto.RegisterType((*QueryParamsRequest)(nil), "nexarail.fees.v1.QueryParamsRequest")
	proto.RegisterType((*QueryParamsResponse)(nil), "nexarail.fees.v1.QueryParamsResponse")
	proto.RegisterType((*QueryFeeSplitRequest)(nil), "nexarail.fees.v1.QueryFeeSplitRequest")
	proto.RegisterType((*QueryFeeSplitResponse)(nil), "nexarail.fees.v1.QueryFeeSplitResponse")
}

func RegisterLegacyAminoCodec(cdc *codec.LegacyAmino) {
	cdc.RegisterConcrete(&MsgUpdateParams{}, "nexarail/fees/MsgUpdateParams", nil)
}

func RegisterInterfaces(registry types.InterfaceRegistry) {
	registry.RegisterImplementations(
		(*sdk.Msg)(nil),
		&MsgUpdateParams{},
	)
}
