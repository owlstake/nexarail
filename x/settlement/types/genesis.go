package types

import (
	"fmt"
)

// GenesisState defines the genesis state for the settlement module.
type GenesisState struct {
	Params      Params       `json:"params" yaml:"params"`
	Settlements []Settlement `json:"settlements" yaml:"settlements"`
}

func NewGenesisState(params Params, settlements []Settlement) *GenesisState {
	return &GenesisState{Params: params, Settlements: settlements}
}

func DefaultGenesis() *GenesisState {
	return &GenesisState{
		Params:      DefaultParams(),
		Settlements: []Settlement{},
	}
}

func (gs *GenesisState) ProtoMessage() {}
func (gs *GenesisState) Reset()        { *gs = GenesisState{} }
func (gs *GenesisState) String() string {
	return fmt.Sprintf("GenesisState{settlements=%d}", len(gs.Settlements))
}

// Validate performs validation of the genesis state.
func (gs GenesisState) Validate() error {
	if err := gs.Params.Validate(); err != nil {
		return fmt.Errorf("settlement genesis params: %w", err)
	}
	for i, s := range gs.Settlements {
		if err := s.Validate(); err != nil {
			return fmt.Errorf("settlement %d: %w", i, err)
		}
	}
	return nil
}
