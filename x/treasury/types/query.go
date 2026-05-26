package types

type QueryParamsRequest struct{}
type QueryParamsResponse struct {
	Params Params `json:"params"`
}

func NewQueryParamsResponse(p Params) *QueryParamsResponse { return &QueryParamsResponse{p} }

type QueryTreasuryAccountRequest struct {
	AccountId string `json:"account_id"`
}
type QueryTreasuryAccountResponse struct {
	Account TreasuryAccount `json:"account"`
}

func NewQueryTreasuryAccountResponse(a TreasuryAccount) *QueryTreasuryAccountResponse {
	return &QueryTreasuryAccountResponse{a}
}

type QueryTreasuryAccountsRequest struct{}
type QueryTreasuryAccountsResponse struct {
	Accounts []TreasuryAccount `json:"accounts"`
}

func NewQueryTreasuryAccountsResponse(as []TreasuryAccount) *QueryTreasuryAccountsResponse {
	return &QueryTreasuryAccountsResponse{as}
}

type QueryBudgetRequest struct {
	BudgetId string `json:"budget_id"`
}
type QueryBudgetResponse struct {
	Budget Budget `json:"budget"`
}

func NewQueryBudgetResponse(b Budget) *QueryBudgetResponse { return &QueryBudgetResponse{b} }

type QueryBudgetsRequest struct{}
type QueryBudgetsResponse struct {
	Budgets []Budget `json:"budgets"`
}

func NewQueryBudgetsResponse(bs []Budget) *QueryBudgetsResponse { return &QueryBudgetsResponse{bs} }

type QueryGrantRequest struct {
	GrantId string `json:"grant_id"`
}
type QueryGrantResponse struct {
	Grant Grant `json:"grant"`
}

func NewQueryGrantResponse(g Grant) *QueryGrantResponse { return &QueryGrantResponse{g} }

type QueryGrantsRequest struct{}
type QueryGrantsResponse struct {
	Grants []Grant `json:"grants"`
}

func NewQueryGrantsResponse(gs []Grant) *QueryGrantsResponse { return &QueryGrantsResponse{gs} }

type QuerySpendRequestRequest struct {
	SpendId string `json:"spend_id"`
}
type QuerySpendRequestResponse struct {
	SpendRequest SpendRequest `json:"spend_request"`
}

func NewQuerySpendRequestResponse(s SpendRequest) *QuerySpendRequestResponse {
	return &QuerySpendRequestResponse{s}
}

type QuerySpendRequestsRequest struct{}
type QuerySpendRequestsResponse struct {
	SpendRequests []SpendRequest `json:"spend_requests"`
}

func NewQuerySpendRequestsResponse(ss []SpendRequest) *QuerySpendRequestsResponse {
	return &QuerySpendRequestsResponse{ss}
}

type QueryTreasurySummaryRequest struct{}
type QueryTreasurySummaryResponse struct {
	TotalAccounts      uint64 `json:"total_accounts"`
	TotalBudgets       uint64 `json:"total_budgets"`
	TotalGrants        uint64 `json:"total_grants"`
	TotalSpendRequests uint64 `json:"total_spend_requests"`
}

func NewQueryTreasurySummaryResponse(a, b, g, s uint64) *QueryTreasurySummaryResponse {
	return &QueryTreasurySummaryResponse{a, b, g, s}
}

func (r *QueryParamsRequest) ProtoMessage()             {}
func (r *QueryParamsRequest) Reset()                    {}
func (r *QueryParamsRequest) String() string            { return "QPR{}" }
func (r *QueryParamsResponse) ProtoMessage()            {}
func (r *QueryParamsResponse) Reset()                   {}
func (r *QueryParamsResponse) String() string           { return "QPResp{}" }
func (r *QueryTreasuryAccountRequest) ProtoMessage()    {}
func (r *QueryTreasuryAccountRequest) Reset()           {}
func (r *QueryTreasuryAccountRequest) String() string   { return "QTAReq{}" }
func (r *QueryTreasuryAccountResponse) ProtoMessage()   {}
func (r *QueryTreasuryAccountResponse) Reset()          {}
func (r *QueryTreasuryAccountResponse) String() string  { return "QTAResp{}" }
func (r *QueryTreasuryAccountsRequest) ProtoMessage()   {}
func (r *QueryTreasuryAccountsRequest) Reset()          {}
func (r *QueryTreasuryAccountsRequest) String() string  { return "QTAsReq{}" }
func (r *QueryTreasuryAccountsResponse) ProtoMessage()  {}
func (r *QueryTreasuryAccountsResponse) Reset()         {}
func (r *QueryTreasuryAccountsResponse) String() string { return "QTAsResp{}" }
func (r *QueryBudgetRequest) ProtoMessage()             {}
func (r *QueryBudgetRequest) Reset()                    {}
func (r *QueryBudgetRequest) String() string            { return "QBReq{}" }
func (r *QueryBudgetResponse) ProtoMessage()            {}
func (r *QueryBudgetResponse) Reset()                   {}
func (r *QueryBudgetResponse) String() string           { return "QBResp{}" }
func (r *QueryBudgetsRequest) ProtoMessage()            {}
func (r *QueryBudgetsRequest) Reset()                   {}
func (r *QueryBudgetsRequest) String() string           { return "QBsReq{}" }
func (r *QueryBudgetsResponse) ProtoMessage()           {}
func (r *QueryBudgetsResponse) Reset()                  {}
func (r *QueryBudgetsResponse) String() string          { return "QBsResp{}" }
func (r *QueryGrantRequest) ProtoMessage()              {}
func (r *QueryGrantRequest) Reset()                     {}
func (r *QueryGrantRequest) String() string             { return "QGReq{}" }
func (r *QueryGrantResponse) ProtoMessage()             {}
func (r *QueryGrantResponse) Reset()                    {}
func (r *QueryGrantResponse) String() string            { return "QGResp{}" }
func (r *QueryGrantsRequest) ProtoMessage()             {}
func (r *QueryGrantsRequest) Reset()                    {}
func (r *QueryGrantsRequest) String() string            { return "QGsReq{}" }
func (r *QueryGrantsResponse) ProtoMessage()            {}
func (r *QueryGrantsResponse) Reset()                   {}
func (r *QueryGrantsResponse) String() string           { return "QGsResp{}" }
func (r *QuerySpendRequestRequest) ProtoMessage()       {}
func (r *QuerySpendRequestRequest) Reset()              {}
func (r *QuerySpendRequestRequest) String() string      { return "QSRReq{}" }
func (r *QuerySpendRequestResponse) ProtoMessage()      {}
func (r *QuerySpendRequestResponse) Reset()             {}
func (r *QuerySpendRequestResponse) String() string     { return "QSRResp{}" }
func (r *QuerySpendRequestsRequest) ProtoMessage()      {}
func (r *QuerySpendRequestsRequest) Reset()             {}
func (r *QuerySpendRequestsRequest) String() string     { return "QSRsReq{}" }
func (r *QuerySpendRequestsResponse) ProtoMessage()     {}
func (r *QuerySpendRequestsResponse) Reset()            {}
func (r *QuerySpendRequestsResponse) String() string    { return "QSRsResp{}" }
func (r *QueryTreasurySummaryRequest) ProtoMessage()    {}
func (r *QueryTreasurySummaryRequest) Reset()           {}
func (r *QueryTreasurySummaryRequest) String() string   { return "QTSReq{}" }
func (r *QueryTreasurySummaryResponse) ProtoMessage()   {}
func (r *QueryTreasurySummaryResponse) Reset()          {}
func (r *QueryTreasurySummaryResponse) String() string  { return "QTSResp{}" }
