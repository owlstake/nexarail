package cli

import (
	"fmt"
	"strconv"

	"github.com/spf13/cobra"

	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/client/flags"

	"github.com/nexarail/chain/x/settlement/types"
)

func GetQueryCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:                        types.ModuleName,
		Short:                      "Query commands for the settlement module",
		DisableFlagParsing:         true,
		SuggestionsMinimumDistance: 2,
		RunE:                       client.ValidateCmd,
	}
	cmd.AddCommand(
		GetCmdQueryParams(),
		GetCmdQuerySettlement(),
		GetCmdQuerySettlements(),
		GetCmdQuerySettlementsByMerchant(),
		GetCmdQuerySettlementsByPayer(),
	)
	return cmd
}

func GetCmdQueryParams() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "params",
		Short: "Query settlement module parameters",
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

func GetCmdQuerySettlement() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "settlement [id]",
		Short: "Query a settlement by ID",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			id, err := strconv.ParseUint(args[0], 10, 64)
			if err != nil {
				return fmt.Errorf("invalid settlement ID: %w", err)
			}
			clientCtx, err := client.GetClientQueryContext(cmd)
			if err != nil {
				return err
			}
			qc := types.NewQueryClient(clientCtx)
			res, err := qc.Settlement(cmd.Context(), &types.QuerySettlementRequest{Id: id})
			if err != nil {
				return err
			}
			s := res.Settlement
			fmt.Printf("ID:              %d\n", s.Id)
			fmt.Printf("Payer:           %s\n", s.Payer)
			fmt.Printf("Merchant:        %s (%s)\n", s.MerchantOwner, s.MerchantId)
			fmt.Printf("Amount:          %s\n", s.Amount)
			fmt.Printf("Fee:             %s\n", s.FeeAmount)
			fmt.Printf("Validator Share: %s\n", s.ValidatorShare)
			fmt.Printf("Treasury Share:  %s\n", s.TreasuryShare)
			fmt.Printf("Burn Share:      %s\n", s.BurnShare)
			fmt.Printf("Rebate:          %d bps (%s)\n", s.RebateAppliedBps, s.RebateAmount)
			fmt.Printf("Status:          %s\n", types.SettlementStatus(s.Status))
			fmt.Printf("Created:         %d\n", s.CreatedAt)
			return nil
		},
	}
	flags.AddQueryFlagsToCmd(cmd)
	return cmd
}

func GetCmdQuerySettlements() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "list",
		Short: "List all settlements",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, _ []string) error {
			clientCtx, err := client.GetClientQueryContext(cmd)
			if err != nil {
				return err
			}
			qc := types.NewQueryClient(clientCtx)
			res, err := qc.Settlements(cmd.Context(), &types.QuerySettlementsRequest{})
			if err != nil {
				return err
			}
			fmt.Printf("Found %d settlements:\n", len(res.Settlements))
			for _, s := range res.Settlements {
				fmt.Printf("  %d: %s → %s  %s  [%s]\n", s.Id, s.Payer[:10], s.MerchantOwner[:10], s.Amount, types.SettlementStatus(s.Status))
			}
			return nil
		},
	}
	flags.AddQueryFlagsToCmd(cmd)
	return cmd
}

func GetCmdQuerySettlementsByMerchant() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "by-merchant [merchant-owner]",
		Short: "Query settlements by merchant owner address",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			clientCtx, err := client.GetClientQueryContext(cmd)
			if err != nil {
				return err
			}
			qc := types.NewQueryClient(clientCtx)
			res, err := qc.SettlementsByMerchant(cmd.Context(), &types.QuerySettlementsByMerchantRequest{MerchantOwner: args[0]})
			if err != nil {
				return err
			}
			fmt.Printf("Found %d settlements:\n", len(res.Settlements))
			for _, s := range res.Settlements {
				fmt.Printf("  %d: %s → %s  %s  [%s]\n", s.Id, s.Payer[:10], s.MerchantOwner[:10], s.Amount, types.SettlementStatus(s.Status))
			}
			return nil
		},
	}
	flags.AddQueryFlagsToCmd(cmd)
	return cmd
}

func GetCmdQuerySettlementsByPayer() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "by-payer [payer-address]",
		Short: "Query settlements by payer address",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			clientCtx, err := client.GetClientQueryContext(cmd)
			if err != nil {
				return err
			}
			qc := types.NewQueryClient(clientCtx)
			res, err := qc.SettlementsByPayer(cmd.Context(), &types.QuerySettlementsByPayerRequest{Payer: args[0]})
			if err != nil {
				return err
			}
			fmt.Printf("Found %d settlements:\n", len(res.Settlements))
			for _, s := range res.Settlements {
				fmt.Printf("  %d: %s → %s  %s  [%s]\n", s.Id, s.Payer[:10], s.MerchantOwner[:10], s.Amount, types.SettlementStatus(s.Status))
			}
			return nil
		},
	}
	flags.AddQueryFlagsToCmd(cmd)
	return cmd
}
