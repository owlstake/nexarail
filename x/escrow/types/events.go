package types

const (
	EventCreateEscrow   = "escrow_created"
	EventReleaseEscrow  = "escrow_released"
	EventRefundEscrow   = "escrow_refunded"
	EventDisputeEscrow  = "escrow_disputed"
	EventResolveDispute = "escrow_dispute_resolved"
	EventCancelEscrow   = "escrow_cancelled"
	EventUpdateParams   = "escrow_params_updated"

	AttrEscrowId         = "escrow_id"
	AttrBuyer            = "buyer_address"
	AttrSeller           = "seller_address"
	AttrMerchantId       = "merchant_id"
	AttrAmount           = "amount"
	AttrAssetDenom       = "asset_denom"
	AttrStatus           = "status"
	AttrDisputeStatus    = "dispute_status"
	AttrReason           = "reason"
	AttrResolutionNote   = "resolution_note"
	AttrReleaseReference = "release_reference"
	AttrRefundReference  = "refund_reference"
	AttrSigner           = "signer"
)
