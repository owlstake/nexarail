# Phase 9O — Gov Runtime Proof

**Date:** 2026-05-26
**Chain:** nexarail-agent-testnet-1
**Status:** Partial proof — proposal submitted on-chain; full lifecycle blocked by sequence tracking

---

## Runtime Setup

| Parameter | Value |
|---|---|
| Agent count | 5 |
| Chain ID | nexarail-agent-testnet-1 |
| Binary | build/nexaraild (Phase 9N descriptor fix included) |
| gRPC enabled | ✅ All 5 agents |
| gRPC-web disabled | ✅ (avoids port conflicts) |
| Rosetta disabled | ✅ (avoids PrepareProposal panic) |
| Voting period | 30s (genesis) |
| Validator set | 5 |

## Runtime Stability

| Issue | Status | Fix |
|---|---|---|
| All 5 agents produce blocks | ✅ | gRPC-web + Rosetta disabled |
| RPC endpoints respond | ✅ | Ports 27657-27697 |
| gRPC endpoints respond | ✅ | Ports 9190-9194 |
| gRPC BroadcastTx state version error | ⚠️ | gRPC queries fail on just-restarted nodes |
| PrepareProposal nil pointer panic | ✅ Fixed | Rosetta disabled |
| gRPC-web port conflicts | ✅ Fixed | gRPC-web disabled |
| Agent sequences | ⚠️ | Non-zero for some validators after gentx/restart |

## gRPC Health

All 5 agents: cosmos.tx.v1beta1.Service, BroadcastTx, nexarail.escrow.v1.Query, cosmos.gov.v1.Query available.

**Caveat:** gRPC BroadcastTx and ABCI state queries fail with "failed to load state at height N; version does not exist" on just-restarted nodes. This is a Cosmos SDK multistore versioning issue. Workaround: CometBFT RPC for broadcast.

## Governance Proof

### Enable Proposal

| Field | Value |
|---|---|
| Proposal ID | **1** |
| Submit tx hash | `685A24844676309BB30FB4FA799575009390EA42FB1C173FAF8C3D114F61B96A` |
| Submit tx code | **0 (SUCCESS)** |
| Block height | 45 |
| Proposal events | `submit_proposal proposal_id=1`, `proposal_deposit proposal_id=1` |

**✅ Goverance proposal SUCCESSFULLY SUBMITTED ON-CHAIN.** This is the first time a gov v1 proposal with nested Any messages has been submitted and confirmed on the agent testnet.

### Vote Results

| Agent | Vote tx hash | Status |
|---|---|---|
| bravo | `34288FDF7732DAD1E4F458FBCCCCF9B9246B7282DAF983D934CA9E137E9695D5` | ✅ On-chain (height 75) |
| alpha | Pending | ⚠️ Sequence tracking needed |
| charlie | Pending | ⚠️ Sequence tracking needed |
| delta | Pending | ⚠️ Sequence tracking needed |
| echo | Pending | ⚠️ Sequence tracking needed |

Bravo's vote confirmed on-chain at height 75. Other validators blocked by sequence tracking (fresh genesis sequences not correctly tracked).

### Proposal Status

Proposal 1 created but not yet passed (requires 4 more votes). Voting period is 30s. State queries blocked by gRPC version issue.

### LiveEnabled

- Before: `false` (default)
- After enable proposal: Pending (requires proposal to pass)
- After disable proposal: Pending

## Final Live Flags (current)

| Module | Flag | Value |
|---|---|---|
| escrow | live_enabled | false |
| settlement | live_enabled | false |
| treasury | live_enabled | false |
| payout | live_enabled | false |

## Evidence Path

```
rehearsals/validator-agents/gov-runtime/evidence/20260526_213845/
├── tx.hex, tx.b64 (enable proposal encoded bytes)
├── broadcast-enable.json (CometBFT RPC response, code 0)
├── votes/
│   ├── alpha_unsigned.json, alpha_signed.json, alpha.b64
│   ├── bravo_unsigned.json, bravo_signed.json, bravo.b64
│   ├── charlie_unsigned.json, ...
│   ├── delta_unsigned.json, ...
│   └── echo_unsigned.json, ...
```

## Remaining Blockers

| Blocker | Severity | Status |
|---|---|---|
| Non-bravo validator sequences | Medium | Need sequence tracking doc |
| gRPC state version race | Low | CometBFT RPC workaround works |
| gRPC BroadcastTx unreliability | Low | CometBFT RPC workaround |
| REST gateway "Not Implemented" | Low | gRPC direct works |

## Conclusion

Phase 9O is **partially complete**. The governance proposal was successfully submitted on-chain via proto broadcast — the first confirmed gov v1 proposal with nested Any messages on the agent testnet. This proves the descriptor fix (Phase 9N) works end-to-end. Full lifecycle proof (votes → pass → disable → pass → all false) requires sequence tracking for remaining validators.
