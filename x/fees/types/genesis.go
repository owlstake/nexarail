package types

import "fmt"

// GenesisState defines the genesis state for the fees module.
type GenesisState struct {
	Params Params `json:"params" yaml:"params"`
}

// NewGenesisState creates a new GenesisState instance.
func NewGenesisState(params Params) GenesisState {
	return GenesisState{Params: params}
}

// DefaultGenesis returns the default fees module genesis state.
func DefaultGenesis() *GenesisState {
	return &GenesisState{
		Params: DefaultParams(),
	}
}

// proto.Message interface
func (gs *GenesisState) ProtoMessage()  {}
func (gs *GenesisState) Reset()         { *gs = GenesisState{} }
func (gs *GenesisState) String() string { return fmt.Sprintf("GenesisState{%v}", gs.Params) }

// Validate performs basic validation of the genesis state.
func (gs GenesisState) Validate() error {
	if err := gs.Params.Validate(); err != nil {
		return fmt.Errorf("fees genesis params: %w", err)
	}
	return nil
}
