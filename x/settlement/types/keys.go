package types

const (
	ModuleName = "settlement"
	StoreKey   = ModuleName
	RouterKey  = ModuleName
)

var (
	ParamsKey           = []byte{0x01}
	SettlementKeyPrefix = []byte{0x02}
	SettlementCountKey  = []byte{0x03}
)

// SettlementKey builds a settlement store key from its ID (big-endian uint64).
func SettlementKey(id uint64) []byte {
	bz := make([]byte, 8)
	bz[0] = byte(id >> 56)
	bz[1] = byte(id >> 48)
	bz[2] = byte(id >> 40)
	bz[3] = byte(id >> 32)
	bz[4] = byte(id >> 24)
	bz[5] = byte(id >> 16)
	bz[6] = byte(id >> 8)
	bz[7] = byte(id)
	return append(SettlementKeyPrefix, bz...)
}
