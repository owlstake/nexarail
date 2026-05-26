# NexaRail Live Flags Matrix

**Date:** 2026-05-25
**All flags default to false.** Enabling any flag requires a governance proposal with voting period + deposit + quorum.

## Flag Inventory

| # | Module | Flag | Default | Effect When True | Dependencies | Safe on Devnet? |
|---|---|---|---|---|---|---|
| 1 | x/escrow | `LiveEnabled` | false | Escrow custody: buyer → module account. Release/Refund/Cancel transfer funds. | None | ✅ Yes |
| 2 | x/treasury | `LiveEnabled` | false | Spend execution: treasury → recipient on MarkSpendExecuted. | None | ✅ Yes |
| 3 | x/payout | `LiveEnabled` | false | Payout execution: treasury → recipient on MarkPayoutPaid. | None | ✅ Yes |
| 4 | x/settlement | `LiveEnabled` | false | Merchant-net transfer: payer → merchant via SendCoins. | None | ✅ Yes |
| 5 | x/settlement | `TreasuryRoutingEnabled` | false | Treasury-share routing: payer → nexarail_treasury via SendCoinsFromAccountToModule. | Flag 4 (LiveEnabled) | ✅ Yes |
| 6 | x/settlement | `BurnRoutingEnabled` | false | Burn-share routing: payer → nexarail_burner → BurnCoins (supply reduction). | Flags 4 + 5 | ✅ Yes (careful — reduces supply) |

## Flag Combinations and Behaviour

### x/settlement — Progressive Enablement

| LiveEnabled | TreasuryRoutingEnabled | BurnRoutingEnabled | Bank Calls | Supply Change |
|---|---|---|---|---|
| false | * | * | None | None |
| true | false | false | 1 (SendCoins) | None |
| true | true | false | 2 (+ SendCoinsFromAccountToModule) | None |
| true | true | true | 4 (+ SendCoinsFromAccountToModule + BurnCoins) | **Decrease** (burn) |

### x/escrow, x/treasury, x/payout — Independent

| LiveEnabled | Behaviour |
|---|---|
| false | Metadata-only lifecycle |
| true | Live fund movement (custody / spend / payout) |

## Failure Behaviour

| Scenario | Behaviour |
|---|---|
| Bank transfer fails (insufficient balance, blocked address, etc.) | Error returned. Entire message handler rolls back (SDK atomicity). No state mutation. |
| Governance disables flag mid-operation | Flag read once at message start. Consistent within single transaction. | 
| Module account has zero balance (escrow release, treasury spend) | Bank transfer fails with insufficient funds. Rolls back. |
| BurnCoins fails (wrong permission, module account missing) | Error returned. All prior transfers in same tx roll back. |

## Test Coverage

| Flag | Tests | Test File |
|---|---|---|
| x/escrow LiveEnabled | ~11 live + hardening tests | `x/escrow/keeper/keeper_test.go` |
| x/treasury LiveEnabled | ~7 live + hardening tests | `x/treasury/keeper/keeper_test.go` |
| x/payout LiveEnabled | ~5 live tests | `x/payout/keeper/keeper_test.go` |
| x/settlement LiveEnabled | ~12 tests (metadata, live, failure, invariants) | `x/settlement/keeper/keeper_test.go` |
| x/settlement TreasuryRoutingEnabled | ~22 tests | `x/settlement/keeper/keeper_test.go` |
| x/settlement BurnRoutingEnabled | ~20 tests | `x/settlement/keeper/keeper_test.go` |

## Enabling on Devnet

All flags are safe to enable on a local devnet for testing. Recommended enablement order:

```
1. x/settlement LiveEnabled          (merchant payments)
2. x/escrow LiveEnabled              (escrow custody)
3. x/settlement TreasuryRoutingEnabled  (treasury fee accumulation)
4. x/treasury LiveEnabled            (treasury spend execution)
5. x/payout LiveEnabled              (payout execution)
6. x/settlement BurnRoutingEnabled   (supply reduction — enable last)
```

### Governance Examples (local devnet only)

```bash
# Enable settlement live merchant transfers
nexaraild tx gov submit-proposal param-change proposal.json --from validator --chain-id nexarail-devnet-1

# proposal.json:
{
  "title": "Enable Settlement Live Transfers",
  "description": "Enable live merchant-net transfers on devnet",
  "changes": [
    {
      "subspace": "settlement",
      "key": "LiveEnabled",
      "value": "true"
    }
  ],
  "deposit": "10000000unxrl"
}
```

**Note:** Custom modules (settlement, escrow, treasury, payout) use direct KV storage, not Cosmos SDK params subspaces. Governance proposals must use `MsgUpdateParams` messages for each module rather than parameter change proposals.

## Flag Not Yet Implemented

| Module | Flag | Status |
|---|---|---|
| x/settlement | `ValidatorRoutingEnabled` | Deferred (Phase 5F.7 design complete) |
