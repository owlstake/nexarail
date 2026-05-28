package app

import (
	dbm "github.com/cometbft/cometbft-db"
	"github.com/cometbft/cometbft/libs/log"
	"github.com/cosmos/cosmos-sdk/store/rootmulti"
	storetypes "github.com/cosmos/cosmos-sdk/store/types"
)

type latestQueryMultiStore struct {
	storetypes.MultiStore
}

func newLatestQueryMultiStore(ms storetypes.MultiStore) latestQueryMultiStore {
	return latestQueryMultiStore{MultiStore: ms}
}

func (q latestQueryMultiStore) CacheMultiStoreWithVersion(version int64) (storetypes.CacheMultiStore, error) {
	if version >= q.LatestVersion() {
		return q.CacheMultiStore(), nil
	}
	return q.MultiStore.CacheMultiStoreWithVersion(version)
}

type reloadingQueryMultiStore struct {
	*rootmulti.Store
	db     dbm.DB
	logger log.Logger
	keys   map[string]*storetypes.KVStoreKey
}

func newReloadingQueryMultiStore(db dbm.DB, logger log.Logger, keys map[string]*storetypes.KVStoreKey) *reloadingQueryMultiStore {
	base := rootmulti.NewStore(db, logger)
	for _, key := range keys {
		base.MountStoreWithDB(key, storetypes.StoreTypeIAVL, nil)
	}
	_ = base.LoadLatestVersion()
	return &reloadingQueryMultiStore{
		Store:  base,
		db:     db,
		logger: logger,
		keys:   keys,
	}
}

func (q *reloadingQueryMultiStore) freshStore() (*rootmulti.Store, error) {
	rs := rootmulti.NewStore(q.db, q.logger)
	for _, key := range q.keys {
		rs.MountStoreWithDB(key, storetypes.StoreTypeIAVL, nil)
	}
	if err := rs.LoadLatestVersion(); err != nil {
		return nil, err
	}
	return rs, nil
}

func (q *reloadingQueryMultiStore) LatestVersion() int64 {
	return rootmulti.GetLatestVersion(q.db)
}

func (q *reloadingQueryMultiStore) CacheMultiStore() storetypes.CacheMultiStore {
	rs, err := q.freshStore()
	if err != nil {
		return q.Store.CacheMultiStore()
	}
	return rs.CacheMultiStore()
}

func (q *reloadingQueryMultiStore) CacheMultiStoreWithVersion(version int64) (storetypes.CacheMultiStore, error) {
	rs, err := q.freshStore()
	if err != nil {
		return nil, err
	}
	return rs.CacheMultiStoreWithVersion(version)
}
