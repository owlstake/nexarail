package cli

import (
	"fmt"
	"strconv"
	"strings"

	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/client/flags"
	"github.com/cosmos/cosmos-sdk/client/tx"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/nexarail/chain/x/escrow/types"
	"github.com/spf13/cobra"
)

func GetTxCmd() *cobra.Command {
	cmd := &cobra.Command{Use: types.ModuleName, Short: "Escrow tx commands", DisableFlagParsing: true, SuggestionsMinimumDistance: 2, RunE: client.ValidateCmd}
	cmd.AddCommand(cmdCreate(), cmdRelease(), cmdRefund(), cmdDispute(), cmdResolve(), cmdCancel(), cmdUpdateParams())
	return cmd
}

func cmdCreate() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "create [escrow-id] [seller-address] [merchant-id] [amount]",
		Short: "Create an escrow",
		Args:  cobra.ExactArgs(4),
		Long: `Create a new escrow. The buyer is the --from address.

Example:
  nexaraild tx escrow create order-123 nxr1seller merchant-1 1000000unxrl \
    --payment-reference "Invoice ABC" --memo "30-day net" --from buyer --gas auto
`,
		RunE: func(c *cobra.Command, args []string) error {
			cc, _ := client.GetClientTxContext(c)
			amount, err := sdk.ParseCoinNormalized(args[3])
			if err != nil {
				return fmt.Errorf("amount: %w", err)
			}
			ref, _ := c.Flags().GetString("payment-reference")
			memo, _ := c.Flags().GetString("memo")
			expiry, _ := c.Flags().GetInt64("expires-at")

			msg := types.NewMsgCreateEscrow(cc.GetFromAddress().String(), args[0], args[1], args[2], amount.Denom, amount,
				strings.TrimSpace(ref), strings.TrimSpace(memo), expiry)
			if err := msg.ValidateBasic(); err != nil {
				return fmt.Errorf("invalid: %w", err)
			}
			return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), msg)
		},
	}
	cmd.Flags().String("payment-reference", "", "Payment reference")
	cmd.Flags().String("memo", "", "Escrow memo")
	cmd.Flags().Int64("expires-at", 0, "Expiry timestamp (0 = default)")
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}

func cmdRelease() *cobra.Command {
	cmd := &cobra.Command{
		Use: "release [escrow-id]", Short: "Release an escrow (buyer or authority)", Args: cobra.ExactArgs(1),
		RunE: func(c *cobra.Command, args []string) error {
			cc, _ := client.GetClientTxContext(c)
			ref, _ := c.Flags().GetString("release-reference")
			memo, _ := c.Flags().GetString("memo")
			msg := types.NewMsgReleaseEscrow(cc.GetFromAddress().String(), args[0], strings.TrimSpace(ref), strings.TrimSpace(memo))
			if err := msg.ValidateBasic(); err != nil {
				return fmt.Errorf("invalid: %w", err)
			}
			return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), msg)
		},
	}
	cmd.Flags().String("release-reference", "", "Release reference")
	cmd.Flags().String("memo", "", "Memo")
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}

func cmdRefund() *cobra.Command {
	cmd := &cobra.Command{
		Use: "refund [escrow-id]", Short: "Refund an escrow (seller or authority)", Args: cobra.ExactArgs(1),
		RunE: func(c *cobra.Command, args []string) error {
			cc, _ := client.GetClientTxContext(c)
			ref, _ := c.Flags().GetString("refund-reference")
			memo, _ := c.Flags().GetString("memo")
			msg := types.NewMsgRefundEscrow(cc.GetFromAddress().String(), args[0], strings.TrimSpace(ref), strings.TrimSpace(memo))
			if err := msg.ValidateBasic(); err != nil {
				return fmt.Errorf("invalid: %w", err)
			}
			return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), msg)
		},
	}
	cmd.Flags().String("refund-reference", "", "Refund reference")
	cmd.Flags().String("memo", "", "Memo")
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}

func cmdDispute() *cobra.Command {
	cmd := &cobra.Command{
		Use: "dispute [escrow-id] [reason]", Short: "Open a dispute (buyer or seller)", Args: cobra.ExactArgs(2),
		RunE: func(c *cobra.Command, args []string) error {
			cc, _ := client.GetClientTxContext(c)
			msg := types.NewMsgOpenDispute(cc.GetFromAddress().String(), args[0], strings.TrimSpace(args[1]))
			if err := msg.ValidateBasic(); err != nil {
				return fmt.Errorf("invalid: %w", err)
			}
			return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), msg)
		},
	}
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}

func cmdResolve() *cobra.Command {
	cmd := &cobra.Command{
		Use: "resolve-dispute [escrow-id] [resolution]", Short: "Resolve a dispute (authority only)", Args: cobra.ExactArgs(2),
		Long: `Resolution values: 3=buyer_wins, 4=seller_wins, 5=settled, 6=rejected`,
		RunE: func(c *cobra.Command, args []string) error {
			cc, _ := client.GetClientTxContext(c)
			ds, err := strconv.ParseInt(args[1], 10, 32)
			if err != nil {
				return fmt.Errorf("resolution: %w", err)
			}
			note, _ := c.Flags().GetString("resolution-note")
			msg := types.NewMsgResolveDispute(cc.GetFromAddress().String(), args[0], int32(ds), strings.TrimSpace(note))
			if err := msg.ValidateBasic(); err != nil {
				return fmt.Errorf("invalid: %w", err)
			}
			return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), msg)
		},
	}
	cmd.Flags().String("resolution-note", "", "Resolution note")
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}

func cmdCancel() *cobra.Command {
	cmd := &cobra.Command{
		Use: "cancel [escrow-id]", Short: "Cancel an escrow (buyer or authority)", Args: cobra.ExactArgs(1),
		RunE: func(c *cobra.Command, args []string) error {
			cc, _ := client.GetClientTxContext(c)
			memo, _ := c.Flags().GetString("memo")
			msg := types.NewMsgCancelEscrow(cc.GetFromAddress().String(), args[0], strings.TrimSpace(memo))
			if err := msg.ValidateBasic(); err != nil {
				return fmt.Errorf("invalid: %w", err)
			}
			return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), msg)
		},
	}
	cmd.Flags().String("memo", "", "Memo")
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}

func cmdUpdateParams() *cobra.Command {
	cmd := &cobra.Command{
		Use: "update-params [enabled]", Short: "Update params (authority only)", Args: cobra.ExactArgs(1),
		RunE: func(c *cobra.Command, args []string) error {
			cc, _ := client.GetClientTxContext(c)
			enabled := strings.ToLower(args[0]) == "true"
			p := types.DefaultParams()
			p.EscrowsEnabled = enabled
			msg := types.NewMsgUpdateParams(cc.GetFromAddress().String(), p)
			if err := msg.ValidateBasic(); err != nil {
				return fmt.Errorf("invalid: %w", err)
			}
			return tx.GenerateOrBroadcastTxCLI(cc, c.Flags(), msg)
		},
	}
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}
