# Validator Intake Pipeline — NexaRail Testnet

**Chain:** nexarail-testnet-1
**Phase:** 7B — Outreach, Intake & Operations
**Audience:** Genesis coordinator (internal)

---

## Pipeline Stages

```
APPLICATION RECEIVED  →  INITIAL SCREENING  →  TECHNICAL REVIEW
         ↓                       ↓                      ↓
    (auto-ack)           (rejected/waitlist)    (more info needed)
                                                         ↓
       ACCEPTED  →  GENTX SUBMITTED  →  GENTX VERIFIED
           ↓                ↓                   ↓
    (checklist sent)  (reminder nudge)    (rejected/resubmit)
                                                    ↓
    GENESIS INCLUDED  →  LAUNCH STANDBY  →  ACTIVE VALIDATOR
           ↓                   ↓                    ↓
    (checksum published)  (T-0 coordinated)   (monitoring)
```

## Stage Detail

### Stage 1: Application Received

| Field | Detail |
|---|---|
| Trigger | Application form submitted via GitHub Issue or designated channel |
| Owner | Coordinator |
| Action | Log application in tracker, assign ID |
| Auto-response | Send "Application Received" email (Template A) |
| SLA | Acknowledge within 48 hours |

**Entry criteria:**
- [ ] Application submitted via correct channel
- [ ] All required fields present
- [ ] Applicant confirmed testnet-only disclaimers

**Exit criteria:**
- [ ] Application logged in tracker
- [ ] Auto-acknowledgment sent
- [ ] Status advanced to "Initial Screening"

### Stage 2: Initial Screening

| Field | Detail |
|---|---|
| Trigger | Application acknowledged |
| Owner | Coordinator |
| Action | Review for red flags, completeness, basic eligibility |
| Outcome | Advance to Technical Review OR Reject/Waitlist |
| SLA | Complete within 3 days of receipt |

**Red flags (immediate rejection):**
- [ ] Claims NXRL has monetary value or is an investment
- [ ] Intends to run on macOS/Docker Desktop as primary infrastructure
- [ ] Application contains fraudulent or obviously false information
- [ ] Applicant refuses to acknowledge testnet-only nature
- [ ] History of validator attacks or slashing exploits

**Screening checks:**
- [ ] All required fields complete
- [ ] Contact information provided and valid-looking
- [ ] Country/jurisdiction acceptable (no restricted jurisdictions)
- [ ] Operator name and moniker not impersonating known entities
- [ ] Disclaimers acknowledged (checklist in application form)

**Exit criteria:**
- [ ] No red flags found
- [ ] All screening checks passed
- [ ] Status advanced to "Technical Review" OR rejected with reason

### Stage 3: Technical Review

| Field | Detail |
|---|---|
| Trigger | Initial screening passed |
| Owner | Coordinator (may consult technical advisor) |
| Action | Review hardware, experience, technical capability |
| Outcome | Accepted / More Information Needed / Rejected |
| SLA | Complete within 5 days of screening |

**Review criteria:**
- [ ] Linux host confirmed (not macOS/Docker Desktop)
- [ ] Hardware meets minimum (4 vCPU, 8 GB RAM, 100 GB SSD)
- [ ] Public static IP available
- [ ] Validator experience assessed (scoring rubric)
- [ ] Key management practice assessed
- [ ] Monitoring capability assessed
- [ ] Communication reliability assessed
- [ ] Geographic/network diversity contribution assessed

**Score threshold:** See `VALIDATOR_SCORING_RUBRIC.md`

**Exit criteria:**
- [ ] Score assessed
- [ ] Decision: Accepted / More Info / Rejected
- [ ] Applicant notified with appropriate template

### Stage 4: Accepted

| Field | Detail |
|---|---|
| Trigger | Technical review passed |
| Owner | Coordinator |
| Action | Send acceptance package, instructions, deadline |
| SLA | Within 24 hours of acceptance decision |

**Acceptance package includes:**
- [ ] Acceptance notification (Template B)
- [ ] Link to `VALIDATOR_ACCEPTANCE_CHECKLIST.md`
- [ ] Link to `GENESIS_SUBMISSION_INSTRUCTIONS.md`
- [ ] Genesis file (or instructions to wait for it)
- [ ] Persistent peer list (coordinator seed nodes)
- [ ] Gentx submission deadline
- [ ] Communication channel invite

**Exit criteria:**
- [ ] Acceptance package sent
- [ ] Status advanced to "Gentx Submitted" (when gentx received)

### Stage 5: Gentx Submitted

