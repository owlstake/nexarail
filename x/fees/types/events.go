package types

// Event types for the fees module.
const (
	EventTypeUpdateParams = "fees_update_params"

	AttributeKeyValidatorShareBps = "validator_share_bps"
	AttributeKeyTreasuryShareBps  = "treasury_share_bps"
	AttributeKeyBurnShareBps      = "burn_share_bps"
	AttributeKeyFeeCollectorName  = "fee_collector_name"
	AttributeKeyTreasuryAccount   = "treasury_account"
	AttributeKeyBurnEnabled       = "burn_enabled"
	AttributeKeyMinProtocolFee    = "min_protocol_fee"
	AttributeKeyAuthority         = "authority"
)
