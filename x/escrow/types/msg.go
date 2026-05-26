package types

import (
	"fmt"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

var (
	_ sdk.Msg = (*MsgCreateEscrow)(nil)
	_ sdk.Msg = (*MsgReleaseEscrow)(nil)
	_ sdk.Msg = (*MsgRefundEscrow)(nil)
	_ sdk.Msg = (*MsgOpenDispute)(nil)
	_ sdk.Msg = (*MsgResolveDispute)(nil)
	_ sdk.Msg = (*MsgCancelEscrow)(nil)
	_ sdk.Msg = (*MsgUpdateParams)(nil)
)

// --- MsgCreateEscrow ---

type MsgCreateEscrow struct {
	Buyer            string   `json:"buyer" yaml:"buyer"`
	EscrowId         string   `json:"escrow_id" yaml:"escrow_id"`
	SellerAddress    string   `json:"seller_address" yaml:"seller_address"`
	MerchantId       string   `json:"merchant_id" yaml:"merchant_id"`
	AssetDenom       string   `json:"asset_denom" yaml:"asset_denom"`
	Amount           sdk.Coin `json:"amount" yaml:"amount"`
	PaymentReference string   `json:"payment_reference" yaml:"payment_reference"`
	Memo             string   `json:"memo" yaml:"memo"`
	ExpiresAt        int64    `json:"expires_at" yaml:"expires_at"`
}

func NewMsgCreateEscrow(buyer, escrowID, seller, merchantID, denom string, amount sdk.Coin, ref, memo string, expires int64) *MsgCreateEscrow {
	return &MsgCreateEscrow{Buyer: buyer, EscrowId: escrowID, SellerAddress: seller, MerchantId: merchantID, AssetDenom: denom, Amount: amount, PaymentReference: ref, Memo: memo, ExpiresAt: expires}
}
func (m *MsgCreateEscrow) ProtoMessage()  {}
func (m *MsgCreateEscrow) Reset()         { *m = MsgCreateEscrow{} }
func (m *MsgCreateEscrow) String() string { return fmt.Sprintf("MsgCreateEscrow{%s}", m.EscrowId) }
func (m MsgCreateEscrow) Route() string   { return RouterKey }
func (m MsgCreateEscrow) Type() string    { return "create_escrow" }
func (m MsgCreateEscrow) ValidateBasic() error {
	if _, err := sdk.AccAddressFromBech32(m.Buyer); err != nil {
		return fmt.Errorf("buyer: %w", err)
	}
	if _, err := sdk.AccAddressFromBech32(m.SellerAddress); err != nil {
		return fmt.Errorf("seller: %w", err)
	}
	if m.Buyer == m.SellerAddress {
		return fmt.Errorf("buyer and seller must differ: %w", ErrInvalidBuyer)
	}
	if m.Amount.IsZero() || m.Amount.IsNegative() {
		return fmt.Errorf("amount: %w", ErrAmountNotPositive)
	}
	return nil
}
func (m MsgCreateEscrow) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Buyer)
	return []sdk.AccAddress{a}
}
func (m MsgCreateEscrow) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

// --- MsgReleaseEscrow ---

type MsgReleaseEscrow struct {
	Signer           string `json:"signer" yaml:"signer"`
	EscrowId         string `json:"escrow_id" yaml:"escrow_id"`
	ReleaseReference string `json:"release_reference" yaml:"release_reference"`
	Memo             string `json:"memo" yaml:"memo"`
}

func NewMsgReleaseEscrow(signer, escrowID, ref, memo string) *MsgReleaseEscrow {
	return &MsgReleaseEscrow{Signer: signer, EscrowId: escrowID, ReleaseReference: ref, Memo: memo}
}
func (m *MsgReleaseEscrow) ProtoMessage()  {}
func (m *MsgReleaseEscrow) Reset()         { *m = MsgReleaseEscrow{} }
func (m *MsgReleaseEscrow) String() string { return fmt.Sprintf("MsgReleaseEscrow{%s}", m.EscrowId) }
func (m MsgReleaseEscrow) Route() string   { return RouterKey }
func (m MsgReleaseEscrow) Type() string    { return "release_escrow" }
func (m MsgReleaseEscrow) ValidateBasic() error {
	if _, err := sdk.AccAddressFromBech32(m.Signer); err != nil {
		return fmt.Errorf("signer: %w", err)
	}
	return nil
}
func (m MsgReleaseEscrow) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Signer)
	return []sdk.AccAddress{a}
}
func (m MsgReleaseEscrow) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

