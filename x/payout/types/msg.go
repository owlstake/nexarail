package types

import (
	"fmt"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/nexarail/chain/x/common"
)

var _ sdk.Msg = (*MsgCreatePayout)(nil)
var _ sdk.Msg = (*MsgCreateBatchPayout)(nil)
var _ sdk.Msg = (*MsgApprovePayout)(nil)
var _ sdk.Msg = (*MsgMarkPayoutPaid)(nil)
var _ sdk.Msg = (*MsgCancelPayout)(nil)
var _ sdk.Msg = (*MsgFailPayout)(nil)
var _ sdk.Msg = (*MsgUpdateParams)(nil)

// 1. CreatePayout
type MsgCreatePayout struct {
	Initiator        string   `json:"initiator" protobuf:"bytes,1,opt,name=initiator,proto3"`
	PayoutId         string   `json:"payout_id" protobuf:"bytes,2,opt,name=payout_id,json=payoutId,proto3"`
	MerchantId       string   `json:"merchant_id" protobuf:"bytes,3,opt,name=merchant_id,json=merchantId,proto3"`
	RecipientAddress string   `json:"recipient_address" protobuf:"bytes,4,opt,name=recipient_address,json=recipientAddress,proto3"`
	Amount           sdk.Coin `json:"amount" protobuf:"bytes,5,opt,name=amount,proto3"`
	AssetDenom       string   `json:"asset_denom" protobuf:"bytes,6,opt,name=asset_denom,json=assetDenom,proto3"`
	PayoutType       int32    `json:"payout_type" protobuf:"varint,7,opt,name=payout_type,json=payoutType,proto3"`
	PayoutReference  string   `json:"payout_reference" protobuf:"bytes,8,opt,name=payout_reference,json=payoutReference,proto3"`
	Memo             string   `json:"memo" protobuf:"bytes,9,opt,name=memo,proto3"`
}

func NewMsgCreatePayout(initiator, id, merchant, recipient, denom string, amount sdk.Coin, ptype int32, ref, memo string) *MsgCreatePayout {
	return &MsgCreatePayout{initiator, id, merchant, recipient, amount, denom, ptype, ref, memo}
}
func (m *MsgCreatePayout) ProtoMessage()               {}
func (m *MsgCreatePayout) Descriptor() ([]byte, []int) { return common.PayoutDescriptorBytes, []int{2} }
func (m *MsgCreatePayout) Reset()                      { *m = MsgCreatePayout{} }
func (m *MsgCreatePayout) String() string              { return fmt.Sprintf("MsgCreatePayout{%s}", m.PayoutId) }
func (m MsgCreatePayout) Route() string                { return RouterKey }
func (m MsgCreatePayout) Type() string                 { return "create_payout" }
func (m MsgCreatePayout) ValidateBasic() error {
	if _, err := sdk.AccAddressFromBech32(m.Initiator); err != nil {
		return fmt.Errorf("initiator: %w", err)
	}
	if _, err := sdk.AccAddressFromBech32(m.RecipientAddress); err != nil {
		return fmt.Errorf("recipient: %w", err)
	}
	if m.Amount.IsZero() || m.Amount.IsNegative() {
		return fmt.Errorf("amount: %w", ErrAmountNotPositive)
	}
	return nil
}
func (m MsgCreatePayout) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Initiator)
	return []sdk.AccAddress{a}
}
func (m MsgCreatePayout) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

