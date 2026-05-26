package types

import (
	"fmt"
	sdk "github.com/cosmos/cosmos-sdk/types"
)

const (
	DefaultMaxNameLen    = 80
	DefaultMaxDescLen    = 1000
	DefaultMaxURILen     = 300
	DefaultMaxPurposeLen = 1000
	DefaultMaxMemoLen    = 280
)

var DefaultMinSpendAmount = sdk.NewInt64Coin("unxrl", 1)

type Params struct {
	TreasuryEnabled      bool     `json:"treasury_enabled"`
	LiveEnabled          bool     `json:"live_enabled"`
	SpendRequestsEnabled bool     `json:"spend_requests_enabled"`
	GrantsEnabled        bool     `json:"grants_enabled"`
	BudgetsEnabled       bool     `json:"budgets_enabled"`
	MaxNameLength        uint32   `json:"max_name_length"`
	MaxDescriptionLength uint32   `json:"max_description_length"`
	MaxMetadataUriLength uint32   `json:"max_metadata_uri_length"`
	MaxPurposeLength     uint32   `json:"max_purpose_length"`
	MaxMemoLength        uint32   `json:"max_memo_length"`
	MinSpendAmount       sdk.Coin `json:"min_spend_amount"`
}

func DefaultParams() Params {
	return Params{true, false, true, true, true, DefaultMaxNameLen, DefaultMaxDescLen, DefaultMaxURILen, DefaultMaxPurposeLen, DefaultMaxMemoLen, DefaultMinSpendAmount}
}
func (p *Params) ProtoMessage()  {}
func (p *Params) Reset()         { *p = Params{} }
func (p *Params) String() string { return "TreasuryParams{}" }
func (p Params) Validate() error {
	if p.MaxNameLength == 0 || p.MaxDescriptionLength == 0 {
		return fmt.Errorf("zero length: %w", ErrInvalidParams)
	}
	if p.MinSpendAmount.IsNegative() {
		return fmt.Errorf("min spend: %w", ErrInvalidParams)
	}
	return nil
}
