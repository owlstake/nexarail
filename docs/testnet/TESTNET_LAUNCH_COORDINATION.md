# Testnet Launch Coordination — NexaRail Testnet

**Chain:** nexarail-testnet-1
**Phase:** 7E — Pre-Launch
**Audience:** Coordinator and accepted validators

---

## ⚠️ Critical Disclaimers

- **Testnet only.** No mainnet is live. No launch date has been set for any mainnet.
- **No monetary value.** NXRL testnet tokens cannot be exchanged or traded.
- **No token sale.** NXRL has not been offered for sale.
- **No investment.** Participation is for technical testing only.
- **Live funds are disabled.** All 6 live fund flags default to `false`.

---

## Launch Summary

| Parameter | Value |
|---|---|
| Chain ID | `nexarail-testnet-1` |
| Launch Date | [TBD] |
| Launch Time (T-0) | [TBD] UTC |
| Validator Count | [TBD] |
| Genesis Checksum | [TBD] |
| Minimum Gas Price | 0.025unxrl |

---

## Pre-Launch Timeline

| Time | Event | Owner |
|---|---|---|
| T-72h | Genesis published, checksum distributed | Coordinator |
| T-72h | Peer list distributed | Coordinator |
| T-72h | Validators verify genesis checksum | Validator |
| T-48h | Pre-launch coordination call | All |
| T-24h | Final readiness confirmation | Validator |
| T-2h | Pre-launch check | All |
| T-0 | ALL VALIDATORS START | All |
| T+5min | First blocks confirmed | Coordinator |
| T+1h | Network health confirmed | Coordinator |
| T+24h | 24h stability check | All |

---

## Validator Sync Instructions

### Step 1: Download Genesis

```bash
# Download genesis from coordinator-provided location
# Place at: ~/.nexarail/config/genesis.json

# Verify checksum
sha256sum ~/.nexarail/config/genesis.json
# Compare against published checksum
```

### Step 2: Configure Peers

```bash
# Edit ~/.nexarail/config/config.toml
# Set persistent_peers to the published peer list:
persistent_peers = "<node-id-1>@<ip-1>:26656,<node-id-2>@<ip-2>:26656,..."
pex = true
addr_book_strict = false
p2p.laddr = "tcp://0.0.0.0:26656"
```

### Step 3: Configure Minimum Gas Price

```bash
# Edit ~/.nexarail/config/app.toml (or use command-line flag)
minimum-gas-prices = "0.025unxrl"
```

### Step 4: Verify Binary

```bash
./build/nexaraild version
# Confirm build is current
```

### Step 5: Start at T-0

```bash
# At the coordinated time:
./build/nexaraild start --minimum-gas-prices 0.025unxrl
```

---

## Seed / Persistent Peer Instructions

### Seed Node (if deployed)

```
<seed-node-id>@<seed-ip>:26656
```

Set in `config.toml`:
```toml
seeds = "<seed-node-id>@<seed-ip>:26656"
```

### Persistent Peers

The coordinator will publish the complete peer list after genesis assembly. Format:

```
<val1-node-id>@<val1-ip>:26656,<val2-node-id>@<val2-ip>:26656,...
```

Set in `config.toml`:
```toml
persistent_peers = "<full-peer-list>"
```

---

## First 100 Blocks Monitoring

### Coordinator Monitor

```bash
# Monitor block height
watch -n 5 'curl -s http://<rpc>:26657/status | jq ".result.sync_info.latest_block_height"'

# Monitor validator set
watch -n 30 'curl -s http://<rpc>:26657/validators | jq "{count: (.result.validators | length), total: .result.total}"'

# Monitor peer count per validator
for ip in <validator-ips>; do
    echo "$ip: $(curl -s http://$ip:26657/net_info | jq '.result.n_peers')"
done
```

### Launch Health Checks

| Check | T+1min | T+5min | T+15min | T+1h |
|---|---|---|---|---|
| Block 1 produced | ☐ | — | — | — |
| All validators in set | ☐ | ☐ | ☐ | ☐ |
| All peers connected | ☐ | ☐ | ☐ | ☐ |
| Block time ~5-6s | — | ☐ | ☐ | ☐ |
| No panics in logs | ☐ | ☐ | ☐ | ☐ |
| Chain ID correct | ☐ | ☐ | ☐ | ☐ |
| Governance working | — | — | ☐ | ☐ |

---

## Incident Reporting

### During Launch

| Issue | Action |
|---|---|
| Validator fails to start | Validator notifies coordinator in communication channel |
| Block not produced within 30s | Coordinator investigates, validators DO NOT restart |
| Consensus halt | Coordinator declares halt, all validators STOP |
| Panic in validator log | Validator captures logs, notifies coordinator, does NOT restart |
| Wrong genesis detected | STOP immediately, verify checksum, contact coordinator |

### Incident Communication

1. Report in the testnet communication channel
2. Include: validator name, observed symptom, log excerpts (sanitised)
3. Coordinator acknowledges within 5 minutes (during launch window)
4. Do NOT take unilateral action (restart, resync, etc.) without coordinator instruction

---

## Halt / Reset Procedure

### Controlled Halt

```
1. Coordinator declares halt in communication channel
2. All validators stop their nodes (Ctrl+C)
3. Coordinator investigates root cause
4. Coordinator publishes restart instructions OR reset decision
5. If restart: coordinated new T-0 announced
6. If reset: new genesis, new checksum, new launch time
```

### Emergency Halt

```
1. Any validator detects critical issue → notify coordinator immediately
2. Coordinator confirms with ≥ 2 validators
3. Coordinator declares emergency halt
4. All validators STOP immediately
5. Coordinator leads investigation and resolution
```

### Reset Decision

If a reset is required:
- New genesis with modified validator set or parameters
- New checksum published
- All validators wipe data: `rm -rf ~/.nexarail/data/`
- New genesis placed at `~/.nexarail/config/genesis.json`
- New peer list distributed
- New T-0 coordinated

---

## Post-Launch Validator Checklist

- [ ] Monitor block production for 24 hours
- [ ] Verify you appear in validator set
- [ ] Verify peer connectivity to all other validators
- [ ] Check disk usage growth rate
- [ ] Check memory usage stability
- [ ] Report any anomalies to coordinator
- [ ] Participate in post-launch coordination call (T+24h)

---

## Emergency Contacts

| Role | Name | Contact |
|---|---|---|
| Coordinator | Bradley Johnston | [Contact TBD] |
| Technical | Clove | Via coordinator |
| Security | — | [security@nexarail.network — TBC] |

---

## Notes

- Launch is a coordinated event — timing precision matters
- All validators should be in the communication channel 30 minutes before T-0
- Keep the communication channel clear during launch for coordination only
- Have a backup contact method ready (email or phone) in case the primary channel fails
