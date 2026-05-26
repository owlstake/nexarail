package types

import (
	"fmt"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"strings"
)

type BudgetStatus int32

const (
	BudgetUnspecified BudgetStatus = 0
	BudgetDraft       BudgetStatus = 1
	BudgetActive      BudgetStatus = 2
	BudgetPaused      BudgetStatus = 3
	BudgetClosed      BudgetStatus = 4
)

func (s BudgetStatus) String() string {
	switch s {
	case BudgetDraft:
		return "draft"
	case BudgetActive:
		return "active"
	case BudgetPaused:
		return "paused"
	case BudgetClosed:
		return "closed"
	default:
		return "unspecified"
	}
}

var validBudgetStatuses = map[int32]bool{0: true, 1: true, 2: true, 3: true, 4: true}

func IsValidBudgetStatus(s int32) bool { return validBudgetStatuses[s] }

type Budget struct {
	BudgetId        string   `json:"budget_id"`
	AccountId       string   `json:"account_id"`
	Category        int32    `json:"category"`
	Title           string   `json:"title"`
	Description     string   `json:"description"`
	TotalAmount     sdk.Coin `json:"total_amount"`
	AllocatedAmount sdk.Coin `json:"allocated_amount"`
	SpentAmount     sdk.Coin `json:"spent_amount"`
	Status          int32    `json:"status"`
	StartTime       int64    `json:"start_time"`
	EndTime         int64    `json:"end_time"`
	MetadataUri     string   `json:"metadata_uri"`
	CreatedAt       int64    `json:"created_at"`
	UpdatedAt       int64    `json:"updated_at"`
}

func NewBudget(id, acctID string, cat int32, title, desc string, total sdk.Coin, start, end int64, uri string, now int64) Budget {
	return Budget{id, acctID, cat, strings.TrimSpace(title), strings.TrimSpace(desc), total, sdk.NewInt64Coin(total.Denom, 0), sdk.NewInt64Coin(total.Denom, 0), int32(BudgetActive), start, end, strings.TrimSpace(uri), now, now}
}
func (b *Budget) ProtoMessage() {}
func (b *Budget) Reset()        { *b = Budget{} }
func (b *Budget) String() string {
	return fmt.Sprintf("Budget{id=%s,total=%s}", b.BudgetId, b.TotalAmount)
}

func (b Budget) ValidateWithParams(p Params) error {
	if len(b.BudgetId) < 3 || len(b.BudgetId) > 80 {
		return fmt.Errorf("budget id: %w", ErrInvalidID)
	}
	if !idRegex.MatchString(b.BudgetId) {
		return fmt.Errorf("id format: %w", ErrInvalidID)
	}
	if strings.TrimSpace(b.Title) == "" {
		return fmt.Errorf("title: %w", ErrInvalidParams)
	}
	if len(b.Title) > int(p.MaxNameLength) {
		return fmt.Errorf("title too long: %w", ErrInvalidParams)
	}
	if len(b.Description) > int(p.MaxDescriptionLength) {
		return fmt.Errorf("desc too long: %w", ErrInvalidParams)
	}
	if b.TotalAmount.IsZero() || b.TotalAmount.IsNegative() {
		return fmt.Errorf("total: %w", ErrInvalidAmount)
	}
	if b.AllocatedAmount.IsNegative() || b.SpentAmount.IsNegative() {
		return fmt.Errorf("alloc/spent negative: %w", ErrInvalidAmount)
	}
	if b.AllocatedAmount.Add(b.SpentAmount).Amount.GT(b.TotalAmount.Amount) {
		return fmt.Errorf("alloc+spent > total: %w", ErrInvalidAmount)
	}
	if !validBudgetStatuses[b.Status] {
		return fmt.Errorf("status: %w", ErrInvalidStatus)
	}
	if b.StartTime != 0 && b.EndTime != 0 && b.StartTime >= b.EndTime {
		return fmt.Errorf("start>=end: %w", ErrInvalidParams)
	}
	return nil
}
