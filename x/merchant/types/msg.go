package types

import (
	"fmt"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

var (
	_ sdk.Msg = (*MsgRegisterMerchant)(nil)
	_ sdk.Msg = (*MsgUpdateMerchant)(nil)
)

// --- MsgRegisterMerchant ---

type MsgRegisterMerchant struct {
	Owner       string `json:"owner" yaml:"owner"`
	Name        string `json:"name" yaml:"name"`
	Description string `json:"description" yaml:"description"`
	Website     string `json:"website" yaml:"website"`
}

func NewMsgRegisterMerchant(owner sdk.AccAddress, name, description, website string) *MsgRegisterMerchant {
	return &MsgRegisterMerchant{
		Owner:       owner.String(),
		Name:        name,
		Description: description,
		Website:     website,
	}
}

func (msg *MsgRegisterMerchant) ProtoMessage() {}
func (msg *MsgRegisterMerchant) Reset()        { *msg = MsgRegisterMerchant{} }
func (msg *MsgRegisterMerchant) String() string {
	return fmt.Sprintf("MsgRegisterMerchant{%s}", msg.Owner)
}

func (msg MsgRegisterMerchant) Route() string { return RouterKey }
func (msg MsgRegisterMerchant) Type() string  { return "register_merchant" }

func (msg MsgRegisterMerchant) ValidateBasic() error {
	if _, err := sdk.AccAddressFromBech32(msg.Owner); err != nil {
		return fmt.Errorf("invalid owner: %w", err)
	}
	if len(msg.Name) == 0 {
		return fmt.Errorf("name is required")
	}
	return nil
}

func (msg MsgRegisterMerchant) GetSigners() []sdk.AccAddress {
	addr, _ := sdk.AccAddressFromBech32(msg.Owner)
	return []sdk.AccAddress{addr}
}

func (msg MsgRegisterMerchant) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&msg))
}

// --- MsgUpdateMerchant ---

type MsgUpdateMerchant struct {
	Owner       string `json:"owner" yaml:"owner"`
	Name        string `json:"name" yaml:"name"`
	Description string `json:"description" yaml:"description"`
	Website     string `json:"website" yaml:"website"`
}

func NewMsgUpdateMerchant(owner sdk.AccAddress, name, description, website string) *MsgUpdateMerchant {
	return &MsgUpdateMerchant{
		Owner:       owner.String(),
		Name:        name,
		Description: description,
		Website:     website,
	}
}

func (msg *MsgUpdateMerchant) ProtoMessage()  {}
func (msg *MsgUpdateMerchant) Reset()         { *msg = MsgUpdateMerchant{} }
func (msg *MsgUpdateMerchant) String() string { return fmt.Sprintf("MsgUpdateMerchant{%s}", msg.Owner) }

func (msg MsgUpdateMerchant) Route() string { return RouterKey }
func (msg MsgUpdateMerchant) Type() string  { return "update_merchant" }

func (msg MsgUpdateMerchant) ValidateBasic() error {
	if _, err := sdk.AccAddressFromBech32(msg.Owner); err != nil {
		return fmt.Errorf("invalid owner: %w", err)
	}
	return nil
}

func (msg MsgUpdateMerchant) GetSigners() []sdk.AccAddress {
	addr, _ := sdk.AccAddressFromBech32(msg.Owner)
	return []sdk.AccAddress{addr}
}

func (msg MsgUpdateMerchant) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&msg))
}

// --- Responses ---

type MsgRegisterMerchantResponse struct{}
type MsgUpdateMerchantResponse struct{}

func (r *MsgRegisterMerchantResponse) ProtoMessage()  {}
func (r *MsgRegisterMerchantResponse) Reset()         {}
func (r *MsgRegisterMerchantResponse) String() string { return "MsgRegisterMerchantResponse{}" }

