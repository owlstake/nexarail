package types

const (
	EventTypeCreateSettlement       = "settlement_created"
	EventTypeUpdateSettlementStatus = "settlement_status_updated"

	AttributeKeySettlementId   = "settlement_id"
	AttributeKeyPayer          = "payer"
	AttributeKeyMerchantOwner  = "merchant_owner"
	AttributeKeyAmount         = "amount"
	AttributeKeyFeeAmount      = "fee_amount"
	AttributeKeyValidatorShare = "validator_share"
	AttributeKeyTreasuryShare  = "treasury_share"
	AttributeKeyBurnShare      = "burn_share"
	AttributeKeyRebateBps      = "rebate_bps"
	AttributeKeyStatus         = "status"
	AttributeKeyFundsSettled   = "funds_settled"
	AttributeKeyTreasuryRouted = "treasury_routed"
	AttributeKeyBurnRouted     = "burn_routed"
	AttributeKeyMetadata       = "metadata"
	AttributeKeyAuthority      = "authority"
	EventTypeUpdateParams       = "settlement_params_updated"
)

