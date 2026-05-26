package types

import (
	"fmt"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

// Basis points constants.
const (
	BasisPointsMax    = uint32(10_000)
	BasisPointsFactor = uint32(10_000)

	DefaultValidatorShareBps uint32 = 6000
	DefaultTreasuryShareBps  uint32 = 2000
	DefaultBurnShareBps      uint32 = 2000

	DefaultFeeCollectorName = "fee_collector"
	DefaultBurnEnabled      = false
)

var DefaultMinProtocolFee = sdk.NewInt64Coin("unxrl", 0)

// Params defines the fee split parameters for the NexaRail fees module.
type Params struct {
	// ValidatorShareBps — share that goes to validators/delegators (basis points, default 6000)
	ValidatorShareBps uint32 `json:"validator_share_bps" yaml:"validator_share_bps"`
	// TreasuryShareBps — share that goes to the protocol treasury (basis points, default 2000)
	TreasuryShareBps uint32 `json:"treasury_share_bps" yaml:"treasury_share_bps"`
	// BurnShareBps — share that gets burned (basis points, default 2000)
	BurnShareBps uint32 `json:"burn_share_bps" yaml:"burn_share_bps"`
	// FeeCollectorName — name of the fee collector module account
	FeeCollectorName string `json:"fee_collector_name" yaml:"fee_collector_name"`
	// TreasuryAccount — bech32 address of the protocol treasury (empty = disabled)
	TreasuryAccount string `json:"treasury_account" yaml:"treasury_account"`
	// BurnEnabled — enables the burn mechanism
	BurnEnabled bool `json:"burn_enabled" yaml:"burn_enabled"`
	// MinProtocolFee — minimum fee required for protocol fee splitting
	MinProtocolFee sdk.Coin `json:"min_protocol_fee" yaml:"min_protocol_fee"`
}

// DefaultParams returns the default parameters.
func DefaultParams() Params {
	return Params{
		ValidatorShareBps: DefaultValidatorShareBps,
		TreasuryShareBps:  DefaultTreasuryShareBps,
		BurnShareBps:      DefaultBurnShareBps,
		FeeCollectorName:  DefaultFeeCollectorName,
		TreasuryAccount:   "",
		BurnEnabled:       DefaultBurnEnabled,
		MinProtocolFee:    DefaultMinProtocolFee,
	}
}

// ProtoMessage implements proto.Message.
func (p *Params) ProtoMessage() {}

// Reset implements proto.Message.
func (p *Params) Reset() { *p = Params{} }

// String implements proto.Message.
func (p *Params) String() string {
	return fmt.Sprintf("Params{val=%d, treas=%d, burn=%d}", p.ValidatorShareBps, p.TreasuryShareBps, p.BurnShareBps)
}

// Validate performs full validation of the parameters.
func (p Params) Validate() error {
	if p.ValidatorShareBps > BasisPointsMax {
		return fmt.Errorf("validator share bps %d exceeds max %d: %w", p.ValidatorShareBps, BasisPointsMax, ErrInvalidShareBps)
	}
	if p.TreasuryShareBps > BasisPointsMax {
		return fmt.Errorf("treasury share bps %d exceeds max %d: %w", p.TreasuryShareBps, BasisPointsMax, ErrInvalidShareBps)
	}
	if p.BurnShareBps > BasisPointsMax {
		return fmt.Errorf("burn share bps %d exceeds max %d: %w", p.BurnShareBps, BasisPointsMax, ErrInvalidShareBps)
	}

	total := p.ValidatorShareBps + p.TreasuryShareBps + p.BurnShareBps
	if total != BasisPointsMax {
		return fmt.Errorf(
			"share basis points must total %d, got %d: %w",
			BasisPointsMax, total, ErrInvalidShareBps,
		)
	}

	if p.FeeCollectorName == "" {
		return fmt.Errorf("fee collector name: %w", ErrEmptyFeeCollector)
	}

	if p.TreasuryAccount != "" {
		if _, err := sdk.AccAddressFromBech32(p.TreasuryAccount); err != nil {
			return fmt.Errorf("treasury account '%s': %w", p.TreasuryAccount, ErrInvalidTreasuryAccount)
		}
	}

	if p.MinProtocolFee.IsNegative() {
		return fmt.Errorf("min protocol fee: %w", ErrNegativeMinFee)
	}

	return nil
}

// ValidateSharesTotal checks that the three shares sum to exactly 10000 bps.
func (p Params) ValidateSharesTotal() error {
	total := p.ValidatorShareBps + p.TreasuryShareBps + p.BurnShareBps
	if total != BasisPointsMax {
		return fmt.Errorf(
			"share basis points must total %d, got %d: %w",
			BasisPointsMax, total, ErrInvalidShareBps,
		)
	}
	return nil
}
