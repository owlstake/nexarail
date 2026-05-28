# Emergency Governance Runbook — NexaRail Testnet

**Date:** 2026-05-26
**Applies to:** nexarail-testnet-1

---

## ⚠️ Testnet Only

All procedures apply to the controlled testnet. No mainnet is live. No real value at risk.

---

## When to Use Emergency Governance

| Scenario | Action |
|---|---|
| Live flag accidentally enabled | Submit proposal to disable |
| Critical vulnerability discovered | Disable affected module flags |
| Unauthorised param change | Rollback via new proposal |
| Bug in a module causing chain issues | Pause module via governance |
| Validator misbehaviour | Propose validator removal |

## Disabling Live Flags

If a live fund module flag was enabled and needs to be disabled:

```bash
# Submit governance proposal to disable a live flag
nexaraild tx gov submit-legacy-proposal param-change proposal.json \
  --from <key> --chain-id nexarail-testnet-1 \
  --gas auto --fees 1000unxrl -y
```

Proposal JSON for disabling `settlement.live_enabled`:
```json
{
  "title": "Disable settlement live_enabled",
  "description": "Emergency disable due to [reason]",
  "changes": [
    {
      "subspace": "settlement",
      "key": "live_enabled",
      "value": false
    }
  ],
  "deposit": "1000000unxrl"
}
```

## Pausing Risky Modules

Modules can be effectively paused by disabling their enablement flags:
- settlement: `live_enabled`, `treasury_routing_enabled`, `burn_routing_enabled`
- escrow: `live_enabled`
- treasury: `live_enabled`
- payout: `live_enabled`

## Parameter Rollback

If a parameter was changed in error:

```bash
# Submit rollback proposal
nexaraild tx gov submit-legacy-proposal param-change rollback.json \
  --from <key> --chain-id nexarail-testnet-1 -y
```

Proposal JSON for rolling back fee rate:
```json
{
  "title": "Rollback fee_rate_bps to 100",
  "description": "Emergency rollback due to erroneous param change",
  "changes": [
    {
      "subspace": "settlement",
      "key": "fee_rate_bps",
      "value": "100"
    }
  ],
  "deposit": "1000000unxrl"
}
```

## Software Upgrade Proposal

For emergency binary upgrades:

```bash
nexaraild tx gov submit-legacy-proposal software-upgrade v0.1.1-testnet \
  --title "Emergency Upgrade to v0.1.1-testnet" \
  --description "Emergency upgrade to fix [issue]" \
  --upgrade-height <height> \
  --from <key> --chain-id nexarail-testnet-1 -y
```

## Communication Steps

1. **Detect**: Coordinator or validator identifies issue
2. **Confirm**: Coordinator verifies with ≥ 2 validators
3. **Announce**: Post in communication channel
4. **Propose**: Submit governance proposal
5. **Vote**: Validators vote (60s voting period on testnet)
6. **Execute**: If passed, params change or upgrade executes
7. **Verify**: Confirm fix applied

## Testnet-Only Disclaimers

- All governance actions use testnet tokens (no monetary value)
- Voting period is 60s (testnet-accelerated)
- Minimum deposit is 1,000,000 unxrl (testnet token)
- Proposals can be created by any validator
- Coordinator may override governance for testnet emergencies
- These procedures are NOT suitable for mainnet without full legal and security review
