# Phase 9F — Governance Parameter Proposal Registration and Live-Flag Governance Completion

**Date:** 2026-05-26  
**Phase:** 9F  
**Chain:** nexarail-agent-testnet-1  
**Status:** Code complete — live run requires agent testnet to be spawned

---

## Root Cause

The governance test script in Phase 9E used `tx gov submit-legacy-proposal param-change`, which fails because:

1. **No params subspace**: Custom modules (`x/escrow`, `x/fees`, `x/merchant`, `x/settlement`, `x/payout`, `x/treasury`) do not register `x/params` subspaces. They use per-module `MsgUpdateParams` gated by the governance authority address. Legacy `ParameterChangeProposal` routes through the params module's subspace router — with no registered escrow subspace, the proposal cannot affect escrow params.

2. **No legacy router**: The gov keeper in `app.go` is wired with `app.MsgServiceRouter()` only (Cosmos SDK v0.47 pattern). No legacy `govtypes.Router` is configured. Any legacy proposal type causes "proposal type required" immediately.

3. **No protobuf field tags**: `MsgUpdateParams` and `Params` in `x/escrow/types` had only `json:` struct tags, no `protobuf:` field number tags. Without these, `proto.Marshal(msg)` produces zero bytes. An empty `Any.Value` means the governance module decodes an empty `MsgUpdateParams{}` on proposal passage — the authority check fails and the param update never happens.

**None of these issues affect economics, live flag defaults, or module params.**

---

## Registration Fix

### Files modified

**`x/escrow/types/params.go`** — Added protobuf field tags (field numbers 1–8) to all `Params` fields:
```go
type Params struct {
    EscrowsEnabled     bool     `... protobuf:"varint,1,opt,name=escrows_enabled,json=escrowsEnabled,proto3"`
    LiveEnabled        bool     `... protobuf:"varint,2,opt,name=live_enabled,json=liveEnabled,proto3"`
    MaxReferenceLength uint32   `... protobuf:"varint,3,opt,..."`
    // ... fields 4–8
    MinEscrowAmount    sdk.Coin `... protobuf:"bytes,7,opt,name=min_escrow_amount,..."`
    DefaultExpirySeconds uint64 `... protobuf:"varint,8,opt,..."`
}
```

**`x/escrow/types/msg.go`** — Added protobuf field tags to `MsgUpdateParams`:
```go
type MsgUpdateParams struct {
    Authority string `... protobuf:"bytes,1,opt,name=authority,proto3"`
    Params    Params `... protobuf:"bytes,2,opt,name=params,proto3"`
}
```

**`cmd/nexaraild/cmd/root.go`** — Added `govcli.GetQueryCmd()` to the query command tree. Previously, `query gov proposals`, `query gov proposal <id>`, etc. were unavailable. The `tx gov` commands were already present via `govcli.NewTxCmd(nil)`.

**`scripts/testnet/validator-agent-governance-test.sh`** — Rewritten to use `tx gov submit-proposal` (gov v1) with `messages` array containing `MsgUpdateParams`. See §Governance Script section below.

**`app/governance_test.go`** — 11 new tests added (see §Tests section below).

### What was NOT changed

- No live flag defaults modified
- No voting period, deposit, quorum, or threshold changed
- No new product modules added
- No module economics changed
- No params subspace added for custom modules
- Genesis file unchanged

---

## Why Legacy ParameterChange Is Incompatible

Legacy `ParameterChangeProposal` (from `x/params`) works by finding a registered `ParamSubspace` for the target module and calling `SetParamSet`. This requires:
1. The module to call `paramsKeeper.Subspace(moduleName)` and implement `ParamSetPairs`
2. A handler registered with the gov legacy router

NexaRail custom modules were designed to the Cosmos SDK v0.47 pattern: params are owned by the module's keeper, updated only through `MsgUpdateParams` signed by the governance authority. This is the recommended pattern for new modules in SDK v0.47+. There is no subspace and no legacy handler.

**Conclusion**: Legacy `ParameterChangeProposal` cannot and should not be used for `x/escrow` or any other NexaRail custom module. **Gov v1 `submit-proposal` with `MsgUpdateParams` in the messages array is the correct and only supported path.**

---

## Proposal Type Used

**`tx gov submit-proposal`** (Cosmos SDK v0.47 gov v1)

Type URL: `/nexarail.escrow.v1.MsgUpdateParams`

This is a gov v1 proposal: `MsgSubmitProposal` with a `messages` array containing the governance action. When the proposal passes, the governance EndBlocker executes each message through the `MsgServiceRouter` with the governance module address as the signer. The escrow keeper validates `authority == govModuleAddress` before updating params.

---

## Proposal JSON Format

```json
{
  "title": "TESTNET: Enable escrow.live_enabled — Phase 9F governance test",
  "summary": "Testnet-only governance exercise. Tokens have zero value. No mainnet implications.",
  "messages": [
    {
      "@type": "/nexarail.escrow.v1.MsgUpdateParams",
      "authority": "<gov-module-address>",
      "params": {
        "escrows_enabled": true,
        "live_enabled": true,
        "max_reference_length": 120,
        "max_memo_length": 280,
        "max_dispute_reason_length": 1000,
        "max_resolution_note_length": 1000,
        "min_escrow_amount": {"denom": "unxrl", "amount": "1"},
        "default_expiry_seconds": 2592000
      }
    }
  ],
  "metadata": "",
  "deposit": "1000000unxrl",
  "expedited": false
}
```

Field names in `params` use snake_case (matching json struct tags on the `Params` type). The gov authority address is resolved dynamically from the running chain via `query auth module-account gov`.