| Field | Detail |
|---|---|
| Trigger | Validator submits gentx |
| Owner | Coordinator |
| Action | Log receipt, verify gentx, advance or request resubmission |
| SLA | Verify within 3 days of receipt |

**Gentx receipt check:**
- [ ] File received (not private keys)
- [ ] File is valid JSON
- [ ] File is a gentx (has expected structure)

**Exit criteria:**
- [ ] Gentx logged in tracker
- [ ] Reminder sent if approaching deadline (Template E)
- [ ] Status advanced to "Gentx Verified" (when verified)

### Stage 6: Gentx Verified

| Field | Detail |
|---|---|
| Trigger | Gentx received and validation passes |
| Owner | Coordinator |
| Action | Run gentx validation, include in genesis, or reject with reason |
| SLA | Complete before genesis build deadline |

**Verification checklist:** See `GENESIS_GENTX_REVIEW_CHECKLIST.md`

**Exit criteria:**
- [ ] All gentx validation checks pass
- [ ] Gentx included in genesis build
- [ ] Status advanced to "Genesis Included"

### Stage 7: Genesis Included

| Field | Detail |
|---|---|
| Trigger | Gentx included in final genesis |
| Owner | Coordinator |
| Action | Publish genesis checksum, peer list, launch time |
| SLA | 48+ hours before T-0 |

**Actions:**
- [ ] Final genesis built with all verified gentxs
- [ ] Genesis checksum published to all validators
- [ ] Peer list distributed
- [ ] Launch time confirmed
- [ ] Status advanced to "Launch Standby"

**Exit criteria:**
- [ ] Validator confirms receipt of genesis and checksum
- [ ] Validator confirms readiness

### Stage 8: Launch Standby

| Field | Detail |
|---|---|
| Trigger | Genesis published, T-0 approaching |
| Owner | Validator (primary), Coordinator (oversight) |
| Action | Pre-launch check, wait for T-0, start node |

**Pre-launch check (T-2 hours):**
- [ ] Genesis checksum verified by validator
- [ ] Binary built and ready
- [ ] Ports confirmed open
- [ ] Validator in communication channel
- [ ] Validator confirms they will be at T-0

**Launch (T-0):**
- [ ] All validators start simultaneously
- [ ] Coordinator monitors first blocks
- [ ] Status advanced to "Active Validator"

### Stage 9: Active Validator

| Field | Detail |
|---|---|
| Trigger | Validator node running and producing blocks |
| Owner | Both |
| Action | Ongoing monitoring, governance, coordination |

**Ongoing:**
- [ ] Block production confirmed
- [ ] Validator appears in validator set
- [ ] Peer connectivity healthy
- [ ] Validator participates in governance
- [ ] Validator responds to communications

## Pipeline States Summary

| State | Meaning | Next |
|---|---|---|
| Application Received | Form submitted, auto-ack sent | Initial Screening |
| Initial Screening | Red flags check | Technical Review or Rejected |
| Technical Review | Capability assessment | Accepted / More Info / Rejected |
| Accepted | Validator approved | Gentx Submitted |
| Gentx Submitted | Gentx received | Gentx Verified |
| Gentx Verified | Gentx validated | Genesis Included |
| Genesis Included | In final genesis | Launch Standby |
| Launch Standby | Ready for T-0 | Active Validator |
| Active Validator | Producing blocks | Ongoing |
| Rejected | Not accepted | Application closed |
| More Info Needed | Additional details required | Technical Review (resume) |

## Rejection Reasons (Standardised)

| Code | Reason | Template |
|---|---|---|
| R1 | Hardware below minimum | Template D |
| R2 | No Linux host | Template D |
| R3 | Insufficient validator experience | Template D |
| R4 | Application incomplete | Template C (more info) then D |
| R5 | Red flag (token value/investment claim) | Template D |
| R6 | Restricted jurisdiction | Template D |
| R7 | Impersonation or fraud | No template — manual |
| R8 | Capacity reached (waitlist) | Template D (waitlist variant) |

## SLA Summary

| Stage | SLA |
|---|---|
| Application acknowledgment | 48 hours |
| Initial screening | 3 days |
| Technical review | 5 days |
| Acceptance notification | 24 hours after decision |
| Gentx verification | 3 days after receipt |
| Gentx reminder (if late) | 48 hours before deadline |
| Pre-launch check | T-2 hours |
| Post-launch monitoring | Continuous |

## Tracker

See `VALIDATOR_REGISTRATION_TRACKER_TEMPLATE.csv` for the tracking spreadsheet template.
