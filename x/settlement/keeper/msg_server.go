package keeper

import (
	"context"
	"fmt"

	sdk "github.com/cosmos/cosmos-sdk/types"
	grpc "google.golang.org/grpc"

	"github.com/nexarail/chain/x/settlement/types"
)

type MsgServer struct {
	keeper Keeper
}

func NewMsgServerImpl(k Keeper) MsgServer { return MsgServer{keeper: k} }

func (ms MsgServer) CreateSettlement(ctx context.Context, msg *types.MsgCreateSettlement) (*types.MsgCreateSettlementResponse, error) {
	if err := msg.ValidateBasic(); err != nil {
		return nil, err
	}
	s, err := ms.keeper.CreateSettlement(sdk.UnwrapSDKContext(ctx), msg)
	if err != nil {
		return nil, err
	}
	return &types.MsgCreateSettlementResponse{Id: s.Id}, nil
}

func (ms MsgServer) UpdateSettlementStatus(ctx context.Context, msg *types.MsgUpdateSettlementStatus) (*types.MsgUpdateSettlementStatusResponse, error) {
	if err := msg.ValidateBasic(); err != nil {
		return nil, err
	}
	if err := ms.keeper.UpdateSettlementStatus(sdk.UnwrapSDKContext(ctx), msg.Authority, msg.Id, msg.Status); err != nil {
		return nil, err
	}
	return &types.MsgUpdateSettlementStatusResponse{}, nil
}

func (ms MsgServer) UpdateParams(ctx context.Context, msg *types.MsgUpdateParams) (*types.MsgUpdateParamsResponse, error) {
	if err := msg.ValidateBasic(); err != nil {
		return nil, err
	}
	sdkCtx := sdk.UnwrapSDKContext(ctx)
	if err := ms.keeper.UpdateParams(sdkCtx, msg.Authority, msg.Params); err != nil {
		return nil, err
	}
	sdkCtx.EventManager().EmitEvent(
		sdk.NewEvent(
			types.EventTypeUpdateParams,
			sdk.NewAttribute("authority", msg.Authority),
			sdk.NewAttribute("live_enabled", fmt.Sprintf("%t", msg.Params.LiveEnabled)),
		),
	)
	return &types.MsgUpdateParamsResponse{}, nil
}

// --- gRPC ---

func RegisterMsgServer(s grpc.ServiceRegistrar, srv MsgServer) {
	s.RegisterService(&_Msg_serviceDesc, srv)
}

var _Msg_serviceDesc = grpc.ServiceDesc{
	ServiceName: "nexarail.settlement.v1.Msg",
	HandlerType: (*interface{})(nil),
	Methods: []grpc.MethodDesc{
		{MethodName: "CreateSettlement", Handler: _Msg_CreateSettlement_Handler},
		{MethodName: "UpdateSettlementStatus", Handler: _Msg_UpdateSettlementStatus_Handler},
		{MethodName: "UpdateParams", Handler: _Msg_UpdateParams_Handler},
	},
	Streams:  []grpc.StreamDesc{},
	Metadata: "nexarail/settlement/v1/settlement.proto",
}

func _Msg_CreateSettlement_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(types.MsgCreateSettlement)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(MsgServer).CreateSettlement(ctx, in)
	}
	info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.settlement.v1.Msg/CreateSettlement"}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(MsgServer).CreateSettlement(ctx, req.(*types.MsgCreateSettlement))
	}
	return interceptor(ctx, in, info, handler)
}

func _Msg_UpdateSettlementStatus_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(types.MsgUpdateSettlementStatus)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(MsgServer).UpdateSettlementStatus(ctx, in)
	}
	info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.settlement.v1.Msg/UpdateSettlementStatus"}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(MsgServer).UpdateSettlementStatus(ctx, req.(*types.MsgUpdateSettlementStatus))
	}
	return interceptor(ctx, in, info, handler)
}

func _Msg_UpdateParams_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(types.MsgUpdateParams)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(MsgServer).UpdateParams(ctx, in)
	}
	info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.settlement.v1.Msg/UpdateParams"}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(MsgServer).UpdateParams(ctx, req.(*types.MsgUpdateParams))
	}
	return interceptor(ctx, in, info, handler)
}
