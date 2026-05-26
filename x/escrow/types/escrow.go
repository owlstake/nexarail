package types

import (
	"fmt"
	"regexp"
	"strings"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

// --- EscrowStatus ---

type EscrowStatus int32

const (
	EscrowUnspecified EscrowStatus = 0
	EscrowCreated     EscrowStatus = 1
	EscrowFunded      EscrowStatus = 2
	EscrowReleased    EscrowStatus = 3
	EscrowRefunded    EscrowStatus = 4
	EscrowDisputed    EscrowStatus = 5
	EscrowCancelled   EscrowStatus = 6
	EscrowExpired     EscrowStatus = 7
)

func (s EscrowStatus) String() string {
	switch s {
	case EscrowUnspecified:
		return "unspecified"
	case EscrowCreated:
		return "created"
	case EscrowFunded:
		return "funded"
	case EscrowReleased:
		return "released"
	case EscrowRefunded:
		return "refunded"
	case EscrowDisputed:
		return "disputed"
	case EscrowCancelled:
		return "cancelled"
	case EscrowExpired:
		return "expired"
	default:
		return "unknown"
	}
}

var validEscrowStatuses = map[int32]bool{
	0: true, 1: true, 2: true, 3: true, 4: true, 5: true, 6: true, 7: true,
}

// --- DisputeStatus ---

type DisputeStatus int32

const (
	DisputeUnspecified DisputeStatus = 0
	DisputeNone        DisputeStatus = 1
	DisputeOpen        DisputeStatus = 2
	DisputeBuyerWins   DisputeStatus = 3
	DisputeSellerWins  DisputeStatus = 4
	DisputeSettled     DisputeStatus = 5
	DisputeRejected    DisputeStatus = 6
)

func (s DisputeStatus) String() string {
	switch s {
	case DisputeUnspecified:
		return "unspecified"
	case DisputeNone:
		return "none"
	case DisputeOpen:
		return "open"
	case DisputeBuyerWins:
		return "buyer_wins"
	case DisputeSellerWins:
		return "seller_wins"
	case DisputeSettled:
		return "settled"
	case DisputeRejected:
		return "rejected"
	default:
		return "unknown"
	}
}

var validDisputeStatuses = map[int32]bool{
	0: true, 1: true, 2: true, 3: true, 4: true, 5: true, 6: true,
}

// --- Escrow ---

var escrowIDRegex = regexp.MustCompile(`^[a-z0-9][a-z0-9\-]{1,78}[a-z0-9]$`)

const EscrowModuleAccount = "nexarail_escrow"

type Escrow struct {
	EscrowId         string   `json:"escrow_id" yaml:"escrow_id"`
	BuyerAddress     string   `json:"buyer_address" yaml:"buyer_address"`
	SellerAddress    string   `json:"seller_address" yaml:"seller_address"`
	MerchantId       string   `json:"merchant_id" yaml:"merchant_id"`
	AssetDenom       string   `json:"asset_denom" yaml:"asset_denom"`
	Amount           sdk.Coin `json:"amount" yaml:"amount"`
	PlatformFee      sdk.Coin `json:"platform_fee" yaml:"platform_fee"`
	SellerAmount     sdk.Coin `json:"seller_amount" yaml:"seller_amount"`
	Status           int32    `json:"status" yaml:"status"`
	DisputeStatus    int32    `json:"dispute_status" yaml:"dispute_status"`
	ArbitratorAddr   string   `json:"arbitrator_address" yaml:"arbitrator_address"`
	PaymentReference string   `json:"payment_reference" yaml:"payment_reference"`
	Memo             string   `json:"memo" yaml:"memo"`
	ReleaseReference string   `json:"release_reference" yaml:"release_reference"`
	RefundReference  string   `json:"refund_reference" yaml:"refund_reference"`
	DisputeReason    string   `json:"dispute_reason" yaml:"dispute_reason"`
	ResolutionNote   string   `json:"resolution_note" yaml:"resolution_note"`
	CreatedAt        int64    `json:"created_at" yaml:"created_at"`
	UpdatedAt        int64    `json:"updated_at" yaml:"updated_at"`
	ExpiresAt        int64    `json:"expires_at" yaml:"expires_at"`
	FundsCustodied   bool     `json:"funds_custodied" yaml:"funds_custodied"`
}

func NewEscrow(escrowID, buyer, seller, merchantID, denom string, amount sdk.Coin,
	paymentRef, memo string, createdAt, expiresAt int64) Escrow {
	return Escrow{
		EscrowId:         escrowID,
		BuyerAddress:     buyer,
		SellerAddress:    seller,
		MerchantId:       merchantID,
		AssetDenom:       denom,
		Amount:           amount,
		PlatformFee:      sdk.NewInt64Coin(denom, 0),
		SellerAmount:     sdk.NewInt64Coin(denom, 0),
		Status:           int32(EscrowCreated),
		DisputeStatus:    int32(DisputeNone),
		PaymentReference: strings.TrimSpace(paymentRef),
		Memo:             strings.TrimSpace(memo),
		CreatedAt:        createdAt,
		UpdatedAt:        createdAt,
		ExpiresAt:        expiresAt,
	}
}

func (e *Escrow) ProtoMessage() {}
func (e *Escrow) Reset()        { *e = Escrow{} }
func (e *Escrow) String() string {
	return fmt.Sprintf("Escrow{id=%s, buyer=%s, seller=%s, amount=%s, status=%s}",
		e.EscrowId, e.BuyerAddress, e.SellerAddress, e.Amount, EscrowStatus(e.Status))
}

// Validate performs basic structural validation.
func (e Escrow) Validate() error {
	return e.ValidateWithParams(DefaultParams())
}

// ValidateWithParams validates the escrow against module parameters.
func (e Escrow) ValidateWithParams(p Params) error {
	// Escrow ID
	if len(e.EscrowId) < 3 || len(e.EscrowId) > 80 {
		return fmt.Errorf("escrow_id length %d must be 3–80: %w", len(e.EscrowId), ErrInvalidEscrowID)
	}
	if !escrowIDRegex.MatchString(e.EscrowId) {
		return fmt.Errorf("escrow_id must be lowercase letters, numbers, and hyphens: %w", ErrInvalidEscrowID)
	}
	// Addresses
	if _, err := sdk.AccAddressFromBech32(e.BuyerAddress); err != nil {
		return fmt.Errorf("buyer_address: %w", ErrInvalidBuyer)
	}
	if _, err := sdk.AccAddressFromBech32(e.SellerAddress); err != nil {
		return fmt.Errorf("seller_address: %w", ErrInvalidSeller)
	}
	if e.BuyerAddress == e.SellerAddress {
		return fmt.Errorf("buyer and seller must differ: %w", ErrInvalidBuyer)
	}
	if strings.TrimSpace(e.MerchantId) == "" {
		return fmt.Errorf("merchant_id required: %w", ErrInvalidMerchantID)
	}
	// Amount
	if e.Amount.IsZero() || e.Amount.IsNegative() {
		return fmt.Errorf("amount must be positive: %w", ErrAmountNotPositive)
	}
	if e.Amount.Denom != e.AssetDenom {
		return fmt.Errorf("amount denom %s != asset_denom %s: %w", e.Amount.Denom, e.AssetDenom, ErrInvalidDenom)
	}
	// Min amount
	if e.AssetDenom == p.MinEscrowAmount.Denom && e.Amount.IsLT(p.MinEscrowAmount) {
		return fmt.Errorf("amount %s below minimum %s: %w", e.Amount, p.MinEscrowAmount, ErrAmountNotPositive)
	}
	// Fees
	if e.PlatformFee.IsNegative() {
		return fmt.Errorf("platform_fee negative: %w", ErrInvalidFee)
	}
	if e.SellerAmount.IsNegative() {
		return fmt.Errorf("seller_amount negative: %w", ErrInvalidFee)
	}
	totalFeeSeller := e.PlatformFee.Add(e.SellerAmount)
	if totalFeeSeller.Amount.GT(e.Amount.Amount) {
		return fmt.Errorf("platform_fee + seller_amount %s > amount %s: %w", totalFeeSeller, e.Amount, ErrInvalidFee)
	}
	// Statuses
	if !validEscrowStatuses[e.Status] {
		return fmt.Errorf("invalid escrow status %d: %w", e.Status, ErrInvalidStatus)
	}
	if !validDisputeStatuses[e.DisputeStatus] {
		return fmt.Errorf("invalid dispute status %d: %w", e.DisputeStatus, ErrInvalidDisputeStatus)
	}
	// Length checks
	if len(e.PaymentReference) > int(p.MaxReferenceLength) {
		return fmt.Errorf("payment_reference too long (%d > %d): %w", len(e.PaymentReference), p.MaxReferenceLength, ErrReferenceTooLong)
	}
	if len(e.Memo) > int(p.MaxMemoLength) {
		return fmt.Errorf("memo too long (%d > %d): %w", len(e.Memo), p.MaxMemoLength, ErrMemoTooLong)
	}
	if len(e.DisputeReason) > int(p.MaxDisputeReasonLength) {
		return fmt.Errorf("dispute_reason too long: %w", ErrDisputeReasonTooLong)
	}
	if len(e.ResolutionNote) > int(p.MaxResolutionNoteLength) {
		return fmt.Errorf("resolution_note too long: %w", ErrResolutionNoteTooLong)
	}
	// Expiry
	if e.ExpiresAt != 0 && e.ExpiresAt <= e.CreatedAt {
		return fmt.Errorf("expires_at %d must be > created_at %d: %w", e.ExpiresAt, e.CreatedAt, ErrInvalidExpiry)
	}
	return nil
}
