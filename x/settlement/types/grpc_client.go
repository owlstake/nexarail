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
	err := conn.Invoke(ctx, "/nexarail.settlement.v1.Query/Params", &QueryParamsRequest{}, resp)
	return resp, err
}

func (qc QueryClient) Settlement(ctx context.Context, req *QuerySettlementRequest) (*QuerySettlementResponse, error) {
	conn := qc.clientCtx.GRPCClient
	if conn == nil {
		return nil, fmt.Errorf("gRPC client not configured")
	}
	resp := &QuerySettlementResponse{}
	err := conn.Invoke(ctx, "/nexarail.settlement.v1.Query/Settlement", req, resp)
	return resp, err
}

func (qc QueryClient) SettlementsByPayer(ctx context.Context, req *QuerySettlementsByPayerRequest) (*QuerySettlementsByPayerResponse, error) {
	conn := qc.clientCtx.GRPCClient
	if conn == nil {
		return nil, fmt.Errorf("gRPC client not configured")
	}
	resp := &QuerySettlementsByPayerResponse{}
	err := conn.Invoke(ctx, "/nexarail.settlement.v1.Query/SettlementsByPayer", req, resp)
	return resp, err
}

func (qc QueryClient) SettlementsByMerchant(ctx context.Context, req *QuerySettlementsByMerchantRequest) (*QuerySettlementsByMerchantResponse, error) {
	conn := qc.clientCtx.GRPCClient
	if conn == nil {
		return nil, fmt.Errorf("gRPC client not configured")
	}
	resp := &QuerySettlementsByMerchantResponse{}
	err := conn.Invoke(ctx, "/nexarail.settlement.v1.Query/SettlementsByMerchant", req, resp)
	return resp, err
}

func (qc QueryClient) Settlements(ctx context.Context, _ *QuerySettlementsRequest) (*QuerySettlementsResponse, error) {
	conn := qc.clientCtx.GRPCClient
	if conn == nil {
		return nil, fmt.Errorf("gRPC client not configured")
	}
	resp := &QuerySettlementsResponse{}
	err := conn.Invoke(ctx, "/nexarail.settlement.v1.Query/Settlements", &QuerySettlementsRequest{}, resp)
	return resp, err
}
