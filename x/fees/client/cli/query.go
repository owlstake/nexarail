package cli

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/client/flags"

	"github.com/nexarail/chain/x/fees/types"
)

// GetQueryCmd returns the CLI query commands for the fees module.
func GetQueryCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:                        types.ModuleName,
		Short:                      "Query commands for the fees module",
		DisableFlagParsing:         true,
		SuggestionsMinimumDistance: 2,
		RunE:                       client.ValidateCmd,
	}

	cmd.AddCommand(
		GetCmdQueryParams(),
		GetCmdQueryFeeSplit(),
	)

	return cmd
}

// GetCmdQueryParams returns the query params command.
func GetCmdQueryParams() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "params",
		Short: "Query the current fees module parameters",
		Args:  cobra.NoArgs,
		Long: `Query the current fee split parameters for the NexaRail fees module.

The parameters include validator/delegator share, treasury share, burn share,
fee collector name, treasury account, burn enabled status, and minimum protocol fee.

Example:
  nexaraild query fees params
`,
		RunE: func(cmd *cobra.Command, _ []string) error {
			clientCtx, err := client.GetClientQueryContext(cmd)
			if err != nil {
				return err
			}

			queryClient := types.NewQueryClient(clientCtx)
			res, err := queryClient.Params(cmd.Context(), &types.QueryParamsRequest{})
			if err != nil {
				return err
			}

			fmt.Printf("%+v\n", res.Params)
			return nil
		},
	}

	flags.AddQueryFlagsToCmd(cmd)
	return cmd
}

// GetCmdQueryFeeSplit returns the query fee split command.
func GetCmdQueryFeeSplit() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "fee-split",
		Short: "Query the current fee split proportions",
		Args:  cobra.NoArgs,
		Long: `Query the current fee split proportions in basis points.

Returns the validator/delegator share, treasury share, and burn share.
All values are in basis points (1/100 of a percent).

Example:
  nexaraild query fees fee-split
`,
		RunE: func(cmd *cobra.Command, _ []string) error {
			clientCtx, err := client.GetClientQueryContext(cmd)
			if err != nil {
				return err
			}

			queryClient := types.NewQueryClient(clientCtx)
			res, err := queryClient.FeeSplit(cmd.Context(), &types.QueryFeeSplitRequest{})
			if err != nil {
				return err
			}

			fmt.Printf("Validator/Delegator Share: %d bps (%.2f%%)\n", res.ValidatorShareBps, float64(res.ValidatorShareBps)/100)
			fmt.Printf("Treasury Share:            %d bps (%.2f%%)\n", res.TreasuryShareBps, float64(res.TreasuryShareBps)/100)
			fmt.Printf("Burn Share:               %d bps (%.2f%%)\n", res.BurnShareBps, float64(res.BurnShareBps)/100)

			return nil
		},
	}

	flags.AddQueryFlagsToCmd(cmd)
	return cmd
}
