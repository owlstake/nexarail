package types

import (
	"fmt"

	"github.com/nexarail/chain/x/common"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

// Verify interface compliance.
var (
	_ sdk.Msg = (*MsgUpdateParams)(nil)
)

// MsgUpdateParams is the message for updating the fees module parameters.
type MsgUpdateParams struct {
	Authority string `json:"authority" yaml:"authority" protobuf:"bytes,1,opt,name=authority,proto3"`
	Params    Params `json:"params" yaml:"params" protobuf:"bytes,2,opt,name=params,proto3"`
}

// NewMsgUpdateParams creates a new MsgUpdateParams.
func NewMsgUpdateParams(authority string, params Params) *MsgUpdateParams {
	return &MsgUpdateParams{
		Authority: authority,
		Params:    params,
	}
}

// proto.Message interface
func (msg *MsgUpdateParams) ProtoMessage()               {}
func (msg *MsgUpdateParams) Descriptor() ([]byte, []int) { return common.FeesDescriptorBytes, []int{1} }
func (msg *MsgUpdateParams) Reset()                      { *msg = MsgUpdateParams{} }
func (msg *MsgUpdateParams) String() string              { return fmt.Sprintf("MsgUpdateParams{%s}", msg.Authority) }

// Route implements sdk.Msg.
func (msg MsgUpdateParams) Route() string { return RouterKey }

// Type implements sdk.Msg.
func (msg MsgUpdateParams) Type() string { return "update_params" }

// ValidateBasic implements sdk.Msg.
func (msg MsgUpdateParams) ValidateBasic() error {
	if _, err := sdk.AccAddressFromBech32(msg.Authority); err != nil {
		return fmt.Errorf("invalid authority: %w", err)
	}
	if err := msg.Params.Validate(); err != nil {
		return fmt.Errorf("invalid params: %w", err)
	}
	return nil
}

// GetSigners implements sdk.Msg.
func (msg MsgUpdateParams) GetSigners() []sdk.AccAddress {
	addr, _ := sdk.AccAddressFromBech32(msg.Authority)
	return []sdk.AccAddress{addr}
}

// GetSignBytes implements sdk.Msg.
func (msg MsgUpdateParams) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&msg))
}

// MsgUpdateParamsResponse is the response to MsgUpdateParams.
type MsgUpdateParamsResponse struct{}

func (r *MsgUpdateParamsResponse) Reset()         {}
func (r *MsgUpdateParamsResponse) String() string { return "MsgUpdateParamsResponse{}" }
func (r *MsgUpdateParamsResponse) ProtoMessage()  {}
