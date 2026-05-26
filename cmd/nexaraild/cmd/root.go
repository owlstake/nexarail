package cmd

import (
	"io"
	"os"
	"path/filepath"

	dbm "github.com/cometbft/cometbft-db"
	tmconfig "github.com/cometbft/cometbft/config"
	"github.com/cometbft/cometbft/libs/log"
	tmtypes "github.com/cometbft/cometbft/types"
	"github.com/spf13/cobra"

	"github.com/cosmos/cosmos-sdk/baseapp"
	sdkclient "github.com/cosmos/cosmos-sdk/client"
	clientconfig "github.com/cosmos/cosmos-sdk/client/config"
	"github.com/cosmos/cosmos-sdk/client/flags"
	"github.com/cosmos/cosmos-sdk/client/keys"
	"github.com/cosmos/cosmos-sdk/client/rpc"
	"github.com/cosmos/cosmos-sdk/server"
	servertypes "github.com/cosmos/cosmos-sdk/server/types"
	"github.com/cosmos/cosmos-sdk/x/auth/types"
	banktypes "github.com/cosmos/cosmos-sdk/x/bank/types"
	genutilcli "github.com/cosmos/cosmos-sdk/x/genutil/client/cli"
	genutiltypes "github.com/cosmos/cosmos-sdk/x/genutil/types"

	"github.com/nexarail/chain/app"
	escrowcli "github.com/nexarail/chain/x/escrow/client/cli"
	feescli "github.com/nexarail/chain/x/fees/client/cli"
	merchantcli "github.com/nexarail/chain/x/merchant/client/cli"
	payoutcli "github.com/nexarail/chain/x/payout/client/cli"
	settlementcli "github.com/nexarail/chain/x/settlement/client/cli"
	treasurycli "github.com/nexarail/chain/x/treasury/client/cli"
)

func NewRootCmd() *cobra.Command {
	rootCmd := &cobra.Command{
		Use:   "nexaraild",
		Short: "NexaRail blockchain daemon",
		Long: `NexaRail is a sovereign Layer 1 blockchain for railway settlement and payments.

Built on Cosmos SDK, NexaRail provides a decentralised payment protocol for the rail industry
with capabilities for merchant settlement, fee splitting, escrow, and treasury management.`,
		PersistentPreRunE: func(cmd *cobra.Command, _ []string) error {
			cmd.SetOut(cmd.OutOrStdout())
			cmd.SetErr(cmd.ErrOrStderr())

			encodingConfig := app.MakeEncodingConfig()

			// Base client context. Home is resolved from --home (or default).
			clientCtx := sdkclient.Context{}.
				WithCodec(encodingConfig.Codec).
				WithInterfaceRegistry(encodingConfig.InterfaceRegistry).
				WithTxConfig(encodingConfig.TxConfig).
				WithLegacyAmino(encodingConfig.Amino).
				WithInput(os.Stdin).
				WithAccountRetriever(types.AccountRetriever{}).
				WithHomeDir(app.DefaultNodeHome).
				WithViper("")

			// Apply persistent CLI flags (--home, --chain-id, --node, etc.),
			// then merge in values from client.toml. ReadFromClientConfig
			// creates the config dir and a default client.toml when missing,
			// so bootstrap commands (init, keys, gentx) work from a fresh home.
			clientCtx, err := sdkclient.ReadPersistentCommandFlags(clientCtx, cmd.Flags())
			if err != nil {
				return err
			}

			clientCtx, err = clientconfig.ReadFromClientConfig(clientCtx)
			if err != nil {
				return err
			}

			if err := sdkclient.SetCmdClientContextHandler(clientCtx, cmd); err != nil {
				return err
			}

			// Load config.toml and app.toml from disk into the server context.
			// This is what applies p2p.persistent_peers, p2p.laddr, rpc.laddr,
			// addr_book_strict and allow_duplicate_ip to the running node.
			// InterceptConfigsPreRunHandler writes default files when they don't
			// exist, so bootstrap commands are safe here too.
			return server.InterceptConfigsPreRunHandler(cmd, "", nil, tmconfig.DefaultConfig())
		},
	}

	rootCmd.PersistentFlags().String(flags.FlagLogLevel, "info", "log level")
	rootCmd.PersistentFlags().String(flags.FlagLogFormat, "plain", "log format")
	rootCmd.PersistentFlags().String(flags.FlagChainID, "nexarail-devnet-1", "chain ID")
	rootCmd.PersistentFlags().String(flags.FlagHome, app.DefaultNodeHome, "directory for config and data")

	rootCmd.AddCommand(
		genutilcli.InitCmd(app.ModuleBasics, app.DefaultNodeHome),
		genutilcli.CollectGenTxsCmd(banktypes.GenesisBalancesIterator{}, app.DefaultNodeHome, genutiltypes.DefaultMessageValidator),
		genutilcli.GenTxCmd(app.ModuleBasics, app.MakeEncodingConfig().TxConfig, banktypes.GenesisBalancesIterator{}, app.DefaultNodeHome),
		genutilcli.MigrateGenesisCmd(),
		genutilcli.ValidateGenesisCmd(app.ModuleBasics),
		AddGenesisAccountCmd(app.DefaultNodeHome),
		keys.Commands(app.DefaultNodeHome),
		server.StartCmd(newAppCreator(), app.DefaultNodeHome),
		server.ExportCmd(exportAppStateAndValidators, app.DefaultNodeHome),
		server.VersionCmd(),
		DebugP2PConfigCmd(),
		rpc.StatusCommand(),
		rpc.ValidatorCommand(),
		rpc.BlockCommand(),
		queryCommand(),
		txCommand(),
	)

	return rootCmd
}

