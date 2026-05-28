package types

import (
	"fmt"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/nexarail/chain/x/common"
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
	Authority      string   `json:"authority" protobuf:"bytes,1,opt,name=authority,proto3"`
	AccountId      string   `json:"account_id" protobuf:"bytes,2,opt,name=account_id,json=accountId,proto3"`
	Category       int32    `json:"category" protobuf:"varint,3,opt,name=category,proto3"`
	Name           string   `json:"name" protobuf:"bytes,4,opt,name=name,proto3"`
	Description    string   `json:"description" protobuf:"bytes,5,opt,name=description,proto3"`
	MetadataUri    string   `json:"metadata_uri" protobuf:"bytes,6,opt,name=metadata_uri,json=metadataUri,proto3"`
	NominalBalance sdk.Coin `json:"nominal_balance" protobuf:"bytes,7,opt,name=nominal_balance,json=nominalBalance,proto3"`
}

func NewMsgCreateTreasuryAccount(auth, id string, cat int32, name, desc, uri string, bal sdk.Coin) *MsgCreateTreasuryAccount {
	return &MsgCreateTreasuryAccount{auth, id, cat, name, desc, uri, bal}
}
func (m *MsgCreateTreasuryAccount) ProtoMessage() {}
func (m *MsgCreateTreasuryAccount) Descriptor() ([]byte, []int) {
	return common.TreasuryDescriptorBytes, []int{1}
}
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
	Authority   string   `json:"authority" protobuf:"bytes,1,opt,name=authority,proto3"`
	BudgetId    string   `json:"budget_id" protobuf:"bytes,2,opt,name=budget_id,json=budgetId,proto3"`
	AccountId   string   `json:"account_id" protobuf:"bytes,3,opt,name=account_id,json=accountId,proto3"`
	Category    int32    `json:"category" protobuf:"varint,4,opt,name=category,proto3"`
	Title       string   `json:"title" protobuf:"bytes,5,opt,name=title,proto3"`
	Description string   `json:"description" protobuf:"bytes,6,opt,name=description,proto3"`
	TotalAmount sdk.Coin `json:"total_amount" protobuf:"bytes,7,opt,name=total_amount,json=totalAmount,proto3"`
	StartTime   int64    `json:"start_time" protobuf:"varint,8,opt,name=start_time,json=startTime,proto3"`
	EndTime     int64    `json:"end_time" protobuf:"varint,9,opt,name=end_time,json=endTime,proto3"`
	MetadataUri string   `json:"metadata_uri" protobuf:"bytes,10,opt,name=metadata_uri,json=metadataUri,proto3"`
}

func NewMsgCreateBudget(auth, bid, aid string, cat int32, title, desc string, total sdk.Coin, st, et int64, uri string) *MsgCreateBudget {
	return &MsgCreateBudget{auth, bid, aid, cat, title, desc, total, st, et, uri}
}
func (m *MsgCreateBudget) ProtoMessage() {}
func (m *MsgCreateBudget) Descriptor() ([]byte, []int) {
	return common.TreasuryDescriptorBytes, []int{2}
}
func (m *MsgCreateBudget) Reset()         { *m = MsgCreateBudget{} }
func (m *MsgCreateBudget) String() string { return fmt.Sprintf("CreateBudget{%s}", m.BudgetId) }
func (m MsgCreateBudget) Route() string   { return RouterKey }
func (m MsgCreateBudget) Type() string    { return "create_budget" }
func (m MsgCreateBudget) ValidateBasic() error {
	_, e := sdk.AccAddressFromBech32(m.Authority)
	if e != nil {
		return fmt.Errorf("invalid authority: %w", e)
	}
	if m.BudgetId == "" {
		return fmt.Errorf("budget_id is required")
	}
	if m.AccountId == "" {
		return fmt.Errorf("account_id is required")
	}
	if !m.TotalAmount.IsValid() || m.TotalAmount.IsNegative() {
		return fmt.Errorf("invalid total amount")
	}
	return nil
}
func (m MsgCreateBudget) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Authority)
	return []sdk.AccAddress{a}
}
func (m MsgCreateBudget) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