// 2. CreateBatchPayout
type PayoutInput struct {
	PayoutId         string   `json:"payout_id" protobuf:"bytes,1,opt,name=payout_id,json=payoutId,proto3"`
	RecipientAddress string   `json:"recipient_address" protobuf:"bytes,2,opt,name=recipient_address,json=recipientAddress,proto3"`
	Amount           sdk.Coin `json:"amount" protobuf:"bytes,3,opt,name=amount,proto3"`
	AssetDenom       string   `json:"asset_denom" protobuf:"bytes,4,opt,name=asset_denom,json=assetDenom,proto3"`
	PayoutType       int32    `json:"payout_type" protobuf:"varint,5,opt,name=payout_type,json=payoutType,proto3"`
	PayoutReference  string   `json:"payout_reference" protobuf:"bytes,6,opt,name=payout_reference,json=payoutReference,proto3"`
	Memo             string   `json:"memo" protobuf:"bytes,7,opt,name=memo,proto3"`
}
type MsgCreateBatchPayout struct {
	Initiator      string        `json:"initiator" protobuf:"bytes,1,opt,name=initiator,proto3"`
	BatchId        string        `json:"batch_id" protobuf:"bytes,2,opt,name=batch_id,json=batchId,proto3"`
	MerchantId     string        `json:"merchant_id" protobuf:"bytes,3,opt,name=merchant_id,json=merchantId,proto3"`
	Payouts        []PayoutInput `json:"payouts" protobuf:"bytes,4,rep,name=payouts,proto3"`
	BatchReference string        `json:"batch_reference" protobuf:"bytes,5,opt,name=batch_reference,json=batchReference,proto3"`
	Memo           string        `json:"memo" protobuf:"bytes,6,opt,name=memo,proto3"`
}

func NewMsgCreateBatchPayout(initiator, batchID, merchantID string, payouts []PayoutInput, ref, memo string) *MsgCreateBatchPayout {
	return &MsgCreateBatchPayout{initiator, batchID, merchantID, payouts, ref, memo}
}
func (m *MsgCreateBatchPayout) ProtoMessage() {}
func (m *MsgCreateBatchPayout) Descriptor() ([]byte, []int) {
	return common.PayoutDescriptorBytes, []int{3}
}
func (m *MsgCreateBatchPayout) Reset()         { *m = MsgCreateBatchPayout{} }
func (m *MsgCreateBatchPayout) String() string { return fmt.Sprintf("MsgBatchPayout{%s}", m.BatchId) }
func (m MsgCreateBatchPayout) Route() string   { return RouterKey }
func (m MsgCreateBatchPayout) Type() string    { return "create_batch_payout" }
func (m MsgCreateBatchPayout) ValidateBasic() error {
	if _, err := sdk.AccAddressFromBech32(m.Initiator); err != nil {
		return fmt.Errorf("initiator: %w", err)
	}
	if len(m.Payouts) == 0 {
		return fmt.Errorf("empty payouts: %w", ErrInvalidPayoutID)
	}
	return nil
}
func (m MsgCreateBatchPayout) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Initiator)
	return []sdk.AccAddress{a}
}
func (m MsgCreateBatchPayout) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

// 3-6: Single-field messages
type MsgApprovePayout struct {
	Signer   string `json:"signer" protobuf:"bytes,1,opt,name=signer,proto3"`
	PayoutId string `json:"payout_id" protobuf:"bytes,2,opt,name=payout_id,json=payoutId,proto3"`
}

func NewMsgApprovePayout(signer, id string) *MsgApprovePayout { return &MsgApprovePayout{signer, id} }
func (m *MsgApprovePayout) ProtoMessage()                     {}
func (m *MsgApprovePayout) Descriptor() ([]byte, []int) {
	return common.PayoutDescriptorBytes, []int{4}
}
func (m *MsgApprovePayout) Reset()         { *m = MsgApprovePayout{} }
func (m *MsgApprovePayout) String() string { return fmt.Sprintf("MsgApprove{%s}", m.PayoutId) }
func (m MsgApprovePayout) Route() string   { return RouterKey }
func (m MsgApprovePayout) Type() string    { return "approve_payout" }
func (m MsgApprovePayout) ValidateBasic() error {
	_, err := sdk.AccAddressFromBech32(m.Signer)
	return err
}
func (m MsgApprovePayout) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Signer)
	return []sdk.AccAddress{a}
}
func (m MsgApprovePayout) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

