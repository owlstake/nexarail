package keeper

import (
	"context"
	"fmt"

	sdk "github.com/cosmos/cosmos-sdk/types"
	grpc "google.golang.org/grpc"

	"github.com/nexarail/chain/x/fees/types"
)

// MsgServer implements the MsgServer interface for the fees module.
type MsgServer struct {
	keeper Keeper
}

// NewMsgServerImpl returns an implementation of the MsgServer interface.
func NewMsgServerImpl(keeper Keeper) MsgServer {
	return MsgServer{keeper: keeper}
}

// UpdateParams handles MsgUpdateParams.
// Only the module authority (governance) may update the params.
func (ms MsgServer) UpdateParams(ctx context.Context, msg *types.MsgUpdateParams) (*types.MsgUpdateParamsResponse, error) {
	if err := msg.ValidateBasic(); err != nil {
		return nil, err
	}

	if msg.Authority != ms.keeper.GetAuthority() {
		return nil, fmt.Errorf("unauthorized: expected %s, got %s: %w",
			ms.keeper.GetAuthority(), msg.Authority, types.ErrUnauthorized)
	}

	sdkCtx := sdk.UnwrapSDKContext(ctx)

	if err := ms.keeper.SetParams(sdkCtx, msg.Params); err != nil {
		return nil, err
	}

	// Emit event
	sdkCtx.EventManager().EmitEvent(
		sdk.NewEvent(
			types.EventTypeUpdateParams,
			sdk.NewAttribute(types.AttributeKeyValidatorShareBps, fmt.Sprintf("%d", msg.Params.ValidatorShareBps)),
			sdk.NewAttribute(types.AttributeKeyTreasuryShareBps, fmt.Sprintf("%d", msg.Params.TreasuryShareBps)),
			sdk.NewAttribute(types.AttributeKeyBurnShareBps, fmt.Sprintf("%d", msg.Params.BurnShareBps)),
			sdk.NewAttribute(types.AttributeKeyFeeCollectorName, msg.Params.FeeCollectorName),
			sdk.NewAttribute(types.AttributeKeyTreasuryAccount, msg.Params.TreasuryAccount),
			sdk.NewAttribute(types.AttributeKeyBurnEnabled, fmt.Sprintf("%t", msg.Params.BurnEnabled)),
			sdk.NewAttribute(types.AttributeKeyMinProtocolFee, msg.Params.MinProtocolFee.String()),
			sdk.NewAttribute(types.AttributeKeyAuthority, msg.Authority),
		),
	)

	return &types.MsgUpdateParamsResponse{}, nil
}

// RegisterMsgServer registers the fees Msg service with the gRPC server.
func RegisterMsgServer(s grpc.ServiceRegistrar, srv MsgServer) {
	s.RegisterService(&_Msg_serviceDesc, srv)
}

var _Msg_serviceDesc = grpc.ServiceDesc{
	ServiceName: "nexarail.fees.v1.Msg",
	HandlerType: (*interface{})(nil),
	Methods: []grpc.MethodDesc{
		{
			MethodName: "UpdateParams",
			Handler:    _Msg_UpdateParams_Handler,
		},
	},
	Streams:  []grpc.StreamDesc{},
	Metadata: "nexarail/fees/v1/fees.proto",
}

func _Msg_UpdateParams_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(types.MsgUpdateParams)
	if err := dec(in); err != nil {
		return nil, err
	}

	if interceptor == nil {
		return srv.(MsgServer).UpdateParams(ctx, in)
	}

	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/nexarail.fees.v1.Msg/UpdateParams",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(MsgServer).UpdateParams(ctx, req.(*types.MsgUpdateParams))
	}
	return interceptor(ctx, in, info, handler)
}
