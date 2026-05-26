package cli

import (
	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/client/flags"
	"github.com/cosmos/cosmos-sdk/client/tx"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/nexarail/chain/x/treasury/types"
	"github.com/spf13/cobra"
	"strconv"
	"strings"
)

func GetTxCmd() *cobra.Command {
	c := &cobra.Command{Use: types.ModuleName, Short: "Treasury tx", DisableFlagParsing: true, SuggestionsMinimumDistance: 2, RunE: client.ValidateCmd}
	c.AddCommand(cCreateAcct(), cCreateBudget(), cUpdateBudget(), cCreateGrant(), cUpdateGrant(), cCreateSpend(), cApproveSpend(), cRejectSpend(), cMarkExec(), cCancelSpend(), cUpdateParams())
	return c
}

func cCreateAcct() *cobra.Command {
	cmd := &cobra.Command{Use: "create-account [id] [category] [name] [balance]", Short: "Create treasury account", Args: cobra.ExactArgs(4), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientTxContext(c)
		cat, _ := strconv.ParseInt(a[1], 10, 32)
		bal, err := sdk.ParseCoinNormalized(a[3])
		if err != nil {
			return err
		}
		desc, _ := c.Flags().GetString("description")
		uri, _ := c.Flags().GetString("metadata-uri")
		m := types.NewMsgCreateTreasuryAccount(cc.GetFromAddress().String(), a[0], int32(cat), a[2], desc, uri, bal)
		m.ValidateBasic()
		return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), m)
	}}
	cmd.Flags().String("description", "", "")
	cmd.Flags().String("metadata-uri", "", "")
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}
func cCreateBudget() *cobra.Command {
	cmd := &cobra.Command{Use: "create-budget [id] [account-id] [category] [title] [total]", Short: "Create budget", Args: cobra.ExactArgs(5), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientTxContext(c)
		cat, _ := strconv.ParseInt(a[2], 10, 32)
		total, err := sdk.ParseCoinNormalized(a[4])
		if err != nil {
			return err
		}
		desc, _ := c.Flags().GetString("description")
		uri, _ := c.Flags().GetString("metadata-uri")
		st, _ := c.Flags().GetInt64("start-time")
		et, _ := c.Flags().GetInt64("end-time")
		m := types.NewMsgCreateBudget(cc.GetFromAddress().String(), a[0], a[1], int32(cat), a[3], desc, total, st, et, uri)
		m.ValidateBasic()
		return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), m)
	}}
	cmd.Flags().String("description", "", "")
	cmd.Flags().String("metadata-uri", "", "")
	cmd.Flags().Int64("start-time", 0, "")
	cmd.Flags().Int64("end-time", 0, "")
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}
func cUpdateBudget() *cobra.Command {
	cmd := &cobra.Command{Use: "update-budget-status [id] [status]", Short: "Update budget status", Args: cobra.ExactArgs(2), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientTxContext(c)
		s, _ := strconv.ParseInt(a[1], 10, 32)
		m := types.NewMsgUpdateBudgetStatus(cc.GetFromAddress().String(), a[0], int32(s))
		m.ValidateBasic()
		return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), m)
	}}
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}
func cCreateGrant() *cobra.Command {
	cmd := &cobra.Command{Use: "create-grant [id] [budget-id] [recipient] [amount] [title]", Short: "Create grant", Args: cobra.ExactArgs(5), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientTxContext(c)
		amt, err := sdk.ParseCoinNormalized(a[3])
		if err != nil {
			return err
		}
		desc, _ := c.Flags().GetString("description")
		mc, _ := c.Flags().GetUint32("milestone-count")
		uri, _ := c.Flags().GetString("metadata-uri")
		m := types.NewMsgCreateGrant(cc.GetFromAddress().String(), a[0], a[1], a[2], a[4], desc, amt, mc, uri)
		m.ValidateBasic()
		return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), m)
	}}
	cmd.Flags().String("description", "", "")
	cmd.Flags().Uint32("milestone-count", 1, "")
	cmd.Flags().String("metadata-uri", "", "")
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}
func cUpdateGrant() *cobra.Command {
	cmd := &cobra.Command{Use: "update-grant-status [id] [status]", Short: "Update grant status", Args: cobra.ExactArgs(2), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientTxContext(c)
		s, _ := strconv.ParseInt(a[1], 10, 32)
		m := types.NewMsgUpdateGrantStatus(cc.GetFromAddress().String(), a[0], int32(s))
		m.ValidateBasic()
		return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), m)
	}}
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}
func cCreateSpend() *cobra.Command {
	cmd := &cobra.Command{Use: "create-spend [id] [account-id] [recipient] [amount] [purpose]", Short: "Create spend request", Args: cobra.ExactArgs(5), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientTxContext(c)
		amt, err := sdk.ParseCoinNormalized(a[3])
		if err != nil {
			return err
		}
		bid, _ := c.Flags().GetString("budget-id")
		gid, _ := c.Flags().GetString("grant-id")
		ref, _ := c.Flags().GetString("reference")
		memo, _ := c.Flags().GetString("memo")
		m := types.NewMsgCreateSpendRequest(cc.GetFromAddress().String(), a[0], a[1], bid, gid, a[2], amt, a[4], strings.TrimSpace(ref), strings.TrimSpace(memo))
		m.ValidateBasic()
		return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), m)
	}}
	cmd.Flags().String("budget-id", "", "")
	cmd.Flags().String("grant-id", "", "")
	cmd.Flags().String("reference", "", "")
	cmd.Flags().String("memo", "", "")
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}
func cApproveSpend() *cobra.Command {
	cmd := &cobra.Command{Use: "approve-spend [id]", Short: "Approve spend", Args: cobra.ExactArgs(1), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientTxContext(c)
		m := types.NewMsgApproveSpendRequest(cc.GetFromAddress().String(), a[0])
		m.ValidateBasic()
		return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), m)
	}}
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}
func cRejectSpend() *cobra.Command {
	cmd := &cobra.Command{Use: "reject-spend [id]", Short: "Reject spend", Args: cobra.ExactArgs(1), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientTxContext(c)
		memo, _ := c.Flags().GetString("memo")
		m := types.NewMsgRejectSpendRequest(cc.GetFromAddress().String(), a[0], memo)
		m.ValidateBasic()
		return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), m)
	}}
	cmd.Flags().String("memo", "", "")
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}
func cMarkExec() *cobra.Command {
	cmd := &cobra.Command{Use: "mark-spend-executed [id]", Short: "Mark spend executed", Args: cobra.ExactArgs(1), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientTxContext(c)
		ref, _ := c.Flags().GetString("reference")
		memo, _ := c.Flags().GetString("memo")
		m := types.NewMsgMarkSpendExecuted(cc.GetFromAddress().String(), a[0], strings.TrimSpace(ref), strings.TrimSpace(memo))
		m.ValidateBasic()
		return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), m)
	}}
	cmd.Flags().String("reference", "", "")
	cmd.Flags().String("memo", "", "")
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}
func cCancelSpend() *cobra.Command {
	cmd := &cobra.Command{Use: "cancel-spend [id]", Short: "Cancel spend", Args: cobra.ExactArgs(1), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientTxContext(c)
		memo, _ := c.Flags().GetString("memo")
		m := types.NewMsgCancelSpendRequest(cc.GetFromAddress().String(), a[0], memo)
		m.ValidateBasic()
		return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), m)
	}}
	cmd.Flags().String("memo", "", "")
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}
func cUpdateParams() *cobra.Command {
	cmd := &cobra.Command{Use: "update-params [enabled]", Short: "Update params", Args: cobra.ExactArgs(1), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientTxContext(c)
		p := types.DefaultParams()
		p.TreasuryEnabled = strings.ToLower(a[0]) == "true"
		m := types.NewMsgUpdateParams(cc.GetFromAddress().String(), p)
		m.ValidateBasic()
		return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), m)
	}}
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}
