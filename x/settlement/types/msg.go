package types

import (
	"fmt"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

// --- Compile-time interface checks ---
var (
	_ sdk.Msg = (*MsgCreateSettlement)(nil)
	_ sdk.Msg = (*MsgUpdateSettlementStatus)(nil)
	_ sdk.Msg = (*MsgUpdateParams)(nil)
)

// --- MsgCreateSettlement ---

type MsgCreateSettlement struct {
	Payer         string   `json:"payer" yaml:"payer"`
	MerchantOwner string   `json:"merchant_owner" yaml:"merchant_owner"`
	Amount        sdk.Coin `json:"amount" yaml:"amount"`
	Metadata      string   `json:"metadata" yaml:"metadata"`
}

func NewMsgCreateSettlement(payer, merchantOwner string, amount sdk.Coin, metadata string) *MsgCreateSettlement {
	return &MsgCreateSettlement{
		Payer:         payer,
		MerchantOwner: merchantOwner,
		Amount:        amount,
		Metadata:      metadata,
	}
}

func (msg *MsgCreateSettlement) ProtoMessage() {}
func (msg *MsgCreateSettlement) Reset()        { *msg = MsgCreateSettlement{} }
func (msg *MsgCreateSettlement) String() string {
	return fmt.Sprintf("MsgCreateSettlement{%s->%s, %s}", msg.Payer, msg.MerchantOwner, msg.Amount)
}
func (msg MsgCreateSettlement) Route() string { return RouterKey }
func (msg MsgCreateSettlement) Type() string  { return "create_settlement" }
func (msg MsgCreateSettlement) ValidateBasic() error {
	if _, err := sdk.AccAddressFromBech32(msg.Payer); err != nil {
		return fmt.Errorf("payer: %w", ErrInvalidPayer)
	}
	if _, err := sdk.AccAddressFromBech32(msg.MerchantOwner); err != nil {
		return fmt.Errorf("merchant: %w", ErrInvalidMerchant)
	}
	if msg.Amount.IsZero() || msg.Amount.IsNegative() {
		return fmt.Errorf("amount: %w", ErrAmountNotPositive)
	}
	return nil
}
func (msg MsgCreateSettlement) GetSigners() []sdk.AccAddress {
	addr, _ := sdk.AccAddressFromBech32(msg.Payer)
	return []sdk.AccAddress{addr}
}
func (msg MsgCreateSettlement) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&msg))
}

// --- MsgUpdateSettlementStatus (authority-only) ---

type MsgUpdateSettlementStatus struct {
	Authority string `json:"authority" yaml:"authority"`
	Id        uint64 `json:"id" yaml:"id"`
	Status    int32  `json:"status" yaml:"status"`
}

func NewMsgUpdateSettlementStatus(authority string, id uint64, status int32) *MsgUpdateSettlementStatus {
	return &MsgUpdateSettlementStatus{Authority: authority, Id: id, Status: status}
}

func (msg *MsgUpdateSettlementStatus) ProtoMessage() {}
func (msg *MsgUpdateSettlementStatus) Reset()        { *msg = MsgUpdateSettlementStatus{} }
func (msg *MsgUpdateSettlementStatus) String() string {
	return fmt.Sprintf("MsgUpdateSettlementStatus{id=%d, status=%d}", msg.Id, msg.Status)
}
func (msg MsgUpdateSettlementStatus) Route() string { return RouterKey }
func (msg MsgUpdateSettlementStatus) Type() string  { return "update_settlement_status" }
func (msg MsgUpdateSettlementStatus) ValidateBasic() error {
	if _, err := sdk.AccAddressFromBech32(msg.Authority); err != nil {
		return fmt.Errorf("invalid authority: %w", err)
	}
	if msg.Status < 0 || msg.Status > 3 {
		return fmt.Errorf("status %d: %w", msg.Status, ErrInvalidStatus)
	}
	return nil
}
func (msg MsgUpdateSettlementStatus) GetSigners() []sdk.AccAddress {
	addr, _ := sdk.AccAddressFromBech32(msg.Authority)
	return []sdk.AccAddress{addr}
}
func (msg MsgUpdateSettlementStatus) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&msg))
}

// --- MsgUpdateParams (authority-only) ---

type MsgUpdateParams struct {
	Authority string `json:"authority" yaml:"authority"`
	Params    Params `json:"params" yaml:"params"`
}

func NewMsgUpdateParams(authority string, params Params) *MsgUpdateParams {
	return &MsgUpdateParams{Authority: authority, Params: params}
}

func (msg *MsgUpdateParams) ProtoMessage() {}
func (msg *MsgUpdateParams) Reset()        { *msg = MsgUpdateParams{} }
func (msg *MsgUpdateParams) String() string {
	return fmt.Sprintf("MsgUpdateParams{authority=%s}", msg.Authority)
}
func (msg MsgUpdateParams) Route() string { return RouterKey }
func (msg MsgUpdateParams) Type() string  { return "update_params" }
func (msg MsgUpdateParams) ValidateBasic() error {
	if _, err := sdk.AccAddressFromBech32(msg.Authority); err != nil {
		return fmt.Errorf("invalid authority: %w", err)
	}
	return msg.Params.Validate()
}
func (msg MsgUpdateParams) GetSigners() []sdk.AccAddress {
	addr, _ := sdk.AccAddressFromBech32(msg.Authority)
	return []sdk.AccAddress{addr}
}
func (msg MsgUpdateParams) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&msg))
}

// --- Responses ---

type MsgCreateSettlementResponse struct {
	Id uint64 `json:"id" yaml:"id"`
}

func (r *MsgCreateSettlementResponse) ProtoMessage() {}
func (r *MsgCreateSettlementResponse) Reset()        {}
func (r *MsgCreateSettlementResponse) String() string {
	return fmt.Sprintf("MsgCreateSettlementResponse{id=%d}", r.Id)
}

type MsgUpdateSettlementStatusResponse struct{}

func (r *MsgUpdateSettlementStatusResponse) ProtoMessage() {}
func (r *MsgUpdateSettlementStatusResponse) Reset()        {}
func (r *MsgUpdateSettlementStatusResponse) String() string {
	return "MsgUpdateSettlementStatusResponse{}"
}

type MsgUpdateParamsResponse struct{}

func (r *MsgUpdateParamsResponse) ProtoMessage()  {}
func (r *MsgUpdateParamsResponse) Reset()         {}
func (r *MsgUpdateParamsResponse) String() string { return "MsgUpdateParamsResponse{}" }
