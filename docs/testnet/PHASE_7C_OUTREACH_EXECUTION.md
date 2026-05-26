# Phase 7C — Outreach Execution Plan

**Date:** 2026-05-26
**Status:** Ready for execution
**Chain:** nexarail-testnet-1

---

## Objective

Begin controlled outreach to qualified technical validators, process applications through the intake pipeline, score applicants, and prepare accepted validators for gentx submission.

## Current Status

| Metric | Status |
|---|---|
| Outreach started | ⬜ Not yet |
| Applications received | 0 |
| In screening | 0 |
| Accepted | 0 |
| Awaiting gentx | 0 |
| Gentx verified | 0 |
| Genesis ready | ⬜ Not yet |

## Target Validator Count

| Parameter | Target |
|---|---|
| Minimum validators for launch | 3 |
| Target validators for launch | 5 |
| Maximum for intake round | 7 |
| Waitlist capacity | Unlimited |

**Reasoning:** 3 validators is the minimum for consensus but requires 100% uptime. 5 provides fault tolerance (can tolerate 1 offline). 7 exceeds the controlled testnet needs but builds community. We cap at 7 to keep coordination manageable.

## Preferred Validator Profile

| Attribute | Preferred | Acceptable |
|---|---|---|
| Linux host | Required | — |
| CPU | 8+ vCPU | 4 vCPU |
| RAM | 16+ GB | 8 GB |
| Disk | 200+ GB NVMe | 100 GB SSD |
| Validator experience | 2+ years, Cosmos SDK | 1+ year, any chain |
| Geographic diversity | Unique region | Any |
| Key management | HSM or hardware wallet | Secure software backup |
| Monitoring | Prometheus/Grafana | Basic alerting |
| Communication | Discord/Telegram, responsive | Email, responsive |
| Testnet commitment | Explicit understanding | Acknowledged |

## Outreach Channels

| Channel | Method | Audience |
|---|---|---|
| Cosmos validator forums | Direct post | Active Cosmos validators |
| Discord/Telegram groups | Announcement + DM | Validator communities |
| GitHub | Issue + README | Developer audience |
| Personal network | Direct contact | Known validators |
| Testnet explorer directories | Listing | Validator discovery |

## Application Process

### Submission

- **Primary:** GitHub Issues using `testnet_validator_application.md` template
- **Secondary:** Direct message to coordinator with completed application form

### Review Cadence

| Action | Frequency |
|---|---|
| Check for new applications | Daily |
| Initial screening | Within 48 hours of receipt |
| Technical review | Within 5 days of screening |
| Scoring | Per application during review |
| Acceptance notification | Within 24 hours of decision |

### Acceptance Process

1. Application passes initial screening (no red flags)
2. Technical review scores ≥ 20/35 on rubric
3. Coordinator approves inclusion
4. Acceptance email sent (Template B)
5. Validator added to shortlist
6. Acceptance checklist and gentx instructions sent
7. Validator invited to communication channel

### Rejection Process

1. Application fails screening or scores below threshold
2. Coordinator documents reason (standardised code)
3. Rejection email sent (Template D)
4. Application moved to "Rejected" in tracker
5. Applicant may reapply in future rounds

### More Information Process

1. Coordinator identifies information gap
2. "More Info Needed" email sent (Template C) with specific questions
3. 7-day response window
4. If no response: application closed
5. If response received: resume technical review

## Communication Process

### During Intake

- Auto-acknowledge within 48 hours (Template A)
- Decision notification (Template B, C, or D)
- Gentx reminder 48 hours before deadline (Template E)
- Launch coordination at T-72h, T-24h, T-2h (Template F)

### Ongoing

- Weekly validator coordination (if active validators)
- Incident/update notices as needed (Template G)
- Governance proposal notifications

## Documents Required for Execution

| Document | Status |
|---|---|
| `CONTROLLED_VALIDATOR_REGISTRATION.md` | ✅ |
| `VALIDATOR_APPLICATION_FORM.md` | ✅ |
| `VALIDATOR_ACCEPTANCE_CHECKLIST.md` | ✅ |
| `VALIDATOR_INTAKE_PIPELINE.md` | ✅ |
| `VALIDATOR_SCORING_RUBRIC.md` | ✅ |
| `VALIDATOR_EMAIL_TEMPLATES.md` | ✅ |
| `GENESIS_SUBMISSION_INSTRUCTIONS.md` | ✅ |
| `GENESIS_GENTX_REVIEW_CHECKLIST.md` | ✅ |
| `GENESIS_COORDINATOR_RUNBOOK.md` | ✅ |
| `DISCORD_TELEGRAM_MODERATION_GUIDE.md` | ✅ |
| `CONTROLLED_REGISTRATION_ANNOUNCEMENT_FINAL.md` | ✅ |
| `VALIDATOR_REGISTRATION_TRACKER_TEMPLATE.csv` | ✅ |
| `VALIDATOR_SHORTLIST.md` | ✅ (this phase) |
| `VALIDATOR_OUTREACH_LOG.md` | ✅ (this phase) |
| `GENESIS_VALIDATOR_SET_DRAFT.md` | ✅ (this phase) |
| `VALIDATOR_COORDINATION_MESSAGE.md` | ✅ (this phase) |

## Pre-Execution Checklist

Before sending the first outreach message:

- [ ] Announcement posted to at least one channel
- [ ] GitHub issue template published and test-submitted
- [ ] Tracker spreadsheet initialised
- [ ] Communication channel created (Discord/Telegram)
- [ ] Welcome message and pinned posts configured
- [ ] Moderation guide shared with moderators
- [ ] Coordinator contact information confirmed
- [ ] Gentx deadline set (recommend: 7-14 days after first acceptance)
- [ ] Genesis machine ready for gentx collection

## Timeline

| Milestone | Target |
|---|---|
| Outreach begins | [Date TBD] |
| First applications received | [TBD] |
| Application review complete (first round) | [TBD] |
| Accepted validators notified | [TBD] |
| Gentx deadline | [TBD] |
| Genesis built and published | [TBD] |
| Coordinated launch | [TBD] |

## Success Criteria

- [ ] ≥ 3 validators accepted and genlisted
- [ ] All accepted validators running Linux
- [ ] Geographic diversity across ≥ 2 regions
- [ ] All gentxs verified and included in genesis
- [ ] Coordinated launch executed
- [ ] 100 blocks produced post-launch with all validators signing
- [ ] Zero security incidents during intake
- [ ] Zero complaints about investment/token value misrepresentation
