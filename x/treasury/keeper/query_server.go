package keeper

import (
	"context"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/nexarail/chain/x/treasury/types"
	grpc "google.golang.org/grpc"
)

type QueryServer struct{ keeper Keeper }

func NewQueryServerImpl(k Keeper) QueryServer { return QueryServer{keeper: k} }

func (qs QueryServer) Params(ctx context.Context, _ *types.QueryParamsRequest) (*types.QueryParamsResponse, error) {
	return types.NewQueryParamsResponse(qs.keeper.GetParams(sdk.UnwrapSDKContext(ctx))), nil
}
func (qs QueryServer) TreasuryAccount(ctx context.Context, req *types.QueryTreasuryAccountRequest) (*types.QueryTreasuryAccountResponse, error) {
	a, f := qs.keeper.GetTreasuryAccount(sdk.UnwrapSDKContext(ctx), req.AccountId)
	if !f {
		return nil, types.ErrRecordNotFound
	}
	return types.NewQueryTreasuryAccountResponse(a), nil
}
func (qs QueryServer) TreasuryAccounts(ctx context.Context, _ *types.QueryTreasuryAccountsRequest) (*types.QueryTreasuryAccountsResponse, error) {
	return types.NewQueryTreasuryAccountsResponse(qs.keeper.GetAllTreasuryAccounts(sdk.UnwrapSDKContext(ctx))), nil
}
func (qs QueryServer) Budget(ctx context.Context, req *types.QueryBudgetRequest) (*types.QueryBudgetResponse, error) {
	b, f := qs.keeper.GetBudget(sdk.UnwrapSDKContext(ctx), req.BudgetId)
	if !f {
		return nil, types.ErrRecordNotFound
	}
	return types.NewQueryBudgetResponse(b), nil
}
func (qs QueryServer) Budgets(ctx context.Context, _ *types.QueryBudgetsRequest) (*types.QueryBudgetsResponse, error) {
	return types.NewQueryBudgetsResponse(qs.keeper.GetAllBudgets(sdk.UnwrapSDKContext(ctx))), nil
}
func (qs QueryServer) Grant(ctx context.Context, req *types.QueryGrantRequest) (*types.QueryGrantResponse, error) {
	g, f := qs.keeper.GetGrant(sdk.UnwrapSDKContext(ctx), req.GrantId)
	if !f {
		return nil, types.ErrRecordNotFound
	}
	return types.NewQueryGrantResponse(g), nil
}
func (qs QueryServer) Grants(ctx context.Context, _ *types.QueryGrantsRequest) (*types.QueryGrantsResponse, error) {
	return types.NewQueryGrantsResponse(qs.keeper.GetAllGrants(sdk.UnwrapSDKContext(ctx))), nil
}
func (qs QueryServer) SpendRequest(ctx context.Context, req *types.QuerySpendRequestRequest) (*types.QuerySpendRequestResponse, error) {
	s, f := qs.keeper.GetSpendRequest(sdk.UnwrapSDKContext(ctx), req.SpendId)
	if !f {
		return nil, types.ErrRecordNotFound
	}
	return types.NewQuerySpendRequestResponse(s), nil
}
func (qs QueryServer) SpendRequests(ctx context.Context, _ *types.QuerySpendRequestsRequest) (*types.QuerySpendRequestsResponse, error) {
	return types.NewQuerySpendRequestsResponse(qs.keeper.GetAllSpendRequests(sdk.UnwrapSDKContext(ctx))), nil
}
func (qs QueryServer) TreasurySummary(ctx context.Context, _ *types.QueryTreasurySummaryRequest) (*types.QueryTreasurySummaryResponse, error) {
	c := sdk.UnwrapSDKContext(ctx)
	return types.NewQueryTreasurySummaryResponse(
		uint64(len(qs.keeper.GetAllTreasuryAccounts(c))),
		uint64(len(qs.keeper.GetAllBudgets(c))),
		uint64(len(qs.keeper.GetAllGrants(c))),
		uint64(len(qs.keeper.GetAllSpendRequests(c))),
	), nil
}

func RegisterQueryServer(s grpc.ServiceRegistrar, srv QueryServer) {
	s.RegisterService(&_Query_serviceDesc, srv)
}

var _Query_serviceDesc = grpc.ServiceDesc{ServiceName: "nexarail.treasury.v1.Query", HandlerType: (*interface{})(nil),
	Methods: []grpc.MethodDesc{
		{MethodName: "Params", Handler: _qh(0)}, {MethodName: "TreasuryAccount", Handler: _qh(1)},
		{MethodName: "TreasuryAccounts", Handler: _qh(2)}, {MethodName: "Budget", Handler: _qh(3)},
		{MethodName: "Budgets", Handler: _qh(4)}, {MethodName: "Grant", Handler: _qh(5)},
		{MethodName: "Grants", Handler: _qh(6)}, {MethodName: "SpendRequest", Handler: _qh(7)},
		{MethodName: "SpendRequests", Handler: _qh(8)}, {MethodName: "TreasurySummary", Handler: _qh(9)},
	}, Streams: []grpc.StreamDesc{}, Metadata: "nexarail/treasury/v1/treasury.proto",
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
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.treasury.v1.Query/Params"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(QueryServer).Params(c, r.(*types.QueryParamsRequest))
			})
		case 1:
			in := new(types.QueryTreasuryAccountRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(QueryServer).TreasuryAccount(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.treasury.v1.Query/TreasuryAccount"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(QueryServer).TreasuryAccount(c, r.(*types.QueryTreasuryAccountRequest))
			})
		case 2:
			in := new(types.QueryTreasuryAccountsRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(QueryServer).TreasuryAccounts(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.treasury.v1.Query/TreasuryAccounts"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(QueryServer).TreasuryAccounts(c, r.(*types.QueryTreasuryAccountsRequest))
			})
		case 3:
			in := new(types.QueryBudgetRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(QueryServer).Budget(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.treasury.v1.Query/Budget"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(QueryServer).Budget(c, r.(*types.QueryBudgetRequest))
			})
		case 4:
			in := new(types.QueryBudgetsRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(QueryServer).Budgets(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.treasury.v1.Query/Budgets"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(QueryServer).Budgets(c, r.(*types.QueryBudgetsRequest))
			})
		case 5:
			in := new(types.QueryGrantRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(QueryServer).Grant(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.treasury.v1.Query/Grant"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(QueryServer).Grant(c, r.(*types.QueryGrantRequest))
			})
		case 6:
			in := new(types.QueryGrantsRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(QueryServer).Grants(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.treasury.v1.Query/Grants"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(QueryServer).Grants(c, r.(*types.QueryGrantsRequest))
			})
		case 7:
			in := new(types.QuerySpendRequestRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(QueryServer).SpendRequest(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.treasury.v1.Query/SpendRequest"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(QueryServer).SpendRequest(c, r.(*types.QuerySpendRequestRequest))
			})
		case 8:
			in := new(types.QuerySpendRequestsRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(QueryServer).SpendRequests(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.treasury.v1.Query/SpendRequests"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(QueryServer).SpendRequests(c, r.(*types.QuerySpendRequestsRequest))
			})
		case 9:
			in := new(types.QueryTreasurySummaryRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return srv.(QueryServer).TreasurySummary(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.treasury.v1.Query/TreasurySummary"}
			return interceptor(ctx, in, info, func(c context.Context, r interface{}) (interface{}, error) {
				return srv.(QueryServer).TreasurySummary(c, r.(*types.QueryTreasurySummaryRequest))
			})
		}
		return nil, nil
	}
}
