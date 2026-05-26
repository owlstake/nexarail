package types

import (
	"context"
	"fmt"
	"github.com/cosmos/cosmos-sdk/client"
)

type QueryClient struct{ clientCtx client.Context }

func NewQueryClient(c client.Context) QueryClient { return QueryClient{c} }

func (qc QueryClient) Params(ctx context.Context, _ *QueryParamsRequest) (*QueryParamsResponse, error) {
	r := &QueryParamsResponse{}
	return r, qc.invoke(ctx, "/nexarail.payout.v1.Query/Params", &QueryParamsRequest{}, r)
}
func (qc QueryClient) Payout(ctx context.Context, req *QueryPayoutRequest) (*QueryPayoutResponse, error) {
	r := &QueryPayoutResponse{}
	return r, qc.invoke(ctx, "/nexarail.payout.v1.Query/Payout", req, r)
}
func (qc QueryClient) Payouts(ctx context.Context, _ *QueryPayoutsRequest) (*QueryPayoutsResponse, error) {
	r := &QueryPayoutsResponse{}
	return r, qc.invoke(ctx, "/nexarail.payout.v1.Query/Payouts", &QueryPayoutsRequest{}, r)
}
func (qc QueryClient) PayoutsByMerchant(ctx context.Context, req *QueryPayoutsByMerchantRequest) (*QueryPayoutsByMerchantResponse, error) {
	r := &QueryPayoutsByMerchantResponse{}
	return r, qc.invoke(ctx, "/nexarail.payout.v1.Query/PayoutsByMerchant", req, r)
}
func (qc QueryClient) PayoutsByRecipient(ctx context.Context, req *QueryPayoutsByRecipientRequest) (*QueryPayoutsByRecipientResponse, error) {
	r := &QueryPayoutsByRecipientResponse{}
	return r, qc.invoke(ctx, "/nexarail.payout.v1.Query/PayoutsByRecipient", req, r)
}
func (qc QueryClient) PayoutsByInitiator(ctx context.Context, req *QueryPayoutsByInitiatorRequest) (*QueryPayoutsByInitiatorResponse, error) {
	r := &QueryPayoutsByInitiatorResponse{}
	return r, qc.invoke(ctx, "/nexarail.payout.v1.Query/PayoutsByInitiator", req, r)
}
func (qc QueryClient) BatchPayout(ctx context.Context, req *QueryBatchPayoutRequest) (*QueryBatchPayoutResponse, error) {
	r := &QueryBatchPayoutResponse{}
	return r, qc.invoke(ctx, "/nexarail.payout.v1.Query/BatchPayout", req, r)
}
func (qc QueryClient) BatchPayouts(ctx context.Context, _ *QueryBatchPayoutsRequest) (*QueryBatchPayoutsResponse, error) {
	r := &QueryBatchPayoutsResponse{}
	return r, qc.invoke(ctx, "/nexarail.payout.v1.Query/BatchPayouts", &QueryBatchPayoutsRequest{}, r)
}
func (qc QueryClient) PayoutExists(ctx context.Context, req *QueryPayoutExistsRequest) (*QueryPayoutExistsResponse, error) {
	r := &QueryPayoutExistsResponse{}
	return r, qc.invoke(ctx, "/nexarail.payout.v1.Query/PayoutExists", req, r)
}

func (qc QueryClient) invoke(ctx context.Context, method string, req, resp interface{}) error {
	conn := qc.clientCtx.GRPCClient
	if conn == nil {
		return fmt.Errorf("gRPC not configured")
	}
	return conn.Invoke(ctx, method, req, resp)
}
