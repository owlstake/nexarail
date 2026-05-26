package types

import (
	"fmt"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"strings"
)

type SpendStatus int32

const (
	SpendUnspecified SpendStatus = 0
	SpendRequested   SpendStatus = 1
	SpendApproved    SpendStatus = 2
	SpendRejected    SpendStatus = 3
	SpendExecuted    SpendStatus = 4
	SpendCancelled   SpendStatus = 5
)

func (s SpendStatus) String() string {
	switch s {
	case SpendRequested:
		return "requested"
	case SpendApproved:
		return "approved"
	case SpendRejected:
		return "rejected"
	case SpendExecuted:
		return "executed"
	case SpendCancelled:
		return "cancelled"
	default:
		return "unspecified"
	}
}

var validSpendStatuses = map[int32]bool{0: true, 1: true, 2: true, 3: true, 4: true, 5: true}

type SpendRequest struct {
	SpendId          string   `json:"spend_id"`
	AccountId        string   `json:"account_id"`
	BudgetId         string   `json:"budget_id"`
	GrantId          string   `json:"grant_id"`
	RequesterAddress string   `json:"requester_address"`
	RecipientAddress string   `json:"recipient_address"`
	Amount           sdk.Coin `json:"amount"`
	Purpose          string   `json:"purpose"`
	Status           int32    `json:"status"`
	Reference        string   `json:"reference"`
	Memo             string   `json:"memo"`
	FundsExecuted    bool     `json:"funds_executed"`
	CreatedAt        int64    `json:"created_at"`
	UpdatedAt        int64    `json:"updated_at"`
	ApprovedAt       int64    `json:"approved_at"`
	ExecutedAt       int64    `json:"executed_at"`
	RejectedAt       int64    `json:"rejected_at"`
}

func NewSpendRequest(id, acctID, budgetID, grantID, requester, recipient string, amount sdk.Coin, purpose, ref, memo string, now int64) SpendRequest {
	return SpendRequest{id, acctID, budgetID, grantID, requester, recipient, amount, strings.TrimSpace(purpose), int32(SpendRequested), strings.TrimSpace(ref), strings.TrimSpace(memo), false, now, now, 0, 0, 0}
}
func (s *SpendRequest) ProtoMessage() {}
func (s *SpendRequest) Reset()        { *s = SpendRequest{} }
func (s *SpendRequest) String() string {
	return fmt.Sprintf("Spend{id=%s,amount=%s}", s.SpendId, s.Amount)
}

func (s SpendRequest) ValidateWithParams(p Params) error {
	if len(s.SpendId) < 3 || len(s.SpendId) > 80 {
		return fmt.Errorf("spend id: %w", ErrInvalidID)
	}
	if !idRegex.MatchString(s.SpendId) {
		return fmt.Errorf("id format: %w", ErrInvalidID)
	}
	if _, err := sdk.AccAddressFromBech32(s.RequesterAddress); err != nil {
		return fmt.Errorf("requester: %w", ErrInvalidRequester)
	}
	if _, err := sdk.AccAddressFromBech32(s.RecipientAddress); err != nil {
		return fmt.Errorf("recipient: %w", ErrInvalidRecipient)
	}
	if s.Amount.IsZero() || s.Amount.IsNegative() {
		return fmt.Errorf("amount: %w", ErrInvalidAmount)
	}
	if s.Amount.Denom == p.MinSpendAmount.Denom && s.Amount.IsLT(p.MinSpendAmount) {
		return fmt.Errorf("below min %s: %w", p.MinSpendAmount, ErrInvalidAmount)
	}
	if len(s.Purpose) > int(p.MaxPurposeLength) {
		return fmt.Errorf("purpose: %w", ErrInvalidParams)
	}
	if len(s.Memo) > int(p.MaxMemoLength) {
		return fmt.Errorf("memo: %w", ErrInvalidParams)
	}
	if !validSpendStatuses[s.Status] {
		return fmt.Errorf("status: %w", ErrInvalidStatus)
	}
	return nil
}
