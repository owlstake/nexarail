# Validator Incident Report Template — NexaRail Testnet

**Date:** [Fill in]
**Incident ID:** INC-XXX
**Reporter:** [Validator Name / Moniker]

---

## Incident Summary

| Field | Value |
|---|---|
| Date/Time (UTC) | |
| Detected by | |
| Duration | |
| Impact | |
| Chain halted? | Yes / No |
| Resolved? | Yes / No |

## Environment

| Field | Value |
|---|---|
| Validator Moniker | |
| Node Version | `nexaraild version` output |
| Commit Hash | |
| OS / Arch | |
| Binary Source | Docker / Native / Release |
| Hosting Provider | |

## Incident Details

### What Happened

[Describe the incident in your own words. Timeline if possible.]

### Height at Incident

```
[Block height when issue was detected]
```

### Logs

```
[Paste relevant log excerpts — sanitise any private keys]
```

### Peer Status

| Metric | Value |
|---|---|
| n_peers | |
| Connected to all peers? | Yes / No |
| Missing peers | [List if any] |

### Error Messages

```
[Exact error messages from logs or CLI]
```

### Remediation Attempted

| Action | Result |
|---|---|
| | |
| | |

### Resolution

[How was the incident resolved?]

## Impact

- [ ] Block production halted
- [ ] Validator jailed
- [ ] State inconsistency detected
- [ ] Memory/disk leak
- [ ] API/REST unresponsive
- [ ] gRPC unresponsive
- [ ] P2P disconnected
- [ ] Other: [describe]

## Follow-Up

| Action | Owner | Status |
|---|---|---|
| Root cause analysis | | |
| Preventive fix | | |
| Test added | | |
| Runbook updated | | |
| Communication sent | | |

## Attachments

- [ ] Log file
- [ ] Consensus state dump
- [ ] Validator set snapshot
- [ ] Screenshots / terminal output

---

**Submit to:** Coordinator via communication channel or GitHub Issue
