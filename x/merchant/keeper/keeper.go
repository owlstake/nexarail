package keeper

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/cometbft/cometbft/libs/log"
	storetypes "github.com/cosmos/cosmos-sdk/store/types"
	sdk "github.com/cosmos/cosmos-sdk/types"

	"github.com/nexarail/chain/x/merchant/types"
)

// Keeper maintains the state for the merchant module.
type Keeper struct {
	storeKey      storetypes.StoreKey
	authority     string
	accountKeeper types.AccountKeeper
	bankKeeper    types.BankKeeper
}

// NewKeeper creates a new merchant keeper.
func NewKeeper(
	storeKey storetypes.StoreKey,
	accountKeeper types.AccountKeeper,
	bankKeeper types.BankKeeper,
	authority string,
) Keeper {
	return Keeper{
		storeKey:      storeKey,
		authority:     authority,
		accountKeeper: accountKeeper,
		bankKeeper:    bankKeeper,
	}
}

func (k Keeper) GetAuthority() string { return k.authority }

func (k Keeper) Logger(ctx sdk.Context) log.Logger {
	return ctx.Logger().With("module", fmt.Sprintf("x/%s", types.ModuleName))
}

// --- Params ---

func (k Keeper) SetParams(ctx sdk.Context, p types.Params) error {
	if err := p.Validate(); err != nil {
		return err
	}
	bz, err := json.Marshal(p)
	if err != nil {
		return err
	}
	ctx.KVStore(k.storeKey).Set(types.ParamsKey, bz)
	return nil
}

func (k Keeper) GetParams(ctx sdk.Context) types.Params {
	bz := ctx.KVStore(k.storeKey).Get(types.ParamsKey)
	if bz == nil {
		return types.DefaultParams()
	}
	var p types.Params
	if err := json.Unmarshal(bz, &p); err != nil {
		panic(fmt.Errorf("merchant params unmarshal: %w", err))
	}
	return p
}

// --- Merchant ---

func (k Keeper) SetMerchant(ctx sdk.Context, m types.Merchant) error {
	bz, err := json.Marshal(m)
	if err != nil {
		return err
	}
	owner, err := sdk.AccAddressFromBech32(m.Owner)
	if err != nil {
		return fmt.Errorf("invalid owner in merchant: %w", err)
	}
	ctx.KVStore(k.storeKey).Set(types.MerchantKey(owner), bz)
	return nil
}

func (k Keeper) GetMerchant(ctx sdk.Context, owner sdk.AccAddress) (types.Merchant, bool) {
	bz := ctx.KVStore(k.storeKey).Get(types.MerchantKey(owner))
	if bz == nil {
		return types.Merchant{}, false
	}
	var m types.Merchant
	if err := json.Unmarshal(bz, &m); err != nil {
		panic(fmt.Errorf("merchant unmarshal: %w", err))
	}
	return m, true
}

func (k Keeper) HasMerchant(ctx sdk.Context, owner sdk.AccAddress) bool {
	return ctx.KVStore(k.storeKey).Has(types.MerchantKey(owner))
}

// GetAllMerchants returns all registered merchants.
func (k Keeper) GetAllMerchants(ctx sdk.Context) []types.Merchant {
	store := ctx.KVStore(k.storeKey)
	iter := sdk.KVStorePrefixIterator(store, types.MerchantKeyPrefix)
	defer iter.Close()

	var merchants []types.Merchant
	for ; iter.Valid(); iter.Next() {
		var m types.Merchant
		if err := json.Unmarshal(iter.Value(), &m); err != nil {
			panic(fmt.Errorf("merchant unmarshal during iteration: %w", err))
		}
		merchants = append(merchants, m)
	}
	return merchants
}

// RegisterMerchant registers a new merchant, collecting the registration fee.
func (k Keeper) RegisterMerchant(ctx sdk.Context, msg *types.MsgRegisterMerchant) error {
	owner, err := sdk.AccAddressFromBech32(msg.Owner)
	if err != nil {
		return fmt.Errorf("invalid owner: %w", err)
	}
	if k.HasMerchant(ctx, owner) {
		return fmt.Errorf("merchant %s: %w", msg.Owner, types.ErrMerchantAlreadyExists)
	}

	params := k.GetParams(ctx)
	now := time.Now().Unix()

	m := types.NewMerchant(owner, msg.Name, msg.Description, msg.Website, now, now)
	if err := m.ValidateWithParams(params); err != nil {
		return err
	}

	// Collect registration fee
	if !params.RegistrationFee.IsZero() {
		if err := k.bankKeeper.SendCoinsFromAccountToModule(
			ctx, owner, types.ModuleName, sdk.Coins{params.RegistrationFee},
		); err != nil {
			return fmt.Errorf("registration fee: %w", err)
		}
	}

	if err := k.SetMerchant(ctx, m); err != nil {
		return err
	}

	// Emit event
	ctx.EventManager().EmitEvent(sdk.NewEvent(
		types.EventTypeRegisterMerchant,
		sdk.NewAttribute(types.AttributeKeyOwner, m.Owner),
		sdk.NewAttribute(types.AttributeKeyName, m.Name),
		sdk.NewAttribute(types.AttributeKeyDescription, m.Description),
		sdk.NewAttribute(types.AttributeKeyWebsite, m.Website),
		sdk.NewAttribute(types.AttributeKeyStatus, fmt.Sprintf("%d", m.Status)),
	))

	return nil
}

