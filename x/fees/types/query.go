package types

// Query endpoints.
const (
	QueryParams   = "fees/params"
	QueryFeeSplit = "fees/fee_split"
)

// QueryParamsRequest is the request type for the Query/Params RPC.
type QueryParamsRequest struct{}

// QueryParamsResponse is the response type for the Query/Params RPC.
type QueryParamsResponse struct {
	Params Params `json:"params" yaml:"params"`
}

// NewQueryParamsResponse creates a new QueryParamsResponse.
func NewQueryParamsResponse(params Params) *QueryParamsResponse {
	return &QueryParamsResponse{Params: params}
}

// QueryFeeSplitRequest is the request type for the Query/FeeSplit RPC.
type QueryFeeSplitRequest struct{}

// QueryFeeSplitResponse is the response type for the Query/FeeSplit RPC.
type QueryFeeSplitResponse struct {
	ValidatorShareBps uint32 `json:"validator_share_bps" yaml:"validator_share_bps"`
	TreasuryShareBps  uint32 `json:"treasury_share_bps" yaml:"treasury_share_bps"`
	BurnShareBps      uint32 `json:"burn_share_bps" yaml:"burn_share_bps"`
}

// NewQueryFeeSplitResponse creates a new QueryFeeSplitResponse.
func NewQueryFeeSplitResponse(validatorBps, treasuryBps, burnBps uint32) *QueryFeeSplitResponse {
	return &QueryFeeSplitResponse{
		ValidatorShareBps: validatorBps,
		TreasuryShareBps:  treasuryBps,
		BurnShareBps:      burnBps,
	}
}
