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

	proto.RegisterType((*MsgRegisterMerchant)(nil), "nexarail.merchant.v1.MsgRegisterMerchant")
	proto.RegisterType((*MsgRegisterMerchantResponse)(nil), "nexarail.merchant.v1.MsgRegisterMerchantResponse")
	proto.RegisterType((*MsgUpdateMerchant)(nil), "nexarail.merchant.v1.MsgUpdateMerchant")
	proto.RegisterType((*MsgUpdateMerchantResponse)(nil), "nexarail.merchant.v1.MsgUpdateMerchantResponse")
	proto.RegisterType((*MsgUpdateParams)(nil), "nexarail.merchant.v1.MsgUpdateParams")
	proto.RegisterType((*MsgUpdateParamsResponse)(nil), "nexarail.merchant.v1.MsgUpdateParamsResponse")
	proto.RegisterType((*MsgSetMerchantStatus)(nil), "nexarail.merchant.v1.MsgSetMerchantStatus")
	proto.RegisterType((*MsgSetMerchantStatusResponse)(nil), "nexarail.merchant.v1.MsgSetMerchantStatusResponse")
	proto.RegisterType((*MsgSetVerificationStatus)(nil), "nexarail.merchant.v1.MsgSetVerificationStatus")
	proto.RegisterType((*MsgSetVerificationStatusResponse)(nil), "nexarail.merchant.v1.MsgSetVerificationStatusResponse")
	proto.RegisterType((*MsgSetRebateTier)(nil), "nexarail.merchant.v1.MsgSetRebateTier")
	proto.RegisterType((*MsgSetRebateTierResponse)(nil), "nexarail.merchant.v1.MsgSetRebateTierResponse")
	proto.RegisterType((*Params)(nil), "nexarail.merchant.v1.Params")
	proto.RegisterType((*GenesisState)(nil), "nexarail.merchant.v1.GenesisState")
	proto.RegisterType((*QueryParamsRequest)(nil), "nexarail.merchant.v1.QueryParamsRequest")
	proto.RegisterType((*QueryParamsResponse)(nil), "nexarail.merchant.v1.QueryParamsResponse")
	proto.RegisterType((*QueryMerchantRequest)(nil), "nexarail.merchant.v1.QueryMerchantRequest")
	proto.RegisterType((*QueryMerchantResponse)(nil), "nexarail.merchant.v1.QueryMerchantResponse")
	proto.RegisterType((*QueryMerchantsRequest)(nil), "nexarail.merchant.v1.QueryMerchantsRequest")
	proto.RegisterType((*QueryMerchantsResponse)(nil), "nexarail.merchant.v1.QueryMerchantsResponse")
}

func RegisterLegacyAminoCodec(cdc *codec.LegacyAmino) {
	cdc.RegisterConcrete(&MsgRegisterMerchant{}, "nexarail/merchant/MsgRegisterMerchant", nil)
	cdc.RegisterConcrete(&MsgUpdateMerchant{}, "nexarail/merchant/MsgUpdateMerchant", nil)
	cdc.RegisterConcrete(&MsgUpdateParams{}, "nexarail/merchant/MsgUpdateParams", nil)
	cdc.RegisterConcrete(&MsgSetMerchantStatus{}, "nexarail/merchant/MsgSetMerchantStatus", nil)
	cdc.RegisterConcrete(&MsgSetVerificationStatus{}, "nexarail/merchant/MsgSetVerificationStatus", nil)
	cdc.RegisterConcrete(&MsgSetRebateTier{}, "nexarail/merchant/MsgSetRebateTier", nil)
}

func RegisterInterfaces(registry types.InterfaceRegistry) {
	registry.RegisterImplementations(
		(*sdk.Msg)(nil),
		&MsgRegisterMerchant{},
		&MsgUpdateMerchant{},
		&MsgUpdateParams{},
		&MsgSetMerchantStatus{},
		&MsgSetVerificationStatus{},
		&MsgSetRebateTier{},
	)
}
