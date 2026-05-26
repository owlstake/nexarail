package types

import (
	"context"
	"fmt"

	"github.com/cosmos/cosmos-sdk/client"
)

// QueryClient is the gRPC client for the fees query service.
type QueryClient struct {
	clientCtx client.Context
}

// NewQueryClient creates a new QueryClient.
func NewQueryClient(clientCtx client.Context) QueryClient {
	return QueryClient{clientCtx: clientCtx}
}

// Params queries the current fees module parameters.
func (qc QueryClient) Params(ctx context.Context, req *QueryParamsRequest) (*QueryParamsResponse, error) {
	conn := qc.clientCtx.GRPCClient
	if conn == nil {
		return nil, fmt.Errorf("gRPC client not configured")
	}

	resp := &QueryParamsResponse{}
	if err := conn.Invoke(ctx, "/nexarail.fees.v1.Query/Params", req, resp); err != nil {
		return nil, err
	}
	return resp, nil
}

// FeeSplit queries the current fee split proportions.
func (qc QueryClient) FeeSplit(ctx context.Context, req *QueryFeeSplitRequest) (*QueryFeeSplitResponse, error) {
	conn := qc.clientCtx.GRPCClient
	if conn == nil {
		return nil, fmt.Errorf("gRPC client not configured")
	}

	resp := &QueryFeeSplitResponse{}
	if err := conn.Invoke(ctx, "/nexarail.fees.v1.Query/FeeSplit", req, resp); err != nil {
		return nil, err
	}
	return resp, nil
}
