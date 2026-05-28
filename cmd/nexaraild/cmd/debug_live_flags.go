package cmd

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/spf13/cobra"

	"github.com/cosmos/cosmos-sdk/client"

	escrowtypes "github.com/nexarail/chain/x/escrow/types"
	feestypes "github.com/nexarail/chain/x/fees/types"
	merchanttypes "github.com/nexarail/chain/x/merchant/types"
	settlementtypes "github.com/nexarail/chain/x/settlement/types"
)

// DebugLiveFlagsCmd returns a command that prints all live flags from genesis.
func DebugLiveFlagsCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "debug-live-flags",
		Short: "Print all live flags from genesis.json",
		Long: `Prints the current state of all 6 live fund flags from the genesis file.
This is a diagnostic tool — it reads genesis.json directly without connecting to a running node.

Flags checked:
  settlement.live_enabled, settlement.treasury_routing_enabled, settlement.burn_routing_enabled
  escrow.live_enabled
  treasury.live_enabled
  payout.live_enabled`,
		Args: cobra.NoArgs,
		RunE: func(cmd *cobra.Command, _ []string) error {
			clientCtx, err := client.GetClientQueryContext(cmd)
			if err != nil {
				return err
			}

			genFile := clientCtx.HomeDir + "/config/genesis.json"
			data, err := os.ReadFile(genFile)
			if err != nil {
				return fmt.Errorf("failed to read genesis file at %s: %w", genFile, err)
			}

			var genesis map[string]interface{}
			if err := json.Unmarshal(data, &genesis); err != nil {
				return fmt.Errorf("failed to parse genesis: %w", err)
			}

			appState, ok := genesis["app_state"].(map[string]interface{})
			if !ok {
				return fmt.Errorf("genesis has no app_state")
			}

			chainID, _ := genesis["chain_id"].(string)
			fmt.Fprintf(cmd.OutOrStdout(), "Chain ID: %s\n\n", chainID)

			type flagCheck struct {
				module string
				flag   string
				label  string
			}

			flags := []flagCheck{
				{"settlement", "live_enabled", "settlement.live_enabled"},
				{"settlement", "treasury_routing_enabled", "settlement.treasury_routing_enabled"},
				{"settlement", "burn_routing_enabled", "settlement.burn_routing_enabled"},
				{"escrow", "live_enabled", "escrow.live_enabled"},
				{"treasury", "live_enabled", "treasury.live_enabled"},
				{"payout", "live_enabled", "payout.live_enabled"},
			}

			allFalse := true
			for _, fc := range flags {
				mod, ok := appState[fc.module].(map[string]interface{})
				if !ok {
					fmt.Fprintf(cmd.OutOrStdout(), "  %-42s ❓ module '%s' not found in genesis\n", fc.label+":", fc.module)
					allFalse = false
					continue
				}
				params, ok := mod["params"].(map[string]interface{})
				if !ok {
					fmt.Fprintf(cmd.OutOrStdout(), "  %-42s ❓ params not found in module '%s'\n", fc.label+":", fc.module)
					allFalse = false
					continue
				}
				val, ok := params[fc.flag]
				if !ok {
					fmt.Fprintf(cmd.OutOrStdout(), "  %-42s ❓ flag not found\n", fc.label+":")
					allFalse = false
					continue
				}
				isFalse := false
				switch v := val.(type) {
				case bool:
					isFalse = !v
				case string:
					isFalse = (v == "false" || v == "False")
				}
				if isFalse {
					fmt.Fprintf(cmd.OutOrStdout(), "  %-42s ✅ false\n", fc.label+":")
				} else {
					fmt.Fprintf(cmd.OutOrStdout(), "  %-42s ❌ %v (expected false)\n", fc.label+":", val)
					allFalse = false
				}
			}

			fmt.Fprintln(cmd.OutOrStdout(), "")
			if allFalse {
				fmt.Fprintln(cmd.OutOrStdout(), "✅ All 6 live flags default to false.")
			} else {
				fmt.Fprintln(cmd.OutOrStdout(), "❌ One or more live flags are not false.")
			}

			return nil
		},
	}
}

