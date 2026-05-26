# Discord / Telegram Moderation Guide — NexaRail Testnet

**Chain:** nexarail-testnet-1
**Phase:** 7B — Community Operations
**Audience:** Moderators, coordinator, community managers

---

## Channel Purpose

The NexaRail testnet communication channel exists for:
- Validator coordination and technical discussions
- Testnet announcements and updates
- Technical support and troubleshooting
- Community building around the NexaRail protocol

It does **not** exist for:
- Token price discussion
- Investment advice
- Speculation about mainnet
- Token sale rumours
- Financial promotion of any kind

---

## Allowed Topics

| Topic | Example |
|---|---|
| Validator setup and configuration | "How do I configure persistent_peers?" |
| Node performance and monitoring | "My node is at height X but my peer is at Y" |
| Governance proposals | "Proposal #3 is up for vote — discussion thread" |
| Bug reports and troubleshooting | "Getting error X when running command Y" |
| Testnet documentation | "The gentx guide says X, should I do Y?" |
| Upgrade coordination | "New binary released for upgrade at height Z" |
| Module testing | "Has anyone tested settlement with custom fee rates?" |
| Infrastructure discussion | "What monitoring stack are people using?" |
| General Cosmos SDK / CometBFT topics | Technical discussion relevant to validators |

---

## Prohibited Topics

| Topic | Action |
|---|---|
| Token price or value speculation | Remove message, warn user |
| Investment claims ("NXRL will go to $X") | Remove message, warn user, possible ban |
| Token sale claims ("ICO coming soon") | Remove message, immediate ban |
| "When mainnet?" (speculation) | Redirect to FAQ |
| "How much will NXRL be worth?" | Remove message, warn user |
| "Can I buy NXRL? Where to trade?" | Remove message, direct to FAQ |
| Promotion of other projects/tokens | Remove message, warn (unless pre-approved) |
| Spam, phishing, or scam links | Remove message, immediate ban |
| Hate speech, harassment | Remove message, warn or ban |
| NSFW content | Remove message, immediate ban |
| Private key / mnemonic requests | Remove message, warn — this is always a scam |

---

## Standard Responses

### "Can I buy NXRL?"

> NXRL has not been offered for sale. There is no ICO, IEO, IDO, or private sale. Testnet tokens have no monetary value and cannot be exchanged. Any claim that you can buy NXRL is fraudulent. Please see the FAQ: `docs/testnet/FAQ.md`

### "Is mainnet live?"

> No. NexaRail has no public mainnet. The current network (`nexarail-testnet-1`) is a controlled testnet for infrastructure testing only. See the FAQ for more details.

### "When will mainnet launch?"

> No mainnet launch date has been set or announced. The project is currently in controlled testnet phase. Any claims about mainnet launch dates are speculation. We will make official announcements through this channel when there are updates.

### "What's the NXRL price?"

> NXRL is a testnet token with no monetary value. It is not traded on any exchange and has no market price. This channel is for technical discussion only — not price talk.

### "Is this an investment?"

> No. Participation in the NexaRail testnet is not an investment. Testnet tokens have zero monetary value. No financial returns are promised or expected. This is infrastructure testing only.

### "How do I become a validator?"

> Validator registration is controlled — not permissionless. You must apply, be reviewed, and be accepted. Start here: `docs/testnet/CONTROLLED_VALIDATOR_REGISTRATION.md`

### "Can I claim the airdrop?"

> There is no airdrop. No token distribution has been announced. Any claim of an NXRL airdrop is fraudulent.

### "I found a security vulnerability"

> Please do NOT post security issues in this public channel. Report security issues via: [security contact placeholder]. See `docs/security/` for our disclosure policy.

---

## Handling Scammers

### Signs of a Scammer

- DM'ing users with "investment opportunities"
- Offering to sell NXRL tokens
- Claiming to be a team member without verification
- Asking for private keys, mnemonics, or passwords
- Posting phishing links
- Impersonating the coordinator or known validators

### Response Protocol

1. **Remove** the message immediately
2. **Ban** the user for: phishing, impersonation, token sale offers, DM spam
3. **Warn** the user for: first-time price talk, borderline content
4. **Announce** to the channel: "We've removed a scam/phishing message. Do not click unknown links or share private keys. NXRL cannot be purchased."
5. **Document** the incident for the coordinator

### When to Escalate

Escalate to the coordinator (direct message) if:
- A coordinated scam/phishing campaign is detected
- A known validator's account appears compromised
- A user is persistently evading bans
- Legal or regulatory concerns arise

---

## Escalation Paths

| Issue | First Responder | Escalate To |
|---|---|---|
| Price/investment talk | Moderator removes, warns | Coordinator if repeated |
| Scam/phishing | Moderator removes, bans | Coordinator + security contact |
| Impersonation | Moderator removes, bans | Coordinator immediately |
| Harassment | Moderator removes, warns | Coordinator if repeated |
| Security vulnerability report | Moderator redirects to security contact | Coordinator + security contact |
| Legal/regulatory question | Do not answer — escalate | Coordinator |
| Media/press inquiry | Do not answer — escalate | Coordinator |
| Validator emergency | Escalate immediately | Coordinator |

---

## Moderator Conduct

- Be professional and consistent
- Enforce rules evenly — no favouritism
- Do not engage in debates about token value
- Do not share internal team information
- Do not make commitments on behalf of the project
- When in doubt, escalate — don't improvise
- Keep a log of moderation actions for coordinator review

---

## Channel Setup Recommendations

- **Welcome message** with rules, FAQ link, and disclaimer
- **Pinned messages:** Rules, FAQ link, registration guide link
- **Slow mode** enabled during launch events (to manage volume)
- **Verification** (optional) to prevent bot spam
- **Announcement channel** (read-only) for official updates separate from discussion

---

## Weekly Moderation Checklist

- [ ] Review recent moderation actions
- [ ] Check for unanswered technical questions (bump or escalate)
- [ ] Verify pinned messages are current
- [ ] Report any concerning patterns to coordinator
- [ ] Update FAQ if new common questions emerge
