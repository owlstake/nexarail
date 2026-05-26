package types

import (
	"fmt"
	sdk "github.com/cosmos/cosmos-sdk/types"
)

var _ sdk.Msg = (*MsgCreateTreasuryAccount)(nil)
var _ sdk.Msg = (*MsgCreateBudget)(nil)
var _ sdk.Msg = (*MsgUpdateBudgetStatus)(nil)
var _ sdk.Msg = (*MsgCreateGrant)(nil)
var _ sdk.Msg = (*MsgUpdateGrantStatus)(nil)
var _ sdk.Msg = (*MsgCreateSpendRequest)(nil)
var _ sdk.Msg = (*MsgApproveSpendRequest)(nil)
var _ sdk.Msg = (*MsgRejectSpendRequest)(nil)
var _ sdk.Msg = (*MsgMarkSpendExecuted)(nil)
var _ sdk.Msg = (*MsgCancelSpendRequest)(nil)
var _ sdk.Msg = (*MsgUpdateParams)(nil)

type MsgCreateTreasuryAccount struct {
	Authority      string
	AccountId      string
	Category       int32
	Name           string
	Description    string
	MetadataUri    string
	NominalBalance sdk.Coin
}

func NewMsgCreateTreasuryAccount(auth, id string, cat int32, name, desc, uri string, bal sdk.Coin) *MsgCreateTreasuryAccount {
	return &MsgCreateTreasuryAccount{auth, id, cat, name, desc, uri, bal}
}
func (m *MsgCreateTreasuryAccount) ProtoMessage()  {}
func (m *MsgCreateTreasuryAccount) Reset()         { *m = MsgCreateTreasuryAccount{} }
func (m *MsgCreateTreasuryAccount) String() string { return fmt.Sprintf("CreateAcct{%s}", m.AccountId) }
func (m MsgCreateTreasuryAccount) Route() string   { return RouterKey }
func (m MsgCreateTreasuryAccount) Type() string    { return "create_account" }
func (m MsgCreateTreasuryAccount) ValidateBasic() error {
	_, e := sdk.AccAddressFromBech32(m.Authority)
	return e
}
func (m MsgCreateTreasuryAccount) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Authority)
	return []sdk.AccAddress{a}
}
func (m MsgCreateTreasuryAccount) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

type MsgCreateBudget struct {
	Authority   string
	BudgetId    string
	AccountId   string
	Category    int32
	Title       string
	Description string
	TotalAmount sdk.Coin
	StartTime   int64
	EndTime     int64
	MetadataUri string
}

func NewMsgCreateBudget(auth, bid, aid string, cat int32, title, desc string, total sdk.Coin, st, et int64, uri string) *MsgCreateBudget {
	return &MsgCreateBudget{auth, bid, aid, cat, title, desc, total, st, et, uri}
}
func (m *MsgCreateBudget) ProtoMessage()  {}
func (m *MsgCreateBudget) Reset()         { *m = MsgCreateBudget{} }
func (m *MsgCreateBudget) String() string { return fmt.Sprintf("CreateBudget{%s}", m.BudgetId) }
func (m MsgCreateBudget) Route() string   { return RouterKey }
func (m MsgCreateBudget) Type() string    { return "create_budget" }
func (m MsgCreateBudget) ValidateBasic() error {
	_, e := sdk.AccAddressFromBech32(m.Authority)
	return e
}
func (m MsgCreateBudget) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Authority)
	return []sdk.AccAddress{a}
}
func (m MsgCreateBudget) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

type MsgUpdateBudgetStatus struct {
	Authority string
	BudgetId  string
	Status    int32
}

func NewMsgUpdateBudgetStatus(auth, id string, status int32) *MsgUpdateBudgetStatus {
	return &MsgUpdateBudgetStatus{auth, id, status}
}
func (m *MsgUpdateBudgetStatus) ProtoMessage()  {}
func (m *MsgUpdateBudgetStatus) Reset()         { *m = MsgUpdateBudgetStatus{} }
func (m *MsgUpdateBudgetStatus) String() string { return fmt.Sprintf("UpdateBudget{%s}", m.BudgetId) }
func (m MsgUpdateBudgetStatus) Route() string   { return RouterKey }
func (m MsgUpdateBudgetStatus) Type() string    { return "update_budget_status" }
func (m MsgUpdateBudgetStatus) ValidateBasic() error {
	_, e := sdk.AccAddressFromBech32(m.Authority)
	return e
}
func (m MsgUpdateBudgetStatus) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Authority)
	return []sdk.AccAddress{a}
}
func (m MsgUpdateBudgetStatus) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

