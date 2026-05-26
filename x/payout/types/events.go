package types

const (
	EventCreatePayout  = "payout_created"
	EventCreateBatch   = "batch_payout_created"
	EventApprovePayout = "payout_approved"
	EventPayPayout     = "payout_paid"
	EventCancelPayout  = "payout_cancelled"
	EventFailPayout    = "payout_failed"
	EventUpdateParams  = "payout_params_updated"

	AttrPayoutId   = "payout_id"
	AttrBatchId    = "batch_id"
	AttrMerchantId = "merchant_id"
	AttrInitiator  = "initiator"
	AttrRecipient  = "recipient"
	AttrAmount     = "amount"
	AttrStatus     = "status"
	AttrType       = "payout_type"
	AttrRef        = "reference"
	AttrReason     = "reason"
	AttrFundsPaid  = "funds_paid"
)
