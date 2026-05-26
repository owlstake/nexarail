package types

import (
	"fmt"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

const (
	DefaultMinNameLength        = 3
	DefaultMaxNameLength        = 64
	DefaultMaxDescriptionLength = 256
)

var DefaultRegistrationFee = sdk.NewInt64Coin("unxrl", 1000000) // 1 NXRL

// Params defines the merchant module parameters.
type Params struct {
	RegistrationFee      sdk.Coin `json:"registration_fee" yaml:"registration_fee"`
	MinNameLength        uint32   `json:"min_name_length" yaml:"min_name_length"`
	MaxNameLength        uint32   `json:"max_name_length" yaml:"max_name_length"`
	MaxDescriptionLength uint32   `json:"max_description_length" yaml:"max_description_length"`
}

// DefaultParams returns default module parameters.
func DefaultParams() Params {
	return Params{
		RegistrationFee:      DefaultRegistrationFee,
		MinNameLength:        DefaultMinNameLength,
		MaxNameLength:        DefaultMaxNameLength,
		MaxDescriptionLength: DefaultMaxDescriptionLength,
	}
}

// ProtoMessage implements proto.Message.
func (p *Params) ProtoMessage()  {}
func (p *Params) Reset()         { *p = Params{} }
func (p *Params) String() string { return fmt.Sprintf("Params{fee=%s}", p.RegistrationFee) }

// Validate checks all params are valid.
func (p Params) Validate() error {
	if p.RegistrationFee.IsNegative() {
		return fmt.Errorf("registration fee must not be negative: %w", ErrInvalidParams)
	}
	if p.MinNameLength < 1 {
		return fmt.Errorf("min name length must be at least 1: %w", ErrInvalidParams)
	}
	if p.MaxNameLength < p.MinNameLength {
		return fmt.Errorf("max name length must be >= min: %w", ErrInvalidParams)
	}
	if p.MaxDescriptionLength < 1 {
		return fmt.Errorf("max description length must be at least 1: %w", ErrInvalidParams)
	}
	return nil
}
