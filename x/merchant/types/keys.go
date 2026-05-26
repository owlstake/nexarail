package types

const (
	ModuleName   = "merchant"
	StoreKey     = ModuleName
	RouterKey    = ModuleName
	QuerierRoute = ModuleName
)

// KV store key prefixes
var (
	// ParamsKey stores the module parameters.
	ParamsKey = []byte{0x01}
	// MerchantKeyPrefix stores merchant records.
	MerchantKeyPrefix = []byte{0x02}
)

// MerchantKey returns the store key for a merchant by owner address.
func MerchantKey(owner []byte) []byte {
	return append(MerchantKeyPrefix, owner...)
}
