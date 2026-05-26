package types

// --- Query/Params ---

type QueryParamsRequest struct{}

func (r *QueryParamsRequest) ProtoMessage()  {}
func (r *QueryParamsRequest) Reset()         {}
func (r *QueryParamsRequest) String() string { return "QueryParamsRequest{}" }

type QueryParamsResponse struct {
	Params Params `json:"params" yaml:"params"`
}

func (r *QueryParamsResponse) ProtoMessage()  {}
func (r *QueryParamsResponse) Reset()         {}
func (r *QueryParamsResponse) String() string { return "QueryParamsResponse{}" }

func NewQueryParamsResponse(params Params) *QueryParamsResponse {
	return &QueryParamsResponse{Params: params}
}

// --- Query/Merchant ---

type QueryMerchantRequest struct {
	Owner string `json:"owner" yaml:"owner"`
}

func (r *QueryMerchantRequest) ProtoMessage()  {}
func (r *QueryMerchantRequest) Reset()         {}
func (r *QueryMerchantRequest) String() string { return "QueryMerchantRequest{}" }

type QueryMerchantResponse struct {
	Merchant Merchant `json:"merchant" yaml:"merchant"`
}

func (r *QueryMerchantResponse) ProtoMessage()  {}
func (r *QueryMerchantResponse) Reset()         {}
func (r *QueryMerchantResponse) String() string { return "QueryMerchantResponse{}" }

func NewQueryMerchantResponse(m Merchant) *QueryMerchantResponse {
	return &QueryMerchantResponse{Merchant: m}
}

// --- Query/Merchants ---

type QueryMerchantsRequest struct {
	Pagination *PageRequest `json:"pagination,omitempty" yaml:"pagination,omitempty"`
}

func (r *QueryMerchantsRequest) ProtoMessage()  {}
func (r *QueryMerchantsRequest) Reset()         {}
func (r *QueryMerchantsRequest) String() string { return "QueryMerchantsRequest{}" }

type QueryMerchantsResponse struct {
	Merchants  []Merchant    `json:"merchants" yaml:"merchants"`
	Pagination *PageResponse `json:"pagination,omitempty" yaml:"pagination,omitempty"`
}

func (r *QueryMerchantsResponse) ProtoMessage()  {}
func (r *QueryMerchantsResponse) Reset()         {}
func (r *QueryMerchantsResponse) String() string { return "QueryMerchantsResponse{}" }

// --- Pagination ---

type PageRequest struct {
	Key    string `json:"key" yaml:"key"`
	Offset uint64 `json:"offset" yaml:"offset"`
	Limit  uint64 `json:"limit" yaml:"limit"`
}

type PageResponse struct {
	NextKey string `json:"next_key" yaml:"next_key"`
	Total   uint64 `json:"total" yaml:"total"`
}
