package types

import (
	"fmt"
	"regexp"
	"strings"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

type PayoutStatus int32

const (
	PayoutUnspecified PayoutStatus = 0
	PayoutCreated     PayoutStatus = 1
	PayoutApproved    PayoutStatus = 2
	PayoutPaid        PayoutStatus = 3
	PayoutCancelled   PayoutStatus = 4
	PayoutFailed      PayoutStatus = 5
)

func (s PayoutStatus) String() string {
	switch s {
	case PayoutUnspecified:
		return "unspecified"
	case PayoutCreated:
		return "created"
	case PayoutApproved:
		return "approved"
	case PayoutPaid:
		return "paid"
	case PayoutCancelled:
		return "cancelled"
	case PayoutFailed:
		return "failed"
	default:
		return "unknown"
	}
}

var validPayoutStatuses = map[int32]bool{0: true, 1: true, 2: true, 3: true, 4: true, 5: true}

type PayoutType int32

const (
	PayoutTypeUnspecified PayoutType = 0
	PayoutTypeCreator     PayoutType = 1
	PayoutTypeAffiliate   PayoutType = 2
	PayoutTypeSupplier    PayoutType = 3
	PayoutTypeMarketplace PayoutType = 4
	PayoutTypeRefund      PayoutType = 5
	PayoutTypeOther       PayoutType = 6
)

func (t PayoutType) String() string {
	switch t {
	case PayoutTypeCreator:
		return "creator"
	case PayoutTypeAffiliate:
		return "affiliate"
	case PayoutTypeSupplier:
		return "supplier"
	case PayoutTypeMarketplace:
		return "marketplace_seller"
	case PayoutTypeRefund:
		return "refund"
	case PayoutTypeOther:
		return "other"
	default:
		return "unspecified"
	}
}

var validPayoutTypes = map[int32]bool{0: true, 1: true, 2: true, 3: true, 4: true, 5: true, 6: true}

var payoutIDRegex = regexp.MustCompile(`^[a-z0-9][a-z0-9\-]{1,78}[a-z0-9]$`)

type Payout struct {
	PayoutId          string   `json:"payout_id"`
	BatchId           string   `json:"batch_id"`
	MerchantId        string   `json:"merchant_id"`
	InitiatorAddress  string   `json:"initiator_address"`
	RecipientAddress  string   `json:"recipient_address"`
	AssetDenom        string   `json:"asset_denom"`
	Amount            sdk.Coin `json:"amount"`
	FeeAmount         sdk.Coin `json:"fee_amount"`
	NetAmount         sdk.Coin `json:"net_amount"`
	Status            int32    `json:"status"`
	FundsPaid         bool     `json:"funds_paid"`
	PayoutType        int32    `json:"payout_type"`
	PayoutReference   string   `json:"payout_reference"`
	Memo              string   `json:"memo"`
	ExternalReference string   `json:"external_reference"`
	FailureReason     string   `json:"failure_reason"`
	CreatedAt         int64    `json:"created_at"`
	UpdatedAt         int64    `json:"updated_at"`
	ApprovedAt        int64    `json:"approved_at"`
	PaidAt            int64    `json:"paid_at"`
	CancelledAt       int64    `json:"cancelled_at"`
	FailedAt          int64    `json:"failed_at"`
}

func NewPayout(id, batchID, merchantID, initiator, recipient, denom string, amount sdk.Coin, pType int32, ref, memo string, now int64) Payout {
	return Payout{
		PayoutId: id, BatchId: batchID, MerchantId: merchantID, InitiatorAddress: initiator,
		RecipientAddress: recipient, AssetDenom: denom, Amount: amount,
		FeeAmount: sdk.NewInt64Coin(denom, 0), NetAmount: amount,
		Status: int32(PayoutCreated), PayoutType: pType,
		PayoutReference: strings.TrimSpace(ref), Memo: strings.TrimSpace(memo),
		CreatedAt: now, UpdatedAt: now,
	}
}
func (p *Payout) ProtoMessage() {}
func (p *Payout) Reset()        { *p = Payout{} }
func (p *Payout) String() string {
	return fmt.Sprintf("Payout{id=%s, to=%s, %s}", p.PayoutId, p.RecipientAddress, p.Amount)
}

func (p Payout) ValidateWithParams(params Params) error {
	// ID
	if len(p.PayoutId) < 3 || len(p.PayoutId) > 80 {
		return fmt.Errorf("id length %d: %w", len(p.PayoutId), ErrInvalidPayoutID)
	}
	if !payoutIDRegex.MatchString(p.PayoutId) {
		return fmt.Errorf("id format: %w", ErrInvalidPayoutID)
	}
	// Addresses
	if _, err := sdk.AccAddressFromBech32(p.InitiatorAddress); err != nil {
		return fmt.Errorf("initiator: %w", ErrInvalidInitiator)
	}
	if _, err := sdk.AccAddressFromBech32(p.RecipientAddress); err != nil {
		return fmt.Errorf("recipient: %w", ErrInvalidRecipient)
	}
	if p.InitiatorAddress == p.RecipientAddress {
		return fmt.Errorf("initiator==recipient: %w", ErrInvalidInitiator)
	}
	if strings.TrimSpace(p.MerchantId) == "" {
		return fmt.Errorf("merchant: %w", ErrInvalidMerchantID)
	}
	// Amount
	if p.Amount.IsZero() || p.Amount.IsNegative() {
		return fmt.Errorf("amount: %w", ErrAmountNotPositive)
	}
	if p.Amount.Denom != p.AssetDenom {
		return fmt.Errorf("denom mismatch: %w", ErrInvalidDenom)
	}
	if p.Amount.Denom == params.MinPayoutAmount.Denom && p.Amount.IsLT(params.MinPayoutAmount) {
		return fmt.Errorf("below min %s: %w", params.MinPayoutAmount, ErrAmountNotPositive)
	}
	// Fees
	if p.FeeAmount.IsNegative() {
		return fmt.Errorf("fee: %w", ErrInvalidFee)
	}
	if p.NetAmount.IsNegative() {
		return fmt.Errorf("net: %w", ErrInvalidFee)
	}
	if p.FeeAmount.Add(p.NetAmount).Amount.GT(p.Amount.Amount) {
		return fmt.Errorf("fee+net>amount: %w", ErrInvalidFee)
	}
	// Status & type
	if !validPayoutStatuses[p.Status] {
		return fmt.Errorf("status %d: %w", p.Status, ErrInvalidStatus)
	}
	if !validPayoutTypes[p.PayoutType] {
		return fmt.Errorf("type %d: %w", p.PayoutType, ErrInvalidPayoutType)
	}
	// Funds-paid consistency: a payout with funds disbursed must be in PAID status.
	if p.FundsPaid && p.Status != int32(PayoutPaid) {
		return fmt.Errorf("funds_paid requires paid status, got %s: %w", PayoutStatus(p.Status), ErrInvalidStatus)
	}
	// Lengths
	if len(p.PayoutReference) > int(params.MaxReferenceLength) {
		return fmt.Errorf("ref: %w", ErrReferenceTooLong)
	}
	if len(p.Memo) > int(params.MaxMemoLength) {
		return fmt.Errorf("memo: %w", ErrMemoTooLong)
	}
	if len(p.FailureReason) > int(params.MaxFailureReasonLength) {
		return fmt.Errorf("failure: %w", ErrFailureReasonTooLong)
	}
	return nil
}
