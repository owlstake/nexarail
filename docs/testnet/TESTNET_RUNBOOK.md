# NexaRail Testnet Runbook

**Document:** docs/testnet/TESTNET_RUNBOOK.md
**Version:** 1.0
**Date:** 2026-05-25
**Target:** Core team operators

## Launch Checklist

- [ ] Genesis published + checksum verified
- [ ] Gentx collected from all validators
- [ ] `validate-genesis` passes
- [ ] Peer list published
- [ ] Seed node(s) running
- [ ] Faucet account funded in genesis
- [ ] Faucet service deployed
- [ ] Explorer deployed + pointed at RPC
- [ ] RPC / REST / gRPC endpoints live
- [ ] Monitoring dashboards configured
- [ ] Discord announcement drafted
- [ ] Validators confirmed ready in Discord

## Pre-Launch Validation

```bash
# Validate genesis
./build/nexaraild validate-genesis

# Dry-run start (immediate halt after init)
./build/nexaraild start --halt-height 1

# Verify peer connectivity
curl -s http://localhost:26657/net_info | jq '.result.n_peers'
```

## Validator Coordination

Communication channels:
- Discord `#testnet-validators` channel
- GitHub Discussions for proposals
- Emergency: direct message to known validators

## Halt Response

If chain halts (no blocks produced for > 5 minutes):

1. Check validator status:
```bash
curl -s http://localhost:26657/status | jq '.result.sync_info.latest_block_height'
```

2. Check consensus state:
```bash
curl -s http://localhost:26657/dump_consensus_state | jq '.result.round_state'
```

3. Check logs:
```bash
journalctl -u nexaraild -n 100 --no-pager
```

4. Common causes:
   - > 1/3 validators offline → wait or contact offline validators
   - Software bug → collect logs, restart with debug logging
   - Network partition → verify peer connectivity

5. Recovery:
   - Restart `nexaraild`
   - If persistent, coordinate validator restart

## Emergency Reset

Only if chain is irrecoverably halted:

1. Announce reset in Discord + GitHub
2. Export latest state: `nexaraild export > recovery.json`
3. Create new genesis from exported state
4. Increment chain ID: `nexarail-testnet-N+1`
5. Publish new genesis + checksum
6. Validators re-initialise

## Software Upgrade

### Planned Upgrade (Governance)

1. Core team publishes upgrade height + new binary checksum
2. Validators download + verify new binary
3. `nexaraild` automatically halts at upgrade height
4. Validators restart with new binary
5. Chain resumes

### Emergency Patch (Unplanned)

1. Core team identifies critical bug
2. Announce immediate halt (if possible, via governance)
3. Validators stop `nexaraild`
4. New binary published
5. Coordinated restart at agreed time

## Chain Halt Debugging

```bash
# Check for consensus failure
grep -i "consensus failure\|timeout\|error" ~/.nexarail/logs/nexarail.log | tail -50

# Check module-specific errors
grep -i "settlement\|escrow\|treasury\|payout" ~/.nexarail/logs/nexarail.log | tail -50

# Check for invariant violations
grep -i "invariant" ~/.nexarail/logs/nexarail.log | tail -20

# Check CometBFT logs
grep -i "timeout_commit\|timeout_propose\|timeout_prevote\|timeout_precommit" \
    ~/.nexarail/logs/nexarail.log | tail -20
```

## RPC Outage Response

1. Check node status: `curl -s http://localhost:26657/status`
2. Check Nginx/load balancer
3. If node is syncing, RPC may return stale data — wait for sync
4. If node crashed, restart `nexaraild`
5. If persistent, redirect traffic to backup RPC node

## Faucet Abuse Response

1. Monitor faucet balance
2. If rapid draining detected, temporarily disable faucet
3. Identify abusing addresses / IPs
4. Add to blacklist
5. Re-enable faucet
6. Consider reducing per-address limits

## Incident Reporting

All incidents should be documented:
- Timestamp
- Description
- Root cause
- Resolution
- Prevention measure
- Posted to `#testnet-incidents` (Discord) or GitHub issue
