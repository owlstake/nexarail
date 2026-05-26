package keeper

import (
	"context"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/nexarail/chain/x/escrow/types"
	grpc "google.golang.org/grpc"
)

type QueryServer struct{ keeper Keeper }

func NewQueryServerImpl(k Keeper) QueryServer { return QueryServer{keeper: k} }

func (qs QueryServer) Params(ctx context.Context, _ *types.QueryParamsRequest) (*types.QueryParamsResponse, error) {
	return types.NewQueryParamsResponse(qs.keeper.GetParams(sdk.UnwrapSDKContext(ctx))), nil
}
func (qs QueryServer) Escrow(ctx context.Context, req *types.QueryEscrowRequest) (*types.QueryEscrowResponse, error) {
	e, found := qs.keeper.GetEscrow(sdk.UnwrapSDKContext(ctx), req.EscrowId)
	if !found {
		return nil, types.ErrEscrowNotFound
	}
	return types.NewQueryEscrowResponse(e), nil
}
func (qs QueryServer) Escrows(ctx context.Context, _ *types.QueryEscrowsRequest) (*types.QueryEscrowsResponse, error) {
	return types.NewQueryEscrowsResponse(qs.keeper.GetAllEscrows(sdk.UnwrapSDKContext(ctx))), nil
}
func (qs QueryServer) EscrowsByBuyer(ctx context.Context, req *types.QueryEscrowsByBuyerRequest) (*types.QueryEscrowsByBuyerResponse, error) {
	return types.NewQueryEscrowsByBuyerResponse(qs.keeper.GetEscrowsByBuyer(sdk.UnwrapSDKContext(ctx), req.Buyer)), nil
}
func (qs QueryServer) EscrowsBySeller(ctx context.Context, req *types.QueryEscrowsBySellerRequest) (*types.QueryEscrowsBySellerResponse, error) {
	return types.NewQueryEscrowsBySellerResponse(qs.keeper.GetEscrowsBySeller(sdk.UnwrapSDKContext(ctx), req.Seller)), nil
}
func (qs QueryServer) EscrowsByMerchant(ctx context.Context, req *types.QueryEscrowsByMerchantRequest) (*types.QueryEscrowsByMerchantResponse, error) {
	return types.NewQueryEscrowsByMerchantResponse(qs.keeper.GetEscrowsByMerchant(sdk.UnwrapSDKContext(ctx), req.MerchantId)), nil
}
func (qs QueryServer) EscrowExists(ctx context.Context, req *types.QueryEscrowExistsRequest) (*types.QueryEscrowExistsResponse, error) {
	return types.NewQueryEscrowExistsResponse(qs.keeper.HasEscrow(sdk.UnwrapSDKContext(ctx), req.EscrowId)), nil
}

func RegisterQueryServer(s grpc.ServiceRegistrar, srv QueryServer) {
	s.RegisterService(&_Query_serviceDesc, srv)
}

var _Query_serviceDesc = grpc.ServiceDesc{
	ServiceName: "nexarail.escrow.v1.Query",
	HandlerType: (*interface{})(nil),
	Methods: []grpc.MethodDesc{
		{MethodName: "Params", Handler: _qh(0)},
		{MethodName: "Escrow", Handler: _qh(1)},
		{MethodName: "Escrows", Handler: _qh(2)},
		{MethodName: "EscrowsByBuyer", Handler: _qh(3)},
		{MethodName: "EscrowsBySeller", Handler: _qh(4)},
		{MethodName: "EscrowsByMerchant", Handler: _qh(5)},
		{MethodName: "EscrowExists", Handler: _qh(6)},
	},
	Streams:  []grpc.StreamDesc{},
	Metadata: "nexarail/escrow/v1/escrow.proto",
}

func _qh(method int) func(interface{}, context.Context, func(interface{}) error, grpc.UnaryServerInterceptor) (interface{}, error) {
	return func(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
		qs := srv.(QueryServer)
		switch method {
		case 0:
			in := new(types.QueryParamsRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return qs.Params(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.escrow.v1.Query/Params"}
			return interceptor(ctx, in, info, func(ctx context.Context, req interface{}) (interface{}, error) {
				return qs.Params(ctx, req.(*types.QueryParamsRequest))
			})
		case 1:
			in := new(types.QueryEscrowRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return qs.Escrow(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.escrow.v1.Query/Escrow"}
			return interceptor(ctx, in, info, func(ctx context.Context, req interface{}) (interface{}, error) {
				return qs.Escrow(ctx, req.(*types.QueryEscrowRequest))
			})
		case 2:
			in := new(types.QueryEscrowsRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return qs.Escrows(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.escrow.v1.Query/Escrows"}
			return interceptor(ctx, in, info, func(ctx context.Context, req interface{}) (interface{}, error) {
				return qs.Escrows(ctx, req.(*types.QueryEscrowsRequest))
			})
		case 3:
			in := new(types.QueryEscrowsByBuyerRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return qs.EscrowsByBuyer(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.escrow.v1.Query/EscrowsByBuyer"}
			return interceptor(ctx, in, info, func(ctx context.Context, req interface{}) (interface{}, error) {
				return qs.EscrowsByBuyer(ctx, req.(*types.QueryEscrowsByBuyerRequest))
			})
		case 4:
			in := new(types.QueryEscrowsBySellerRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return qs.EscrowsBySeller(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.escrow.v1.Query/EscrowsBySeller"}
			return interceptor(ctx, in, info, func(ctx context.Context, req interface{}) (interface{}, error) {
				return qs.EscrowsBySeller(ctx, req.(*types.QueryEscrowsBySellerRequest))
			})
		case 5:
			in := new(types.QueryEscrowsByMerchantRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return qs.EscrowsByMerchant(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.escrow.v1.Query/EscrowsByMerchant"}
			return interceptor(ctx, in, info, func(ctx context.Context, req interface{}) (interface{}, error) {
				return qs.EscrowsByMerchant(ctx, req.(*types.QueryEscrowsByMerchantRequest))
			})
		case 6:
			in := new(types.QueryEscrowExistsRequest)
			if err := dec(in); err != nil {
				return nil, err
			}
			if interceptor == nil {
				return qs.EscrowExists(ctx, in)
			}
			info := &grpc.UnaryServerInfo{Server: srv, FullMethod: "/nexarail.escrow.v1.Query/EscrowExists"}
			return interceptor(ctx, in, info, func(ctx context.Context, req interface{}) (interface{}, error) {
				return qs.EscrowExists(ctx, req.(*types.QueryEscrowExistsRequest))
			})
		}
		return nil, nil
	}
}
