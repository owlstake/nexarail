package cli

import (
	"fmt"
	"github.com/cosmos/cosmos-sdk/client"
	"github.com/nexarail/chain/x/payout/types"
	"github.com/spf13/cobra"
)

func GetQueryCmd() *cobra.Command {
	cmd := &cobra.Command{Use: types.ModuleName, Short: "Payout queries", DisableFlagParsing: true, SuggestionsMinimumDistance: 2, RunE: client.ValidateCmd}
	cmd.AddCommand(qParams(), qPayout(), qList(), qByMerchant(), qByRecipient(), qByInitiator(), qBatch(), qBatches(), qExists())
	return cmd
}
func qParams() *cobra.Command {
	return &cobra.Command{Use: "params", Short: "Query params", Args: cobra.NoArgs, RunE: func(c *cobra.Command, _ []string) error {
		cc, _ := client.GetClientQueryContext(c)
		r, _ := types.NewQueryClient(cc).Params(c.Context(), &types.QueryParamsRequest{})
		return cc.PrintProto(&r.Params)
	}}
}
func qPayout() *cobra.Command {
	return &cobra.Command{Use: "payout [id]", Short: "Query payout", Args: cobra.ExactArgs(1), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientQueryContext(c)
		r, err := types.NewQueryClient(cc).Payout(c.Context(), &types.QueryPayoutRequest{PayoutId: a[0]})
		if err != nil {
			return err
		}
		p := r.Payout
		fmt.Printf("ID: %s  Status: %s  Amount: %s  Recipient: %s\n", p.PayoutId, types.PayoutStatus(p.Status), p.Amount, p.RecipientAddress)
		return nil
	}}
}
func qList() *cobra.Command {
	return &cobra.Command{Use: "list", Short: "List payouts", Args: cobra.NoArgs, RunE: func(c *cobra.Command, _ []string) error {
		cc, _ := client.GetClientQueryContext(c)
		r, _ := types.NewQueryClient(cc).Payouts(c.Context(), &types.QueryPayoutsRequest{})
		fmt.Printf("%d payouts\n", len(r.Payouts))
		for _, p := range r.Payouts {
			fmt.Printf("  %s: %s [%s]\n", p.PayoutId, p.Amount, types.PayoutStatus(p.Status))
		}
		return nil
	}}
}
func qByMerchant() *cobra.Command {
	return &cobra.Command{Use: "by-merchant [id]", Short: "By merchant", Args: cobra.ExactArgs(1), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientQueryContext(c)
		r, _ := types.NewQueryClient(cc).PayoutsByMerchant(c.Context(), &types.QueryPayoutsByMerchantRequest{MerchantId: a[0]})
		fmt.Printf("%d payouts\n", len(r.Payouts))
		for _, p := range r.Payouts {
			fmt.Printf("  %s: %s [%s]\n", p.PayoutId, p.Amount, types.PayoutStatus(p.Status))
		}
		return nil
	}}
}
func qByRecipient() *cobra.Command {
	return &cobra.Command{Use: "by-recipient [addr]", Short: "By recipient", Args: cobra.ExactArgs(1), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientQueryContext(c)
		r, _ := types.NewQueryClient(cc).PayoutsByRecipient(c.Context(), &types.QueryPayoutsByRecipientRequest{Recipient: a[0]})
		fmt.Printf("%d payouts\n", len(r.Payouts))
		for _, p := range r.Payouts {
			fmt.Printf("  %s: %s\n", p.PayoutId, p.Amount)
		}
		return nil
	}}
}
func qByInitiator() *cobra.Command {
	return &cobra.Command{Use: "by-initiator [addr]", Short: "By initiator", Args: cobra.ExactArgs(1), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientQueryContext(c)
		r, _ := types.NewQueryClient(cc).PayoutsByInitiator(c.Context(), &types.QueryPayoutsByInitiatorRequest{Initiator: a[0]})
		fmt.Printf("%d payouts\n", len(r.Payouts))
		for _, p := range r.Payouts {
			fmt.Printf("  %s: %s\n", p.PayoutId, p.Amount)
		}
		return nil
	}}
}
func qBatch() *cobra.Command {
	return &cobra.Command{Use: "batch [id]", Short: "Query batch", Args: cobra.ExactArgs(1), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientQueryContext(c)
		r, err := types.NewQueryClient(cc).BatchPayout(c.Context(), &types.QueryBatchPayoutRequest{BatchId: a[0]})
		if err != nil {
			return err
		}
		b := r.BatchPayout
		fmt.Printf("Batch: %s  Status: %s  Payouts: %d  Total: %s\n", b.BatchId, types.BatchStatus(b.Status), len(b.PayoutIds), b.TotalAmount)
		return nil
	}}
}
func qBatches() *cobra.Command {
	return &cobra.Command{Use: "batches", Short: "List batches", Args: cobra.NoArgs, RunE: func(c *cobra.Command, _ []string) error {
		cc, _ := client.GetClientQueryContext(c)
		r, _ := types.NewQueryClient(cc).BatchPayouts(c.Context(), &types.QueryBatchPayoutsRequest{})
		fmt.Printf("%d batches\n", len(r.BatchPayouts))
		for _, b := range r.BatchPayouts {
			fmt.Printf("  %s: %s [%s]\n", b.BatchId, b.TotalAmount, types.BatchStatus(b.Status))
		}
		return nil
	}}
}
func qExists() *cobra.Command {
	return &cobra.Command{Use: "exists [id]", Short: "Check exists", Args: cobra.ExactArgs(1), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientQueryContext(c)
		r, _ := types.NewQueryClient(cc).PayoutExists(c.Context(), &types.QueryPayoutExistsRequest{PayoutId: a[0]})
		fmt.Printf("%s: %t\n", a[0], r.Exists)
		return nil
	}}
}
