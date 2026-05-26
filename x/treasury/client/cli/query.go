package cli

import (
	"fmt"
	"github.com/cosmos/cosmos-sdk/client"
	"github.com/nexarail/chain/x/treasury/types"
	"github.com/spf13/cobra"
)

func GetQueryCmd() *cobra.Command {
	c := &cobra.Command{Use: types.ModuleName, Short: "Treasury queries", DisableFlagParsing: true, SuggestionsMinimumDistance: 2, RunE: client.ValidateCmd}
	c.AddCommand(q("params", "Query params", func(cc client.Context, c *cobra.Command, a []string) error {
		r, _ := types.NewQueryClient(cc).Params(c.Context(), &types.QueryParamsRequest{})
		return cc.PrintProto(&r.Params)
	}, 0))
	c.AddCommand(q("account", "Query account", func(cc client.Context, c *cobra.Command, a []string) error {
		r, err := types.NewQueryClient(cc).TreasuryAccount(c.Context(), &types.QueryTreasuryAccountRequest{AccountId: a[0]})
		if err != nil {
			return err
		}
		a1 := r.Account
		fmt.Printf("ID: %s  Category: %d  Name: %s  Balance: %s\n", a1.AccountId, a1.Category, a1.Name, a1.NominalBalance)
		return nil
	}, 1))
	c.AddCommand(q("accounts", "List accounts", func(cc client.Context, c *cobra.Command, _ []string) error {
		r, _ := types.NewQueryClient(cc).TreasuryAccounts(c.Context(), &types.QueryTreasuryAccountsRequest{})
		fmt.Printf("%d accounts\n", len(r.Accounts))
		for _, a := range r.Accounts {
			fmt.Printf("  %s: %s [cat:%d]\n", a.AccountId, a.Name, a.Category)
		}
		return nil
	}, 0))
	c.AddCommand(q("budget", "Query budget", func(cc client.Context, c *cobra.Command, a []string) error {
		r, err := types.NewQueryClient(cc).Budget(c.Context(), &types.QueryBudgetRequest{BudgetId: a[0]})
		if err != nil {
			return err
		}
		b := r.Budget
		fmt.Printf("ID: %s  Title: %s  Total: %s  Alloc: %s  Spent: %s  Status: %d\n", b.BudgetId, b.Title, b.TotalAmount, b.AllocatedAmount, b.SpentAmount, b.Status)
		return nil
	}, 1))
	c.AddCommand(q("budgets", "List budgets", func(cc client.Context, c *cobra.Command, _ []string) error {
		r, _ := types.NewQueryClient(cc).Budgets(c.Context(), &types.QueryBudgetsRequest{})
		fmt.Printf("%d budgets\n", len(r.Budgets))
		for _, b := range r.Budgets {
			fmt.Printf("  %s: %s [%s]\n", b.BudgetId, b.TotalAmount, types.BudgetStatus(b.Status))
		}
		return nil
	}, 0))
	c.AddCommand(q("grant", "Query grant", func(cc client.Context, c *cobra.Command, a []string) error {
		r, err := types.NewQueryClient(cc).Grant(c.Context(), &types.QueryGrantRequest{GrantId: a[0]})
		if err != nil {
			return err
		}
		g := r.Grant
		fmt.Printf("ID: %s  Title: %s  Amount: %s  Status: %d  Recipient: %s\n", g.GrantId, g.Title, g.Amount, g.Status, g.RecipientAddress)
		return nil
	}, 1))
	c.AddCommand(q("grants", "List grants", func(cc client.Context, c *cobra.Command, _ []string) error {
		r, _ := types.NewQueryClient(cc).Grants(c.Context(), &types.QueryGrantsRequest{})
		fmt.Printf("%d grants\n", len(r.Grants))
		for _, g := range r.Grants {
			fmt.Printf("  %s: %s [%s]\n", g.GrantId, g.Amount, types.GrantStatus(g.Status))
		}
		return nil
	}, 0))
	c.AddCommand(q("spend", "Query spend", func(cc client.Context, c *cobra.Command, a []string) error {
		r, err := types.NewQueryClient(cc).SpendRequest(c.Context(), &types.QuerySpendRequestRequest{SpendId: a[0]})
		if err != nil {
			return err
		}
		s := r.SpendRequest
		fmt.Printf("ID: %s  Amount: %s  Purpose: %s  Status: %d\n", s.SpendId, s.Amount, s.Purpose, s.Status)
		return nil
	}, 1))
	c.AddCommand(q("spends", "List spends", func(cc client.Context, c *cobra.Command, _ []string) error {
		r, _ := types.NewQueryClient(cc).SpendRequests(c.Context(), &types.QuerySpendRequestsRequest{})
		fmt.Printf("%d spends\n", len(r.SpendRequests))
		for _, s := range r.SpendRequests {
			fmt.Printf("  %s: %s [%s]\n", s.SpendId, s.Amount, types.SpendStatus(s.Status))
		}
		return nil
	}, 0))
	c.AddCommand(q("summary", "Treasury summary", func(cc client.Context, c *cobra.Command, _ []string) error {
		r, _ := types.NewQueryClient(cc).TreasurySummary(c.Context(), &types.QueryTreasurySummaryRequest{})
		fmt.Printf("Accounts: %d  Budgets: %d  Grants: %d  Spends: %d\n", r.TotalAccounts, r.TotalBudgets, r.TotalGrants, r.TotalSpendRequests)
		return nil
	}, 0))
	return c
}
func q(name, desc string, fn func(client.Context, *cobra.Command, []string) error, args int) *cobra.Command {
	a := cobra.NoArgs
	if args == 1 {
		a = cobra.ExactArgs(1)
	}
	return &cobra.Command{Use: name, Short: desc, Args: a, RunE: func(c *cobra.Command, as []string) error {
		cc, _ := client.GetClientQueryContext(c)
		return fn(cc, c, as)
	}}
}