type MsgUpdateBudgetStatus struct {
	Authority string `json:"authority" protobuf:"bytes,1,opt,name=authority,proto3"`
	BudgetId  string `json:"budget_id" protobuf:"bytes,2,opt,name=budget_id,json=budgetId,proto3"`
	Status    int32  `json:"status" protobuf:"varint,3,opt,name=status,proto3"`
}

func NewMsgUpdateBudgetStatus(auth, id string, status int32) *MsgUpdateBudgetStatus {
	return &MsgUpdateBudgetStatus{auth, id, status}
}
func (m *MsgUpdateBudgetStatus) ProtoMessage() {}
func (m *MsgUpdateBudgetStatus) Descriptor() ([]byte, []int) {
	return common.TreasuryDescriptorBytes, []int{3}
}
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
	Authority        string   `json:"authority" protobuf:"bytes,1,opt,name=authority,proto3"`
	GrantId          string   `json:"grant_id" protobuf:"bytes,2,opt,name=grant_id,json=grantId,proto3"`
	BudgetId         string   `json:"budget_id" protobuf:"bytes,3,opt,name=budget_id,json=budgetId,proto3"`
	RecipientAddress string   `json:"recipient_address" protobuf:"bytes,4,opt,name=recipient_address,json=recipientAddress,proto3"`
	Title            string   `json:"title" protobuf:"bytes,5,opt,name=title,proto3"`
	Description      string   `json:"description" protobuf:"bytes,6,opt,name=description,proto3"`
	Amount           sdk.Coin `json:"amount" protobuf:"bytes,7,opt,name=amount,proto3"`
	MilestoneCount   uint32   `json:"milestone_count" protobuf:"varint,8,opt,name=milestone_count,json=milestoneCount,proto3"`
	MetadataUri      string   `json:"metadata_uri" protobuf:"bytes,9,opt,name=metadata_uri,json=metadataUri,proto3"`
}

func NewMsgCreateGrant(auth, gid, bid, recip, title, desc string, amt sdk.Coin, mc uint32, uri string) *MsgCreateGrant {
	return &MsgCreateGrant{auth, gid, bid, recip, title, desc, amt, mc, uri}
}
func (m *MsgCreateGrant) ProtoMessage() {}
func (m *MsgCreateGrant) Descriptor() ([]byte, []int) {
	return common.TreasuryDescriptorBytes, []int{4}
}
func (m *MsgCreateGrant) Reset()         { *m = MsgCreateGrant{} }
func (m *MsgCreateGrant) String() string { return fmt.Sprintf("CreateGrant{%s}", m.GrantId) }
func (m MsgCreateGrant) Route() string   { return RouterKey }
func (m MsgCreateGrant) Type() string    { return "create_grant" }
func (m MsgCreateGrant) ValidateBasic() error {
	_, e := sdk.AccAddressFromBech32(m.Authority)
	if e != nil {
		return fmt.Errorf("invalid authority: %w", e)
	}
	if m.GrantId == "" {
		return fmt.Errorf("grant_id is required")
	}
	if m.BudgetId == "" {
		return fmt.Errorf("budget_id is required")
	}
	if m.RecipientAddress != "" {
		if _, err := sdk.AccAddressFromBech32(m.RecipientAddress); err != nil {
			return fmt.Errorf("invalid recipient address: %w", err)
		}
	}
	if !m.Amount.IsValid() || m.Amount.IsNegative() {
		return fmt.Errorf("invalid amount")
	}
	return nil
}
func (m MsgCreateGrant) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Authority)
	return []sdk.AccAddress{a}
}
func (m MsgCreateGrant) GetSignBytes() []byte { return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m)) }