func (r *MsgUpdateMerchantResponse) ProtoMessage()  {}
func (r *MsgUpdateMerchantResponse) Reset()         {}
func (r *MsgUpdateMerchantResponse) String() string { return "MsgUpdateMerchantResponse{}" }

// --- MsgUpdateParams (authority-only) ---

type MsgUpdateParams struct {
	Authority string `json:"authority" yaml:"authority"`
	Params    Params `json:"params" yaml:"params"`
}

var _ sdk.Msg = (*MsgUpdateParams)(nil)

func NewMsgUpdateParams(authority string, params Params) *MsgUpdateParams {
	return &MsgUpdateParams{Authority: authority, Params: params}
}

func (msg *MsgUpdateParams) ProtoMessage()  {}
func (msg *MsgUpdateParams) Reset()         { *msg = MsgUpdateParams{} }
func (msg *MsgUpdateParams) String() string { return fmt.Sprintf("MsgUpdateParams{%s}", msg.Authority) }
func (msg MsgUpdateParams) Route() string   { return RouterKey }
func (msg MsgUpdateParams) Type() string    { return "update_params" }
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

type MsgUpdateParamsResponse struct{}

func (r *MsgUpdateParamsResponse) ProtoMessage()  {}
func (r *MsgUpdateParamsResponse) Reset()         {}
func (r *MsgUpdateParamsResponse) String() string { return "MsgUpdateParamsResponse{}" }

// --- MsgSetMerchantStatus (authority-only) ---

type MsgSetMerchantStatus struct {
	Authority string `json:"authority" yaml:"authority"`
	Owner     string `json:"owner" yaml:"owner"`
	Status    int32  `json:"status" yaml:"status"`
}

var _ sdk.Msg = (*MsgSetMerchantStatus)(nil)

func NewMsgSetMerchantStatus(authority, owner string, status int32) *MsgSetMerchantStatus {
	return &MsgSetMerchantStatus{Authority: authority, Owner: owner, Status: status}
}

func (msg *MsgSetMerchantStatus) ProtoMessage() {}
func (msg *MsgSetMerchantStatus) Reset()        { *msg = MsgSetMerchantStatus{} }
func (msg *MsgSetMerchantStatus) String() string {
	return fmt.Sprintf("MsgSetMerchantStatus{%s->%d}", msg.Owner, msg.Status)
}
func (msg MsgSetMerchantStatus) Route() string { return RouterKey }
func (msg MsgSetMerchantStatus) Type() string  { return "set_merchant_status" }
func (msg MsgSetMerchantStatus) ValidateBasic() error {
	if _, err := sdk.AccAddressFromBech32(msg.Authority); err != nil {
		return fmt.Errorf("invalid authority: %w", err)
	}
	if _, err := sdk.AccAddressFromBech32(msg.Owner); err != nil {
		return fmt.Errorf("invalid owner: %w", err)
	}
	if msg.Status < 0 || msg.Status > 2 {
		return fmt.Errorf("invalid status: %d", msg.Status)
	}
	return nil
}
func (msg MsgSetMerchantStatus) GetSigners() []sdk.AccAddress {
	addr, _ := sdk.AccAddressFromBech32(msg.Authority)
	return []sdk.AccAddress{addr}
}
func (msg MsgSetMerchantStatus) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&msg))
}

type MsgSetMerchantStatusResponse struct{}

func (r *MsgSetMerchantStatusResponse) ProtoMessage()  {}
func (r *MsgSetMerchantStatusResponse) Reset()         {}
func (r *MsgSetMerchantStatusResponse) String() string { return "MsgSetMerchantStatusResponse{}" }

// --- MsgSetVerificationStatus (authority-only) ---

type MsgSetVerificationStatus struct {
	Authority string `json:"authority" yaml:"authority"`
	Owner     string `json:"owner" yaml:"owner"`
	Status    int32  `json:"status" yaml:"status"`
}

var _ sdk.Msg = (*MsgSetVerificationStatus)(nil)

