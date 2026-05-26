# Pre-Launch Freeze Checklist — NexaRail Testnet

**Chain:** nexarail-testnet-1
**Phase:** 7E — Pre-Launch Freeze
**Status:** Pending — to be completed after genesis assembly

---

## Freeze Declaration

Once this checklist is complete, the following are **frozen**:

- No protocol code changes
- No genesis changes
- No validator set changes
- No parameter changes

Only emergency fixes with coordinator approval are permitted after freeze.

---

## Code Freeze

| # | Check | Status |
|---|---|---|
| 1 | No protocol features added since Phase 6J.2 | ☐ |
| 2 | No chain economics changed | ☐ |
| 3 | No live flags enabled by default | ☐ |
| 4 | `go test ./...` all pass | ☐ |
| 5 | `go build ./...` passes | ☐ |
| 6 | `go vet ./...` passes | ☐ |
| 7 | `go mod tidy && go mod verify` passes | ☐ |

## Genesis Freeze

| # | Check | Status |
|---|---|---|
| 8 | Genesis assembled with `assemble-testnet-genesis.sh` | ☐ |
| 9 | `validate-genesis` passes | ☐ |
| 10 | gen_txs count matches accepted validator count | ☐ |
| 11 | All gentxs verified (22-point checklist) | ☐ |
| 12 | Chain ID = `nexarail-testnet-1` | ☐ |
| 13 | Denom = `unxrl` | ☐ |
| 14 | Bond denom = `unxrl` | ☐ |
| 15 | Voting period = 60s | ☐ |
| 16 | All 6 live flags = false | ☐ |
| 17 | Custom modules present in genesis (6 modules) | ☐ |

## Checksum

| # | Check | Status |
|---|---|---|
| 18 | Genesis checksum generated (SHA-256) | ☐ |
| 19 | Checksum published to all validators | ☐ |
| 20 | All validators confirmed checksum matches | ☐ |

## Documentation

| # | Check | Status |
|---|---|---|
| 21 | `PHASE_7E_GENTX_COLLECTION.md` complete | ☐ |
| 22 | `GENESIS_ASSEMBLY_LOG.md` populated | ☐ |
| 23 | `GENESIS_VALIDATION_REPORT.md` populated | ☐ |
| 24 | `TESTNET_LAUNCH_COORDINATION.md` distributed | ☐ |
| 25 | `GENESIS_VALIDATOR_SET_DRAFT.md` finalised | ☐ |
| 26 | `TESTNET_READINESS_CHECKLIST.md` updated to Phase 7E | ☐ |

## Validator Readiness

| # | Check | Status |
|---|---|---|
| 27 | All accepted validators notified of launch time | ☐ |
| 28 | All validators received genesis + checksum | ☐ |
| 29 | All validators confirmed checksum match | ☐ |
| 30 | All validators received peer list | ☐ |
| 31 | All validators confirmed binary built | ☐ |
| 32 | All validators confirmed port 26656 open | ☐ |
| 33 | All validators in communication channel | ☐ |
| 34 | All validators acknowledged launch time | ☐ |

## Unsafe Wording

| # | Check | Status |
|---|---|---|
| 35 | No "mainnet live" in any public-facing doc | ☐ |
| 36 | No "buy NXRL" in any public-facing doc | ☐ |
| 37 | No "token sale" (positive) in any doc | ☐ |
| 38 | No "investment" (positive) in any doc | ☐ |
| 39 | No "guaranteed" (financial) in any doc | ☐ |
| 40 | No "profit" in any doc | ☐ |
| 41 | No "returns" (financial) in any doc | ☐ |
| 42 | All public docs include testnet-only disclaimer | ☐ |

## Emergency Preparedness

| # | Check | Status |
|---|---|---|
| 43 | Coordinator emergency contact distributed | ☐ |
| 44 | Validator emergency contacts collected | ☐ |
| 45 | Halt/reset procedure documented and shared | ☐ |
| 46 | Backup communication channel confirmed | ☐ |
| 47 | Log capture instructions distributed | ☐ |

## Coordinator Sign-Off

I, [Coordinator Name], confirm that all pre-launch freeze checks have been completed. The genesis is final. Validators are ready. Launch may proceed at the coordinated time.

**Signed:** ________________
**Date:** ________________
**Launch Time (T-0):** ________________ UTC
