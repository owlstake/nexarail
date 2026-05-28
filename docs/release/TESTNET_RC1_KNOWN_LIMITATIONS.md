# NexaRail Controlled Testnet RC1 — Known Limitations

This document enumerates all known limitations, deferred work, and gating items for the NexaRail Controlled Testnet RC1 release.

---

## 1. No Mainnet Exists

The NexaRail mainnet has not been launched. This release is exclusively a controlled testnet release candidate. No mainnet infrastructure, incentives, or guarantees are implied.

---

## 2. No Token Sale Has Occurred

No token sale has taken place. No tokens with real or implied economic value exist on the network. All testnet tokens are for testing purposes only and carry zero value.

---

## 3. External Validators Have Not Been Onboarded (Pending)

The validator set is currently internal only. External validator onboarding is pending and planned for a subsequent release phase. No gentx from external parties has been collected.

---

## 4. Final External Genesis Not Assembled

The final genesis file for an external validator set requires gentx collection from prospective validators. This has not been performed. The current genesis is generated for the controlled testnet only.

---

## 5. Escrow Dispute Harness Coverage Deferred

The underlying escrow keeper module supports dispute resolution, but the end-to-end dispute test harness has not been implemented. Dispute scenarios remain manually verifiable via keeper unit tests only.

---

## 6. CLI-Native Product-Gov Commands Deferred

Dedicated CLI commands for product governance operations have not been implemented. A script-based wrapper exists for testing and rehearsal purposes. Native CLI commands are planned for a future release.

---

## 7. External Security Audit Pending

No external third-party security audit has been performed. The codebase has undergone internal review and automated testing only.

---

## 8. Legal Review Pending

The project has not undergone external legal review. Compliance with applicable regulations has not been assessed by external counsel.

---

## 9. Validator Distribution Design Pending

The design for validator distribution, including delegation mechanics and incentive structures, has been deferred to the external validator onboarding phase.

---

## 10. Public Testnet Launch Remains Gated

A public testnet launch is contingent on the completion of:
- Validator onboarding
- Genesis assembly (gentx collection)
- External security audit
- Legal review
- Communications and documentation readiness

All of these items remain pending.

---

## 11. Live Fund Flags Disabled by Default

All genesis parameters that would enable live funds, real-value transfers, or economic operation are set to `false` by default. This is by design. No flag should be toggled to `true` until a mainnet-grade release is prepared.

---

## 12. REST Is Readback-Only; Tx Broadcast Uses Generic Cosmos Endpoint

The REST API layer supports readback queries (36/36 endpoints operational), but transaction broadcast relies on the generic Cosmos SDK `/cosmos/tx/v1beta1/txs` endpoint. There is no NexaRail-specific tx broadcast endpoint in this release.

---

## 13. No SLAs, No Mainnet Guarantees, No Token Value

This release is provided as-is for testing and validation purposes only. There are no:
- Service level agreements (SLAs)
- Uptime or availability guarantees
- Mainnet commitments
- Token value representations

---

*End of known limitations.*