func newAppCreator() servertypes.AppCreator {
	return func(logger log.Logger, db dbm.DB, traceStore io.Writer, appOpts servertypes.AppOptions) servertypes.Application {
		homePath, ok := appOpts.Get(flags.FlagHome).(string)
		if !ok || homePath == "" {
			homePath = app.DefaultNodeHome
		}

		encodingConfig := app.MakeEncodingConfig()
		app.RegisterInterfaces(encodingConfig.InterfaceRegistry)

		// Read chain ID from genesis.json so BaseApp.InitChain validates correctly.
		genFile := filepath.Join(homePath, "config", "genesis.json")
		chainID := ""
		if genDoc, err := tmtypes.GenesisDocFromFile(genFile); err == nil {
			chainID = genDoc.ChainID
		}

		baseAppOpts := []func(*baseapp.BaseApp){baseapp.SetChainID(chainID)}

		return app.NewNexaRailApp(
			logger,
			db,
			traceStore,
			true,
			nil,
			homePath,
			0,
			encodingConfig,
			appOpts,
			baseAppOpts...,
		)
	}
}

func exportAppStateAndValidators(
	logger log.Logger,
	db dbm.DB,
	traceStore io.Writer,
	height int64,
	forZeroHeight bool,
	jailAllowedAddrs []string,
	appOpts servertypes.AppOptions,
	modulesToExport []string,
) (servertypes.ExportedApp, error) {
	homePath, ok := appOpts.Get(flags.FlagHome).(string)
	if !ok || homePath == "" {
		homePath = app.DefaultNodeHome
	}

	encodingConfig := app.MakeEncodingConfig()
	app.RegisterInterfaces(encodingConfig.InterfaceRegistry)

	nexApp := app.NewNexaRailApp(
		logger,
		db,
		traceStore,
		height == -1,
		nil,
		homePath,
		0,
		encodingConfig,
		appOpts,
	)

	if height != -1 {
		if err := nexApp.LoadHeight(height); err != nil {
			return servertypes.ExportedApp{}, err
		}
	}

	return nexApp.ExportAppStateAndValidators(forZeroHeight, jailAllowedAddrs, modulesToExport)
}

func queryCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:                        "query",
		Aliases:                    []string{"q"},
		Short:                      "Query subcommands",
		DisableFlagParsing:         true,
		SuggestionsMinimumDistance: 2,
		RunE:                       sdkclient.ValidateCmd,
	}

	cmd.AddCommand(
		rpc.ValidatorCommand(),
		rpc.BlockCommand(),
		feescli.GetQueryCmd(),
		merchantcli.GetQueryCmd(),
		settlementcli.GetQueryCmd(),
		escrowcli.GetQueryCmd(),
		treasurycli.GetQueryCmd(),
		payoutcli.GetQueryCmd(),
	)

	return cmd
}

func txCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:                        "tx",
		Short:                      "Transactions subcommands",
		DisableFlagParsing:         true,
		SuggestionsMinimumDistance: 2,
		RunE:                       sdkclient.ValidateCmd,
	}

	cmd.AddCommand(
	// tx broadcast and signing commands will be added in Phase 2 refinement
	)

	return cmd
}
