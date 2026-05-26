package types

type QueryParamsRequest struct{}
type QueryParamsResponse struct {
	Params Params `json:"params"`
}

func NewQueryParamsResponse(p Params) *QueryParamsResponse { return &QueryParamsResponse{p} }

type QueryPayoutRequest struct {
	PayoutId string `json:"payout_id"`
}
type QueryPayoutResponse struct {
	Payout Payout `json:"payout"`
}

func NewQueryPayoutResponse(p Payout) *QueryPayoutResponse { return &QueryPayoutResponse{p} }

type QueryPayoutsRequest struct{}
type QueryPayoutsResponse struct {
	Payouts []Payout `json:"payouts"`
}

func NewQueryPayoutsResponse(ps []Payout) *QueryPayoutsResponse { return &QueryPayoutsResponse{ps} }

type QueryPayoutsByMerchantRequest struct {
	MerchantId string `json:"merchant_id"`
}
type QueryPayoutsByMerchantResponse struct {
	Payouts []Payout `json:"payouts"`
}

func NewQueryPayoutsByMerchantResponse(ps []Payout) *QueryPayoutsByMerchantResponse {
	return &QueryPayoutsByMerchantResponse{ps}
}

type QueryPayoutsByRecipientRequest struct {
	Recipient string `json:"recipient"`
}
type QueryPayoutsByRecipientResponse struct {
	Payouts []Payout `json:"payouts"`
}

func NewQueryPayoutsByRecipientResponse(ps []Payout) *QueryPayoutsByRecipientResponse {
	return &QueryPayoutsByRecipientResponse{ps}
}

type QueryPayoutsByInitiatorRequest struct {
	Initiator string `json:"initiator"`
}
type QueryPayoutsByInitiatorResponse struct {
	Payouts []Payout `json:"payouts"`
}

func NewQueryPayoutsByInitiatorResponse(ps []Payout) *QueryPayoutsByInitiatorResponse {
	return &QueryPayoutsByInitiatorResponse{ps}
}

type QueryBatchPayoutRequest struct {
	BatchId string `json:"batch_id"`
}
type QueryBatchPayoutResponse struct {
	BatchPayout BatchPayout `json:"batch_payout"`
}

func NewQueryBatchPayoutResponse(b BatchPayout) *QueryBatchPayoutResponse {
	return &QueryBatchPayoutResponse{b}
}

type QueryBatchPayoutsRequest struct{}
type QueryBatchPayoutsResponse struct {
	BatchPayouts []BatchPayout `json:"batch_payouts"`
}

func NewQueryBatchPayoutsResponse(bs []BatchPayout) *QueryBatchPayoutsResponse {
	return &QueryBatchPayoutsResponse{bs}
}

type QueryPayoutExistsRequest struct {
	PayoutId string `json:"payout_id"`
}
type QueryPayoutExistsResponse struct {
	Exists bool `json:"exists"`
}

func NewQueryPayoutExistsResponse(exists bool) *QueryPayoutExistsResponse {
	return &QueryPayoutExistsResponse{exists}
}

// proto boilerplate
func (r *QueryParamsRequest) ProtoMessage()               {}
func (r *QueryParamsRequest) Reset()                      {}
func (r *QueryParamsRequest) String() string              { return "QPReq{}" }
func (r *QueryParamsResponse) ProtoMessage()              {}
func (r *QueryParamsResponse) Reset()                     {}
func (r *QueryParamsResponse) String() string             { return "QPResp{}" }
func (r *QueryPayoutRequest) ProtoMessage()               {}
func (r *QueryPayoutRequest) Reset()                      {}
func (r *QueryPayoutRequest) String() string              { return "QPReq{}" }
func (r *QueryPayoutResponse) ProtoMessage()              {}
func (r *QueryPayoutResponse) Reset()                     {}
func (r *QueryPayoutResponse) String() string             { return "QPResp{}" }
func (r *QueryPayoutsRequest) ProtoMessage()              {}
func (r *QueryPayoutsRequest) Reset()                     {}
func (r *QueryPayoutsRequest) String() string             { return "QPsReq{}" }
func (r *QueryPayoutsResponse) ProtoMessage()             {}
func (r *QueryPayoutsResponse) Reset()                    {}
func (r *QueryPayoutsResponse) String() string            { return "QPsResp{}" }
func (r *QueryPayoutsByMerchantRequest) ProtoMessage()    {}
func (r *QueryPayoutsByMerchantRequest) Reset()           {}
func (r *QueryPayoutsByMerchantRequest) String() string   { return "QPBMReq{}" }
func (r *QueryPayoutsByMerchantResponse) ProtoMessage()   {}
func (r *QueryPayoutsByMerchantResponse) Reset()          {}
func (r *QueryPayoutsByMerchantResponse) String() string  { return "QPBMResp{}" }
func (r *QueryPayoutsByRecipientRequest) ProtoMessage()   {}
func (r *QueryPayoutsByRecipientRequest) Reset()          {}
func (r *QueryPayoutsByRecipientRequest) String() string  { return "QPBRReq{}" }
func (r *QueryPayoutsByRecipientResponse) ProtoMessage()  {}
func (r *QueryPayoutsByRecipientResponse) Reset()         {}
func (r *QueryPayoutsByRecipientResponse) String() string { return "QPBRResp{}" }
func (r *QueryPayoutsByInitiatorRequest) ProtoMessage()   {}
func (r *QueryPayoutsByInitiatorRequest) Reset()          {}
func (r *QueryPayoutsByInitiatorRequest) String() string  { return "QPBIReq{}" }
func (r *QueryPayoutsByInitiatorResponse) ProtoMessage()  {}
func (r *QueryPayoutsByInitiatorResponse) Reset()         {}
func (r *QueryPayoutsByInitiatorResponse) String() string { return "QPBIResp{}" }
func (r *QueryBatchPayoutRequest) ProtoMessage()          {}
func (r *QueryBatchPayoutRequest) Reset()                 {}
func (r *QueryBatchPayoutRequest) String() string         { return "QBPReq{}" }
func (r *QueryBatchPayoutResponse) ProtoMessage()         {}
func (r *QueryBatchPayoutResponse) Reset()                {}
func (r *QueryBatchPayoutResponse) String() string        { return "QBPResp{}" }
func (r *QueryBatchPayoutsRequest) ProtoMessage()         {}
func (r *QueryBatchPayoutsRequest) Reset()                {}
func (r *QueryBatchPayoutsRequest) String() string        { return "QBPsReq{}" }
func (r *QueryBatchPayoutsResponse) ProtoMessage()        {}
func (r *QueryBatchPayoutsResponse) Reset()               {}
func (r *QueryBatchPayoutsResponse) String() string       { return "QBPsResp{}" }
func (r *QueryPayoutExistsRequest) ProtoMessage()         {}
func (r *QueryPayoutExistsRequest) Reset()                {}
func (r *QueryPayoutExistsRequest) String() string        { return "QPEReq{}" }
func (r *QueryPayoutExistsResponse) ProtoMessage()        {}
func (r *QueryPayoutExistsResponse) Reset()               {}
func (r *QueryPayoutExistsResponse) String() string       { return "QPEResp{}" }
