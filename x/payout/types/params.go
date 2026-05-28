package types

import (
	"fmt"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/nexarail/chain/x/common"
)

const (
	DefaultMaxRefLen    = 120
	DefaultMaxMemoLen   = 280
	DefaultMaxFailLen   = 1000
	DefaultMaxBatchSize = 100
)

var DefaultMinPayout = sdk.NewInt64Coin("unxrl", 1)

type Params struct {
	PayoutsEnabled      bool `json:"payouts_enabled" protobuf:"varint,1,opt,name=payouts_enabled,json=payoutsEnabled,proto3"`
	BatchPayoutsEnabled bool `json:"batch_payouts_enabled" protobuf:"varint,2,opt,name=batch_payouts_enabled,json=batchPayoutsEnabled,proto3"`
	ApprovalRequired    bool `json:"approval_required" protobuf:"varint,3,opt,name=approval_required,json=approvalRequired,proto3"`
	// LiveEnabled, when true, makes MsgMarkPayoutPaid transfer funds from the
	// nexarail_treasury module account to the payout recipient. Default false
	// keeps payouts metadata-only. Governance-controlled via MsgUpdateParams.
	LiveEnabled            bool     `json:"live_enabled" protobuf:"varint,4,opt,name=live_enabled,json=liveEnabled,proto3"`
	MaxReferenceLength     uint32   `json:"max_reference_length" protobuf:"varint,5,opt,name=max_reference_length,json=maxReferenceLength,proto3"`
	MaxMemoLength          uint32   `json:"max_memo_length" protobuf:"varint,6,opt,name=max_memo_length,json=maxMemoLength,proto3"`
	MaxFailureReasonLength uint32   `json:"max_failure_reason_length" protobuf:"varint,7,opt,name=max_failure_reason_length,json=maxFailureReasonLength,proto3"`
	MaxBatchSize           uint32   `json:"max_batch_size" protobuf:"varint,8,opt,name=max_batch_size,json=maxBatchSize,proto3"`
	MinPayoutAmount        sdk.Coin `json:"min_payout_amount" protobuf:"bytes,9,opt,name=min_payout_amount,json=minPayoutAmount,proto3"`
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
func (p *Params) ProtoMessage()               {}
func (p *Params) Descriptor() ([]byte, []int) { return common.PayoutDescriptorBytes, []int{0} }
func (p *Params) Reset()                      { *p = Params{} }
func (p *Params) String() string              { return "PayoutParams{}" }
func (p Params) Validate() error {
	if p.MaxReferenceLength == 0 || p.MaxMemoLength == 0 || p.MaxBatchSize == 0 {
		return fmt.Errorf("zero length: %w", ErrInvalidParams)
	}
	if p.MinPayoutAmount.IsNegative() {
		return fmt.Errorf("min amount: %w", ErrInvalidParams)
	}
	return nil
}