type MsgMarkPayoutPaid struct {
	Authority         string `json:"authority" protobuf:"bytes,1,opt,name=authority,proto3"`
	PayoutId          string `json:"payout_id" protobuf:"bytes,2,opt,name=payout_id,json=payoutId,proto3"`
	ExternalReference string `json:"external_reference" protobuf:"bytes,3,opt,name=external_reference,json=externalReference,proto3"`
	Memo              string `json:"memo" protobuf:"bytes,4,opt,name=memo,proto3"`
}

func NewMsgMarkPayoutPaid(authority, id, extRef, memo string) *MsgMarkPayoutPaid {
	return &MsgMarkPayoutPaid{authority, id, extRef, memo}
}
func (m *MsgMarkPayoutPaid) ProtoMessage() {}
func (m *MsgMarkPayoutPaid) Descriptor() ([]byte, []int) {
	return common.PayoutDescriptorBytes, []int{5}
}
func (m *MsgMarkPayoutPaid) Reset()         { *m = MsgMarkPayoutPaid{} }
func (m *MsgMarkPayoutPaid) String() string { return fmt.Sprintf("MsgMarkPaid{%s}", m.PayoutId) }
func (m MsgMarkPayoutPaid) Route() string   { return RouterKey }
func (m MsgMarkPayoutPaid) Type() string    { return "mark_paid" }
func (m MsgMarkPayoutPaid) ValidateBasic() error {
	_, err := sdk.AccAddressFromBech32(m.Authority)
	return err
}
func (m MsgMarkPayoutPaid) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Authority)
	return []sdk.AccAddress{a}
}
func (m MsgMarkPayoutPaid) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

type MsgCancelPayout struct {
	Signer   string `json:"signer" protobuf:"bytes,1,opt,name=signer,proto3"`
	PayoutId string `json:"payout_id" protobuf:"bytes,2,opt,name=payout_id,json=payoutId,proto3"`
	Memo     string `json:"memo" protobuf:"bytes,3,opt,name=memo,proto3"`
}

func NewMsgCancelPayout(signer, id, memo string) *MsgCancelPayout {
	return &MsgCancelPayout{signer, id, memo}
}
func (m *MsgCancelPayout) ProtoMessage()               {}
func (m *MsgCancelPayout) Descriptor() ([]byte, []int) { return common.PayoutDescriptorBytes, []int{6} }
func (m *MsgCancelPayout) Reset()                      { *m = MsgCancelPayout{} }
func (m *MsgCancelPayout) String() string              { return fmt.Sprintf("MsgCancel{%s}", m.PayoutId) }
func (m MsgCancelPayout) Route() string                { return RouterKey }
func (m MsgCancelPayout) Type() string                 { return "cancel_payout" }
func (m MsgCancelPayout) ValidateBasic() error {
	_, err := sdk.AccAddressFromBech32(m.Signer)
	return err
}
func (m MsgCancelPayout) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Signer)
	return []sdk.AccAddress{a}
}
func (m MsgCancelPayout) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

type MsgFailPayout struct {
	Authority     string `json:"authority" protobuf:"bytes,1,opt,name=authority,proto3"`
	PayoutId      string `json:"payout_id" protobuf:"bytes,2,opt,name=payout_id,json=payoutId,proto3"`
	FailureReason string `json:"failure_reason" protobuf:"bytes,3,opt,name=failure_reason,json=failureReason,proto3"`
}

