package types

// --- Query/Params ---

type QueryParamsRequest struct{}
type QueryParamsResponse struct {
	Params Params `json:"params" yaml:"params"`
}

func NewQueryParamsResponse(p Params) *QueryParamsResponse {
	return &QueryParamsResponse{Params: p}
}

func (r *QueryParamsRequest) ProtoMessage()   {}
func (r *QueryParamsRequest) Reset()          {}
func (r *QueryParamsRequest) String() string  { return "QueryParamsRequest{}" }
func (r *QueryParamsResponse) ProtoMessage()  {}
func (r *QueryParamsResponse) Reset()         {}
func (r *QueryParamsResponse) String() string { return "QueryParamsResponse{}" }

// --- Query/Settlement ---

type QuerySettlementRequest struct {
	Id uint64 `json:"id" yaml:"id"`
}
type QuerySettlementResponse struct {
	Settlement Settlement `json:"settlement" yaml:"settlement"`
}

func NewQuerySettlementResponse(s Settlement) *QuerySettlementResponse {
	return &QuerySettlementResponse{Settlement: s}
}

func (r *QuerySettlementRequest) ProtoMessage()   {}
func (r *QuerySettlementRequest) Reset()          {}
func (r *QuerySettlementRequest) String() string  { return "QuerySettlementRequest{}" }
func (r *QuerySettlementResponse) ProtoMessage()  {}
func (r *QuerySettlementResponse) Reset()         {}
func (r *QuerySettlementResponse) String() string { return "QuerySettlementResponse{}" }

// --- Query/SettlementsByPayer ---

type QuerySettlementsByPayerRequest struct {
	Payer string `json:"payer" yaml:"payer"`
}
type QuerySettlementsByPayerResponse struct {
	Settlements []Settlement `json:"settlements" yaml:"settlements"`
}

func NewQuerySettlementsByPayerResponse(settlements []Settlement) *QuerySettlementsByPayerResponse {
	return &QuerySettlementsByPayerResponse{Settlements: settlements}
}

func (r *QuerySettlementsByPayerRequest) ProtoMessage()   {}
func (r *QuerySettlementsByPayerRequest) Reset()          {}
func (r *QuerySettlementsByPayerRequest) String() string  { return "QuerySettlementsByPayerRequest{}" }
func (r *QuerySettlementsByPayerResponse) ProtoMessage()  {}
func (r *QuerySettlementsByPayerResponse) Reset()         {}
func (r *QuerySettlementsByPayerResponse) String() string { return "QuerySettlementsByPayerResponse{}" }

// --- Query/SettlementsByMerchant ---

type QuerySettlementsByMerchantRequest struct {
	MerchantOwner string `json:"merchant_owner" yaml:"merchant_owner"`
}
type QuerySettlementsByMerchantResponse struct {
	Settlements []Settlement `json:"settlements" yaml:"settlements"`
}

func NewQuerySettlementsByMerchantResponse(settlements []Settlement) *QuerySettlementsByMerchantResponse {
	return &QuerySettlementsByMerchantResponse{Settlements: settlements}
}

func (r *QuerySettlementsByMerchantRequest) ProtoMessage() {}
func (r *QuerySettlementsByMerchantRequest) Reset()        {}
func (r *QuerySettlementsByMerchantRequest) String() string {
	return "QuerySettlementsByMerchantRequest{}"
}
func (r *QuerySettlementsByMerchantResponse) ProtoMessage() {}
func (r *QuerySettlementsByMerchantResponse) Reset()        {}
func (r *QuerySettlementsByMerchantResponse) String() string {
	return "QuerySettlementsByMerchantResponse{}"
}

// --- Query/Settlements (all) ---

type QuerySettlementsRequest struct{}
type QuerySettlementsResponse struct {
	Settlements []Settlement `json:"settlements" yaml:"settlements"`
}

func NewQuerySettlementsResponse(settlements []Settlement) *QuerySettlementsResponse {
	return &QuerySettlementsResponse{Settlements: settlements}
}

func (r *QuerySettlementsRequest) ProtoMessage()   {}
func (r *QuerySettlementsRequest) Reset()          {}
func (r *QuerySettlementsRequest) String() string  { return "QuerySettlementsRequest{}" }
func (r *QuerySettlementsResponse) ProtoMessage()  {}
func (r *QuerySettlementsResponse) Reset()         {}
func (r *QuerySettlementsResponse) String() string { return "QuerySettlementsResponse{}" }
