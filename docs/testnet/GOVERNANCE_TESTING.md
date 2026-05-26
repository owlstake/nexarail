# NexaRail Testnet Governance Testing

**Document:** docs/testnet/GOVERNANCE_TESTING.md
**Version:** 1.0
**Date:** 2026-05-25
**Status:** Testnet-only proposals — NOT for mainnet

## Purpose

Exercise governance proposal lifecycle on testnet. Enable live fund flows progressively, test parameter changes, verify quorum and voting behaviour.

## Prerequisites

- Testnet running with multiple validators
- Validators have funded accounts
- Governance parameters set appropriately for testnet (shorter voting period recommended)

### Testnet Governance Params (Recommended)

```json
{
  "voting_period": "300s",       // 5 minutes (fast for testing)
  "min_deposit": "1000000unxrl", // 1 NXRL
  "quorum": "0.2",               // 20%
  "threshold": "0.5",            // 50%
  "veto_threshold": "0.334"      // 33.4%
}
```

Set via genesis or `MsgUpdateParams` on gov module.

## Proposal Templates

### 1. Enable Escrow LiveEnabled

```json
{
  "title": "TESTNET: Enable Escrow Live Custody",
  "description": "☢️ TESTNET ONLY. This proposal enables live escrow custody on the NexaRail testnet. If passed, escrow CreateEscrow will transfer buyer funds to the nexarail_escrow module account. Release, Refund, Cancel, and ResolveDispute will transfer funds accordingly. This proposal is for testing purposes only and carries no mainnet implications.",
  "changes": [
    {"subspace": "escrow", "key": "LiveEnabled", "value": "true"}
  ],
  "deposit": "1000000unxrl"
}
```

**Note:** Custom modules use per-module `MsgUpdateParams`, not parameter change proposals. Use:
```bash
nexaraild tx escrow update-params --live-enabled true \
    --from validator --chain-id nexarail-testnet-1 -y
```

### 2. Enable Treasury LiveEnabled

```bash
nexaraild tx treasury update-params --live-enabled true \
    --from validator --chain-id nexarail-testnet-1 -y
```

### 3. Enable Payout LiveEnabled

```bash
nexaraild tx payout update-params --live-enabled true \
    --from validator --chain-id nexarail-testnet-1 -y
```

### 4. Enable Settlement LiveEnabled

```bash
nexaraild tx settlement update-params --live-enabled true \
    --from validator --chain-id nexarail-testnet-1 -y
```

### 5. Enable Settlement TreasuryRoutingEnabled

```bash
nexaraild tx settlement update-params --treasury-routing-enabled true \
    --from validator --chain-id nexarail-testnet-1 -y
```

### 6. Enable Settlement BurnRoutingEnabled

```bash
nexaraild tx settlement update-params --burn-routing-enabled true \
    --from validator --chain-id nexarail-testnet-1 -y
```

### 7. Disable Flags After Testing

Reverse the enable commands:
```bash
nexaraild tx settlement update-params --burn-routing-enabled false \
    --from validator --chain-id nexarail-testnet-1 -y
nexaraild tx settlement update-params --treasury-routing-enabled false \
    --from validator --chain-id nexarail-testnet-1 -y
nexaraild tx settlement update-params --live-enabled false \
    --from validator --chain-id nexarail-testnet-1 -y
```

### 8. Parameter Update: Fee Rate

```bash
# Update settlement fee rate from 100 bps (1%) to 50 bps (0.5%)
nexaraild tx settlement update-params --fee-rate-bps 50 \
    --from validator --chain-id nexarail-testnet-1 -y
```

### 9. Parameter Update: Fee Split

```bash
# Update fee split (via x/fees module)
nexaraild tx fees update-params \
    --validator-share-bps 5000 \
    --treasury-share-bps 3000 \
    --burn-share-bps 2000 \
    --from validator --chain-id nexarail-testnet-1 -y
```

## Governance Test Flow

For each flag:
1. Query current params: `nexaraild query settlement params`
2. Verify flag is `false`
3. Submit enable proposal via authority
4. Verify flag is `true`: `nexaraild query settlement params`
5. Execute live fund flow (create settlement, escrow, etc.)
6. Verify on-chain balance changes
7. Submit disable proposal
8. Verify flag is `false` again
9. Confirm metadata-only behaviour restored

## Validator Voting

Validators should vote on all test proposals:
```bash
nexaraild tx gov vote <proposal-id> yes \
    --from <validator-key> --chain-id nexarail-testnet-1 -y
```

## ⚠️ Testnet-Only Warning

All proposals in this document are **testnet-only**. They enable features on a test network with zero-value tokens. Do not use these proposals on mainnet. Mainnet governance would require separate, reviewed proposals with appropriate voting periods and deposits.
