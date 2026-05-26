package types

import "fmt"

type GenesisState struct {
	Params        Params            `json:"params"`
	Accounts      []TreasuryAccount `json:"accounts"`
	Budgets       []Budget          `json:"budgets"`
	Grants        []Grant           `json:"grants"`
	SpendRequests []SpendRequest    `json:"spend_requests"`
}

func DefaultGenesis() *GenesisState    { return &GenesisState{Params: DefaultParams()} }
func (gs *GenesisState) ProtoMessage() {}
func (gs *GenesisState) Reset()        { *gs = GenesisState{} }
func (gs *GenesisState) String() string {
	return fmt.Sprintf("Genesis{accts=%d,budgets=%d,grants=%d,spends=%d}", len(gs.Accounts), len(gs.Budgets), len(gs.Grants), len(gs.SpendRequests))
}

func (gs GenesisState) Validate() error {
	if err := gs.Params.Validate(); err != nil {
		return err
	}
	seen := make(map[string]bool)
	for i, a := range gs.Accounts {
		if seen[a.AccountId] {
			return fmt.Errorf("dup account %s at %d", a.AccountId, i)
		}
		seen[a.AccountId] = true
		if err := a.ValidateWithParams(gs.Params); err != nil {
			return err
		}
	}
	seen = make(map[string]bool)
	for i, b := range gs.Budgets {
		if seen[b.BudgetId] {
			return fmt.Errorf("dup budget %s at %d", b.BudgetId, i)
		}
		seen[b.BudgetId] = true
		if err := b.ValidateWithParams(gs.Params); err != nil {
			return err
		}
	}
	seen = make(map[string]bool)
	for i, g := range gs.Grants {
		if seen[g.GrantId] {
			return fmt.Errorf("dup grant %s at %d", g.GrantId, i)
		}
		seen[g.GrantId] = true
		if err := g.ValidateWithParams(gs.Params); err != nil {
			return err
		}
	}
	seen = make(map[string]bool)
	for i, s := range gs.SpendRequests {
		if seen[s.SpendId] {
			return fmt.Errorf("dup spend %s at %d", s.SpendId, i)
		}
		seen[s.SpendId] = true
		if err := s.ValidateWithParams(gs.Params); err != nil {
			return err
		}
	}
	return nil
}
