package keeper

import (
	"context"

	sdk "github.com/cosmos/cosmos-sdk/types"
	grpc "google.golang.org/grpc"

	"github.com/nexarail/chain/x/merchant/types"
)

type MsgServer struct {
	keeper Keeper
}

func NewMsgServerImpl(k Keeper) MsgServer {
	return MsgServer{keeper: k}
}

func (ms MsgServer) RegisterMerchant(ctx context.Context, msg *types.MsgRegisterMerchant) (*types.MsgRegisterMerchantResponse, error) {
	if err := msg.ValidateBasic(); err != nil {
		return nil, err
	}
	sdkCtx := sdk.UnwrapSDKContext(ctx)
	if err := ms.keeper.RegisterMerchant(sdkCtx, msg); err != nil {
		return nil, err
	}
	return &types.MsgRegisterMerchantResponse{}, nil
}

func (ms MsgServer) UpdateMerchant(ctx context.Context, msg *types.MsgUpdateMerchant) (*types.MsgUpdateMerchantResponse, error) {
	if err := msg.ValidateBasic(); err != nil {
		return nil, err
	}
	sdkCtx := sdk.UnwrapSDKContext(ctx)
	if err := ms.keeper.UpdateMerchant(sdkCtx, msg); err != nil {
		return nil, err
	}
	return &types.MsgUpdateMerchantResponse{}, nil
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
		),
	)
	return &types.MsgUpdateParamsResponse{}, nil
}

func (ms MsgServer) SetMerchantStatus(ctx context.Context, msg *types.MsgSetMerchantStatus) (*types.MsgSetMerchantStatusResponse, error) {
	if err := msg.ValidateBasic(); err != nil {
		return nil, err
	}
	sdkCtx := sdk.UnwrapSDKContext(ctx)
	if err := ms.keeper.SetMerchantStatus(sdkCtx, msg.Authority, msg.Owner, msg.Status); err != nil {
		return nil, err
	}
	return &types.MsgSetMerchantStatusResponse{}, nil
}

func (ms MsgServer) SetVerificationStatus(ctx context.Context, msg *types.MsgSetVerificationStatus) (*types.MsgSetVerificationStatusResponse, error) {
	if err := msg.ValidateBasic(); err != nil {
		return nil, err
	}
	sdkCtx := sdk.UnwrapSDKContext(ctx)
	if err := ms.keeper.SetVerificationStatus(sdkCtx, msg.Authority, msg.Owner, msg.Status); err != nil {
		return nil, err
	}
	return &types.MsgSetVerificationStatusResponse{}, nil
}

func (ms MsgServer) SetRebateTier(ctx context.Context, msg *types.MsgSetRebateTier) (*types.MsgSetRebateTierResponse, error) {
	if err := msg.ValidateBasic(); err != nil {
		return nil, err
	}
	sdkCtx := sdk.UnwrapSDKContext(ctx)
	if err := ms.keeper.SetRebateTier(sdkCtx, msg.Authority, msg.Owner, msg.Tier); err != nil {
		return nil, err
	}
	return &types.MsgSetRebateTierResponse{}, nil
}

// --- gRPC registration ---

func RegisterMsgServer(s grpc.ServiceRegistrar, srv MsgServer) {
	s.RegisterService(&_Msg_serviceDesc, srv)
}

var _Msg_serviceDesc = grpc.ServiceDesc{
	ServiceName: "nexarail.merchant.v1.Msg",
	HandlerType: (*interface{})(nil),
	Methods: []grpc.MethodDesc{
		{MethodName: "RegisterMerchant", Handler: _Msg_RegisterMerchant_Handler},
		{MethodName: "UpdateMerchant", Handler: _Msg_UpdateMerchant_Handler},
		{MethodName: "UpdateParams", Handler: _Msg_UpdateParams_Handler},
		{MethodName: "SetMerchantStatus", Handler: _Msg_SetMerchantStatus_Handler},
		{MethodName: "SetVerificationStatus", Handler: _Msg_SetVerificationStatus_Handler},
		{MethodName: "SetRebateTier", Handler: _Msg_SetRebateTier_Handler},
	},
	Streams:  []grpc.StreamDesc{},
	Metadata: "nexarail/merchant/v1/merchant.proto",
}

func _Msg_RegisterMerchant_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(types.MsgRegisterMerchant)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(MsgServer).RegisterMerchant(ctx, in)
	}
	info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.merchant.v1.Msg/RegisterMerchant"}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(MsgServer).RegisterMerchant(ctx, req.(*types.MsgRegisterMerchant))
	}
	return interceptor(ctx, in, info, handler)
}

func _Msg_UpdateMerchant_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(types.MsgUpdateMerchant)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(MsgServer).UpdateMerchant(ctx, in)
	}
	info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.merchant.v1.Msg/UpdateMerchant"}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(MsgServer).UpdateMerchant(ctx, req.(*types.MsgUpdateMerchant))
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
	info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.merchant.v1.Msg/UpdateParams"}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(MsgServer).UpdateParams(ctx, req.(*types.MsgUpdateParams))
	}
	return interceptor(ctx, in, info, handler)
}

func _Msg_SetMerchantStatus_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(types.MsgSetMerchantStatus)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(MsgServer).SetMerchantStatus(ctx, in)
	}
	info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.merchant.v1.Msg/SetMerchantStatus"}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(MsgServer).SetMerchantStatus(ctx, req.(*types.MsgSetMerchantStatus))
	}
	return interceptor(ctx, in, info, handler)
}

func _Msg_SetVerificationStatus_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(types.MsgSetVerificationStatus)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(MsgServer).SetVerificationStatus(ctx, in)
	}
	info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.merchant.v1.Msg/SetVerificationStatus"}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(MsgServer).SetVerificationStatus(ctx, req.(*types.MsgSetVerificationStatus))
	}
	return interceptor(ctx, in, info, handler)
}

func _Msg_SetRebateTier_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(types.MsgSetRebateTier)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(MsgServer).SetRebateTier(ctx, in)
	}
	info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.merchant.v1.Msg/SetRebateTier"}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(MsgServer).SetRebateTier(ctx, req.(*types.MsgSetRebateTier))
	}
	return interceptor(ctx, in, info, handler)
}
