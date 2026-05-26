package types

import (
	"fmt"

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
	EscrowsEnabled          bool     `json:"escrows_enabled" yaml:"escrows_enabled"`
	LiveEnabled             bool     `json:"live_enabled" yaml:"live_enabled"`
	MaxReferenceLength      uint32   `json:"max_reference_length" yaml:"max_reference_length"`
	MaxMemoLength           uint32   `json:"max_memo_length" yaml:"max_memo_length"`
	MaxDisputeReasonLength  uint32   `json:"max_dispute_reason_length" yaml:"max_dispute_reason_length"`
	MaxResolutionNoteLength uint32   `json:"max_resolution_note_length" yaml:"max_resolution_note_length"`
	MinEscrowAmount         sdk.Coin `json:"min_escrow_amount" yaml:"min_escrow_amount"`
	DefaultExpirySeconds    uint64   `json:"default_expiry_seconds" yaml:"default_expiry_seconds"`
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

func (p *Params) ProtoMessage()  {}
func (p *Params) Reset()         { *p = Params{} }
func (p *Params) String() string { return "EscrowParams{}" }

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
