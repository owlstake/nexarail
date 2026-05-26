package types

// QueryParams
type QueryParamsRequest struct{}
type QueryParamsResponse struct {
	Params Params `json:"params" yaml:"params"`
}

func NewQueryParamsResponse(p Params) *QueryParamsResponse { return &QueryParamsResponse{Params: p} }

// QueryEscrow
type QueryEscrowRequest struct {
	EscrowId string `json:"escrow_id" yaml:"escrow_id"`
}
type QueryEscrowResponse struct {
	Escrow Escrow `json:"escrow" yaml:"escrow"`
}

func NewQueryEscrowResponse(e Escrow) *QueryEscrowResponse { return &QueryEscrowResponse{Escrow: e} }

// QueryEscrows
type QueryEscrowsRequest struct{}
type QueryEscrowsResponse struct {
	Escrows []Escrow `json:"escrows" yaml:"escrows"`
}

func NewQueryEscrowsResponse(es []Escrow) *QueryEscrowsResponse {
	return &QueryEscrowsResponse{Escrows: es}
}

// QueryEscrowsByBuyer
type QueryEscrowsByBuyerRequest struct {
	Buyer string `json:"buyer" yaml:"buyer"`
}
type QueryEscrowsByBuyerResponse struct {
	Escrows []Escrow `json:"escrows" yaml:"escrows"`
}

func NewQueryEscrowsByBuyerResponse(es []Escrow) *QueryEscrowsByBuyerResponse {
	return &QueryEscrowsByBuyerResponse{Escrows: es}
}

// QueryEscrowsBySeller
type QueryEscrowsBySellerRequest struct {
	Seller string `json:"seller" yaml:"seller"`
}
type QueryEscrowsBySellerResponse struct {
	Escrows []Escrow `json:"escrows" yaml:"escrows"`
}

func NewQueryEscrowsBySellerResponse(es []Escrow) *QueryEscrowsBySellerResponse {
	return &QueryEscrowsBySellerResponse{Escrows: es}
}

// QueryEscrowsByMerchant
type QueryEscrowsByMerchantRequest struct {
	MerchantId string `json:"merchant_id" yaml:"merchant_id"`
}
type QueryEscrowsByMerchantResponse struct {
	Escrows []Escrow `json:"escrows" yaml:"escrows"`
}

func NewQueryEscrowsByMerchantResponse(es []Escrow) *QueryEscrowsByMerchantResponse {
	return &QueryEscrowsByMerchantResponse{Escrows: es}
}

// QueryEscrowExists
type QueryEscrowExistsRequest struct {
	EscrowId string `json:"escrow_id" yaml:"escrow_id"`
}
type QueryEscrowExistsResponse struct {
	Exists bool `json:"exists" yaml:"exists"`
}

func NewQueryEscrowExistsResponse(exists bool) *QueryEscrowExistsResponse {
	return &QueryEscrowExistsResponse{Exists: exists}
}

// ProtoMessage boilerplate for all query types
func (r *QueryParamsRequest) ProtoMessage()              {}
func (r *QueryParamsRequest) Reset()                     {}
func (r *QueryParamsRequest) String() string             { return "QueryParamsRequest{}" }
func (r *QueryParamsResponse) ProtoMessage()             {}
func (r *QueryParamsResponse) Reset()                    {}
func (r *QueryParamsResponse) String() string            { return "QueryParamsResponse{}" }
func (r *QueryEscrowRequest) ProtoMessage()              {}
func (r *QueryEscrowRequest) Reset()                     {}
func (r *QueryEscrowRequest) String() string             { return "QueryEscrowRequest{}" }
func (r *QueryEscrowResponse) ProtoMessage()             {}
func (r *QueryEscrowResponse) Reset()                    {}
func (r *QueryEscrowResponse) String() string            { return "QueryEscrowResponse{}" }
func (r *QueryEscrowsRequest) ProtoMessage()             {}
func (r *QueryEscrowsRequest) Reset()                    {}
func (r *QueryEscrowsRequest) String() string            { return "QueryEscrowsRequest{}" }
func (r *QueryEscrowsResponse) ProtoMessage()            {}
func (r *QueryEscrowsResponse) Reset()                   {}
func (r *QueryEscrowsResponse) String() string           { return "QueryEscrowsResponse{}" }
func (r *QueryEscrowsByBuyerRequest) ProtoMessage()      {}
func (r *QueryEscrowsByBuyerRequest) Reset()             {}
func (r *QueryEscrowsByBuyerRequest) String() string     { return "QueryEscrowsByBuyerRequest{}" }
func (r *QueryEscrowsByBuyerResponse) ProtoMessage()     {}
func (r *QueryEscrowsByBuyerResponse) Reset()            {}
func (r *QueryEscrowsByBuyerResponse) String() string    { return "QueryEscrowsByBuyerResponse{}" }
func (r *QueryEscrowsBySellerRequest) ProtoMessage()     {}
func (r *QueryEscrowsBySellerRequest) Reset()            {}
func (r *QueryEscrowsBySellerRequest) String() string    { return "QueryEscrowsBySellerRequest{}" }
func (r *QueryEscrowsBySellerResponse) ProtoMessage()    {}
func (r *QueryEscrowsBySellerResponse) Reset()           {}
func (r *QueryEscrowsBySellerResponse) String() string   { return "QueryEscrowsBySellerResponse{}" }
func (r *QueryEscrowsByMerchantRequest) ProtoMessage()   {}
func (r *QueryEscrowsByMerchantRequest) Reset()          {}
func (r *QueryEscrowsByMerchantRequest) String() string  { return "QueryEscrowsByMerchantRequest{}" }
func (r *QueryEscrowsByMerchantResponse) ProtoMessage()  {}
func (r *QueryEscrowsByMerchantResponse) Reset()         {}
func (r *QueryEscrowsByMerchantResponse) String() string { return "QueryEscrowsByMerchantResponse{}" }
func (r *QueryEscrowExistsRequest) ProtoMessage()        {}
func (r *QueryEscrowExistsRequest) Reset()               {}
func (r *QueryEscrowExistsRequest) String() string       { return "QueryEscrowExistsRequest{}" }
func (r *QueryEscrowExistsResponse) ProtoMessage()       {}
func (r *QueryEscrowExistsResponse) Reset()              {}
func (r *QueryEscrowExistsResponse) String() string      { return "QueryEscrowExistsResponse{}" }
