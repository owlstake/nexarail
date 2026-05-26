package types

const (
	ModuleName = "escrow"
	StoreKey   = ModuleName
	RouterKey  = ModuleName
)

var (
	ParamsKey       = []byte{0x01}
	EscrowKeyPrefix = []byte{0x02}
	EscrowCountKey  = []byte{0x03}
)

// EscrowKey stores an escrow by its string ID.
func EscrowKey(escrowID string) []byte {
	return append(EscrowKeyPrefix, []byte(escrowID)...)
}

// Index prefixes
var (
	EscrowByBuyerPrefix    = []byte{0x11}
	EscrowBySellerPrefix   = []byte{0x12}
	EscrowByMerchantPrefix = []byte{0x13}
)

func EscrowByBuyerKey(buyer, escrowID string) []byte {
	return append(append(EscrowByBuyerPrefix, []byte(buyer)...), []byte(escrowID)...)
}

func EscrowBySellerKey(seller, escrowID string) []byte {
	return append(append(EscrowBySellerPrefix, []byte(seller)...), []byte(escrowID)...)
}

func EscrowByMerchantKey(merchantID, escrowID string) []byte {
	return append(append(EscrowByMerchantPrefix, []byte(merchantID)...), []byte(escrowID)...)
}
