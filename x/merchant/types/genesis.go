package types

import (
	"fmt"
)

// GenesisState defines the genesis state for the merchant module.
type GenesisState struct {
	Params    Params     `json:"params" yaml:"params"`
	Merchants []Merchant `json:"merchants" yaml:"merchants"`
}

// NewGenesisState creates a new GenesisState.
func NewGenesisState(params Params, merchants []Merchant) *GenesisState {
	return &GenesisState{Params: params, Merchants: merchants}
}

// DefaultGenesis returns the default genesis state.
func DefaultGenesis() *GenesisState {
	return &GenesisState{
		Params:    DefaultParams(),
		Merchants: []Merchant{},
	}
}

// ProtoMessage implements proto.Message.
func (gs *GenesisState) ProtoMessage() {}
func (gs *GenesisState) Reset()        { *gs = GenesisState{} }
func (gs *GenesisState) String() string {
	return fmt.Sprintf("GenesisState{merchants=%d}", len(gs.Merchants))
}

// Validate performs validation of the genesis state.
func (gs GenesisState) Validate() error {
	if err := gs.Params.Validate(); err != nil {
		return fmt.Errorf("merchant genesis params: %w", err)
	}
	seen := make(map[string]bool, len(gs.Merchants))
	for i, m := range gs.Merchants {
		if _, ok := seen[m.Owner]; ok {
			return fmt.Errorf("duplicate merchant owner at index %d: %s", i, m.Owner)
		}
		seen[m.Owner] = true
		if err := m.Validate(); err != nil {
			return fmt.Errorf("merchant %d: %w", i, err)
		}
	}
	return nil
}
