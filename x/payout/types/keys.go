package types

const (
	ModuleName = "payout"
	StoreKey   = ModuleName
	RouterKey  = ModuleName

	// TreasuryModuleAccount is the module account that funds live payouts in v1.
	// MUST match app.NexaRailTreasuryModuleAccount and x/treasury
	// TreasuryModuleAccount ("nexarail_treasury"). Defined locally to avoid a
	// payout -> treasury module dependency.
	TreasuryModuleAccount = "nexarail_treasury"
)

var (
	ParamsKey            = []byte{0x01}
	PayoutKeyPrefix      = []byte{0x02}
	BatchPayoutKeyPrefix = []byte{0x03}
)

func PayoutKey(id string) []byte      { return append(PayoutKeyPrefix, []byte(id)...) }
func BatchPayoutKey(id string) []byte { return append(BatchPayoutKeyPrefix, []byte(id)...) }
func PayoutByMerchantKey(m, id string) []byte {
	return append(append([]byte{0x11}, []byte(m)...), []byte(id)...)
}
func PayoutByRecipientKey(r, id string) []byte {
	return append(append([]byte{0x12}, []byte(r)...), []byte(id)...)
}
func PayoutByInitiatorKey(i, id string) []byte {
	return append(append([]byte{0x13}, []byte(i)...), []byte(id)...)
}
