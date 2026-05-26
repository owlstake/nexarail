package main

import (
	"context"
	"os"

	"github.com/cometbft/cometbft/libs/log"
	servercmd "github.com/cosmos/cosmos-sdk/server/cmd"

	"github.com/nexarail/chain/cmd/nexaraild/cmd"
)

func main() {
	rootCmd := cmd.NewRootCmd()

	// Seed the command context with the client.Context and server.Context
	// placeholder pointers that SetCmdClientContext / SetCmdServerContext copy
	// into during PersistentPreRunE. Without this, both handlers fail with
	// "client context not set" / "server context not set", which causes start
	// to fall back to a default server context (empty p2p.persistent_peers,
	// p2p.laddr, rpc.laddr) and ignore config.toml.
	ctx := servercmd.CreateExecuteContext(context.Background())

	if err := rootCmd.ExecuteContext(ctx); err != nil {
		logger := log.NewTMLogger(log.NewSyncWriter(os.Stderr))
		logger.Error("fatal", "error", err)
		os.Exit(1)
	}
}
