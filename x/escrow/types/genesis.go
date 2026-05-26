package types

import "fmt"

type GenesisState struct {
	Params  Params   `json:"params" yaml:"params"`
	Escrows []Escrow `json:"escrows" yaml:"escrows"`
}

func NewGenesisState(p Params, escrows []Escrow) *GenesisState {
	return &GenesisState{Params: p, Escrows: escrows}
}
func DefaultGenesis() *GenesisState {
	return &GenesisState{Params: DefaultParams(), Escrows: []Escrow{}}
}

func (gs *GenesisState) ProtoMessage() {}
func (gs *GenesisState) Reset()        { *gs = GenesisState{} }
func (gs *GenesisState) String() string {
	return fmt.Sprintf("GenesisState{escrows=%d}", len(gs.Escrows))
}

func (gs GenesisState) Validate() error {
	if err := gs.Params.Validate(); err != nil {
		return fmt.Errorf("escrow genesis params: %w", err)
	}
	seen := make(map[string]bool, len(gs.Escrows))
	for i, e := range gs.Escrows {
		if seen[e.EscrowId] {
			return fmt.Errorf("duplicate escrow_id %s at index %d", e.EscrowId, i)
		}
		seen[e.EscrowId] = true
		if err := e.ValidateWithParams(gs.Params); err != nil {
			return fmt.Errorf("escrow %s: %w", e.EscrowId, err)
		}
	}
	return nil
}