type MsgUpdateGrantStatus struct {
	Authority string `json:"authority" protobuf:"bytes,1,opt,name=authority,proto3"`
	GrantId   string `json:"grant_id" protobuf:"bytes,2,opt,name=grant_id,json=grantId,proto3"`
	Status    int32  `json:"status" protobuf:"varint,3,opt,name=status,proto3"`
}

func NewMsgUpdateGrantStatus(auth, id string, status int32) *MsgUpdateGrantStatus {
	return &MsgUpdateGrantStatus{auth, id, status}
}
func (m *MsgUpdateGrantStatus) ProtoMessage() {}
func (m *MsgUpdateGrantStatus) Descriptor() ([]byte, []int) {
	return common.TreasuryDescriptorBytes, []int{5}
}
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
	Requester        string   `json:"requester" protobuf:"bytes,1,opt,name=requester,proto3"`
	SpendId          string   `json:"spend_id" protobuf:"bytes,2,opt,name=spend_id,json=spendId,proto3"`
	AccountId        string   `json:"account_id" protobuf:"bytes,3,opt,name=account_id,json=accountId,proto3"`
	BudgetId         string   `json:"budget_id" protobuf:"bytes,4,opt,name=budget_id,json=budgetId,proto3"`
	GrantId          string   `json:"grant_id" protobuf:"bytes,5,opt,name=grant_id,json=grantId,proto3"`
	RecipientAddress string   `json:"recipient_address" protobuf:"bytes,6,opt,name=recipient_address,json=recipientAddress,proto3"`
	Amount           sdk.Coin `json:"amount" protobuf:"bytes,7,opt,name=amount,proto3"`
	Purpose          string   `json:"purpose" protobuf:"bytes,8,opt,name=purpose,proto3"`
	Reference        string   `json:"reference" protobuf:"bytes,9,opt,name=reference,proto3"`
	Memo             string   `json:"memo" protobuf:"bytes,10,opt,name=memo,proto3"`
}

func NewMsgCreateSpendRequest(req, sid, aid, bid, gid, recip string, amt sdk.Coin, purpose, ref, memo string) *MsgCreateSpendRequest {
	return &MsgCreateSpendRequest{req, sid, aid, bid, gid, recip, amt, purpose, ref, memo}
}
func (m *MsgCreateSpendRequest) ProtoMessage() {}
func (m *MsgCreateSpendRequest) Descriptor() ([]byte, []int) {
	return common.TreasuryDescriptorBytes, []int{6}
}
func (m *MsgCreateSpendRequest) Reset()         { *m = MsgCreateSpendRequest{} }
func (m *MsgCreateSpendRequest) String() string { return fmt.Sprintf("CreateSpend{%s}", m.SpendId) }
func (m MsgCreateSpendRequest) Route() string   { return RouterKey }
func (m MsgCreateSpendRequest) Type() string    { return "create_spend" }
func (m MsgCreateSpendRequest) ValidateBasic() error {
	_, e := sdk.AccAddressFromBech32(m.Requester)
	if e != nil {
		return fmt.Errorf("invalid requester: %w", e)
	}
	if m.SpendId == "" {
		return fmt.Errorf("spend_id is required")
	}
	if m.AccountId == "" {
		return fmt.Errorf("account_id is required")
	}
	if _, err := sdk.AccAddressFromBech32(m.RecipientAddress); err != nil {
		return fmt.Errorf("invalid recipient address: %w", err)
	}
	if !m.Amount.IsValid() || m.Amount.IsNegative() {
		return fmt.Errorf("invalid amount")
	}
	if len(m.Purpose) > 512 {
		return fmt.Errorf("purpose too long: max 512")
	}
	return nil
}
func (m MsgCreateSpendRequest) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Requester)
	return []sdk.AccAddress{a}
}
func (m MsgCreateSpendRequest) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

