package keeper

import (
	"context"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/nexarail/chain/x/escrow/types"
	grpc "google.golang.org/grpc"
)

type MsgServer struct{ keeper Keeper }

func NewMsgServerImpl(k Keeper) MsgServer { return MsgServer{keeper: k} }

func (ms MsgServer) CreateEscrow(ctx context.Context, m *types.MsgCreateEscrow) (*types.MsgCreateEscrowResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	_, err := ms.keeper.CreateEscrow(sdk.UnwrapSDKContext(ctx), m)
	return &types.MsgCreateEscrowResponse{}, err
}
func (ms MsgServer) ReleaseEscrow(ctx context.Context, m *types.MsgReleaseEscrow) (*types.MsgReleaseEscrowResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgReleaseEscrowResponse{}, ms.keeper.ReleaseEscrow(sdk.UnwrapSDKContext(ctx), m)
}
func (ms MsgServer) RefundEscrow(ctx context.Context, m *types.MsgRefundEscrow) (*types.MsgRefundEscrowResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgRefundEscrowResponse{}, ms.keeper.RefundEscrow(sdk.UnwrapSDKContext(ctx), m)
}
func (ms MsgServer) OpenDispute(ctx context.Context, m *types.MsgOpenDispute) (*types.MsgOpenDisputeResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgOpenDisputeResponse{}, ms.keeper.OpenDispute(sdk.UnwrapSDKContext(ctx), m)
}
func (ms MsgServer) ResolveDispute(ctx context.Context, m *types.MsgResolveDispute) (*types.MsgResolveDisputeResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgResolveDisputeResponse{}, ms.keeper.ResolveDispute(sdk.UnwrapSDKContext(ctx), m)
}
func (ms MsgServer) CancelEscrow(ctx context.Context, m *types.MsgCancelEscrow) (*types.MsgCancelEscrowResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgCancelEscrowResponse{}, ms.keeper.CancelEscrow(sdk.UnwrapSDKContext(ctx), m)
}
func (ms MsgServer) UpdateParams(ctx context.Context, m *types.MsgUpdateParams) (*types.MsgUpdateParamsResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgUpdateParamsResponse{}, ms.keeper.UpdateParams(sdk.UnwrapSDKContext(ctx), m.Authority, m.Params)
}

func RegisterMsgServer(s grpc.ServiceRegistrar, srv MsgServer) {
	s.RegisterService(&_Msg_serviceDesc, srv)
}

var _Msg_serviceDesc = grpc.ServiceDesc{
	ServiceName: "nexarail.escrow.v1.Msg",
	HandlerType: (*interface{})(nil),
	Methods: []grpc.MethodDesc{
		{MethodName: "CreateEscrow", Handler: _h(0)},
		{MethodName: "ReleaseEscrow", Handler: _h(1)},
		{MethodName: "RefundEscrow", Handler: _h(2)},
		{MethodName: "OpenDispute", Handler: _h(3)},
		{MethodName: "ResolveDispute", Handler: _h(4)},
		{MethodName: "CancelEscrow", Handler: _h(5)},
		{MethodName: "UpdateParams", Handler: _h(6)},
	},
	Streams:  []grpc.StreamDesc{},
	Metadata: "nexarail/escrow/v1/escrow.proto",
}

func _h(method int) func(interface{}, context.Context, func(interface{}) error, grpc.UnaryServerInterceptor) (interface{}, error) {
	return func(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
		switch method {
		case 0:
			in := new(types.MsgCreateEscrow)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).CreateEscrow(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.escrow.v1.Msg/CreateEscrow"}
			return interceptor(ctx, in, info, func(ctx context.Context, req interface{}) (interface{}, error) {
				return srv.(MsgServer).CreateEscrow(ctx, req.(*types.MsgCreateEscrow))
			})
		case 1:
			in := new(types.MsgReleaseEscrow)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).ReleaseEscrow(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.escrow.v1.Msg/ReleaseEscrow"}
			return interceptor(ctx, in, info, func(ctx context.Context, req interface{}) (interface{}, error) {
				return srv.(MsgServer).ReleaseEscrow(ctx, req.(*types.MsgReleaseEscrow))
			})
		case 2:
			in := new(types.MsgRefundEscrow)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).RefundEscrow(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.escrow.v1.Msg/RefundEscrow"}
			return interceptor(ctx, in, info, func(ctx context.Context, req interface{}) (interface{}, error) {
				return srv.(MsgServer).RefundEscrow(ctx, req.(*types.MsgRefundEscrow))
			})
		case 3:
			in := new(types.MsgOpenDispute)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).OpenDispute(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.escrow.v1.Msg/OpenDispute"}
			return interceptor(ctx, in, info, func(ctx context.Context, req interface{}) (interface{}, error) {
				return srv.(MsgServer).OpenDispute(ctx, req.(*types.MsgOpenDispute))
			})
		case 4:
			in := new(types.MsgResolveDispute)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).ResolveDispute(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.escrow.v1.Msg/ResolveDispute"}
			return interceptor(ctx, in, info, func(ctx context.Context, req interface{}) (interface{}, error) {
				return srv.(MsgServer).ResolveDispute(ctx, req.(*types.MsgResolveDispute))
			})
		case 5:
			in := new(types.MsgCancelEscrow)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).CancelEscrow(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.escrow.v1.Msg/CancelEscrow"}
			return interceptor(ctx, in, info, func(ctx context.Context, req interface{}) (interface{}, error) {
				return srv.(MsgServer).CancelEscrow(ctx, req.(*types.MsgCancelEscrow))
			})
		case 6:
			in := new(types.MsgUpdateParams)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).UpdateParams(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.escrow.v1.Msg/UpdateParams"}
			return interceptor(ctx, in, info, func(ctx context.Context, req interface{}) (interface{}, error) {
				return srv.(MsgServer).UpdateParams(ctx, req.(*types.MsgUpdateParams))
			})
		}
		return nil, nil
	}
}
