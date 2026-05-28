package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	dbm "github.com/cometbft/cometbft-db"
	"github.com/cometbft/cometbft/libs/log"

	"github.com/cosmos/cosmos-sdk/store/iavl"
	"github.com/cosmos/cosmos-sdk/store/rootmulti"
	storetypes "github.com/cosmos/cosmos-sdk/store/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/x/authz"
	authtypes "github.com/cosmos/cosmos-sdk/x/auth/types"
	banktypes "github.com/cosmos/cosmos-sdk/x/bank/types"
	capabilitytypes "github.com/cosmos/cosmos-sdk/x/capability/types"
	crisistypes "github.com/cosmos/cosmos-sdk/x/crisis/types"
	distrtypes "github.com/cosmos/cosmos-sdk/x/distribution/types"
	evidencetypes "github.com/cosmos/cosmos-sdk/x/evidence/types"
	"github.com/cosmos/cosmos-sdk/x/feegrant"
	govtypes "github.com/cosmos/cosmos-sdk/x/gov/types"
	minttypes "github.com/cosmos/cosmos-sdk/x/mint/types"
	paramstypes "github.com/cosmos/cosmos-sdk/x/params/types"
	slashingtypes "github.com/cosmos/cosmos-sdk/x/slashing/types"
	stakingtypes "github.com/cosmos/cosmos-sdk/x/staking/types"
	upgradetypes "github.com/cosmos/cosmos-sdk/x/upgrade/types"
	"github.com/nexarail/chain/app"
	escrowtypes "github.com/nexarail/chain/x/escrow/types"
	feestypes "github.com/nexarail/chain/x/fees/types"
	merchanttypes "github.com/nexarail/chain/x/merchant/types"
	payouttypes "github.com/nexarail/chain/x/payout/types"
	settlementtypes "github.com/nexarail/chain/x/settlement/types"
	treasurytypes "github.com/nexarail/chain/x/treasury/types"
)

func main() {
	var home string
	var heightsCSV string
	flag.StringVar(&home, "home", "", "validator home directory")
	flag.StringVar(&heightsCSV, "heights", "1,5,10", "comma-separated heights")
	flag.Parse()
	if home == "" {
		fmt.Fprintln(os.Stderr, "--home required")
		os.Exit(2)
	}

	db, err := dbm.NewGoLevelDB("application", filepath.Join(home, "data"))
	if err != nil {
		fmt.Fprintf(os.Stderr, "open DB: %v\n", err)
		os.Exit(1)
	}
	defer db.Close()

	enc := app.MakeEncodingConfig()
	nexApp := app.NewNexaRailApp(log.NewNopLogger(), db, nil, true, nil, home, 0, enc, nil)
	fmt.Printf("latest=%d\n", nexApp.CommitMultiStore().LatestVersion())

	for _, raw := range strings.Split(heightsCSV, ",") {
		raw = strings.TrimSpace(raw)
		if raw == "" {
			continue
		}
		h, err := strconv.ParseInt(raw, 10, 64)
		if err != nil {
			fmt.Printf("height %s: parse error: %v\n", raw, err)
			continue
		}
		_, err = nexApp.CommitMultiStore().CacheMultiStoreWithVersion(h)
		if err != nil {
			fmt.Printf("height %d: FAIL: %v\n", h, err)
		} else {
			fmt.Printf("height %d: OK\n", h)
		}
	}

	fmt.Println("stores:")
	keys := sdk.NewKVStoreKeys(
		authtypes.StoreKey, banktypes.StoreKey, stakingtypes.StoreKey,
		minttypes.StoreKey, distrtypes.StoreKey, slashingtypes.StoreKey,
		govtypes.StoreKey, paramstypes.StoreKey, upgradetypes.StoreKey,
		evidencetypes.StoreKey, capabilitytypes.StoreKey, feegrant.StoreKey,
		authz.ModuleName, crisistypes.StoreKey, feestypes.StoreKey,
		merchanttypes.StoreKey, settlementtypes.StoreKey, payouttypes.StoreKey,
		escrowtypes.StoreKey, treasurytypes.StoreKey,
	)
	rs := rootmulti.NewStore(db, log.NewNopLogger())
	for _, key := range keys {
		rs.MountStoreWithDB(key, storetypes.StoreTypeIAVL, nil)
	}
	if err := rs.LoadLatestVersion(); err != nil {
		fmt.Printf("  load rootmulti failed: %v\n", err)
		return
	}
	fmt.Printf("mounted_latest=%d\n", rs.LatestVersion())
	for _, key := range keys {
		store := rs.GetCommitKVStore(key)
		iavlStore, ok := store.(*iavl.Store)
		if !ok {
			fmt.Printf("  %s: non-iavl %T\n", key.Name(), store)
			continue
		}
		var parts []string
		for _, raw := range strings.Split(heightsCSV, ",") {
			raw = strings.TrimSpace(raw)
			if raw == "" {
				continue
			}
			h, _ := strconv.ParseInt(raw, 10, 64)
			if iavlStore.VersionExists(h) {
				parts = append(parts, fmt.Sprintf("%d=ok", h))
			} else {
				parts = append(parts, fmt.Sprintf("%d=missing", h))
			}
		}
		fmt.Printf("  %s: %s\n", key.Name(), strings.Join(parts, " "))
	}
}