// --- MsgRefundEscrow ---

type MsgRefundEscrow struct {
	Signer          string `json:"signer" yaml:"signer"`
	EscrowId        string `json:"escrow_id" yaml:"escrow_id"`
	RefundReference string `json:"refund_reference" yaml:"refund_reference"`
	Memo            string `json:"memo" yaml:"memo"`
}

func NewMsgRefundEscrow(signer, escrowID, ref, memo string) *MsgRefundEscrow {
	return &MsgRefundEscrow{Signer: signer, EscrowId: escrowID, RefundReference: ref, Memo: memo}
}
func (m *MsgRefundEscrow) ProtoMessage()  {}
func (m *MsgRefundEscrow) Reset()         { *m = MsgRefundEscrow{} }
func (m *MsgRefundEscrow) String() string { return fmt.Sprintf("MsgRefundEscrow{%s}", m.EscrowId) }
func (m MsgRefundEscrow) Route() string   { return RouterKey }
func (m MsgRefundEscrow) Type() string    { return "refund_escrow" }
func (m MsgRefundEscrow) ValidateBasic() error {
	if _, err := sdk.AccAddressFromBech32(m.Signer); err != nil {
		return fmt.Errorf("signer: %w", err)
	}
	return nil
}
func (m MsgRefundEscrow) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Signer)
	return []sdk.AccAddress{a}
}
func (m MsgRefundEscrow) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

// --- MsgOpenDispute ---

type MsgOpenDispute struct {
	Signer        string `json:"signer" yaml:"signer"`
	EscrowId      string `json:"escrow_id" yaml:"escrow_id"`
	DisputeReason string `json:"dispute_reason" yaml:"dispute_reason"`
}

func NewMsgOpenDispute(signer, escrowID, reason string) *MsgOpenDispute {
	return &MsgOpenDispute{Signer: signer, EscrowId: escrowID, DisputeReason: reason}
}
func (m *MsgOpenDispute) ProtoMessage()  {}
func (m *MsgOpenDispute) Reset()         { *m = MsgOpenDispute{} }
func (m *MsgOpenDispute) String() string { return fmt.Sprintf("MsgOpenDispute{%s}", m.EscrowId) }
func (m MsgOpenDispute) Route() string   { return RouterKey }
func (m MsgOpenDispute) Type() string    { return "open_dispute" }
func (m MsgOpenDispute) ValidateBasic() error {
	if _, err := sdk.AccAddressFromBech32(m.Signer); err != nil {
		return fmt.Errorf("signer: %w", err)
	}
	return nil
}
func (m MsgOpenDispute) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Signer)
	return []sdk.AccAddress{a}
}
func (m MsgOpenDispute) GetSignBytes() []byte { return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m)) }

// --- MsgResolveDispute ---

type MsgResolveDispute struct {
	Authority      string `json:"authority" yaml:"authority"`
	EscrowId       string `json:"escrow_id" yaml:"escrow_id"`
	DisputeStatus  int32  `json:"dispute_status" yaml:"dispute_status"`
	ResolutionNote string `json:"resolution_note" yaml:"resolution_note"`
}

func NewMsgResolveDispute(authority, escrowID string, dStatus int32, note string) *MsgResolveDispute {
	return &MsgResolveDispute{Authority: authority, EscrowId: escrowID, DisputeStatus: dStatus, ResolutionNote: note}
}
func (m *MsgResolveDispute) ProtoMessage()  {}
func (m *MsgResolveDispute) Reset()         { *m = MsgResolveDispute{} }
func (m *MsgResolveDispute) String() string { return fmt.Sprintf("MsgResolveDispute{%s}", m.EscrowId) }
func (m MsgResolveDispute) Route() string   { return RouterKey }
func (m MsgResolveDispute) Type() string    { return "resolve_dispute" }
func (m MsgResolveDispute) ValidateBasic() error {
	if _, err := sdk.AccAddressFromBech32(m.Authority); err != nil {
		return fmt.Errorf("authority: %w", err)
	}
	if !validDisputeStatuses[m.DisputeStatus] || m.DisputeStatus < 3 || m.DisputeStatus > 6 {
		return fmt.Errorf("dispute_status must be buyer_wins(3), seller_wins(4), settled(5), or rejected(6): %w", ErrInvalidDisputeStatus)
	}
	return nil
}
func (m MsgResolveDispute) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Authority)
	return []sdk.AccAddress{a}
}
func (m MsgResolveDispute) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

// --- MsgCancelEscrow ---

