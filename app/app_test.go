package app

import (
	"encoding/json"
	"testing"

	dbm "github.com/cometbft/cometbft-db"
	"github.com/cometbft/cometbft/libs/log"
	"github.com/stretchr/testify/require"

	"github.com/cosmos/cosmos-sdk/baseapp"
	servertypes "github.com/cosmos/cosmos-sdk/server/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	authtypes "github.com/cosmos/cosmos-sdk/x/auth/types"
)

func TestAppInitialization(t *testing.T) {
	app := setupTestApp(t)
	require.NotNil(t, app)
	require.Equal(t, "nexarail", app.Name())
}

func TestAppGenesis(t *testing.T) {
	genState := NewDefaultGenesisState()
	require.NotEmpty(t, genState)
	require.Contains(t, genState, "auth")
	require.Contains(t, genState, "bank")
	require.Contains(t, genState, "staking")
	require.Contains(t, genState, "gov")
	require.Contains(t, genState, "mint")
}

func TestAppInfo(t *testing.T) {
	app := setupTestApp(t)
	require.NotNil(t, app.AppCodec())
	require.NotNil(t, app.InterfaceRegistry())
	require.NotNil(t, app.TxConfig())
}

func TestAppServerType(t *testing.T) {
	app := setupTestApp(t)
	var _ servertypes.Application = app
}

func TestBech32Prefix(t *testing.T) {
	require.Equal(t, "nxr", AccountAddressPrefix)
}

func TestModuleBasics(t *testing.T) {
	expected := []string{
		"auth", "bank", "staking", "gov", "mint",
		"distribution", "slashing", "params", "crisis",
		"upgrade", "evidence", "feegrant", "authz",
		"capability", "vesting", "genutil",
	}
	bm := ModuleBasics
	for _, name := range expected {
		_, ok := bm[name]
		require.True(t, ok, "missing module: %s", name)
	}
}

func TestMaccPerms(t *testing.T) {
	perms := GetMaccPerms()
	require.Contains(t, perms, "fee_collector")
	require.Contains(t, perms, "bonded_tokens_pool")
	require.Contains(t, perms, "not_bonded_tokens_pool")
	require.Contains(t, perms, "gov")
	// Phase 5B: module account infrastructure
	require.Contains(t, perms, "nexarail_escrow")
	require.Contains(t, perms, "nexarail_treasury")
	require.Contains(t, perms, "nexarail_fee_router")
}

func TestModuleAccountPermissions(t *testing.T) {
	perms := GetMaccPerms()
	// Module accounts should have no special permissions
	require.Nil(t, perms["nexarail_escrow"])
	require.Nil(t, perms["nexarail_treasury"])
	require.Nil(t, perms["nexarail_fee_router"])
}

func TestBlockedAddrs(t *testing.T) {
	app := setupTestApp(t)
	addrs := app.ModuleAccountAddrs()
	// Verify module accounts are blocked from user sends
	require.Contains(t, addrs, authtypes.NewModuleAddress("nexarail_escrow").String())
	require.Contains(t, addrs, authtypes.NewModuleAddress("nexarail_treasury").String())
	require.Contains(t, addrs, authtypes.NewModuleAddress("nexarail_fee_router").String())
}

func TestAccountAddress(t *testing.T) {
	addr := sdk.AccAddress("testaddress12345")
	bech32, err := sdk.Bech32ifyAddressBytes("nxr", addr)
	require.NoError(t, err)
	require.Contains(t, bech32, "nxr")
}

func TestDefaultGenesisValidJSON(t *testing.T) {
	genState := NewDefaultGenesisState()
	jsonBytes, err := json.Marshal(genState)
	require.NoError(t, err)
	require.NotEmpty(t, jsonBytes)

	// Unmarshal back to verify
	var decoded GenesisState
	err = json.Unmarshal(jsonBytes, &decoded)
	require.NoError(t, err)
	require.NotEmpty(t, decoded)
}

func setupTestApp(t *testing.T) *NexaRailApp {
	t.Helper()
	db := dbm.NewMemDB()
	logger := log.NewNopLogger()

	encodingConfig := MakeEncodingConfig()
	RegisterInterfaces(encodingConfig.InterfaceRegistry)

	return NewNexaRailApp(
		logger,
		db,
		nil,
		true,
		nil,
		"",
		0,
		encodingConfig,
		nil,
		baseapp.SetChainID("nexarail-devnet-1"),
	)
}
