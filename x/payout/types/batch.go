package types

import (
	"fmt"
	"strings"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

type BatchStatus int32

const (
	BatchUnspecified BatchStatus = 0
	BatchCreated     BatchStatus = 1
	BatchApproved    BatchStatus = 2
	BatchPaid        BatchStatus = 3
	BatchCancelled   BatchStatus = 4
	BatchFailed      BatchStatus = 5
)

func (s BatchStatus) String() string {
	switch s {
	case BatchCreated:
		return "created"
	case BatchApproved:
		return "approved"
	case BatchPaid:
		return "paid"
	case BatchCancelled:
		return "cancelled"
	case BatchFailed:
		return "failed"
	default:
		return "unspecified"
	}
}

var validBatchStatuses = map[int32]bool{0: true, 1: true, 2: true, 3: true, 4: true, 5: true}

type BatchPayout struct {
	BatchId          string   `json:"batch_id"`
	MerchantId       string   `json:"merchant_id"`
	InitiatorAddress string   `json:"initiator_address"`
	PayoutIds        []string `json:"payout_ids"`
	TotalAmount      sdk.Coin `json:"total_amount"`
	TotalFee         sdk.Coin `json:"total_fee"`
	TotalNet         sdk.Coin `json:"total_net"`
	Status           int32    `json:"status"`
	BatchReference   string   `json:"batch_reference"`
	Memo             string   `json:"memo"`
	CreatedAt        int64    `json:"created_at"`
	UpdatedAt        int64    `json:"updated_at"`
}

func NewBatchPayout(id, merchantID, initiator string, payoutIDs []string, totalAmt, totalFee, totalNet sdk.Coin, ref, memo string, now int64) BatchPayout {
	return BatchPayout{
		BatchId: id, MerchantId: merchantID, InitiatorAddress: initiator,
		PayoutIds: payoutIDs, TotalAmount: totalAmt, TotalFee: totalFee, TotalNet: totalNet,
		Status: int32(BatchCreated), BatchReference: strings.TrimSpace(ref), Memo: strings.TrimSpace(memo),
		CreatedAt: now, UpdatedAt: now,
	}
}
func (b *BatchPayout) ProtoMessage() {}
func (b *BatchPayout) Reset()        { *b = BatchPayout{} }
func (b *BatchPayout) String() string {
	return fmt.Sprintf("Batch{id=%s, payouts=%d}", b.BatchId, len(b.PayoutIds))
}

func (b BatchPayout) ValidateWithParams(p Params) error {
	if len(b.BatchId) < 3 || len(b.BatchId) > 80 {
		return fmt.Errorf("batch id length %d: %w", len(b.BatchId), ErrInvalidPayoutID)
	}
	if !payoutIDRegex.MatchString(b.BatchId) {
		return fmt.Errorf("batch id format: %w", ErrInvalidPayoutID)
	}
	if strings.TrimSpace(b.MerchantId) == "" {
		return fmt.Errorf("merchant: %w", ErrInvalidMerchantID)
	}
	if _, err := sdk.AccAddressFromBech32(b.InitiatorAddress); err != nil {
		return fmt.Errorf("initiator: %w", ErrInvalidInitiator)
	}
	if len(b.PayoutIds) == 0 {
		return fmt.Errorf("empty payouts: %w", ErrInvalidPayoutID)
	}
	if uint32(len(b.PayoutIds)) > p.MaxBatchSize {
		return fmt.Errorf("batch size %d > max %d: %w", len(b.PayoutIds), p.MaxBatchSize, ErrInvalidPayoutID)
	}
	seen := make(map[string]bool)
	for _, pid := range b.PayoutIds {
		if seen[pid] {
			return fmt.Errorf("duplicate payout %s in batch: %w", pid, ErrInvalidPayoutID)
		}
		seen[pid] = true
	}
	if b.TotalAmount.IsNegative() {
		return fmt.Errorf("total: %w", ErrInvalidFee)
	}
	if b.TotalFee.IsNegative() {
		return fmt.Errorf("total_fee: %w", ErrInvalidFee)
	}
	if b.TotalNet.IsNegative() {
		return fmt.Errorf("total_net: %w", ErrInvalidFee)
	}
	if !validBatchStatuses[b.Status] {
		return fmt.Errorf("batch status %d: %w", b.Status, ErrInvalidStatus)
	}
	if len(b.BatchReference) > int(p.MaxReferenceLength) {
		return fmt.Errorf("ref: %w", ErrReferenceTooLong)
	}
	if len(b.Memo) > int(p.MaxMemoLength) {
		return fmt.Errorf("memo: %w", ErrMemoTooLong)
	}
	return nil
}
