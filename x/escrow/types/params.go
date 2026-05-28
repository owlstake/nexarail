package types

import (
	"fmt"

	"github.com/nexarail/chain/x/common"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

const (
	DefaultMaxReferenceLength      = 120
	DefaultMaxMemoLength           = 280
	DefaultMaxDisputeReasonLength  = 1000
	DefaultMaxResolutionNoteLength = 1000
	DefaultExpirySeconds           = 2592000 // 30 days
)

var DefaultMinEscrowAmount = sdk.NewInt64Coin("unxrl", 1)

type Params struct {
	EscrowsEnabled          bool     `json:"escrows_enabled" yaml:"escrows_enabled" protobuf:"varint,1,opt,name=escrows_enabled,json=escrowsEnabled,proto3"`
	LiveEnabled             bool     `json:"live_enabled" yaml:"live_enabled" protobuf:"varint,2,opt,name=live_enabled,json=liveEnabled,proto3"`
	MaxReferenceLength      uint32   `json:"max_reference_length" yaml:"max_reference_length" protobuf:"varint,3,opt,name=max_reference_length,json=maxReferenceLength,proto3"`
	MaxMemoLength           uint32   `json:"max_memo_length" yaml:"max_memo_length" protobuf:"varint,4,opt,name=max_memo_length,json=maxMemoLength,proto3"`
	MaxDisputeReasonLength  uint32   `json:"max_dispute_reason_length" yaml:"max_dispute_reason_length" protobuf:"varint,5,opt,name=max_dispute_reason_length,json=maxDisputeReasonLength,proto3"`
	MaxResolutionNoteLength uint32   `json:"max_resolution_note_length" yaml:"max_resolution_note_length" protobuf:"varint,6,opt,name=max_resolution_note_length,json=maxResolutionNoteLength,proto3"`
	MinEscrowAmount         sdk.Coin `json:"min_escrow_amount" yaml:"min_escrow_amount" protobuf:"bytes,7,opt,name=min_escrow_amount,json=minEscrowAmount,proto3"`
	DefaultExpirySeconds    uint64   `json:"default_expiry_seconds" yaml:"default_expiry_seconds" protobuf:"varint,8,opt,name=default_expiry_seconds,json=defaultExpirySeconds,proto3"`
}

func DefaultParams() Params {
	return Params{
		EscrowsEnabled:          true,
		LiveEnabled:             false,
		MaxReferenceLength:      DefaultMaxReferenceLength,
		MaxMemoLength:           DefaultMaxMemoLength,
		MaxDisputeReasonLength:  DefaultMaxDisputeReasonLength,
		MaxResolutionNoteLength: DefaultMaxResolutionNoteLength,
		MinEscrowAmount:         DefaultMinEscrowAmount,
		DefaultExpirySeconds:    DefaultExpirySeconds,
	}
}

func (p *Params) ProtoMessage()               {}
func (p *Params) Descriptor() ([]byte, []int) { return common.EscrowDescriptorBytes, []int{0} }
func (p *Params) Reset()                      { *p = Params{} }
func (p *Params) String() string              { return "EscrowParams{}" }

func (p Params) Validate() error {
	if p.MaxReferenceLength == 0 {
		return fmt.Errorf("max_reference_length: %w", ErrInvalidParams)
	}
	if p.MaxMemoLength == 0 {
		return fmt.Errorf("max_memo_length: %w", ErrInvalidParams)
	}
	if p.MinEscrowAmount.IsNegative() {
		return fmt.Errorf("min_escrow_amount: %w", ErrInvalidParams)
	}
	if p.DefaultExpirySeconds == 0 {
		return fmt.Errorf("default_expiry_seconds: %w", ErrInvalidParams)
	}
	return nil
}
