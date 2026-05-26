package keeper

import (
	"context"
	"fmt"

	sdk "github.com/cosmos/cosmos-sdk/types"
	grpc "google.golang.org/grpc"

	"github.com/nexarail/chain/x/merchant/types"
)

type QueryServer struct {
	keeper Keeper
}

func NewQueryServerImpl(k Keeper) QueryServer {
	return QueryServer{keeper: k}
}

func (qs QueryServer) Params(ctx context.Context, _ *types.QueryParamsRequest) (*types.QueryParamsResponse, error) {
	sdkCtx := sdk.UnwrapSDKContext(ctx)
	return types.NewQueryParamsResponse(qs.keeper.GetParams(sdkCtx)), nil
}

func (qs QueryServer) Merchant(ctx context.Context, req *types.QueryMerchantRequest) (*types.QueryMerchantResponse, error) {
	sdkCtx := sdk.UnwrapSDKContext(ctx)
	owner, err := sdk.AccAddressFromBech32(req.Owner)
	if err != nil {
		return nil, fmt.Errorf("invalid owner: %w", err)
	}
	m, found := qs.keeper.GetMerchant(sdkCtx, owner)
	if !found {
		return nil, types.ErrMerchantNotFound
	}
	return types.NewQueryMerchantResponse(m), nil
}

func (qs QueryServer) Merchants(ctx context.Context, req *types.QueryMerchantsRequest) (*types.QueryMerchantsResponse, error) {
	sdkCtx := sdk.UnwrapSDKContext(ctx)
	merchants := qs.keeper.GetAllMerchants(sdkCtx)
	return &types.QueryMerchantsResponse{
		Merchants:  merchants,
		Pagination: &types.PageResponse{Total: uint64(len(merchants))},
	}, nil
}

// --- gRPC registration ---

func RegisterQueryServer(s grpc.ServiceRegistrar, srv QueryServer) {
	s.RegisterService(&_Query_serviceDesc, srv)
}

var _Query_serviceDesc = grpc.ServiceDesc{
	ServiceName: "nexarail.merchant.v1.Query",
	HandlerType: (*interface{})(nil),
	Methods: []grpc.MethodDesc{
		{MethodName: "Params", Handler: _Query_Params_Handler},
		{MethodName: "Merchant", Handler: _Query_Merchant_Handler},
		{MethodName: "Merchants", Handler: _Query_Merchants_Handler},
	},
	Streams:  []grpc.StreamDesc{},
	Metadata: "nexarail/merchant/v1/merchant.proto",
}

func _Query_Params_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(types.QueryParamsRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(QueryServer).Params(ctx, in)
	}
	info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.merchant.v1.Query/Params"}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(QueryServer).Params(ctx, req.(*types.QueryParamsRequest))
	}
	return interceptor(ctx, in, info, handler)
}

func _Query_Merchant_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(types.QueryMerchantRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(QueryServer).Merchant(ctx, in)
	}
	info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.merchant.v1.Query/Merchant"}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(QueryServer).Merchant(ctx, req.(*types.QueryMerchantRequest))
	}
	return interceptor(ctx, in, info, handler)
}

func _Query_Merchants_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(types.QueryMerchantsRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(QueryServer).Merchants(ctx, in)
	}
	info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.merchant.v1.Query/Merchants"}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(QueryServer).Merchants(ctx, req.(*types.QueryMerchantsRequest))
	}
	return interceptor(ctx, in, info, handler)
}
