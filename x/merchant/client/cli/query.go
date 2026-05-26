package cli

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/client/flags"
	sdk "github.com/cosmos/cosmos-sdk/types"

	"github.com/nexarail/chain/x/merchant/types"
)

func GetQueryCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:                        types.ModuleName,
		Short:                      "Query commands for the merchant module",
		DisableFlagParsing:         true,
		SuggestionsMinimumDistance: 2,
		RunE:                       client.ValidateCmd,
	}
	cmd.AddCommand(GetCmdQueryParams(), GetCmdQueryMerchant(), GetCmdQueryMerchants())
	return cmd
}

func GetCmdQueryParams() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "params",
		Short: "Query merchant module parameters",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, _ []string) error {
			clientCtx, err := client.GetClientQueryContext(cmd)
			if err != nil {
				return err
			}
			qc := types.NewQueryClient(clientCtx)
			res, err := qc.Params(cmd.Context(), &types.QueryParamsRequest{})
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

func GetCmdQueryMerchant() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "merchant [owner-address]",
		Short: "Query a merchant by owner address",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			clientCtx, err := client.GetClientQueryContext(cmd)
			if err != nil {
				return err
			}
			addr, err := sdk.AccAddressFromBech32(args[0])
			if err != nil {
				return fmt.Errorf("invalid address: %w", err)
			}
			qc := types.NewQueryClient(clientCtx)
			res, err := qc.Merchant(cmd.Context(), &types.QueryMerchantRequest{Owner: addr.String()})
			if err != nil {
				return err
			}
			// Print manually since proto encoding is not generated
			m := res.Merchant
			fmt.Printf("Owner:       %s\n", m.Owner)
			fmt.Printf("Name:        %s\n", m.Name)
			fmt.Printf("Description: %s\n", m.Description)
			fmt.Printf("Website:     %s\n", m.Website)
			fmt.Printf("Status:      %s\n", statusString(m.Status))
			return nil
		},
	}
	flags.AddQueryFlagsToCmd(cmd)
	return cmd
}

func GetCmdQueryMerchants() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "merchants",
		Short: "Query all registered merchants",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, _ []string) error {
			clientCtx, err := client.GetClientQueryContext(cmd)
			if err != nil {
				return err
			}
			qc := types.NewQueryClient(clientCtx)
			res, err := qc.Merchants(cmd.Context(), &types.QueryMerchantsRequest{})
			if err != nil {
				return err
			}
			fmt.Printf("Found %d merchants:\n", len(res.Merchants))
			for _, m := range res.Merchants {
				status := statusString(m.Status)
				fmt.Printf("  %s — %s (%s)\n", m.Name, m.Owner, status)
			}
			return nil
		},
	}
	flags.AddQueryFlagsToCmd(cmd)
	return cmd
}

func statusString(s int32) string {
	if s == 0 {
		return "active"
	}
	return "inactive"
}
