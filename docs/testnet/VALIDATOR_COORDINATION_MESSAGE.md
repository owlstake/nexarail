# Validator Coordination Message — NexaRail Testnet

**Chain:** nexarail-testnet-1
**Phase:** 7C — Accepted Validator Onboarding
**Use:** Send to validators immediately upon acceptance

---

## Message to Accepted Validators

---

**Subject:** Welcome to NexaRail Testnet — Next Steps for [Moniker]

Congratulations — your application to operate a validator on the NexaRail controlled testnet has been accepted.

### What This Is

You've been accepted as a genesis validator for `nexarail-testnet-1`. Your validator will participate in consensus from block 1. This is infrastructure testing — not mainnet, not a token sale, not an investment.

### Important Reminders

- **Testnet only.** No mainnet is live. No launch date has been set.
- **No monetary value.** NXRL testnet tokens cannot be exchanged, traded, or transferred for value.
- **No token sale.** NXRL has not been offered for sale through any mechanism.
- **No investment.** Participation is for technical testing only.
- **Linux required.** Your validator must run on a Linux host. macOS and Docker Desktop are not supported.
- **Chain may reset.** Testnet state may be wiped at any time.

### Chain Configuration

| Parameter | Value |
|---|---|
| Chain ID | `nexarail-testnet-1` |
| Denom | `unxrl` |
| Display Ticker | `NXRL` (1 NXRL = 1,000,000 unxrl) |
| Bech32 Prefix | `nxr` |
| Minimum Self-Delegation | 500,000,000 unxrl |
| Minimum Gas Price | 0.025unxrl |

### Your Next Steps

**Deadline for gentx submission:** [Date/Time UTC]

1. **Read the acceptance checklist:** `docs/testnet/VALIDATOR_ACCEPTANCE_CHECKLIST.md`
2. **Follow the gentx instructions:** `docs/testnet/GENESIS_SUBMISSION_INSTRUCTIONS.md`
3. **Join the communication channel:** [Channel invite link]

### What to Submit

When ready, submit your gentx file. The acceptance checklist walks you through every step:
- Build the binary
- Initialise your validator
- Generate keys
- Create your validator account
- Create and submit your gentx

### What NOT to Submit

- Private keys (priv_validator_key.json, node_key.json)
- Mnemonic phrases
- Passwords
- Any other private material

### Support

- **Technical questions:** Communication channel or GitHub Issues
- **Urgent issues:** Direct message to coordinator
- **Gentx trouble:** Reply to this message with your specific error

### What Happens Next

1. You submit your gentx
2. Coordinator verifies it (3 days)
3. All gentxs collected → genesis built
4. Genesis checksum published
5. Launch time announced
6. Coordinated launch at T-0

### Thank You

Thank you for contributing to NexaRail's infrastructure testing. Your participation helps validate the protocol before any consideration of mainnet readiness.

—
NexaRail Genesis Coordinator
[Contact Channel Placeholder]

---

**Template Notes:**

- Replace `[Moniker]` with the validator's moniker
- Replace `[Date/Time UTC]` with the actual gentx deadline
- Replace `[Channel invite link]` with the actual invite
- Send via the validator's preferred contact method (email, Discord, or Telegram)
- CC coordinator for records
- Send within 24 hours of acceptance decision
