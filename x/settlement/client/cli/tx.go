package cli

import (
	"fmt"
	"strconv"
	"strings"

	"github.com/spf13/cobra"

	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/client/flags"
	"github.com/cosmos/cosmos-sdk/client/tx"
	sdk "github.com/cosmos/cosmos-sdk/types"

	"github.com/nexarail/chain/x/settlement/types"
)

func GetTxCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:                        types.ModuleName,
		Short:                      "Transaction commands for the settlement module",
		DisableFlagParsing:         true,
		SuggestionsMinimumDistance: 2,
		RunE:                       client.ValidateCmd,
	}
	cmd.AddCommand(
		GetCmdCreateSettlement(),
		GetCmdUpdateSettlementStatus(),
		GetCmdUpdateParams(),
	)
	return cmd
}

func GetCmdCreateSettlement() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "create [merchant-owner] [amount]",
		Short: "Create a new settlement (payer is the from address)",
		Args:  cobra.ExactArgs(2),
		Long: `Create a settlement payment to a merchant.

The merchant must be registered and active. The fee is calculated automatically
based on the x/fees split parameters and the merchant's rebate tier.

Example:
  nexaraild tx settlement create nxr1merchant 1000000unxrl \
    --metadata "Order #12345" \
    --from payer --chain-id nexarail-devnet-1 --gas auto
`,
		RunE: func(cmd *cobra.Command, args []string) error {
			clientCtx, err := client.GetClientTxContext(cmd)
			if err != nil {
				return err
			}

			amount, err := sdk.ParseCoinNormalized(args[1])
			if err != nil {
				return fmt.Errorf("invalid amount: %w", err)
			}

			metadata, _ := cmd.Flags().GetString("metadata")

			msg := types.NewMsgCreateSettlement(
				clientCtx.GetFromAddress().String(),
				args[0],
				amount,
				strings.TrimSpace(metadata),
			)
			if err := msg.ValidateBasic(); err != nil {
				return fmt.Errorf("invalid message: %w", err)
			}
			return tx.GenerateOrBroadcastTxCLI(clientCtx, cmd.Flags(), msg)
		},
	}
	cmd.Flags().String("metadata", "", "Settlement metadata")
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}

func GetCmdUpdateSettlementStatus() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "update-status [settlement-id] [status]",
		Short: "Update a settlement status (authority only)",
		Args:  cobra.ExactArgs(2),
		Long: `Update a settlement's status. Only the module authority may execute this.

Status values:
  0 = pending
  1 = completed
  2 = failed
  3 = refunded
  4 = cancelled

Terminal statuses (failed, refunded, cancelled) cannot transition to other statuses.

Example:
  nexaraild tx settlement update-status 42 2 \
    --from gov --chain-id nexarail-devnet-1 --gas auto
`,
		RunE: func(cmd *cobra.Command, args []string) error {
			clientCtx, err := client.GetClientTxContext(cmd)
			if err != nil {
				return err
			}

			id, err := strconv.ParseUint(args[0], 10, 64)
			if err != nil {
				return fmt.Errorf("invalid settlement ID: %w", err)
			}
			status, err := strconv.ParseInt(args[1], 10, 32)
			if err != nil {
				return fmt.Errorf("invalid status: %w", err)
			}

			msg := types.NewMsgUpdateSettlementStatus(
				clientCtx.GetFromAddress().String(),
				id,
				int32(status),
			)
			if err := msg.ValidateBasic(); err != nil {
				return fmt.Errorf("invalid message: %w", err)
			}
			return tx.GenerateOrBroadcastTxCLI(clientCtx, cmd.Flags(), msg)
		},
	}
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}

func GetCmdUpdateParams() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "update-params [fee-rate-bps] [enabled]",
		Short: "Update settlement module parameters (authority only)",
		Args:  cobra.ExactArgs(2),
		Long: `Update settlement parameters. Only the module authority may execute this.

Example:
  nexaraild tx settlement update-params 100 true \
    --from gov --chain-id nexarail-devnet-1 --gas auto
`,
		RunE: func(cmd *cobra.Command, args []string) error {
			clientCtx, err := client.GetClientTxContext(cmd)
			if err != nil {
				return err
			}

			feeRate, err := strconv.ParseUint(args[0], 10, 32)
			if err != nil {
				return fmt.Errorf("invalid fee rate bps: %w", err)
			}
			enabled := strings.ToLower(args[1]) == "true"

			params := types.DefaultParams()
			params.FeeRateBps = uint32(feeRate)
			params.Enabled = enabled

			msg := types.NewMsgUpdateParams(
				clientCtx.GetFromAddress().String(),
				params,
			)
			if err := msg.ValidateBasic(); err != nil {
				return fmt.Errorf("invalid message: %w", err)
			}
			return tx.GenerateOrBroadcastTxCLI(clientCtx, cmd.Flags(), msg)
		},
	}
	flags.AddTxFlagsToCmd(cmd)
	return cmd
}
