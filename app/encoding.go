package app

import (
	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/codec"
	"github.com/cosmos/cosmos-sdk/codec/types"
	cryptocodec "github.com/cosmos/cosmos-sdk/crypto/codec"
	"github.com/cosmos/cosmos-sdk/std"
	"github.com/cosmos/cosmos-sdk/x/auth/tx"
)

// EncodingConfig specifies the concrete encoding types to use for the NexaRail chain.
type EncodingConfig struct {
	InterfaceRegistry types.InterfaceRegistry
	Codec             codec.Codec
	TxConfig          client.TxConfig
	Amino             *codec.LegacyAmino
}

// MakeEncodingConfig creates an EncodingConfig for testing or CLI usage.
func MakeEncodingConfig() EncodingConfig {
	// Set Bech32 prefix early so all CLI commands (keys, gentx, etc.) use nxr.
	SetBech32Prefix()

	cdc := codec.NewLegacyAmino()
	interfaceRegistry := types.NewInterfaceRegistry()
	marshaler := codec.NewProtoCodec(interfaceRegistry)

	txCfg := tx.NewTxConfig(marshaler, tx.DefaultSignModes)

	// Register crypto types for keyring support (secp256k1, ed25519 pubkeys).
	cryptocodec.RegisterInterfaces(interfaceRegistry)
	cryptocodec.RegisterCrypto(cdc)

	// Register all module interfaces so CLI commands (add-genesis-account,
	// gentx, etc.) can resolve proto type URLs.
	RegisterInterfaces(interfaceRegistry)

	return EncodingConfig{
		InterfaceRegistry: interfaceRegistry,
		Codec:             marshaler,
		TxConfig:          txCfg,
		Amino:             cdc,
	}
}

// RegisterInterfaces registers the module interfaces with the interface registry.
func RegisterInterfaces(registry types.InterfaceRegistry) {
	std.RegisterInterfaces(registry)
	ModuleBasics.RegisterInterfaces(registry)
}
