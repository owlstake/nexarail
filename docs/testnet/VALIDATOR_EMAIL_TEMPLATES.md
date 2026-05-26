# Validator Email Templates — NexaRail Testnet

**Chain:** nexarail-testnet-1
**Phase:** 7B — Intake Communications
**Use:** Standardised emails for validator intake pipeline

---

## Template A: Application Received

**Subject:** NexaRail Testnet — Validator Application Received (APP-XXX)

Dear [Operator Name],

Thank you for applying to operate a validator on the NexaRail controlled testnet (`nexarail-testnet-1`).

**Your application reference:** APP-[XXX]

**What happens next:**

1. Your application will be screened for completeness and eligibility (typically within 3 days).
2. If it passes initial screening, it will proceed to technical review (up to 5 days).
3. You will receive a decision: accepted, more information needed, or not accepted for this round.

**What this is (and isn't):**

- This is a **controlled testnet** for infrastructure testing. No mainnet is live.
- Testnet tokens (NXRL) **have no monetary value** and cannot be exchanged.
- This is **not a token sale, investment, or financial opportunity.**
- Validator registration is **not permissionless** — each application is reviewed.

**In the meantime:**

- Review the registration guide: `docs/testnet/CONTROLLED_VALIDATOR_REGISTRATION.md`
- Read the FAQ: `docs/testnet/FAQ.md`
- Ensure your infrastructure meets the minimum requirements (Linux host required)

If you have questions, reply to this email or contact the coordinator through the testnet communication channel.

—
NexaRail Genesis Coordinator
[Contact Channel Placeholder]

---

## Template B: Accepted

**Subject:** NexaRail Testnet — Validator Application Accepted (APP-XXX)

Dear [Operator Name],

Your application to operate a validator on the NexaRail controlled testnet has been **accepted**.

**Your validator moniker:** [Moniker]

**Next steps:**

1. **Complete the acceptance checklist:** `docs/testnet/VALIDATOR_ACCEPTANCE_CHECKLIST.md`
   - Provision your Linux host
   - Build the `nexaraild` binary
   - Generate your validator keys

2. **Follow the gentx submission instructions:** `docs/testnet/GENESIS_SUBMISSION_INSTRUCTIONS.md`
   - Initialise your validator
   - Record your node ID and validator public key
   - Create your validator account key
   - Submit your gentx

3. **Join the communication channel:** [Channel invite link]

**Gentx deadline:** [Date/Time UTC]

**Important reminders:**

- You **must run on a Linux host** — not macOS or Docker Desktop.
- Testnet tokens have **zero monetary value**.
- This is infrastructure testing — not an investment.
- The testnet state may be wiped at any time.

**Your node ID** (once generated) will be added to the persistent peer list distributed to all validators.

Please confirm receipt of this email and your intent to proceed.

—
NexaRail Genesis Coordinator
[Contact Channel Placeholder]

---

## Template C: More Information Needed

**Subject:** NexaRail Testnet — Additional Information Requested (APP-XXX)

Dear [Operator Name],

Thank you for your validator application. Before we can proceed with the technical review, we need additional information.

**Specifically:**

[Insert specific questions — e.g., "Please confirm your intended Linux distribution and version", "Please provide more detail about your key management practice", etc.]

Please respond within [N] days. If we don't hear back, your application will be paused.

You can reply directly to this email or through the testnet communication channel.

—
NexaRail Genesis Coordinator
[Contact Channel Placeholder]

---

## Template D: Not Accepted for This Round

**Subject:** NexaRail Testnet — Validator Application Status (APP-XXX)

Dear [Operator Name],

Thank you for applying to operate a validator on the NexaRail controlled testnet. After review, your application has **not been accepted** for this intake round.

**Reason:** [Select from standardised codes — R1 through R8 — and provide brief explanation]

**Example reasons:**
- "The current minimum hardware requirement is 4 vCPU / 8 GB RAM / 100 GB SSD on a Linux host."
- "Validator operators must run on Linux hosts. macOS/Docker Desktop is not supported for validator operation."
- "We are prioritising operators with demonstrated validator experience at this stage."
- "Controlled registration capacity has been reached for this round."

**What this means:**

This decision applies to the current intake round only. You are welcome to reapply in future rounds, particularly if your circumstances change or capacity expands.

**This is not:**
- A judgment on you or your organisation
- A permanent exclusion
- Financial rejection (there is no financial element to testnet participation)

Thank you for your interest in NexaRail.

—
NexaRail Genesis Coordinator
[Contact Channel Placeholder]

---

## Template D (Waitlist Variant)

**Subject:** NexaRail Testnet — Validator Application Waitlisted (APP-XXX)

Dear [Operator Name],

Thank you for your validator application. Your application meets our requirements, but **controlled registration capacity has been reached** for the current intake round.

Your application has been placed on the **waitlist**. If a slot becomes available (e.g., a validator withdraws or we expand the set), you will be contacted in order.

We expect to review the validator set size periodically and will notify waitlisted applicants of any changes.

—
NexaRail Genesis Coordinator
[Contact Channel Placeholder]

---

## Template E: Gentx Reminder

**Subject:** NexaRail Testnet — Gentx Submission Reminder (APP-XXX)

Dear [Operator Name],

This is a reminder that the **gentx submission deadline** for the NexaRail controlled testnet is:

**[Date/Time UTC]** — [N] hours from now.

**Your application reference:** APP-[XXX]
**Status:** Accepted, awaiting gentx

To submit your gentx, follow: `docs/testnet/GENESIS_SUBMISSION_INSTRUCTIONS.md`

If you need an extension or are encountering technical difficulties, please contact the coordinator as soon as possible.

If we do not receive your gentx by the deadline, your validator will not be included in the initial genesis. You may reapply in a future round.

—
NexaRail Genesis Coordinator
[Contact Channel Placeholder]

---

## Template F: Launch Coordination

**Subject:** NexaRail Testnet — Launch Coordination (T-[Time])

Dear [Operator Name],

The coordinated launch of `nexarail-testnet-1` is scheduled for:

**Launch time:** [Date/Time UTC]
**Your validator:** [Moniker] (APP-XXX)

**Pre-launch checklist (T-2 hours):**
- [ ] Verify genesis checksum: [checksum]
- [ ] Confirm binary is built and tested
- [ ] Confirm ports 26656 (P2P) and 26657 (RPC) are open
- [ ] Confirm you are in the testnet communication channel
- [ ] Reply to this email confirming readiness

**At T-0:**
```bash
nexaraild start --minimum-gas-prices 0.025unxrl
```

**Persistent peers:**
```
[peer_list]
```

**Post-launch:**
- Monitor block production for the first 100 blocks
- Report any issues immediately in the communication channel
- The coordinator will confirm when the network is stable

**Emergency contact:** [Coordinator direct contact]

—
NexaRail Genesis Coordinator
[Contact Channel Placeholder]

---

## Template G: Incident / Update Notice

**Subject:** NexaRail Testnet — [INFO/ISSUE/UPGRADE] [Brief Title]

Dear Validators,

**[Brief description of the incident, update, or announcement.]**

**Status:** [Investigating / Resolved / Scheduled / In Progress]

**Impact:** [What this means for your validator]

**Action required:** [What you need to do, if anything]

**Timeline:**
- [Time]: [Event]
- [Time]: [Event]

**Additional information:** [Link to GitHub issue, doc, or detailed update]

Please acknowledge receipt. For urgent issues, contact the coordinator directly.

—
NexaRail Genesis Coordinator
[Contact Channel Placeholder]

---

## Template Guidelines

- **Always include** the testnet-only disclaimer in acceptance and onboarding emails
- **Never use** investment, profit, returns, price, or token value language in any positive/affirmative context
- **Never promise** mainnet launch, token distribution, or financial benefit
- **Always reference** the application ID (APP-XXX) for tracking
- **Keep templates factual** — coordinator may personalise as needed
- **CC or BCC** coordinator for record-keeping where appropriate

## Template Usage by Stage

| Stage | Template |
|---|---|
| Application Received | A |
| Accepted | B |
| More Info Needed | C |
| Rejected | D |
| Waitlisted | D (variant) |
| Gentx approaching deadline | E |
| Launch coordination | F |
| Incident / Update | G |