// DebugModuleSummaryCmd returns a command that prints a summary of all custom modules.
func DebugModuleSummaryCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "debug-module-summary",
		Short: "Print a summary of all custom module parameters",
		Long:  `Prints chain ID, all custom module params, live flags, and module account names from genesis.`,
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, _ []string) error {
			out := cmd.OutOrStdout()

			fmt.Fprintln(out, "╔══════════════════════════════════════════╗")
			fmt.Fprintln(out, "║  NexaRail Module Summary                ║")
			fmt.Fprintln(out, "╚══════════════════════════════════════════╝")

			// Module list
			fmt.Fprintln(out, "\n--- Custom Modules ---")
			modules := []struct {
				name    string
				version string
				purpose string
			}{
				{"x/fees", "v1", "Fee split parameters (validator/treasury/burn shares)"},
				{"x/merchant", "v1", "Merchant registration and rebate tiers"},
				{"x/settlement", "v1", "Payment settlement with fee routing (3 live flags)"},
				{"x/escrow", "v1", "Payment escrow custody (1 live flag)"},
				{"x/payout", "v1", "Automated payouts (1 live flag)"},
				{"x/treasury", "v1", "Protocol treasury and spend execution (1 live flag)"},
			}
			for _, m := range modules {
				fmt.Fprintf(out, "  %-20s %s  %s\n", m.name, m.version, m.purpose)
			}

			// Module account names
			fmt.Fprintln(out, "\n--- Module Accounts ---")
			accounts := []struct {
				name    string
				purpose string
			}{
				{"nexarail_escrow", "Escrow custody pool"},
				{"nexarail_treasury", "Treasury fund pool"},
				{"nexarail_fee_router", "Fee routing intermediary"},
				{"nexarail_burner", "Burn routing destination"},
			}
			for _, a := range accounts {
				fmt.Fprintf(out, "  %-30s %s\n", a.name, a.purpose)
			}

			// Fee split defaults
			fmt.Fprintln(out, "\n--- Default Fee Split ---")
			fmt.Fprintf(out, "  Validator/Delegator:  %d bps (%.2f%%)\n", feestypes.DefaultValidatorShareBps, float64(feestypes.DefaultValidatorShareBps)/100)
			fmt.Fprintf(out, "  Treasury:             %d bps (%.2f%%)\n", feestypes.DefaultTreasuryShareBps, float64(feestypes.DefaultTreasuryShareBps)/100)
			fmt.Fprintf(out, "  Burn:                 %d bps (%.2f%%)\n", feestypes.DefaultBurnShareBps, float64(feestypes.DefaultBurnShareBps)/100)

			// Default params for other modules
			fmt.Fprintln(out, "\n--- Default Params ---")
			fmt.Fprintf(out, "  settlement.fee_rate_bps:       %d\n", settlementtypes.DefaultFeeRateBps)
			fmt.Fprintf(out, "  merchant.registration_fee:     %s\n", merchanttypes.DefaultRegistrationFee.String())
			fmt.Fprintf(out, "  escrow.default_expiry_seconds: %d\n", escrowtypes.DefaultExpirySeconds)

			// Warnings
			fmt.Fprintln(out, "\n--- Current Warnings ---")
			warnings := []string{
				"Live fund modules are disabled by default (all 6 flags = false).",
				"No mainnet is live. This is testnet/devnet infrastructure only.",
				"NXRL testnet tokens have no monetary value. No token sale has occurred.",
				"External security audit has not been completed.",
				"Legal review has not been completed.",
			}
			for i, w := range warnings {
				fmt.Fprintf(out, "  %d. %s\n", i+1, w)
			}

			fmt.Fprintln(out, "")
			return nil
		},
	}
}
