package types

import (
	"fmt"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"strings"
)

type GrantStatus int32

const (
	GrantUnspecified GrantStatus = 0
	GrantProposed    GrantStatus = 1
	GrantApproved    GrantStatus = 2
	GrantRejected    GrantStatus = 3
	GrantActive      GrantStatus = 4
	GrantCompleted   GrantStatus = 5
	GrantCancelled   GrantStatus = 6
)

func (s GrantStatus) String() string {
	switch s {
	case GrantProposed:
		return "proposed"
	case GrantApproved:
		return "approved"
	case GrantRejected:
		return "rejected"
	case GrantActive:
		return "active"
	case GrantCompleted:
		return "completed"
	case GrantCancelled:
		return "cancelled"
	default:
		return "unspecified"
	}
}

var validGrantStatuses = map[int32]bool{0: true, 1: true, 2: true, 3: true, 4: true, 5: true, 6: true}

func IsValidGrantStatus(s int32) bool { return validGrantStatuses[s] }

type Grant struct {
	GrantId             string   `json:"grant_id"`
	BudgetId            string   `json:"budget_id"`
	RecipientAddress    string   `json:"recipient_address"`
	Title               string   `json:"title"`
	Description         string   `json:"description"`
	Amount              sdk.Coin `json:"amount"`
	Status              int32    `json:"status"`
	MilestoneCount      uint32   `json:"milestone_count"`
	CompletedMilestones uint32   `json:"completed_milestones"`
	MetadataUri         string   `json:"metadata_uri"`
	CreatedAt           int64    `json:"created_at"`
	UpdatedAt           int64    `json:"updated_at"`
	ApprovedAt          int64    `json:"approved_at"`
	CompletedAt         int64    `json:"completed_at"`
}

func NewGrant(id, budgetID, recipient, title, desc string, amount sdk.Coin, milestones uint32, uri string, now int64) Grant {
	return Grant{id, budgetID, recipient, strings.TrimSpace(title), strings.TrimSpace(desc), amount, int32(GrantApproved), milestones, 0, uri, now, now, now, 0}
}
func (g *Grant) ProtoMessage()  {}
func (g *Grant) Reset()         { *g = Grant{} }
func (g *Grant) String() string { return fmt.Sprintf("Grant{id=%s,amount=%s}", g.GrantId, g.Amount) }

func (g Grant) ValidateWithParams(p Params) error {
	if len(g.GrantId) < 3 || len(g.GrantId) > 80 {
		return fmt.Errorf("grant id: %w", ErrInvalidID)
	}
	if !idRegex.MatchString(g.GrantId) {
		return fmt.Errorf("id format: %w", ErrInvalidID)
	}
	if _, err := sdk.AccAddressFromBech32(g.RecipientAddress); err != nil {
		return fmt.Errorf("recipient: %w", ErrInvalidRecipient)
	}
	if strings.TrimSpace(g.Title) == "" {
		return fmt.Errorf("title: %w", ErrInvalidParams)
	}
	if len(g.Title) > int(p.MaxNameLength) {
		return fmt.Errorf("title too long: %w", ErrInvalidParams)
	}
	if g.Amount.IsZero() || g.Amount.IsNegative() {
		return fmt.Errorf("amount: %w", ErrInvalidAmount)
	}
	if !validGrantStatuses[g.Status] {
		return fmt.Errorf("status: %w", ErrInvalidStatus)
	}
	return nil
}
