package types

const (
	EventCreateAccount = "treasury_account_created"
	EventCreateBudget  = "budget_created"
	EventUpdateBudget  = "budget_status_updated"
	EventCreateGrant   = "grant_created"
	EventUpdateGrant   = "grant_status_updated"
	EventCreateSpend   = "spend_request_created"
	EventApproveSpend  = "spend_request_approved"
	EventRejectSpend   = "spend_request_rejected"
	EventExecuteSpend  = "spend_request_executed"
	EventCancelSpend   = "spend_request_cancelled"
	EventUpdateParams  = "treasury_params_updated"
	AttrAccountId      = "account_id"
	AttrBudgetId       = "budget_id"
	AttrGrantId        = "grant_id"
	AttrSpendId        = "spend_id"
	AttrAmount         = "amount"
	AttrStatus         = "status"
	AttrCategory       = "category"
	AttrRequester      = "requester"
	AttrRecipient      = "recipient"
)
