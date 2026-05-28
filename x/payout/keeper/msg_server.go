package keeper

import (
	"context"
	"fmt"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/nexarail/chain/x/payout/types"
	grpc "google.golang.org/grpc"
)

type MsgServer struct{ keeper Keeper }

func NewMsgServerImpl(k Keeper) MsgServer { return MsgServer{keeper: k} }

func (ms MsgServer) CreatePayout(ctx context.Context, m *types.MsgCreatePayout) (*types.MsgCreatePayoutResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgCreatePayoutResponse{}, ms.keeper.CreatePayout(sdk.UnwrapSDKContext(ctx), m)
}
func (ms MsgServer) CreateBatchPayout(ctx context.Context, m *types.MsgCreateBatchPayout) (*types.MsgCreateBatchPayoutResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgCreateBatchPayoutResponse{}, ms.keeper.CreateBatchPayout(sdk.UnwrapSDKContext(ctx), m)
}
func (ms MsgServer) ApprovePayout(ctx context.Context, m *types.MsgApprovePayout) (*types.MsgApprovePayoutResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgApprovePayoutResponse{}, ms.keeper.ApprovePayout(sdk.UnwrapSDKContext(ctx), m)
}
func (ms MsgServer) MarkPayoutPaid(ctx context.Context, m *types.MsgMarkPayoutPaid) (*types.MsgMarkPayoutPaidResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgMarkPayoutPaidResponse{}, ms.keeper.MarkPayoutPaid(sdk.UnwrapSDKContext(ctx), m)
}
func (ms MsgServer) CancelPayout(ctx context.Context, m *types.MsgCancelPayout) (*types.MsgCancelPayoutResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgCancelPayoutResponse{}, ms.keeper.CancelPayout(sdk.UnwrapSDKContext(ctx), m)
}
func (ms MsgServer) FailPayout(ctx context.Context, m *types.MsgFailPayout) (*types.MsgFailPayoutResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgFailPayoutResponse{}, ms.keeper.FailPayout(sdk.UnwrapSDKContext(ctx), m)
}
func (ms MsgServer) UpdateParams(ctx context.Context, m *types.MsgUpdateParams) (*types.MsgUpdateParamsResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	sdkCtx := sdk.UnwrapSDKContext(ctx)
	if err := ms.keeper.UpdateParams(sdkCtx, m.Authority, m.Params); err != nil {
		return nil, err
	}
	sdkCtx.EventManager().EmitEvent(
		sdk.NewEvent(
			types.EventUpdateParams,
			sdk.NewAttribute("authority", m.Authority),
			sdk.NewAttribute("live_enabled", fmt.Sprintf("%t", m.Params.LiveEnabled)),
		),
	)
	return &types.MsgUpdateParamsResponse{}, nil
}

func RegisterMsgServer(s grpc.ServiceRegistrar, srv MsgServer) {
	s.RegisterService(&_Msg_serviceDesc, srv)
}

var _Msg_serviceDesc = grpc.ServiceDesc{
	ServiceName: "nexarail.payout.v1.Msg", HandlerType: (*interface{})(nil),
	Methods: []grpc.MethodDesc{
		{MethodName: "CreatePayout", Handler: _mh(0)},
		{MethodName: "CreateBatchPayout", Handler: _mh(1)},
		{MethodName: "ApprovePayout", Handler: _mh(2)},
		{MethodName: "MarkPayoutPaid", Handler: _mh(3)},
		{MethodName: "CancelPayout", Handler: _mh(4)},
		{MethodName: "FailPayout", Handler: _mh(5)},
		{MethodName: "UpdateParams", Handler: _mh(6)},
	}, Streams: []grpc.StreamDesc{}, Metadata: "nexarail/payout/v1/payout.proto",
}

func _mh(m int) func(interface{}, context.Context, func(interface{}) error, grpc.UnaryServerInterceptor) (interface{}, error) {
	return func(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
		switch m {
		case 0:
			in := new(types.MsgCreatePayout)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).CreatePayout(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.payout.v1.Msg/CreatePayout"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(MsgServer).CreatePayout(c, r.(*types.MsgCreatePayout))
			})
		case 1:
			in := new(types.MsgCreateBatchPayout)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).CreateBatchPayout(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.payout.v1.Msg/CreateBatchPayout"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(MsgServer).CreateBatchPayout(c, r.(*types.MsgCreateBatchPayout))
			})
		case 2:
			in := new(types.MsgApprovePayout)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).ApprovePayout(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.payout.v1.Msg/ApprovePayout"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(MsgServer).ApprovePayout(c, r.(*types.MsgApprovePayout))
			})
		case 3:
			in := new(types.MsgMarkPayoutPaid)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).MarkPayoutPaid(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.payout.v1.Msg/MarkPayoutPaid"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(MsgServer).MarkPayoutPaid(c, r.(*types.MsgMarkPayoutPaid))
			})
		case 4:
			in := new(types.MsgCancelPayout)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).CancelPayout(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.payout.v1.Msg/CancelPayout"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(MsgServer).CancelPayout(c, r.(*types.MsgCancelPayout))
			})
		case 5:
			in := new(types.MsgFailPayout)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).FailPayout(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.payout.v1.Msg/FailPayout"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(MsgServer).FailPayout(c, r.(*types.MsgFailPayout))
			})
		case 6:
			in := new(types.MsgUpdateParams)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).UpdateParams(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.payout.v1.Msg/UpdateParams"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(MsgServer).UpdateParams(c, r.(*types.MsgUpdateParams))
			})
		}
		return nil, nil
	}
}
