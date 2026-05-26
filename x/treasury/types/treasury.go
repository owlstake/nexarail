package types

import (
	"fmt"
	"regexp"
	"strings"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

var idRegex = regexp.MustCompile(`^[a-z0-9][a-z0-9\-]{1,78}[a-z0-9]$`)

type TreasuryCategory int32

const (
	CategoryUnspecified TreasuryCategory = 0
	CategoryProtocol    TreasuryCategory = 1
	CategoryGrants      TreasuryCategory = 2
	CategorySecurity    TreasuryCategory = 3
	CategoryLiquidity   TreasuryCategory = 4
	CategoryMarketing   TreasuryCategory = 5
	CategoryOperations  TreasuryCategory = 6
	CategoryRiskReserve TreasuryCategory = 7
	CategoryEcosystem   TreasuryCategory = 8
)

func (c TreasuryCategory) String() string {
	switch c {
	case CategoryProtocol:
		return "protocol"
	case CategoryGrants:
		return "grants"
	case CategorySecurity:
		return "security"
	case CategoryLiquidity:
		return "liquidity"
	case CategoryMarketing:
		return "marketing"
	case CategoryOperations:
		return "operations"
	case CategoryRiskReserve:
		return "risk_reserve"
	case CategoryEcosystem:
		return "ecosystem"
	default:
		return "unspecified"
	}
}

var validCategories = map[int32]bool{0: true, 1: true, 2: true, 3: true, 4: true, 5: true, 6: true, 7: true, 8: true}

type TreasuryAccount struct {
	AccountId      string   `json:"account_id"`
	Category       int32    `json:"category"`
	Name           string   `json:"name"`
	Description    string   `json:"description"`
	MetadataUri    string   `json:"metadata_uri"`
	NominalBalance sdk.Coin `json:"nominal_balance"`
	CreatedAt      int64    `json:"created_at"`
	UpdatedAt      int64    `json:"updated_at"`
}

func NewTreasuryAccount(id string, cat int32, name, desc, uri string, balance sdk.Coin, now int64) TreasuryAccount {
	return TreasuryAccount{id, cat, strings.TrimSpace(name), strings.TrimSpace(desc), strings.TrimSpace(uri), balance, now, now}
}
func (a *TreasuryAccount) ProtoMessage() {}
func (a *TreasuryAccount) Reset()        { *a = TreasuryAccount{} }
func (a *TreasuryAccount) String() string {
	return fmt.Sprintf("Account{id=%s,cat=%d}", a.AccountId, a.Category)
}

func (a TreasuryAccount) ValidateWithParams(p Params) error {
	if len(a.AccountId) < 3 || len(a.AccountId) > 80 {
		return fmt.Errorf("account id: %w", ErrInvalidID)
	}
	if !idRegex.MatchString(a.AccountId) {
		return fmt.Errorf("id format: %w", ErrInvalidID)
	}
	if !validCategories[a.Category] {
		return fmt.Errorf("category %d: %w", a.Category, ErrInvalidCategory)
	}
	if strings.TrimSpace(a.Name) == "" {
		return fmt.Errorf("name: %w", ErrInvalidParams)
	}
	if len(a.Name) > int(p.MaxNameLength) {
		return fmt.Errorf("name too long: %w", ErrInvalidParams)
	}
	if len(a.Description) > int(p.MaxDescriptionLength) {
		return fmt.Errorf("desc too long: %w", ErrInvalidParams)
	}
	if len(a.MetadataUri) > int(p.MaxMetadataUriLength) {
		return fmt.Errorf("uri too long: %w", ErrInvalidParams)
	}
	if a.NominalBalance.IsNegative() {
		return fmt.Errorf("balance negative: %w", ErrInvalidAmount)
	}
	return nil
}
