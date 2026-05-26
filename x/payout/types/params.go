package types

import (
	"fmt"
	sdk "github.com/cosmos/cosmos-sdk/types"
)

const (
	DefaultMaxRefLen    = 120
	DefaultMaxMemoLen   = 280
	DefaultMaxFailLen   = 1000
	DefaultMaxBatchSize = 100
)

var DefaultMinPayout = sdk.NewInt64Coin("unxrl", 1)

type Params struct {
	PayoutsEnabled      bool `json:"payouts_enabled"`
	BatchPayoutsEnabled bool `json:"batch_payouts_enabled"`
	ApprovalRequired    bool `json:"approval_required"`
	// LiveEnabled, when true, makes MsgMarkPayoutPaid transfer funds from the
	// nexarail_treasury module account to the payout recipient. Default false
	// keeps payouts metadata-only. Governance-controlled via MsgUpdateParams.
	LiveEnabled            bool     `json:"live_enabled"`
	MaxReferenceLength     uint32   `json:"max_reference_length"`
	MaxMemoLength          uint32   `json:"max_memo_length"`
	MaxFailureReasonLength uint32   `json:"max_failure_reason_length"`
	MaxBatchSize           uint32   `json:"max_batch_size"`
	MinPayoutAmount        sdk.Coin `json:"min_payout_amount"`
}

func DefaultParams() Params {
	return Params{
		PayoutsEnabled:         true,
		BatchPayoutsEnabled:    true,
		ApprovalRequired:       true,
		LiveEnabled:            false,
		MaxReferenceLength:     DefaultMaxRefLen,
		MaxMemoLength:          DefaultMaxMemoLen,
		MaxFailureReasonLength: DefaultMaxFailLen,
		MaxBatchSize:           DefaultMaxBatchSize,
		MinPayoutAmount:        DefaultMinPayout,
	}
}
func (p *Params) ProtoMessage()  {}
func (p *Params) Reset()         { *p = Params{} }
func (p *Params) String() string { return "PayoutParams{}" }
func (p Params) Validate() error {
	if p.MaxReferenceLength == 0 || p.MaxMemoLength == 0 || p.MaxBatchSize == 0 {
		return fmt.Errorf("zero length: %w", ErrInvalidParams)
	}
	if p.MinPayoutAmount.IsNegative() {
		return fmt.Errorf("min amount: %w", ErrInvalidParams)
	}
	return nil
}
