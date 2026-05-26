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
	proto.RegisterType((*MsgCreateTreasuryAccount)(nil), "nexarail.treasury.v1.MsgCreateTreasuryAccount")
	proto.RegisterType((*MsgCreateBudget)(nil), "nexarail.treasury.v1.MsgCreateBudget")
	proto.RegisterType((*MsgUpdateBudgetStatus)(nil), "nexarail.treasury.v1.MsgUpdateBudgetStatus")
	proto.RegisterType((*MsgCreateGrant)(nil), "nexarail.treasury.v1.MsgCreateGrant")
	proto.RegisterType((*MsgUpdateGrantStatus)(nil), "nexarail.treasury.v1.MsgUpdateGrantStatus")
	proto.RegisterType((*MsgCreateSpendRequest)(nil), "nexarail.treasury.v1.MsgCreateSpendRequest")
	proto.RegisterType((*MsgApproveSpendRequest)(nil), "nexarail.treasury.v1.MsgApproveSpendRequest")
	proto.RegisterType((*MsgRejectSpendRequest)(nil), "nexarail.treasury.v1.MsgRejectSpendRequest")
	proto.RegisterType((*MsgMarkSpendExecuted)(nil), "nexarail.treasury.v1.MsgMarkSpendExecuted")
	proto.RegisterType((*MsgCancelSpendRequest)(nil), "nexarail.treasury.v1.MsgCancelSpendRequest")
	proto.RegisterType((*MsgUpdateParams)(nil), "nexarail.treasury.v1.MsgUpdateParams")
	proto.RegisterType((*Params)(nil), "nexarail.treasury.v1.Params")
}

func RegisterLegacyAminoCodec(cdc *codec.LegacyAmino) {
	cdc.RegisterConcrete(&MsgCreateTreasuryAccount{}, "nexarail/treasury/MsgCreateTreasuryAccount", nil)
	cdc.RegisterConcrete(&MsgCreateBudget{}, "nexarail/treasury/MsgCreateBudget", nil)
	cdc.RegisterConcrete(&MsgUpdateBudgetStatus{}, "nexarail/treasury/MsgUpdateBudgetStatus", nil)
	cdc.RegisterConcrete(&MsgCreateGrant{}, "nexarail/treasury/MsgCreateGrant", nil)
	cdc.RegisterConcrete(&MsgUpdateGrantStatus{}, "nexarail/treasury/MsgUpdateGrantStatus", nil)
	cdc.RegisterConcrete(&MsgCreateSpendRequest{}, "nexarail/treasury/MsgCreateSpendRequest", nil)
	cdc.RegisterConcrete(&MsgApproveSpendRequest{}, "nexarail/treasury/MsgApproveSpendRequest", nil)
	cdc.RegisterConcrete(&MsgRejectSpendRequest{}, "nexarail/treasury/MsgRejectSpendRequest", nil)
	cdc.RegisterConcrete(&MsgMarkSpendExecuted{}, "nexarail/treasury/MsgMarkSpendExecuted", nil)
	cdc.RegisterConcrete(&MsgCancelSpendRequest{}, "nexarail/treasury/MsgCancelSpendRequest", nil)
	cdc.RegisterConcrete(&MsgUpdateParams{}, "nexarail/treasury/MsgUpdateParams", nil)
}

func RegisterInterfaces(r types.InterfaceRegistry) {
	r.RegisterImplementations((*sdk.Msg)(nil),
		&MsgCreateTreasuryAccount{}, &MsgCreateBudget{}, &MsgUpdateBudgetStatus{},
		&MsgCreateGrant{}, &MsgUpdateGrantStatus{}, &MsgCreateSpendRequest{},
		&MsgApproveSpendRequest{}, &MsgRejectSpendRequest{}, &MsgMarkSpendExecuted{},
		&MsgCancelSpendRequest{}, &MsgUpdateParams{},
	)
}
