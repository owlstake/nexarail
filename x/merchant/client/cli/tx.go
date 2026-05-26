package cli

import (
	"fmt"
	"strings"

	"github.com/spf13/cobra"

	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/client/flags"
	"github.com/cosmos/cosmos-sdk/client/tx"
	sdk "github.com/cosmos/cosmos-sdk/types"

	"github.com/nexarail/chain/x/merchant/types"
)

func GetTxCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:                        types.ModuleName,
		Short:                      "Transaction commands for the merchant module",
		DisableFlagParsing:         true,
		SuggestionsMinimumDistance: 2,
		RunE:                       client.ValidateCmd,
	}
	cmd.AddCommand(GetCmdRegisterMerchant(), GetCmdUpdateMerchant())
	return cmd
}

func GetCmdRegisterMerchant() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "register [name] [description] [website]",
		Short: "Register a new merchant",
		Args:  cobra.ExactArgs(3),
		Long: `Register a new merchant on the NexaRail protocol.

The registration fee is set by governance params (default 1000000unxrl = 1 NXRL).

Example:
  nexaraild tx merchant register "Acme Rail" "Rail logistics provider" "https://acme.example.com" \
    --from merchant-owner --chain-id nexarail-devnet-1 --gas auto
`,
		RunE: func(cmd *cobra.Command, args []string) error {
			clientCtx, err := client.GetClientTxContext(cmd)
			if err != nil {
				return err
			}

			msg := types.NewMsgRegisterMerchant(
				clientCtx.GetFromAddress(),
				strings.TrimSpace(args[0]),
				strings.TrimSpace(args[1]),
				strings.TrimSpace(args[2]),
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

func GetCmdUpdateMerchant() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "update [owner] [name] [description] [website]",
		Short: "Update an existing merchant profile",
		Args:  cobra.ExactArgs(4),
		Long: `Update the profile of a registered merchant. Only the merchant owner may update.

Provide empty "" for fields you do not wish to change.

Example:
  nexaraild tx merchant update nxr1... "New Name" "" "https://new.example.com" \
    --from merchant-owner --chain-id nexarail-devnet-1 --gas auto
`,
		RunE: func(cmd *cobra.Command, args []string) error {
			clientCtx, err := client.GetClientTxContext(cmd)
			if err != nil {
				return err
			}

			owner, err := sdk.AccAddressFromBech32(args[0])
			if err != nil {
				return fmt.Errorf("invalid owner address: %w", err)
			}

			msg := types.NewMsgUpdateMerchant(
				owner,
				strings.TrimSpace(args[1]),
				strings.TrimSpace(args[2]),
				strings.TrimSpace(args[3]),
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
