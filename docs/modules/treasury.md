# NexaRail Treasury Module (x/treasury)

## Purpose

The `x/treasury` module manages protocol treasury accounting — treasury accounts, budgets, grants, and spend requests — with full lifecycle tracking, approvals, and reconciliation metadata.

## v1 Scope

- Treasury accounts by category (protocol, grants, security, liquidity, marketing, operations, risk reserve, ecosystem)
- Budget creation with allocation tracking and capacity enforcement
- Grant creation tied to budgets with recipient records
- Spend request lifecycle: create → approve → execute (or reject/cancel)
- Authority-gated approvals, budget status updates, and spending controls
- Indexed queries by account, budget, grant, requester, and recipient
- Genesis import/export with duplicate rejection

### Metadata-Only v1 (Default)

By default (`params.LiveEnabled=false`), no coins are moved. The module records treasury accounting, budgets, grants, spend approvals, execution metadata, and reconciliation references only.

### Live Spend Execution (Phase 5D, gated)

When `params.LiveEnabled=true` (governance-controlled), the `MarkSpendExecuted` handler transfers funds from the `nexarail_treasury` module account to the spend recipient using `bank.SendCoinsFromModuleToAccount`. The transfer:
- Occurs BEFORE the spend status is set to EXECUTED
- Sets `FundsExecuted=true` on the spend record
- Fails the entire transaction if the bank transfer fails (no partial state)
- Is gated behind `LiveEnabled=false` by default — metadata-only path preserved

### What This Module Does Not Do

- Live treasury transfers or disbursements (unless LiveEnabled is governance-enabled)
- Fee routing from the fee collector
- Burn integration
- Grant milestone release
- Multi-signature approval workflows
- Spending limits (beyond budget capacity)
- Risk reserve accounting automation
- Public treasury dashboard

## State Model

### TreasuryAccount

Category: protocol, grants, security, liquidity, marketing, operations, risk_reserve, ecosystem

### Budget

Status: draft → active → paused/closed. Closed cannot reopen.

### Grant

Status: specified/proposed → approved → active → completed/cancelled.

### SpendRequest

Lifecycle: requested → approved → executed/rejected/cancelled.

### Params

| Parameter | Default |
|---|---|
| treasury_enabled | true |
| spend_requests_enabled | true |
| grants_enabled | true |
| budgets_enabled | true |
| max_name_length | 80 |
| max_description_length | 1000 |
| max_purpose_length | 1000 |
| max_memo_length | 280 |
| min_spend_amount | 1unxrl |

## CLI

```bash
# Queries
nexaraild query treasury params
nexaraild query treasury account prot-001
nexaraild query treasury accounts
nexaraild query treasury budget bud-001
nexaraild query treasury budgets
nexaraild query treasury grant grt-001
nexaraild query treasury grants
nexaraild query treasury spend spd-001
nexaraild query treasury spends
nexaraild query treasury summary

# Transactions (all authority-gated except spend create/cancel)
nexaraild tx treasury create-account prot-001 1 "Protocol Treasury" 1000000000000unxrl --from gov
nexaraild tx treasury create-budget bud-001 prot-001 1 "Q3 Budget" 100000000000unxrl --from gov
nexaraild tx treasury create-grant grt-001 bud-001 nxr1recipient 5000000000unxrl "Grant" --from gov
nexaraild tx treasury create-spend spd-001 prot-001 nxr1recipient 1000000unxrl "purpose" --budget-id bud-001 --from requester
nexaraild tx treasury approve-spend spd-001 --from gov
nexaraild tx treasury mark-spend-executed spd-001 --from gov
nexaraild tx treasury cancel-spend spd-001 --from requester
```

## Security Notes

- All creation and lifecycle messages (except spend create/cancel) are authority-gated
- Spend requests can be created by any address with a valid account reference
- Spend requests can be cancelled by the requester or authority
- Budget capacity is enforced (allocated + spent ≤ total)
- Closed budgets cannot be reopened
- Executed spends cannot be cancelled
- v1 is metadata-only — no funds are moved

## Future Work

- Live module accounts and actual treasury transfers
- Fee routing integration from x/fees
- Burn integration for deflationary mechanics
- Grant milestone release with partial payouts
- Multi-signature approval for large spends
- Spending limits and rate limiting
- Risk reserve accounting automation
- Public treasury dashboard and transparency reports