func NewMsgFailPayout(authority, id, reason string) *MsgFailPayout {
	return &MsgFailPayout{authority, id, reason}
}
func (m *MsgFailPayout) ProtoMessage()               {}
func (m *MsgFailPayout) Descriptor() ([]byte, []int) { return common.PayoutDescriptorBytes, []int{7} }
func (m *MsgFailPayout) Reset()                      { *m = MsgFailPayout{} }
func (m *MsgFailPayout) String() string              { return fmt.Sprintf("MsgFail{%s}", m.PayoutId) }
func (m MsgFailPayout) Route() string                { return RouterKey }
func (m MsgFailPayout) Type() string                 { return "fail_payout" }
func (m MsgFailPayout) ValidateBasic() error {
	_, err := sdk.AccAddressFromBech32(m.Authority)
	return err
}
func (m MsgFailPayout) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Authority)
	return []sdk.AccAddress{a}
}
func (m MsgFailPayout) GetSignBytes() []byte { return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m)) }

type MsgUpdateParams struct {
	Authority string `json:"authority" protobuf:"bytes,1,opt,name=authority,proto3"`
	Params    Params `json:"params" protobuf:"bytes,2,opt,name=params,proto3"`
}

func NewMsgUpdateParams(authority string, p Params) *MsgUpdateParams {
	return &MsgUpdateParams{authority, p}
}
func (m *MsgUpdateParams) ProtoMessage() {}

// Descriptor implements the descriptorIface for proto unknown field checking compatibility.
func (m *MsgUpdateParams) Descriptor() ([]byte, []int) { return common.PayoutDescriptorBytes, []int{8} }
func (m *MsgUpdateParams) Reset()                      { *m = MsgUpdateParams{} }
func (m *MsgUpdateParams) String() string              { return fmt.Sprintf("MsgUpdateParams{%s}", m.Authority) }
func (m MsgUpdateParams) Route() string                { return RouterKey }
func (m MsgUpdateParams) Type() string                 { return "update_params" }
func (m MsgUpdateParams) ValidateBasic() error {
	_, err := sdk.AccAddressFromBech32(m.Authority)
	return err
}
func (m MsgUpdateParams) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Authority)
	return []sdk.AccAddress{a}
}
func (m MsgUpdateParams) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

// Responses
type MsgCreatePayoutResponse struct{}
type MsgCreateBatchPayoutResponse struct{}
type MsgApprovePayoutResponse struct{}
type MsgMarkPayoutPaidResponse struct{}
type MsgCancelPayoutResponse struct{}
type MsgFailPayoutResponse struct{}
type MsgUpdateParamsResponse struct{}

func (r *MsgCreatePayoutResponse) ProtoMessage()       {}
func (r *MsgCreatePayoutResponse) Reset()              {}
func (r *MsgCreatePayoutResponse) String() string      { return "MsgCreatePayoutResp{}" }
func (r *MsgCreateBatchPayoutResponse) ProtoMessage()  {}
func (r *MsgCreateBatchPayoutResponse) Reset()         {}
func (r *MsgCreateBatchPayoutResponse) String() string { return "MsgBatchPayoutResp{}" }
func (r *MsgApprovePayoutResponse) ProtoMessage()      {}
func (r *MsgApprovePayoutResponse) Reset()             {}
func (r *MsgApprovePayoutResponse) String() string     { return "MsgApproveResp{}" }
func (r *MsgMarkPayoutPaidResponse) ProtoMessage()     {}
func (r *MsgMarkPayoutPaidResponse) Reset()            {}
func (r *MsgMarkPayoutPaidResponse) String() string    { return "MsgMarkPaidResp{}" }
func (r *MsgCancelPayoutResponse) ProtoMessage()       {}
func (r *MsgCancelPayoutResponse) Reset()              {}
func (r *MsgCancelPayoutResponse) String() string      { return "MsgCancelResp{}" }
func (r *MsgFailPayoutResponse) ProtoMessage()         {}
func (r *MsgFailPayoutResponse) Reset()                {}
func (r *MsgFailPayoutResponse) String() string        { return "MsgFailResp{}" }
func (r *MsgUpdateParamsResponse) ProtoMessage()       {}
func (r *MsgUpdateParamsResponse) Reset()              {}
func (r *MsgUpdateParamsResponse) String() string      { return "MsgUpdateParamsResp{}" }
