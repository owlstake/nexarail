package keeper

import (
	"context"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/nexarail/chain/x/treasury/types"
	grpc "google.golang.org/grpc"
)

type MsgServer struct{ keeper Keeper }

func NewMsgServerImpl(k Keeper) MsgServer { return MsgServer{keeper: k} }

func (ms MsgServer) CreateTreasuryAccount(ctx context.Context, m *types.MsgCreateTreasuryAccount) (*types.MsgCreateTreasuryAccountResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgCreateTreasuryAccountResponse{}, ms.keeper.CreateTreasuryAccount(sdk.UnwrapSDKContext(ctx), m)
}
func (ms MsgServer) CreateBudget(ctx context.Context, m *types.MsgCreateBudget) (*types.MsgCreateBudgetResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgCreateBudgetResponse{}, ms.keeper.CreateBudget(sdk.UnwrapSDKContext(ctx), m)
}
func (ms MsgServer) UpdateBudgetStatus(ctx context.Context, m *types.MsgUpdateBudgetStatus) (*types.MsgUpdateBudgetStatusResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgUpdateBudgetStatusResponse{}, ms.keeper.UpdateBudgetStatus(sdk.UnwrapSDKContext(ctx), m)
}
func (ms MsgServer) CreateGrant(ctx context.Context, m *types.MsgCreateGrant) (*types.MsgCreateGrantResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgCreateGrantResponse{}, ms.keeper.CreateGrant(sdk.UnwrapSDKContext(ctx), m)
}
func (ms MsgServer) UpdateGrantStatus(ctx context.Context, m *types.MsgUpdateGrantStatus) (*types.MsgUpdateGrantStatusResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgUpdateGrantStatusResponse{}, ms.keeper.UpdateGrantStatus(sdk.UnwrapSDKContext(ctx), m)
}
func (ms MsgServer) CreateSpendRequest(ctx context.Context, m *types.MsgCreateSpendRequest) (*types.MsgCreateSpendRequestResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgCreateSpendRequestResponse{}, ms.keeper.CreateSpendRequest(sdk.UnwrapSDKContext(ctx), m)
}
func (ms MsgServer) ApproveSpendRequest(ctx context.Context, m *types.MsgApproveSpendRequest) (*types.MsgApproveSpendRequestResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgApproveSpendRequestResponse{}, ms.keeper.ApproveSpendRequest(sdk.UnwrapSDKContext(ctx), m)
}
func (ms MsgServer) RejectSpendRequest(ctx context.Context, m *types.MsgRejectSpendRequest) (*types.MsgRejectSpendRequestResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgRejectSpendRequestResponse{}, ms.keeper.RejectSpendRequest(sdk.UnwrapSDKContext(ctx), m)
}
func (ms MsgServer) MarkSpendExecuted(ctx context.Context, m *types.MsgMarkSpendExecuted) (*types.MsgMarkSpendExecutedResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgMarkSpendExecutedResponse{}, ms.keeper.MarkSpendExecuted(sdk.UnwrapSDKContext(ctx), m)
}
func (ms MsgServer) CancelSpendRequest(ctx context.Context, m *types.MsgCancelSpendRequest) (*types.MsgCancelSpendRequestResponse, error) {
	if err := m.ValidateBasic(); err != nil {
		return nil, err
	}
	return &types.MsgCancelSpendRequestResponse{}, ms.keeper.CancelSpendRequest(sdk.UnwrapSDKContext(ctx), m)
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

var _Msg_serviceDesc = grpc.ServiceDesc{ServiceName: "nexarail.treasury.v1.Msg", HandlerType: (*interface{})(nil),
	Methods: []grpc.MethodDesc{
		{MethodName: "CreateTreasuryAccount", Handler: _mh(0)}, {MethodName: "CreateBudget", Handler: _mh(1)},
		{MethodName: "UpdateBudgetStatus", Handler: _mh(2)}, {MethodName: "CreateGrant", Handler: _mh(3)},
		{MethodName: "UpdateGrantStatus", Handler: _mh(4)}, {MethodName: "CreateSpendRequest", Handler: _mh(5)},
		{MethodName: "ApproveSpendRequest", Handler: _mh(6)}, {MethodName: "RejectSpendRequest", Handler: _mh(7)},
		{MethodName: "MarkSpendExecuted", Handler: _mh(8)}, {MethodName: "CancelSpendRequest", Handler: _mh(9)},
		{MethodName: "UpdateParams", Handler: _mh(10)},
	}, Streams: []grpc.StreamDesc{}, Metadata: "nexarail/treasury/v1/treasury.proto",
}

func _mh(m int) func(interface{}, context.Context, func(interface{}) error, grpc.UnaryServerInterceptor) (interface{}, error) {
	return func(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
		switch m {
		case 0:
			in := new(types.MsgCreateTreasuryAccount)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).CreateTreasuryAccount(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.treasury.v1.Msg/CreateTreasuryAccount"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(MsgServer).CreateTreasuryAccount(c, r.(*types.MsgCreateTreasuryAccount))
			})
		case 1:
			in := new(types.MsgCreateBudget)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).CreateBudget(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.treasury.v1.Msg/CreateBudget"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(MsgServer).CreateBudget(c, r.(*types.MsgCreateBudget))
			})
		case 2:
			in := new(types.MsgUpdateBudgetStatus)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).UpdateBudgetStatus(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.treasury.v1.Msg/UpdateBudgetStatus"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(MsgServer).UpdateBudgetStatus(c, r.(*types.MsgUpdateBudgetStatus))
			})
		case 3:
			in := new(types.MsgCreateGrant)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).CreateGrant(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.treasury.v1.Msg/CreateGrant"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(MsgServer).CreateGrant(c, r.(*types.MsgCreateGrant))
			})
		case 4:
			in := new(types.MsgUpdateGrantStatus)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).UpdateGrantStatus(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.treasury.v1.Msg/UpdateGrantStatus"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(MsgServer).UpdateGrantStatus(c, r.(*types.MsgUpdateGrantStatus))
			})
		case 5:
			in := new(types.MsgCreateSpendRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).CreateSpendRequest(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.treasury.v1.Msg/CreateSpendRequest"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(MsgServer).CreateSpendRequest(c, r.(*types.MsgCreateSpendRequest))
			})
		case 6:
			in := new(types.MsgApproveSpendRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).ApproveSpendRequest(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.treasury.v1.Msg/ApproveSpendRequest"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(MsgServer).ApproveSpendRequest(c, r.(*types.MsgApproveSpendRequest))
			})
		case 7:
			in := new(types.MsgRejectSpendRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).RejectSpendRequest(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.treasury.v1.Msg/RejectSpendRequest"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(MsgServer).RejectSpendRequest(c, r.(*types.MsgRejectSpendRequest))
			})
		case 8:
			in := new(types.MsgMarkSpendExecuted)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).MarkSpendExecuted(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.treasury.v1.Msg/MarkSpendExecuted"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(MsgServer).MarkSpendExecuted(c, r.(*types.MsgMarkSpendExecuted))
			})
		case 9:
			in := new(types.MsgCancelSpendRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).CancelSpendRequest(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.treasury.v1.Msg/CancelSpendRequest"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(MsgServer).CancelSpendRequest(c, r.(*types.MsgCancelSpendRequest))
			})
		case 10:
			in := new(types.MsgUpdateParams)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(MsgServer).UpdateParams(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.treasury.v1.Msg/UpdateParams"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(MsgServer).UpdateParams(c, r.(*types.MsgUpdateParams))
			})
		}
		return nil, nil
	}
}
