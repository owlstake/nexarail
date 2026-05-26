package keeper

import (
	"context"

	sdk "github.com/cosmos/cosmos-sdk/types"
	grpc "google.golang.org/grpc"

	"github.com/nexarail/chain/x/settlement/types"
)

type QueryServer struct {
	keeper Keeper
}

func NewQueryServerImpl(k Keeper) QueryServer { return QueryServer{keeper: k} }

func (qs QueryServer) Params(ctx context.Context, _ *types.QueryParamsRequest) (*types.QueryParamsResponse, error) {
	return types.NewQueryParamsResponse(qs.keeper.GetParams(sdk.UnwrapSDKContext(ctx))), nil
}

func (qs QueryServer) Settlement(ctx context.Context, req *types.QuerySettlementRequest) (*types.QuerySettlementResponse, error) {
	s, found := qs.keeper.GetSettlement(sdk.UnwrapSDKContext(ctx), req.Id)
	if !found {
		return nil, types.ErrSettlementNotFound
	}
	return types.NewQuerySettlementResponse(s), nil
}

func (qs QueryServer) SettlementsByPayer(ctx context.Context, req *types.QuerySettlementsByPayerRequest) (*types.QuerySettlementsByPayerResponse, error) {
	settlements := qs.keeper.GetSettlementsByPayer(sdk.UnwrapSDKContext(ctx), req.Payer)
	return types.NewQuerySettlementsByPayerResponse(settlements), nil
}

func (qs QueryServer) SettlementsByMerchant(ctx context.Context, req *types.QuerySettlementsByMerchantRequest) (*types.QuerySettlementsByMerchantResponse, error) {
	settlements := qs.keeper.GetSettlementsByMerchant(sdk.UnwrapSDKContext(ctx), req.MerchantOwner)
	return types.NewQuerySettlementsByMerchantResponse(settlements), nil
}

func (qs QueryServer) Settlements(ctx context.Context, _ *types.QuerySettlementsRequest) (*types.QuerySettlementsResponse, error) {
	settlements := qs.keeper.GetAllSettlements(sdk.UnwrapSDKContext(ctx))
	return types.NewQuerySettlementsResponse(settlements), nil
}

// --- gRPC ---

func RegisterQueryServer(s grpc.ServiceRegistrar, srv QueryServer) {
	s.RegisterService(&_Query_serviceDesc, srv)
}

var _Query_serviceDesc = grpc.ServiceDesc{
	ServiceName: "nexarail.settlement.v1.Query",
	HandlerType: (*interface{})(nil),
	Methods: []grpc.MethodDesc{
		{MethodName: "Params", Handler: _Query_Params_Handler},
		{MethodName: "Settlement", Handler: _Query_Settlement_Handler},
		{MethodName: "SettlementsByPayer", Handler: _Query_SettlementsByPayer_Handler},
		{MethodName: "SettlementsByMerchant", Handler: _Query_SettlementsByMerchant_Handler},
		{MethodName: "Settlements", Handler: _Query_Settlements_Handler},
	},
	Streams:  []grpc.StreamDesc{},
	Metadata: "nexarail/settlement/v1/settlement.proto",
}

func _Query_Params_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(types.QueryParamsRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(QueryServer).Params(ctx, in)
	}
	info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.settlement.v1.Query/Params"}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(QueryServer).Params(ctx, req.(*types.QueryParamsRequest))
	}
	return interceptor(ctx, in, info, handler)
}

func _Query_Settlement_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(types.QuerySettlementRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(QueryServer).Settlement(ctx, in)
	}
	info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.settlement.v1.Query/Settlement"}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(QueryServer).Settlement(ctx, req.(*types.QuerySettlementRequest))
	}
	return interceptor(ctx, in, info, handler)
}

func _Query_SettlementsByPayer_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(types.QuerySettlementsByPayerRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(QueryServer).SettlementsByPayer(ctx, in)
	}
	info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.settlement.v1.Query/SettlementsByPayer"}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(QueryServer).SettlementsByPayer(ctx, req.(*types.QuerySettlementsByPayerRequest))
	}
	return interceptor(ctx, in, info, handler)
}

func _Query_SettlementsByMerchant_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(types.QuerySettlementsByMerchantRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(QueryServer).SettlementsByMerchant(ctx, in)
	}
	info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.settlement.v1.Query/SettlementsByMerchant"}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(QueryServer).SettlementsByMerchant(ctx, req.(*types.QuerySettlementsByMerchantRequest))
	}
	return interceptor(ctx, in, info, handler)
}

func _Query_Settlements_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(types.QuerySettlementsRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(QueryServer).Settlements(ctx, in)
	}
	info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.settlement.v1.Query/Settlements"}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(QueryServer).Settlements(ctx, req.(*types.QuerySettlementsRequest))
	}
	return interceptor(ctx, in, info, handler)
}
