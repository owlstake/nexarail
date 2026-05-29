package cmd

import (
	"bytes"
	"context"
	"io"
	"os"
	"strings"
	"testing"

	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/server"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

// rootCommandNames returns the immediate subcommand names registered on the
// root command, used to assert validator-facing groups stay registered.
func rootCommandNames(t *testing.T) map[string]bool {
	t.Helper()
	root := NewRootCmd()
	names := make(map[string]bool, len(root.Commands()))
	for _, c := range root.Commands() {
		names[c.Name()] = true
		for _, a := range c.Aliases {
			names[a] = true
		}
	}
	return names
}

// TestRootHasValidatorCommands locks in the validator-onboarding command
// surface. Loss of any of these regressed external validator setup at RC1
// (see docs/release/VALIDATOR_CLI_HOTFIX_NOTES.md).
func TestRootHasValidatorCommands(t *testing.T) {
	names := rootCommandNames(t)
	for _, want := range []string{
		"tendermint", "comet", "cometbft",
		"start", "init", "keys", "query", "tx",
		"add-genesis-account", "gentx", "collect-gentxs",
		"export", "status",
	} {
		if !names[want] {
			t.Errorf("root command missing %q", want)
		}
	}
}

func TestProductModuleCommandsRemainRegistered(t *testing.T) {
	root := NewRootCmd()
	for parent, wants := range map[string][]string{
		"query": {"fees", "merchant", "settlement", "escrow", "treasury", "payout"},
		"tx":    {"fees", "merchant", "settlement", "escrow", "treasury", "payout"},
	} {
		cmd := findSubcommand(root, parent)
		if cmd == nil {
			t.Fatalf("root command missing %q", parent)
		}
		names := make(map[string]bool, len(cmd.Commands()))
		for _, c := range cmd.Commands() {
			names[c.Name()] = true
		}
		for _, want := range wants {
			if !names[want] {
				t.Errorf("%s command missing product module %q", parent, want)
			}
		}
	}
}

// TestTendermintGroupHasNodeID asserts the tendermint subcommand group
// exposes the helpers a validator needs to publish a node ID and inspect
// the local validator key.
func TestTendermintGroupHasNodeID(t *testing.T) {
	root := NewRootCmd()
	tmCmd := findSubcommand(root, "tendermint")
	if tmCmd == nil {
		t.Fatal("tendermint subcommand not registered on root")
	}

	subs := make(map[string]bool, len(tmCmd.Commands()))
	for _, c := range tmCmd.Commands() {
		subs[c.Name()] = true
	}
	for _, want := range []string{
		"show-node-id", "show-validator", "show-address",
		"version", "bootstrap-state",
	} {
		if !subs[want] {
			t.Errorf("tendermint group missing %q subcommand", want)
		}
	}
}

// TestTendermintHelpDoesNotPanic exercises the --help path on the
// tendermint subcommand to guard against rendering panics that would
// confuse validators following the action pack.
func TestTendermintHelpDoesNotPanic(t *testing.T) {
	root := NewRootCmd()
	buf := &bytes.Buffer{}
	root.SetOut(buf)
	root.SetErr(buf)
	root.SetArgs([]string{"tendermint", "--help"})

	if err := root.ExecuteContext(context.Background()); err != nil {
		t.Fatalf("tendermint --help failed: %v", err)
	}
	if !strings.Contains(buf.String(), "show-node-id") {
		t.Fatalf("tendermint --help output missing show-node-id; got:\n%s", buf.String())
	}
}

// TestShowNodeIDReturnsHex initialises a fresh node home and calls
// `tendermint show-node-id` plus the `comet` alias, asserting both return the
// validator's 40-char hex node ID. This is the exact flow external validators run.
func TestShowNodeIDReturnsHex(t *testing.T) {
	home := t.TempDir()

	// Initialise a node home: writes config.toml, node_key.json, priv_validator_key.json, genesis.json.
	// `init` writes the genesis snapshot to stdout, so we swallow stdout during init too.
	withCapturedOutput(t, func() {
		initRoot := NewRootCmd()
		initRoot.SetArgs([]string{"init", "cli-hotfix-test", "--chain-id", "nexarail-devnet-1", "--home", home})
		initRoot.SetOut(io.Discard)
		initRoot.SetErr(io.Discard)
		if err := initRoot.ExecuteContext(injectServerCtx(context.Background(), home)); err != nil {
			t.Fatalf("init failed: %v", err)
		}
	})

	tendermintID := runShowNodeID(t, home, "tendermint")
	cometID := runShowNodeID(t, home, "comet")

	assertNodeID(t, tendermintID)
	if cometID != tendermintID {
		t.Fatalf("comet alias returned different node ID: tendermint=%q comet=%q", tendermintID, cometID)
	}
}

func findSubcommand(cmd *cobra.Command, name string) *cobra.Command {
	for _, c := range cmd.Commands() {
		if c.Name() == name {
			return c
		}
	}
	return nil
}

func runShowNodeID(t *testing.T, home string, group string) string {
	t.Helper()

	stdout := withCapturedOutput(t, func() {
		root := NewRootCmd()
		errBuf := &bytes.Buffer{}
		root.SetErr(errBuf)
		root.SetArgs([]string{group, "show-node-id", "--home", home})
		if err := root.ExecuteContext(injectServerCtx(context.Background(), home)); err != nil {
			t.Fatalf("%s show-node-id failed: %v\nstderr:\n%s", group, err, errBuf.String())
		}
	})

	return strings.TrimSpace(stdout)
}

func assertNodeID(t *testing.T, got string) {
	t.Helper()

	if len(got) != 40 {
		t.Fatalf("expected 40-char hex node ID, got %d chars: %q", len(got), got)
	}
	for _, r := range got {
		if !((r >= '0' && r <= '9') || (r >= 'a' && r <= 'f')) {
			t.Fatalf("node ID contains non-hex character %q in %q", r, got)
		}
	}
}

// withCapturedOutput swaps os.Stdout/os.Stderr for pipes and returns stdout.
// Cosmos SDK helper commands write directly to these descriptors in a few paths.
func withCapturedOutput(t *testing.T, fn func()) string {
	t.Helper()
	stdoutR, stdoutW, err := os.Pipe()
	if err != nil {
		t.Fatalf("stdout pipe: %v", err)
	}
	stderrR, stderrW, err := os.Pipe()
	if err != nil {
		t.Fatalf("stderr pipe: %v", err)
	}

	origStdout := os.Stdout
	origStderr := os.Stderr
	os.Stdout = stdoutW
	os.Stderr = stderrW
	restored := false
	restore := func() {
		if restored {
			return
		}
		_ = stdoutW.Close()
		_ = stderrW.Close()
		os.Stdout = origStdout
		os.Stderr = origStderr
		restored = true
	}
	defer restore()

	done := make(chan string, 1)
	stderrDone := make(chan struct{}, 1)
	go func() {
		buf := &bytes.Buffer{}
		_, _ = io.Copy(buf, stdoutR)
		done <- buf.String()
	}()
	go func() {
		_, _ = io.Copy(io.Discard, stderrR)
		stderrDone <- struct{}{}
	}()

	fn()

	restore()
	<-stderrDone

	return <-done
}

// injectServerCtx places a server.Context with --home applied into ctx so
// commands depending on viper resolve the temp home during tests.
func injectServerCtx(parent context.Context, home string) context.Context {
	v := viper.New()
	v.Set("home", home)
	srvCtx := server.NewDefaultContext()
	srvCtx.Viper = v
	srvCtx.Config.SetRoot(home)
	ctx := context.WithValue(parent, server.ServerContextKey, srvCtx)
	ctx = context.WithValue(ctx, client.ClientContextKey, &client.Context{HomeDir: home})
	return ctx
}
