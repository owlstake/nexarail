# Phase 15A — Runtime Invariant Framework

## Invariant Goals
Runtime invariants are assertions about blockchain state that should always be true. They protect against programming errors, state corruption, and unexpected edge cases. Invariants can be checked:
- On every block end (expensive — use sparingly)
- On demand via CLI (preferred for most checks)
- In tests only (for assertions that require controlled environments)

## Modules Covered
### Fees
- Fee split (validator / treasury / burn) shares must always sum to 10000 bps
- No share may be negative
- Fee collector module account must exist
- Burn module account must exist after any burn operation

### Settlement
- Live_enabled defaults to false (test-time invariant)
- A settlement with `FundsSettled=true` must have non-zero `FeeAmount`
- Settlement amount must be > 0
- Payer and merchant must be valid addresses

### Escrow
- Escrow cannot be both released and refunded simultaneously
- Escrow cannot transition to released after refund, or vice versa
- Live-enabled default is false (test-time invariant)

### Treasury
- A spend cannot be executed twice
- A spend cannot transition to executed after rejection
- Treasury module account must exist

### Payout
- Payout cannot be marked paid twice
- Payout cannot transition to failed after paid, or paid after failed
- Live-enabled default is false (test-time invariant)

## Implementation Status
| Invariant | On-Chain Check | Test-Only | On-Demand CLI | Deferred |
|---|---|---|---|---|
| Fee split bps sum = 10000 | — | ✅ | — | — |
| Fee shares non-negative | — | ✅ | — | — |
| Settlement live default false | — | ✅ | — | — |
| Escrow terminal state | — | ✅ | — | — |
| Payout double-mark-paid | — | ✅ | — | — |
| Treasury double-execute | — | ✅ | — | — |
| Module account existence | — | ✅ | — | — |

## Cost Considerations
- Test-only invariants have zero runtime cost
- On-demand CLI invariants have one-time query cost proportional to state size
- Per-block invariants would add O(n) scanning cost per block
- Current implementation uses test-only invariants to avoid runtime overhead

## Failure Handling Strategy
Test-only invariants:
- FAIL a test if invariant is violated
- Clearly report which invariant failed and which module

On-chain invariants (if implemented later):
- Should halt the chain with a clear error
- Should log the violating state for debugging
- Should NOT proceed with invalid state

## Why No Changes to Economics or Live Defaults
- Invariant tests only assert existing expected behavior
- No params values changed
- No live_enabled defaults changed
- No new authorization paths created
