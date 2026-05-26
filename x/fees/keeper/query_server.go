package keeper

import (
	"context"

	sdk "github.com/cosmos/cosmos-sdk/types"
	grpc "google.golang.org/grpc"

	"github.com/nexarail/chain/x/fees/types"
)

// QueryServer implements the QueryServer interface for the fees module.
type QueryServer struct {
	keeper Keeper
}

// NewQueryServerImpl returns an implementation of the QueryServer interface.
func NewQueryServerImpl(keeper Keeper) QueryServer {
	return QueryServer{keeper: keeper}
}

// Params handles the Query/Params request.
func (qs QueryServer) Params(ctx context.Context, req *types.QueryParamsRequest) (*types.QueryParamsResponse, error) {
	sdkCtx := sdk.UnwrapSDKContext(ctx)
	params := qs.keeper.GetParams(sdkCtx)
	return types.NewQueryParamsResponse(params), nil
}

// FeeSplit handles the Query/FeeSplit request.
func (qs QueryServer) FeeSplit(ctx context.Context, req *types.QueryFeeSplitRequest) (*types.QueryFeeSplitResponse, error) {
	sdkCtx := sdk.UnwrapSDKContext(ctx)
	valBps, treasBps, burnBps := qs.keeper.GetFeeSplit(sdkCtx)
	return types.NewQueryFeeSplitResponse(valBps, treasBps, burnBps), nil
}

// RegisterQueryServer registers the fees Query service with the gRPC server.
func RegisterQueryServer(s grpc.ServiceRegistrar, srv QueryServer) {
	s.RegisterService(&_Query_serviceDesc, srv)
}

var _Query_serviceDesc = grpc.ServiceDesc{
	ServiceName: "nexarail.fees.v1.Query",
	HandlerType: (*interface{})(nil),
	Methods: []grpc.MethodDesc{
		{
			MethodName: "Params",
			Handler:    _Query_Params_Handler,
		},
		{
			MethodName: "FeeSplit",
			Handler:    _Query_FeeSplit_Handler,
		},
	},
	Streams:  []grpc.StreamDesc{},
	Metadata: "nexarail/fees/v1/fees.proto",
}

func _Query_Params_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(types.QueryParamsRequest)
	if err := dec(in); err != nil {
		return nil, err
	}

	if interceptor == nil {
		return srv.(QueryServer).Params(ctx, in)
	}

	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/nexarail.fees.v1.Query/Params",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(QueryServer).Params(ctx, req.(*types.QueryParamsRequest))
	}
	return interceptor(ctx, in, info, handler)
}

func _Query_FeeSplit_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(types.QueryFeeSplitRequest)
	if err := dec(in); err != nil {
		return nil, err
	}

	if interceptor == nil {
		return srv.(QueryServer).FeeSplit(ctx, in)
	}

	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/nexarail.fees.v1.Query/FeeSplit",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(QueryServer).FeeSplit(ctx, req.(*types.QueryFeeSplitRequest))
	}
	return interceptor(ctx, in, info, handler)
}
