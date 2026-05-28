# Phase 16A.7 — Governance Vote Reliability and Sequence Race Hardening

## Failure Analysis
**Single failure from full product-flow replay (Phase 16A.6):**
`FAIL settlement-treasury-routing-enable echo vote tx included code=3`

### Root Cause
The `vote_all_yes()` function in `run-product-flow-rehearsal.sh` sends ALL agent votes through **Bravo's RPC endpoint** (`--node "$BRAVO_RPC"`). When vote transactions for 5 agents are sent sequentially through a single node's RPC:

1. Each agent's vote is signed using its own key (from its own home directory)
2. But the account sequence is queried from Bravo's RPC, not the agent's own RPC
3. If Bravo's mempool has pending transactions from a specific agent (from other operations routed through Bravo), the sequence queried for that agent can be stale
4. The vote is signed with the stale sequence and rejected with code=3 (invalid sequence)

### Supporting Evidence
- Echo's vote failed on the **enable** proposal but succeeded on the **disable** proposal (lines later)
- All other agents voted successfully through Bravo's RPC
- The proposal passed with 4/5 votes (no state impact)
- This is a **transient race condition**, not a chain or module bug

### Fix Strategy

| Issue | Fix |
|---|---|
| All votes through Bravo's RPC | Route each agent's vote through **its own RPC** |
| No retry on sequence mismatch | Add retry loop with 2s delay + sequence refresh |
| No failure classification | Distinguish "vote tx failed" vs "proposal failed" |

### Changes Made

**1. `run-product-flow-rehearsal.sh` — `vote_all_yes()` hardened:**
- Each agent votes through its OWN RPC endpoint (resolved from `AGENT_DEFS`)
- Added retry loop: up to 3 attempts with 2s delay between attempts
- Failed votes are recorded but proposal outcome is tracked separately

**2. Per-agent RPC resolution added:**
```bash
# Pattern for resolving agent-specific endpoints from AGENT_DEFS:
# "name:rpc:p2p:rest:grpc"
# Used in vote_all_yes() to route votes through the correct RPC
```

### Harness Self-Test Updated
The harness check script (`check-product-flow-harness.sh`) now validates:
- Each agent has its own RPC endpoint in `AGENT_DEFS`
- Vote function uses agent-specific RPC

### Reliability Test Script
**`scripts/testnet/test-governance-vote-reliability.sh`** created but requires compatible proposal submission format for the SDK version. Can be used after verifying the proposal JSON format against the chain's governance module.

### Remaining Risk
- Sequence races can still occur if the same agent sends concurrent transactions through different RPC endpoints
- Mitigation is the retry loop which re-queries sequence on failure
- Full elimination would require centralized sequence tracking, which adds complexity
