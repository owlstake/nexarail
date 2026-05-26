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

	"github.com/nexarail/chain/x/fees/types"
)

// GetTxCmd returns the transaction CLI commands for the fees module.
func GetTxCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:                        types.ModuleName,
		Short:                      "Transaction commands for the fees module",
		DisableFlagParsing:         true,
		SuggestionsMinimumDistance: 2,
		RunE:                       client.ValidateCmd,
	}

	cmd.AddCommand(
		GetCmdUpdateParams(),
	)

	return cmd
}

// GetCmdUpdateParams returns the update params command.
func GetCmdUpdateParams() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "update-params [validator-share-bps] [treasury-share-bps] [burn-share-bps] [fee-collector-name] [treasury-account] [burn-enabled] [min-fee]",
		Short: "Update the fees module parameters (governance only)",
		Args:  cobra.ExactArgs(7),
		Long: `Update the fee split parameters. Only the module authority (governance) may execute this.

Arguments:
  validator-share-bps   Validator/delegator share in basis points (e.g. 6000)
  treasury-share-bps    Treasury share in basis points (e.g. 2000)
  burn-share-bps        Burn share in basis points (e.g. 2000)
  fee-collector-name    Name of the fee collector account (e.g. "fee_collector")
  treasury-account      Treasury account bech32 address (empty string to disable)
  burn-enabled          Enable burn mechanism (true/false)
  min-fee               Minimum protocol fee as coin (e.g. "1unxrl")

All three shares must total 10000 basis points.

Example:
  nexaraild tx fees update-params 6000 2000 2000 fee_collector "" false 1unxrl --from gov --chain-id nexarail-devnet-1
`,
		RunE: func(cmd *cobra.Command, args []string) error {
			clientCtx, err := client.GetClientTxContext(cmd)
			if err != nil {
				return err
			}

			validatorBps, err := strconv.ParseUint(args[0], 10, 32)
			if err != nil {
				return fmt.Errorf("invalid validator share bps: %w", err)
			}

			treasuryBps, err := strconv.ParseUint(args[1], 10, 32)
			if err != nil {
				return fmt.Errorf("invalid treasury share bps: %w", err)
			}

			burnBps, err := strconv.ParseUint(args[2], 10, 32)
			if err != nil {
				return fmt.Errorf("invalid burn share bps: %w", err)
			}

			feeCollectorName := args[3]

			treasuryAccount := args[4]
			if treasuryAccount == "" || treasuryAccount == "\"\"" {
				treasuryAccount = ""
			}

			burnEnabled := strings.ToLower(args[5]) == "true"

			minFee, err := sdk.ParseCoinNormalized(args[6])
			if err != nil {
				return fmt.Errorf("invalid min fee: %w", err)
			}

			params := types.Params{
				ValidatorShareBps: uint32(validatorBps),
				TreasuryShareBps:  uint32(treasuryBps),
				BurnShareBps:      uint32(burnBps),
				FeeCollectorName:  feeCollectorName,
				TreasuryAccount:   treasuryAccount,
				BurnEnabled:       burnEnabled,
				MinProtocolFee:    minFee,
			}

			msg := types.NewMsgUpdateParams(clientCtx.GetFromAddress().String(), params)
			if err := msg.ValidateBasic(); err != nil {
				return fmt.Errorf("invalid message: %w", err)
			}

			return tx.GenerateOrBroadcastTxCLI(clientCtx, cmd.Flags(), msg)
		},
	}

	flags.AddTxFlagsToCmd(cmd)
	return cmd
}
