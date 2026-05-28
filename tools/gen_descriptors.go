//go:build ignore

package main

import (
	"bytes"
	"compress/gzip"
	"fmt"
	"go/format"
	"os"

	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/descriptorpb"
)

type field struct {
	name     string
	number   int32
	typ      descriptorpb.FieldDescriptorProto_Type
	typeName string
	repeated bool
}

type message struct {
	name   string
	fields []field
}

type module struct {
	goName  string
	pkg     string
	proto   string
	msgs    []message
	imports []string
}

var (
	tString  = descriptorpb.FieldDescriptorProto_TYPE_STRING
	tBool    = descriptorpb.FieldDescriptorProto_TYPE_BOOL
	tInt32   = descriptorpb.FieldDescriptorProto_TYPE_INT32
	tInt64   = descriptorpb.FieldDescriptorProto_TYPE_INT64
	tUint32  = descriptorpb.FieldDescriptorProto_TYPE_UINT32
	tUint64  = descriptorpb.FieldDescriptorProto_TYPE_UINT64
	tMessage = descriptorpb.FieldDescriptorProto_TYPE_MESSAGE
)

const coinType = ".cosmos.base.v1beta1.Coin"

func main() {
	modules := []module{
		{
			goName: "Fees", pkg: "nexarail.fees.v1", proto: "nexarail/fees/v1/tx.proto",
			imports: []string{"cosmos/base/v1beta1/coin.proto"},
			msgs: []message{
				{"Params", []field{
					{"validator_share_bps", 1, tUint32, "", false},
					{"treasury_share_bps", 2, tUint32, "", false},
					{"burn_share_bps", 3, tUint32, "", false},
					{"fee_collector_name", 4, tString, "", false},
					{"treasury_account", 5, tString, "", false},
					{"burn_enabled", 6, tBool, "", false},
					{"min_protocol_fee", 7, tMessage, coinType, false},
				}},
				{"MsgUpdateParams", []field{
					{"authority", 1, tString, "", false},
					{"params", 2, tMessage, ".nexarail.fees.v1.Params", false},
				}},
			},
		},
		{
			goName: "Merchant", pkg: "nexarail.merchant.v1", proto: "nexarail/merchant/v1/tx.proto",
			imports: []string{"cosmos/base/v1beta1/coin.proto"},
			msgs: []message{
				{"Params", []field{
					{"registration_fee", 1, tMessage, coinType, false},
					{"min_name_length", 2, tUint32, "", false},
					{"max_name_length", 3, tUint32, "", false},
					{"max_description_length", 4, tUint32, "", false},
				}},
				{"MsgRegisterMerchant", []field{
					{"owner", 1, tString, "", false},
					{"name", 2, tString, "", false},
					{"description", 3, tString, "", false},
					{"website", 4, tString, "", false},
				}},
				{"MsgUpdateMerchant", []field{
					{"owner", 1, tString, "", false},
					{"name", 2, tString, "", false},
					{"description", 3, tString, "", false},
					{"website", 4, tString, "", false},
				}},
				{"MsgUpdateParams", []field{
					{"authority", 1, tString, "", false},
					{"params", 2, tMessage, ".nexarail.merchant.v1.Params", false},
				}},
				{"MsgSetMerchantStatus", []field{
					{"authority", 1, tString, "", false},
					{"owner", 2, tString, "", false},
					{"status", 3, tInt32, "", false},
				}},
				{"MsgSetVerificationStatus", []field{
					{"authority", 1, tString, "", false},
					{"owner", 2, tString, "", false},
					{"status", 3, tInt32, "", false},
				}},
				{"MsgSetRebateTier", []field{
					{"authority", 1, tString, "", false},
					{"owner", 2, tString, "", false},
					{"tier", 3, tInt32, "", false},
				}},
			},
		},
		{
			goName: "Settlement", pkg: "nexarail.settlement.v1", proto: "nexarail/settlement/v1/tx.proto",
			imports: []string{"cosmos/base/v1beta1/coin.proto"},
			msgs: []message{
				{"Params", []field{
					{"enabled", 1, tBool, "", false},
					{"live_enabled", 2, tBool, "", false},
					{"treasury_routing_enabled", 3, tBool, "", false},
					{"burn_routing_enabled", 4, tBool, "", false},
					{"fee_rate_bps", 5, tUint32, "", false},
					{"rebate_tiers", 6, tUint32, "", true},
				}},
				{"MsgCreateSettlement", []field{
					{"payer", 1, tString, "", false},
					{"merchant_owner", 2, tString, "", false},
					{"amount", 3, tMessage, coinType, false},
					{"metadata", 4, tString, "", false},
				}},
				{"MsgUpdateSettlementStatus", []field{
					{"authority", 1, tString, "", false},
					{"id", 2, tUint64, "", false},
					{"status", 3, tInt32, "", false},
				}},
				{"MsgUpdateParams", []field{
					{"authority", 1, tString, "", false},
					{"params", 2, tMessage, ".nexarail.settlement.v1.Params", false},
				}},
			},
		},
		{
			goName: "Escrow", pkg: "nexarail.escrow.v1", proto: "nexarail/escrow/v1/tx.proto",
			imports: []string{"cosmos/base/v1beta1/coin.proto"},
			msgs: []message{
				{"Params", []field{
					{"escrows_enabled", 1, tBool, "", false},
					{"live_enabled", 2, tBool, "", false},
					{"max_reference_length", 3, tUint32, "", false},
					{"max_memo_length", 4, tUint32, "", false},
					{"max_dispute_reason_length", 5, tUint32, "", false},
					{"max_resolution_note_length", 6, tUint32, "", false},
					{"min_escrow_amount", 7, tMessage, coinType, false},
					{"default_expiry_seconds", 8, tUint64, "", false},
				}},
				{"MsgCreateEscrow", []field{
					{"buyer", 1, tString, "", false},
					{"escrow_id", 2, tString, "", false},
					{"seller_address", 3, tString, "", false},
					{"merchant_id", 4, tString, "", false},
					{"asset_denom", 5, tString, "", false},
					{"amount", 6, tMessage, coinType, false},
					{"payment_reference", 7, tString, "", false},
					{"memo", 8, tString, "", false},
					{"expires_at", 9, tInt64, "", false},
				}},
				{"MsgReleaseEscrow", []field{
					{"signer", 1, tString, "", false},
					{"escrow_id", 2, tString, "", false},
					{"release_reference", 3, tString, "", false},
					{"memo", 4, tString, "", false},
				}},
				{"MsgRefundEscrow", []field{
					{"signer", 1, tString, "", false},
					{"escrow_id", 2, tString, "", false},
					{"refund_reference", 3, tString, "", false},
					{"memo", 4, tString, "", false},
				}},
				{"MsgOpenDispute", []field{
					{"signer", 1, tString, "", false},
					{"escrow_id", 2, tString, "", false},
					{"dispute_reason", 3, tString, "", false},
				}},
				{"MsgResolveDispute", []field{
					{"authority", 1, tString, "", false},
					{"escrow_id", 2, tString, "", false},
					{"dispute_status", 3, tInt32, "", false},
					{"resolution_note", 4, tString, "", false},
				}},
				{"MsgCancelEscrow", []field{
					{"signer", 1, tString, "", false},
					{"escrow_id", 2, tString, "", false},
					{"memo", 3, tString, "", false},
				}},
				{"MsgUpdateParams", []field{
					{"authority", 1, tString, "", false},
					{"params", 2, tMessage, ".nexarail.escrow.v1.Params", false},
				}},
			},
		},
		{
			goName: "Payout", pkg: "nexarail.payout.v1", proto: "nexarail/payout/v1/tx.proto",
			imports: []string{"cosmos/base/v1beta1/coin.proto"},
			msgs: []message{
				{"Params", []field{
					{"payouts_enabled", 1, tBool, "", false},
					{"batch_payouts_enabled", 2, tBool, "", false},
					{"approval_required", 3, tBool, "", false},
					{"live_enabled", 4, tBool, "", false},
					{"max_reference_length", 5, tUint32, "", false},
					{"max_memo_length", 6, tUint32, "", false},
					{"max_failure_reason_length", 7, tUint32, "", false},
					{"max_batch_size", 8, tUint32, "", false},
					{"min_payout_amount", 9, tMessage, coinType, false},
				}},
				{"PayoutInput", []field{
					{"payout_id", 1, tString, "", false},
					{"recipient_address", 2, tString, "", false},
					{"amount", 3, tMessage, coinType, false},
					{"asset_denom", 4, tString, "", false},
					{"payout_type", 5, tInt32, "", false},
					{"payout_reference", 6, tString, "", false},
					{"memo", 7, tString, "", false},
				}},
				{"MsgCreatePayout", []field{
					{"initiator", 1, tString, "", false},
					{"payout_id", 2, tString, "", false},
					{"merchant_id", 3, tString, "", false},
					{"recipient_address", 4, tString, "", false},
					{"amount", 5, tMessage, coinType, false},
					{"asset_denom", 6, tString, "", false},
					{"payout_type", 7, tInt32, "", false},
					{"payout_reference", 8, tString, "", false},
					{"memo", 9, tString, "", false},
				}},
				{"MsgCreateBatchPayout", []field{
					{"initiator", 1, tString, "", false},
					{"batch_id", 2, tString, "", false},
					{"merchant_id", 3, tString, "", false},
					{"payouts", 4, tMessage, ".nexarail.payout.v1.PayoutInput", true},
					{"batch_reference", 5, tString, "", false},
					{"memo", 6, tString, "", false},
				}},
				{"MsgApprovePayout", []field{{"signer", 1, tString, "", false}, {"payout_id", 2, tString, "", false}}},
				{"MsgMarkPayoutPaid", []field{{"authority", 1, tString, "", false}, {"payout_id", 2, tString, "", false}, {"external_reference", 3, tString, "", false}, {"memo", 4, tString, "", false}}},
				{"MsgCancelPayout", []field{{"signer", 1, tString, "", false}, {"payout_id", 2, tString, "", false}, {"memo", 3, tString, "", false}}},
				{"MsgFailPayout", []field{{"authority", 1, tString, "", false}, {"payout_id", 2, tString, "", false}, {"failure_reason", 3, tString, "", false}}},
				{"MsgUpdateParams", []field{{"authority", 1, tString, "", false}, {"params", 2, tMessage, ".nexarail.payout.v1.Params", false}}},
			},
		},
		{
			goName: "Treasury", pkg: "nexarail.treasury.v1", proto: "nexarail/treasury/v1/tx.proto",
			imports: []string{"cosmos/base/v1beta1/coin.proto"},
			msgs: []message{
				{"Params", []field{
					{"treasury_enabled", 1, tBool, "", false},
					{"live_enabled", 2, tBool, "", false},
					{"spend_requests_enabled", 3, tBool, "", false},
					{"grants_enabled", 4, tBool, "", false},
					{"budgets_enabled", 5, tBool, "", false},
					{"max_name_length", 6, tUint32, "", false},
					{"max_description_length", 7, tUint32, "", false},
					{"max_metadata_uri_length", 8, tUint32, "", false},
					{"max_purpose_length", 9, tUint32, "", false},
					{"max_memo_length", 10, tUint32, "", false},
					{"min_spend_amount", 11, tMessage, coinType, false},
				}},
				{"MsgCreateTreasuryAccount", []field{{"authority", 1, tString, "", false}, {"account_id", 2, tString, "", false}, {"category", 3, tInt32, "", false}, {"name", 4, tString, "", false}, {"description", 5, tString, "", false}, {"metadata_uri", 6, tString, "", false}, {"nominal_balance", 7, tMessage, coinType, false}}},
				{"MsgCreateBudget", []field{{"authority", 1, tString, "", false}, {"budget_id", 2, tString, "", false}, {"account_id", 3, tString, "", false}, {"category", 4, tInt32, "", false}, {"title", 5, tString, "", false}, {"description", 6, tString, "", false}, {"total_amount", 7, tMessage, coinType, false}, {"start_time", 8, tInt64, "", false}, {"end_time", 9, tInt64, "", false}, {"metadata_uri", 10, tString, "", false}}},
				{"MsgUpdateBudgetStatus", []field{{"authority", 1, tString, "", false}, {"budget_id", 2, tString, "", false}, {"status", 3, tInt32, "", false}}},
				{"MsgCreateGrant", []field{{"authority", 1, tString, "", false}, {"grant_id", 2, tString, "", false}, {"budget_id", 3, tString, "", false}, {"recipient_address", 4, tString, "", false}, {"title", 5, tString, "", false}, {"description", 6, tString, "", false}, {"amount", 7, tMessage, coinType, false}, {"milestone_count", 8, tUint32, "", false}, {"metadata_uri", 9, tString, "", false}}},
				{"MsgUpdateGrantStatus", []field{{"authority", 1, tString, "", false}, {"grant_id", 2, tString, "", false}, {"status", 3, tInt32, "", false}}},
				{"MsgCreateSpendRequest", []field{{"requester", 1, tString, "", false}, {"spend_id", 2, tString, "", false}, {"account_id", 3, tString, "", false}, {"budget_id", 4, tString, "", false}, {"grant_id", 5, tString, "", false}, {"recipient_address", 6, tString, "", false}, {"amount", 7, tMessage, coinType, false}, {"purpose", 8, tString, "", false}, {"reference", 9, tString, "", false}, {"memo", 10, tString, "", false}}},
				{"MsgApproveSpendRequest", []field{{"authority", 1, tString, "", false}, {"spend_id", 2, tString, "", false}}},
				{"MsgRejectSpendRequest", []field{{"authority", 1, tString, "", false}, {"spend_id", 2, tString, "", false}, {"memo", 3, tString, "", false}}},
				{"MsgMarkSpendExecuted", []field{{"authority", 1, tString, "", false}, {"spend_id", 2, tString, "", false}, {"reference", 3, tString, "", false}, {"memo", 4, tString, "", false}}},
				{"MsgCancelSpendRequest", []field{{"signer", 1, tString, "", false}, {"spend_id", 2, tString, "", false}, {"memo", 3, tString, "", false}}},
				{"MsgUpdateParams", []field{{"authority", 1, tString, "", false}, {"params", 2, tMessage, ".nexarail.treasury.v1.Params", false}}},
			},
		},
	}

	var buf bytes.Buffer
	buf.WriteString("// Code generated by tools/gen_descriptors.go. DO NOT EDIT.\n\n")
	buf.WriteString("package common\n\n")
	buf.WriteString("var (\n")
	for _, mod := range modules {
		b, err := descriptorBytes(mod)
		if err != nil {
			fmt.Fprintf(os.Stderr, "descriptor %s: %v\n", mod.goName, err)
			os.Exit(1)
		}
		fmt.Fprintf(&buf, "\t%sDescriptorBytes = %#v\n", mod.goName, b)
	}
	buf.WriteString(")\n")

	src, err := format.Source(buf.Bytes())
	if err != nil {
		fmt.Fprint(os.Stderr, err)
		os.Exit(1)
	}
	fmt.Print(string(src))
}

