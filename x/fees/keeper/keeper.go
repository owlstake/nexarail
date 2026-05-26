package keeper

import (
	"encoding/json"
	"fmt"

	"github.com/cometbft/cometbft/libs/log"
	storetypes "github.com/cosmos/cosmos-sdk/store/types"
	sdk "github.com/cosmos/cosmos-sdk/types"

	"github.com/nexarail/chain/x/fees/types"
)

// Keeper maintains the state and logic for the fees module.
type Keeper struct {
	storeKey      storetypes.StoreKey
	authority     string
	accountKeeper types.AccountKeeper
	bankKeeper    types.BankKeeper
}

// NewKeeper creates a new fees keeper.
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

// GetAuthority returns the module's authority address.
func (k Keeper) GetAuthority() string {
	return k.authority
}

// Logger returns a module-specific logger.
func (k Keeper) Logger(ctx sdk.Context) log.Logger {
	return ctx.Logger().With("module", fmt.Sprintf("x/%s", types.ModuleName))
}

// SetParams sets the fees module parameters.
func (k Keeper) SetParams(ctx sdk.Context, params types.Params) error {
	if err := params.Validate(); err != nil {
		return err
	}

	store := ctx.KVStore(k.storeKey)
	bz, err := json.Marshal(params)
	if err != nil {
		return err
	}
	store.Set(types.ParamsKey, bz)
	return nil
}

// GetParams returns the current fees module parameters.
func (k Keeper) GetParams(ctx sdk.Context) types.Params {
	store := ctx.KVStore(k.storeKey)
	bz := store.Get(types.ParamsKey)
	if bz == nil {
		return types.DefaultParams()
	}

	var params types.Params
	if err := json.Unmarshal(bz, &params); err != nil {
		panic(fmt.Errorf("failed to unmarshal fees params: %w", err))
	}
	return params
}

// GetFeeSplit returns the current fee split proportions.
func (k Keeper) GetFeeSplit(ctx sdk.Context) (validatorBps, treasuryBps, burnBps uint32) {
	params := k.GetParams(ctx)
	return params.ValidatorShareBps, params.TreasuryShareBps, params.BurnShareBps
}

// GetDefaultGenesis returns the default genesis state for the fees module.
func (k Keeper) GetDefaultGenesis() *types.GenesisState {
	return types.DefaultGenesis()
}
