package cli

import (
	"strconv"
	"strings"

	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/client/flags"
	"github.com/cosmos/cosmos-sdk/client/tx"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/nexarail/chain/x/payout/types"
	"github.com/spf13/cobra"
)

func GetTxCmd() *cobra.Command {
	cmd := &cobra.Command{Use: types.ModuleName, Short: "Payout tx", DisableFlagParsing: true, SuggestionsMinimumDistance: 2, RunE: client.ValidateCmd}
	cmd.AddCommand(cCreate(), cBatch(), cApprove(), cMarkPaid(), cCancel(), cFail(), cParams())
	return cmd
}
func cCreate() *cobra.Command {
	cmd := &cobra.Command{
		Use: "create [id] [merchant-id] [recipient] [amount] [payout-type]", Short: "Create payout", Args: cobra.ExactArgs(5),
		RunE: func(c *cobra.Command, args []string) error {
			cc, _ := client.GetClientTxContext(c)
			amt, err := sdk.ParseCoinNormalized(args[3])
			if err != nil {
				return err
			}
			pt, _ := strconv.ParseInt(args[4], 10, 32)
			ref, _ := c.Flags().GetString("payout-reference")
			memo, _ := c.Flags().GetString("memo")
			msg := types.NewMsgCreatePayout(cc.GetFromAddress().String(), args[0], args[1], args[2], amt.Denom, amt, int32(pt), strings.TrimSpace(ref), strings.TrimSpace(memo))
			if err := msg.ValidateBasic(); err != nil {
				return err
			}
			return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), msg)
		},
	}
	cmd.Flags().String("payout-reference", "", "Ref")
	cmd.Flags().String("memo", "", "Memo")
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}
func cBatch() *cobra.Command {
	cmd := &cobra.Command{
		Use: "create-batch [batch-id] [merchant-id] [recipient] [amount] [payout-type] [payout-id]", Short: "Create batch payout (single for CLI)", Args: cobra.MinimumNArgs(6),
		RunE: func(c *cobra.Command, args []string) error {
			cc, _ := client.GetClientTxContext(c)
			amt, err := sdk.ParseCoinNormalized(args[3])
			if err != nil {
				return err
			}
			pt, _ := strconv.ParseInt(args[4], 10, 32)
			ref, _ := c.Flags().GetString("batch-reference")
			memo, _ := c.Flags().GetString("memo")
			msg := types.NewMsgCreateBatchPayout(cc.GetFromAddress().String(), args[0], args[1], []types.PayoutInput{
				{PayoutId: args[5], RecipientAddress: args[2], Amount: amt, AssetDenom: amt.Denom, PayoutType: int32(pt)},
			}, strings.TrimSpace(ref), strings.TrimSpace(memo))
			if err := msg.ValidateBasic(); err != nil {
				return err
			}
			return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), msg)
		},
	}
	cmd.Flags().String("batch-reference", "", "Ref")
	cmd.Flags().String("memo", "", "Memo")
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}
func cApprove() *cobra.Command {
	cmd := &cobra.Command{Use: "approve [id]", Short: "Approve payout", Args: cobra.ExactArgs(1), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientTxContext(c)
		m := types.NewMsgApprovePayout(cc.GetFromAddress().String(), a[0])
		m.ValidateBasic()
		return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), m)
	}}
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}
func cMarkPaid() *cobra.Command {
	cmd := &cobra.Command{Use: "mark-paid [id] [ext-ref]", Short: "Mark paid (authority)", Args: cobra.ExactArgs(2), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientTxContext(c)
		memo, _ := c.Flags().GetString("memo")
		m := types.NewMsgMarkPayoutPaid(cc.GetFromAddress().String(), a[0], a[1], strings.TrimSpace(memo))
		m.ValidateBasic()
		return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), m)
	}}
	cmd.Flags().String("memo", "", "")
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}
func cCancel() *cobra.Command {
	cmd := &cobra.Command{Use: "cancel [id]", Short: "Cancel payout", Args: cobra.ExactArgs(1), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientTxContext(c)
		memo, _ := c.Flags().GetString("memo")
		m := types.NewMsgCancelPayout(cc.GetFromAddress().String(), a[0], strings.TrimSpace(memo))
		m.ValidateBasic()
		return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), m)
	}}
	cmd.Flags().String("memo", "", "")
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}
func cFail() *cobra.Command {
	cmd := &cobra.Command{Use: "fail [id] [reason]", Short: "Fail payout (authority)", Args: cobra.ExactArgs(2), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientTxContext(c)
		m := types.NewMsgFailPayout(cc.GetFromAddress().String(), a[0], a[1])
		m.ValidateBasic()
		return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), m)
	}}
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}
func cParams() *cobra.Command {
	cmd := &cobra.Command{Use: "update-params [enabled]", Short: "Update params (authority)", Args: cobra.ExactArgs(1), RunE: func(c *cobra.Command, a []string) error {
		cc, _ := client.GetClientTxContext(c)
		p := types.DefaultParams()
		p.PayoutsEnabled = strings.ToLower(a[0]) == "true"
		m := types.NewMsgUpdateParams(cc.GetFromAddress().String(), p)
		m.ValidateBasic()
		return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), m)
	}}
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}