type MsgCreateGrant struct {
	Authority        string
	GrantId          string
	BudgetId         string
	RecipientAddress string
	Title            string
	Description      string
	Amount           sdk.Coin
	MilestoneCount   uint32
	MetadataUri      string
}

func NewMsgCreateGrant(auth, gid, bid, recip, title, desc string, amt sdk.Coin, mc uint32, uri string) *MsgCreateGrant {
	return &MsgCreateGrant{auth, gid, bid, recip, title, desc, amt, mc, uri}
}
func (m *MsgCreateGrant) ProtoMessage()  {}
func (m *MsgCreateGrant) Reset()         { *m = MsgCreateGrant{} }
func (m *MsgCreateGrant) String() string { return fmt.Sprintf("CreateGrant{%s}", m.GrantId) }
func (m MsgCreateGrant) Route() string   { return RouterKey }
func (m MsgCreateGrant) Type() string    { return "create_grant" }
func (m MsgCreateGrant) ValidateBasic() error {
	_, e := sdk.AccAddressFromBech32(m.Authority)
	return e
}
func (m MsgCreateGrant) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Authority)
	return []sdk.AccAddress{a}
}
func (m MsgCreateGrant) GetSignBytes() []byte { return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m)) }

type MsgUpdateGrantStatus struct {
	Authority string
	GrantId   string
	Status    int32
}

func NewMsgUpdateGrantStatus(auth, id string, status int32) *MsgUpdateGrantStatus {
	return &MsgUpdateGrantStatus{auth, id, status}
}
func (m *MsgUpdateGrantStatus) ProtoMessage()  {}
func (m *MsgUpdateGrantStatus) Reset()         { *m = MsgUpdateGrantStatus{} }
func (m *MsgUpdateGrantStatus) String() string { return fmt.Sprintf("UpdateGrant{%s}", m.GrantId) }
func (m MsgUpdateGrantStatus) Route() string   { return RouterKey }
func (m MsgUpdateGrantStatus) Type() string    { return "update_grant_status" }
func (m MsgUpdateGrantStatus) ValidateBasic() error {
	_, e := sdk.AccAddressFromBech32(m.Authority)
	return e
}
func (m MsgUpdateGrantStatus) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Authority)
	return []sdk.AccAddress{a}
}
func (m MsgUpdateGrantStatus) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

type MsgCreateSpendRequest struct {
	Requester        string
	SpendId          string
	AccountId        string
	BudgetId         string
	GrantId          string
	RecipientAddress string
	Amount           sdk.Coin
	Purpose          string
	Reference        string
	Memo             string
}

func NewMsgCreateSpendRequest(req, sid, aid, bid, gid, recip string, amt sdk.Coin, purpose, ref, memo string) *MsgCreateSpendRequest {
	return &MsgCreateSpendRequest{req, sid, aid, bid, gid, recip, amt, purpose, ref, memo}
}
func (m *MsgCreateSpendRequest) ProtoMessage()  {}
func (m *MsgCreateSpendRequest) Reset()         { *m = MsgCreateSpendRequest{} }
func (m *MsgCreateSpendRequest) String() string { return fmt.Sprintf("CreateSpend{%s}", m.SpendId) }
func (m MsgCreateSpendRequest) Route() string   { return RouterKey }
func (m MsgCreateSpendRequest) Type() string    { return "create_spend" }
func (m MsgCreateSpendRequest) ValidateBasic() error {
	_, e := sdk.AccAddressFromBech32(m.Requester)
	return e
}
func (m MsgCreateSpendRequest) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Requester)
	return []sdk.AccAddress{a}
}
func (m MsgCreateSpendRequest) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

type MsgApproveSpendRequest struct {
	Authority string
	SpendId   string
}

