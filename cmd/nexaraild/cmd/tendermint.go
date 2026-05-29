package cmd

import (
	tmcmd "github.com/cometbft/cometbft/cmd/cometbft/commands"
	"github.com/spf13/cobra"

	"github.com/cosmos/cosmos-sdk/server"
)

// tendermintCommand builds the `tendermint` (aliases: `comet`, `cometbft`)
// subcommand group exposed by Cosmos SDK servers. Validators need
// `tendermint show-node-id` to publish their node identity for peer
// coordination; without this group registered, the binary returned
// `unknown command "tendermint"`, blocking onboarding.
//
// This mirrors the grouping that server.AddCommands installs upstream
// (cosmos-sdk v0.47.17, server/util.go), but is wired directly so we
// don't disturb the existing root-level start/export/version wiring.
func tendermintCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:     "tendermint",
		Aliases: []string{"comet", "cometbft"},
		Short:   "Tendermint/CometBFT subcommands (node ID, validator key, reset, bootstrap)",
	}

	cmd.AddCommand(
		server.ShowNodeIDCmd(),
		server.ShowValidatorCmd(),
		server.ShowAddressCmd(),
		server.VersionCmd(),
		tmcmd.ResetAllCmd,
		tmcmd.ResetStateCmd,
		server.BootstrapStateCmd(newAppCreator()),
	)

	return cmd
}
