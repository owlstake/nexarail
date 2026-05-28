package types

import (
	"fmt"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/nexarail/chain/x/common"
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
	TreasuryEnabled      bool     `json:"treasury_enabled" protobuf:"varint,1,opt,name=treasury_enabled,json=treasuryEnabled,proto3"`
	LiveEnabled          bool     `json:"live_enabled" protobuf:"varint,2,opt,name=live_enabled,json=liveEnabled,proto3"`
	SpendRequestsEnabled bool     `json:"spend_requests_enabled" protobuf:"varint,3,opt,name=spend_requests_enabled,json=spendRequestsEnabled,proto3"`
	GrantsEnabled        bool     `json:"grants_enabled" protobuf:"varint,4,opt,name=grants_enabled,json=grantsEnabled,proto3"`
	BudgetsEnabled       bool     `json:"budgets_enabled" protobuf:"varint,5,opt,name=budgets_enabled,json=budgetsEnabled,proto3"`
	MaxNameLength        uint32   `json:"max_name_length" protobuf:"varint,6,opt,name=max_name_length,json=maxNameLength,proto3"`
	MaxDescriptionLength uint32   `json:"max_description_length" protobuf:"varint,7,opt,name=max_description_length,json=maxDescriptionLength,proto3"`
	MaxMetadataUriLength uint32   `json:"max_metadata_uri_length" protobuf:"varint,8,opt,name=max_metadata_uri_length,json=maxMetadataUriLength,proto3"`
	MaxPurposeLength     uint32   `json:"max_purpose_length" protobuf:"varint,9,opt,name=max_purpose_length,json=maxPurposeLength,proto3"`
	MaxMemoLength        uint32   `json:"max_memo_length" protobuf:"varint,10,opt,name=max_memo_length,json=maxMemoLength,proto3"`
	MinSpendAmount       sdk.Coin `json:"min_spend_amount" protobuf:"bytes,11,opt,name=min_spend_amount,json=minSpendAmount,proto3"`
}

func DefaultParams() Params {
	return Params{true, false, true, true, true, DefaultMaxNameLen, DefaultMaxDescLen, DefaultMaxURILen, DefaultMaxPurposeLen, DefaultMaxMemoLen, DefaultMinSpendAmount}
}
func (p *Params) ProtoMessage()               {}
func (p *Params) Descriptor() ([]byte, []int) { return common.TreasuryDescriptorBytes, []int{0} }
func (p *Params) Reset()                      { *p = Params{} }
func (p *Params) String() string              { return "TreasuryParams{}" }
func (p Params) Validate() error {
	if p.MaxNameLength == 0 || p.MaxDescriptionLength == 0 {
		return fmt.Errorf("zero length: %w", ErrInvalidParams)
	}
	if p.MinSpendAmount.IsNegative() {
		return fmt.Errorf("min spend: %w", ErrInvalidParams)
	}
	return nil
}
