# Validator Scoring Rubric — NexaRail Testnet

**Chain:** nexarail-testnet-1
**Phase:** 7B — Intake
**Use:** Score applicant validators during Technical Review stage

---

## Scoring Categories

Each category scored 0-5. Maximum total: 35.

Pass threshold: **20/35** (flexible — coordinator discretion applies).

---

### 1. Validator Experience (0-5)

Proven track record running blockchain validators.

| Score | Criteria |
|---|---|
| 0 | No validator experience |
| 1 | Has experimented with testnet validators |
| 2 | 1+ years running validators on 1 chain |
| 3 | 2+ years on 2+ chains, including Cosmos SDK |
| 4 | 3+ years on 3+ chains, Cosmos SDK mainnet experience |
| 5 | 4+ years, multiple mainnets, incident response experience |

**Evidence:** Listed chains, years, references, GitHub activity.

---

### 2. Linux / Server Capability (0-5)

Ability to provision, secure, and maintain a Linux server for validator operations.

| Score | Criteria |
|---|---|
| 0 | No server administration experience |
| 1 | Basic Linux familiarity, uses managed hosting |
| 2 | Comfortable with Linux CLI, can follow setup guides |
| 3 | Self-manages servers, SSH hardening, firewall configuration |
| 4 | Automated provisioning (Ansible/Terraform), monitoring stack |
| 5 | Multi-datacenter, redundant infrastructure, sentry node architecture |

**Evidence:** Infrastructure description, hosting provider, automation tools.

---

### 3. Monitoring Capability (0-5)

Ability to detect and respond to validator issues proactively.

| Score | Criteria |
|---|---|
| 0 | No monitoring planned |
| 1 | Manual log checks |
| 2 | Basic alerting (uptime monitor) |
| 3 | Prometheus/Grafana stack, alert thresholds |
| 4 | Full observability (metrics, logs, traces), pager duty |
| 5 | Custom dashboards, anomaly detection, 24/7 on-call |

**Evidence:** Monitoring setup description, tools listed.

---

### 4. Security Practices (0-5)

Key management, access control, and operational security.

| Score | Criteria |
|---|---|
| 0 | No security practices described |
| 1 | Basic key backup (encrypted file) |
| 2 | Hardware wallet or dedicated key machine |
| 3 | HSM, air-gapped signing, multi-sig for withdrawals |
| 4 | Formal key ceremony, hardware security module, access audit logs |
| 5 | Dedicated security team, external audit, insurance |

**Evidence:** Key management practice, access control description.

---

### 5. Communication Reliability (0-5)

Responsiveness, professionalism, and availability for coordination.

| Score | Criteria |
|---|---|
| 0 | No contact information provided |
| 1 | Email only, no real-time contact |
| 2 | Discord/Telegram handle provided |
| 3 | Responsive to coordinator within 24h, professional communication |
| 4 | 24/7 reachable, emergency contact provided, proactive communicator |
| 5 | Dedicated operations contact, established communication protocols |

**Evidence:** Contact methods, response patterns during application.

---

### 6. Geographic / Network Diversity (0-5)

Contribution to validator set diversity — reduces correlated failure risk.

| Score | Criteria |
|---|---|
| 0 | Same region/provider as existing validators |
| 1 | Different city, same continent |
| 2 | Different continent from majority |
| 3 | Unique geographic region, different hosting provider |
| 4 | Unique country + unique provider + unique network path |
| 5 | Strategically diverse (underserved region, unique infrastructure) |

**Evidence:** Hosting provider, geographic region, network specs.

**Note:** This category is evaluated relative to the current validator set. Early applicants get neutral scoring until diversity can be assessed.

---

### 7. Testnet Commitment & Understanding (0-5)

Clear understanding that this is testnet-only, with no monetary value or investment expectations.

| Score | Criteria |
|---|---|
| 0 | Makes investment/token value claims |
| 1 | Vague about testnet-only nature |
| 2 | Acknowledges testnet-only but seems uncertain |
| 3 | Clearly states understanding of testnet-only, no-value status |
| 4 | Articulates specific testing goals, willing to test edge cases |
| 5 | Proposes specific test scenarios, actively contributes to test quality |

**Evidence:** Application responses, disclaimers acknowledged, communication.

---

## Score Summary

| Category | Weight | Score |
|---|---|---|
| Validator Experience | 0-5 | |
| Linux / Server Capability | 0-5 | |
| Monitoring Capability | 0-5 | |
| Security Practices | 0-5 | |
| Communication Reliability | 0-5 | |
| Geographic / Network Diversity | 0-5 | |
| Testnet Commitment | 0-5 | |
| **Total** | **/35** | |

## Decision Matrix

| Score | Decision |
|---|---|
| 30-35 | Strong accept — prioritise for early genesis inclusion |
| 25-29 | Accept — standard validator |
| 20-24 | Conditional accept — may request additional information or infrastructure upgrade |
| 15-19 | Waitlist — reconsider in next intake round if capacity allows |
| 0-14 | Reject — does not meet minimum threshold |

## Overrides

The coordinator may override the numeric score in either direction for:

- **Known operator** with strong reputation (can skip scoring)
- **Critical diversity contribution** (unique geography, provider, or infrastructure)
- **Red flags** (score irrelevant — immediate rejection):
  - Token value or investment claims
  - Fraud or impersonation
  - History of validator attacks
  - Refusal to acknowledge testnet-only nature

## Notes

- This rubric is for **controlled testnet intake only**. Mainnet criteria would be stricter.
- Early applicants may score lower on geographic diversity — this is expected.
- The rubric is a guide. Coordinator judgment is final.
- Scores and notes are internal — not shared with applicants.
