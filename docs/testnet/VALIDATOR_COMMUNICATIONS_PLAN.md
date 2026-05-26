# Validator Communications Plan — NexaRail Testnet

**Chain:** nexarail-testnet-1
**Phase:** Controlled Registration
**Audience:** Validator operators, genesis coordinator, technical support

---

## Communication Channels

| Channel | Purpose | Access |
|---|---|---|
| Discord / Telegram (TBD) | Primary coordination, announcements, community | All validators + public |
| GitHub Issues | Bug reports, feature requests, technical issues | Public |
| Direct Message (Signal/Telegram) | Emergency contact, sensitive issues | Coordinator ↔ Validator |
| Email (TBD) | Formal communications, security reports | All validators |
| GitHub Repository | Code, docs, release notes | Public |

## Announcement Protocol

### Routine Announcements

- **Where:** Primary chat channel (Discord/Telegram)
- **When:** As needed
- **What:** Status updates, timeline reminders, documentation updates
- **Response expected:** Acknowledgment preferred, not required

### Time-Sensitive Announcements

- **Where:** Primary chat channel + direct message to all validators
- **When:** 24-72 hours before action required
- **What:** Upgrade coordination, gentx deadlines, genesis ceremony scheduling
- **Response expected:** Confirmation of receipt within 24 hours

### Emergency Communications

- **Where:** Direct message to all validators + announcement channel
- **When:** Immediately upon detection
- **What:** Chain halt, security incident, critical bug, emergency upgrade
- **Response expected:** Immediate acknowledgment, action within 1 hour

## Technical Support

### Tier 1: Self-Service

- Documentation: `docs/testnet/`
- FAQ: `docs/testnet/FAQ.md`
- Runbook: `docs/testnet/CONTROLLED_VALIDATOR_REGISTRATION.md`

### Tier 2: Community Support

- Primary chat channel for peer support
- Validators help validators
- Coordinator monitors and escalates

### Tier 3: Coordinator Support

- Direct message to coordinator for blocking issues
- GitHub Issues for reproducible bugs
- Response time: 24-48 hours (non-emergency)

## Issue Reporting

### Bug Reports

Use GitHub Issues with the bug report template:
- Description of the issue
- Steps to reproduce
- Expected vs actual behaviour
- Logs and evidence (sanitised — no private keys)
- Environment details (OS, binary version, commit hash)

### Security Reports

- Do NOT file security issues as public GitHub Issues
- Report via designated security contact:
  - Email: `security@nexarail.network` (TBC)
  - Encrypted channel if available
- See `docs/security/` for responsible disclosure policy

## Validator Coordination Calls

### Genesis Ceremony

- **When:** ~48 hours before T-0
- **Duration:** 30-60 minutes
- **Agenda:**
  - Final genesis checksum verification
  - Launch time confirmation
  - Peer list distribution
  - Emergency contacts confirmation
  - Launch sequence walkthrough

### Pre-Launch Check

- **When:** ~2 hours before T-0
- **Duration:** 15 minutes
- **Agenda:**
  - All validators confirm readiness
  - Last-minute issues
  - Countdown synchronisation

### Post-Launch Monitoring

- **When:** T+2 hours, T+24 hours, T+72 hours
- **Duration:** 15-30 minutes
- **Agenda:**
  - Block production status
  - Peer connectivity
  - Performance metrics
  - Issues encountered

### Recurring

- **When:** Weekly (day/time TBD)
- **Duration:** 30 minutes
- **Agenda:**
  - Network health review
  - Upcoming upgrades
  - Governance proposals
  - Open issues

## Emergency Halt Communication

If the chain halts unexpectedly:

1. **Coordinator detects halt** (monitoring alert or validator report)
2. **Coordinator confirms** with at least 2 validators
3. **Emergency announcement** sent to all validators (direct + channel)
4. **Validators: DO NOT restart** until coordinator provides diagnosis
5. **Coordinator investigates** root cause
6. **Coordinator publishes** restart instructions or upgrade path
7. **Coordinated restart** at announced time

## Upgrade Communication

### Planned Upgrades

1. **Proposal:** Governance proposal submitted on-chain
2. **Discussion:** 3-5 day discussion period in chat channel
3. **Voting:** Validators vote on-chain
4. **If passed:** Coordinator announces upgrade height and binary
5. **Preparation:** Validators build/install new binary
6. **Upgrade:** Automatic at specified height (or coordinated manual)

### Emergency Upgrades

1. **Detection:** Bug or vulnerability discovered
2. **Assessment:** Coordinator assesses severity and fix
3. **Announcement:** Emergency communication to all validators
4. **Patch:** New binary released
5. **Coordination:** Coordinated upgrade time announced
6. **Execution:** All validators upgrade simultaneously

## Offboarding

If a validator wishes to leave:

1. Notify coordinator through direct message
2. Provide notice period (ideally 48+ hours)
3. Coordinator arranges validator set adjustment if needed
4. Validator may undelegate and remove node

If a validator is removed:

1. Coordinator notifies validator of governance decision
2. Validator stops node
3. Validator set adjusts automatically at next epoch

## Communication Rules

- Be professional and constructive
- No price discussion, investment advice, or token value speculation
- No disclosure of private keys, mnemonics, or sensitive infrastructure details in public channels
- Respect the testnet-only nature — no mainnet or token sale claims
- Report violations to the coordinator

## Contact Escalation

| Level | Contact | Response Time |
|---|---|---|
| General inquiry | Chat channel | 24-48 hours |
| Technical blocking issue | Direct message to coordinator | 24 hours |
| Chain halt | Emergency direct message | 1 hour |
| Security vulnerability | Security email | 4 hours |
