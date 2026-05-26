package types

const (
	// ModuleName defines the module name
	ModuleName = "fees"

	// StoreKey defines the primary store key
	StoreKey = ModuleName

	// RouterKey is the message route for the fees module
	RouterKey = ModuleName

	// QuerierRoute is the querier route for the fees module
	QuerierRoute = ModuleName
)

// KV store keys
var (
	ParamsKey = []byte{0x01} // key for module params
)

// PrefixForParam returns the store key prefix for a specific param key.
func PrefixForParam(param []byte) []byte {
	return append(ParamsKey, param...)
}
