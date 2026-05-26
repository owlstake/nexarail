package cmd

import (
	"encoding/json"
	"fmt"

	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/client/flags"
	"github.com/cosmos/cosmos-sdk/crypto/keyring"
	"github.com/cosmos/cosmos-sdk/server"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/x/genutil"
	genutiltypes "github.com/cosmos/cosmos-sdk/x/genutil/types"
	"github.com/spf13/cobra"

	authtypes "github.com/cosmos/cosmos-sdk/x/auth/types"
	banktypes "github.com/cosmos/cosmos-sdk/x/bank/types"
)

// AddGenesisAccountCmd returns add-genesis-account cobra Command.
func AddGenesisAccountCmd(homeDir string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "add-genesis-account [address_or_key_name] [coin][,coin]",
		Short: "Add a genesis account to genesis.json",
		Args:  cobra.ExactArgs(2),
		RunE: func(cmd *cobra.Command, args []string) error {
			clientCtx := client.GetClientContextFromCmd(cmd)
			cdc := clientCtx.Codec
			serverCtx := server.GetServerContextFromCmd(cmd)
			config := serverCtx.Config
			config.SetRoot(clientCtx.HomeDir)

			addr, err := sdk.AccAddressFromBech32(args[0])
			if err != nil {
				// try keyring
				kr, err := keyring.New(sdk.KeyringServiceName(), "test", clientCtx.HomeDir, clientCtx.Input, cdc)
				if err != nil {
					return fmt.Errorf("address not found: %w", err)
				}
				info, err := kr.Key(args[0])
				if err != nil {
					return fmt.Errorf("address '%s' not found: %w", args[0], err)
				}
				addr, err = info.GetAddress()
				if err != nil {
					return err
				}
			}

			coins, err := sdk.ParseCoinsNormalized(args[1])
			if err != nil {
				return fmt.Errorf("failed to parse coins: %w", err)
			}

			genFile := config.GenesisFile()
			appState, genDoc, err := genutiltypes.GenesisStateFromGenFile(genFile)
			if err != nil {
				return fmt.Errorf("failed to read genesis file: %w", err)
			}

			// auth genesis
			authGenState := authtypes.GetGenesisStateFromAppState(cdc, appState)

			baseAcc := authtypes.NewBaseAccount(addr, nil, 0, 0)
			packedAccs, err := authtypes.PackAccounts(authtypes.GenesisAccounts{baseAcc})
			if err != nil {
				return fmt.Errorf("failed to pack account: %w", err)
			}
			authGenState.Accounts = append(authGenState.Accounts, packedAccs...)

			authGenStateBz, err := cdc.MarshalJSON(&authGenState)
			if err != nil {
				return err
			}
			appState[authtypes.ModuleName] = authGenStateBz

			// bank genesis
			bankGenState := banktypes.GetGenesisStateFromAppState(cdc, appState)
			bankGenState.Balances = append(bankGenState.Balances, banktypes.Balance{
				Address: addr.String(),
				Coins:   coins,
			})
			bankGenState.Balances = banktypes.SanitizeGenesisBalances(bankGenState.Balances)
			bankGenState.Supply = bankGenState.Supply.Add(coins...)

			bankGenStateBz, err := cdc.MarshalJSON(bankGenState)
			if err != nil {
				return err
			}
			appState[banktypes.ModuleName] = bankGenStateBz

			appStateJSON, err := json.Marshal(appState)
			if err != nil {
				return err
			}
			genDoc.AppState = appStateJSON

			return genutil.ExportGenesisFile(genDoc, genFile)
		},
	}

	cmd.Flags().String(flags.FlagHome, homeDir, "The application home directory")
	return cmd
}