func NewMsgSetVerificationStatus(authority, owner string, status int32) *MsgSetVerificationStatus {
	return &MsgSetVerificationStatus{Authority: authority, Owner: owner, Status: status}
}

func (msg *MsgSetVerificationStatus) ProtoMessage() {}
func (msg *MsgSetVerificationStatus) Reset()        { *msg = MsgSetVerificationStatus{} }
func (msg *MsgSetVerificationStatus) String() string {
	return fmt.Sprintf("MsgSetVerificationStatus{%s->%d}", msg.Owner, msg.Status)
}
func (msg MsgSetVerificationStatus) Route() string { return RouterKey }
func (msg MsgSetVerificationStatus) Type() string  { return "set_verification_status" }
func (msg MsgSetVerificationStatus) ValidateBasic() error {
	if _, err := sdk.AccAddressFromBech32(msg.Authority); err != nil {
		return fmt.Errorf("invalid authority: %w", err)
	}
	if _, err := sdk.AccAddressFromBech32(msg.Owner); err != nil {
		return fmt.Errorf("invalid owner: %w", err)
	}
	if msg.Status < 0 || msg.Status > 2 {
		return fmt.Errorf("invalid verification status: %d", msg.Status)
	}
	return nil
}
func (msg MsgSetVerificationStatus) GetSigners() []sdk.AccAddress {
	addr, _ := sdk.AccAddressFromBech32(msg.Authority)
	return []sdk.AccAddress{addr}
}
func (msg MsgSetVerificationStatus) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&msg))
}

type MsgSetVerificationStatusResponse struct{}

func (r *MsgSetVerificationStatusResponse) ProtoMessage() {}
func (r *MsgSetVerificationStatusResponse) Reset()        {}
func (r *MsgSetVerificationStatusResponse) String() string {
	return "MsgSetVerificationStatusResponse{}"
}

// --- MsgSetRebateTier (authority-only) ---

type MsgSetRebateTier struct {
	Authority string `json:"authority" yaml:"authority"`
	Owner     string `json:"owner" yaml:"owner"`
	Tier      int32  `json:"tier" yaml:"tier"`
}

var _ sdk.Msg = (*MsgSetRebateTier)(nil)

func NewMsgSetRebateTier(authority, owner string, tier int32) *MsgSetRebateTier {
	return &MsgSetRebateTier{Authority: authority, Owner: owner, Tier: tier}
}

func (msg *MsgSetRebateTier) ProtoMessage() {}
func (msg *MsgSetRebateTier) Reset()        { *msg = MsgSetRebateTier{} }
func (msg *MsgSetRebateTier) String() string {
	return fmt.Sprintf("MsgSetRebateTier{%s->%d}", msg.Owner, msg.Tier)
}
func (msg MsgSetRebateTier) Route() string { return RouterKey }
func (msg MsgSetRebateTier) Type() string  { return "set_rebate_tier" }
func (msg MsgSetRebateTier) ValidateBasic() error {
	if _, err := sdk.AccAddressFromBech32(msg.Authority); err != nil {
		return fmt.Errorf("invalid authority: %w", err)
	}
	if _, err := sdk.AccAddressFromBech32(msg.Owner); err != nil {
		return fmt.Errorf("invalid owner: %w", err)
	}
	if msg.Tier < 0 || msg.Tier > 4 {
		return fmt.Errorf("invalid rebate tier: %d", msg.Tier)
	}
	return nil
}
func (msg MsgSetRebateTier) GetSigners() []sdk.AccAddress {
	addr, _ := sdk.AccAddressFromBech32(msg.Authority)
	return []sdk.AccAddress{addr}
}
func (msg MsgSetRebateTier) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&msg))
}

type MsgSetRebateTierResponse struct{}

func (r *MsgSetRebateTierResponse) ProtoMessage()  {}
func (r *MsgSetRebateTierResponse) Reset()         {}
func (r *MsgSetRebateTierResponse) String() string { return "MsgSetRebateTierResponse{}" }
