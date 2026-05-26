package cmd

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/cosmos/cosmos-sdk/server"
)

// DebugP2PConfigCmd prints the CometBFT P2P/RPC config as it was loaded into the
// server context by InterceptConfigsPreRunHandler. It is a diagnostic that
// proves config.toml is actually being applied at runtime (the same path that
// "start" uses), without having to boot a full node.
func DebugP2PConfigCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "debug-p2p-config",
		Short: "Print the loaded CometBFT P2P/RPC config (diagnostic)",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, _ []string) error {
			cfg := server.GetServerContextFromCmd(cmd).Config
			out := cmd.OutOrStdout()

			fmt.Fprintf(out, "home                 = %q\n", cfg.RootDir)
			fmt.Fprintf(out, "p2p.laddr            = %q\n", cfg.P2P.ListenAddress)
			fmt.Fprintf(out, "p2p.persistent_peers = %q\n", cfg.P2P.PersistentPeers)
			fmt.Fprintf(out, "p2p.addr_book_strict = %v\n", cfg.P2P.AddrBookStrict)
			fmt.Fprintf(out, "p2p.allow_duplicate_ip = %v\n", cfg.P2P.AllowDuplicateIP)
			fmt.Fprintf(out, "p2p.pex              = %v\n", cfg.P2P.PexReactor)
			fmt.Fprintf(out, "rpc.laddr            = %q\n", cfg.RPC.ListenAddress)
			return nil
		},
	}
}
