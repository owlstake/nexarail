package types

import (
	"context"
	"fmt"
	"github.com/cosmos/cosmos-sdk/client"
)

type QueryClient struct{ clientCtx client.Context }

func NewQueryClient(c client.Context) QueryClient { return QueryClient{c} }
func (qc QueryClient) invoke(ctx context.Context, m string, req, resp interface{}) error {
	if qc.clientCtx.GRPCClient == nil {
		return fmt.Errorf("gRPC not configured")
	}
	return qc.clientCtx.GRPCClient.Invoke(ctx, m, req, resp)
}
func (qc QueryClient) Params(ctx context.Context, _ *QueryParamsRequest) (*QueryParamsResponse, error) {
	r := &QueryParamsResponse{}
	return r, qc.invoke(ctx, "/nexarail.treasury.v1.Query/Params", &QueryParamsRequest{}, r)
}
func (qc QueryClient) TreasuryAccount(ctx context.Context, req *QueryTreasuryAccountRequest) (*QueryTreasuryAccountResponse, error) {
	r := &QueryTreasuryAccountResponse{}
	return r, qc.invoke(ctx, "/nexarail.treasury.v1.Query/TreasuryAccount", req, r)
}
func (qc QueryClient) TreasuryAccounts(ctx context.Context, _ *QueryTreasuryAccountsRequest) (*QueryTreasuryAccountsResponse, error) {
	r := &QueryTreasuryAccountsResponse{}
	return r, qc.invoke(ctx, "/nexarail.treasury.v1.Query/TreasuryAccounts", &QueryTreasuryAccountsRequest{}, r)
}
func (qc QueryClient) Budget(ctx context.Context, req *QueryBudgetRequest) (*QueryBudgetResponse, error) {
	r := &QueryBudgetResponse{}
	return r, qc.invoke(ctx, "/nexarail.treasury.v1.Query/Budget", req, r)
}
func (qc QueryClient) Budgets(ctx context.Context, _ *QueryBudgetsRequest) (*QueryBudgetsResponse, error) {
	r := &QueryBudgetsResponse{}
	return r, qc.invoke(ctx, "/nexarail.treasury.v1.Query/Budgets", &QueryBudgetsRequest{}, r)
}
func (qc QueryClient) Grant(ctx context.Context, req *QueryGrantRequest) (*QueryGrantResponse, error) {
	r := &QueryGrantResponse{}
	return r, qc.invoke(ctx, "/nexarail.treasury.v1.Query/Grant", req, r)
}
func (qc QueryClient) Grants(ctx context.Context, _ *QueryGrantsRequest) (*QueryGrantsResponse, error) {
	r := &QueryGrantsResponse{}
	return r, qc.invoke(ctx, "/nexarail.treasury.v1.Query/Grants", &QueryGrantsRequest{}, r)
}
func (qc QueryClient) SpendRequest(ctx context.Context, req *QuerySpendRequestRequest) (*QuerySpendRequestResponse, error) {
	r := &QuerySpendRequestResponse{}
	return r, qc.invoke(ctx, "/nexarail.treasury.v1.Query/SpendRequest", req, r)
}
func (qc QueryClient) SpendRequests(ctx context.Context, _ *QuerySpendRequestsRequest) (*QuerySpendRequestsResponse, error) {
	r := &QuerySpendRequestsResponse{}
	return r, qc.invoke(ctx, "/nexarail.treasury.v1.Query/SpendRequests", &QuerySpendRequestsRequest{}, r)
}
func (qc QueryClient) TreasurySummary(ctx context.Context, _ *QueryTreasurySummaryRequest) (*QueryTreasurySummaryResponse, error) {
	r := &QueryTreasurySummaryResponse{}
	return r, qc.invoke(ctx, "/nexarail.treasury.v1.Query/TreasurySummary", &QueryTreasurySummaryRequest{}, r)
}
