package types

import "fmt"

type GenesisState struct {
	Params       Params        `json:"params"`
	Payouts      []Payout      `json:"payouts"`
	BatchPayouts []BatchPayout `json:"batch_payouts"`
}

func NewGenesisState(p Params, payouts []Payout, batches []BatchPayout) *GenesisState {
	return &GenesisState{p, payouts, batches}
}
func DefaultGenesis() *GenesisState    { return &GenesisState{Params: DefaultParams()} }
func (gs *GenesisState) ProtoMessage() {}
func (gs *GenesisState) Reset()        { *gs = GenesisState{} }
func (gs *GenesisState) String() string {
	return fmt.Sprintf("Genesis{payouts=%d,batches=%d}", len(gs.Payouts), len(gs.BatchPayouts))
}

func (gs GenesisState) Validate() error {
	if err := gs.Params.Validate(); err != nil {
		return fmt.Errorf("payout params: %w", err)
	}
	seen := make(map[string]bool)
	for i, p := range gs.Payouts {
		if seen[p.PayoutId] {
			return fmt.Errorf("duplicate payout %s at %d", p.PayoutId, i)
		}
		seen[p.PayoutId] = true
		if err := p.ValidateWithParams(gs.Params); err != nil {
			return fmt.Errorf("payout %s: %w", p.PayoutId, err)
		}
	}
	bseen := make(map[string]bool)
	for i, b := range gs.BatchPayouts {
		if bseen[b.BatchId] {
			return fmt.Errorf("duplicate batch %s at %d", b.BatchId, i)
		}
		bseen[b.BatchId] = true
		if err := b.ValidateWithParams(gs.Params); err != nil {
			return fmt.Errorf("batch %s: %w", b.BatchId, err)
		}
	}
	return nil
}
