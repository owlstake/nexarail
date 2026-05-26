package cli

import (
	"fmt"
	"github.com/cosmos/cosmos-sdk/client"
	"github.com/nexarail/chain/x/escrow/types"
	"github.com/spf13/cobra"
)

func GetQueryCmd() *cobra.Command {
	cmd := &cobra.Command{Use: types.ModuleName, Short: "Escrow query commands", DisableFlagParsing: true, SuggestionsMinimumDistance: 2, RunE: client.ValidateCmd}
	cmd.AddCommand(qParams(), qEscrow(), qList(), qByBuyer(), qBySeller(), qByMerchant(), qExists())
	return cmd
}

func qParams() *cobra.Command {
	return &cobra.Command{
		Use: "params", Short: "Query escrow params", Args: cobra.NoArgs,
		RunE: func(c *cobra.Command, _ []string) error {
			cc, _ := client.GetClientQueryContext(c)
			qc := types.NewQueryClient(cc)
			r, err := qc.Params(c.Context(), &types.QueryParamsRequest{})
			if err != nil {
				return err
			}
			return cc.PrintProto(&r.Params)
		},
	}
}

func qEscrow() *cobra.Command {
	return &cobra.Command{
		Use: "escrow [id]", Short: "Query escrow by ID", Args: cobra.ExactArgs(1),
		RunE: func(c *cobra.Command, args []string) error {
			cc, _ := client.GetClientQueryContext(c)
			qc := types.NewQueryClient(cc)
			r, err := qc.Escrow(c.Context(), &types.QueryEscrowRequest{EscrowId: args[0]})
			if err != nil {
				return err
			}
			e := r.Escrow
			fmt.Printf("ID:           %s\n", e.EscrowId)
			fmt.Printf("Buyer:        %s\n", e.BuyerAddress)
			fmt.Printf("Seller:       %s\n", e.SellerAddress)
			fmt.Printf("Merchant:     %s\n", e.MerchantId)
			fmt.Printf("Amount:       %s\n", e.Amount)
			fmt.Printf("Platform Fee: %s\n", e.PlatformFee)
			fmt.Printf("Status:       %s\n", types.EscrowStatus(e.Status))
			fmt.Printf("Dispute:      %s\n", types.DisputeStatus(e.DisputeStatus))
			fmt.Printf("Created:      %d\n", e.CreatedAt)
			return nil
		},
	}
}

func qList() *cobra.Command {
	return &cobra.Command{
		Use: "list", Short: "List all escrows", Args: cobra.NoArgs,
		RunE: func(c *cobra.Command, _ []string) error {
			cc, _ := client.GetClientQueryContext(c)
			qc := types.NewQueryClient(cc)
			r, err := qc.Escrows(c.Context(), &types.QueryEscrowsRequest{})
			if err != nil {
				return err
			}
			fmt.Printf("Found %d escrows:\n", len(r.Escrows))
			for _, e := range r.Escrows {
				fmt.Printf("  %s: %s → %s  %s  [%s]\n", e.EscrowId, e.BuyerAddress[:10], e.SellerAddress[:10], e.Amount, types.EscrowStatus(e.Status))
			}
			return nil
		},
	}
}

func qByBuyer() *cobra.Command {
	return &cobra.Command{
		Use: "by-buyer [address]", Short: "Query escrows by buyer", Args: cobra.ExactArgs(1),
		RunE: func(c *cobra.Command, args []string) error {
			cc, _ := client.GetClientQueryContext(c)
			qc := types.NewQueryClient(cc)
			r, err := qc.EscrowsByBuyer(c.Context(), &types.QueryEscrowsByBuyerRequest{Buyer: args[0]})
			if err != nil {
				return err
			}
			fmt.Printf("Found %d escrows:\n", len(r.Escrows))
			for _, e := range r.Escrows {
				fmt.Printf("  %s: %s [%s]\n", e.EscrowId, e.Amount, types.EscrowStatus(e.Status))
			}
			return nil
		},
	}
}

func qBySeller() *cobra.Command {
	return &cobra.Command{
		Use: "by-seller [address]", Short: "Query escrows by seller", Args: cobra.ExactArgs(1),
		RunE: func(c *cobra.Command, args []string) error {
			cc, _ := client.GetClientQueryContext(c)
			qc := types.NewQueryClient(cc)
			r, err := qc.EscrowsBySeller(c.Context(), &types.QueryEscrowsBySellerRequest{Seller: args[0]})
			if err != nil {
				return err
			}
			fmt.Printf("Found %d escrows:\n", len(r.Escrows))
			for _, e := range r.Escrows {
				fmt.Printf("  %s: %s [%s]\n", e.EscrowId, e.Amount, types.EscrowStatus(e.Status))
			}
			return nil
		},
	}
}

func qByMerchant() *cobra.Command {
	return &cobra.Command{
		Use: "by-merchant [id]", Short: "Query escrows by merchant", Args: cobra.ExactArgs(1),
		RunE: func(c *cobra.Command, args []string) error {
			cc, _ := client.GetClientQueryContext(c)
			qc := types.NewQueryClient(cc)
			r, err := qc.EscrowsByMerchant(c.Context(), &types.QueryEscrowsByMerchantRequest{MerchantId: args[0]})
			if err != nil {
				return err
			}
			fmt.Printf("Found %d escrows:\n", len(r.Escrows))
			for _, e := range r.Escrows {
				fmt.Printf("  %s: %s [%s]\n", e.EscrowId, e.Amount, types.EscrowStatus(e.Status))
			}
			return nil
		},
	}
}

func qExists() *cobra.Command {
	return &cobra.Command{
		Use: "exists [id]", Short: "Check if escrow exists", Args: cobra.ExactArgs(1),
		RunE: func(c *cobra.Command, args []string) error {
			cc, _ := client.GetClientQueryContext(c)
			qc := types.NewQueryClient(cc)
			r, err := qc.EscrowExists(c.Context(), &types.QueryEscrowExistsRequest{EscrowId: args[0]})
			if err != nil {
				return err
			}
			fmt.Printf("Escrow %s exists: %t\n", args[0], r.Exists)
			return nil
		},
	}
}
