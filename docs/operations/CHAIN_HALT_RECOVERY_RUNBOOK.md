# Chain Halt Recovery Runbook — NexaRail Testnet

**Date:** 2026-05-26
**Applies to:** nexarail-testnet-1

---

## ⚠️ Testnet Only

This runbook applies to the controlled testnet. No mainnet is live. No real value is at risk.

---

## Symptoms of Chain Halt

- Block height stops incrementing
- `curl http://<rpc>:26657/status` shows same height for >60s
- Validator logs show consensus timeout errors
- `catching_up` remains true indefinitely

## Immediate Actions

### Coordinator
1. Confirm halt with ≥ 2 validators
2. Announce halt in communication channel
3. Instruct validators: **DO NOT restart** until diagnosis

### Validator
1. Note the last block height
2. Capture logs: `journalctl -u nexaraild --since "5 minutes ago" > halt-logs.txt`
3. DO NOT restart or reset data
4. Wait for coordinator instructions

## Log Collection

```bash
# Validator logs (systemd)
journalctl -u nexaraild --since "10 minutes ago" > halt-logs.txt

# Docker logs
docker logs nexarail-val0 --tail 200 > halt-logs.txt

# Consensus state
curl -s http://localhost:26657/dump_consensus_state > consensus-state.json

# Validator set at halt height
curl -s http://localhost:26657/validators?height=$(curl -s http://localhost:26657/status | jq -r '.result.sync_info.latest_block_height') > validator-set.json
```

## Diagnosis

Common causes:
1. **Validator offline**: One validator disconnected — check peer count
2. **Consensus timeout**: Network latency or clock skew
3. **App hash mismatch**: Node state diverged — requires reset
4. **Disk full**: IAVL tree can't write — check disk space
5. **Upgrade halt**: Planned halt at upgrade height — expected

## Recovery Procedures

### Recovery A: Validator Restart (Minor)

If one validator crashed:
1. Coordinator confirms which validator is down
2. That validator restarts their node
3. Chain resumes within 30s

### Recovery B: Coordinated Restart (Consensus Failure)

If all validators lost consensus:
1. All validators stop nodes
2. Coordinator announces restart time
3. At announced time: all validators restart simultaneously
4. Chain resumes from last committed height

### Recovery C: State Reset (App Hash Mismatch)

If a node's state diverged:
1. Stop the affected node
2. Wipe data: `rm -rf ~/.nexarail/data/`
3. Download state snapshot from coordinator or peer (if available)
4. Or: resync from genesis (slow)
5. Restart node

### Recovery D: Genesis Reset (Catastrophic)

If recovery is impossible:
1. Coordinator declares genesis reset
2. All validators wipe data: `rm -rf ~/.nexarail/data/`
3. New genesis distributed with checksum
4. New peer list distributed
5. New launch time coordinated

## Unsafe Reset Warning

**Never use these operations without coordinator instruction:**
- `tendermint unsafe-reset-all` — wipes all chain data
- Deleting `~/.nexarail/data/` without backup
- Restarting with a different genesis than other validators

## When to Reset the Testnet

Resets are acceptable for testnet:
- After a failed upgrade
- After state corruption
- To test genesis changes
- Between major version upgrades

Resets are routine in testnet. No real value is lost.

## State Export (Pre-Reset)

```bash
# Export state at current height
nexaraild export --height <halt-height> > exported-state.json

# The export can be used to rebuild genesis
# Module params and accounts are preserved
```

## Incident Report

After recovery, file an incident report using `docs/operations/VALIDATOR_INCIDENT_REPORT_TEMPLATE.md`.
