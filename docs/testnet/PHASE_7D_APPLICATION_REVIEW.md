# Phase 7D — Application Review Framework

**Date:** 2026-05-26
**Status:** Ready for execution
**Chain:** nexarail-testnet-1

---

## Objective

Process validator applications received during controlled outreach, score each applicant using the rubric, accept a curated validator set, and reject or waitlist remaining applicants with clear reasoning.

## Review Team

| Role | Name | Responsibility |
|---|---|---|
| Coordinator | Bradley Johnston | Final decision on all applications |
| Technical Reviewer | Clove (or designate) | Technical review and scoring |
| Communications | Coordinator | Applicant notifications |

## Review Principles

1. **Consistency** — every applicant scored against the same rubric
2. **Transparency** — rejection reasons are clear and honest
3. **Speed** — decisions within published SLAs
4. **No favouritism** — personal relationships do not influence scoring
5. **Safety first** — red flags result in immediate rejection regardless of score
6. **Testnet only** — reinforce at every stage: no mainnet, no token value, no investment

## Application Review Process

### Step 1: Intake

| Action | Owner | SLA |
|---|---|---|
| Application received via GitHub Issue or form | System | — |
| Assign application ID (APP-XXX) | Coordinator | Same day |
| Log in tracker CSV | Coordinator | Same day |
| Send acknowledgment (Template A) | Communications | 48 hours |

### Step 2: Initial Screening

| Action | Owner | SLA |
|---|---|---|
| Check for red flags | Coordinator | 3 days |
| Verify all required fields complete | Coordinator | 3 days |
| Verify contact information | Coordinator | 3 days |
| Check jurisdiction acceptability | Coordinator | 3 days |

**Red flag = immediate rejection:**
- Claims NXRL has monetary value or is an investment
- Intends to run on macOS/Docker Desktop as primary infra
- Fraudulent or false information
- Refuses to acknowledge testnet-only nature
- Impersonation of known entities
- History of validator attacks or slashing exploits

**Screening outcome:**
- Pass → advance to Technical Review
- Fail → reject with reason (Template D with rejection code)
- Incomplete → request more info (Template C)

### Step 3: Technical Review

| Action | Owner | SLA |
|---|---|---|
| Score against 7-category rubric | Technical Reviewer | 5 days |
| Assess Linux/server capability | Technical Reviewer | — |
| Assess validator experience | Technical Reviewer | — |
| Assess monitoring capability | Technical Reviewer | — |
| Assess security practices | Technical Reviewer | — |
| Assess communication reliability | Technical Reviewer | — |
| Assess geographic/network diversity | Technical Reviewer | — |
| Assess testnet commitment understanding | Technical Reviewer | — |
| Record score and notes in shortlist | Technical Reviewer | — |

**Scoring rubric:** See `VALIDATOR_SCORING_RUBRIC.md`

| Score | Decision |
|---|---|
| 30-35 | Strong accept |
| 25-29 | Accept |
| 20-24 | Conditional accept |
| 15-19 | Waitlist |
| 0-14 | Reject |

### Step 4: Decision

| Action | Owner | SLA |
|---|---|---|
| Coordinator reviews score and recommendation | Coordinator | 24 hours |
| Coordinator makes final decision | Coordinator | — |
| If accepted: verify slot available (≤ 7 total) | Coordinator | — |
| If waitlisted: add to waitlist queue | Coordinator | — |
| If rejected: document rejection code | Coordinator | — |
| Send decision notification (Template B/C/D) | Communications | 24 hours |

### Step 5: Post-Decision

**If accepted:**
- Send acceptance checklist and gentx instructions
- Add to genesis validator set draft
- Invite to communication channel
- Set gentx deadline expectation

**If waitlisted:**
- Position in queue noted
- Notify if slot opens

**If rejected:**
- Application closed
- Applicant may reapply in future rounds

## Review Schedule

| Activity | Frequency |
|---|---|
| Check for new applications | Daily |
| Initial screening batch | Every 2-3 days |
| Technical review batch | Weekly (or per application) |
| Decision notifications | Within 24 hours of review |

## Quality Gates

Before an application can be marked "Accepted":

- [ ] All 7 scoring categories assessed
- [ ] Score ≥ 20/35
- [ ] No red flags
- [ ] Linux host confirmed
- [ ] Contact information verified
- [ ] Testnet-only understanding explicit
- [ ] Coordinator sign-off obtained
- [ ] Slot available in validator set (≤ 7)

## Review Documentation

For each application, maintain:
- Application form (submitted by applicant)
- Scoring sheet (internal)
- Review notes (internal)
- Decision and rationale (internal)
- Communication log (all emails/messages)

Store internally. Do not share scores or internal notes with applicants.

## Appeals

Applicants may request reconsideration within 7 days of rejection. Appeals are reviewed by the coordinator. The coordinator's decision on appeal is final.

Valid appeal grounds:
- Factual error in review (e.g., hardware mischaracterised)
- New information not available at time of application
- Changed circumstances (e.g., upgraded infrastructure)

Invalid appeal grounds:
- Disagreement with scoring
- Claims about token value or investment
- Pressure or threats

## Current Review Status

| Metric | Count |
|---|---|
| Applications received | 0 |
| In initial screening | 0 |
| In technical review | 0 |
| Accepted | 0 |
| Waitlisted | 0 |
| Rejected | 0 |
| More info requested | 0 |

## Notes

- Review criteria may tighten as slots fill (earlier applicants benefit)
- Geographic diversity is weighted more heavily once baseline validator set exists
- Coordinator may override scores for strategic diversity contributions
- All decisions are for the controlled testnet only — not precedent for any future mainnet validator set