type MsgCancelEscrow struct {
	Signer   string `json:"signer" yaml:"signer"`
	EscrowId string `json:"escrow_id" yaml:"escrow_id"`
	Memo     string `json:"memo" yaml:"memo"`
}

func NewMsgCancelEscrow(signer, escrowID, memo string) *MsgCancelEscrow {
	return &MsgCancelEscrow{Signer: signer, EscrowId: escrowID, Memo: memo}
}
func (m *MsgCancelEscrow) ProtoMessage()  {}
func (m *MsgCancelEscrow) Reset()         { *m = MsgCancelEscrow{} }
func (m *MsgCancelEscrow) String() string { return fmt.Sprintf("MsgCancelEscrow{%s}", m.EscrowId) }
func (m MsgCancelEscrow) Route() string   { return RouterKey }
func (m MsgCancelEscrow) Type() string    { return "cancel_escrow" }
func (m MsgCancelEscrow) ValidateBasic() error {
	if _, err := sdk.AccAddressFromBech32(m.Signer); err != nil {
		return fmt.Errorf("signer: %w", err)
	}
	return nil
}
func (m MsgCancelEscrow) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Signer)
	return []sdk.AccAddress{a}
}
func (m MsgCancelEscrow) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

// --- MsgUpdateParams ---

type MsgUpdateParams struct {
	Authority string `json:"authority" yaml:"authority"`
	Params    Params `json:"params" yaml:"params"`
}

func NewMsgUpdateParams(authority string, p Params) *MsgUpdateParams {
	return &MsgUpdateParams{Authority: authority, Params: p}
}
func (m *MsgUpdateParams) ProtoMessage()  {}
func (m *MsgUpdateParams) Reset()         { *m = MsgUpdateParams{} }
func (m *MsgUpdateParams) String() string { return fmt.Sprintf("MsgUpdateParams{%s}", m.Authority) }
func (m MsgUpdateParams) Route() string   { return RouterKey }
func (m MsgUpdateParams) Type() string    { return "update_params" }
func (m MsgUpdateParams) ValidateBasic() error {
	if _, err := sdk.AccAddressFromBech32(m.Authority); err != nil {
		return fmt.Errorf("authority: %w", err)
	}
	return m.Params.Validate()
}
func (m MsgUpdateParams) GetSigners() []sdk.AccAddress {
	a, _ := sdk.AccAddressFromBech32(m.Authority)
	return []sdk.AccAddress{a}
}
func (m MsgUpdateParams) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&m))
}

// --- Responses ---

type MsgCreateEscrowResponse struct{}
type MsgReleaseEscrowResponse struct{}
type MsgRefundEscrowResponse struct{}
type MsgOpenDisputeResponse struct{}
type MsgResolveDisputeResponse struct{}
type MsgCancelEscrowResponse struct{}
type MsgUpdateParamsResponse struct{}

func (r *MsgCreateEscrowResponse) ProtoMessage()    {}
func (r *MsgCreateEscrowResponse) Reset()           {}
func (r *MsgCreateEscrowResponse) String() string   { return "MsgCreateEscrowResponse{}" }
func (r *MsgReleaseEscrowResponse) ProtoMessage()   {}
func (r *MsgReleaseEscrowResponse) Reset()          {}
func (r *MsgReleaseEscrowResponse) String() string  { return "MsgReleaseEscrowResponse{}" }
func (r *MsgRefundEscrowResponse) ProtoMessage()    {}
func (r *MsgRefundEscrowResponse) Reset()           {}
func (r *MsgRefundEscrowResponse) String() string   { return "MsgRefundEscrowResponse{}" }
func (r *MsgOpenDisputeResponse) ProtoMessage()     {}
func (r *MsgOpenDisputeResponse) Reset()            {}
func (r *MsgOpenDisputeResponse) String() string    { return "MsgOpenDisputeResponse{}" }
func (r *MsgResolveDisputeResponse) ProtoMessage()  {}
func (r *MsgResolveDisputeResponse) Reset()         {}
func (r *MsgResolveDisputeResponse) String() string { return "MsgResolveDisputeResponse{}" }
func (r *MsgCancelEscrowResponse) ProtoMessage()    {}
func (r *MsgCancelEscrowResponse) Reset()           {}
func (r *MsgCancelEscrowResponse) String() string   { return "MsgCancelEscrowResponse{}" }
func (r *MsgUpdateParamsResponse) ProtoMessage()    {}
func (r *MsgUpdateParamsResponse) Reset()           {}
func (r *MsgUpdateParamsResponse) String() string   { return "MsgUpdateParamsResponse{}" }
