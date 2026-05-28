package common

import (
	"bytes"
	"compress/gzip"
	"testing"

	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/descriptorpb"
)

func decompress(t *testing.T, raw []byte) *descriptorpb.FileDescriptorProto {
	t.Helper()
	gz, err := gzip.NewReader(bytes.NewReader(raw))
	if err != nil {
		t.Fatalf("gzip reader: %v", err)
	}
	defer gz.Close()
	var buf bytes.Buffer
	if _, err := buf.ReadFrom(gz); err != nil {
		t.Fatalf("read gzip: %v", err)
	}
	fd := &descriptorpb.FileDescriptorProto{}
	if err := proto.Unmarshal(buf.Bytes(), fd); err != nil {
		t.Fatalf("unmarshal FileDescriptorProto: %v", err)
	}
	return fd
}

func TestDescriptorsAreGzipValid(t *testing.T) {
	tests := []struct {
		name string
		raw  []byte
	}{
		{"Fees", FeesDescriptorBytes},
		{"Merchant", MerchantDescriptorBytes},
		{"Settlement", SettlementDescriptorBytes},
		{"Escrow", EscrowDescriptorBytes},
		{"Payout", PayoutDescriptorBytes},
		{"Treasury", TreasuryDescriptorBytes},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fd := decompress(t, tt.raw)
			if fd.GetName() == "" {
				t.Error("empty file descriptor name")
			}
			if len(fd.MessageType) == 0 {
				t.Error("no message types")
			}
			t.Logf("module=%s package=%s messages=%d", fd.GetName(), fd.GetPackage(), len(fd.MessageType))
			for i, mt := range fd.MessageType {
				t.Logf("  [%d] %s (fields=%d)", i, mt.GetName(), len(mt.Field))
			}
		})
	}
}

func TestDescriptorMessageCounts(t *testing.T) {
	tests := []struct {
		name    string
		raw     []byte
		minMsgs int
	}{
		{"Fees", FeesDescriptorBytes, 2},
		{"Merchant", MerchantDescriptorBytes, 7},
		{"Settlement", SettlementDescriptorBytes, 4},
		{"Escrow", EscrowDescriptorBytes, 8},
		{"Payout", PayoutDescriptorBytes, 9},
		{"Treasury", TreasuryDescriptorBytes, 12},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fd := decompress(t, tt.raw)
			if got := len(fd.MessageType); got < tt.minMsgs {
				t.Errorf("want >= %d messages, got %d", tt.minMsgs, got)
			}
		})
	}
}

func TestDescriptorsRoundTrip(t *testing.T) {
	for name, raw := range map[string][]byte{
		"Fees":       FeesDescriptorBytes,
		"Merchant":   MerchantDescriptorBytes,
		"Settlement": SettlementDescriptorBytes,
		"Escrow":     EscrowDescriptorBytes,
		"Payout":     PayoutDescriptorBytes,
		"Treasury":   TreasuryDescriptorBytes,
	} {
		t.Run(name, func(t *testing.T) {
			fd := decompress(t, raw)
			b, err := proto.Marshal(fd)
			if err != nil {
				t.Fatalf("proto.Marshal: %v", err)
			}
			fd2 := &descriptorpb.FileDescriptorProto{}
			if err := proto.Unmarshal(b, fd2); err != nil {
				t.Fatalf("proto.Unmarshal: %v", err)
			}
			if fd.GetName() != fd2.GetName() {
				t.Errorf("name mismatch: %q vs %q", fd.GetName(), fd2.GetName())
			}
			if len(fd.MessageType) != len(fd2.MessageType) {
				t.Errorf("message count mismatch: %d vs %d", len(fd.MessageType), len(fd2.MessageType))
			}
			// Verify each message index can be accessed directly.
			for i, mt := range fd.MessageType {
				if mt.GetName() == "" {
					t.Errorf("message[%d] has empty name", i)
				}
			}
		})
	}
}

func TestSpecificDescriptorIndexPaths(t *testing.T) {
	// Verify the exact descriptor index paths used by Descriptor() methods
	// match the expected message positions in the FileDescriptorProto.
	tests := []struct {
		name     string
		raw      []byte
		messages []string // expected message names at each 0-based index
	}{
		{
			"Fees", FeesDescriptorBytes,
			[]string{"Params", "MsgUpdateParams"},
		},
		{
			"Merchant", MerchantDescriptorBytes,
			[]string{"Params", "MsgRegisterMerchant", "MsgUpdateMerchant", "MsgUpdateParams", "MsgSetMerchantStatus", "MsgSetVerificationStatus", "MsgSetRebateTier"},
		},
		{
			"Settlement", SettlementDescriptorBytes,
			[]string{"Params", "MsgCreateSettlement", "MsgUpdateSettlementStatus", "MsgUpdateParams"},
		},
		{
			"Escrow", EscrowDescriptorBytes,
			[]string{"Params", "MsgCreateEscrow", "MsgReleaseEscrow", "MsgRefundEscrow", "MsgOpenDispute", "MsgResolveDispute", "MsgCancelEscrow", "MsgUpdateParams"},
		},
		{
			"Payout", PayoutDescriptorBytes,
			[]string{"Params", "PayoutInput", "MsgCreatePayout", "MsgCreateBatchPayout", "MsgApprovePayout", "MsgMarkPayoutPaid", "MsgCancelPayout", "MsgFailPayout", "MsgUpdateParams"},
		},
		{
			"Treasury", TreasuryDescriptorBytes,
			[]string{"Params", "MsgCreateTreasuryAccount", "MsgCreateBudget", "MsgUpdateBudgetStatus", "MsgCreateGrant", "MsgUpdateGrantStatus", "MsgCreateSpendRequest", "MsgApproveSpendRequest", "MsgRejectSpendRequest", "MsgMarkSpendExecuted", "MsgCancelSpendRequest", "MsgUpdateParams"},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fd := decompress(t, tt.raw)
			if len(fd.MessageType) != len(tt.messages) {
				t.Errorf("message count: want %d, got %d", len(tt.messages), len(fd.MessageType))
				return
			}
			for i, want := range tt.messages {
				got := fd.MessageType[i].GetName()
				if got != want {
					t.Errorf("index %d: want %q, got %q", i, want, got)
				}
			}
		})
	}
}
