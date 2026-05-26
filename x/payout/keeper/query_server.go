package keeper

import (
	"context"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/nexarail/chain/x/payout/types"
	grpc "google.golang.org/grpc"
)

type QueryServer struct{ keeper Keeper }

func NewQueryServerImpl(k Keeper) QueryServer { return QueryServer{keeper: k} }

func (qs QueryServer) Params(ctx context.Context, _ *types.QueryParamsRequest) (*types.QueryParamsResponse, error) {
	return types.NewQueryParamsResponse(qs.keeper.GetParams(sdk.UnwrapSDKContext(ctx))), nil
}
func (qs QueryServer) Payout(ctx context.Context, req *types.QueryPayoutRequest) (*types.QueryPayoutResponse, error) {
	p, found := qs.keeper.GetPayout(sdk.UnwrapSDKContext(ctx), req.PayoutId)
	if !found {
		return nil, types.ErrPayoutNotFound
	}
	return types.NewQueryPayoutResponse(p), nil
}
func (qs QueryServer) Payouts(ctx context.Context, _ *types.QueryPayoutsRequest) (*types.QueryPayoutsResponse, error) {
	return types.NewQueryPayoutsResponse(qs.keeper.GetAllPayouts(sdk.UnwrapSDKContext(ctx))), nil
}
func (qs QueryServer) PayoutsByMerchant(ctx context.Context, req *types.QueryPayoutsByMerchantRequest) (*types.QueryPayoutsByMerchantResponse, error) {
	return types.NewQueryPayoutsByMerchantResponse(qs.keeper.GetPayoutsByMerchant(sdk.UnwrapSDKContext(ctx), req.MerchantId)), nil
}
func (qs QueryServer) PayoutsByRecipient(ctx context.Context, req *types.QueryPayoutsByRecipientRequest) (*types.QueryPayoutsByRecipientResponse, error) {
	return types.NewQueryPayoutsByRecipientResponse(qs.keeper.GetPayoutsByRecipient(sdk.UnwrapSDKContext(ctx), req.Recipient)), nil
}
func (qs QueryServer) PayoutsByInitiator(ctx context.Context, req *types.QueryPayoutsByInitiatorRequest) (*types.QueryPayoutsByInitiatorResponse, error) {
	return types.NewQueryPayoutsByInitiatorResponse(qs.keeper.GetPayoutsByInitiator(sdk.UnwrapSDKContext(ctx), req.Initiator)), nil
}
func (qs QueryServer) BatchPayout(ctx context.Context, req *types.QueryBatchPayoutRequest) (*types.QueryBatchPayoutResponse, error) {
	b, found := qs.keeper.GetBatchPayout(sdk.UnwrapSDKContext(ctx), req.BatchId)
	if !found {
		return nil, types.ErrBatchNotFound
	}
	return types.NewQueryBatchPayoutResponse(b), nil
}
func (qs QueryServer) BatchPayouts(ctx context.Context, _ *types.QueryBatchPayoutsRequest) (*types.QueryBatchPayoutsResponse, error) {
	return types.NewQueryBatchPayoutsResponse(qs.keeper.GetAllBatchPayouts(sdk.UnwrapSDKContext(ctx))), nil
}
func (qs QueryServer) PayoutExists(ctx context.Context, req *types.QueryPayoutExistsRequest) (*types.QueryPayoutExistsResponse, error) {
	return types.NewQueryPayoutExistsResponse(qs.keeper.HasPayout(sdk.UnwrapSDKContext(ctx), req.PayoutId)), nil
}

func RegisterQueryServer(s grpc.ServiceRegistrar, srv QueryServer) {
	s.RegisterService(&_Query_serviceDesc, srv)
}

var _Query_serviceDesc = grpc.ServiceDesc{
	ServiceName: "nexarail.payout.v1.Query", HandlerType: (*interface{})(nil),
	Methods: []grpc.MethodDesc{
		{MethodName: "Params", Handler: _qh(0)}, {MethodName: "Payout", Handler: _qh(1)},
		{MethodName: "Payouts", Handler: _qh(2)}, {MethodName: "PayoutsByMerchant", Handler: _qh(3)},
		{MethodName: "PayoutsByRecipient", Handler: _qh(4)}, {MethodName: "PayoutsByInitiator", Handler: _qh(5)},
		{MethodName: "BatchPayout", Handler: _qh(6)}, {MethodName: "BatchPayouts", Handler: _qh(7)},
		{MethodName: "PayoutExists", Handler: _qh(8)},
	}, Streams: []grpc.StreamDesc{}, Metadata: "nexarail/payout/v1/payout.proto",
}

func _qh(m int) func(interface{}, context.Context, func(interface{}) error, grpc.UnaryServerInterceptor) (interface{}, error) {
	return func(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
		switch m {
		case 0:
			in := new(types.QueryParamsRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(QueryServer).Params(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.payout.v1.Query/Params"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(QueryServer).Params(c, r.(*types.QueryParamsRequest))
			})
		case 1:
			in := new(types.QueryPayoutRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(QueryServer).Payout(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.payout.v1.Query/Payout"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(QueryServer).Payout(c, r.(*types.QueryPayoutRequest))
			})
		case 2:
			in := new(types.QueryPayoutsRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(QueryServer).Payouts(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.payout.v1.Query/Payouts"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(QueryServer).Payouts(c, r.(*types.QueryPayoutsRequest))
			})
		case 3:
			in := new(types.QueryPayoutsByMerchantRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(QueryServer).PayoutsByMerchant(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.payout.v1.Query/PayoutsByMerchant"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(QueryServer).PayoutsByMerchant(c, r.(*types.QueryPayoutsByMerchantRequest))
			})
		case 4:
			in := new(types.QueryPayoutsByRecipientRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(QueryServer).PayoutsByRecipient(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.payout.v1.Query/PayoutsByRecipient"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(QueryServer).PayoutsByRecipient(c, r.(*types.QueryPayoutsByRecipientRequest))
			})
		case 5:
			in := new(types.QueryPayoutsByInitiatorRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(QueryServer).PayoutsByInitiator(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.payout.v1.Query/PayoutsByInitiator"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(QueryServer).PayoutsByInitiator(c, r.(*types.QueryPayoutsByInitiatorRequest))
			})
		case 6:
			in := new(types.QueryBatchPayoutRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(QueryServer).BatchPayout(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.payout.v1.Query/BatchPayout"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(QueryServer).BatchPayout(c, r.(*types.QueryBatchPayoutRequest))
			})
		case 7:
			in := new(types.QueryBatchPayoutsRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(QueryServer).BatchPayouts(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.payout.v1.Query/BatchPayouts"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(QueryServer).BatchPayouts(c, r.(*types.QueryBatchPayoutsRequest))
			})
		case 8:
			in := new(types.QueryPayoutExistsRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(QueryServer).PayoutExists(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.payout.v1.Query/PayoutExists"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(QueryServer).PayoutExists(c, r.(*types.QueryPayoutExistsRequest))
			})
		}
		return nil, nil
	}
}
