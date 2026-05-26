package types

import (
	"fmt"
)

const (
	DefaultFeeRateBps uint32 = 100 // 1%
	BasisPointsMax    uint32 = 10000
)

// Default rebate percentages per tier (basis points).
var DefaultRebateTiers = []uint32{0, 500, 1000, 1500, 2000} // 0%, 5%, 10%, 15%, 20%

// Params defines the settlement module parameters.
type Params struct {
	// Enabled allows settlements to be created.
	Enabled bool `json:"enabled" yaml:"enabled"`
	// LiveEnabled enables live merchant-net transfers from payer to merchant.
	// When false (default), settlements are metadata-only. Governance-gated.
	LiveEnabled bool `json:"live_enabled" yaml:"live_enabled"`
	// TreasuryRoutingEnabled enables live treasury-share transfers from payer to
	// nexarail_treasury. Only effective when LiveEnabled=true. Default false.
	TreasuryRoutingEnabled bool `json:"treasury_routing_enabled" yaml:"treasury_routing_enabled"`
	// BurnRoutingEnabled enables live burn-share routing from payer to nexarail_burner
	// via SendCoinsFromAccountToModule + bank.BurnCoins. Only effective when both
	// LiveEnabled=true AND TreasuryRoutingEnabled=true. Default false.
	BurnRoutingEnabled bool `json:"burn_routing_enabled" yaml:"burn_routing_enabled"`
	// FeeRateBps is the protocol fee rate in basis points (default 100 = 1%).
	FeeRateBps uint32 `json:"fee_rate_bps" yaml:"fee_rate_bps"`
	// RebateTiers maps RebateTier enum values to discount basis points.
	RebateTiers []uint32 `json:"rebate_tiers" yaml:"rebate_tiers"`
}

func DefaultParams() Params {
	tiers := make([]uint32, len(DefaultRebateTiers))
	copy(tiers, DefaultRebateTiers)
	return Params{
		Enabled:                true,
		LiveEnabled:            false,
		TreasuryRoutingEnabled: false,
		BurnRoutingEnabled:     false,
		FeeRateBps:             DefaultFeeRateBps,
		RebateTiers:            tiers,
	}
}

func (p *Params) ProtoMessage()  {}
func (p *Params) Reset()         { *p = Params{} }
func (p *Params) String() string { return fmt.Sprintf("Params{fee=%d bps}", p.FeeRateBps) }

// Validate checks all params are valid.
func (p Params) Validate() error {
	if p.FeeRateBps > BasisPointsMax {
		return fmt.Errorf("fee rate bps %d exceeds max %d: %w", p.FeeRateBps, BasisPointsMax, ErrInvalidParams)
	}
	if len(p.RebateTiers) != 5 {
		return fmt.Errorf("rebate tiers must have exactly 5 entries (none/bronze/silver/gold/platinum): %w", ErrInvalidParams)
	}
	for i, r := range p.RebateTiers {
		if r > BasisPointsMax {
			return fmt.Errorf("rebate tier %d bps %d exceeds max %d: %w", i, r, BasisPointsMax, ErrInvalidParams)
		}
	}
	return nil
}

// GetRebateBps returns the rebate basis points for a given tier (0-4).
func (p Params) GetRebateBps(tier int32) uint32 {
	if tier < 0 || int(tier) >= len(p.RebateTiers) {
		return 0
	}
	return p.RebateTiers[tier]
}