type MsgApproveSpendRequest struct {
	Authority string `json:"authority" protobuf:"bytes,1,opt,name=authority,proto3"`
	SpendId   string `json:"spend_id" protobuf:"bytes,2,opt,name=spend_id,json=spendId,proto3"`
}

func NewMsgApproveSpendRequest(auth, id string) *MsgApproveSpendRequest {
	return &MsgApproveSpendRequest{auth, id}
}
func (m *MsgApproveSpendRequest) ProtoMessage() {}
func (m *MsgApproveSpendRequest) Descriptor() ([]byte, []int) {
	return common.TreasuryDescriptorBytes, []int{7}
}
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
	Authority string `json:"authority" protobuf:"bytes,1,opt,name=authority,proto3"`
	SpendId   string `json:"spend_id" protobuf:"bytes,2,opt,name=spend_id,json=spendId,proto3"`
	Memo      string `json:"memo" protobuf:"bytes,3,opt,name=memo,proto3"`
}

func NewMsgRejectSpendRequest(auth, id, memo string) *MsgRejectSpendRequest {
	return &MsgRejectSpendRequest{auth, id, memo}
}
func (m *MsgRejectSpendRequest) ProtoMessage() {}
func (m *MsgRejectSpendRequest) Descriptor() ([]byte, []int) {
	return common.TreasuryDescriptorBytes, []int{8}
}
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
	Authority string `json:"authority" protobuf:"bytes,1,opt,name=authority,proto3"`
	SpendId   string `json:"spend_id" protobuf:"bytes,2,opt,name=spend_id,json=spendId,proto3"`
	Reference string `json:"reference" protobuf:"bytes,3,opt,name=reference,proto3"`
	Memo      string `json:"memo" protobuf:"bytes,4,opt,name=memo,proto3"`
}

func NewMsgMarkSpendExecuted(auth, id, ref, memo string) *MsgMarkSpendExecuted {
	return &MsgMarkSpendExecuted{auth, id, ref, memo}
}
func (m *MsgMarkSpendExecuted) ProtoMessage() {}
func (m *MsgMarkSpendExecuted) Descriptor() ([]byte, []int) {
	return common.TreasuryDescriptorBytes, []int{9}
}
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
	Signer  string `json:"signer" protobuf:"bytes,1,opt,name=signer,proto3"`
	SpendId string `json:"spend_id" protobuf:"bytes,2,opt,name=spend_id,json=spendId,proto3"`
	Memo    string `json:"memo" protobuf:"bytes,3,opt,name=memo,proto3"`
}

func NewMsgCancelSpendRequest(signer, id, memo string) *MsgCancelSpendRequest {
	return &MsgCancelSpendRequest{signer, id, memo}
}
func (m *MsgCancelSpendRequest) ProtoMessage() {}
func (m *MsgCancelSpendRequest) Descriptor() ([]byte, []int) {
	return common.TreasuryDescriptorBytes, []int{10}
}
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
	Authority string `json:"authority" protobuf:"bytes,1,opt,name=authority,proto3"`
	Params    Params `json:"params" protobuf:"bytes,2,opt,name=params,proto3"`
}

func NewMsgUpdateParams(auth string, p Params) *MsgUpdateParams { return &MsgUpdateParams{auth, p} }
func (m *MsgUpdateParams) ProtoMessage()                        {}

// Descriptor implements the descriptorIface for proto unknown field checking.
func (m *MsgUpdateParams) Descriptor() ([]byte, []int) {
	return common.TreasuryDescriptorBytes, []int{11}
}
func (m *MsgUpdateParams) Reset()         { *m = MsgUpdateParams{} }
func (m *MsgUpdateParams) String() string { return fmt.Sprintf("UpdateParams{%s}", m.Authority) }
func (m MsgUpdateParams) Route() string   { return RouterKey }
func (m MsgUpdateParams) Type() string    { return "update_params" }
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