func descriptorBytes(mod module) ([]byte, error) {
	fd := &descriptorpb.FileDescriptorProto{
		Name:       proto.String(mod.proto),
		Package:    proto.String(mod.pkg),
		Syntax:     proto.String("proto3"),
		Dependency: mod.imports,
	}
	for _, msg := range mod.msgs {
		fd.MessageType = append(fd.MessageType, buildMessage(msg))
	}
	raw, err := proto.Marshal(fd)
	if err != nil {
		return nil, err
	}
	var gz bytes.Buffer
	zw := gzip.NewWriter(&gz)
	if _, err := zw.Write(raw); err != nil {
		return nil, err
	}
	if err := zw.Close(); err != nil {
		return nil, err
	}
	return gz.Bytes(), nil
}

func buildMessage(msg message) *descriptorpb.DescriptorProto {
	out := &descriptorpb.DescriptorProto{Name: proto.String(msg.name)}
	for _, f := range msg.fields {
		out.Field = append(out.Field, buildField(f))
	}
	return out
}

func buildField(f field) *descriptorpb.FieldDescriptorProto {
	label := descriptorpb.FieldDescriptorProto_LABEL_OPTIONAL
	if f.repeated {
		label = descriptorpb.FieldDescriptorProto_LABEL_REPEATED
	}
	fd := &descriptorpb.FieldDescriptorProto{
		Name:   proto.String(f.name),
		Number: proto.Int32(f.number),
		Label:  label.Enum(),
		Type:   f.typ.Enum(),
	}
	if f.typeName != "" {
		fd.TypeName = proto.String(f.typeName)
	}
	return fd
}
