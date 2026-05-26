package types

import (
	"context"
	"fmt"

	"github.com/cosmos/cosmos-sdk/client"
)

type QueryClient struct {
	clientCtx client.Context
}

func NewQueryClient(clientCtx client.Context) QueryClient {
	return QueryClient{clientCtx: clientCtx}
}

func (qc QueryClient) Params(ctx context.Context, _ *QueryParamsRequest) (*QueryParamsResponse, error) {
	conn := qc.clientCtx.GRPCClient
	if conn == nil {
		return nil, fmt.Errorf("gRPC client not configured")
	}
	resp := &QueryParamsResponse{}
	if err := conn.Invoke(ctx, "/nexarail.merchant.v1.Query/Params", &QueryParamsRequest{}, resp); err != nil {
		return nil, err
	}
	return resp, nil
}

func (qc QueryClient) Merchant(ctx context.Context, req *QueryMerchantRequest) (*QueryMerchantResponse, error) {
	conn := qc.clientCtx.GRPCClient
	if conn == nil {
		return nil, fmt.Errorf("gRPC client not configured")
	}
	resp := &QueryMerchantResponse{}
	if err := conn.Invoke(ctx, "/nexarail.merchant.v1.Query/Merchant", req, resp); err != nil {
		return nil, err
	}
	return resp, nil
}

func (qc QueryClient) Merchants(ctx context.Context, req *QueryMerchantsRequest) (*QueryMerchantsResponse, error) {
	conn := qc.clientCtx.GRPCClient
	if conn == nil {
		return nil, fmt.Errorf("gRPC client not configured")
	}
	resp := &QueryMerchantsResponse{}
	if err := conn.Invoke(ctx, "/nexarail.merchant.v1.Query/Merchants", req, resp); err != nil {
		return nil, err
	}
	return resp, nil
}
