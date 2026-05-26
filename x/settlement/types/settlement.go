package types

import (
	"fmt"
	"strings"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

// SettlementStatus enum.
type SettlementStatus int32

const (
	SettlementPending   SettlementStatus = 0
	SettlementCompleted SettlementStatus = 1
	SettlementFailed    SettlementStatus = 2
	SettlementRefunded  SettlementStatus = 3
	SettlementCancelled SettlementStatus = 4
)

func (s SettlementStatus) String() string {
	switch s {
	case SettlementPending:
		return "pending"
	case SettlementCompleted:
		return "completed"
	case SettlementFailed:
		return "failed"
	case SettlementRefunded:
		return "refunded"
	case SettlementCancelled:
		return "cancelled"
	default:
		return "unknown"
	}
}

// TerminalStatuses returns the set of terminal status values.
func TerminalStatuses() map[int32]bool {
	return map[int32]bool{
		int32(SettlementFailed):    true,
		int32(SettlementRefunded):  true,
		int32(SettlementCancelled): true,
	}
}

// Settlement represents a payment settlement between a payer and a merchant.
type Settlement struct {
	Id                uint64   `json:"id" yaml:"id"`
	Payer             string   `json:"payer" yaml:"payer"`
	MerchantOwner     string   `json:"merchant_owner" yaml:"merchant_owner"`
	MerchantId        string   `json:"merchant_id" yaml:"merchant_id"`
	SettlementAddress string   `json:"settlement_address" yaml:"settlement_address"`
	Amount            sdk.Coin `json:"amount" yaml:"amount"`
	FeeAmount         sdk.Coin `json:"fee_amount" yaml:"fee_amount"`
	ValidatorShare    sdk.Coin `json:"validator_share" yaml:"validator_share"`
	TreasuryShare     sdk.Coin `json:"treasury_share" yaml:"treasury_share"`
	BurnShare         sdk.Coin `json:"burn_share" yaml:"burn_share"`
	RebateAppliedBps  uint32   `json:"rebate_applied_bps" yaml:"rebate_applied_bps"`
	RebateAmount      sdk.Coin `json:"rebate_amount" yaml:"rebate_amount"`
	Status            int32    `json:"status" yaml:"status"`
	FundsSettled      bool     `json:"funds_settled" yaml:"funds_settled"`
	BurnExecuted      bool     `json:"burn_executed" yaml:"burn_executed"`
	PaymentReference  string   `json:"payment_reference" yaml:"payment_reference"`
	Memo              string   `json:"memo" yaml:"memo"`
	Metadata          string   `json:"metadata" yaml:"metadata"`
	CreatedAt         int64    `json:"created_at" yaml:"created_at"`
	UpdatedAt         int64    `json:"updated_at" yaml:"updated_at"`
}

func NewSettlement(
	id uint64, payer, merchantOwner, merchantId, settlementAddress string,
	amount, feeAmount, validatorShare, treasuryShare, burnShare, rebateAmount sdk.Coin,
	rebateAppliedBps uint32, paymentReference, memo, metadata string, createdAt int64,
) Settlement {
	return Settlement{
		Id:                id,
		Payer:             payer,
		MerchantOwner:     merchantOwner,
		MerchantId:        merchantId,
		SettlementAddress: settlementAddress,
		Amount:            amount,
		FeeAmount:         feeAmount,
		ValidatorShare:    validatorShare,
		TreasuryShare:     treasuryShare,
		BurnShare:         burnShare,
		RebateAppliedBps:  rebateAppliedBps,
		RebateAmount:      rebateAmount,
		Status:            int32(SettlementPending),
		PaymentReference:  paymentReference,
		Memo:              memo,
		Metadata:          metadata,
		CreatedAt:         createdAt,
		UpdatedAt:         createdAt,
	}
}

func (s *Settlement) ProtoMessage() {}
func (s *Settlement) Reset()        { *s = Settlement{} }
func (s *Settlement) String() string {
	return fmt.Sprintf("Settlement{id=%d, payer=%s, merchant=%s, amount=%s, status=%s}",
		s.Id, s.Payer, s.MerchantOwner, s.Amount, SettlementStatus(s.Status))
}

// Validate performs basic validation on a settlement.
func (s Settlement) Validate() error {
	if _, err := sdk.AccAddressFromBech32(s.Payer); err != nil {
		return fmt.Errorf("invalid payer: %w", err)
	}
	if _, err := sdk.AccAddressFromBech32(s.MerchantOwner); err != nil {
		return fmt.Errorf("invalid merchant owner: %w", err)
	}
	if strings.TrimSpace(s.MerchantId) == "" {
		return fmt.Errorf("merchant id must not be empty")
	}
	if s.Amount.IsZero() || s.Amount.IsNegative() {
		return fmt.Errorf("settlement amount must be positive")
	}
	if s.FeeAmount.IsNegative() {
		return fmt.Errorf("fee amount must not be negative")
	}
	if s.RebateAmount.IsNegative() {
		return fmt.Errorf("rebate amount must not be negative")
	}
	if s.Status < 0 || s.Status > 4 {
		return fmt.Errorf("invalid status: %d", s.Status)
	}
	// FundsSettled=true requires status COMPLETED (live transfer executed)
	if s.FundsSettled && s.Status != int32(SettlementCompleted) {
		return fmt.Errorf("funds_settled=true requires status completed, got %s", SettlementStatus(s.Status))
	}
	// BurnExecuted=true requires FundsSettled=true and status COMPLETED
	if s.BurnExecuted {
		if !s.FundsSettled {
			return fmt.Errorf("burn_executed=true requires funds_settled=true")
		}
		if s.Status != int32(SettlementCompleted) {
			return fmt.Errorf("burn_executed=true requires status completed, got %s", SettlementStatus(s.Status))
		}
		if !s.BurnShare.Amount.IsPositive() {
			return fmt.Errorf("burn_executed=true requires positive burn share, got %s", s.BurnShare)
		}
	}
	return nil
}

func (s Settlement) IsPending() bool  { return s.Status == int32(SettlementPending) }
func (s Settlement) IsTerminal() bool { return TerminalStatuses()[s.Status] }