// UpdateMerchant updates an existing merchant's profile.
// Closed merchants cannot be updated.
func (k Keeper) UpdateMerchant(ctx sdk.Context, msg *types.MsgUpdateMerchant) error {
	owner, err := sdk.AccAddressFromBech32(msg.Owner)
	if err != nil {
		return fmt.Errorf("invalid owner: %w", err)
	}
	m, found := k.GetMerchant(ctx, owner)
	if !found {
		return fmt.Errorf("merchant %s: %w", msg.Owner, types.ErrMerchantNotFound)
	}

	if m.IsClosed() {
		return fmt.Errorf("merchant %s: %w", msg.Owner, types.ErrMerchantClosed)
	}

	params := k.GetParams(ctx)

	if msg.Name != "" {
		m.Name = msg.Name
	}
	if msg.Description != "" {
		m.Description = msg.Description
	}
	if msg.Website != "" {
		m.Website = msg.Website
	}
	m.UpdatedAt = time.Now().Unix()

	if err := m.ValidateWithParams(params); err != nil {
		return err
	}

	if err := k.SetMerchant(ctx, m); err != nil {
		return err
	}

	ctx.EventManager().EmitEvent(sdk.NewEvent(
		types.EventTypeUpdateMerchant,
		sdk.NewAttribute(types.AttributeKeyOwner, m.Owner),
		sdk.NewAttribute(types.AttributeKeyName, m.Name),
		sdk.NewAttribute(types.AttributeKeyDescription, m.Description),
		sdk.NewAttribute(types.AttributeKeyWebsite, m.Website),
	))

	return nil
}

// --- Authority-gated operations ---

func (k Keeper) SetMerchantStatus(ctx sdk.Context, authority, ownerStr string, status int32) error {
	if authority != k.authority {
		return fmt.Errorf("expected %s, got %s: %w", k.authority, authority, types.ErrUnauthorized)
	}
	if status < 0 || status > 2 {
		return fmt.Errorf("invalid status: %d: %w", status, types.ErrInvalidParams)
	}
	owner, err := sdk.AccAddressFromBech32(ownerStr)
	if err != nil {
		return fmt.Errorf("invalid owner: %w", err)
	}
	m, found := k.GetMerchant(ctx, owner)
	if !found {
		return fmt.Errorf("merchant %s: %w", ownerStr, types.ErrMerchantNotFound)
	}
	m.Status = status
	m.UpdatedAt = time.Now().Unix()
	if err := k.SetMerchant(ctx, m); err != nil {
		return err
	}
	ctx.EventManager().EmitEvent(sdk.NewEvent(
		types.EventTypeUpdateMerchant,
		sdk.NewAttribute(types.AttributeKeyOwner, m.Owner),
		sdk.NewAttribute(types.AttributeKeyStatus, fmt.Sprintf("%d", status)),
	))
	return nil
}

func (k Keeper) SetVerificationStatus(ctx sdk.Context, authority, ownerStr string, status int32) error {
	if authority != k.authority {
		return fmt.Errorf("expected %s, got %s: %w", k.authority, authority, types.ErrUnauthorized)
	}
	if status < 0 || status > 2 {
		return fmt.Errorf("invalid verification status: %d: %w", status, types.ErrInvalidParams)
	}
	owner, err := sdk.AccAddressFromBech32(ownerStr)
	if err != nil {
		return fmt.Errorf("invalid owner: %w", err)
	}
	m, found := k.GetMerchant(ctx, owner)
	if !found {
		return fmt.Errorf("merchant %s: %w", ownerStr, types.ErrMerchantNotFound)
	}
	m.VerificationStatus = status
	m.UpdatedAt = time.Now().Unix()
	if err := k.SetMerchant(ctx, m); err != nil {
		return err
	}
	ctx.EventManager().EmitEvent(sdk.NewEvent(
		types.EventTypeUpdateMerchant,
		sdk.NewAttribute(types.AttributeKeyOwner, m.Owner),
		sdk.NewAttribute(types.AttributeKeyStatus, fmt.Sprintf("verification:%d", status)),
	))
	return nil
}

func (k Keeper) SetRebateTier(ctx sdk.Context, authority, ownerStr string, tier int32) error {
	if authority != k.authority {
		return fmt.Errorf("expected %s, got %s: %w", k.authority, authority, types.ErrUnauthorized)
	}
	if tier < 0 || tier > 4 {
		return fmt.Errorf("invalid rebate tier: %d: %w", tier, types.ErrInvalidParams)
	}
	owner, err := sdk.AccAddressFromBech32(ownerStr)
	if err != nil {
		return fmt.Errorf("invalid owner: %w", err)
	}
	m, found := k.GetMerchant(ctx, owner)
	if !found {
		return fmt.Errorf("merchant %s: %w", ownerStr, types.ErrMerchantNotFound)
	}
	m.RebateTier = tier
	m.UpdatedAt = time.Now().Unix()
	if err := k.SetMerchant(ctx, m); err != nil {
		return err
	}
	ctx.EventManager().EmitEvent(sdk.NewEvent(
		types.EventTypeUpdateMerchant,
		sdk.NewAttribute(types.AttributeKeyOwner, m.Owner),
		sdk.NewAttribute(types.AttributeKeyStatus, fmt.Sprintf("rebate:%d", tier)),
	))
	return nil
}

func (k Keeper) UpdateParams(ctx sdk.Context, authority string, params types.Params) error {
	if authority != k.authority {
		return fmt.Errorf("expected %s, got %s: %w", k.authority, authority, types.ErrUnauthorized)
	}
	return k.SetParams(ctx, params)
}