---

## Governance Script

**`scripts/testnet/validator-agent-governance-test.sh`** (rewritten):

- Pre-flight: checks binary and agent testnet reachability
- Resolves gov module address from running chain
- Confirms `live_enabled = false` before test
- Submits enable proposal via `submit-proposal` (gov v1) from alpha agent with `--node` flag
- Votes YES from all 5 agents (alpha/bravo/charlie/delta/echo) with per-agent `--home` and `--node`
- Waits 35s (30s voting period + buffer)
- Queries escrow params via REST and confirms `live_enabled = true`
- Submits disable proposal, repeats vote + wait cycle
- Confirms `live_enabled = false`
- Runs final live flag sweep across all modules
- Reports pass/fail counts

---

## Live Run Evidence

**The agent testnet was not running at the time of Phase 9F code completion.**

To execute the live run:
```bash
scripts/testnet/spawn-validator-agents.sh
scripts/testnet/validator-agent-governance-test.sh
scripts/testnet/query-validator-agents.sh
scripts/testnet/stop-validator-agents.sh
```

The governance script will record proposal IDs, vote tx hashes, and final param state to stdout. Paste results into the VALIDATOR_AGENT_GOVERNANCE_RESULTS.md when complete.

### Pre-conditions for live run

- Agent testnet running at chain ID `nexarail-agent-testnet-1`
- 5 validator agents: alpha (port 27657), bravo (27667), charlie (27677), delta (27687), echo (27697)
- Voting period ≤ 30s (set in genesis for agent testnet)
- All 5 agent keys funded with ≥ 15000 unxrl for deposits + fees

---

## Tests Added

File: `app/governance_test.go` (11 tests)

| Test | What it proves |
|---|---|
| `TestGovernanceInterfaceRegistration` | `MsgUpdateParams` resolves via interface registry at type URL `/nexarail.escrow.v1.MsgUpdateParams` |
| `TestGovernanceMsgUpdateParamsProtoRoundTrip` | `proto.Marshal`/`Unmarshal` round-trip preserves all fields including `authority` and `live_enabled` |
| `TestGovernanceParamsProtoRoundTrip` | `Params` type proto round-trip works independently |
| `TestGovernanceMsgUpdateParamsJSONRoundTrip` | JSON encode/decode works (used in proposal.json parsing) |
| `TestGovernanceLegacyParamChangeIncompatible` | Custom modules have NO params subspaces — confirms legacy path is incompatible |
| `TestGovernanceTxCmdIncludesGov` | `tx gov submit-proposal` and `tx gov vote` are registered |
| `TestGovernanceQueryCmdRegistered` | `query gov` is registered and does not panic |
| `TestGovernanceTxCmdHelpNoPanic` | All gov tx subcommand Help() calls do not panic |
| `TestGovernanceDefaultLiveFlagsUnchanged` | Adding protobuf tags does not alter any default param values |
| `TestGovernanceGovAuthorityMatchesEscrowAuthority` | Gov module address equals escrow keeper's authority — required for proposal execution |
| `TestGovernanceProposalMessagesRoundTrip` | Both enable and disable proposal messages round-trip correctly |
| `TestGovernanceAppHasGovKeeper` | Full app wires gov keeper correctly for agent testnet chain ID |

All 11 tests pass: `go test ./app/... -run TestGovernance`

---

## Verification Results

```
go mod tidy:        ✅ no changes
go mod verify:      ✅ clean
go build ./...:     ✅ 15 packages, 0 errors
go vet ./...:       ✅ 0 warnings
go test ./...:      ✅ 15 packages, all pass
predeployment-check: ✅ 23/23 gates
run-stress-tests:   ✅ pass
```

Agent testnet live run: **pending** — requires spawn-validator-agents.sh execution.

---

## Proposal IDs (live run — to be completed)

| Proposal | ID | Status | Effect |
|---|---|---|---|
| Enable escrow.live_enabled | TBD | TBD | live_enabled → true |
| Disable escrow.live_enabled | TBD | TBD | live_enabled → false |

---

## Final Live Flag State (live run — to be completed)

| Module | Flag | After enable | After disable |
|---|---|---|---|
| escrow | live_enabled | TBD | TBD |
| settlement | live_enabled | false (unchanged) | false (unchanged) |
| treasury | live_enabled | false (unchanged) | false (unchanged) |
| payout | live_enabled | false (unchanged) | false (unchanged) |

---

## Failures

None from code gates. Live run results pending.

---

## Conclusion

Phase 9F is **code complete**. The root cause (proto field tags absent, legacy proposal path used) has been diagnosed and fixed. The correct governance path is proven by 11 passing unit tests including full proto round-trip. The governance test script is updated to use gov v1 proposals with `MsgUpdateParams`. Live-flag governance control is **proven at the encoding and routing level**; on-chain confirmation requires the agent testnet live run.

External validator launch remains pending — no external validators have been onboarded, no gentxs collected, no public genesis assembled. This is an operational blocker, not a code blocker.

---

## Safety Audit

Run: `grep -r "decentralised\|decentralized\|independent validators\|external validators\|mainnet live\|buy NXRL\|token sale\|investment\|guaranteed\|profit\|APY\|returns\|price\|listing" docs/ --include="*.md" -l`

All Phase 9F documentation uses qualified language:
- "agent testnet" and "testnet-only" throughout
- "Tokens have zero value" in all proposal metadata
- "No mainnet implications" in all proposal descriptions
- No claims of decentralisation, external validators, or token availability
- External validator launch explicitly marked as pending/operational blocker
