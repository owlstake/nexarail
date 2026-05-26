package types

import (
	"context"
	"fmt"
	"github.com/cosmos/cosmos-sdk/client"
)

type QueryClient struct{ clientCtx client.Context }

func NewQueryClient(c client.Context) QueryClient { return QueryClient{clientCtx: c} }

func (qc QueryClient) Params(ctx context.Context, _ *QueryParamsRequest) (*QueryParamsResponse, error) {
	r := &QueryParamsResponse{}
	return r, qc.invoke(ctx, "/nexarail.escrow.v1.Query/Params", &QueryParamsRequest{}, r)
}
func (qc QueryClient) Escrow(ctx context.Context, req *QueryEscrowRequest) (*QueryEscrowResponse, error) {
	r := &QueryEscrowResponse{}
	return r, qc.invoke(ctx, "/nexarail.escrow.v1.Query/Escrow", req, r)
}
func (qc QueryClient) Escrows(ctx context.Context, _ *QueryEscrowsRequest) (*QueryEscrowsResponse, error) {
	r := &QueryEscrowsResponse{}
	return r, qc.invoke(ctx, "/nexarail.escrow.v1.Query/Escrows", &QueryEscrowsRequest{}, r)
}
func (qc QueryClient) EscrowsByBuyer(ctx context.Context, req *QueryEscrowsByBuyerRequest) (*QueryEscrowsByBuyerResponse, error) {
	r := &QueryEscrowsByBuyerResponse{}
	return r, qc.invoke(ctx, "/nexarail.escrow.v1.Query/EscrowsByBuyer", req, r)
}
func (qc QueryClient) EscrowsBySeller(ctx context.Context, req *QueryEscrowsBySellerRequest) (*QueryEscrowsBySellerResponse, error) {
	r := &QueryEscrowsBySellerResponse{}
	return r, qc.invoke(ctx, "/nexarail.escrow.v1.Query/EscrowsBySeller", req, r)
}
func (qc QueryClient) EscrowsByMerchant(ctx context.Context, req *QueryEscrowsByMerchantRequest) (*QueryEscrowsByMerchantResponse, error) {
	r := &QueryEscrowsByMerchantResponse{}
	return r, qc.invoke(ctx, "/nexarail.escrow.v1.Query/EscrowsByMerchant", req, r)
}
func (qc QueryClient) EscrowExists(ctx context.Context, req *QueryEscrowExistsRequest) (*QueryEscrowExistsResponse, error) {
	r := &QueryEscrowExistsResponse{}
	return r, qc.invoke(ctx, "/nexarail.escrow.v1.Query/EscrowExists", req, r)
}

func (qc QueryClient) invoke(ctx context.Context, method string, req, resp interface{}) error {
	conn := qc.clientCtx.GRPCClient
	if conn == nil {
		return fmt.Errorf("gRPC client not configured")
	}
	return conn.Invoke(ctx, method, req, resp)
}