func NewMsgApproveSpendRequest(auth, id string) *MsgApproveSpendRequest {
	return &MsgApproveSpendRequest{auth, id}
}
func (m *MsgApproveSpendRequest) ProtoMessage()  {}
func (m *MsgApproveSpendRequest) Reset()         { *m = MsgApproveSpendRequest{} }
func (m *MsgApproveSpendRequest) String() string { return fmt.Sprintf("ApproveSpend{%s}", m.SpendId) }
func (m MsgApproveSpendRequest) Route() string   { return RouterKey }
func (m MsgApproveSpendRequest) Type() string    { return "approve_spend" }
func (m MsgApproveSpendRequest) ValidateBasic() error {
	_, e := sdk.AccAddressFromBech32(m.Authority)
	return e
}
func (m MsgApproveSpendRequest) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Authority)
	return []sdk.AccAddress{a}
}
func (m MsgApproveSpendRequest) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

type MsgRejectSpendRequest struct {
	Authority string
	SpendId   string
	Memo      string
}

func NewMsgRejectSpendRequest(auth, id, memo string) *MsgRejectSpendRequest {
	return &MsgRejectSpendRequest{auth, id, memo}
}
func (m *MsgRejectSpendRequest) ProtoMessage()  {}
func (m *MsgRejectSpendRequest) Reset()         { *m = MsgRejectSpendRequest{} }
func (m *MsgRejectSpendRequest) String() string { return fmt.Sprintf("RejectSpend{%s}", m.SpendId) }
func (m MsgRejectSpendRequest) Route() string   { return RouterKey }
func (m MsgRejectSpendRequest) Type() string    { return "reject_spend" }
func (m MsgRejectSpendRequest) ValidateBasic() error {
	_, e := sdk.AccAddressFromBech32(m.Authority)
	return e
}
func (m MsgRejectSpendRequest) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Authority)
	return []sdk.AccAddress{a}
}
func (m MsgRejectSpendRequest) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

type MsgMarkSpendExecuted struct {
	Authority string
	SpendId   string
	Reference string
	Memo      string
}

func NewMsgMarkSpendExecuted(auth, id, ref, memo string) *MsgMarkSpendExecuted {
	return &MsgMarkSpendExecuted{auth, id, ref, memo}
}
func (m *MsgMarkSpendExecuted) ProtoMessage()  {}
func (m *MsgMarkSpendExecuted) Reset()         { *m = MsgMarkSpendExecuted{} }
func (m *MsgMarkSpendExecuted) String() string { return fmt.Sprintf("ExecuteSpend{%s}", m.SpendId) }
func (m MsgMarkSpendExecuted) Route() string   { return RouterKey }
func (m MsgMarkSpendExecuted) Type() string    { return "mark_spend_executed" }
func (m MsgMarkSpendExecuted) ValidateBasic() error {
	_, e := sdk.AccAddressFromBech32(m.Authority)
	return e
}
func (m MsgMarkSpendExecuted) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Authority)
	return []sdk.AccAddress{a}
}
func (m MsgMarkSpendExecuted) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

type MsgCancelSpendRequest struct {
	Signer  string
	SpendId string
	Memo    string
}

func NewMsgCancelSpendRequest(signer, id, memo string) *MsgCancelSpendRequest {
	return &MsgCancelSpendRequest{signer, id, memo}
}
func (m *MsgCancelSpendRequest) ProtoMessage()  {}
func (m *MsgCancelSpendRequest) Reset()         { *m = MsgCancelSpendRequest{} }
func (m *MsgCancelSpendRequest) String() string { return fmt.Sprintf("CancelSpend{%s}", m.SpendId) }
func (m MsgCancelSpendRequest) Route() string   { return RouterKey }
func (m MsgCancelSpendRequest) Type() string    { return "cancel_spend" }
func (m MsgCancelSpendRequest) ValidateBasic() error {
	_, e := sdk.AccAddressFromBech32(m.Signer)
	return e
}
func (m MsgCancelSpendRequest) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Signer)
	return []sdk.AccAddress{a}
}
func (m MsgCancelSpendRequest) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

type MsgUpdateParams struct {
	Authority string
	Params    Params
}

