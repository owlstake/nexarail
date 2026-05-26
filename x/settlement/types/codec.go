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

	proto.RegisterType((*MsgCreateSettlement)(nil), "nexarail.settlement.v1.MsgCreateSettlement")
	proto.RegisterType((*MsgCreateSettlementResponse)(nil), "nexarail.settlement.v1.MsgCreateSettlementResponse")
	proto.RegisterType((*MsgUpdateSettlementStatus)(nil), "nexarail.settlement.v1.MsgUpdateSettlementStatus")
	proto.RegisterType((*MsgUpdateSettlementStatusResponse)(nil), "nexarail.settlement.v1.MsgUpdateSettlementStatusResponse")
	proto.RegisterType((*MsgUpdateParams)(nil), "nexarail.settlement.v1.MsgUpdateParams")
	proto.RegisterType((*MsgUpdateParamsResponse)(nil), "nexarail.settlement.v1.MsgUpdateParamsResponse")
	proto.RegisterType((*Params)(nil), "nexarail.settlement.v1.Params")
	proto.RegisterType((*GenesisState)(nil), "nexarail.settlement.v1.GenesisState")
}

func RegisterLegacyAminoCodec(cdc *codec.LegacyAmino) {
	cdc.RegisterConcrete(&MsgCreateSettlement{}, "nexarail/settlement/MsgCreateSettlement", nil)
	cdc.RegisterConcrete(&MsgUpdateSettlementStatus{}, "nexarail/settlement/MsgUpdateSettlementStatus", nil)
	cdc.RegisterConcrete(&MsgUpdateParams{}, "nexarail/settlement/MsgUpdateParams", nil)
}

func RegisterInterfaces(registry types.InterfaceRegistry) {
	registry.RegisterImplementations(
		(*sdk.Msg)(nil),
		&MsgCreateSettlement{},
		&MsgUpdateSettlementStatus{},
		&MsgUpdateParams{},
	)
}