func NewMsgUpdateParams(auth string, p Params) *MsgUpdateParams { return &MsgUpdateParams{auth, p} }
func (m *MsgUpdateParams) ProtoMessage()                        {}
func (m *MsgUpdateParams) Reset()                               { *m = MsgUpdateParams{} }
func (m *MsgUpdateParams) String() string                       { return fmt.Sprintf("UpdateParams{%s}", m.Authority) }
func (m MsgUpdateParams) Route() string                         { return RouterKey }
func (m MsgUpdateParams) Type() string                          { return "update_params" }
func (m MsgUpdateParams) ValidateBasic() error {
	_, e := sdk.AccAddressFromBech32(m.Authority)
	return e
}
func (m MsgUpdateParams) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Authority)
	return []sdk.AccAddress{a}
}
func (m MsgUpdateParams) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

type MsgCreateTreasuryAccountResponse struct{}
type MsgCreateBudgetResponse struct{}
type MsgUpdateBudgetStatusResponse struct{}
type MsgCreateGrantResponse struct{}
type MsgUpdateGrantStatusResponse struct{}
type MsgCreateSpendRequestResponse struct{}
type MsgApproveSpendRequestResponse struct{}
type MsgRejectSpendRequestResponse struct{}
type MsgMarkSpendExecutedResponse struct{}
type MsgCancelSpendRequestResponse struct{}
type MsgUpdateParamsResponse struct{}

func (r *MsgCreateTreasuryAccountResponse) ProtoMessage()  {}
func (r *MsgCreateTreasuryAccountResponse) Reset()         {}
func (r *MsgCreateTreasuryAccountResponse) String() string { return "CreateAcctResp{}" }
func (r *MsgCreateBudgetResponse) ProtoMessage()           {}
func (r *MsgCreateBudgetResponse) Reset()                  {}
func (r *MsgCreateBudgetResponse) String() string          { return "CreateBudgetResp{}" }
func (r *MsgUpdateBudgetStatusResponse) ProtoMessage()     {}
func (r *MsgUpdateBudgetStatusResponse) Reset()            {}
func (r *MsgUpdateBudgetStatusResponse) String() string    { return "UpdateBudgetResp{}" }
func (r *MsgCreateGrantResponse) ProtoMessage()            {}
func (r *MsgCreateGrantResponse) Reset()                   {}
func (r *MsgCreateGrantResponse) String() string           { return "CreateGrantResp{}" }
func (r *MsgUpdateGrantStatusResponse) ProtoMessage()      {}
func (r *MsgUpdateGrantStatusResponse) Reset()             {}
func (r *MsgUpdateGrantStatusResponse) String() string     { return "UpdateGrantResp{}" }
func (r *MsgCreateSpendRequestResponse) ProtoMessage()     {}
func (r *MsgCreateSpendRequestResponse) Reset()            {}
func (r *MsgCreateSpendRequestResponse) String() string    { return "CreateSpendResp{}" }
func (r *MsgApproveSpendRequestResponse) ProtoMessage()    {}
func (r *MsgApproveSpendRequestResponse) Reset()           {}
func (r *MsgApproveSpendRequestResponse) String() string   { return "ApproveSpendResp{}" }
func (r *MsgRejectSpendRequestResponse) ProtoMessage()     {}
func (r *MsgRejectSpendRequestResponse) Reset()            {}
func (r *MsgRejectSpendRequestResponse) String() string    { return "RejectSpendResp{}" }
func (r *MsgMarkSpendExecutedResponse) ProtoMessage()      {}
func (r *MsgMarkSpendExecutedResponse) Reset()             {}
func (r *MsgMarkSpendExecutedResponse) String() string     { return "MarkExecResp{}" }
func (r *MsgCancelSpendRequestResponse) ProtoMessage()     {}
func (r *MsgCancelSpendRequestResponse) Reset()            {}
func (r *MsgCancelSpendRequestResponse) String() string    { return "CancelSpendResp{}" }
func (r *MsgUpdateParamsResponse) ProtoMessage()           {}
func (r *MsgUpdateParamsResponse) Reset()                  {}
func (r *MsgUpdateParamsResponse) String() string          { return "UpdateParamsResp{}" }
